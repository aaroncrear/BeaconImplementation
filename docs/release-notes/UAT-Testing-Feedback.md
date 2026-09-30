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
- Add a new Opportunity Stage, **Request for Information**, at **0% probability**, **open**
  (not closed), and **omitted** from forecast category rollups. It should only be available in
  the **Subscription New** sales process, and should be the **first** stage in the order.
- Reorder the Opportunity **Type** picklist so **New Business** is first and **Existing
  Business** is second.
- Remove the **Additional Information** section from the Opportunity page layout entirely,
  including its **Next Steps** and **Description** fields.
- Create a new Campaign compact layout, **Beacon Campaign Compact Layout**, displaying **Type**,
  **Status**, **Start Date**, **End Date**, and **Campaign Record Type**.
- Remove the **Parent Campaign** field from the **Beacon Parent Campaign Record Page** Lightning
  page.
- Add a **Sub Campaign** quick action that creates a new Campaign using the **Sub Campaign**
  record type, and surface it as an action on the **Beacon Parent Campaign Record Page**,
  replacing the page's existing **Child Campaign** action reference.

Additional UAT feedback delivered on the `UAT-Testing-Updates` branch:

- Capture event logistics and costs on Campaigns: **Attendance Format** (Attended / Sponsored),
  **Event City**, **Event Country**, **Event Region**, and cost fields for **Cost for travel**,
  **Hotel**, and **Registration**, surfaced on the **Beacon Sub Campaign Record Page**.
- Add a **Line of Business** picklist (Beacon / Consulting) to Campaign and show it on the
  **Beacon Parent Campaign Record Page** in place of **Type**.
- Add APAC split fields (**AM Split APAC**, **SDR Split APAC**) to Campaign, and trim the
  **Splits** section of the parent campaign page to the splits actually in use.
- Remove the hierarchy **Budgeted Cost** and **Actual Cost** rollups from the parent campaign
  page.
- Move Campaign **Primary Module** onto the shared **Primary Module** global value set so its
  values stay in sync with Opportunity.
- Add a shared **Countries** global value set for country picklists.
- Add an **Auto-Renew** checkbox and a **Sales Cycle Duration (Days)** calculation to
  Opportunity.
- Give the **Consulting** and **Subscription Renewal** Opportunity record types their own page
  layouts, so each record type only shows the fields relevant to it.
- Grant field-level security on all new fields through the nine Beacon persona
  `_Object_Tab_FLS` permission sets.

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

**New Opportunity Stage: Request for Information.** A new standard value, **`Request for
Information`**, was added to the global **Opportunity Stage** picklist (`OpportunityStage`
standard value set): `probability` 0, `closed` false (open), `won` false, and
`forecastCategory` `Omitted`. It was added as the **first** entry in that value set, which is
what drives the stage's position in the Stage picklist everywhere it's shown (Salesforce does
not support a per-sales-process stage order — a sales process only selects which global stage
values are included; the display order always follows the global Stage picklist order), so this
also makes it the first stage anywhere it appears.

It was added to the **`Subscription New`** business process (`Subscription New.businessProcess-meta.xml`)
only — **not** to `Consulting` or `Subscription Renewal` — so it is selectable exclusively on
Opportunities using the **Subscription New** record type / sales process, as requested. The
`Subscription_New` record type has no `StageName` picklist restriction of its own (Stage
availability there is driven entirely by the business process), so no record type change was
needed. The record type's existing `ForecastCategoryName` restriction already includes
`Omitted`, so no change was needed there either.

**Opportunity Type reorder.** The **`OpportunityType`** standard value set was not previously
tracked in this repo, so it was added (`unpackaged/main/default/standardValueSets/OpportunityType.standardValueSet-meta.xml`)
with its two existing values — **New Business** and **Existing Business** — reordered so
**New Business** is first and **Existing Business** is second. This is the master order that
drives the Type picklist everywhere it's shown, including on all three Opportunity record types
(Consulting, Subscription New, Subscription Renewal), none of which needed any changes of their
own since they don't restrict the Type picklist's order, only its membership.

