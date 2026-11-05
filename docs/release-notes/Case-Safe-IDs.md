# "Case-Safe-IDs" – Release Notes

## Requirements

- Users need the 18-character record ID in reports. Standard reports only show the 15-character ID, which is case-sensitive. Excel, VLOOKUPs, and many integration and data-load tools treat IDs as case-insensitive, so two different 15-character IDs can look like the same record.
- Add a case-safe (18-character) ID field to **Accounts, Contacts, Leads, Opportunities, and Campaigns**.
- Give **read-only** access to the new fields to the **Beacon Salesforce Admin** persona permission set only.

## Release Notes

A new formula field, **Case Safe ID** (`Case_Safe_ID__c`), was added to Account, Contact, Lead, Opportunity, and Campaign. Each one uses the formula `CASESAFEID(Id)` and returns Text.

Why it was built this way:

- **Formula field, not a stored text field.** `CASESAFEID(Id)` is calculated when the record is read. It's filled in on every existing and new record right away, with no data backfill and no flow or trigger to maintain. It also can't get out of sync with the real record ID.
- **Same API name and label on all five objects.** Report builders and data-load templates can always look for `Case_Safe_ID__c`, whatever the object.
- **Read-only access.** Formula fields can't be edited. Access was added as Read (`editable` = false) to `Beacon_Salesforce_Admin_Object_Tab_FLS`, the permission set that holds field-level security for the Beacon Salesforce Admin persona. That's the same pattern earlier builds used. No other persona got access in this build.
- **No page layout changes.** The fields are for reporting and exports, so they weren't added to any page layout.

## Acceptance Criteria

1. Deploy the branch to the target org.
2. Go to **Setup → Object Manager** and check each of these objects: **Account, Contact, Lead, Opportunity, Campaign**. On each one, confirm a field named **Case Safe ID** (`Case_Safe_ID__c`) exists, is a Formula (Text) field, and uses `CASESAFEID(Id)`.
3. Go to **Setup → Permission Sets → Beacon Salesforce Admin - Object, Tab, FLS**. For each of the five objects, confirm **Case Safe ID** has Read access and no Edit access.
4. Log in as (or impersonate) a user with the Beacon Salesforce Admin persona. Create a report on each object (for example, *Accounts*, *Contacts & Accounts*, *Leads*, *Opportunities*, *Campaigns*) and add the **Case Safe ID** column.
5. Run each report. Confirm every row shows an 18-character ID. Its first 15 characters should match the record's standard ID (from the URL or the standard ID column).
6. Copy a Case Safe ID from the report and paste it into the browser after `/lightning/r/`. Confirm it opens the correct record.
7. Log in as a user who does **not** have the Beacon Salesforce Admin persona (for example, Beacon Sales). Confirm the **Case Safe ID** field isn't available when building a report.

## Post Deployment Items

None. If other personas need the field later, add Read FLS to their `*_Object_Tab_FLS` permission sets in a follow-up build.

## Component Manifest

Github Branch: [Case-Safe-IDs](https://github.com/aaroncrear/BeaconImplementation/tree/Case-Safe-IDs)

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | CustomField | Account | Case_Safe_ID__c | Case Safe ID | Created | Formula (Text) field: `CASESAFEID(Id)`. Returns the 18-character case-safe Account ID for reports and exports. |
| 2 | CustomField | Contact | Case_Safe_ID__c | Case Safe ID | Created | Formula (Text) field: `CASESAFEID(Id)`. Returns the 18-character case-safe Contact ID for reports and exports. |
| 3 | CustomField | Lead | Case_Safe_ID__c | Case Safe ID | Created | Formula (Text) field: `CASESAFEID(Id)`. Returns the 18-character case-safe Lead ID for reports and exports. |
| 4 | CustomField | Opportunity | Case_Safe_ID__c | Case Safe ID | Created | Formula (Text) field: `CASESAFEID(Id)`. Returns the 18-character case-safe Opportunity ID for reports and exports. |
| 5 | CustomField | Campaign | Case_Safe_ID__c | Case Safe ID | Created | Formula (Text) field: `CASESAFEID(Id)`. Returns the 18-character case-safe Campaign ID for reports and exports. |
| 6 | PermissionSet | N/A | Beacon_Salesforce_Admin_Object_Tab_FLS | Beacon Salesforce Admin - Object, Tab, FLS | Updated | Added Read-only FLS for Account.Case_Safe_ID__c, Contact.Case_Safe_ID__c, Lead.Case_Safe_ID__c, Opportunity.Case_Safe_ID__c, and Campaign.Case_Safe_ID__c. |
