# "Campaigns" – Release Notes

## Requirements

This build was deployed directly to the `Campaigns` branch via Gearset (no prior written
requirements doc was supplied alongside the deploy). Based on the metadata that was pushed, the
underlying business need was to give Beacon a structured Parent/Sub Campaign model with richer
categorization and ownership tracking on the `Campaign` object:

- Distinguish top-level ("Parent") campaigns from the campaigns that roll up under them ("Sub"),
  each with its own record type, page layout assignment, and Lightning record page.
- Capture additional campaign metadata needed for marketing/content reporting: content type,
  strategy type, event host, and which product module(s) a campaign relates to.
- Track named owners from the Marketing, Product, and ResOps teams (primary + secondary) against
  each campaign.
- Refresh the `Channels__c` picklist to match the channels Beacon actually uses today, and retire
  channels that are no longer used (without deleting historical data on existing records).
- Extend the existing Beacon persona permission sets so each persona can see (and, for Marketing
  and Salesforce Admin, edit) the new campaign fields, consistent with how the persona permission
  sets were built in the prior `beacon-permission-sets-jaq4s2` branch.
- When a Sub Campaign is created, automatically default its `Type` to the same value as its
  Parent Campaign's `Type`, so reporting on Sub Campaigns can rely on `Type` being populated
  without requiring the user to re-enter it.

## Release Notes

Two new record types were added to `Campaign`: `Parent_Campaign` ("Parent Campaign") and
`Sub_Campaign` ("Sub Campaign"), each carrying its own picklist value subsets for
`Beacon_Module_Family__c` and `Channels__c`. Two matching Lightning record pages were created —
`Beacon_Parent_Campaign_Record_Page` and `Beacon_Sub_Campaign_Record_Page` — both built on the
two-column desktop record page template with a highlights panel, field sections, and a related
list quick-links container. All 23 profiles in this repo (including Admin and Standard) had
`layoutAssignments` added, mapping both new record types to the existing `Campaign-Campaign
Layout` — i.e. both record types use the same page layout, differentiated by record page rather
than by layout.

Ten new fields were added to `Campaign`:

| Field | Type | Purpose |
|---|---|---|
| `Content_Type__c` | Picklist | Content Type (Infographic, Webinar, Webinar Recording, Newsletters, Brochure, Conference Reports, Market Reports, Landscape Reviews, Thought Leadership) |
| `Strategy_Type__c` | Picklist | Strategy Type (New Business, ABM) |
| `Host__c` | Text(255) | The event host |
| `Related_Modules__c` | Multi-select Picklist | Related Modules, drawn from the existing `Primary_Module` value set |
| `Marketing_Primary__c` / `Marketing_Secondary__c` | Lookup(User) | Primary/secondary Marketing owner for the campaign |
| `Product_Primary__c` / `Product_Secondary__c` | Lookup(User) | Primary/secondary Product owner for the campaign |
| `ResOps_Primary__c` / `ResOps_Secondary__c` | Lookup(User) | Primary/secondary ResOps owner for the campaign |

The existing `Channels__c` picklist was refreshed: `AI Engines`, `Email - HubSpot`, `Google Ads`,
`In-Product`, `LinkedIn (Organic)`, `Organic Search`, and `Remarketing`/`Third Party` were added as
active values (alongside the previously-existing `Email - SendGrid`, `HW Event Onsite`, `Landing
Page (Organic)`, and `LinkedIn (Paid)`, which remain active). `ABM - Email`, `Direct Marketing`,
`Email - Pardot`, `Email, Events`, `HW Event Collab`, `PPC`, `Social Media (Organic)`, and `Social
Media (Paid)` were set to `isActive=false` rather than deleted, so existing records/reports that
reference these values on historical Campaigns are preserved.

The standard `Campaign.Type` picklist (`CampaignType` standard value set) was defined explicitly
for the first time in this repo, with values `Content Download`, `Demo Request`, `Event`
(default), `Onsite Enquiry`, `Other`, `Webinar`, `ZoomInfo`.

