# "Lead-Conversion-Tracking" – Release Notes

## Requirements

Beacon needs to be able to tell which Accounts, Contacts, and Opportunities came from a converted
Lead, and which Lead they came from:

- Add two new fields to each of Account, Contact, and Opportunity:
  - **Created Through Lead Conversion** — a checkbox. It must be a regular checkbox, not a formula,
    so historic records can be flagged through data loads.
  - **Converted Lead ID** — an 18-character text field holding the Id of the converted Lead.
- Both fields need descriptions. They don't need to be on any page layouts.
- Grant **Read** access to the nine persona `Object, Tab, FLS` permission sets (Consulting,
  Customer Success, Executive, Finance, Marketing, Product, ResOps, Sales, Tech), and **Edit**
  access to `Beacon Salesforce Admin - Object, Tab, FLS`.
- Build a `Lead - On Conversion - After Save` flow that populates both fields on all three objects
  when a Lead is converted.

## Release Notes

Six custom fields were added, two each on Account, Contact, and Opportunity:

- **`Created_Through_Lead_Conversion__c`** (Checkbox, default unchecked). This is a plain checkbox
  rather than a formula on `Converted_Lead_ID__c`, so it can be set on historic records through a
  data load without also needing a Lead Id.
- **`Converted_Lead_ID__c`** (Text, 18). It is 18 characters long to hold the case-insensitive
  18-character form of a Salesforce Id, which is the form Flow writes. It is not marked as an
  External ID or Unique.

Neither field was added to any page layout. Field history and feed tracking are off.

Field-level security was added only to the ten `_Object_Tab_FLS` permission sets. The nine
persona sets get Read-only access, and `Beacon_Salesforce_Admin_Object_Tab_FLS` gets Read + Edit
so admins can correct values and run historic loads. New `fieldPermissions` entries were inserted
in alphabetical order to match the existing ordering in each file. The base persona permission
sets (without the `_Object_Tab_FLS` suffix) and the Baseline sets were not changed. The flow runs
in system context, so users don't need Edit access for it to stamp the fields.

A new record-triggered flow, **`Lead - On Conversion - After Save`**
(`Lead_On_Conversion_After_Save`), was added. It runs after save on Lead **update** with the entry
condition `IsConverted = true`. It is set to run *only when a record is updated to meet the
condition requirements*, so it fires once, at the moment of conversion, and not on any later
update to an already-converted Lead. The flow does the following:

1. **`Update Converted Account`** — updates the Account whose Id equals `$Record.ConvertedAccountId`,
   setting `Created_Through_Lead_Conversion__c = true` and `Converted_Lead_ID__c = $Record.Id`.
2. **`Update Converted Contact`** — the same, for the Contact whose Id equals
   `$Record.ConvertedContactId`.
3. **`Opportunity Created?`** — users can choose not to create an Opportunity during conversion,
   so this checks that `$Record.ConvertedOpportunityId` is populated.
4. **`Update Converted Opportunity`** — the same update, on the Opportunity whose Id equals
   `$Record.ConvertedOpportunityId`.

Every Update Records element sends its fault connector to the existing `Fault Path Subflow`, which
emails the fault message instead of failing silently. This is the same pattern used in
`Lead - On Create - After Save`. Every element has a description.

The fields are populated by a flow and not by Lead field mapping because the Lead Id isn't
available as a mappable Lead field. The flow sets all three objects from a single place.

## Acceptance Criteria

1. In Object Manager > Account, Contact, and Opportunity > Fields & Relationships, confirm each
   object has `Created Through Lead Conversion` (`Created_Through_Lead_Conversion__c`, Checkbox,
   default unchecked) and `Converted Lead ID` (`Converted_Lead_ID__c`, Text(18)). Confirm both
   fields have a description.
2. Confirm neither field appears on any Account, Contact, or Opportunity page layout.
3. For each of the nine persona permission sets (Consulting, Customer Success, Executive,
   Finance, Marketing, Product, ResOps, Sales, Tech `- Object, Tab, FLS`), open Object Settings
   for Account, Contact, and Opportunity. Confirm both new fields have Read checked and Edit
   unchecked.
4. In `Beacon Salesforce Admin - Object, Tab, FLS`, confirm both new fields have Read and Edit
   checked on all three objects.
5. In Setup > Flows, confirm `Lead - On Conversion - After Save` exists and is Active.
6. Convert a Lead, creating a **new** Account, a new Contact, and a new Opportunity. On each of the
   three resulting records, confirm `Created Through Lead Conversion` is checked and
   `Converted Lead ID` equals the converted Lead's 18-character Id.
7. Convert a different Lead, ticking **"Don't create an opportunity upon conversion."** Confirm the
   Account and Contact are stamped as in step 6, and that the conversion completes without error.
8. Edit a field on an Account, Contact, or Opportunity from step 6 and save. Confirm the two
   fields keep their values.
9. As a user with only a persona `Object, Tab, FLS` permission set (not Admin), confirm the two
   fields are visible but read-only (for example, in a list view or report, since they're not on
   layouts). Confirm that the user can still convert a Lead and that the fields are populated.
10. As a Salesforce Admin, edit `Created Through Lead Conversion` and `Converted Lead ID` on an
    existing Account, Contact, or Opportunity. Confirm both can be saved, which shows the fields
    support manual or historic data loads.
11. Edit an already-converted Lead (if the profile allows it). Confirm the flow does not run
    again.

## Post Deployment Items

- **Confirm Lead Settings allow automation on conversion.** In Setup > Lead Settings, confirm
  **"Require Validation for Converted Leads"** is enabled. Without it, Lead automation, including
  record-triggered flows, may not run during conversion, and the fields won't be populated.
