# "Case-Safe-IDs" – Release Notes

## Requirements

- Users need the 18-character record ID in reports. Standard reports only show the 15-character ID, which is case-sensitive. Excel, VLOOKUPs, and many integration and data-load tools treat IDs as case-insensitive, so two different 15-character IDs can look like the same record.
- Add a case-safe (18-character) ID field to **Accounts, Contacts, Leads, Opportunities, Campaigns, Opportunity Contact Roles, Opportunity Team Members, Account Team Members, and Campaign Members**.
- Give **read-only** access to the new fields to the **Beacon Salesforce Admin** persona permission set only.

## Release Notes

A new formula field was added to each of nine objects. Each one uses the formula `CASESAFEID(Id)` and returns Text. Seven are deployed with this branch. The two team member fields are created manually after deployment (see Post Deployment Items):

| Object | Label | API Name |
|--------|-------|----------|
| Account | Account CaseSafeId | `Account_CaseSafeId__c` |
| Contact | Contact CaseSafeId | `Contact_CaseSafeId__c` |
| Lead | Lead CaseSafeId | `Lead_CaseSafeId__c` |
| Opportunity | Opportunity CaseSafeId | `Opportunity_CaseSafeId__c` |
| Campaign | Campaign CaseSafeId | `Campaign_CaseSafeId__c` |
| Opportunity Contact Role | Opportunity Contact Role CaseSafeId | `Opportunity_Contact_Role_CaseSafeId__c` |
| Opportunity Team Member | Opportunity Team Member CaseSafeId | `Opportunity_Team_Member_CaseSafeId__c` (manual) |
| Account Team Member | Account Team Member CaseSafeId | `Account_Team_Member_CaseSafeId__c` (manual) |
| Campaign Member | Campaign Member CaseSafeId | `Campaign_Member_CaseSafeId__c` |

Why it was built this way:

- **Formula field, not a stored text field.** `CASESAFEID(Id)` is calculated when the record is read. It's filled in on every existing and new record right away, with no data backfill and no flow or trigger to maintain. It also can't get out of sync with the real record ID.
- **Object name in every label and API name (`<Object> CaseSafeId`).** Reports that join objects (for example, Opportunities with Contact Roles) show several of these columns side by side. Putting the object name in the label makes it clear which record's ID each column holds.
- **Read-only access.** Formula fields can't be edited. Access was added as Read (`editable` = false) to `Beacon_Salesforce_Admin_Object_Tab_FLS`, the permission set that holds field-level security for the Beacon Salesforce Admin persona. That's the same pattern earlier builds used. No other persona got access in this build.
- **Junction objects included.** Opportunity Contact Role, Opportunity Team Member, Account Team Member, and Campaign Member link records together. Their IDs are needed when updating or deleting those links with data-load tools, so they got the same field.
- **Team member fields are created manually.** Gearset doesn't list the AccountTeamMember or OpportunityTeamMember fields in its comparison, so they can't be deployed with it. Account Teams and Team Selling are enabled in HTCDEV, UAT, and Prod, and both objects allow custom fields, so the org isn't the problem. When the permission set referenced these fields without them, the whole deployment failed (`no CustomField named AccountTeamMember.Account_Team_Member_CaseSafeId__c found`). The two fields and their permission set access were taken out of the branch so the other seven deploy cleanly. They're created by hand in Setup after deployment.
- **No page layout changes.** The fields are for reporting and exports, so they weren't added to any page layout.

## Acceptance Criteria

1. Deploy the branch to the target org, then complete the Post Deployment Items.
2. Go to **Setup → Object Manager** and check each of these objects: **Account, Contact, Lead, Opportunity, Campaign, Opportunity Contact Role, Opportunity Team Member, Account Team Member, Campaign Member**. On each one, confirm the field from the Release Notes table exists with that label and API name (for example, **Account CaseSafeId** / `Account_CaseSafeId__c`), is a Formula (Text) field, and uses `CASESAFEID(Id)`.
3. Go to **Setup → Permission Sets → Beacon Salesforce Admin - Object, Tab, FLS**. For each of the nine objects, confirm that object's **CaseSafeId** field has Read access and no Edit access.
4. Log in as (or impersonate) a user with the Beacon Salesforce Admin persona. Create a report on each object (for example, *Accounts*, *Contacts & Accounts*, *Leads*, *Opportunities*, *Campaigns*, *Opportunities with Contact Roles*, *Opportunities with Opportunity Teams*, *Account Teams*, *Campaigns with Campaign Members*) and add the `<Object> CaseSafeId` column. On reports with more than one object, confirm a CaseSafeId column can be added for each object, and that each column is clearly labeled with its object name.
5. Run each report. Confirm every row shows an 18-character ID. Its first 15 characters should match the record's standard ID (from the URL or the standard ID column).
6. Copy a CaseSafeId value from the report and paste it into the browser after `/lightning/r/`. Confirm it opens the correct record.
7. Log in as a user who does **not** have the Beacon Salesforce Admin persona (for example, Beacon Sales). Confirm the **CaseSafeId** fields aren't available when building a report.

