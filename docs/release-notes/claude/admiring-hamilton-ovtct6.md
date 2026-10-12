# "claude/admiring-hamilton-ovtct6" – Release Notes

## Requirements

- Remove all access to the custom Milestone (Milestones PM) objects and their fields from these two permission sets:
  - Beacon Consulting - Object, Tab, FLS (`Beacon_Consulting_Object_Tab_FLS`)
  - Beacon Salesforce Admin - Object, Tab, FLS (`Beacon_Salesforce_Admin_Object_Tab_FLS`)
- The access called out was `PermissionSetFieldPermissions.Milestone1_Milestone__c.Kickoff__c`. The access to remove also covers the rest of the Milestone objects and their related objects.

## Release Notes

- **Why a separate package is needed.** The permission set files in `unpackaged/` already have no Milestone references, because they were removed in `claude/peaceful-davinci-ocwwbe`. But the Beacon HTCDEV org still grants that access. The Metadata API only changes the permissions a permission set file lists. It does not remove permissions that are missing from the file. So deploying `unpackaged/` again does not revoke anything. The access has to be turned off with explicit `false` values.
- **Added a revoke package at `manifest/destructive/project-management/revoke-access/`.** It is in Metadata API format and has a `package.xml` and one file for each of the two permission sets. Each file sets the following to `false` or `None`:
  - **125 field permissions** across `Milestone1_Milestone__c`, `Milestone1_Project__c`, `Milestone1_Task__c`, `Milestone1_Time__c` and `Milestone1_Expense__c`. This includes `Milestone1_Milestone__c.Kickoff__c`, `Milestone1_Project__c.Kickoff__c` and `Milestone1_Milestone__c.Project_Kickoff_Offset__c`. The list was taken from the `FieldPermissions` records in the Beacon HTCDEV org for each permission set, so it also covers formula and roll-up fields that were never in source.
  - **5 object permissions.** Read, Create, Edit, Delete, View All, Modify All and View All Fields are turned off for the same 5 objects.
  - **1 tab setting.** The `Milestone1_Project__c` tab is set to `None`. It was `DefaultOn`.
- **Other permissions stay the same.** Each file has only the Milestone entries plus the label, description and license the permission set already has. Object, field and tab access for Account, Contact, Lead, Opportunity, Campaign, Account Plans, Action Plans, `Project__c`, `Project_Time__c`, `Project_Team_Member__c` and `Beacon_Feedback__c` is not affected.
- **What was left out:**
  - `Milestone1_Log__c`, `Milestone1_Settings__c` and `Project_Snapshot__c` aren't in the package because neither permission set grants access to them in the org.
  - `Project_Team_Member__c` isn't in the package because the new Project Management app on `Beacon-Custom-PM-App` uses it.
- **No changes to `unpackaged/`.** The source permission sets are already correct.

## Acceptance Criteria

1. Deploy the revoke package to the sandbox:
   `sf project deploy start --metadata-dir manifest/destructive/project-management/revoke-access --target-org <sandbox-alias>`
   In Gearset, deploy the two permission sets from this folder instead.
2. Confirm the deploy succeeds with no component errors.
3. In Setup > Permission Sets, open **Beacon Consulting - Object, Tab, FLS** > Object Settings. Confirm Project, Milestone, Project Task, Time and Expense show **No Access** and all field permissions are unchecked.
4. In the same permission set, open Milestone > Field Permissions. Confirm **Kickoff** has Read and Edit unchecked.
5. In the same permission set, confirm the **Project** (`Milestone1_Project__c`) tab is set to **Not Available**.
6. Repeat steps 3–5 for **Beacon Salesforce Admin - Object, Tab, FLS**.
7. Confirm the other access did not change. In both permission sets, Account, Contact, Lead, Opportunity, Campaign, `Project__c`, `Project_Time__c` and `Project_Team_Member__c` should have the same object and field access as before.
8. Run this query in the sandbox and confirm it returns 0 rows:
   `SELECT Parent.Name, Field FROM FieldPermissions WHERE Parent.Name IN ('Beacon_Consulting_Object_Tab_FLS','Beacon_Salesforce_Admin_Object_Tab_FLS') AND SobjectType IN ('Milestone1_Expense__c','Milestone1_Milestone__c','Milestone1_Project__c','Milestone1_Task__c','Milestone1_Time__c')`
9. Log in as a user who has one of these permission sets and no other Milestone access. Confirm the Project tab and Milestone records can't be opened.

## Post Deployment Items

- **Deploy this before the destructive deploy.** Deploy the revoke package before the `manifest/destructive/project-management/` destructive deploy from `claude/peaceful-davinci-ocwwbe`. If the Milestone objects are deleted first, this package will fail on missing fields. In that case it isn't needed, because deleting the objects also removes their permissions.
- **Check `Project_Team_Member__c` in the destructive manifest.** `destructiveChanges.xml` still lists `Project_Team_Member__c`, but the new Project Management app (`Beacon-Custom-PM-App`) uses that object. Remove it from `destructiveChanges.xml` before running the destructive deploy, or the new object will be deleted.

## Component Manifest

Github Branch: [claude/admiring-hamilton-ovtct6](https://github.com/aaroncrear/BeaconImplementation/tree/claude/admiring-hamilton-ovtct6)

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Permission Set | N/A | Beacon_Consulting_Object_Tab_FLS | Beacon Consulting - Object, Tab, FLS | Updated | Revokes all object, field and tab access to the 5 Milestone1 objects, including `Milestone1_Milestone__c.Kickoff__c`. Deployed from `manifest/destructive/project-management/revoke-access/`. |
| 2 | Permission Set | N/A | Beacon_Salesforce_Admin_Object_Tab_FLS | Beacon Salesforce Admin - Object, Tab, FLS | Updated | Revokes all object, field and tab access to the 5 Milestone1 objects, including `Milestone1_Milestone__c.Kickoff__c`. Deployed from `manifest/destructive/project-management/revoke-access/`. |
| 3 | Deployment Manifest | N/A | manifest/destructive/project-management/revoke-access/package.xml | package.xml | Created | Package manifest for the two permission set revoke files. |
