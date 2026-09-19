# "UAT-Testing-Feedback" – Release Notes

## Requirements

Feedback from UAT identified two changes needed to the Lead and Contact compliance model:

- Retire the **Deceased** checkbox (`Deceased__c`) on Lead and Contact. It duplicated
  information that will now be captured by a single, more descriptive **Unqualified Reason**
  field, and it needed to be fully removed from page layouts and permission sets (not just
  hidden) so it can be deleted from both objects.
- Add a new **Unqualified Reason** picklist on Lead and Contact, backed by a shared Global
  Value Set, so that whenever a Lead or Contact is marked **Unqualified**, the reason is
  captured from a standard list of values: Left Organization, Deceased, Competitor, Country
  Sanction, Blacklisted, Duplicate, Invalid Contact Details, Fake / Spam Individual, No
  response, No Budget, No Authority, No Use Case, Bad Timing, Other.
- The new field must only be selectable whenever **Lead Status** / **Contact Status** is
  **Unqualified**, placed in the bottom-right of the existing **Compliance & Data Quality**
  section on both layouts, and granted **Edit** field-level security on the same nine Beacon
  persona `_Object_Tab_FLS` permission sets used for the other compliance fields.
- Require **First Name** on both Lead and Contact via a validation rule, since UAT found
  records being created without one.

## Release Notes

**Deceased__c removed (Lead and Contact).** The `Deceased__c` checkbox field was deleted from
both objects. All references were removed so the field can be safely deleted without breaking
a deployment:

- Removed the `Deceased__c` layout item from the **Compliance & Data Quality** section on both
  `Lead-Lead Layout` and `Contact-Contact Layout` (it sat in the bottom-right slot, which the
  new `Unqualified_Reason__c` field now occupies).
- Removed the `Contact.Deceased__c` and `Lead.Deceased__c` `fieldPermissions` entries from all
  nine `_Object_Tab_FLS` permission sets.
- Removed the `Deceased__c = true` filter condition from the **Lead - On Update - Before Save**
  and **Contact - On Update - Before Save** before-save flows, which previously set Status to
  "Do Not Engage" when a record was blacklisted, deceased, or DNC + opted out of email. The
  filter logic was renumbered from `1 OR 2 OR (3 AND 4)` to `1 OR (2 AND 3)` and each flow's
  description was updated to no longer mention Deceased. These flows were not called out
  explicitly in the request but reference the field directly, so they had to be updated for the
  deletion to deploy cleanly.

**Unqualified Reason global value set and fields (Lead and Contact).** A new Global Value Set,
**`Unqualified_Reason`** (master label "Unqualified Reason"), was created with the 14
requested values (Left Organization, Deceased, Competitor, Country Sanction, Blacklisted,
Duplicate, Invalid Contact Details, Fake / Spam Individual, No response, No Budget, No
Authority, No Use Case, Bad Timing, Other), all active and unsorted (matching the convention of
the existing `Blacklisted_Reason` value set).

A new restricted picklist field, **`Unqualified_Reason__c`** (label "Unqualified Reason"), was
created on both **Lead** and **Contact**, each referencing the shared global value set and each
with a field description explaining its purpose and when it is available.

**Layout placement.** On both `Lead-Lead Layout` and `Contact-Contact Layout`, `Unqualified_Reason__c`
was added as the last (bottom) item of the right-hand column of the **Compliance & Data
Quality** section — directly under `Blacklisted_Reason__c` — which is the bottom-right position
of that section, exactly where `Deceased__c` previously sat.

**Conditional requirement via field dependency.** `Unqualified_Reason__c` is a **dependent
picklist**, controlled by `Status` on Lead and `Contact_Status__c` on Contact — the same pattern
already used for `Blacklisted_Reason__c` (controlled by `Blacklisted__c`). All 14 values are
mapped to the controlling field value **"Unqualified"**, so the picklist offers no selectable
values (and shows disabled) unless Status / Contact Status is set to Unqualified, at which point
all 14 reasons become available. The field itself stays `required=false` and the layout item
keeps the `Edit` behavior, matching the existing Blacklisted Reason convention rather than
introducing a validation rule.

