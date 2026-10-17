# "Experience-Cloud-Lead-Upload" – Release Notes

## Requirements

Experience Cloud users (for example, partners) need a self-service way to upload Lead lists of up to 2,000 records, without Data Import Wizard, Data Loader or help from an admin. The business asked for:

1. A page component that Experience Cloud users can use to upload a list of Leads from a file.
2. Support for lists of up to 2,000 records in a single upload.
3. Clear feedback on which rows failed and why, so users can fix them and upload them again.
4. A record of each upload, so internal users can see who uploaded what and which Leads came from each list.
5. Uploaded Leads assigned to a queue rather than left with the partner user who uploaded them.
6. Routing that scales as partners are onboarded: each partner's Leads go to the queue for that partner, worked out from who is uploading, with no code changes per partner.

## Release Notes

**Lead Uploader component.** `leadUploader` is a Lightning Web Component exposed to Experience Builder (`lightningCommunity__Page` / `lightningCommunity__Default`) and to Lightning App Builder (App and Home pages, so internal users can use and test it too). It has two settings: **Card Title** and **Default Lead Source**. The user flow is:

1. **Download Template.** Downloads a CSV whose header row holds the labels of every field the user can create: First Name, Last Name, Company, Title, Email, Phone, Mobile Phone, Website, Street, City, State/Province, Zip/Postal Code, Country, Industry, Lead Source, Employees, Annual Revenue and Description. The list comes from Apex and respects field-level security, so the template never offers a column the user can't fill.
2. **Choose a CSV file.** The file is read and parsed in the browser. The parser handles quoted values, commas and line breaks inside quotes, and the byte-order mark that Excel's "CSV UTF-8" format adds. Columns are matched to fields by label or API name, ignoring case, spaces and punctuation, so both "Zip/Postal Code" and "PostalCode" work. Columns that don't match a field are listed as ignored. The upload is blocked with a clear message if the file isn't a .csv, is over 5 MB, has no data rows, has more than 2,000 rows, is missing a required column, or has two columns that map to the same field.
3. **Preview.** The first 10 rows are shown in a table so the user can check the mapping before uploading.
4. **Upload Leads.** Rows are sent to Apex in batches of 200, one after another. Each batch is its own transaction, so 2,000 rows (10 batches) stay well inside governor limits even with the Lead record-triggered flows running. A progress bar shows how many rows have been processed. Inserts allow partial success, so a bad row doesn't stop the rest of its batch. If a whole batch call fails (for example, a timeout), its rows are recorded as failed and the remaining batches still run.
5. **Results.** A banner shows how many Leads were created and how many rows failed. **Download Errors** downloads a CSV with the file row number, the error message and the original row values, so the user can fix the rows and upload the error file again. **Start Over** clears the component for the next file.

Why this approach: the standard Data Import Wizard isn't available to Experience Cloud users, and a screen flow can't parse a CSV without custom code. Parsing in the browser and sending batches avoids the Apex heap and CPU limits a single 2,000-row transaction would risk. It also avoids storing the raw file before it's validated, and gives the user feedback row by row.

**Partner-based queue routing.** `LeadUploadRouting` decides who owns each upload's Leads, from the uploading user, at the start of the upload:

1. If the user belongs to a partner Account and that Account's **Lead Upload Queue** (`Account.Lead_Upload_Queue__c`) is set, the Leads go to that queue.
2. Otherwise they go to the **Default Queue** on the **Lead Upload Setting** custom metadata record named `Default`. It ships set to the new **Partner Leads** queue. This also covers internal users.
3. If neither is set, the uploading user keeps the Leads.

Onboarding a partner is configuration only. Use the default queue, or create a queue for the partner and put its API name on their Account. The fields hold queue API names (Developer Names) rather than Ids, so they stay valid across sandboxes and production. The route is worked out on the server from the running user and never accepted from the browser, so a partner can't send Leads to another partner's queue. If a configured queue doesn't exist or doesn't support Leads, the upload is blocked before any Lead is created, with a message to contact a Beacon administrator. Leads are never sent somewhere unexpected. The chosen queue is stored on the Lead Upload record (**Assigned Queue**), and every batch of that upload uses it, so a configuration change mid-upload can't split a list. Each Lead is also stamped with **Partner Account** (`Lead.Partner_Account__c`), for reporting by partner and for any future partner-based sharing rule.

