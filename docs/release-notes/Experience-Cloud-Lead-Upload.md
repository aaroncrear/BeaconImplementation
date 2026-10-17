# "Experience-Cloud-Lead-Upload" – Release Notes

## Requirements

Experience Cloud users (for example, partners) need a self-service way to upload Lead lists of up to 2,000 records, without Data Import Wizard, Data Loader or help from an admin. The business asked for:

1. A page component that Experience Cloud users can use to upload a list of Leads from a file.
2. Support for lists of up to 2,000 records in a single upload.
3. Clear feedback on which rows failed and why, so users can fix them and upload them again.
4. A record of each upload, so internal users can see who uploaded what and which Leads came from each list.

## Release Notes

**Lead Uploader component.** `leadUploader` is a Lightning Web Component exposed to Experience Builder (`lightningCommunity__Page` / `lightningCommunity__Default`) and to Lightning App Builder (App and Home pages, so internal users can use and test it too). It has two settings: **Card Title** and **Default Lead Source**. The user flow is:

1. **Download Template.** Downloads a CSV whose header row holds the labels of every field the user can create: First Name, Last Name, Company, Title, Email, Phone, Mobile Phone, Website, Street, City, State/Province, Zip/Postal Code, Country, Industry, Lead Source, Employees, Annual Revenue and Description. The list comes from Apex and respects field-level security, so the template never offers a column the user can't fill.
2. **Choose a CSV file.** The file is read and parsed in the browser. The parser handles quoted values, commas and line breaks inside quotes, and the byte-order mark that Excel's "CSV UTF-8" format adds. Columns are matched to fields by label or API name, ignoring case, spaces and punctuation, so both "Zip/Postal Code" and "PostalCode" work. Columns that don't match a field are listed as ignored. The upload is blocked with a clear message if the file isn't a .csv, is over 5 MB, has no data rows, has more than 2,000 rows, is missing a required column, or has two columns that map to the same field.
3. **Preview.** The first 10 rows are shown in a table so the user can check the mapping before uploading.
4. **Upload Leads.** Rows are sent to Apex in batches of 200, one after another. Each batch is its own transaction, so 2,000 rows (10 batches) stay well inside governor limits even with the Lead record-triggered flows running. A progress bar shows how many rows have been processed. Inserts allow partial success, so a bad row doesn't stop the rest of its batch. If a whole batch call fails (for example, a timeout), its rows are recorded as failed and the remaining batches still run.
5. **Results.** A banner shows how many Leads were created and how many rows failed. **Download Errors** downloads a CSV with the file row number, the error message and the original row values, so the user can fix the rows and upload the error file again. **Start Over** clears the component for the next file.

Why this approach: the standard Data Import Wizard isn't available to Experience Cloud users, and a screen flow can't parse a CSV without custom code. Parsing in the browser and sending batches avoids the Apex heap and CPU limits a single 2,000-row transaction would risk. It also avoids storing the raw file before it's validated, and gives the user feedback row by row.

**Required values.** A row must have First Name, Last Name, Company, Title, Email, Website and Lead Source. These match the required fields on the **Lead Layout**, plus First Name (enforced by the `First_Name_Required` validation rule). If **Default Lead Source** is set on the component, it fills in any blank Lead Source, and the Lead Source column becomes optional. The required list is the `REQUIRED_FIELDS` set in `LeadUploadController`. Number fields (Employees, Annual Revenue) accept thousands separators and currency symbols (e.g. `$1,250,000`). Picklist, email, state/country and duplicate-rule checks are left to Salesforce, and any failure comes back as that row's error message.

**LeadUploadController (Apex).** A `with sharing` class with four `@AuraEnabled` methods: `getUploadFields` (template columns), `startUpload` (creates the Lead Upload record and rejects files over 2,000 rows), `uploadLeads` (inserts a batch of up to 200 rows) and `completeUpload` (sets the final status and attaches the error file). Every query and DML statement runs in user mode (`WITH USER_MODE`, `insert as user`, `AccessLevel.USER_MODE`), so the uploader's object permissions, field-level security and sharing all apply. Only the fields in the upload list can be set from the file; any other key in the request is ignored. Leads are owned by the uploading user, and Lead assignment rules aren't run. `LeadUploadControllerTest` covers a full 200-row batch, mixed success and failure, the default Lead Source, an all-failed upload, the 2,000-row and 200-row-per-batch limits, and rejecting rows once an upload has finished.

