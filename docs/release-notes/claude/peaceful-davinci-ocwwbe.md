# "claude/peaceful-davinci-ocwwbe" – Release Notes

## Requirements

- Remove the Project Management build from the Beacon org and from source control. That build is the Milestones PM objects (Project, Milestone, Project Task, Time, Expense, Log, Milestone1 Settings) plus Project Snapshot, Project Team Member, their tabs, layouts and Beacon Lightning record pages.
- Provide a destructive change set that can be deployed to the sandbox to delete the previous build.
- Clear the way for a new Project Management app to be built from scratch in a follow-up build.

## Release Notes

- **Deleted all Project Management metadata from `unpackaged/`.** This covers 9 custom objects (with all their fields, list views, validation rules and page layouts), 5 custom tabs and 3 Lightning record pages.
- **Removed every reference to the deleted components from profiles and permission sets.** This covers object, field and tab permissions in 4 permission sets, and page layout assignments and tab visibility in 24 profiles. Without this, a later full deploy from this repo would fail on missing components.
- **Added a destructive manifest at `manifest/destructive/project-management/`.** It is split into two phases because a custom object can't be deleted while a tab or Lightning page still points at it:
  - `destructiveChangesPre.xml` deletes the Lightning record pages and custom tabs first.
  - `destructiveChanges.xml` then deletes the custom objects in the same deployment.
- **Checked the Beacon HTCDEV org before deleting.** No Apex classes, triggers, Visualforce pages, static resources, flows, reports, queues or Lightning apps depend on these objects, so only the components listed below need to be deleted.

## Acceptance Criteria

1. Deploy the destructive manifest to the sandbox:
   `sf project deploy start --manifest manifest/destructive/project-management/package.xml --pre-destructive-changes manifest/destructive/project-management/destructiveChangesPre.xml --post-destructive-changes manifest/destructive/project-management/destructiveChanges.xml --target-org <sandbox-alias>`
   In Gearset, compare the org against this branch and select the deleted items listed in the Component Manifest instead.
2. Confirm the deploy succeeds with no component errors.
3. In Setup > Object Manager, confirm that Project, Milestone, Project Task, Time, Expense, Log, Project Snapshot and Project Team Member no longer appear.
4. In Setup > Custom Settings, confirm Milestone1 Settings is gone.
5. In Setup > Tabs, confirm there are no tabs for Project, Milestone, Project Task, Time or Expense.
6. In Setup > Lightning App Builder, confirm Beacon Project Record Page, Beacon Project Task Record Page and Beason Milestone Record Page are gone.
7. Open the Beacon Consulting Object Tab FLS and Beacon Salesforce Admin Object Tab FLS permission sets. Confirm the deleted objects no longer appear under Object Settings.
8. Do a check-only deploy of `unpackaged/` to the sandbox and confirm it validates with no missing-component errors.

## Post Deployment Items

- **Purge deleted objects.** Deleted custom objects stay in Setup > Object Manager > Deleted Objects for 15 days and still count against custom object limits. If the new Project Management app reuses any of these API names (such as `Project_Team_Member__c`), purge (Erase) the deleted objects first.
- **Back up record data first.** The deletion removes all Project Management data in the org. The Beacon HTCDEV org had 1 Project record at the time of the check. Export it first if it needs to be kept.
- **Lightning page in use.** If the deploy fails because a Lightning record page is still in use, remove its activation in Lightning App Builder and rerun the deploy.

## Component Manifest

