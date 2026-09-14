# "claude/slack-session-jqg2o0" – Release Notes

## Requirements

Beacon tracks a set of "compliance" flags on the Contact object (Blacklisted, Blacklisted
Reason, Email Opt Out) that govern whether and how a person may be engaged. The business need
was to be able to track the same compliance status at the **Account** level, so that an entire
company can be marked as blacklisted, do-not-contact, or opted out of email — independently of
the individual Contacts under it.

- Replicate the four Contact compliance fields — **Blacklisted**, **Blacklisted Reason**, **Do
  Not Contact**, and **Email Opt Out** — onto the Account object.
- Surface all four fields together on the Account record page in a dedicated **Compliance**
  section so users have a single place to review and set an Account's compliance status.
- Grant **Edit** field-level security on all four fields to the nine Beacon persona
  `_Object_Tab_FLS` permission sets (Consulting, Customer Success, Executive, Marketing,
  Product, ResOps, Sales, Salesforce Admin, Tech).

On Contact, **Blacklisted** and **Blacklisted Reason** are custom fields, **Email Opt Out** is
the standard `HasOptedOutOfEmail` field, and there is no existing **Do Not Contact** field.
Because Account has no equivalent standard fields, all four are created here as **new custom
fields** on Account, mirroring the behavior of their Contact counterparts.

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
- **`Account.Do_Not_Contact__c`** (Checkbox, default `false`) — indicates the account should not
  be contacted through any channel.
- **`Account.Email_Opt_Out__c`** (Checkbox, default `false`) — indicates the account has opted
  out of email communications and should be excluded from email sends.

A new **Compliance** section was added to the Account page layout (`Account-Account Layout`),
placed between the existing **Address Information** and **System Information** sections. It uses
a two-column top-to-bottom layout, with **Blacklisted** and **Blacklisted Reason** in the first
column and **Do Not Contact** and **Email Opt Out** in the second. All four items are set to the
**Edit** behavior.

Field-level security for the four new fields was granted as **Edit** (Read + Edit) on the nine
`_Object_Tab_FLS` companion permission sets. Each file already carried a different set of
Account `fieldPermissions`, so the four new entries were inserted in the correct alphabetical
position within each file's existing Account block, matching the case-sensitive ordinal sort
convention the files already use (the same convention under which `Blacklisted_Reason__c` sorts
before `Blacklisted__c`). No existing entries were changed, and no non-Account permissions were
touched.

## Acceptance Criteria

1. In Object Manager > Account > Fields & Relationships, confirm **Blacklisted** (API name
   `Blacklisted__c`) exists as a Checkbox with a default value of unchecked and the description
   about blacklisted accounts.
2. Confirm **Blacklisted Reason** (API name `Blacklisted_Reason__c`) exists as a restricted
   picklist that uses the `Blacklisted_Reason` global value set and offers the values
   **Competitor - Beacon** and **Sanctioned Country**.
3. Confirm **Do Not Contact** (API name `Do_Not_Contact__c`) and **Email Opt Out** (API name
   `Email_Opt_Out__c`) each exist as Checkbox fields defaulting to unchecked, with their
   respective descriptions.
4. Open an Account record page and confirm a **Compliance** section appears between the Address
   Information and System Information sections, showing **Blacklisted** and **Blacklisted Reason**
   in the left column and **Do Not Contact** and **Email Opt Out** in the right column, all
   editable.
5. On an Account with **Blacklisted** unchecked, confirm **Blacklisted Reason** is disabled / has
   no selectable values. Check **Blacklisted**, save/refresh, and confirm **Blacklisted Reason**
   becomes selectable and offers exactly **Competitor - Beacon** and **Sanctioned Country**.
6. Confirm that because the picklist is restricted and dependent, no reason can be selected while
   Blacklisted is unchecked (matching the Contact behavior).
7. For each of the nine `_Object_Tab_FLS` permission sets (Consulting, Customer Success,
   Executive, Marketing, Product, ResOps, Sales, Salesforce Admin, Tech), open Object Settings >
   Account > Fields and confirm **Blacklisted**, **Blacklisted Reason**, **Do Not Contact**, and
   **Email Opt Out** each show both **Read** and **Edit** checked.