**Lead Upload object.** `Lead_Upload__c` (auto-number `LU-00000`) records each upload: **File Name**, **Status** (In Progress, Completed, Completed with Errors, Failed), **Total Rows**, **Success Count**, **Error Count** and **Completed Date**. Success Count is added to as each batch commits. At completion, Error Count is set to Total Rows minus Success Count, so rows from a batch whose call failed outright are still counted. When rows fail, the error CSV is attached to the record as a file named "Lead Upload Errors - LU-xxxxx". An upload that is still **In Progress** later was interrupted, for example because the browser was closed mid-upload. The object is Private (internal and external), so uploaders see only their own uploads, and managers see them through the role hierarchy. It has a tab, an **All** list view and a **Lead Upload Layout** with the details, the Files related list and a Leads related list.

**Lead Upload field on Lead.** `Lead.Lead_Upload__c` looks up to the upload that created the Lead (Set Null if the upload is deleted). It was added read only to the **System Information** section of the **Lead Layout**.

**Beacon - Lead Upload permission set.** `Beacon_Lead_Upload` grants everything the feature needs: Lead Read/Create, Read/Edit on the Lead fields the upload can fill (Address, Annual Revenue, Description, Email, Industry, Lead Source, Lead Upload, Mobile Phone, Employees, Phone, Title, Website), Read/Create/Edit on Lead Upload and its fields, the Lead Upload tab, and access to the `LeadUploadController` class. No user license is set, so it can be assigned to Experience Cloud users as well as internal users. It doesn't grant Lead Edit or Delete. The Lead flows that update a Lead after it's created run in system context and aren't affected.

## Acceptance Criteria

1. **Deployment.** Confirm the deployment succeeds and `LeadUploadControllerTest` passes (Setup → Apex Test Execution).
2. **Permission set.** Open **Beacon - Lead Upload**. Confirm it has no license, has Lead Read/Create (no Edit/Delete), Lead Upload Read/Create/Edit, field permissions on the fields listed above, the Lead Upload tab visible and Apex class access to `LeadUploadController`.
3. **Component placement.** In Experience Builder for the partner site, drag **Lead Uploader** onto a page, set **Default Lead Source** to a valid Lead Source value, and publish. (Internal check: add it to a Lightning App page instead.)
4. **Template.** Log in to the site as an Experience Cloud user who has **Beacon - Lead Upload**. Click **Download Template** and confirm the CSV header lists the fields above.
5. **Happy path.** Fill the template with 5 valid rows and upload it. Confirm the preview shows the rows, the progress bar runs, and the banner reads "5 of 5 Leads created. 0 rows failed." Open the Lead Upload record and confirm Status is **Completed**, Total Rows 5, Success Count 5, Error Count 0, Completed Date populated, and 5 Leads in the Leads related list. Open a Lead and confirm the **Lead Upload** field links back, the owner is the uploading user, and Seniority Level and Account were filled in by the existing Lead flows where they apply.
6. **Default Lead Source.** Upload a file with no Lead Source column. Confirm the upload is allowed and the Leads get the component's Default Lead Source. Remove the Default Lead Source setting, upload the same file again, and confirm it's blocked with "Missing required columns: Lead Source."
7. **Row errors.** Upload a file of 5 rows in which one row has no Company, one has an invalid email, and one has "lots" in Employees. Confirm the banner reads "2 of 5 Leads created. 3 rows failed." Click **Download Errors** and confirm the CSV lists the file row number, a clear error message and the original values for each failed row. Confirm the Lead Upload record is **Completed with Errors** and has the "Lead Upload Errors" file attached.
8. **All rows fail.** Upload a file where every row is missing Last Name. Confirm 0 Leads are created and the Lead Upload status is **Failed**.
9. **2,000 rows.** Upload a file with exactly 2,000 valid rows. Confirm all 2,000 Leads are created, the progress bar steps through 10 batches, and Success Count is 2,000.
10. **Over the limit.** Upload a file with 2,001 rows. Confirm the Upload button stays disabled with a message to split the file.
11. **File checks.** Confirm a non-CSV file, an empty file, a header-only file, a file missing the Email column, and a file with both "Email" and "E-mail" columns are each blocked with a clear message. Confirm an unrecognised column (e.g. "Notes") is listed as ignored and doesn't block the upload.
12. **CSV formats.** Save the template from Excel as **CSV UTF-8** with a Description containing commas, quotes and a line break. Upload it and confirm the Description is stored exactly as entered.
13. **Security.** As an Experience Cloud user without **Beacon - Lead Upload**, confirm the component shows a permission error instead of the upload form. As an uploader, confirm you can see your own Lead Upload records but not another partner's.
14. **Internal visibility.** As an internal user with the permission set, open the **Lead Uploads** tab and confirm uploads are listed with their counts and status.

## Post Deployment Items