**Additional Information section removed (Opportunity).** The **Additional Information**
`layoutSection` was deleted outright from `Opportunity-Opportunity Layout` — it was the only
section on the layout containing **Next Steps** (`NextStep`) and **Description**, so removing
the section removes both fields from the layout in one change. The fields themselves are
standard Opportunity fields and were not deleted (unlike Deceased__c earlier in this branch);
they're simply no longer surfaced on this layout. No other section of the layout referenced
either field, so no further cleanup was needed.

**New Campaign compact layout: Beacon Campaign Compact Layout.** A new compact layout,
**`Beacon_Campaign_Compact_Layout`** (label "Beacon Campaign Compact Layout"), was added under
`unpackaged/main/default/objects/Campaign/compactLayouts/` — this is the first compact layout
tracked for Campaign in this repo. It displays, in order: **Type**, **Status**, **Start Date**
(`StartDate`), **End Date** (`EndDate`), and **Campaign Record Type** (`RecordTypeId`). It was
only created, not assigned as the object's primary compact layout — Campaign's
`compactLayoutAssignment` remains `SYSTEM` (unchanged), so an admin still needs to assign it in
Setup if it should become the default.

**Parent Campaign removed from Beacon Parent Campaign Record Page.** On the
`Beacon_Parent_Campaign_Record_Page` Lightning record page, the highlights/details field
instance for **`Record.ParentId`** (Parent Campaign) was removed from its `flexiPageRegions`
block. No other fields or regions on that page were touched.

**Sub Campaign quick action.** A new **Create** quick action, **`Campaign.Sub_Campaign`** (label
"Sub Campaign"), was added at `unpackaged/main/default/quickActions/Campaign.Sub_Campaign.quickAction-meta.xml`
— object-specific quick actions live in this top-level `quickActions` folder with the object name
prefixed onto the filename via dot notation, not nested under `objects/<Object>/quickActions/`
the way fields, validation rules, and record types are (an earlier attempt on this branch used
the wrong location and was invisible to metadata comparison tools as a result; it was removed
and this is the correct replacement). The action targets **Campaign**, uses the **Sub Campaign**
record type (`Campaign.Sub_Campaign`), and sets `targetParentField` to **`Parent`** — the lookup
*relationship* name, not the raw field API name `ParentId` — so a campaign created via this
action always has its Parent Campaign set to the campaign it was launched from. It defines its
own two-column quick action layout (Name required; Parent Campaign, Start Date on the left;
Status, Active, End Date, Type on the right) and a custom success message.

This action is surfaced via the **`force:highlightsPanel`** component's `actionNames` list on
`Beacon_Parent_Campaign_Record_Page` — the record page's action bar — where it replaces a
pre-existing **`Campaign.Child_Campaign`** action reference that was already in that list. This
is a different mechanism from the classic page layout's `relatedListButtons` (which the earlier,
removed attempt used): action-bar buttons for a Lightning record page are configured on the
FlexiPage itself, not the page layout.

### UAT-Testing-Updates

**New Campaign fields.** Ten custom fields were added to Campaign:

- **Attendance Format** (`Attendance_Format__c`) — restricted picklist: Attended, Sponsored.
- **Line of Business** (`Line_of_Business__c`) — restricted picklist: Beacon, Consulting.
- **Event City** (`Event_City__c`) — Text(80).
- **Event Country** (`Event_Country__c`) — restricted picklist using the new **Countries**
  global value set.
- **Event Region** (`Event_Region__c`) — restricted picklist using the existing **Region**
  global value set.
- **Cost for travel** (`Cost_for_travel__c`), **Hotel** (`Hotel__c`), and **Registration**
  (`Registration__c`) — Currency(16,2).
- **AM Split APAC** (`AM_Split_APAC__c`) and **SDR Split APAC** (`SDR_Split_APAC__c`) —
  Text(20), matching the existing split fields.

**Countries global value set.** A new **Countries** global value set holds 239 active country
values (Afghanistan through Zimbabwe, unsorted). Event Country uses it now, and it can be reused
by other country picklists later.

