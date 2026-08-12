# "claude/external-id-fields-tn6otn" – Release Notes

## Requirements

Hanson Wade (HW) records need to be matched back to their originating record in the Hanson
Wade Salesforce org so that integrations (e.g. data loads, upserts, sync jobs) can reliably
identify existing records instead of creating duplicates. This requires a new field — `HW Record
ID` — on the six core objects HW data flows into: Lead, Account, Opportunity, Contact, Campaign,
and Activity (Task/Event). The field must be marked as an External ID so it can be used as the
match key on Upsert operations. Access to the field should be limited to the Beacon Salesforce
Admin permission set (the "Object, Tab, FLS" admin permission set), consistent with how FLS is
managed for other custom fields in this repo.

## Release Notes

Added a new custom Text field, `HW_Record_ID__c` (label "HW Record ID", description "The record
ID from the Hanson Wade Org"), to six objects: `Lead`, `Account`, `Opportunity`, `Contact`,
`Campaign`, and `Activity`. The field was added to `Activity` rather than directly to `Task` and
`Event` because Salesforce custom fields defined on the `Activity` object are automatically
exposed on both `Task` and `Event` — this is the standard sfdx/Metadata API pattern for adding a
shared custom field to Activities, and matches how the `Activity/fields` directory did not
previously exist in this repo (it was created for this change).

Each field was configured as:
- Type: `Text`
- Length: `18` (matches the length of a Salesforce Record ID, since the HW Record ID is expected
  to be a Salesforce ID from the Hanson Wade org)
- External ID: `true`, so the field can be used as the upsert match key when syncing HW records
- Required: `false`, Unique: `false`, Track History: `false` — consistent with the defaults used
  by other plain custom text fields in this repo (e.g. `NAICS_Code__c`)

Field Level Security (FLS) for all six new `HW_Record_ID__c` fields was added to the `Beacon
Salesforce Admin` permission set only, per the request — `readable=true` and `editable=true` for
each. No other persona permission set (`Beacon_Sales`, `Beacon_Marketing`, etc.) was touched, so
only Beacon Salesforce Admin users can currently see or edit this field. Entries were inserted
alphabetically within each object's existing block of `fieldPermissions`, matching the file's
existing convention, and a new `Activity.HW_Record_ID__c` entry was added in alphabetical object
order between the existing `Account` and `Campaign` blocks.

No object-level or tab-level permissions were changed — `Beacon Salesforce Admin` already has
full object access to Lead, Account, Contact, Opportunity, and Campaign, and Activity (Task/Event)
access is governed by the standard Task/Event object permissions, which this permission set does
not currently touch and which are unaffected by adding a field.

## Acceptance Criteria

1. In Setup > Object Manager, confirm a custom field `HW_Record_ID__c` (label "HW Record ID")
   exists on Lead, Account, Opportunity, Contact, and Campaign.
2. In Setup > Object Manager > Activity, confirm the `HW_Record_ID__c` field is defined and that
   it appears on both the Task and Event field lists (since Activity custom fields propagate to
   both).
3. For each of the six fields, confirm: Data Type = Text(18), Description = "The record ID from
   the Hanson Wade Org", and the "External ID" checkbox is checked.
4. In Setup > Permission Sets > Beacon Salesforce Admin > Object Settings, for Lead, Account,
   Opportunity, Contact, Campaign, and Activity (Task/Event), confirm `HW_Record_ID__c` shows both
   Read and Edit checked.
5. Confirm no other permission set (Beacon Executive, Sales, Marketing, Customer Success, ResOps,
   Consulting, Product, Tech) has been granted access to `HW_Record_ID__c` on any object.
6. As a user assigned only the Beacon Salesforce Admin permission set, confirm the HW Record ID
   field is visible and editable on a Lead, Account, Opportunity, Contact, Campaign, Task, and
   Event record.
7. As a user not assigned Beacon Salesforce Admin, confirm the HW Record ID field is not visible
   on those same record types (unless another permission set/profile independently grants access).
8. Confirm the org allows an Upsert against `HW_Record_ID__c` as the external ID key on each of
   the six objects (e.g. via Data Loader or an API upsert call) without error.

## Post Deployment Items

- Assign the `Beacon Salesforce Admin` permission set to any users/integration users that need to
  read or write `HW_Record_ID__c` values (e.g. the integration user running the HW sync job).
- If other personas (e.g. Beacon Tech, Beacon ResOps) end up needing visibility into HW Record ID
  for support/troubleshooting, add `HW_Record_ID__c` field permissions to those permission sets in
  a follow-up change — it was intentionally excluded from all but Beacon Salesforce Admin per the
  request.

## Component Manifest

Github Branch: https://github.com/aaroncrear/beaconimplementation/tree/claude/external-id-fields-tn6otn

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Field | Lead | HW_Record_ID__c | HW Record ID | Created | External ID text field (length 18) storing the record ID from the Hanson Wade org. |
| 2 | Field | Account | HW_Record_ID__c | HW Record ID | Created | External ID text field (length 18) storing the record ID from the Hanson Wade org. |
| 3 | Field | Opportunity | HW_Record_ID__c | HW Record ID | Created | External ID text field (length 18) storing the record ID from the Hanson Wade org. |
| 4 | Field | Contact | HW_Record_ID__c | HW Record ID | Created | External ID text field (length 18) storing the record ID from the Hanson Wade org. |
| 5 | Field | Campaign | HW_Record_ID__c | HW Record ID | Created | External ID text field (length 18) storing the record ID from the Hanson Wade org. |
| 6 | Field | Activity | HW_Record_ID__c | HW Record ID | Created | External ID text field (length 18) on Activity, propagated to Task and Event, storing the record ID from the Hanson Wade org. |
| 7 | Permission Set | N/A | Beacon_Salesforce_Admin | Beacon Salesforce Admin | Updated | Added Read/Edit field permissions for `HW_Record_ID__c` on Lead, Account, Opportunity, Contact, Campaign, and Activity. |