Github Branch: [claude/peaceful-davinci-ocwwbe](https://github.com/aaroncrear/BeaconImplementation/tree/claude/peaceful-davinci-ocwwbe)

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Custom Object | Milestone1_Project__c | Milestone1_Project__c | Project | Deleted | Top-level project record from the Milestones PM build. The object, its fields, list views, validation rules and page layout are all deleted. |
| 2 | Custom Object | Milestone1_Milestone__c | Milestone1_Milestone__c | Milestone | Deleted | Project milestones, with roll-ups of task hours and expenses. The object, its fields, list views, validation rules and page layout are all deleted. |
| 3 | Custom Object | Milestone1_Task__c | Milestone1_Task__c | Project Task | Deleted | Tasks under a milestone. The object, its fields, list views, validation rules and page layout are all deleted. |
| 4 | Custom Object | Milestone1_Time__c | Milestone1_Time__c | Time | Deleted | Time logged against a project task. The object, its fields, list views, validation rules and page layout are all deleted. |
| 5 | Custom Object | Milestone1_Expense__c | Milestone1_Expense__c | Expense | Deleted | Expenses logged against a project task. The object, its fields, list views, validation rules and page layout are all deleted. |
| 6 | Custom Object | Milestone1_Log__c | Milestone1_Log__c | Log | Deleted | Activity log for projects, milestones and tasks. The object, its fields, list views, validation rules and page layout are all deleted. |
| 7 | Custom Object | Milestone1_Settings__c | Milestone1_Settings__c | Milestone1 Settings | Deleted | Hierarchy custom setting for the Milestones PM build. The object, its fields, list views, validation rules and page layout are all deleted. |
| 8 | Custom Object | Project_Snapshot__c | Project_Snapshot__c | Project Snapshot | Deleted | Point-in-time snapshot of project totals. The object, its fields, list views, validation rules and page layout are all deleted. |
| 9 | Custom Object | Project_Team_Member__c | Project_Team_Member__c | Project Team Member | Deleted | Links users to a project with a role. The object, its fields, list views, validation rules and page layout are all deleted. |
| 10 | Custom Tab | Milestone1_Project__c | Milestone1_Project__c | Project | Deleted | Object tab for the deleted object. |
| 11 | Custom Tab | Milestone1_Milestone__c | Milestone1_Milestone__c | Milestone | Deleted | Object tab for the deleted object. |
| 12 | Custom Tab | Milestone1_Task__c | Milestone1_Task__c | Project Task | Deleted | Object tab for the deleted object. |
| 13 | Custom Tab | Milestone1_Time__c | Milestone1_Time__c | Time | Deleted | Object tab for the deleted object. |
| 14 | Custom Tab | Milestone1_Expense__c | Milestone1_Expense__c | Expense | Deleted | Object tab for the deleted object. |
| 15 | Lightning Record Page | Milestone1_Project__c | Beacon_Project_Record_Page | Beacon Project Record Page | Deleted | Lightning record page for the deleted object. |
| 16 | Lightning Record Page | Milestone1_Task__c | Beacon_Project_Task_Record_Page | Beacon Project Task Record Page | Deleted | Lightning record page for the deleted object. |
| 17 | Lightning Record Page | Milestone1_Milestone__c | Beason_Milestone_Record_Page | Beason Milestone Record Page | Deleted | Lightning record page for the deleted object. |
| 18 | Permission Set | N/A | Beacon_Consulting_Object_Tab_FLS | Beacon Consulting Object Tab FLS | Updated | Removed object, field and tab permissions for the deleted objects. |
| 19 | Permission Set | N/A | Beacon_Salesforce_Admin_Object_Tab_FLS | Beacon Salesforce Admin Object Tab FLS | Updated | Removed object, field and tab permissions for the deleted objects. |
| 20 | Permission Set | N/A | sfdcInternalInt__sfdc_a360_sfcrm_data_extract | sfdc_a360_sfcrm_data_extract | Updated | Removed object, field and tab permissions for the deleted objects. |
| 21 | Permission Set | N/A | sfdcInternalInt__sfdc_slack | sfdc_slack | Updated | Removed object, field and tab permissions for the deleted objects. |
| 22 | Profile | N/A | Admin | System Administrator | Updated | Removed page layout assignments and tab visibility for the deleted objects. |
| 23 | Profile | N/A | Analytics Cloud Integration User | Analytics Cloud Integration User | Updated | Removed page layout assignments and tab visibility for the deleted objects. |
| 24 | Profile | N/A | Analytics Cloud Security User | Analytics Cloud Security User | Updated | Removed page layout assignments and tab visibility for the deleted objects. |
| 25 | Profile | N/A | CPQ Integration User | CPQ Integration User | Updated | Removed page layout assignments and tab visibility for the deleted objects. |
| 26 | Profile | N/A | Chatter External User | Chatter External User | Updated | Removed page layout assignments and tab visibility for the deleted objects. |
| 27 | Profile | N/A | Chatter Free User | Chatter Free User | Updated | Removed page layout assignments and tab visibility for the deleted objects. |
| 28 | Profile | N/A | Chatter Moderator User | Chatter Moderator User | Updated | Removed page layout assignments and tab visibility for the deleted objects. |
| 29 | Profile | N/A | ContractManager | Contract Manager | Updated | Removed page layout assignments and tab visibility for the deleted objects. |
| 30 | Profile | N/A | Einstein Agent User | Einstein Agent User | Updated | Removed page layout assignments and tab visibility for the deleted objects. |
| 31 | Profile | N/A | End User | End User | Updated | Removed page layout assignments and tab visibility for the deleted objects. |
| 32 | Profile | N/A | Executive Sponsor | Executive Sponsor | Updated | Removed page layout assignments and tab visibility for the deleted objects. |
| 33 | Profile | N/A | External Apps Login User | External Apps Login User | Updated | Removed page layout assignments and tab visibility for the deleted objects. |
| 34 | Profile | N/A | External Einstein Agent User | External Einstein Agent User | Updated | Removed page layout assignments and tab visibility for the deleted objects. |
| 35 | Profile | N/A | Guest License User | Guest License User | Updated | Removed page layout assignments and tab visibility for the deleted objects. |
| 36 | Profile | N/A | Identity User | Identity User | Updated | Removed page layout assignments and tab visibility for the deleted objects. |
| 37 | Profile | N/A | MarketingProfile | Marketing User | Updated | Removed page layout assignments and tab visibility for the deleted objects. |
| 38 | Profile | N/A | Minimum Access - API Only Integrations | Minimum Access - API Only Integrations | Updated | Removed page layout assignments and tab visibility for the deleted objects. |
| 39 | Profile | N/A | Minimum Access - Salesforce | Minimum Access - Salesforce | Updated | Removed page layout assignments and tab visibility for the deleted objects. |
| 40 | Profile | N/A | Read Only | Read Only | Updated | Removed page layout assignments and tab visibility for the deleted objects. |
| 41 | Profile | N/A | Sales Insights Integration User | Sales Insights Integration User | Updated | Removed page layout assignments and tab visibility for the deleted objects. |
| 42 | Profile | N/A | Salesforce API Only System Integrations | Salesforce API Only System Integrations | Updated | Removed page layout assignments and tab visibility for the deleted objects. |
| 43 | Profile | N/A | SalesforceIQ Integration User | SalesforceIQ Integration User | Updated | Removed page layout assignments and tab visibility for the deleted objects. |
| 44 | Profile | N/A | SolutionManager | Solution Manager | Updated | Removed page layout assignments and tab visibility for the deleted objects. |
| 45 | Profile | N/A | Standard | Standard User | Updated | Removed page layout assignments and tab visibility for the deleted objects. |
| 46 | Deployment Manifest | N/A | manifest/destructive/project-management/package.xml | package.xml | Created | Empty package used with the destructive deploy. |
| 47 | Deployment Manifest | N/A | manifest/destructive/project-management/destructiveChangesPre.xml | destructiveChangesPre.xml | Created | Deletes the Lightning record pages and custom tabs first. |
| 48 | Deployment Manifest | N/A | manifest/destructive/project-management/destructiveChanges.xml | destructiveChanges.xml | Created | Deletes the 9 custom objects after the pages and tabs are gone. |
