# "Lead-to-Account-Relation" – Release Notes

## Requirements

Leads are not natively related to Accounts until they are converted, which makes it hard to see
whether a new Lead already belongs to a company Beacon has an Account for. The business need was
to automatically associate a Lead with its matching Account, based on the domain of the Lead's
email address, as soon as the Lead is created:

- Add a `Domain` field on Account that can be matched against a Lead's email domain.
- Derive an `Email Domain` field on Lead from the portion of the Lead's Email address after the
  `@` symbol, so it can be compared against the Account's `Domain` field.
- Add an `Account` lookup field on Lead to hold the matched Account.
- Give the nine `_Object_Tab_FLS` Beacon persona permission sets the right level of access to all
  three fields: Edit on `Account.Domain__c`, Read on `Lead.Email_Domain__c` (system-derived, not
  meant to be typed in by users), and Edit on `Lead.Account__c`.
- Automatically populate the new `Account` lookup on Lead creation by matching `Email Domain` to
  `Domain` and the Lead's `Country` to the Account's `Billing Country`, so two different companies
  that happen to share a generic email domain aren't cross-matched.

## Release Notes

Three fields were added:

- **`Account.Domain__c`** (Text, 255) — the domain used to match Leads to this Account. Placed on
  the Account Layout directly under `Website`, in the same section/column.
- **`Lead.Email_Domain__c`** (Text formula) — `IF(CONTAINS(Email, "@"), MID(Email, FIND("@",
  Email) + 1, LEN(Email) - FIND("@", Email)), "")`, i.e. everything after the `@` in the Lead's
  Email address, or blank if Email has no `@`. Placed on the Lead Layout directly under
  `Second Email`, as a read-only field (formula fields can't be edited directly).
- **`Lead.Account__c`** (Lookup to Account, label "Account") — populated by automation, not
  intended for manual entry. Not added to the Lead Layout since no placement was requested for it;
  it can be surfaced in a related list or added to the layout in a follow-up if needed.

Field-level security for the three new fields was scoped to only the nine `_Object_Tab_FLS`
companion permission sets (Consulting, Customer Success, Executive, Marketing, Product, ResOps,
Sales, Salesforce Admin, Tech): Edit (Read + Edit) on `Account.Domain__c`, Read-only on
`Lead.Email_Domain__c`, and Edit (Read + Edit) on `Lead.Account__c`. New `fieldPermissions`
entries were inserted alphabetically alongside each file's existing entries, matching the
ordering convention already used in these files. The two Baseline permission sets
(`Beacon_Baseline_Standard_Field_Access`, `Beacon_Baseline_System_App_Access`) and the nine base
persona permission sets without the `_Object_Tab_FLS` suffix (`Beacon_Consulting`,
`Beacon_Customer_Success`, `Beacon_Executive`, `Beacon_Marketing`, `Beacon_Product`,
`Beacon_ResOps`, `Beacon_Sales`, `Beacon_Salesforce_Admin`, `Beacon_Tech`) do not carry these
field permissions — an earlier push on this branch had added them everywhere a permission set
name started with `Beacon`, and that was subsequently narrowed to just the nine FLS sets.

A new record-triggered flow, **`Lead - On Create - Before Save`**
(`Lead_On_Create_Before_Save`), runs before a new Lead is saved. Its entry criteria only fires the
flow when both `Email_Domain__c` and `Country` are populated on the incoming Lead (so it doesn't
run a lookup on every single Lead insert). It then retrieves the first Account whose `Domain__c`
equals the Lead's `Email_Domain__c` AND whose `BillingCountry` equals the Lead's `Country`. A
decision element checks whether a matching Account was found; if so, an assignment sets
`$Record.Account__c` to the matched Account's Id directly (no extra DML, since the flow runs
before save and the assignment is picked up by the same save transaction). If no match is found,
the flow does nothing further and the Lead saves without an Account set. Every element in the flow
(the record lookup, the decision, and the assignment) has a `description` explaining its purpose,
matching the documentation convention used in the existing `Campaign - On Create - Before Save`
and `Contact - On Update - Before Save` flows.

## Acceptance Criteria

1. In Object Manager > Account > Fields, confirm `Domain` (API name `Domain__c`, Text(255))
   exists, and that it appears on the Account Layout directly below `Website`.
2. In Object Manager > Lead > Fields, confirm `Email Domain` (API name `Email_Domain__c`, Text
   formula) exists, and that it appears on the Lead Layout directly below `Second Email` as a
   read-only field.
3. In Object Manager > Lead > Fields, confirm `Account` (API name `Account__c`, Lookup to
   Account) exists.
4. On an existing Lead record, set the Email field to `jane@example.com` and save. Confirm
   `Email Domain` auto-populates with `example.com`.
5. Set a Lead's Email to a value with no `@` (or leave it blank) and confirm `Email Domain`
   evaluates to blank rather than an error.
6. Create an Account with `Domain` = `example.com` and `Billing Country` = `United States`. Create
   a new Lead with Email `sales@example.com` and Country `United States`. Confirm the Lead's
   `Account` lookup is automatically populated with that Account immediately upon save.
7. Create a second Account with `Domain` = `example.com` but `Billing Country` = `United Kingdom`.
   Create a new Lead with Email `sales@example.com` and Country `United States`. Confirm the
   Lead's `Account` lookup matches the first (US) Account, not the UK one.
8. Create a new Lead whose email domain and country don't match any existing Account's `Domain`
   and `Billing Country`. Confirm the Lead saves successfully with the `Account` field left blank
   (no error).
9. Create a new Lead with a blank Email or a blank Country. Confirm the Lead saves successfully
   and the flow does not attempt a lookup (no error).