**Partner visibility after hand-off.** Partner users can't see Leads owned by a queue, so by default an Experience Cloud uploader gets a manual **Read** share on each Lead they uploaded that went to a queue. They can still see what they submitted but can't edit it. Uncheck **Share With Uploader** on the Lead Upload Setting to hand Leads off completely. No share is created for internal users, because internal Lead sharing is already Public Read/Write/Transfer. Manual shares are removed by Salesforce when a Lead's owner changes. Once the queue assigns a Lead to a rep, the partner loses sight of it unless a sharing rule on Partner Account is added (see Post Deployment Items).

**Why not Lead assignment rules?** HTCDEV has no Lead assignment rules. Salesforce allows only one active rule per object, and that rule also governs web-to-lead and manual Leads. Routing by partner in an assignment rule would need a new rule entry for every partner. Keeping the routing on the partner's Account keeps this feature self-contained. It also means onboarding a partner is a field edit rather than an assignment rule change.

**Required values.** A row must have First Name, Last Name, Company, Title, Email, Website and Lead Source. These match the required fields on the **Lead Layout**, plus First Name (enforced by the `First_Name_Required` validation rule). If **Default Lead Source** is set on the component, it fills in any blank Lead Source, and the Lead Source column becomes optional. The required list is the `REQUIRED_FIELDS` set in `LeadUploadController`. Number fields (Employees, Annual Revenue) accept thousands separators and currency symbols (e.g. `$1,250,000`). Picklist, email, state/country and duplicate-rule checks are left to Salesforce, and any failure comes back as that row's error message.

**LeadUploadController (Apex).** A `with sharing` class with four `@AuraEnabled` methods: `getUploadFields` (template columns), `startUpload` (creates the Lead Upload record and rejects files over 2,000 rows), `uploadLeads` (inserts a batch of up to 200 rows) and `completeUpload` (sets the final status and attaches the error file). Values from the file are checked against the uploader's own object and field permissions. Lead create access is checked, and `Security.stripInaccessible` runs on the file's values. If any field is removed, the batch is rejected rather than silently dropping data. Only the fields in the upload list can be set from the file, and any other key in the request is ignored. Lead Upload records are read in user mode, so users can only work with their own uploads. The Leads are then inserted in system mode with Owner, Partner Account and Lead Upload set by the server, because partner users can't assign records to a queue. The Lead Upload tracking fields are also written in system mode, so uploaders have Read-only access to them and can't change the counts. Lead assignment rules aren't run. `LeadUploadControllerTest` covers a full 200-row batch, mixed success and failure, the default Lead Source, an all-failed upload, the 2,000-row and 200-row-per-batch limits, and rejecting rows once an upload has finished. It also covers routing: a partner Account queue taking priority over the default, the default queue when the partner has none, the uploader keeping Leads when nothing is configured, and a missing queue blocking the upload. HTCDEV has no partner licences, so the tests can't create a real partner user. `LeadUploadRouting` has test-only hooks that stand in for the partner Account and the user type.

**Lead Upload object.** `Lead_Upload__c` (auto-number `LU-00000`) records each upload: **File Name**, **Status** (In Progress, Completed, Completed with Errors, Failed), **Total Rows**, **Success Count**, **Error Count**, **Completed Date**, **Partner Account** and **Assigned Queue**. Success Count is added to as each batch commits. At completion, Error Count is set to Total Rows minus Success Count, so rows from a batch whose call failed outright are still counted. When rows fail, the error CSV is attached to the record as a file named "Lead Upload Errors - LU-xxxxx". An upload that is still **In Progress** later was interrupted, for example because the browser was closed mid-upload. The object is Private (internal and external), so uploaders see only their own uploads, and managers see them through the role hierarchy. It has a tab, an **All** list view and a **Lead Upload Layout** with the details, the Files related list and a Leads related list.