8. As a user assigned one of the nine permission sets (and not System Administrator), open an
   Account, set all four compliance fields, save, and confirm the values persist — verifying the
   granted Edit access works end to end.

## Post Deployment Items

None. The `Blacklisted_Reason` global value set already exists in the org (it is reused by the
Contact Blacklisted Reason field), so no new value set needs to be deployed and no data backfill
is required — the new fields default to unchecked / blank on existing Account records.

## Component Manifest

Github Branch: https://github.com/aaroncrear/BeaconImplementation/tree/claude/slack-session-jqg2o0

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | CustomField | Account | Blacklisted__c | Blacklisted | Created | Checkbox (default false) marking the account as blacklisted; controls the Blacklisted Reason dependent picklist. |
| 2 | CustomField | Account | Blacklisted_Reason__c | Blacklisted Reason | Created | Restricted picklist dependent on Blacklisted__c, reusing the Blacklisted_Reason global value set (Competitor - Beacon, Sanctioned Country mapped to the checked state), mirroring Contact. |
| 3 | CustomField | Account | Do_Not_Contact__c | Do Not Contact | Created | Checkbox (default false) indicating the account should not be contacted through any channel. |
| 4 | CustomField | Account | Email_Opt_Out__c | Email Opt Out | Created | Checkbox (default false) indicating the account has opted out of email communications. |
| 5 | Layout | Account | Account-Account Layout | Account Layout | Updated | Added a Compliance section (between Address Information and System Information) containing all four new compliance fields as editable items. |
| 6 | PermissionSet | N/A | Beacon_Consulting_Object_Tab_FLS | Beacon Consulting - Object, Tab, FLS | Updated | Added Edit FLS for Account.Blacklisted__c, Blacklisted_Reason__c, Do_Not_Contact__c, and Email_Opt_Out__c. |
| 7 | PermissionSet | N/A | Beacon_Customer_Success_Object_Tab_FLS | Beacon Customer Success - Object, Tab, FLS | Updated | Added Edit FLS for Account.Blacklisted__c, Blacklisted_Reason__c, Do_Not_Contact__c, and Email_Opt_Out__c. |
| 8 | PermissionSet | N/A | Beacon_Executive_Object_Tab_FLS | Beacon Executive - Object, Tab, FLS | Updated | Added Edit FLS for Account.Blacklisted__c, Blacklisted_Reason__c, Do_Not_Contact__c, and Email_Opt_Out__c. |
| 9 | PermissionSet | N/A | Beacon_Marketing_Object_Tab_FLS | Beacon Marketing - Object, Tab, FLS | Updated | Added Edit FLS for Account.Blacklisted__c, Blacklisted_Reason__c, Do_Not_Contact__c, and Email_Opt_Out__c. |
| 10 | PermissionSet | N/A | Beacon_Product_Object_Tab_FLS | Beacon Product - Object, Tab, FLS | Updated | Added Edit FLS for Account.Blacklisted__c, Blacklisted_Reason__c, Do_Not_Contact__c, and Email_Opt_Out__c. |
| 11 | PermissionSet | N/A | Beacon_ResOps_Object_Tab_FLS | Beacon ResOps - Object, Tab, FLS | Updated | Added Edit FLS for Account.Blacklisted__c, Blacklisted_Reason__c, Do_Not_Contact__c, and Email_Opt_Out__c. |
| 12 | PermissionSet | N/A | Beacon_Sales_Object_Tab_FLS | Beacon Sales - Object, Tab, FLS | Updated | Added Edit FLS for Account.Blacklisted__c, Blacklisted_Reason__c, Do_Not_Contact__c, and Email_Opt_Out__c. |
| 13 | PermissionSet | N/A | Beacon_Salesforce_Admin_Object_Tab_FLS | Beacon Salesforce Admin - Object, Tab, FLS | Updated | Added Edit FLS for Account.Blacklisted__c, Blacklisted_Reason__c, Do_Not_Contact__c, and Email_Opt_Out__c. |
| 14 | PermissionSet | N/A | Beacon_Tech_Object_Tab_FLS | Beacon Tech - Object, Tab, FLS | Updated | Added Edit FLS for Account.Blacklisted__c, Blacklisted_Reason__c, Do_Not_Contact__c, and Email_Opt_Out__c. |