## Post Deployment Items

Gearset can't deploy these two fields, so create them by hand in each target org (HTCDEV, UAT, Prod):

1. Go to **Setup → Object Manager → Account Team Member → Fields & Relationships → New**.
2. Choose **Formula**, then click **Next**.
3. Enter **Field Label** `Account Team Member CaseSafeId`. Confirm **Field Name** fills in as `Account_Team_Member_CaseSafeId`. Choose return type **Text**, then click **Next**.
4. Enter the formula `CASESAFEID(Id)`. Click **Check Syntax**, then **Next**.
5. Enter **Description**: `18-character case-safe version of the Account Team Member record ID. Used in reports and exports, where the standard ID field only shows the 15-character case-sensitive ID.` Enter **Help Text**: `18-character case-safe record ID. Use this ID in reports, exports, and data loads.` Click **Next**.
6. On the field-level security step, leave all profiles unchecked and click **Next**. Don't add the field to any page layout, then click **Save**.
7. Repeat steps 1–6 on **Opportunity Team Member**, using label `Opportunity Team Member CaseSafeId` (Field Name `Opportunity_Team_Member_CaseSafeId`). Use "Opportunity Team Member" in the description.
8. Go to **Setup → Permission Sets → Beacon Salesforce Admin - Object, Tab, FLS → Object Settings**.
9. Open **Account Team Members**, click **Edit**, check **Read Access** (not Edit) for **Account Team Member CaseSafeId**, and click **Save**.
10. Open **Opportunity Team Members**, click **Edit**, check **Read Access** (not Edit) for **Opportunity Team Member CaseSafeId**, and click **Save**.

If other personas need these fields later, add Read FLS to their `*_Object_Tab_FLS` permission sets in a follow-up build.

## Component Manifest

Github Branch: [Case-Safe-IDs](https://github.com/aaroncrear/BeaconImplementation/tree/Case-Safe-IDs)

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | CustomField | Account | Account_CaseSafeId__c | Account CaseSafeId | Created | Formula (Text) field: `CASESAFEID(Id)`. Returns the 18-character case-safe Account ID for reports and exports. |
| 2 | CustomField | Contact | Contact_CaseSafeId__c | Contact CaseSafeId | Created | Formula (Text) field: `CASESAFEID(Id)`. Returns the 18-character case-safe Contact ID for reports and exports. |
| 3 | CustomField | Lead | Lead_CaseSafeId__c | Lead CaseSafeId | Created | Formula (Text) field: `CASESAFEID(Id)`. Returns the 18-character case-safe Lead ID for reports and exports. |
| 4 | CustomField | Opportunity | Opportunity_CaseSafeId__c | Opportunity CaseSafeId | Created | Formula (Text) field: `CASESAFEID(Id)`. Returns the 18-character case-safe Opportunity ID for reports and exports. |
| 5 | CustomField | Campaign | Campaign_CaseSafeId__c | Campaign CaseSafeId | Created | Formula (Text) field: `CASESAFEID(Id)`. Returns the 18-character case-safe Campaign ID for reports and exports. |
| 6 | CustomField | OpportunityContactRole | Opportunity_Contact_Role_CaseSafeId__c | Opportunity Contact Role CaseSafeId | Created | Formula (Text) field: `CASESAFEID(Id)`. Returns the 18-character case-safe Opportunity Contact Role ID for reports and exports. |
| 7 | CustomField | CampaignMember | Campaign_Member_CaseSafeId__c | Campaign Member CaseSafeId | Created | Formula (Text) field: `CASESAFEID(Id)`. Returns the 18-character case-safe Campaign Member ID for reports and exports. |
| 8 | PermissionSet | N/A | Beacon_Salesforce_Admin_Object_Tab_FLS | Beacon Salesforce Admin - Object, Tab, FLS | Updated | Added Read-only FLS for Account.Account_CaseSafeId__c, Contact.Contact_CaseSafeId__c, Lead.Lead_CaseSafeId__c, Opportunity.Opportunity_CaseSafeId__c, Campaign.Campaign_CaseSafeId__c, OpportunityContactRole.Opportunity_Contact_Role_CaseSafeId__c, and CampaignMember.Campaign_Member_CaseSafeId__c. (FLS for the two manual team member fields is set in Post Deployment Items.) |
