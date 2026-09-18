# "Account-Compliance-Fields" – Release Notes

## Requirements

Beacon tracks a set of "compliance" flags on the Contact object (Blacklisted, Blacklisted
Reason, Email Opt Out) that govern whether and how a person may be engaged. The business need
was to be able to track the same compliance status at the **Account** level, so that an entire
company can be marked as blacklisted, do-not-call, or opted out of email — independently of
the individual Contacts under it.

- Replicate the four Contact compliance fields — **Blacklisted**, **Blacklisted Reason**, **Do
  Not Call**, and **Email Opt Out** — onto the Account object.
- Surface all four fields together on the Account record page in a dedicated **Compliance**
  section so users have a single place to review and set an Account's compliance status.
- Grant **Edit** field-level security on all four fields to the nine Beacon persona
  `_Object_Tab_FLS` permission sets (Consulting, Customer Success, Executive, Marketing,
  Product, ResOps, Sales, Salesforce Admin, Tech).

On Contact, **Blacklisted** and **Blacklisted Reason** are custom fields, **Email Opt Out** is
the standard `HasOptedOutOfEmail` field, and there is no existing **Do Not Call** field.
Because Account has no equivalent standard fields, all four are created here as **new custom
fields** on Account, mirroring the behavior of their Contact counterparts.

A second phase extended the same compliance model to **Opportunity** and automated the
synchronisation of the flags down from the Account:

- Replicate the same four compliance fields — **Blacklisted**, **Blacklisted Reason**, **Do
  Not Call**, and **Email Opt Out** — onto the **Opportunity** object, in the same dedicated
  **Compliance & Data Quality** section (at the bottom of the layout) and with the same **Edit**
  field-level security on the nine Beacon persona `_Object_Tab_FLS` permission sets.
- Make **all** active **Blacklisted Reason** values available on Opportunity across **all three**
  Opportunity record types (Consulting, Subscription New, Subscription Renewal).
- Automate compliance so that when any of the four compliance fields changes on an **Account**,
  an after-save flow syncs the new values down to the Account's related **Contacts**, related
  **Leads** (via the Lead → Account lookup), and **open Opportunities**.

## Release Notes

Four custom fields were added to the Account object:

- **`Account.Blacklisted__c`** (Checkbox, default `false`) — indicates the account has been
  blacklisted and should not be engaged. When checked, the reason is captured in Blacklisted
  Reason.
- **`Account.Blacklisted_Reason__c`** (Picklist, restricted, dependent) — the reason the account
  has been blacklisted. It is a **dependent picklist controlled by `Blacklisted__c`** and reuses
  the existing **`Blacklisted_Reason` global value set**, with the values **Competitor - Beacon**
  and **Sanctioned Country** both mapped to the controlling field's `checked` state. This mirrors
  exactly how Blacklisted Reason behaves on Contact: the reason is only available for selection
  once Blacklisted is checked, which keeps the two flags logically consistent and prevents a
  reason from being set on a non-blacklisted account.
- **`Account.Do_Not_Call__c`** (Checkbox, default `false`) — indicates the account should not
  be called.
- **`Account.Email_Opt_Out__c`** (Checkbox, default `false`) — indicates the account has opted
  out of email communications and should be excluded from email sends.

A new **Compliance & Data Quality** section was added to the Account page layout
(`Account-Account Layout`), placed at the **bottom** of the page as the last section. It uses
a two-column top-to-bottom layout, with **Blacklisted** and **Blacklisted Reason** in the first
column and **Do Not Call** and **Email Opt Out** in the second. All four items are set to the
**Edit** behavior.

Field-level security for the four new fields was granted as **Edit** (Read + Edit) on the nine
`_Object_Tab_FLS` companion permission sets. Each file already carried a different set of
Account `fieldPermissions`, so the four new entries were inserted in the correct alphabetical
position within each file's existing Account block, matching the case-sensitive ordinal sort
convention the files already use (the same convention under which `Blacklisted_Reason__c` sorts
before `Blacklisted__c`). No existing entries were changed, and no non-Account permissions were
touched.

### Opportunity compliance fields

The same four compliance fields were replicated onto the **Opportunity** object, mirroring the
Account implementation:

- **`Opportunity.Blacklisted__c`** (Checkbox, default `false`).
- **`Opportunity.Blacklisted_Reason__c`** (Picklist, restricted, dependent on `Blacklisted__c`),
  reusing the shared **`Blacklisted_Reason` global value set** with **Competitor - Beacon** and
  **Sanctioned Country** mapped to the controlling field's `checked` state — identical to Account
  and Contact.
- **`Opportunity.Do_Not_Call__c`** (Checkbox, default `false`).
- **`Opportunity.Email_Opt_Out__c`** (Checkbox, default `false`).

A **Compliance & Data Quality** section was added to the Opportunity page layout
(`Opportunity-Opportunity Layout`) at the **bottom** of the page as the last section, using the
same two-column top-to-bottom layout (Blacklisted and Blacklisted Reason on the left, Do Not Call
and Email Opt Out on the right), all editable — matching the Account layout section exactly.

All **active** Blacklisted Reason values were made available on Opportunity across **all three**
Opportunity record types (Consulting, Subscription New, Subscription Renewal). A
`Blacklisted_Reason__c` `picklistValues` block listing **Breach of Contract**, **Competitor -
Beacon**, **Competitor – Consulting**, **Other**, and **Sanctioned Country** (the five active
values of the global value set, copied verbatim including the en-dash in *Competitor – Consulting*)
was inserted into each record type in its correct alphabetical position (first, before
`ForecastCategoryName`).

Field-level security for the four Opportunity fields was granted as **Edit** on the same nine
`_Object_Tab_FLS` permission sets, inserted at the correct case-sensitive ordinal position within
each file's existing Opportunity `fieldPermissions` block (Blacklisted Reason then Blacklisted
after Beacon Demo on; Do Not Call and Email Opt Out after Director Probability / Discovery
Completed). Existing entries were untouched.

### Flow: Account - On Update - After Save

A new record-triggered, **after-save** flow (`Account_On_Update_After_Save`, label *Account - On
Update - After Save*, API version 67.0, status Active) was added on the **Account** object. It is
gated by an entry condition built from four **Is Changed** field conditions — one each on
**Blacklisted** (`Blacklisted__c`), **Blacklisted Reason** (`Blacklisted_Reason__c`), **Do Not
Call** (`Do_Not_Call__c`), and **Email Opt Out** (`Email_Opt_Out__c`) — combined with **OR**
logic (`1 OR 2 OR 3 OR 4`), so it only runs when at least one of the four compliance fields
actually changes on the Account.

When it fires, the flow queries and loops over three sets of related records, sets the four
compliance values on each, and performs a single bulk update per object:

- **Contacts** related to the Account (by `AccountId`).
- **Leads** related to the Account via the custom Lead → Account lookup (`Account__c`).
- **Open Opportunities** related to the Account (`AccountId`) filtered to `IsClosed = false`, so
  **closed** Opportunities are intentionally left untouched.

Because Contact and Lead expose the standard **Do Not Call** (`DoNotCall`) and **Email Opt Out**
(`HasOptedOutOfEmail`) fields, the flow maps the Account's custom `Do_Not_Call__c` and
`Email_Opt_Out__c` to those **standard** fields on Contact and Lead, while mapping to the matching
**custom** fields on Opportunity; the custom `Blacklisted__c` and `Blacklisted_Reason__c` map
directly on all three objects.

After each of the three Get lookups, a **Decision** checks whether any records were returned
before looping: because the Get output is stored automatically, its collection is null when
nothing is found, so each decision tests the Get element **Is Null false** and only enters the
corresponding loop when records exist (otherwise it skips ahead to the next stage). Only the
three **Update** DML operations carry a **fault path**, each routed to the existing reusable
**`Fault_Path_Subflow`**, which emails an automation-failure notification containing the fault
message. That subflow already exists in the org and was not modified.

## Acceptance Criteria

1. In Object Manager > Account > Fields & Relationships, confirm **Blacklisted** (API name
   `Blacklisted__c`) exists as a Checkbox with a default value of unchecked and the description
   about blacklisted accounts.
2. Confirm **Blacklisted Reason** (API name `Blacklisted_Reason__c`) exists as a restricted
   picklist that uses the `Blacklisted_Reason` global value set and offers the values
   **Competitor - Beacon** and **Sanctioned Country**.
