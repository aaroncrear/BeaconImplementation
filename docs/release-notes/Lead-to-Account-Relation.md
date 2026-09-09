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
- **`Lead.Account__c`** (Lookup to Account, label "Account") — populated by automation, but left
  editable so users can see and, if needed, manually correct the matched Account. Placed on the
  Lead Layout directly under `Company`.

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

A new record-triggered flow, **`Lead - On Create - After Save`** (`Lead_On_Create_After_Save`),
runs after every new Lead is saved and tries to match it to an Account in two passes:

1. **Domain + Country match** — `Get Matching Account by Domain and Country` retrieves the first
   Account whose `Domain__c` equals the Lead's `Email_Domain__c` AND whose `BillingCountry` equals
   the Lead's `Country`. If `Matching Account Found?` finds one, `Update Lead Account` sets
   `Account__c` on the triggering Lead (`$Record`) to that Account's Id.
2. **Domain-only fallback** — if no Domain + Country match was found, `Get Matching Account by
   Domain Only` retrieves the first Account whose `Domain__c` matches, ignoring Country. If
   `Matching Domain Account Found?` finds one, `Relate Lead to Account` sets `Account__c` to that
   Account's Id.

If neither pass finds a match, the Lead saves with `Account__c` left blank. Both Update Records
elements (`Update Lead Account` and `Relate Lead to Account`) route their fault path to a new
reusable subflow, **`Fault Path Subflow`** (see below), so a DML failure on the update sends an
email notification instead of failing silently. Unlike the original design, the flow's entry
criteria was removed, so it now evaluates on every Lead create rather than only when
`Email_Domain__c` and `Country` are both populated — a Lead with a blank Country can still be
matched via the domain-only fallback.

This flow was originally built as a before-save flow (`Lead_On_Create_Before_Save`); that version
was deleted and rebuilt as this after-save flow because the before-save version did not work as
intended. It was then updated directly in the org (pulled into this branch via Gearset) to add the
domain-only fallback pass and fault-path email notification described above. Every element in the
flow has a `description` explaining its purpose, matching the documentation convention used in the
existing `Campaign - On Create - Before Save` and `Contact - On Update - Before Save` flows.

A second new flow, **`Fault Path Subflow`** (`Fault_Path_Subflow`), was added as a reusable
utility subflow: it takes a single input variable, `varFaultMessage` (String — the flow's
`$Flow.FaultMessage`), and sends an email via the `emailSimple` action to
`jonathan.kilby-phillips@beaconintel.com` with subject "Salesforce Automation Failure" and the
fault message in the body. It is not Lead-specific and can be called from any flow's fault
connector.

The Account Layout was also updated directly in the org: a new related list was added showing
Leads related via the new `Lead.Account__c` lookup (columns: Full Name, Company, Phone, Status),
and the layout's `excludeButtons` list changed — `DataDotComAccountInsights`, `DataDotComClean`,
and `OpenSlackRecordChannel` were removed, and `DataDotComCompanyHierarchy` and `GenerateKnowledge`
were added.

## Acceptance Criteria

1. In Object Manager > Account > Fields, confirm `Domain` (API name `Domain__c`, Text(255))
   exists, and that it appears on the Account Layout directly below `Website`.
2. In Object Manager > Lead > Fields, confirm `Email Domain` (API name `Email_Domain__c`, Text
   formula) exists, and that it appears on the Lead Layout directly below `Second Email` as a
   read-only field.
3. In Object Manager > Lead > Fields, confirm `Account` (API name `Account__c`, Lookup to
   Account) exists, and that it appears on the Lead Layout directly below `Company` as an
   editable field.
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
8. Using the same two Accounts as #7, create a new Lead with Email `sales@example.com` and Country
   left blank (or set to a country neither Account has, e.g. `Canada`). Confirm the domain-only
   fallback still populates the Lead's `Account` lookup with one of the two `example.com`
   Accounts (whichever the domain-only query returns first).
9. Create a new Lead whose email domain doesn't match any existing Account's `Domain`. Confirm the
   Lead saves successfully with the `Account` field left blank (no error), and that neither the
   Domain + Country pass nor the domain-only fallback pass finds a match.