**Field-level security.** `Edit` (Read + Edit) FLS was granted on `Lead.Unqualified_Reason__c`
and `Contact.Unqualified_Reason__c` in all nine `_Object_Tab_FLS` permission sets (Consulting,
Customer Success, Executive, Marketing, Product, ResOps, Sales, Salesforce Admin, Tech), each
entry inserted in the correct alphabetical position within that file's existing Lead/Contact
`fieldPermissions` block (after `United_States_Time_Zone__c`, since "Unqualified" sorts after
"United" in a case-sensitive ordinal sort). No other entries in these files were changed.

**First Name required (Lead and Contact).** A new validation rule, **`First_Name_Required`**,
was added to both objects: it fires when `ISBLANK(FirstName)` is true, displaying its error on
the First Name field with the message "First Name is required." Each rule carries a description
explaining its purpose. Unlike Unqualified Reason, this is a hard, unconditional requirement
(not tied to any other field's value), so a validation rule is the correct mechanism here rather
than a field dependency.

## Acceptance Criteria

1. In Object Manager, confirm `Deceased__c` no longer exists on Lead or Contact.
2. Open a Lead and a Contact record page and confirm the **Compliance & Data Quality** section
   no longer shows a Deceased checkbox, and that **Unqualified Reason** appears instead, as the
   last field in the right-hand column (bottom-right of the section).
3. In Object Manager > Lead (and Contact) > Fields & Relationships, confirm **Unqualified
   Reason** (`Unqualified_Reason__c`) exists as a restricted picklist using the
   `Unqualified_Reason` global value set, and offers exactly the 14 requested values: Left
   Organization, Deceased, Competitor, Country Sanction, Blacklisted, Duplicate, Invalid
   Contact Details, Fake / Spam Individual, No response, No Budget, No Authority, No Use Case,
   Bad Timing, Other.
4. On a Lead with **Status** set to anything other than **Unqualified**, confirm **Unqualified
   Reason** has no selectable values (disabled/empty), matching how Blacklisted Reason behaves
   when Blacklisted is unchecked.
5. Change **Status** to **Unqualified** and confirm **Unqualified Reason** becomes selectable,
   offering all 14 values. Repeat both checks on a Contact using **Contact Status**.
6. Confirm a Lead/Contact can still be saved with **Unqualified Reason** blank while Status is
   Unqualified (the dependency controls which values are offered, not whether the field must be
   filled in), matching the existing Blacklisted Reason behavior.
7. For each of the nine `_Object_Tab_FLS` permission sets, open Object Settings > Lead (and
   Contact) > Fields and confirm **Unqualified Reason** shows both **Read** and **Edit**
   checked.
8. As a user assigned one of the nine permission sets (not System Administrator), open a Lead
   or Contact, set Unqualified Reason, and save — confirming the granted Edit access works end
   to end.
9. Confirm the **Lead - On Update - Before Save** and **Contact - On Update - Before Save**
   flows are still Active and still set Status to "Do Not Engage" when Blacklisted is checked,
   or when DNC and Email Opt Out are both checked — and no longer reference Deceased.
10. Confirm no remaining references to `Deceased__c` exist anywhere in the metadata (layouts,
    permission sets, flows, or elsewhere).
11. Attempt to save a Lead with **First Name** blank and confirm the save is blocked with the
    error "First Name is required." Populate First Name and confirm the save succeeds. Repeat
    for a Contact.

## Post Deployment Items

None. The new `Unqualified_Reason` global value set, fields, and permission set changes are all
self-contained in this deployment. No data backfill is required.

## Component Manifest

Github Branch: https://github.com/aaroncrear/BeaconImplementation/tree/UAT-Testing-Feedback

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | CustomField | Lead | Deceased__c | Deceased | Deleted | Removed checkbox field; superseded by Unqualified Reason. |
| 2 | CustomField | Contact | Deceased__c | Deceased | Deleted | Removed checkbox field; superseded by Unqualified Reason. |
| 3 | GlobalValueSet | N/A | Unqualified_Reason | Unqualified Reason | Created | Shared picklist value set with 14 values (Left Organization, Deceased, Competitor, Country Sanction, Blacklisted, Duplicate, Invalid Contact Details, Fake / Spam Individual, No response, No Budget, No Authority, No Use Case, Bad Timing, Other). |
| 4 | CustomField | Lead | Unqualified_Reason__c | Unqualified Reason | Created | Restricted, dependent picklist referencing the Unqualified_Reason global value set; controlled by Status, with all 14 values mapped to "Unqualified" so they're only selectable in that status. |
| 5 | CustomField | Contact | Unqualified_Reason__c | Unqualified Reason | Created | Restricted, dependent picklist referencing the Unqualified_Reason global value set; controlled by Contact_Status__c, with all 14 values mapped to "Unqualified" so they're only selectable in that status. |
| 6 | Layout | Lead | Lead-Lead Layout | Lead Layout | Updated | Removed Deceased__c and added Unqualified_Reason__c as the last item in the right-hand column (bottom-right) of the Compliance & Data Quality section. |
| 7 | Layout | Contact | Contact-Contact Layout | Contact Layout | Updated | Removed Deceased__c and added Unqualified_Reason__c as the last item in the right-hand column (bottom-right) of the Compliance & Data Quality section. |
| 8 | Flow | Lead | Lead_On_Update_Before_Save | Lead - On Update - Before Save | Updated | Removed the Deceased__c = true filter and renumbered the filter logic; description updated to no longer mention Deceased. |
| 9 | Flow | Contact | Contact_On_Update_Before_Save | Contact - On Update - Before Save | Updated | Removed the Deceased__c = true filter and renumbered the filter logic; description updated to no longer mention Deceased. |
| 10 | PermissionSet | N/A | Beacon_Consulting_Object_Tab_FLS | Beacon Consulting - Object, Tab, FLS | Updated | Removed Lead/Contact.Deceased__c FLS entries; added Edit FLS for Lead.Unqualified_Reason__c and Contact.Unqualified_Reason__c. |
| 11 | PermissionSet | N/A | Beacon_Customer_Success_Object_Tab_FLS | Beacon Customer Success - Object, Tab, FLS | Updated | Removed Lead/Contact.Deceased__c FLS entries; added Edit FLS for Lead.Unqualified_Reason__c and Contact.Unqualified_Reason__c. |
| 12 | PermissionSet | N/A | Beacon_Executive_Object_Tab_FLS | Beacon Executive - Object, Tab, FLS | Updated | Removed Lead/Contact.Deceased__c FLS entries; added Edit FLS for Lead.Unqualified_Reason__c and Contact.Unqualified_Reason__c. |
| 13 | PermissionSet | N/A | Beacon_Marketing_Object_Tab_FLS | Beacon Marketing - Object, Tab, FLS | Updated | Removed Lead/Contact.Deceased__c FLS entries; added Edit FLS for Lead.Unqualified_Reason__c and Contact.Unqualified_Reason__c. |
| 14 | PermissionSet | N/A | Beacon_Product_Object_Tab_FLS | Beacon Product - Object, Tab, FLS | Updated | Removed Lead/Contact.Deceased__c FLS entries; added Edit FLS for Lead.Unqualified_Reason__c and Contact.Unqualified_Reason__c. |
| 15 | PermissionSet | N/A | Beacon_ResOps_Object_Tab_FLS | Beacon ResOps - Object, Tab, FLS | Updated | Removed Lead/Contact.Deceased__c FLS entries; added Edit FLS for Lead.Unqualified_Reason__c and Contact.Unqualified_Reason__c. |
| 16 | PermissionSet | N/A | Beacon_Sales_Object_Tab_FLS | Beacon Sales - Object, Tab, FLS | Updated | Removed Lead/Contact.Deceased__c FLS entries; added Edit FLS for Lead.Unqualified_Reason__c and Contact.Unqualified_Reason__c. |
| 17 | PermissionSet | N/A | Beacon_Salesforce_Admin_Object_Tab_FLS | Beacon Salesforce Admin - Object, Tab, FLS | Updated | Removed Lead/Contact.Deceased__c FLS entries; added Edit FLS for Lead.Unqualified_Reason__c and Contact.Unqualified_Reason__c. |
| 18 | PermissionSet | N/A | Beacon_Tech_Object_Tab_FLS | Beacon Tech - Object, Tab, FLS | Updated | Removed Lead/Contact.Deceased__c FLS entries; added Edit FLS for Lead.Unqualified_Reason__c and Contact.Unqualified_Reason__c. |
| 19 | ValidationRule | Lead | First_Name_Required | First_Name_Required | Created | Blocks save when First Name is blank. |
| 20 | ValidationRule | Contact | First_Name_Required | First_Name_Required | Created | Blocks save when First Name is blank. |
