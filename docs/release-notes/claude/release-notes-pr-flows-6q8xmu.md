# "claude/release-notes-pr-flows-6q8xmu" – Release Notes

## Requirements

Reps were continuing to work Contacts and Leads that should no longer be engaged — records
marked Blacklisted, Deceased, or that have both opted out of email and asked not to be called.
The business needs these records automatically flagged with a "Do Not Engage" status the moment
they're saved in that state, without relying on reps to remember to update the status manually.

Separately, the team needed a way to capture a secondary email address on Contacts and Leads, and
a Department picklist on Leads, along with tightening a handful of Account and Lead layout fields
(Type, Website, Phone, Industry on Account; Email, Website on Lead) to Required so reps can't save
incomplete records.

## Release Notes

Added two record-triggered Before-Save flows — `Contact - On Update - Before Save` and
`Lead - On Update - Before Save` — that run on every Contact/Lead update. Each flow checks whether
the record is `Blacklisted__c = true`, `Deceased__c = true`, or (`DoNotCall = true` AND
`HasOptedOutOfEmail = true`), and if so sets the status field (`Contact_Status__c` on Contact,
`Status` on Lead) to `"Do Not Engage"`. Both flows use `RecordBeforeSave` (fast-field-update) triggers
rather than an after-save flow or Apex trigger, since the only work being done is a field update on
the triggering record itself — this avoids an extra DML statement and keeps the automation as
lightweight as possible. `doesRequireRecordChangedToMeetCriteria` is set so the flow only fires when
one of the entry-criteria fields actually changes, not on every unrelated edit.

Supporting changes deployed alongside the flows:
- Added `Second_Email__c` (Email type) to both Contact and Lead, for capturing a secondary email
  address, and surfaced it on the Contact and Lead page layouts.
- Added `Department__c` (restricted picklist, currently seeded with a `Placeholder` value pending
  the real value set) to Lead, and surfaced it on the Lead page layout.
- Added `Linkedin_Profile__c` to the Contact page layout (field already existed; this only exposes
  it on the layout).
- Marked `Type`, `Website`, `Phone`, and `Industry` as Required on the Account layout, and `Email`
  and `Website` as Required on the Lead layout, so these can no longer be saved blank.
- Updated the Account and Lead layouts' excluded quick-action buttons (Data.com Clean/Company
  Hierarchy/Account Insights, Open Slack Record Channel) to match current org configuration.
- Granted Read (not Edit) access to `Lead.Department__c` and `Lead.Second_Email__c` on the four
  `sfdcInternalInt__*` integration permission sets (`sfdc_a360`, `sfdc_a360_sfcrm_data_extract`,
  `sfdc_activityplatform`, `sfdc_slack`) so those existing Lead sync integrations don't start
  failing on FLS for the two new fields.

## Acceptance Criteria

1. On a Contact, set `Blacklisted__c = true` and save — confirm `Contact_Status__c` becomes
   `Do Not Engage`.
2. On a Contact, set `Deceased__c = true` and save — confirm `Contact_Status__c` becomes
   `Do Not Engage`.
3. On a Contact, set only `HasOptedOutOfEmail = true` (Do Not Call left false) and save — confirm
   `Contact_Status__c` is NOT changed (the flow requires both DNC and opted-out-of-email together).
4. On a Contact, set both `DoNotCall = true` and `HasOptedOutOfEmail = true` and save — confirm
   `Contact_Status__c` becomes `Do Not Engage`.
5. Repeat steps 1–4 on a Lead, confirming the `Status` field becomes `Do Not Engage` under the same
   conditions.
6. Confirm `Second_Email__c` is visible and editable on the Contact and Lead page layouts, and
   accepts a valid email address.
7. Confirm `Department__c` is visible and editable on the Lead page layout, and shows the
   `Placeholder` picklist value.
8. Confirm `Linkedin_Profile__c` is visible on the Contact page layout.
9. Confirm the Account layout blocks save with a blank `Type`, `Website`, `Phone`, or `Industry`.
10. Confirm the Lead layout blocks save with a blank `Email` or `Website`.
11. As a user assigned one of the four `sfdcInternalInt__*` permission sets updated above, confirm
    `Lead.Department__c` and `Lead.Second_Email__c` are readable (not editable) and that existing
    Lead sync/integration flows relying on those permission sets are not throwing new FLS errors.

## Post Deployment Items

- Replace the `Placeholder` value on `Lead.Department__c` with the real department picklist values
  once the business finalizes the list.
- Deployment was already completed to the org via Gearset prior to this release notes write-up;
  no further deployment action is needed.

## Component Manifest

Github Branch: https://github.com/aaroncrear/beaconimplementation/tree/claude/release-notes-pr-flows-6q8xmu

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Flow | Contact | Contact_On_Update_Before_Save | Contact - On Update - Before Save | Created | Before-save flow that sets `Contact_Status__c` to "Do Not Engage" when the Contact is Blacklisted, Deceased, or both Do Not Call and opted out of email. |
| 2 | Flow | Lead | Lead_On_Update_Before_Save | Lead - On Update - Before Save | Created | Before-save flow that sets `Status` to "Do Not Engage" when the Lead is Blacklisted, Deceased, or both Do Not Call and opted out of email. |
| 3 | Field | Contact | Second_Email__c | Second Email | Created | New Email-type field for capturing a secondary Contact email address. |
| 4 | Field | Lead | Second_Email__c | Second Email | Created | New Email-type field for capturing a secondary Lead email address. |
| 5 | Field | Lead | Department__c | Department | Created | New restricted picklist field (currently seeded with a placeholder value) to track the Lead's department. |
| 6 | Layout | Account | Account-Account Layout | Account Layout | Updated | Marked Type, Website, Phone, and Industry as Required; updated excluded quick-action buttons. |
| 7 | Layout | Contact | Contact-Contact Layout | Contact Layout | Updated | Added `Second_Email__c` and `Linkedin_Profile__c` to the page layout. |
| 8 | Layout | Lead | Lead-Lead Layout | Lead Layout | Updated | Added `Department__c` and `Second_Email__c`; marked Email and Website as Required; updated excluded quick-action buttons. |
| 9 | Permission Set | N/A | sfdcInternalInt__sfdc_a360 | sfdc_a360 | Updated | Granted Read access to `Lead.Department__c` and `Lead.Second_Email__c`. |
| 10 | Permission Set | N/A | sfdcInternalInt__sfdc_a360_sfcrm_data_extract | sfdc_a360_sfcrm_data_extract | Updated | Granted Read access to `Lead.Department__c` and `Lead.Second_Email__c`. |
| 11 | Permission Set | N/A | sfdcInternalInt__sfdc_activityplatform | sfdc_activityplatform | Updated | Granted Read access to `Lead.Department__c` and `Lead.Second_Email__c`. |
| 12 | Permission Set | N/A | sfdcInternalInt__sfdc_slack | sfdc_slack | Updated | Granted Read access to `Lead.Department__c` and `Lead.Second_Email__c`. |