3. Confirm **Do Not Call** (API name `Do_Not_Call__c`) and **Email Opt Out** (API name
   `Email_Opt_Out__c`) each exist as Checkbox fields defaulting to unchecked, with their
   respective descriptions.
4. Open an Account record page and confirm a **Compliance & Data Quality** section appears at the
   bottom of the page as the last section, showing **Blacklisted** and **Blacklisted Reason**
   in the left column and **Do Not Call** and **Email Opt Out** in the right column, all
   editable.
5. On an Account with **Blacklisted** unchecked, confirm **Blacklisted Reason** is disabled / has
   no selectable values. Check **Blacklisted**, save/refresh, and confirm **Blacklisted Reason**
   becomes selectable and offers exactly **Competitor - Beacon** and **Sanctioned Country**.
6. Confirm that because the picklist is restricted and dependent, no reason can be selected while
   Blacklisted is unchecked (matching the Contact behavior).
7. For each of the nine `_Object_Tab_FLS` permission sets (Consulting, Customer Success,
   Executive, Marketing, Product, ResOps, Sales, Salesforce Admin, Tech), open Object Settings >
   Account > Fields and confirm **Blacklisted**, **Blacklisted Reason**, **Do Not Call**, and
   **Email Opt Out** each show both **Read** and **Edit** checked.
8. As a user assigned one of the nine permission sets (and not System Administrator), open an
   Account, set all four compliance fields, save, and confirm the values persist — verifying the
   granted Edit access works end to end.
9. In Object Manager > Opportunity > Fields & Relationships, confirm **Blacklisted**
   (`Blacklisted__c`), **Do Not Call** (`Do_Not_Call__c`), and **Email Opt Out**
   (`Email_Opt_Out__c`) exist as Checkbox fields defaulting to unchecked, and **Blacklisted
   Reason** (`Blacklisted_Reason__c`) exists as a restricted picklist dependent on Blacklisted,
   reusing the `Blacklisted_Reason` global value set.
10. Open an Opportunity record page and confirm a **Compliance & Data Quality** section appears at
    the bottom of the page as the last section, with **Blacklisted** and **Blacklisted Reason** in
    the left column and **Do Not Call** and **Email Opt Out** in the right column, all editable.
11. On an Opportunity with **Blacklisted** unchecked, confirm **Blacklisted Reason** is disabled /
    has no selectable values. Check **Blacklisted**, then confirm Blacklisted Reason becomes
    selectable — verifying the dependency works on Opportunity as it does on Account.
12. For each of the three Opportunity record types (Consulting, Subscription New, Subscription
    Renewal), confirm **Blacklisted Reason** offers all five active values: **Breach of Contract**,
    **Competitor - Beacon**, **Competitor – Consulting**, **Other**, and **Sanctioned Country**
    (note the en-dash in *Competitor – Consulting*).
13. For each of the nine `_Object_Tab_FLS` permission sets, open Object Settings > Opportunity >
    Fields and confirm **Blacklisted**, **Blacklisted Reason**, **Do Not Call**, and **Email Opt
    Out** each show both **Read** and **Edit** checked.
14. Confirm the flow **Account - On Update - After Save** is present and **Active** on the Account
    object. On an Account that has related Contacts, related Leads (with the Account lookup set),
    at least one **open** Opportunity, and at least one **closed** Opportunity, check **Blacklisted**
    (and set a Blacklisted Reason) and save. Confirm the related Contacts, the related Leads, and
    the **open** Opportunity all receive the synced values (Blacklisted / Blacklisted Reason, and
    Do Not Call / Email Opt Out where applicable), while the **closed** Opportunity is left
    unchanged.
15. Confirm the flow only fires on change: edit an unrelated Account field (leaving all four
    compliance fields the same) and verify no sync occurs (none of the four **Is Changed** entry
    conditions is met).
16. Confirm the record-found decisions: on an Account with **no** related Contacts (but with
    related Leads and/or open Opportunities), change a compliance field and verify the flow skips
    the Contact loop and still syncs the Leads and open Opportunities — the empty Get result routes
    through the "No Contacts Found" path without error.
17. Verify the fault handling: force a failure on one of the Update DML operations (for example, a
    validation rule that blocks the update on a child record) and confirm the
    **Fault Path Subflow** sends its automation-failure notification email containing the fault
    message.