**Campaign Primary Module moved to the global value set.** `Campaign.Primary_Module__c` no
longer defines its own local list of module values. It now references the existing
**`Primary_Module`** global value set, which `Opportunity.Primary_Module__c` and
`Campaign.Related_Modules__c` already use, so the module list is maintained in one place. The
field's description notes that the old local-value field was kept in the org as
`Campaign.Primary_Module_Legacy__c`. That legacy field is not tracked in this repo (see Post
Deployment Items).

**Beacon Sub Campaign Record Page.**

- **Event Details** section (still shown only when Type is Event or Webinar) now holds Start
  Date, End Date, Website, and Event City on the left, and Host, Attendance Format, Event
  Country, and Event Region on the right. **Event City**, **Event Country**, and **Event
  Region** have their own field-level visibility rules and appear only when Type is **Event**,
  so a Webinar shows the section without the location fields.
- A new **Campaign Costs** section was added, shown only when Type is **Event**. It holds
  Actual Cost, Cost for travel, and Registration on the left, and Budgeted Cost and Hotel on the
  right. Actual Cost and Budgeted Cost were moved here from **Campaign Statistics**, so all
  costs sit together.

**Beacon Parent Campaign Record Page.**

- **Line of Business** replaces **Type** in the Campaign Overview section. Type was required on
  this page; Line of Business is not.
- The **Hierarchy Budgeted Cost** and **Hierarchy Actual Cost** rollups were removed from the
  Hierarchy Statistics section.
- In the **Splits** section, **SDR Split 5** and **SDR Split 6** were removed, and **AM Split
  APAC** (after AM Split 3) and **SDR Split APAC** (after SDR Split 4) were added. The Project
  Team column next to it still lists SDR 5 and SDR 6.

**New Opportunity fields.**

- **Auto-Renew** (`Auto_Renew__c`) — checkbox, default unchecked, with help text: "Denotes that
  the Contract and Products (those renewable) are auto-renewed".
- **Sales Cycle Duration (Days)** (`Sales_Cycle_Dyration_Days__c`) — number formula (0
  decimals). For closed Opportunities it's Close Date minus Created Date; for open ones it's
  Today minus Created Date. Note the API name has a typo ("Dyration"); the label is spelled
  correctly.

**Opportunity page layouts by record type.** Two new layouts were created:

- **Beacon Consulting Opportunity Layout** — a slimmed-down version of the main layout for
  consulting deals. It drops Type, Primary Module, Renewal Date, Budget Confirmed, Discovery
  Completed, ROI Analysis Completed, Director Probability, Auto-Renew, the demo date fields,
  Director Expected Revenue, and the entire **CPQ** section. It adds Sales Cycle Duration (Days).
- **Beacon Subscription Renewal Opportunity Layout** — the main layout without **Renewal
  Date**, with Sales Cycle Duration (Days) and Auto-Renew added.

The existing **Opportunity Layout** (still used for Subscription New and as the default) was
also updated:

- **Auto-Renew** added at the bottom of the left column of Opportunity Information.
- **Currency** (`CurrencyIsoCode`, required) added under Stage.
- **Sales Cycle Duration (Days)** (read-only) added at the bottom of the right column.
- A **Beacon Feedback** related list added (Name, Beacon Feedback Name, Record Type, Survey
  Completed, Due Date).
- The excluded button changed from **SmartFillEnrich** to **OpenSlackRecordChannel**.
- The Compliance & Data Quality section heading was switched to a custom label (same text).

The two new layouts also include Currency and the Beacon Feedback related list.

**Layout assignments.** In 23 profiles (all tracked profiles except Guest License User), the
**Consulting** record type now uses the Beacon Consulting Opportunity Layout and the
**Subscription Renewal** record type uses the Beacon Subscription Renewal Opportunity Layout.
Subscription New and the master record type still use the Opportunity Layout. Nothing else in
the profiles changed.

**Field-level security.** All 12 new fields were added to the nine `_Object_Tab_FLS` permission
sets:

- **Campaign fields** — Read + Edit in **Marketing** and **Salesforce Admin**; Read only in the
  other seven (Consulting, Customer Success, Executive, Product, ResOps, Sales, Tech).
