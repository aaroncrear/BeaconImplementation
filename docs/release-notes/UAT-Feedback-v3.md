# "UAT-Feedback-v3" – Release Notes

## Requirements

Third round of UAT feedback on the Beacon Campaign, Lead, and Contact setup:

- Campaign **Type** should no longer default to **Event**. Users must choose a Type
  on purpose, and Type must be filled in on every Sub Campaign.
- The event picklists added in the previous UAT round (**Attendance Format**, **Event
  Country**, **Event Region**, **Line of Business**) must offer their values on both
  Campaign record types (**Parent Campaign** and **Sub Campaign**).
- New Contacts should default to a **Contact Status** of **New**.
- Tighten data capture on Leads and Contacts:
  - **Title** and **Currency** are required on both Lead and Contact.
  - **Lead Source** is required on Lead.
  - **Lead Type** is required on Contact.
- Remove the unused **Rating** field from the Lead page layout.

## Release Notes

**Campaign Type default removed.** In the `CampaignType` standard value set, **Event** is
no longer marked as the default, so no Type value is selected on new Campaigns. The
same default was also cleared from the `Type` picklist on both the `Parent_Campaign` and
`Sub_Campaign` record types, since a record type default would override the value set.
All seven Type values (Content Download, Demo Request, Event, Onsite Enquiry, Other,
Webinar, ZoomInfo) are still available on both record types.

**Type required on the Beacon Sub Campaign Record Page.** On
`Beacon_Sub_Campaign_Record_Page`, the `Record.Type` field instance's `uiBehavior` was
changed from `none` to `required`. Type is required only on Sub Campaigns, through the
Lightning page and not at the field level. Without a default, a new Sub Campaign can't be
saved until someone picks a Type. Parent Campaigns are unaffected, because the parent page
shows **Line of Business** in place of Type.

**Event picklists added to Campaign record types.** The four restricted picklists from
the `UAT-Testing-Updates` round were not yet enabled on either Campaign record type, so
they showed no values on those records. These picklists are now listed on both
`Parent_Campaign` and `Sub_Campaign`, with every value enabled and no default:

- `Attendance_Format__c`: Attended, Sponsored
- `Event_Country__c`: all 239 values from the **Countries** global value set
- `Event_Region__c`: Africa, Antarctica, Asia, Europe, Latin America, North America, Oceania
- `Line_of_Business__c`: Beacon, Consulting

The other picklists on these record types still have the same values. Gearset re-sorted
them alphabetically in the file, so the diff is larger than the actual change.

**Contact Status defaults to New.** On `Contact.Contact_Status__c`, the **New** value is
now `default=true`, so new Contacts start at New. Existing
Contacts are not changed.

**Lead Layout.** On `Lead-Lead Layout`:

- **Title** and **Lead Source** changed from Edit to **Required**.
- **Currency** (`CurrencyIsoCode`) was added as a **Required** field at the bottom of the
  left-hand column of the first section, under Status.
- **Rating** was removed from the layout. The field was not deleted.
- The layout no longer excludes three standard buttons: `DataDotComClean`,
  `GenerateKnowledge`, and `OpenSlackRecordChannel`. Only `Submit` is still excluded.
  This came over with the Gearset commit of the org's layout. It may simply reflect what
  is already in the org, but it should be confirmed (see Post Deployment Items).

**Contact Layout.** On `Contact-Contact Layout`:

- **Title** and **Lead Type** (`Lead_Type__c`) changed from Edit to **Required**.
- **Currency** (`CurrencyIsoCode`) was added as a **Required** field at the bottom of the
  left-hand column of the first section, under Reports To.

These requirements are set on the page layouts, not on the fields, and no validation rules
were added. They apply when a user edits a record through the layout, but integrations,
imports, and flows can still save records without these values.

## Acceptance Criteria

1. **Campaign Type has no default.** Create a new Campaign with the **Parent Campaign**
   record type. Confirm that **Type** is blank, not set to Event. Repeat with **Sub
   Campaign**.
2. **Type is required on Sub Campaigns.** On a Parent Campaign, click **Sub Campaign**
   (or create a Campaign with the Sub Campaign record type). Leave **Type** blank and try
   to save. Confirm Salesforce blocks the save and flags Type as required. Pick a Type and
   confirm the record saves.
3. **Type is not required on Parent Campaigns.** Open a Parent Campaign on the Beacon
   Parent Campaign Record Page and edit it. Confirm you can save without a Type.
4. **Event picklists show values.** Edit a Sub Campaign and confirm:
   - **Attendance Format** offers Attended and Sponsored.
   - **Event Region** offers all seven regions.
   - **Event Country** offers the full country list.

   Repeat on a Parent Campaign. Also confirm **Line of Business** offers Beacon and
   Consulting.
5. **Contact Status default.** Create a new Contact and confirm **Contact Status**
   defaults to **New**.
6. **Contact required fields.** Create a new Contact and leave **Title**, **Lead Type**,
   and **Currency** blank. Confirm each one is flagged as required and the record can't be
   saved until all three are filled in.
7. **Lead required fields.** Create a new Lead and leave **Title**, **Lead Source**, and
   **Currency** blank. Confirm each one is flagged as required and the record can't be
   saved until all three are filled in.
8. **Rating removed from Lead.** Open a Lead record and edit it. Confirm **Rating** no
   longer appears on the layout.
9. **Existing records.** Edit an existing Lead or Contact that is missing Title, Lead
   Source, or Lead Type. Confirm the user is asked to fill in the missing value before
   saving.

## Post Deployment Items

- **Confirm the Lead layout button change.** The deployed `Lead-Lead Layout` no longer
  excludes the **Clean** (`DataDotComClean`), **Generate Knowledge**
  (`GenerateKnowledge`), and **Open Slack Record Channel** (`OpenSlackRecordChannel`)
  buttons. Check the Lead record page to confirm whether these buttons should appear.
  If they should stay hidden, add them back to the layout's excluded buttons.
- **Existing records missing newly required values.** Existing Leads with no Title or
  Lead Source, existing Contacts with no Title or Lead Type, and existing Sub Campaigns
  with no Type will force users to fill in the value the next time someone edits the
  record. Run a report and backfill these values if that would disrupt users.
- **Existing Contacts with blank Contact Status** are not backfilled by the new default.
  Update them in bulk if they should be New.

## Component Manifest

Github Branch: [UAT-Feedback-v3](https://github.com/aaroncrear/BeaconImplementation/tree/UAT-Feedback-v3)

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Standard Value Set | Campaign | CampaignType | Campaign Type | Updated | Removed Event as the default Type value. |
| 2 | Record Type | Campaign | Parent_Campaign | Parent Campaign | Updated | Removed the Type default (Event). Enabled all values for Attendance Format, Event Country, Event Region, and Line of Business. |
| 3 | Record Type | Campaign | Sub_Campaign | Sub Campaign | Updated | Removed the Type default (Event). Enabled all values for Attendance Format, Event Country, Event Region, and Line of Business. |
| 4 | Lightning Page (FlexiPage) | Campaign | Beacon_Sub_Campaign_Record_Page | Beacon Sub Campaign Record Page | Updated | Made the Type field required on the page. |
| 5 | Page Layout | Lead | Lead-Lead Layout | Lead Layout | Updated | Made Title and Lead Source required. Added Currency as required. Removed Rating. Three standard buttons are no longer excluded. |
| 6 | Page Layout | Contact | Contact-Contact Layout | Contact Layout | Updated | Made Title and Lead Type required. Added Currency as required. |
| 7 | Custom Field | Contact | Contact_Status__c | Contact Status | Updated | Set New as the default value. |