## Post Deployment Items

None. The `Blacklisted_Reason` global value set already exists in the org (it is reused by the
Contact and Account Blacklisted Reason fields), so no new value set needs to be deployed. The
reusable **`Fault_Path_Subflow`** flow that the new Account - On Update - After Save flow calls
also already exists in the org and is reused as-is (no redeploy needed). No data backfill is
required — the new Opportunity fields default to unchecked / blank on existing records, and the
sync flow populates them going forward whenever an Account's compliance fields change.

## Component Manifest

Github Branch: https://github.com/aaroncrear/BeaconImplementation/tree/Account-Compliance-Fields

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | CustomField | Account | Blacklisted__c | Blacklisted | Created | Checkbox (default false) marking the account as blacklisted; controls the Blacklisted Reason dependent picklist. |
| 2 | CustomField | Account | Blacklisted_Reason__c | Blacklisted Reason | Created | Restricted picklist dependent on Blacklisted__c, reusing the Blacklisted_Reason global value set (Competitor - Beacon, Sanctioned Country mapped to the checked state), mirroring Contact. |
| 3 | CustomField | Account | Do_Not_Call__c | Do Not Call | Created | Checkbox (default false) indicating the account should not be called. |
| 4 | CustomField | Account | Email_Opt_Out__c | Email Opt Out | Created | Checkbox (default false) indicating the account has opted out of email communications. |
| 5 | Layout | Account | Account-Account Layout | Account Layout | Updated | Added a Compliance & Data Quality section (at the bottom of the page as the last section) containing all four new compliance fields as editable items. |
| 6 | PermissionSet | N/A | Beacon_Consulting_Object_Tab_FLS | Beacon Consulting - Object, Tab, FLS | Updated | Added Edit FLS for Account.Blacklisted__c, Blacklisted_Reason__c, Do_Not_Call__c, and Email_Opt_Out__c, and for the same four fields on Opportunity (Opportunity.Blacklisted__c, Blacklisted_Reason__c, Do_Not_Call__c, Email_Opt_Out__c). |
| 7 | PermissionSet | N/A | Beacon_Customer_Success_Object_Tab_FLS | Beacon Customer Success - Object, Tab, FLS | Updated | Added Edit FLS for Account.Blacklisted__c, Blacklisted_Reason__c, Do_Not_Call__c, and Email_Opt_Out__c, and for the same four fields on Opportunity (Opportunity.Blacklisted__c, Blacklisted_Reason__c, Do_Not_Call__c, Email_Opt_Out__c). |
| 8 | PermissionSet | N/A | Beacon_Executive_Object_Tab_FLS | Beacon Executive - Object, Tab, FLS | Updated | Added Edit FLS for Account.Blacklisted__c, Blacklisted_Reason__c, Do_Not_Call__c, and Email_Opt_Out__c, and for the same four fields on Opportunity (Opportunity.Blacklisted__c, Blacklisted_Reason__c, Do_Not_Call__c, Email_Opt_Out__c). |
| 9 | PermissionSet | N/A | Beacon_Marketing_Object_Tab_FLS | Beacon Marketing - Object, Tab, FLS | Updated | Added Edit FLS for Account.Blacklisted__c, Blacklisted_Reason__c, Do_Not_Call__c, and Email_Opt_Out__c, and for the same four fields on Opportunity (Opportunity.Blacklisted__c, Blacklisted_Reason__c, Do_Not_Call__c, Email_Opt_Out__c). |
| 10 | PermissionSet | N/A | Beacon_Product_Object_Tab_FLS | Beacon Product - Object, Tab, FLS | Updated | Added Edit FLS for Account.Blacklisted__c, Blacklisted_Reason__c, Do_Not_Call__c, and Email_Opt_Out__c, and for the same four fields on Opportunity (Opportunity.Blacklisted__c, Blacklisted_Reason__c, Do_Not_Call__c, Email_Opt_Out__c). |
| 11 | PermissionSet | N/A | Beacon_ResOps_Object_Tab_FLS | Beacon ResOps - Object, Tab, FLS | Updated | Added Edit FLS for Account.Blacklisted__c, Blacklisted_Reason__c, Do_Not_Call__c, and Email_Opt_Out__c, and for the same four fields on Opportunity (Opportunity.Blacklisted__c, Blacklisted_Reason__c, Do_Not_Call__c, Email_Opt_Out__c). |
| 12 | PermissionSet | N/A | Beacon_Sales_Object_Tab_FLS | Beacon Sales - Object, Tab, FLS | Updated | Added Edit FLS for Account.Blacklisted__c, Blacklisted_Reason__c, Do_Not_Call__c, and Email_Opt_Out__c, and for the same four fields on Opportunity (Opportunity.Blacklisted__c, Blacklisted_Reason__c, Do_Not_Call__c, Email_Opt_Out__c). |
| 13 | PermissionSet | N/A | Beacon_Salesforce_Admin_Object_Tab_FLS | Beacon Salesforce Admin - Object, Tab, FLS | Updated | Added Edit FLS for Account.Blacklisted__c, Blacklisted_Reason__c, Do_Not_Call__c, and Email_Opt_Out__c, and for the same four fields on Opportunity (Opportunity.Blacklisted__c, Blacklisted_Reason__c, Do_Not_Call__c, Email_Opt_Out__c). |
| 14 | PermissionSet | N/A | Beacon_Tech_Object_Tab_FLS | Beacon Tech - Object, Tab, FLS | Updated | Added Edit FLS for Account.Blacklisted__c, Blacklisted_Reason__c, Do_Not_Call__c, and Email_Opt_Out__c, and for the same four fields on Opportunity (Opportunity.Blacklisted__c, Blacklisted_Reason__c, Do_Not_Call__c, Email_Opt_Out__c). |
| 15 | CustomField | Opportunity | Blacklisted__c | Blacklisted | Created | Checkbox (default false) marking the opportunity's account as blacklisted; controls the Blacklisted Reason dependent picklist. Synced from the Account by the Account - On Update - After Save flow. |
| 16 | CustomField | Opportunity | Blacklisted_Reason__c | Blacklisted Reason | Created | Restricted picklist dependent on Blacklisted__c, reusing the shared Blacklisted_Reason global value set (Competitor - Beacon, Sanctioned Country mapped to the checked state), mirroring Account and Contact. |
| 17 | CustomField | Opportunity | Do_Not_Call__c | Do Not Call | Created | Checkbox (default false) indicating the opportunity's account should not be called. Synced from the Account by the sync flow. |
| 18 | CustomField | Opportunity | Email_Opt_Out__c | Email Opt Out | Created | Checkbox (default false) indicating the opportunity's account has opted out of email communications. Synced from the Account by the sync flow. |
| 19 | Layout | Opportunity | Opportunity-Opportunity Layout | Opportunity Layout | Updated | Added a Compliance & Data Quality section (at the bottom of the page as the last section) containing all four new Opportunity compliance fields as editable items, matching the Account layout section. |
| 20 | RecordType | Opportunity | Consulting | Consulting | Updated | Added a Blacklisted_Reason__c picklistValues block exposing all five active values (Breach of Contract, Competitor - Beacon, Competitor – Consulting, Other, Sanctioned Country). |
| 21 | RecordType | Opportunity | Subscription_New | Subscription New | Updated | Added a Blacklisted_Reason__c picklistValues block exposing all five active values (Breach of Contract, Competitor - Beacon, Competitor – Consulting, Other, Sanctioned Country). |
| 22 | RecordType | Opportunity | Subscription_Renewal | Subscription Renewal | Updated | Added a Blacklisted_Reason__c picklistValues block exposing all five active values (Breach of Contract, Competitor - Beacon, Competitor – Consulting, Other, Sanctioned Country). |
| 23 | Flow | Account | Account_On_Update_After_Save | Account - On Update - After Save | Created | Record-triggered after-save flow gated by four Is Changed entry conditions (Blacklisted, Blacklisted Reason, Do Not Call, Email Opt Out) combined with OR logic; syncs those fields from the Account to its related Contacts, related Leads (Account__c lookup), and open Opportunities (IsClosed = false), mapping to standard DoNotCall/HasOptedOutOfEmail on Contact/Lead and to the custom fields on Opportunity. After each Get Records a decision checks whether records were found before looping, and only the three Update DML elements route their fault paths to the existing Fault_Path_Subflow. |
