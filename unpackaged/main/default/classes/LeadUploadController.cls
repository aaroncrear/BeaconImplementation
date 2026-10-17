/**
 * Backs the leadUploader LWC, which lets Experience Cloud (and internal) users upload a CSV
 * list of up to 2,000 Leads.
 *
 * The component parses the file in the browser and sends it here in batches of up to 200
 * rows, so each batch is its own transaction and stays well inside governor limits (Lead
 * flows included).
 *
 * Security: the uploader's object access and field-level security are checked on every Lead
 * field taken from the file, and Lead Upload records are read in user mode, so users only see
 * their own uploads. Owner, partner and counter fields are set by the server in system mode,
 * because partner users can't assign records to a queue and shouldn't be able to edit them.
 * LeadUploadRouting decides who owns the Leads.
 *
 * Call order: startUpload -> uploadLeads (once per batch) -> completeUpload.
 */
public with sharing class LeadUploadController {
    public static final Integer MAX_ROWS = 2000;
    public static final Integer MAX_BATCH_SIZE = 200;

    public static final String STATUS_IN_PROGRESS = 'In Progress';
    public static final String STATUS_COMPLETED = 'Completed';
    public static final String STATUS_COMPLETED_WITH_ERRORS = 'Completed with Errors';
    public static final String STATUS_FAILED = 'Failed';

    // Lead fields a CSV can populate, in template column order.
    @TestVisible
    private static final List<String> UPLOAD_FIELDS = new List<String>{
        'FirstName', 'LastName', 'Company', 'Title', 'Email', 'Phone', 'MobilePhone', 'Website',
        'Street', 'City', 'State', 'PostalCode', 'Country',
        'Industry', 'LeadSource', 'NumberOfEmployees', 'AnnualRevenue', 'Description'
    };

    // Mirrors the required fields on the Lead Layout, plus First Name (First_Name_Required rule).
    // LeadSource can be supplied by the component's Default Lead Source instead of the file.
    @TestVisible
    private static final Set<String> REQUIRED_FIELDS = new Set<String>{
        'FirstName', 'LastName', 'Company', 'Title', 'Email', 'Website', 'LeadSource'
    };

    public class UploadField {
        @AuraEnabled public String apiName;
        @AuraEnabled public String label;
        @AuraEnabled public Boolean required;
    }

    public class RowResult {
        @AuraEnabled public Integer rowNumber;
        @AuraEnabled public Boolean success;
        @AuraEnabled public String recordId;
        @AuraEnabled public String message;

        RowResult(Integer rowNumber, Boolean success, String recordId, String message) {
            this.rowNumber = rowNumber;
            this.success = success;
            this.recordId = recordId;
            this.message = message;
        }
    }

    /**
     * Returns the columns the CSV can contain, limited to fields the running user can create.
     */
    @AuraEnabled(cacheable=true)
    public static List<UploadField> getUploadFields() {
        if (!Schema.SObjectType.Lead.isCreateable()) {
            throw newAuraException('You do not have permission to create Leads.');
        }
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Lead.fields.getMap();
        List<UploadField> result = new List<UploadField>();
        for (String apiName : UPLOAD_FIELDS) {
            Schema.DescribeFieldResult describe = fieldMap.get(apiName).getDescribe();
            if (!describe.isCreateable()) {
                continue;
            }
            UploadField field = new UploadField();
            field.apiName = apiName;
            field.label = describe.getLabel();
            field.required = REQUIRED_FIELDS.contains(apiName);
            result.add(field);
        }
        return result;
    }

    /**
     * Creates the Lead Upload record that tracks the upload and returns its Id.
     */
    @AuraEnabled
    public static Id startUpload(String fileName, Integer totalRows) {
        if (totalRows == null || totalRows < 1) {
            throw newAuraException('The file has no data rows.');
        }
        if (totalRows > MAX_ROWS) {
            throw newAuraException('The file has ' + totalRows + ' rows. The limit is ' + MAX_ROWS + '.');
        }
        if (!Schema.SObjectType.Lead.isCreateable() || !Schema.SObjectType.Lead_Upload__c.isCreateable()) {
            throw newAuraException('You do not have permission to upload Leads.');
        }

        LeadUploadRouting.Route route;
        try {
            route = LeadUploadRouting.resolve(UserInfo.getUserId());
        } catch (LeadUploadRouting.RoutingException e) {
            throw newAuraException(e.getMessage());
        }

        Lead_Upload__c upload = new Lead_Upload__c(
            File_Name__c = String.isBlank(fileName) ? null : fileName.left(255),
            Total_Rows__c = totalRows,
            Success_Count__c = 0,
            Error_Count__c = 0,
            Status__c = STATUS_IN_PROGRESS,
            Partner_Account__c = route.partnerAccountId,
            Assigned_Queue__c = route.queueName
        );
        try {
            insert as system upload;
        } catch (Exception e) {
            throw newAuraException('The upload could not be started: ' + e.getMessage());
        }
        return upload.Id;
    }

    /**
     * Inserts one batch of rows. rowsJson is a JSON array of objects keyed by Lead field API
     * name. firstRowNumber is the file row number of the first element, used in results.
     * Rows that fail don't stop the rest of the batch.
     */
    @AuraEnabled
    public static List<RowResult> uploadLeads(Id uploadId, String rowsJson, Integer firstRowNumber, String defaultLeadSource) {
        if (!Schema.SObjectType.Lead.isCreateable()) {
            throw newAuraException('You do not have permission to create Leads.');
        }
        Lead_Upload__c upload = getUpload(uploadId);
        if (upload.Status__c != STATUS_IN_PROGRESS) {
            throw newAuraException('This upload has already finished.');
        }

        List<Map<String, String>> rows;
        try {
            rows = (List<Map<String, String>>) JSON.deserialize(rowsJson, List<Map<String, String>>.class);
        } catch (Exception e) {
            throw newAuraException('The batch could not be read: ' + e.getMessage());
        }
        if (rows == null || rows.isEmpty()) {
            return new List<RowResult>();
        }
        if (rows.size() > MAX_BATCH_SIZE) {
            throw newAuraException('A batch can contain at most ' + MAX_BATCH_SIZE + ' rows.');
        }
        Integer startRow = firstRowNumber == null ? 1 : firstRowNumber;

        LeadUploadRouting.Route route;
        try {
            route = LeadUploadRouting.forUpload(upload, UserInfo.getUserId());
        } catch (LeadUploadRouting.RoutingException e) {
            throw newAuraException(e.getMessage());
        }

        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Lead.fields.getMap();
        Set<String> allowedFields = new Set<String>(UPLOAD_FIELDS);

        List<RowResult> results = new List<RowResult>();
        List<Lead> leadsToInsert = new List<Lead>();
        List<Integer> insertRowNumbers = new List<Integer>();

        for (Integer i = 0; i < rows.size(); i++) {
            Integer rowNumber = startRow + i;
            try {
                leadsToInsert.add(buildLead(rows[i], fieldMap, allowedFields, defaultLeadSource));
                insertRowNumbers.add(rowNumber);
            } catch (RowException e) {
                results.add(new RowResult(rowNumber, false, null, e.getMessage()));
            }
        }

        if (!leadsToInsert.isEmpty()) {
            // Enforce field-level security on the values that came from the file. getUploadFields
            // only offers creatable fields, so anything removed here means the request was altered
            // or the user's access changed mid-upload.
            SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, leadsToInsert);
            Set<String> removedFields = decision.getRemovedFields().get('Lead');
            if (removedFields != null && !removedFields.isEmpty()) {
                throw newAuraException('You do not have access to these Lead fields: ' + String.join(new List<String>(removedFields), ', '));
            }
            leadsToInsert = (List<Lead>) decision.getRecords();

            // Server-controlled fields, added after the FLS check.
            for (Lead lead : leadsToInsert) {
                lead.Lead_Upload__c = upload.Id;
                lead.Partner_Account__c = route.partnerAccountId;
                if (route.queueId != null) {
                    lead.OwnerId = route.queueId;
                }
            }

            List<Id> createdLeadIds = new List<Id>();
            List<Database.SaveResult> saveResults = Database.insert(leadsToInsert, false, AccessLevel.SYSTEM_MODE);
            for (Integer i = 0; i < saveResults.size(); i++) {
                Database.SaveResult saveResult = saveResults[i];
                if (saveResult.isSuccess()) {
                    createdLeadIds.add(saveResult.getId());
                    results.add(new RowResult(insertRowNumbers[i], true, saveResult.getId(), null));
                } else {
                    results.add(new RowResult(insertRowNumbers[i], false, null, describeErrors(saveResult.getErrors())));
                }
            }
            if (route.shareWithUploader && !createdLeadIds.isEmpty()) {
                LeadUploadRouting.shareWithUploader(createdLeadIds, UserInfo.getUserId());
            }
        }

        Integer successCount = 0;
        for (RowResult result : results) {
            if (result.success) {
                successCount++;
            }
        }
        upload.Success_Count__c = (upload.Success_Count__c == null ? 0 : upload.Success_Count__c) + successCount;
        upload.Error_Count__c = (upload.Error_Count__c == null ? 0 : upload.Error_Count__c) + (results.size() - successCount);
        update as system upload;

        return results;
    }

    /**
     * Sets the final status on the Lead Upload and, if any rows failed, attaches errorCsv as a
     * file so the errors can be reviewed later. Returns the final status.
     */
    @AuraEnabled
    public static String completeUpload(Id uploadId, String errorCsv) {
        Lead_Upload__c upload = getUpload(uploadId);
        Decimal successCount = upload.Success_Count__c == null ? 0 : upload.Success_Count__c;
        // Success_Count__c only grows in committed batches, so every other row failed, including
        // rows in a batch whose call failed outright and never reached uploadLeads' count update.
        Decimal totalRows = upload.Total_Rows__c == null ? 0 : upload.Total_Rows__c;
        Decimal errorCount = totalRows > successCount ? totalRows - successCount : 0;
        upload.Error_Count__c = errorCount;

        if (errorCount == 0) {
            upload.Status__c = STATUS_COMPLETED;
        } else if (successCount == 0) {
            upload.Status__c = STATUS_FAILED;
        } else {
            upload.Status__c = STATUS_COMPLETED_WITH_ERRORS;
        }
        upload.Completed_Date__c = System.now();
        update as system upload;

        if (String.isNotBlank(errorCsv)) {
            ContentVersion errorFile = new ContentVersion(
                Title = 'Lead Upload Errors - ' + upload.Name,
                PathOnClient = 'Lead Upload Errors - ' + upload.Name + '.csv',
                VersionData = Blob.valueOf(errorCsv),
                FirstPublishLocationId = upload.Id
            );
            insert as user errorFile;
        }
        return upload.Status__c;
    }

    private static Lead_Upload__c getUpload(Id uploadId) {
        List<Lead_Upload__c> uploads = [
            SELECT Id, Name, Status__c, Total_Rows__c, Success_Count__c, Error_Count__c, Partner_Account__c, Assigned_Queue__c
            FROM Lead_Upload__c
            WHERE Id = :uploadId
            WITH USER_MODE
            LIMIT 1
        ];
        if (uploads.isEmpty()) {
            throw newAuraException('The upload record could not be found.');
        }
        return uploads[0];
    }

    private static Lead buildLead(
        Map<String, String> row,
        Map<String, Schema.SObjectField> fieldMap,
        Set<String> allowedFields,
        String defaultLeadSource
    ) {
        Lead lead = new Lead();
        for (String apiName : row.keySet()) {
            String value = row.get(apiName);
            if (!allowedFields.contains(apiName) || String.isBlank(value)) {
                continue;
            }
            Schema.DescribeFieldResult describe = fieldMap.get(apiName).getDescribe();
            lead.put(apiName, convertValue(value.trim(), describe));
        }
        if (String.isBlank(lead.LeadSource) && String.isNotBlank(defaultLeadSource)) {
            lead.LeadSource = defaultLeadSource;
        }

        List<String> missing = new List<String>();
        for (String apiName : UPLOAD_FIELDS) {
            if (REQUIRED_FIELDS.contains(apiName) && lead.get(apiName) == null) {
                missing.add(fieldMap.get(apiName).getDescribe().getLabel());
            }
        }
        if (!missing.isEmpty()) {
            throw new RowException('Missing required value: ' + String.join(missing, ', '));
        }
        return lead;
    }

    private static Object convertValue(String value, Schema.DescribeFieldResult describe) {
        Schema.DisplayType fieldType = describe.getType();
        try {
            if (fieldType == Schema.DisplayType.INTEGER) {
                return Integer.valueOf(cleanNumber(value));
            }
            if (fieldType == Schema.DisplayType.CURRENCY || fieldType == Schema.DisplayType.DOUBLE) {
                return Decimal.valueOf(cleanNumber(value));
            }
        } catch (Exception e) {
            throw new RowException(describe.getLabel() + ' must be a number: "' + value + '"');
        }
        return value;
    }

    // Strips thousands separators, currency symbols and spaces, e.g. "$1,250,000" -> "1250000".
    private static String cleanNumber(String value) {
        return value.replaceAll('[,\\s$£€]', '');
    }

    private static String describeErrors(List<Database.Error> errors) {
        List<String> messages = new List<String>();
        for (Database.Error error : errors) {
            String message = error.getMessage();
            if (error.getFields() != null && !error.getFields().isEmpty()) {
                message += ' (' + String.join(error.getFields(), ', ') + ')';
            }
            messages.add(message);
        }
        return String.join(messages, '; ');
    }

    private static AuraHandledException newAuraException(String message) {
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message);
        return e;
    }

    private class RowException extends Exception {}
}