The `Campaign-Campaign Layout` page layout was updated: `Module__c` was swapped out for
`Primary_Module__c` in the top info section, `Content_Type__c` and `Strategy_Type__c` were added
to that same section, `Related_Modules__c` was added to the description section, a `Related Entity
History` related list was added, and the layout's excluded quick-action button was changed from
`OpenSlackRecordChannel` to `GenerateKnowledge`. A new field, `Primary_Module__c` (Picklist:
ADC, Bispecific, Cancer Vaccines, Cell Therapy, Checkpoint, CVRM, Cytokine, DDR, General, Gene
Therapy, Immune Tolerance, Lung Cancer, Microbiome, Neuro-Degenerative, Neurology, Neuroscience,
Oncology, Oncolytic Viruses, Psychiatric, RAS, RNA, Targeted Radiopharmaceuticals, TPD, plus the
inactive legacy value Adoptive Cell), was created to back that layout field — the layout and
persona permission sets already referenced `Primary_Module__c`, but the field itself hadn't been
created yet in this repo until this deploy.

Both Lightning record pages were tuned for data entry: on `Beacon_Parent_Campaign_Record_Page`,
the `Type` field was changed from optional to required. On `Beacon_Sub_Campaign_Record_Page`,
`ParentId` was changed from optional to required (a Sub Campaign must reference a Parent
Campaign), `Type` was changed from editable to read-only (since `Campaign - On Create - Before
Save` now sets it automatically from the parent), a `Change Record Type` quick action was added
to the highlights panel alongside the existing `Change Owner` action, and the `Host__c` /
`Website__c` fields were reordered (Host now appears before Website).

All nine existing Beacon persona permission sets (`Beacon Executive`, `Beacon Sales`, `Beacon
Marketing`, `Beacon Customer Success`, `Beacon ResOps`, `Beacon Consulting`, `Beacon Product`,
`Beacon Tech`, `Beacon Salesforce Admin`) were updated with field-level security for the nine new
lookup/picklist/text fields above (`Related_Modules__c` was not added to the permission sets).
Read access was granted to every persona; `Beacon Marketing` and `Beacon Salesforce Admin`
additionally received Edit access, consistent with Marketing already holding
Create/Read/Edit/Delete on Campaign and Salesforce Admin holding full CRUD on all tracked fields.
`Beacon Marketing` and `Beacon Salesforce Admin` were granted `recordTypeVisibilities` for both
`Campaign.Sub_Campaign` and, in this latest push, `Campaign.Parent_Campaign` — closing the gap
flagged in the previous Post Deployment Items, where only `Sub_Campaign` visibility had been
granted.

