import { LightningElement, api, wire } from 'lwc';
import getUploadFields from '@salesforce/apex/LeadUploadController.getUploadFields';
import startUpload from '@salesforce/apex/LeadUploadController.startUpload';
import uploadLeads from '@salesforce/apex/LeadUploadController.uploadLeads';
import completeUpload from '@salesforce/apex/LeadUploadController.completeUpload';
import { parseCsv, toCsv, normalizeHeader } from './csvParser';

// Keep in step with LeadUploadController.MAX_ROWS and MAX_BATCH_SIZE.
const MAX_ROWS = 2000;
const BATCH_SIZE = 200;
const MAX_FILE_SIZE = 5 * 1024 * 1024;
const PREVIEW_ROWS = 10;

export default class LeadUploader extends LightningElement {
    @api cardTitle = 'Upload Leads';
    // Applied to rows whose Lead Source column is missing or blank.
    @api defaultLeadSource;

    fields = [];
    loadError;

    fileName;
    headers = [];
    dataRows = [];
    columnMap = []; // { index, apiName } for each mapped column
    ignoredHeaders = [];
    fileErrors = [];

    isUploading = false;
    processedRows = 0;
    result;
    errorRows = [];

    @wire(getUploadFields)
    wiredFields({ data, error }) {
        if (data) {
            this.fields = data;
            this.loadError = undefined;
        } else if (error) {
            this.loadError = reduceError(error);
        }
    }

    get hasLoadError() {
        return Boolean(this.loadError);
    }

    get maxRows() {
        return MAX_ROWS;
    }

    get requiredFieldLabels() {
        return this.fields
            .filter((field) => field.required && !(field.apiName === 'LeadSource' && this.defaultLeadSource))
            .map((field) => field.label)
            .join(', ');
    }

    get hasFile() {
        return Boolean(this.fileName);
    }

    get hasFileErrors() {
        return this.fileErrors.length > 0;
    }

    get hasIgnoredHeaders() {
        return this.ignoredHeaders.length > 0;
    }

    get ignoredHeaderText() {
        return this.ignoredHeaders.join(', ');
    }

    get rowCount() {
        return this.dataRows.length;
    }

    get isUploadDisabled() {
        return !this.hasFile || this.hasFileErrors || this.isUploading || Boolean(this.result);
    }

    get isFileInputDisabled() {
        return this.isUploading || Boolean(this.loadError);
    }

    get progress() {
        return this.rowCount ? Math.round((this.processedRows / this.rowCount) * 100) : 0;
    }

    get previewColumns() {
        return this.columnMap.map((column) => ({
            label: this.fieldLabel(column.apiName),
            fieldName: column.apiName,
            type: 'text'
        }));
    }

    get previewData() {
        return this.dataRows.slice(0, PREVIEW_ROWS).map((row, i) => {
            const record = { key: String(i) };
            this.columnMap.forEach((column) => {
                record[column.apiName] = row[column.index];
            });
            return record;
        });
    }

    get previewLabel() {
        const shown = Math.min(PREVIEW_ROWS, this.rowCount);
        return `Preview (first ${shown} of ${this.rowCount} rows)`;
    }

    get hasErrorRows() {
        return this.errorRows.length > 0;
    }

    get resultVariant() {
        if (!this.result) {
            return '';
        }
        if (this.result.errorCount === 0) {
            return 'slds-notify slds-notify_alert slds-alert_success';
        }
        return this.result.successCount === 0
            ? 'slds-notify slds-notify_alert slds-alert_error'
            : 'slds-notify slds-notify_alert slds-alert_warning';
    }

    fieldLabel(apiName) {
        const field = this.fields.find((f) => f.apiName === apiName);
        return field ? field.label : apiName;
    }

    handleDownloadTemplate() {
        downloadCsv('Lead Upload Template.csv', toCsv([this.fields.map((field) => field.label)]));
    }

    handleFileChange(event) {
        const file = event.target.files && event.target.files[0];
        this.reset();
        if (!file) {
            return;
        }
        this.fileName = file.name;
        if (!/\.csv$/i.test(file.name)) {
            this.fileErrors = ['Choose a .csv file. In Excel, use File > Save As > CSV UTF-8.'];
            return;
        }
        if (file.size > MAX_FILE_SIZE) {
            this.fileErrors = ['The file is larger than 5 MB.'];
            return;
        }
        const reader = new FileReader();
        reader.onload = () => this.loadCsv(reader.result);
        reader.onerror = () => {
            this.fileErrors = ['The file could not be read.'];
        };
        reader.readAsText(file);
    }