**New Lead fields.** `Lead.Lead_Upload__c` looks up to the upload that created the Lead, and `Lead.Partner_Account__c` looks up to the partner who submitted it (both Set Null on delete). Both were added read only to the **System Information** section of the **Lead Layout**. All ten persona "Object, Tab, FLS" permission sets got Read on both, so internal users can see where an uploaded Lead came from.

**Account routing field.** **Lead Upload Queue** sits in a new **Partner Lead Routing** section on the **Account Layout**. **Beacon Salesforce Admin - Object, Tab, FLS** got Read/Edit on it. No other persona can see or change routing.

**Lead Upload Setting and Partner Leads queue.** `Lead_Upload_Setting__mdt` has one record, `Default`. **Default Queue** = `Partner_Leads` and **Share With Uploader** = checked. The new **Partner Leads** queue (`Partner_Leads`, Lead) is the default destination. It has no members until they're added after deployment.

**Beacon - Lead Upload permission set.** `Beacon_Lead_Upload` grants everything the feature needs:

- Lead Read/Create.
- Read/Edit on the Lead fields the upload can fill: Address, Annual Revenue, Description, Email, Industry, Lead Source, Mobile Phone, Employees, Phone, Title and Website.
- Read on Lead Upload and Partner Account on Lead.
- Lead Upload Read/Create, and Read only on its fields.
- The Lead Upload tab and access to the `LeadUploadController` class.

`LeadUploadRouting` is only called by the controller, so it needs no class access. No user license is set, so it can be assigned to Experience Cloud users as well as internal users. It doesn't grant Lead Edit or Delete. The Lead flows that update a Lead after it's created run in system context and aren't affected.

## Acceptance Criteria