10. Update an existing Lead's Email or Country after creation and confirm the `Account` lookup is
    *not* re-evaluated — the flow only runs on Lead creation, not on update.
11. Temporarily break the flow's ability to update the Lead (e.g. revoke Edit access to
    `Lead.Account__c` from the running user's permission set, or set an Account as read-only via a
    validation rule) so the `Update Lead Account` or `Relate Lead to Account` step faults. Confirm
    an email is sent to `jonathan.kilby-phillips@beaconintel.com` with subject "Salesforce
    Automation Failure" via the `Fault Path Subflow`.
12. For each of the nine `_Object_Tab_FLS` permission sets (Consulting, Customer Success,
    Executive, Marketing, Product, ResOps, Sales, Salesforce Admin, Tech), open Object Settings >
    Account > Fields and confirm `Domain` shows both Read and Edit checked. Open Object Settings
    > Lead > Fields and confirm `Email Domain` shows Read checked and Edit unchecked, and
    `Account` shows both Read and Edit checked.
13. Confirm the two Baseline permission sets (`Beacon - Baseline - Standard Field Access`,
    `Beacon - Baseline - System & App Access`) and the nine base persona permission sets without
    the `_Object_Tab_FLS` suffix show no access (Read or Edit) to `Domain`, `Email Domain`, or
    `Account` on Account/Lead.
14. Confirm `Lead - On Create - After Save` and `Fault Path Subflow` both show `Status = Active`
    in Setup > Flows, and that `Lead - On Create - Before Save` no longer exists.
15. On an Account that has related Leads (via the `Account` lookup), confirm the Account record
    page shows a related list of those Leads with Full Name, Company, Phone, and Status columns.

## Post Deployment Items

- **No backfill for existing records.** This flow only runs on Lead *creation*, so Leads that
  already exist in the org will not have `Email_Domain__c` (formula, recalculates automatically)
  or `Account__c` (automation-only) retroactively populated for the lookup. If existing Leads need
  to be matched to Accounts, a one-time data fix (e.g. Data Loader update or anonymous Apex) will
  be needed to run the same matching logic against them.
- **Confirm Domain data quality on existing Accounts.** `Account.Domain__c` is a new, currently
  blank field on all existing Accounts. The matching flow will not find a match for any Account
  until `Domain__c` is populated — confirm whether a data-population project (e.g. deriving Domain
  from existing Website values) is needed for the matching to be effective against the current
  Account base.
- **Confirm the domain-only fallback is intended for generic/shared email domains.** With Country
  no longer required for a match, a Lead whose email domain matches multiple Accounts in different
  countries can now be linked to whichever Account the domain-only query happens to return first
  (Salesforce does not guarantee an order without an explicit `sortField` on the Get Records
  element). Confirm with the business this is acceptable, or whether a `sortField`/tie-breaker
  should be added.
- **Fault notification recipient is hardcoded.** `Fault Path Subflow` sends failure emails to a
  single hardcoded address, `jonathan.kilby-phillips@beaconintel.com`. Confirm this is the
  intended long-term owner of these alerts (e.g. vs. a distribution list), since the address will
  need to be manually updated in the subflow if that changes.
- **Confirm the Account Layout's `excludeButtons` change was intentional.** This branch's push via
  Gearset removed `DataDotComAccountInsights`, `DataDotComClean`, and `OpenSlackRecordChannel` from
  the Account Layout's excluded-buttons list and added `DataDotComCompanyHierarchy` and
  `GenerateKnowledge`. This wasn't part of the original Lead-to-Account request — confirm it was a
  deliberate layout change and not an artifact of the org state Gearset pulled from.

## Component Manifest