1. **Licensing and site prerequisite.** Experience Cloud users can only create Leads on a license that includes Lead access: **Partner Community** or **Partner Relationship Management**. Customer Community licenses don't include Leads. The current dev org (HTCDEV) has no Partner Community licenses and Digital Experiences isn't enabled, so the feature can't be tested there end to end. Provision a Partner Community license and enable Digital Experiences (Setup → Digital Experiences → Settings) in the target org before testing as an external user.
2. **Assign Beacon - Lead Upload** to the Experience Cloud users who should upload Leads. The easiest way is to add it to their external profile's members, or assign it per user. Assign it to any internal users who need to see the Lead Uploads tab and the Lead Upload field on Lead.
3. **Experience Builder.** Add the **Lead Uploader** component to a page in the partner site, set **Card Title** and **Default Lead Source**, set the page's audience/visibility to the uploading users, and publish the site.
4. **Lead Source value.** Confirm the value used as **Default Lead Source** exists in the Lead Source picklist (for example, add a "Partner Upload" value if the business wants partner lists reported separately).
5. **Lead visibility for internal users.** Uploaded Leads are owned by the uploading partner user. Confirm the partner account's role sits where Beacon's internal users need it, or add a Lead sharing rule (Owner in partner roles → internal role/group) so the right internal teams can see and work these Leads.
6. **Optional Lead Upload page.** If you want the Lead Upload record page to use a Lightning record page, create one and activate it. The Lead Upload Layout is used by default.

## Component Manifest

Github Branch: https://github.com/aaroncrear/BeaconImplementation/tree/Experience-Cloud-Lead-Upload

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | LightningComponentBundle | Lead | leadUploader | Lead Uploader | Created | LWC for Experience Cloud and Lightning pages. Downloads the CSV template, parses and validates the file in the browser, previews it, uploads it to Apex in batches of 200 with a progress bar, and offers an error CSV for failed rows. Settings: Card Title, Default Lead Source. |
| 2 | ApexClass | Lead | LeadUploadController | LeadUploadController | Created | `with sharing` controller for the Lead Uploader (getUploadFields, startUpload, uploadLeads, completeUpload). Enforces the 2,000-row and 200-per-batch limits and runs all DML in user mode. |
| 3 | ApexClass | Lead | LeadUploadControllerTest | LeadUploadControllerTest | Created | Tests for LeadUploadController: full batch, partial failures, default Lead Source, all-failed upload, limits and finished-upload protection. |
| 4 | CustomObject | Lead_Upload__c | Lead_Upload__c | Lead Upload | Created | Tracks each Lead list upload (auto-number LU-00000). Private internal and external sharing. |
| 5 | CustomField | Lead_Upload__c | Status__c | Status | Created | Restricted picklist: In Progress (default), Completed, Completed with Errors, Failed. |
| 6 | CustomField | Lead_Upload__c | File_Name__c | File Name | Created | Text(255). Name of the uploaded CSV file. |
| 7 | CustomField | Lead_Upload__c | Total_Rows__c | Total Rows | Created | Number(5,0). Data rows in the file. |
| 8 | CustomField | Lead_Upload__c | Success_Count__c | Success Count | Created | Number(5,0), default 0. Leads created by the upload. |
| 9 | CustomField | Lead_Upload__c | Error_Count__c | Error Count | Created | Number(5,0), default 0. Rows that failed; set to Total Rows minus Success Count at completion. |
| 10 | CustomField | Lead_Upload__c | Completed_Date__c | Completed Date | Created | Date/Time the upload finished. |
| 11 | ListView | Lead_Upload__c | All | All | Created | All Lead Uploads with file name, status, counts, owner and created date. |
| 12 | Layout | Lead_Upload__c | Lead_Upload__c-Lead Upload Layout | Lead Upload Layout | Created | Read-only Information section (number, file, status, completed date, row counts), System Information section, and Files and Leads related lists. |
| 13 | CustomTab | Lead_Upload__c | Lead_Upload__c | Lead Uploads | Created | Custom object tab for Lead Upload. |
| 14 | CustomField | Lead | Lead_Upload__c | Lead Upload | Created | Lookup to Lead Upload (Set Null on delete); child relationship "Leads". Set on Leads created by the Lead Uploader. |
| 15 | Layout | Lead | Lead-Lead Layout | Lead Layout | Updated | Added Lead Upload (read only) to the System Information section. |
| 16 | PermissionSet | Lead | Beacon_Lead_Upload | Beacon - Lead Upload | Created | No license, so it can be assigned to Experience Cloud and internal users. Lead Read/Create, Read/Edit on uploadable Lead fields and Lead Upload, Lead Upload object Read/Create/Edit and its fields, the Lead Upload tab, and LeadUploadController class access. |