1. **Deployment.** Confirm the deployment succeeds and `LeadUploadControllerTest` passes (Setup → Apex Test Execution).
2. **Permission set.** Open **Beacon - Lead Upload**. Confirm it has no license, has Lead Read/Create (no Edit/Delete), Lead Upload Read/Create (no Edit) with Read-only Lead Upload fields, field permissions on the fields listed above, the Lead Upload tab visible and Apex class access to `LeadUploadController`.
3. **Component placement.** In Experience Builder for the partner site, drag **Lead Uploader** onto a page, set **Default Lead Source** to a valid Lead Source value, and publish. (Internal check: add it to a Lightning App page instead.)
4. **Template.** Log in to the site as an Experience Cloud user who has **Beacon - Lead Upload**. Click **Download Template** and confirm the CSV header lists the fields above.
5. **Happy path.** Fill the template with 5 valid rows and upload it. Confirm the preview shows the rows, the progress bar runs, and the banner reads "5 of 5 Leads created. 0 rows failed." Open the Lead Upload record and confirm Status is **Completed**, Total Rows 5, Success Count 5, Error Count 0, Completed Date populated, and 5 Leads in the Leads related list. Open a Lead and confirm the **Lead Upload** field links back, the owner is the **Partner Leads** queue, and Seniority Level and Account were filled in by the existing Lead flows where they apply.
6. **Default Lead Source.** Upload a file with no Lead Source column. Confirm the upload is allowed and the Leads get the component's Default Lead Source. Remove the Default Lead Source setting, upload the same file again, and confirm it's blocked with "Missing required columns: Lead Source."
7. **Row errors.** Upload a file of 5 rows in which one row has no Company, one has an invalid email, and one has "lots" in Employees. Confirm the banner reads "2 of 5 Leads created. 3 rows failed." Click **Download Errors** and confirm the CSV lists the file row number, a clear error message and the original values for each failed row. Confirm the Lead Upload record is **Completed with Errors** and has the "Lead Upload Errors" file attached.
8. **All rows fail.** Upload a file where every row is missing Last Name. Confirm 0 Leads are created and the Lead Upload status is **Failed**.
9. **2,000 rows.** Upload a file with exactly 2,000 valid rows. Confirm all 2,000 Leads are created, the progress bar steps through 10 batches, and Success Count is 2,000.
10. **Over the limit.** Upload a file with 2,001 rows. Confirm the Upload button stays disabled with a message to split the file.
11. **File checks.** Confirm a non-CSV file, an empty file, a header-only file, a file missing the Email column, and a file with both "Email" and "E-mail" columns are each blocked with a clear message. Confirm an unrecognised column (e.g. "Notes") is listed as ignored and doesn't block the upload.
12. **CSV formats.** Save the template from Excel as **CSV UTF-8** with a Description containing commas, quotes and a line break. Upload it and confirm the Description is stored exactly as entered.
13. **Security.** As an Experience Cloud user without **Beacon - Lead Upload**, confirm the component shows a permission error instead of the upload form. As an uploader, confirm you can see your own Lead Upload records but not another partner's.
14. **Routing: default queue.** As a partner user whose Account has no **Lead Upload Queue**, upload 3 valid rows. Confirm the Lead Upload shows **Assigned Queue** = Partner_Leads and the partner's **Partner Account**, and each Lead is owned by the **Partner Leads** queue and has **Partner Account** set. As the partner user, confirm you can still open the Leads but not edit them.
15. **Routing: partner queue.** Create a second Lead queue (e.g. `Acme_Partner_Leads`), put its API name in **Lead Upload Queue** on the partner's Account, and upload again. Confirm the new Leads are owned by that queue and the earlier Leads are unchanged.
16. **Routing: two partners.** Repeat with a user from a second partner Account that has a different queue (or none). Confirm each partner's Leads land in their own queue, and that neither partner can see the other's Leads.
17. **Routing: misconfigured queue.** Set **Lead Upload Queue** on the partner Account to a name that doesn't exist. Confirm the upload is blocked with "Lead routing isn't set up correctly" naming the queue, and no Leads or Lead Upload record are created. Clear the field afterwards.
18. **Share With Uploader off.** Uncheck **Share With Uploader** on the Default Lead Upload Setting, upload as a partner, and confirm the partner can't see the new Leads. Check it again afterwards.
19. **Internal uploader.** As an internal user, upload a file. Confirm the Leads go to the Default Queue, Partner Account is blank, and no share records are created.
20. **Routing security.** Confirm only users with **Beacon Salesforce Admin - Object, Tab, FLS** can see and edit **Lead Upload Queue** on Account.
21. **Internal visibility.** As an internal user with the permission set, open the **Lead Uploads** tab and confirm uploads are listed with their counts and status.

## Post Deployment Items

1. **Partner Leads queue members.** Add the users or public group who should work partner Leads to the **Partner Leads** queue (Setup → Queues), and set its queue email if wanted.
2. **Per-partner queues (as partners onboard).** For a partner whose Leads should go somewhere other than Partner Leads, create a Lead queue and put its API name in **Lead Upload Queue** on that partner's Account. Partners left blank use the Default Queue. To change the default, edit **Default Queue** on Setup → Custom Metadata Types → Lead Upload Setting → Default.
3. **Licensing and site prerequisite.** Experience Cloud users can only create Leads on a license that includes Lead access: **Partner Community** or **Partner Relationship Management**. Customer Community licenses don't include Leads. The current dev org (HTCDEV) has no Partner Community licenses and Digital Experiences isn't enabled, so the feature can't be tested there end to end. Provision a Partner Community license and enable Digital Experiences (Setup → Digital Experiences → Settings) in the target org before testing as an external user.
4. **Assign Beacon - Lead Upload** to the Experience Cloud users who should upload Leads. The easiest way is to add it to their external profile's members, or assign it per user. Assign it to any internal users who need to see the Lead Uploads tab and the Lead Upload field on Lead.
5. **Experience Builder.** Add the **Lead Uploader** component to a page in the partner site, set **Card Title** and **Default Lead Source**, set the page's audience/visibility to the uploading users, and publish the site.
6. **Lead Source value.** Confirm the value used as **Default Lead Source** exists in the Lead Source picklist (for example, add a "Partner Upload" value if the business wants partner lists reported separately).
7. **Partner visibility after assignment (decision needed).** Partners keep Read access to their Leads only while the Leads are queue-owned. If partners should keep seeing their Leads after a rep takes ownership, add a criteria-based Lead sharing rule per partner (Partner Account equals the partner's Account → that partner's role group, Read Only).
8. **Optional Lead Upload page.** If you want the Lead Upload record page to use a Lightning record page, create one and activate it. The Lead Upload Layout is used by default.