Github Branch: https://github.com/aaroncrear/BeaconImplementation/tree/Lead-to-Account-Relation

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Field | Account | Domain__c | Domain | Created | Text(255) field used in automation to match Leads to Accounts based on this field and the Email Domain field on Leads. |
| 2 | Field | Lead | Email_Domain__c | Email Domain | Created | Text formula field returning the portion of Email after the "@" symbol; used in automation to match Leads to Accounts based on this field and the Domain field on Accounts. |
| 3 | Field | Lead | Account__c | Account | Created | Lookup to Account, populated via automation by matching Email Domain (Lead) to Domain (Account). |
| 4 | Layout | Account | Account-Account Layout | Account Layout | Updated | Added the Domain field directly below Website; added a related list of Leads linked via Lead.Account__c (Full Name, Company, Phone, Status); changed excludeButtons (removed DataDotComAccountInsights, DataDotComClean, OpenSlackRecordChannel; added DataDotComCompanyHierarchy, GenerateKnowledge). |
| 5 | Layout | Lead | Lead-Lead Layout | Lead Layout | Updated | Added the read-only Email Domain field directly below Second Email, and the editable Account field directly below Company. |
| 6 | Flow | Lead | Lead_On_Create_Before_Save | Lead - On Create - Before Save | Deleted | Removed and superseded by Lead_On_Create_After_Save (row 7), which replicates the same matching logic on an after-save trigger. |
| 7 | Flow | Lead | Lead_On_Create_After_Save | Lead - On Create - After Save | Created/Updated | After-save, record-triggered on Lead create. Originally: single Domain+Billing Country match updating Account__c. Updated directly in the org (pulled via Gearset) to add a domain-only fallback match (Get Matching Account by Domain Only / Relate Lead to Account) when no Domain+Country match is found, remove the entry-criteria filter formula so it evaluates on every create, and route both Update Records elements' fault paths to the new Fault_Path_Subflow. Every element has a description. |
| 8 | Flow | N/A | Fault_Path_Subflow | Fault Path Subflow | Created | Reusable utility subflow (not Lead-specific); takes input variable varFaultMessage (String) and emails jonathan.kilby-phillips@beaconintel.com with subject "Salesforce Automation Failure" and the fault message. Called from Lead_On_Create_After_Save's fault connectors. |
| 9 | Permission Set | N/A | Beacon_Consulting_Object_Tab_FLS | Beacon Consulting - Object, Tab, FLS | Updated | Added Edit access to Account.Domain__c, Read access to Lead.Email_Domain__c, Edit access to Lead.Account__c. |
| 10 | Permission Set | N/A | Beacon_Customer_Success_Object_Tab_FLS | Beacon Customer Success - Object, Tab, FLS | Updated | Added Edit access to Account.Domain__c, Read access to Lead.Email_Domain__c, Edit access to Lead.Account__c. |
| 11 | Permission Set | N/A | Beacon_Executive_Object_Tab_FLS | Beacon Executive - Object, Tab, FLS | Updated | Added Edit access to Account.Domain__c, Read access to Lead.Email_Domain__c, Edit access to Lead.Account__c. |
| 12 | Permission Set | N/A | Beacon_Marketing_Object_Tab_FLS | Beacon Marketing - Object, Tab, FLS | Updated | Added Edit access to Account.Domain__c, Read access to Lead.Email_Domain__c, Edit access to Lead.Account__c. |
| 13 | Permission Set | N/A | Beacon_Product_Object_Tab_FLS | Beacon Product - Object, Tab, FLS | Updated | Added Edit access to Account.Domain__c, Read access to Lead.Email_Domain__c, Edit access to Lead.Account__c. |
| 14 | Permission Set | N/A | Beacon_ResOps_Object_Tab_FLS | Beacon ResOps - Object, Tab, FLS | Updated | Added Edit access to Account.Domain__c, Read access to Lead.Email_Domain__c, Edit access to Lead.Account__c. |
| 15 | Permission Set | N/A | Beacon_Sales_Object_Tab_FLS | Beacon Sales - Object, Tab, FLS | Updated | Added Edit access to Account.Domain__c, Read access to Lead.Email_Domain__c, Edit access to Lead.Account__c. |
| 16 | Permission Set | N/A | Beacon_Salesforce_Admin_Object_Tab_FLS | Beacon Salesforce Admin - Object, Tab, FLS | Updated | Added Edit access to Account.Domain__c, Read access to Lead.Email_Domain__c, Edit access to Lead.Account__c. |
| 17 | Permission Set | N/A | Beacon_Tech_Object_Tab_FLS | Beacon Tech - Object, Tab, FLS | Updated | Added Edit access to Account.Domain__c, Read access to Lead.Email_Domain__c, Edit access to Lead.Account__c. |