- **Historic data load (optional).** This flow only stamps Leads converted after deployment. To
  backfill existing records, export converted Leads (`IsConverted = true`) with
  `ConvertedAccountId`, `ConvertedContactId`, and `ConvertedOpportunityId`, then load
  `Created_Through_Lead_Conversion__c = true` and `Converted_Lead_ID__c = Lead Id` onto those
  records. This is why the checkbox is not a formula.
- **Converting into existing records.** When a Lead is converted into an **existing** Account or
  Contact, the flow still stamps that existing record. It sets `Created Through Lead Conversion`
  to true and overwrites `Converted Lead ID` with the most recent converted Lead's Id. Confirm
  this is acceptable to the business, or request a follow-up change to stamp only newly created
  records.

## Component Manifest

Github Branch: https://github.com/aaroncrear/BeaconImplementation/tree/Lead-Conversion-Tracking

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Field | Account | Created_Through_Lead_Conversion__c | Created Through Lead Conversion | Created | Checkbox (default false). Checked when the Account was created through Lead conversion. Set by the Lead - On Conversion - After Save flow. Not a formula, so historic data loads are possible. |
| 2 | Field | Account | Converted_Lead_ID__c | Converted Lead ID | Created | Text(18). The 18-character Id of the Lead converted to create this Account. Set by the Lead - On Conversion - After Save flow. |
| 3 | Field | Contact | Created_Through_Lead_Conversion__c | Created Through Lead Conversion | Created | Checkbox (default false). Checked when the Contact was created through Lead conversion. Set by the Lead - On Conversion - After Save flow. Not a formula, so historic data loads are possible. |
| 4 | Field | Contact | Converted_Lead_ID__c | Converted Lead ID | Created | Text(18). The 18-character Id of the Lead converted to create this Contact. Set by the Lead - On Conversion - After Save flow. |
| 5 | Field | Opportunity | Created_Through_Lead_Conversion__c | Created Through Lead Conversion | Created | Checkbox (default false). Checked when the Opportunity was created through Lead conversion. Set by the Lead - On Conversion - After Save flow. Not a formula, so historic data loads are possible. |
| 6 | Field | Opportunity | Converted_Lead_ID__c | Converted Lead ID | Created | Text(18). The 18-character Id of the Lead converted to create this Opportunity. Set by the Lead - On Conversion - After Save flow. |
| 7 | Flow | Lead | Lead_On_Conversion_After_Save | Lead - On Conversion - After Save | Created | After-save, record-triggered on Lead update when IsConverted changes to true. Stamps Created Through Lead Conversion = true and Converted Lead ID = Lead Id on the converted Account, the converted Contact, and the converted Opportunity (if one was created). Fault paths go to Fault_Path_Subflow. |
| 8 | Permission Set | N/A | Beacon_Consulting_Object_Tab_FLS | Beacon Consulting - Object, Tab, FLS | Updated | Added Read access to Created_Through_Lead_Conversion__c and Converted_Lead_ID__c on Account, Contact, and Opportunity. |
| 9 | Permission Set | N/A | Beacon_Customer_Success_Object_Tab_FLS | Beacon Customer Success - Object, Tab, FLS | Updated | Added Read access to Created_Through_Lead_Conversion__c and Converted_Lead_ID__c on Account, Contact, and Opportunity. |
| 10 | Permission Set | N/A | Beacon_Executive_Object_Tab_FLS | Beacon Executive - Object, Tab, FLS | Updated | Added Read access to Created_Through_Lead_Conversion__c and Converted_Lead_ID__c on Account, Contact, and Opportunity. |
| 11 | Permission Set | N/A | Beacon_Finance_Object_Tab_FLS | Beacon Finance - Object, Tab, FLS | Updated | Added Read access to Created_Through_Lead_Conversion__c and Converted_Lead_ID__c on Account, Contact, and Opportunity. |
| 12 | Permission Set | N/A | Beacon_Marketing_Object_Tab_FLS | Beacon Marketing - Object, Tab, FLS | Updated | Added Read access to Created_Through_Lead_Conversion__c and Converted_Lead_ID__c on Account, Contact, and Opportunity. |
| 13 | Permission Set | N/A | Beacon_Product_Object_Tab_FLS | Beacon Product - Object, Tab, FLS | Updated | Added Read access to Created_Through_Lead_Conversion__c and Converted_Lead_ID__c on Account, Contact, and Opportunity. |
| 14 | Permission Set | N/A | Beacon_ResOps_Object_Tab_FLS | Beacon ResOps - Object, Tab, FLS | Updated | Added Read access to Created_Through_Lead_Conversion__c and Converted_Lead_ID__c on Account, Contact, and Opportunity. |
| 15 | Permission Set | N/A | Beacon_Sales_Object_Tab_FLS | Beacon Sales - Object, Tab, FLS | Updated | Added Read access to Created_Through_Lead_Conversion__c and Converted_Lead_ID__c on Account, Contact, and Opportunity. |
| 16 | Permission Set | N/A | Beacon_Tech_Object_Tab_FLS | Beacon Tech - Object, Tab, FLS | Updated | Added Read access to Created_Through_Lead_Conversion__c and Converted_Lead_ID__c on Account, Contact, and Opportunity. |
| 17 | Permission Set | N/A | Beacon_Salesforce_Admin_Object_Tab_FLS | Beacon Salesforce Admin - Object, Tab, FLS | Updated | Added Read + Edit access to Created_Through_Lead_Conversion__c and Converted_Lead_ID__c on Account, Contact, and Opportunity. |