## Component Manifest

Github Branch: https://github.com/aaroncrear/BeaconImplementation/tree/Experience-Cloud-Lead-Upload

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | LightningComponentBundle | Lead | leadUploader | Lead Uploader | Created | LWC for Experience Cloud and Lightning pages. Downloads the CSV template, parses and validates the file in the browser, previews it, uploads it to Apex in batches of 200 with a progress bar, and offers an error CSV for failed rows. Settings: Card Title, Default Lead Source. |
| 2 | ApexClass | Lead | LeadUploadController | LeadUploadController | Created | `with sharing` controller for the Lead Uploader (getUploadFields, startUpload, uploadLeads, completeUpload). Enforces the 2,000-row and 200-per-batch limits, checks the uploader's object and field access on file values, and sets owner, partner and counters on the server. |
| 3 | ApexClass | Lead | LeadUploadControllerTest | LeadUploadControllerTest | Created | Tests for LeadUploadController: full batch, partial failures, default Lead Source, all-failed upload, limits and finished-upload protection. |
| 4 | CustomObject | Lead_Upload__c | Lead_Upload__c | Lead Upload | Created | Tracks each Lead list upload (auto-number LU-00000). Private internal and external sharing. |
| 5 | CustomField | Lead_Upload__c | Status__c | Status | Created | Restricted picklist: In Progress (default), Completed, Completed with Errors, Failed. |
| 6 | CustomField | Lead_Upload__c | File_Name__c | File Name | Created | Text(255). Name of the uploaded CSV file. |
| 7 | CustomField | Lead_Upload__c | Total_Rows__c | Total Rows | Created | Number(5,0). Data rows in the file. |
| 8 | CustomField | Lead_Upload__c | Success_Count__c | Success Count | Created | Number(5,0), default 0. Leads created by the upload. |
| 9 | CustomField | Lead_Upload__c | Error_Count__c | Error Count | Created | Number(5,0), default 0. Rows that failed; set to Total Rows minus Success Count at completion. |
| 10 | CustomField | Lead_Upload__c | Completed_Date__c | Completed Date | Created | Date/Time the upload finished. |
| 11 | ListView | Lead_Upload__c | All | All | Created | All Lead Uploads with file name, status, counts, owner and created date. |
| 12 | Layout | Lead_Upload__c | Lead_Upload__c-Lead Upload Layout | Lead Upload Layout | Created | Read-only Information section (number, file, status, completed date, row counts, partner account, assigned queue), System Information section, and Files and Leads related lists. |
| 13 | CustomTab | Lead_Upload__c | Lead_Upload__c | Lead Uploads | Created | Custom object tab for Lead Upload. |
| 14 | CustomField | Lead | Lead_Upload__c | Lead Upload | Created | Lookup to Lead Upload (Set Null on delete); child relationship "Leads". Set on Leads created by the Lead Uploader. |
| 15 | Layout | Lead | Lead-Lead Layout | Lead Layout | Updated | Added Lead Upload and Partner Account (read only) to the System Information section. |
| 16 | PermissionSet | Lead | Beacon_Lead_Upload | Beacon - Lead Upload | Created | No license, so it can be assigned to Experience Cloud and internal users. Lead Read/Create, Read/Edit on uploadable Lead fields, Read on Lead Upload and Partner Account, Lead Upload object Read/Create with Read-only fields, the Lead Upload tab, and LeadUploadController class access. |
| 17 | ApexClass | Lead | LeadUploadRouting | LeadUploadRouting | Created | `without sharing` routing service: resolves the queue from the partner Account's Lead Upload Queue, then the Default Lead Upload Setting, then the uploader; validates the queue; shares queue-owned Leads back to external uploaders. |
| 18 | CustomField | Account | Lead_Upload_Queue__c | Lead Upload Queue | Created | Text(80). API name of the Lead queue that receives this partner's uploaded Leads; blank uses the default queue. |
| 19 | Layout | Account | Account-Account Layout | Account Layout | Updated | Added a Partner Lead Routing section with Lead Upload Queue. |
| 20 | CustomField | Lead | Partner_Account__c | Partner Account | Created | Lookup to Account (Set Null on delete); child relationship "Partner Leads". The partner that uploaded the Lead. |
| 21 | CustomField | Lead_Upload__c | Partner_Account__c | Partner Account | Created | Lookup to Account (Set Null on delete); child relationship "Lead Uploads". The uploading user's partner Account. |
| 22 | CustomField | Lead_Upload__c | Assigned_Queue__c | Assigned Queue | Created | Text(80). Queue the upload's Leads were assigned to, fixed when the upload starts; blank = uploader owns them. |
| 23 | CustomObject | Lead_Upload_Setting__mdt | Lead_Upload_Setting__mdt | Lead Upload Setting | Created | Custom metadata type for Lead Uploader settings. |
| 24 | CustomField | Lead_Upload_Setting__mdt | Default_Queue__c | Default Queue | Created | Text(80). Queue API name used when the partner Account has no queue, and for internal uploaders. |
| 25 | CustomField | Lead_Upload_Setting__mdt | Share_With_Uploader__c | Share With Uploader | Created | Checkbox (default checked). Gives external uploaders Read access to their queue-owned Leads. |
| 26 | CustomMetadata | Lead_Upload_Setting__mdt | Lead_Upload_Setting.Default | Default | Created | Default Queue = Partner_Leads; Share With Uploader = true. |
| 27 | Queue | Lead | Partner_Leads | Partner Leads | Created | Default Lead queue for uploaded partner Leads. Members are added after deployment. |
| 28 | PermissionSet | Lead | Beacon_Salesforce_Admin_Object_Tab_FLS | Beacon Salesforce Admin - Object, Tab, FLS | Updated | Added Read/Edit on Account Lead Upload Queue, and Read on Lead Lead Upload and Partner Account. |
| 29 | PermissionSet | Lead | Beacon_Consulting_Object_Tab_FLS | Beacon Consulting - Object, Tab, FLS | Updated | Added Read on Lead Lead Upload and Partner Account. |
| 30 | PermissionSet | Lead | Beacon_Customer_Success_Object_Tab_FLS | Beacon Customer Success - Object, Tab, FLS | Updated | Added Read on Lead Lead Upload and Partner Account. |
| 31 | PermissionSet | Lead | Beacon_Executive_Object_Tab_FLS | Beacon Executive - Object, Tab, FLS | Updated | Added Read on Lead Lead Upload and Partner Account. |
| 32 | PermissionSet | Lead | Beacon_Finance_Object_Tab_FLS | Beacon Finance - Object, Tab, FLS | Updated | Added Read on Lead Lead Upload and Partner Account. |
| 33 | PermissionSet | Lead | Beacon_Marketing_Object_Tab_FLS | Beacon Marketing - Object, Tab, FLS | Updated | Added Read on Lead Lead Upload and Partner Account. |
| 34 | PermissionSet | Lead | Beacon_Product_Object_Tab_FLS | Beacon Product - Object, Tab, FLS | Updated | Added Read on Lead Lead Upload and Partner Account. |
| 35 | PermissionSet | Lead | Beacon_ResOps_Object_Tab_FLS | Beacon ResOps - Object, Tab, FLS | Updated | Added Read on Lead Lead Upload and Partner Account. |
| 36 | PermissionSet | Lead | Beacon_Sales_Object_Tab_FLS | Beacon Sales - Object, Tab, FLS | Updated | Added Read on Lead Lead Upload and Partner Account. |
| 37 | PermissionSet | Lead | Beacon_Tech_Object_Tab_FLS | Beacon Tech - Object, Tab, FLS | Updated | Added Read on Lead Lead Upload and Partner Account. |