- **Auto-Renew** — Read + Edit in all nine.
- **Sales Cycle Duration (Days)** — Read only in all nine (it's a formula).

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
12. In Setup > Object Manager > Opportunity > Fields & Relationships > Stage, confirm **Request
    for Information** exists with **Probability** 0%, is **not** marked Closed, and has
    **Forecast Category** = **Omitted**.
13. In Setup > Sales Processes, open **Subscription New** and confirm **Request for
    Information** is included. Open **Consulting** and **Subscription Renewal** and confirm it
    is **not** included in either.
14. Create (or edit) an Opportunity with the **Subscription New** record type and confirm
    **Request for Information** is the **first** value in the Stage picklist / path / kanban
    order.
15. Open the **Type** picklist on an Opportunity (any record type) and confirm **New Business**
    is listed first and **Existing Business** is listed second.
16. Open an Opportunity record page and confirm there is no **Additional Information** section,
    and that **Next Steps** and **Description** no longer appear anywhere on the layout.
17. In Setup > Object Manager > Campaign > Compact Layouts, confirm **Beacon Campaign Compact
    Layout** exists and displays, in order: Type, Status, Start Date, End Date, Campaign Record
    Type.
18. Open a Campaign record using the **Beacon Parent Campaign Record Page** and confirm
    **Parent Campaign** no longer appears anywhere on the page; confirm all other fields on the
    page are unaffected.
19. On that same record page, confirm the action bar shows a **Sub Campaign** action (and no
    longer shows a separate "Child Campaign" action). Click it and confirm the quick action form
    shows Name (required), Parent Campaign, Start Date, Status, Active, End Date, and Type, with
    the new record using the **Sub Campaign** record type.
20. Save the quick action and confirm the new campaign's **Parent Campaign** is set to the
    campaign it was launched from, and that the success message "Sub Campaign Successfully
    Created" appears.
21. In Object Manager > Campaign > Fields & Relationships, confirm these fields exist with the
    stated types: Attendance Format (picklist: Attended, Sponsored), Line of Business
    (picklist: Beacon, Consulting), Event City (text), Event Country (picklist using the
    Countries global value set), Event Region (picklist using the Region global value set),
    Cost for travel, Hotel, and Registration (currency), AM Split APAC and SDR Split APAC
    (text).
22. In Setup > Picklist Value Sets, confirm **Countries** exists with country values from
    Afghanistan to Zimbabwe. Open a Campaign, edit **Event Country**, and confirm the same
    countries are offered.
23. Open Campaign > **Primary Module** in Object Manager and confirm it uses the **Primary
    Module** global value set. Confirm its values match Opportunity > Primary Module, and that
    existing Campaigns still show their Primary Module value.
24. Open a Sub Campaign with Type = **Event**. Confirm **Event Details** shows Start Date, End
    Date, Website, and Event City on the left, and Host, Attendance Format, Event Country, and
    Event Region on the right. Confirm a **Campaign Costs** section shows Actual Cost, Cost for
    travel, and Registration on the left and Budgeted Cost and Hotel on the right. Confirm
    **Campaign Statistics** no longer shows Actual Cost or Budgeted Cost.
25. Change that Sub Campaign's Type to **Webinar** and confirm Event Details still shows Start
    Date, End Date, Website, Host, and Attendance Format, but Event City, Event Country, and
    Event Region are hidden, and Campaign Costs is hidden. Change Type to any other value and confirm both sections are
    hidden.
26. Open a Parent Campaign. Confirm **Line of Business** appears in Campaign Overview where
    Type used to be, and that the record saves with it blank. Confirm Hierarchy Statistics no
    longer shows Hierarchy Budgeted Cost or Hierarchy Actual Cost. Confirm the Splits section
    shows AM Split 1–3, AM Split APAC, SDR Split 1–4, and SDR Split APAC (no SDR Split 5 or 6).
27. Create a **Consulting** Opportunity and confirm it uses the Beacon Consulting Opportunity
    Layout: no Type, Primary Module, Renewal Date, Budget/Discovery/ROI checkboxes, Director
    Probability, Auto-Renew, demo dates, or CPQ section; Currency is required; Sales Cycle
    Duration (Days) is shown.
28. Create a **Subscription Renewal** Opportunity and confirm it uses the Beacon Subscription
    Renewal Opportunity Layout: no Renewal Date field; Auto-Renew, Currency, and Sales Cycle
    Duration (Days) are shown.
29. Create a **Subscription New** Opportunity and confirm it still uses the Opportunity Layout,
    now with Auto-Renew, Currency (required), Sales Cycle Duration (Days), and a Beacon
    Feedback related list.
30. On an open Opportunity created before today, confirm **Sales Cycle Duration (Days)** equals
    today minus the created date. Close it (Closed Won or Lost) with a Close Date and confirm
    the value becomes Close Date minus created date.
31. Check **Auto-Renew** on an Opportunity and save; confirm it saves and shows the help text on
    hover.
32. As a user with the Beacon Marketing permission set, confirm the new Campaign fields can be
    edited. As a user with the Beacon Sales permission set, confirm they're visible but
    read-only, while Auto-Renew is editable and Sales Cycle Duration (Days) is visible.

## Post Deployment Items

The `UAT-Testing-Feedback` changes are self-contained and need no post-deployment work.

For the `UAT-Testing-Updates` changes:

1. **Campaign Primary Module (before deploying).** Salesforce won't let a deployment switch an
   existing picklist from a local value list to a global value set. In any org where
   `Campaign.Primary_Module__c` still has its own local values, first rename that field to
   `Primary_Module_Legacy__c` (as was done in the source org), then deploy so the new
   `Primary_Module__c` gets created. After deploying, copy existing values from Primary Module
   Legacy to Primary Module with a data load, and confirm every legacy value exists in the
   Primary Module global value set.
2. **Guest License User profile.** This profile's Opportunity layout assignments weren't
   changed, so its Consulting and Subscription Renewal record types still use the Opportunity
   Layout. Update it in Setup if guest users should see the new layouts.

## Component Manifest

Github Branch: https://github.com/aaroncrear/BeaconImplementation/tree/UAT-Testing-Feedback

Github Branch: https://github.com/aaroncrear/BeaconImplementation/tree/UAT-Testing-Updates

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
| 10 | PermissionSet | N/A | Beacon_Consulting_Object_Tab_FLS | Beacon Consulting - Object, Tab, FLS | Updated | Removed Lead/Contact.Deceased__c FLS entries; added Edit FLS for Lead.Unqualified_Reason__c and Contact.Unqualified_Reason__c. UAT-Testing-Updates: added FLS for the 10 new Campaign fields (Read only), Opportunity.Auto_Renew__c (Read + Edit), and Opportunity.Sales_Cycle_Dyration_Days__c (Read only). |
| 11 | PermissionSet | N/A | Beacon_Customer_Success_Object_Tab_FLS | Beacon Customer Success - Object, Tab, FLS | Updated | Removed Lead/Contact.Deceased__c FLS entries; added Edit FLS for Lead.Unqualified_Reason__c and Contact.Unqualified_Reason__c. UAT-Testing-Updates: added FLS for the 10 new Campaign fields (Read only), Opportunity.Auto_Renew__c (Read + Edit), and Opportunity.Sales_Cycle_Dyration_Days__c (Read only). |
| 12 | PermissionSet | N/A | Beacon_Executive_Object_Tab_FLS | Beacon Executive - Object, Tab, FLS | Updated | Removed Lead/Contact.Deceased__c FLS entries; added Edit FLS for Lead.Unqualified_Reason__c and Contact.Unqualified_Reason__c. UAT-Testing-Updates: added FLS for the 10 new Campaign fields (Read only), Opportunity.Auto_Renew__c (Read + Edit), and Opportunity.Sales_Cycle_Dyration_Days__c (Read only). |
| 13 | PermissionSet | N/A | Beacon_Marketing_Object_Tab_FLS | Beacon Marketing - Object, Tab, FLS | Updated | Removed Lead/Contact.Deceased__c FLS entries; added Edit FLS for Lead.Unqualified_Reason__c and Contact.Unqualified_Reason__c. UAT-Testing-Updates: added FLS for the 10 new Campaign fields (Read + Edit), Opportunity.Auto_Renew__c (Read + Edit), and Opportunity.Sales_Cycle_Dyration_Days__c (Read only). |
| 14 | PermissionSet | N/A | Beacon_Product_Object_Tab_FLS | Beacon Product - Object, Tab, FLS | Updated | Removed Lead/Contact.Deceased__c FLS entries; added Edit FLS for Lead.Unqualified_Reason__c and Contact.Unqualified_Reason__c. UAT-Testing-Updates: added FLS for the 10 new Campaign fields (Read only), Opportunity.Auto_Renew__c (Read + Edit), and Opportunity.Sales_Cycle_Dyration_Days__c (Read only). |
| 15 | PermissionSet | N/A | Beacon_ResOps_Object_Tab_FLS | Beacon ResOps - Object, Tab, FLS | Updated | Removed Lead/Contact.Deceased__c FLS entries; added Edit FLS for Lead.Unqualified_Reason__c and Contact.Unqualified_Reason__c. UAT-Testing-Updates: added FLS for the 10 new Campaign fields (Read only), Opportunity.Auto_Renew__c (Read + Edit), and Opportunity.Sales_Cycle_Dyration_Days__c (Read only). |
| 16 | PermissionSet | N/A | Beacon_Sales_Object_Tab_FLS | Beacon Sales - Object, Tab, FLS | Updated | Removed Lead/Contact.Deceased__c FLS entries; added Edit FLS for Lead.Unqualified_Reason__c and Contact.Unqualified_Reason__c. UAT-Testing-Updates: added FLS for the 10 new Campaign fields (Read only), Opportunity.Auto_Renew__c (Read + Edit), and Opportunity.Sales_Cycle_Dyration_Days__c (Read only). |
| 17 | PermissionSet | N/A | Beacon_Salesforce_Admin_Object_Tab_FLS | Beacon Salesforce Admin - Object, Tab, FLS | Updated | Removed Lead/Contact.Deceased__c FLS entries; added Edit FLS for Lead.Unqualified_Reason__c and Contact.Unqualified_Reason__c. UAT-Testing-Updates: added FLS for the 10 new Campaign fields (Read + Edit), Opportunity.Auto_Renew__c (Read + Edit), and Opportunity.Sales_Cycle_Dyration_Days__c (Read only). |
| 18 | PermissionSet | N/A | Beacon_Tech_Object_Tab_FLS | Beacon Tech - Object, Tab, FLS | Updated | Removed Lead/Contact.Deceased__c FLS entries; added Edit FLS for Lead.Unqualified_Reason__c and Contact.Unqualified_Reason__c. UAT-Testing-Updates: added FLS for the 10 new Campaign fields (Read only), Opportunity.Auto_Renew__c (Read + Edit), and Opportunity.Sales_Cycle_Dyration_Days__c (Read only). |
| 19 | ValidationRule | Lead | First_Name_Required | First_Name_Required | Created | Blocks save when First Name is blank. |
| 20 | ValidationRule | Contact | First_Name_Required | First_Name_Required | Created | Blocks save when First Name is blank. |
| 21 | StandardValueSet | N/A | OpportunityStage | Opportunity Stage | Updated | Added "Request for Information" as the first value: 0% probability, open, Forecast Category Omitted. |
| 22 | BusinessProcess | Opportunity | Subscription New | Subscription New | Updated | Added "Request for Information" to the Subscription New sales process's stage values (not added to Consulting or Subscription Renewal). |
| 23 | StandardValueSet | N/A | OpportunityType | Opportunity Type | Created | Newly tracked in source; reordered so New Business is first and Existing Business is second. |
| 24 | Layout | Opportunity | Opportunity-Opportunity Layout | Opportunity Layout | Updated | Removed the Additional Information section (Next Steps and Description fields) entirely. UAT-Testing-Updates: added Auto_Renew__c, CurrencyIsoCode (required), and Sales_Cycle_Dyration_Days__c (read-only) to Opportunity Information; added the Beacon Feedback related list; changed the excluded button from SmartFillEnrich to OpenSlackRecordChannel; switched the Compliance & Data Quality section heading to a custom label. |
| 25 | CompactLayout | Campaign | Beacon_Campaign_Compact_Layout | Beacon Campaign Compact Layout | Created | Displays Type, Status, Start Date, End Date, Campaign Record Type. Not assigned as the object's primary compact layout. |
| 26 | FlexiPage | Campaign | Beacon_Parent_Campaign_Record_Page | Beacon Parent Campaign Record Page | Updated | Removed the Parent Campaign (ParentId) field instance from the page; replaced the highlights panel's Campaign.Child_Campaign action reference with Campaign.Sub_Campaign. UAT-Testing-Updates: replaced Type with Line_of_Business__c; removed HierarchyBudgetedCost and HierarchyActualCost; removed SDR_Split_5__c and SDR_Split_6__c and added AM_Split_APAC__c and SDR_Split_APAC__c to Splits. |
| 27 | QuickAction | Campaign | Campaign.Sub_Campaign | Sub Campaign | Created | Create action using the Sub Campaign record type; targetParentField Parent (relationship name) auto-populates Parent Campaign from the launching record. Custom quick action layout and success message. |
| 28 | GlobalValueSet | N/A | Countries | Countries | Created | 239 country values (Afghanistan to Zimbabwe), used by Campaign.Event_Country__c. |
| 29 | CustomField | Campaign | Attendance_Format__c | Attendance Format | Created | Restricted picklist: Attended, Sponsored. |
| 30 | CustomField | Campaign | Line_of_Business__c | Line of Business | Created | Restricted picklist: Beacon, Consulting. |
| 31 | CustomField | Campaign | Event_City__c | Event City | Created | Text(80). |
| 32 | CustomField | Campaign | Event_Country__c | Event Country | Created | Restricted picklist using the Countries global value set. |
| 33 | CustomField | Campaign | Event_Region__c | Event Region | Created | Restricted picklist using the Region global value set. |
| 34 | CustomField | Campaign | Cost_for_travel__c | Cost for travel | Created | Currency(16,2). |
| 35 | CustomField | Campaign | Hotel__c | Hotel | Created | Currency(16,2); hotel cost. |
| 36 | CustomField | Campaign | Registration__c | Registration | Created | Currency(16,2); registration cost. |
| 37 | CustomField | Campaign | AM_Split_APAC__c | AM Split APAC | Created | Text(20). |
| 38 | CustomField | Campaign | SDR_Split_APAC__c | SDR Split APAC | Created | Text(20). |
| 39 | CustomField | Campaign | Primary_Module__c | Primary Module | Updated | Replaced the local value list with the Primary_Module global value set; description updated. |
| 40 | CustomField | Opportunity | Auto_Renew__c | Auto-Renew | Created | Checkbox, default unchecked, with help text. |
| 41 | CustomField | Opportunity | Sales_Cycle_Dyration_Days__c | Sales Cycle Duration (Days) | Created | Number formula: Close Date minus Created Date when closed, otherwise Today minus Created Date. |
| 42 | Layout | Opportunity | Opportunity-Beacon Consulting Opportunity Layout | Beacon Consulting Opportunity Layout | Created | Consulting record type layout; drops subscription-only fields and the CPQ section. |
| 43 | Layout | Opportunity | Opportunity-Beacon Subscription Renewal Opportunity Layout | Beacon Subscription Renewal Opportunity Layout | Created | Subscription Renewal record type layout; drops Renewal Date and adds Auto-Renew and Sales Cycle Duration. |
| 44 | FlexiPage | Campaign | Beacon_Sub_Campaign_Record_Page | Beacon Sub Campaign Record Page | Updated | Added event fields to Event Details (Event City, Event Country, and Event Region visible only when Type = Event); added a Campaign Costs section (Type = Event) and moved Actual/Budgeted Cost into it. |
| 45 | Profile | N/A | Admin | System Administrator | Updated | Assigned the Consulting and Subscription Renewal Opportunity record types to their new Beacon layouts. |
| 46 | Profile | N/A | Analytics Cloud Integration User | Analytics Cloud Integration User | Updated | Assigned the Consulting and Subscription Renewal Opportunity record types to their new Beacon layouts. |
| 47 | Profile | N/A | Analytics Cloud Security User | Analytics Cloud Security User | Updated | Assigned the Consulting and Subscription Renewal Opportunity record types to their new Beacon layouts. |
| 48 | Profile | N/A | CPQ Integration User | CPQ Integration User | Updated | Assigned the Consulting and Subscription Renewal Opportunity record types to their new Beacon layouts. |
| 49 | Profile | N/A | Chatter External User | Chatter External User | Updated | Assigned the Consulting and Subscription Renewal Opportunity record types to their new Beacon layouts. |
| 50 | Profile | N/A | Chatter Free User | Chatter Free User | Updated | Assigned the Consulting and Subscription Renewal Opportunity record types to their new Beacon layouts. |
| 51 | Profile | N/A | Chatter Moderator User | Chatter Moderator User | Updated | Assigned the Consulting and Subscription Renewal Opportunity record types to their new Beacon layouts. |
| 52 | Profile | N/A | ContractManager | Contract Manager | Updated | Assigned the Consulting and Subscription Renewal Opportunity record types to their new Beacon layouts. |
| 53 | Profile | N/A | Einstein Agent User | Einstein Agent User | Updated | Assigned the Consulting and Subscription Renewal Opportunity record types to their new Beacon layouts. |
| 54 | Profile | N/A | End User | End User | Updated | Assigned the Consulting and Subscription Renewal Opportunity record types to their new Beacon layouts. |
| 55 | Profile | N/A | Executive Sponsor | Executive Sponsor | Updated | Assigned the Consulting and Subscription Renewal Opportunity record types to their new Beacon layouts. |
| 56 | Profile | N/A | External Apps Login User | External Apps Login User | Updated | Assigned the Consulting and Subscription Renewal Opportunity record types to their new Beacon layouts. |
| 57 | Profile | N/A | External Einstein Agent User | External Einstein Agent User | Updated | Assigned the Consulting and Subscription Renewal Opportunity record types to their new Beacon layouts. |
| 58 | Profile | N/A | Identity User | Identity User | Updated | Assigned the Consulting and Subscription Renewal Opportunity record types to their new Beacon layouts. |
| 59 | Profile | N/A | MarketingProfile | Marketing User | Updated | Assigned the Consulting and Subscription Renewal Opportunity record types to their new Beacon layouts. |
| 60 | Profile | N/A | Minimum Access - API Only Integrations | Minimum Access - API Only Integrations | Updated | Assigned the Consulting and Subscription Renewal Opportunity record types to their new Beacon layouts. |
| 61 | Profile | N/A | Minimum Access - Salesforce | Minimum Access - Salesforce | Updated | Assigned the Consulting and Subscription Renewal Opportunity record types to their new Beacon layouts. |
| 62 | Profile | N/A | Read Only | Read Only | Updated | Assigned the Consulting and Subscription Renewal Opportunity record types to their new Beacon layouts. |
| 63 | Profile | N/A | Sales Insights Integration User | Sales Insights Integration User | Updated | Assigned the Consulting and Subscription Renewal Opportunity record types to their new Beacon layouts. |
| 64 | Profile | N/A | Salesforce API Only System Integrations | Salesforce API Only System Integrations | Updated | Assigned the Consulting and Subscription Renewal Opportunity record types to their new Beacon layouts. |
| 65 | Profile | N/A | SalesforceIQ Integration User | SalesforceIQ Integration User | Updated | Assigned the Consulting and Subscription Renewal Opportunity record types to their new Beacon layouts. |
| 66 | Profile | N/A | SolutionManager | Solution Manager | Updated | Assigned the Consulting and Subscription Renewal Opportunity record types to their new Beacon layouts. |
| 67 | Profile | N/A | Standard | Standard User | Updated | Assigned the Consulting and Subscription Renewal Opportunity record types to their new Beacon layouts. |