10. Update an existing Lead's Email or Country after creation and confirm the `Account` lookup is
    *not* re-evaluated — the flow only runs on Lead creation, not on update.
11. For each of the nine `_Object_Tab_FLS` permission sets (Consulting, Customer Success,
    Executive, Marketing, Product, ResOps, Sales, Salesforce Admin, Tech), open Object Settings >
    Account > Fields and confirm `Domain` shows both Read and Edit checked. Open Object Settings
    > Lead > Fields and confirm `Email Domain` shows Read checked and Edit unchecked, and
    `Account` shows both Read and Edit checked.
12. Confirm the two Baseline permission sets (`Beacon - Baseline - Standard Field Access`,
    `Beacon - Baseline - System & App Access`) and the nine base persona permission sets without
    the `_Object_Tab_FLS` suffix show no access (Read or Edit) to `Domain`, `Email Domain`, or
    `Account` on Account/Lead.
13. Confirm `Lead - On Create - Before Save` shows `Status = Active` in Setup > Flows.

## Post Deployment Items

- **No backfill for existing records.** This flow only runs on Lead *creation*, so Leads that
  already exist in the org will not have `Email_Domain__c` (formula, recalculates automatically)
  or `Account__c` (automation-only) retroactively populated for the lookup. If existing Leads need
  to be matched to Accounts, a one-time data fix (e.g. Data Loader update or anonymous Apex) will
  be needed to run the same matching logic against them.
- **Confirm whether `Lead.Account__c` should be added to the Lead Layout or a related list.** The
  request only specified creating the field, not a layout placement, so it was left off the
  layout. Confirm with the business whether users should be able to see/reference it directly on
  the Lead page.
- **Confirm Domain data quality on existing Accounts.** `Account.Domain__c` is a new, currently
  blank field on all existing Accounts. The matching flow will not find a match for any Account
  until `Domain__c` is populated — confirm whether a data-population project (e.g. deriving Domain
  from existing Website values) is needed for the matching to be effective against the current
  Account base.

## Component Manifest

Github Branch: https://github.com/aaroncrear/BeaconImplementation/tree/Lead-to-Account-Relation

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Field | Account | Domain__c | Domain | Created | Text(255) field used in automation to match Leads to Accounts based on this field and the Email Domain field on Leads. |
| 2 | Field | Lead | Email_Domain__c | Email Domain | Created | Text formula field returning the portion of Email after the "@" symbol; used in automation to match Leads to Accounts based on this field and the Domain field on Accounts. |
| 3 | Field | Lead | Account__c | Account | Created | Lookup to Account, populated via automation by matching Email Domain (Lead) to Domain (Account). |
| 4 | Layout | Account | Account-Account Layout | Account Layout | Updated | Added the Domain field directly below Website. |
| 5 | Layout | Lead | Lead-Lead Layout | Lead Layout | Updated | Added the read-only Email Domain field directly below Second Email. |
| 6 | Flow | Lead | Lead_On_Create_Before_Save | Lead - On Create - Before Save | Created | Before-save, record-triggered on Lead create; matches Email Domain to Account Domain and Lead Country to Account Billing Country, and populates the Lead's Account lookup when a match is found. Every element has a description. |
| 7 | Permission Set | N/A | Beacon_Consulting_Object_Tab_FLS | Beacon Consulting - Object, Tab, FLS | Updated | Added Edit access to Account.Domain__c, Read access to Lead.Email_Domain__c, Edit access to Lead.Account__c. |
| 8 | Permission Set | N/A | Beacon_Customer_Success_Object_Tab_FLS | Beacon Customer Success - Object, Tab, FLS | Updated | Added Edit access to Account.Domain__c, Read access to Lead.Email_Domain__c, Edit access to Lead.Account__c. |
| 9 | Permission Set | N/A | Beacon_Executive_Object_Tab_FLS | Beacon Executive - Object, Tab, FLS | Updated | Added Edit access to Account.Domain__c, Read access to Lead.Email_Domain__c, Edit access to Lead.Account__c. |
| 10 | Permission Set | N/A | Beacon_Marketing_Object_Tab_FLS | Beacon Marketing - Object, Tab, FLS | Updated | Added Edit access to Account.Domain__c, Read access to Lead.Email_Domain__c, Edit access to Lead.Account__c. |
| 11 | Permission Set | N/A | Beacon_Product_Object_Tab_FLS | Beacon Product - Object, Tab, FLS | Updated | Added Edit access to Account.Domain__c, Read access to Lead.Email_Domain__c, Edit access to Lead.Account__c. |
| 12 | Permission Set | N/A | Beacon_ResOps_Object_Tab_FLS | Beacon ResOps - Object, Tab, FLS | Updated | Added Edit access to Account.Domain__c, Read access to Lead.Email_Domain__c, Edit access to Lead.Account__c. |
| 13 | Permission Set | N/A | Beacon_Sales_Object_Tab_FLS | Beacon Sales - Object, Tab, FLS | Updated | Added Edit access to Account.Domain__c, Read access to Lead.Email_Domain__c, Edit access to Lead.Account__c. |
| 14 | Permission Set | N/A | Beacon_Salesforce_Admin_Object_Tab_FLS | Beacon Salesforce Admin - Object, Tab, FLS | Updated | Added Edit access to Account.Domain__c, Read access to Lead.Email_Domain__c, Edit access to Lead.Account__c. |
| 15 | Permission Set | N/A | Beacon_Tech_Object_Tab_FLS | Beacon Tech - Object, Tab, FLS | Updated | Added Edit access to Account.Domain__c, Read access to Lead.Email_Domain__c, Edit access to Lead.Account__c. |