A record-triggered flow, `Campaign - On Create - Before Save`, was added to keep a Sub Campaign's
`Type` in sync with its Parent Campaign at creation time. It runs before save, only on Campaign
insert, and its entry criteria uses a formula —
`{!$Record.RecordType.DeveloperName} = "Sub_Campaign"` — rather than a hardcoded `RecordTypeId`
(which isn't portable between orgs) or a plain field filter, so it only fires for Sub Campaigns.
When it fires, it looks up the Parent Campaign via `$Record.ParentId`; if a parent is found, it
assigns the parent's `Type` directly onto `$Record.Type`. Because the flow runs before save, that
assignment is picked up by the same save operation with no extra DML — this replaced an earlier
after-save version of this flow (`Campaign - On Crear - After Save`, which used an explicit
Record Update element) that has been deleted and superseded by this one. If `ParentId` is blank
(no parent selected), the flow's decision element detects that the lookup found no record and
skips the assignment rather than faulting.

## Acceptance Criteria

1. In Object Manager > Campaign > Record Types, confirm `Parent Campaign` and `Sub Campaign`
   record types exist and are active.
2. Create a new Campaign of each record type and confirm the Lightning record page shown is
   `Beacon Parent Campaign Record Page` / `Beacon Sub Campaign Record Page` respectively (after
   completing the manual activation described in Post Deployment Items), and that both use the
   `Campaign Layout` page layout.
3. On the Campaign layout, confirm the info section shows `Primary Module` (not `Module`),
   `Content Type`, and `Strategy Type`, and the description section shows `Related Modules`.
4. Confirm the Campaign detail page shows a "Related Entity History" related list, and that the
   `Generate Knowledge` quick action is hidden (no longer `Open Slack Record Channel`, which is now
   available again).
5. Open the `Channels` picklist on a Campaign record and confirm `AI Engines`, `Email - HubSpot`,
   `Google Ads`, `In-Product`, `LinkedIn (Organic)`, `Organic Search`, `Remarketing`, and `Third
   Party` are selectable, and that `ABM - Email`, `Direct Marketing`, `Email - Pardot`, `Email,
   Events`, `HW Event Collab`, `PPC`, `Social Media (Organic)`, and `Social Media (Paid)` are not
   (but still display correctly on any existing record that already has one of those values set).
6. Confirm the `Type` field on Campaign offers `Content Download`, `Demo Request`, `Event`
   (default), `Onsite Enquiry`, `Other`, `Webinar`, `ZoomInfo`.
7. For each of the nine Beacon persona permission sets, open Object Settings > Campaign > Fields
   and confirm `Content Type`, `Host`, `Marketing Primary`, `Marketing Secondary`, `Product
   Primary`, `Product Secondary`, `ResOps Primary`, `ResOps Secondary`, and `Strategy Type` show
   Read checked; confirm only `Beacon Marketing` and `Beacon Salesforce Admin` show Edit checked
   for those fields.
8. Assign `Beacon Marketing` or `Beacon Salesforce Admin` to a test user and confirm they can
   select the `Sub Campaign` record type when creating a Campaign; confirm a user with a
   different persona's permission set cannot.
9. Confirm all 23 profiles deploy cleanly with the two new `layoutAssignments` entries for
   `Campaign.Parent_Campaign` and `Campaign.Sub_Campaign`.
10. Create a Parent Campaign with `Type` set to a specific value (e.g. `Webinar`), then create a
    Sub Campaign with that Parent Campaign as its `ParentId`. Confirm the new Sub Campaign's
    `Type` is set to match the Parent Campaign's `Type` immediately on save.
11. Create a Sub Campaign with no `ParentId` set and confirm it saves successfully with no error,
    and that `Type` is left as whatever the user set (not overwritten or blanked).
12. Create a Parent Campaign and confirm its `Type` is unaffected — the flow should not fire for
    the Parent Campaign record type.
13. Update an existing Sub Campaign's `Type` field directly and confirm it is not reset — the flow
    only fires on Campaign creation, not on update.
14. Confirm `Campaign - On Create - Before Save` shows `Status = Active` in Setup > Flows, and
    that `Campaign - On Crear - After Save` no longer exists.
15. Open Object Manager > Campaign > Fields and confirm `Primary Module` exists as a Picklist
    field with the 23 active values listed in the Release Notes section (and that `Adoptive Cell`
    is present but inactive). Confirm the Campaign Layout's info section shows `Primary Module`
    populated with a value, not blank/broken.
16. On the Parent Campaign record page, confirm `Type` is a required field (record can't be saved
    without it).
17. On the Sub Campaign record page, confirm `Parent Campaign` (ParentId) is required, `Type` is
    read-only (can't be hand-edited — only set by the flow), and the `Change Record Type` quick
    action is available from the highlights panel alongside `Change Owner`.
18. For `Beacon Marketing` and `Beacon Salesforce Admin`, confirm Object Settings > Campaign shows
    both `Parent Campaign` and `Sub Campaign` record types visible (not just `Sub Campaign`).

## Post Deployment Items

- **Activate the new Lightning record pages.** `Beacon_Parent_Campaign_Record_Page` and
  `Beacon_Sub_Campaign_Record_Page` were deployed but page activation/assignment (which app,
  record type, and profile combination each page is shown for) is set through Lightning App
  Builder in the org and is not captured in this metadata — activate each page against its
  matching record type after deploy.
- ~~**Confirm `Parent_Campaign` record-type visibility.**~~ Resolved in this push: `Beacon
  Marketing` and `Beacon Salesforce Admin` now hold `recordTypeVisibilities` for both
  `Campaign.Parent_Campaign` and `Campaign.Sub_Campaign`. The other seven persona permission sets
  still have no explicit `recordTypeVisibilities` for either record type — confirm with the
  business whether any other persona should be able to create Parent or Sub Campaigns directly.
- **Confirm `Related_Modules__c` field-level security.** This field was not added to any of the
  nine Beacon persona permission sets in this deploy — confirm whether it needs Read/Edit access
  granted the same way the other nine new fields were.
- No requirements doc accompanied this deploy — recommend documenting the actual business
  requirements (who requested the Parent/Sub Campaign model, and the target audience for each new
  field) for future reference.
- `Campaign - On Create - Before Save` only syncs `Type` at Sub Campaign creation time. If a Sub
  Campaign's `ParentId` is changed after creation, or the Parent Campaign's `Type` changes later,
  the Sub Campaign's `Type` is not automatically re-synced. Confirm with the business whether that
  ongoing-sync behavior is needed; if so, the flow's trigger would need to change from Create to
  Create and Update (and, if it needs to update the Parent Campaign or another record, an
  after-save Record Update element rather than a before-save $Record assignment).

## Component Manifest

Github Branch: https://github.com/aaroncrear/BeaconImplementation/tree/Campaigns

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Record Type | Campaign | Parent_Campaign | Parent Campaign | Created | Record type for top-level Parent Campaigns. |
| 2 | Record Type | Campaign | Sub_Campaign | Sub Campaign | Created | Record type for Sub Campaigns that roll up under a Parent Campaign. |
| 3 | Field | Campaign | Content_Type__c | Content Type | Created | Picklist capturing the type of content associated with the campaign. |
| 4 | Field | Campaign | Strategy_Type__c | Strategy Type | Created | Picklist capturing whether the campaign is New Business or ABM strategy. |
| 5 | Field | Campaign | Host__c | Host | Created | Text field for the event host. |
| 6 | Field | Campaign | Related_Modules__c | Related Modules | Created | Multi-select picklist of related product modules, using the existing Primary_Module value set. |
| 7 | Field | Campaign | Marketing_Primary__c | Marketing Primary | Created | Lookup to User; primary Marketing owner of the campaign. |
| 8 | Field | Campaign | Marketing_Secondary__c | Marketing Secondary | Created | Lookup to User; secondary Marketing owner of the campaign. |
| 9 | Field | Campaign | Product_Primary__c | Product Primary | Created | Lookup to User; primary Product owner of the campaign. |
| 10 | Field | Campaign | Product_Secondary__c | Product Secondary | Created | Lookup to User; secondary Product owner of the campaign. |
| 11 | Field | Campaign | ResOps_Primary__c | ResOps Primary | Created | Lookup to User; primary ResOps owner of the campaign. |
| 12 | Field | Campaign | ResOps_Secondary__c | ResOps Secondary | Created | Lookup to User; secondary ResOps owner of the campaign. |
| 13 | Field | Campaign | Channels__c | Channels | Updated | Added active values AI Engines, Email - HubSpot, Google Ads, In-Product, LinkedIn (Organic), Organic Search, Remarketing, Third Party; deactivated ABM - Email, Direct Marketing, Email - Pardot, Email/Events, HW Event Collab, PPC, Social Media (Organic), Social Media (Paid). |
| 14 | Standard Value Set | Campaign | CampaignType | Campaign Type | Created | Defined the standard Type picklist values for Campaign (Content Download, Demo Request, Event [default], Onsite Enquiry, Other, Webinar, ZoomInfo). |
| 15 | Layout | Campaign | Campaign-Campaign Layout | Campaign Layout | Updated | Replaced Module__c with Primary_Module__c; added Content_Type__c and Strategy_Type__c to the info section and Related_Modules__c to the description section; added Related Entity History related list; changed excluded button from OpenSlackRecordChannel to GenerateKnowledge. |
| 16 | Flexipage | Campaign | Beacon_Parent_Campaign_Record_Page | Beacon Parent Campaign Record Page | Created | Lightning record page for the Parent Campaign record type; Type field set to required. |
| 17 | Flexipage | Campaign | Beacon_Sub_Campaign_Record_Page | Beacon Sub Campaign Record Page | Created | Lightning record page for the Sub Campaign record type; ParentId set to required, Type set to read-only, added Change Record Type quick action, reordered Host/Website fields. |
| 53 | Field | Campaign | Primary_Module__c | Primary Module | Created | Picklist backing the Campaign Layout's "Primary Module" field (23 active module values plus inactive legacy value Adoptive Cell); already referenced by the layout and persona permission sets but was missing as a field until this deploy. |
| 54 | Permission Set | N/A | Beacon_Marketing_Object_Tab_FLS | Beacon Marketing - Object, Tab, FLS | Updated | Added recordTypeVisibilities for Campaign.Parent_Campaign (already had Campaign.Sub_Campaign). |
| 55 | Permission Set | N/A | Beacon_Salesforce_Admin_Object_Tab_FLS | Beacon Salesforce Admin - Object, Tab, FLS | Updated | Added recordTypeVisibilities for Campaign.Parent_Campaign (already had Campaign.Sub_Campaign). |
| 18 | Permission Set | N/A | Beacon_Executive_Object_Tab_FLS | Beacon Executive - Object, Tab, FLS | Updated | Added Read access to the 9 new Campaign fields (Content_Type__c, Host__c, Marketing_Primary__c, Marketing_Secondary__c, Product_Primary__c, Product_Secondary__c, ResOps_Primary__c, ResOps_Secondary__c, Strategy_Type__c). |
| 19 | Permission Set | N/A | Beacon_Sales_Object_Tab_FLS | Beacon Sales - Object, Tab, FLS | Updated | Added Read access to the 9 new Campaign fields. |
| 20 | Permission Set | N/A | Beacon_Marketing_Object_Tab_FLS | Beacon Marketing - Object, Tab, FLS | Updated | Added Read/Edit access to the 9 new Campaign fields and recordTypeVisibilities for Campaign.Sub_Campaign. |
| 21 | Permission Set | N/A | Beacon_Customer_Success_Object_Tab_FLS | Beacon Customer Success - Object, Tab, FLS | Updated | Added Read access to the 9 new Campaign fields. |
| 22 | Permission Set | N/A | Beacon_ResOps_Object_Tab_FLS | Beacon ResOps - Object, Tab, FLS | Updated | Added Read access to the 9 new Campaign fields. |
| 23 | Permission Set | N/A | Beacon_Consulting_Object_Tab_FLS | Beacon Consulting - Object, Tab, FLS | Updated | Added Read access to the 9 new Campaign fields. |
| 24 | Permission Set | N/A | Beacon_Product_Object_Tab_FLS | Beacon Product - Object, Tab, FLS | Updated | Added Read access to the 9 new Campaign fields. |
| 25 | Permission Set | N/A | Beacon_Tech_Object_Tab_FLS | Beacon Tech - Object, Tab, FLS | Updated | Added Read access to the 9 new Campaign fields. |
| 26 | Permission Set | N/A | Beacon_Salesforce_Admin_Object_Tab_FLS | Beacon Salesforce Admin - Object, Tab, FLS | Updated | Added Read/Edit access to the 9 new Campaign fields and recordTypeVisibilities for Campaign.Sub_Campaign. |
| 27 | Profile | N/A | Admin | Admin | Updated | Added layoutAssignments mapping Campaign.Parent_Campaign and Campaign.Sub_Campaign record types to the Campaign Layout. |
| 28 | Profile | N/A | Analytics Cloud Integration User | Analytics Cloud Integration User | Updated | Added layoutAssignments mapping Campaign.Parent_Campaign and Campaign.Sub_Campaign record types to the Campaign Layout. |
| 29 | Profile | N/A | Analytics Cloud Security User | Analytics Cloud Security User | Updated | Added layoutAssignments mapping Campaign.Parent_Campaign and Campaign.Sub_Campaign record types to the Campaign Layout. |
| 30 | Profile | N/A | CPQ Integration User | CPQ Integration User | Updated | Added layoutAssignments mapping Campaign.Parent_Campaign and Campaign.Sub_Campaign record types to the Campaign Layout. |
| 31 | Profile | N/A | Chatter External User | Chatter External User | Updated | Added layoutAssignments mapping Campaign.Parent_Campaign and Campaign.Sub_Campaign record types to the Campaign Layout. |
| 32 | Profile | N/A | Chatter Free User | Chatter Free User | Updated | Added layoutAssignments mapping Campaign.Parent_Campaign and Campaign.Sub_Campaign record types to the Campaign Layout. |
| 33 | Profile | N/A | Chatter Moderator User | Chatter Moderator User | Updated | Added layoutAssignments mapping Campaign.Parent_Campaign and Campaign.Sub_Campaign record types to the Campaign Layout. |
| 34 | Profile | N/A | ContractManager | ContractManager | Updated | Added layoutAssignments mapping Campaign.Parent_Campaign and Campaign.Sub_Campaign record types to the Campaign Layout. |
| 35 | Profile | N/A | Einstein Agent User | Einstein Agent User | Updated | Added layoutAssignments mapping Campaign.Parent_Campaign and Campaign.Sub_Campaign record types to the Campaign Layout. |
| 36 | Profile | N/A | End User | End User | Updated | Added layoutAssignments mapping Campaign.Parent_Campaign and Campaign.Sub_Campaign record types to the Campaign Layout. |
| 37 | Profile | N/A | Executive Sponsor | Executive Sponsor | Updated | Added layoutAssignments mapping Campaign.Parent_Campaign and Campaign.Sub_Campaign record types to the Campaign Layout. |
| 38 | Profile | N/A | External Apps Login User | External Apps Login User | Updated | Added layoutAssignments mapping Campaign.Parent_Campaign and Campaign.Sub_Campaign record types to the Campaign Layout. |
| 39 | Profile | N/A | External Einstein Agent User | External Einstein Agent User | Updated | Added layoutAssignments mapping Campaign.Parent_Campaign and Campaign.Sub_Campaign record types to the Campaign Layout. |
| 40 | Profile | N/A | Guest License User | Guest License User | Updated | Added layoutAssignments mapping Campaign.Parent_Campaign and Campaign.Sub_Campaign record types to the Campaign Layout. |
| 41 | Profile | N/A | Identity User | Identity User | Updated | Added layoutAssignments mapping Campaign.Parent_Campaign and Campaign.Sub_Campaign record types to the Campaign Layout. |
| 42 | Profile | N/A | MarketingProfile | MarketingProfile | Updated | Added layoutAssignments mapping Campaign.Parent_Campaign and Campaign.Sub_Campaign record types to the Campaign Layout. |
| 43 | Profile | N/A | Minimum Access - API Only Integrations | Minimum Access - API Only Integrations | Updated | Added layoutAssignments mapping Campaign.Parent_Campaign and Campaign.Sub_Campaign record types to the Campaign Layout. |
| 44 | Profile | N/A | Minimum Access - Salesforce | Minimum Access - Salesforce | Updated | Added layoutAssignments mapping Campaign.Parent_Campaign and Campaign.Sub_Campaign record types to the Campaign Layout. |
| 45 | Profile | N/A | Read Only | Read Only | Updated | Added layoutAssignments mapping Campaign.Parent_Campaign and Campaign.Sub_Campaign record types to the Campaign Layout. |
| 46 | Profile | N/A | Sales Insights Integration User | Sales Insights Integration User | Updated | Added layoutAssignments mapping Campaign.Parent_Campaign and Campaign.Sub_Campaign record types to the Campaign Layout. |
| 47 | Profile | N/A | Salesforce API Only System Integrations | Salesforce API Only System Integrations | Updated | Added layoutAssignments mapping Campaign.Parent_Campaign and Campaign.Sub_Campaign record types to the Campaign Layout. |
| 48 | Profile | N/A | SalesforceIQ Integration User | SalesforceIQ Integration User | Updated | Added layoutAssignments mapping Campaign.Parent_Campaign and Campaign.Sub_Campaign record types to the Campaign Layout. |
| 49 | Profile | N/A | SolutionManager | SolutionManager | Updated | Added layoutAssignments mapping Campaign.Parent_Campaign and Campaign.Sub_Campaign record types to the Campaign Layout. |
| 50 | Profile | N/A | Standard | Standard | Updated | Added layoutAssignments mapping Campaign.Parent_Campaign and Campaign.Sub_Campaign record types to the Campaign Layout. |
| 51 | Flow | Campaign | Campaign_On_Crear_After_Save | Campaign - On Crear - After Save | Deleted | Removed and superseded by Campaign_On_Create_Before_Save (row 52), which replicates the same lookup/update logic on a before-save trigger. |
| 52 | Flow | Campaign | Campaign_On_Create_Before_Save | Campaign - On Create - Before Save | Created | Record-triggered flow (before save, on create, formula entry criteria {!$Record.RecordType.DeveloperName} = "Sub_Campaign") that looks up the Parent Campaign via ParentId and assigns its Type onto the triggering Sub Campaign's Type field. |