    loadCsv(text) {
        let rows;
        try {
            rows = parseCsv(text);
        } catch (e) {
            this.fileErrors = [e.message];
            return;
        }
        if (rows.length === 0) {
            this.fileErrors = ['The file is empty.'];
            return;
        }

        this.headers = rows[0].map((header) => header.trim());
        this.dataRows = rows.slice(1);

        // Match each column to a field by label or API name, ignoring case, spaces and punctuation.
        const lookup = new Map();
        this.fields.forEach((field) => {
            lookup.set(normalizeHeader(field.label), field.apiName);
            lookup.set(normalizeHeader(field.apiName), field.apiName);
        });
        const mapped = new Set();
        const columnMap = [];
        const ignoredHeaders = [];
        const errors = [];
        this.headers.forEach((header, index) => {
            const apiName = lookup.get(normalizeHeader(header));
            if (!apiName) {
                if (header) {
                    ignoredHeaders.push(header);
                }
            } else if (mapped.has(apiName)) {
                errors.push(`More than one column maps to ${this.fieldLabel(apiName)}.`);
            } else {
                mapped.add(apiName);
                columnMap.push({ index, apiName });
            }
        });
        this.columnMap = columnMap;
        this.ignoredHeaders = ignoredHeaders;

        const missing = this.fields
            .filter((field) => field.required && !mapped.has(field.apiName))
            .filter((field) => !(field.apiName === 'LeadSource' && this.defaultLeadSource))
            .map((field) => field.label);
        if (missing.length) {
            errors.push(`Missing required columns: ${missing.join(', ')}.`);
        }
        if (this.dataRows.length === 0) {
            errors.push('The file has a header row but no data rows.');
        }
        if (this.dataRows.length > MAX_ROWS) {
            errors.push(`The file has ${this.dataRows.length} rows. The limit is ${MAX_ROWS}. Split it into smaller files.`);
        }
        this.fileErrors = errors;
    }

    async handleUpload() {
        this.isUploading = true;
        this.processedRows = 0;
        this.errorRows = [];
        let successCount = 0;

        try {
            const uploadId = await startUpload({ fileName: this.fileName, totalRows: this.rowCount });

            // Batches run one after another so each is its own transaction.
            for (let start = 0; start < this.rowCount; start += BATCH_SIZE) {
                const batch = this.dataRows.slice(start, start + BATCH_SIZE);
                // File row numbers: the header is row 1, so data starts at row 2.
                const firstRowNumber = start + 2;
                let results;
                try {
                    // eslint-disable-next-line no-await-in-loop
                    results = await uploadLeads({
                        uploadId,
                        rowsJson: JSON.stringify(batch.map((row) => this.toRecord(row))),
                        firstRowNumber,
                        defaultLeadSource: this.defaultLeadSource || null
                    });
                } catch (error) {
                    // The whole batch failed (for example, a timeout). Record every row and carry on.
                    const message = reduceError(error);
                    results = batch.map((row, i) => ({ rowNumber: firstRowNumber + i, success: false, message }));
                }
                const failed = results.filter((rowResult) => !rowResult.success);
                successCount += results.length - failed.length;
                this.errorRows = [...this.errorRows, ...failed];
                this.processedRows = Math.min(start + BATCH_SIZE, this.rowCount);
            }

            const status = await completeUpload({ uploadId, errorCsv: this.hasErrorRows ? this.buildErrorCsv() : null });
            this.result = {
                status,
                successCount,
                errorCount: this.errorRows.length,
                message: `${successCount} of ${this.rowCount} Leads created. ${this.errorRows.length} rows failed.`
            };
        } catch (error) {
            this.result = {
                status: 'Failed',
                successCount,
                errorCount: this.rowCount - successCount,
                message: `The upload stopped: ${reduceError(error)} ${successCount} Leads were created before it stopped.`
            };
        } finally {
            this.isUploading = false;
        }
    }

    toRecord(row) {
        const record = {};
        this.columnMap.forEach((column) => {
            const value = row[column.index];
            if (value !== undefined && value.trim() !== '') {
                record[column.apiName] = value.trim();
            }
        });
        return record;
    }

    buildErrorCsv() {
        const sorted = [...this.errorRows].sort((a, b) => a.rowNumber - b.rowNumber);
        const lines = [['Row', 'Error', ...this.headers]];
        sorted.forEach((rowResult) => {
            const original = this.dataRows[rowResult.rowNumber - 2] || [];
            lines.push([rowResult.rowNumber, rowResult.message, ...original]);
        });
        return toCsv(lines);
    }

    handleDownloadErrors() {
        downloadCsv(`Lead Upload Errors - ${this.fileName}`, this.buildErrorCsv());
    }

    handleReset() {
        this.reset();
    }

    reset() {
        this.fileName = undefined;
        this.headers = [];
        this.dataRows = [];
        this.columnMap = [];
        this.ignoredHeaders = [];
        this.fileErrors = [];
        this.processedRows = 0;
        this.result = undefined;
        this.errorRows = [];
    }
}

function downloadCsv(fileName, csv) {
    const link = document.createElement('a');
    link.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent('﻿' + csv);
    link.download = /\.csv$/i.test(fileName) ? fileName : `${fileName}.csv`;
    link.click();
}

function reduceError(error) {
    if (!error) {
        return 'Unknown error.';
    }
    if (Array.isArray(error.body)) {
        return error.body.map((e) => e.message).join(', ');
    }
    if (error.body && error.body.message) {
        return error.body.message;
    }
    return error.message || String(error);
}
