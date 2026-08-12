# "claude/release-notes-05pbde" – Release Notes

## Requirements

This build is the foundational Beacon sales data model, built directly in a sandbox with
Gearset and committed to this repo as a single "Commit of Salesforce metadata by Gearset."
Working backward from what was configured, the business needed:

- **Account segmentation** by industry ("LS Company Type"), size, and trailing revenue, so
  Life Sciences accounts can be classified and reported on consistently.
- **Lead/Contact qualification and compliance tracking** — a granular Lead Type (drill-down
  from the existing Lead Source), a Contact Status field with a Path Assistant to visualize
  outreach progress, and Blacklist/Deceased flags with a reason picklist to keep the team from
  contacting people they shouldn't.
- **Campaign attribution and credit-splitting** across Account Managers (AM), SDRs, and
  Sponsorship Managers, each needing both a named owner (lookup to User) and a percentage/term
  split (text field), for up to 6 SDRs and 3 AMs/Sponsorship Managers per campaign.
- **A real Opportunity sales process** — three record types (Consulting, Subscription New,
  Subscription Renewal), each with its own stage set, forecast categories, and finance/
  invoicing fields (deposits, payment terms, invoice numbers), replacing a single undifferentiated
  pipeline.
- **Record pages and layouts** reorganized around the new fields, and standard Account/
  Opportunity Team Member layouts so team-selling roles are visible.

## Release Notes

**Global picklists.** Five reusable Global Value Sets were added so the same option list can be
attached to multiple objects without re-defining it per field: `Blacklisted_Reason` (8 values),
`Lead_Type` (26 values covering channels like Webinar Attendee, Content Download, HW Conference,
and referral sources), `Primary_Module` (24 therapeutic/technology areas, e.g. ADC, Cell Therapy,
Oncology, RNA), `Region` (7 continents), and `United_States_Time_Zones` (4 US zones).

**Account** gained 7 fields: `LS_Company_Type__c` (picklist, Life Sciences classification —
MarCap Pharma tiers, Academic, CDMO/CMO, CRO, etc.), `Segment__c` (a formula `Text` field that
derives a Beacon segment label from `LS_Company_Type__c`), `Size__c` (a formula `Text` field
based on `Total_Revenue_Last_365_Days__c`), `Total_Revenue_Last_365_Days__c` (Currency,
non-converted trailing revenue), `Total_Revenue__c` (Summary/roll-up of won Opportunity Amount),
`Region__c` and `United_States_Time_Zone__c` (both driven by the new global value sets).

**Campaign** gained 18 fields for team-based attribution: `SDR_1__c`–`SDR_6__c` and
`Sponsorship_Manager_1__c`–`Sponsorship_Manager_3__c` are `User` lookups; `AM_Split_1__c`–
`AM_Split_3__c` and `SDR_Split_1__c`–`SDR_Split_6__c` are 20-character text fields holding the
corresponding split/percentage. The Campaign layout gained a "Splits" section (all 18 new fields)
and a "Hierarchy Statistics" section (standard hierarchy roll-up fields), plus `Module__c`,
`Beacon_Module_Family__c`, `Content_Family__c`, `Stage`, `Website__c`, `Channels__c`,
`BusinessUnitId`, and `CampaignMemberRecordTypeId` in the main detail section.

**Contact** gained 7 fields: `Blacklisted__c` / `Blacklisted_Reason__c` (Checkbox + picklist),
`Deceased__c` (Checkbox), `Contact_Status__c` (picklist: Do Not Engage, Unqualified, New,
Nurturing, Working, Active Opp), `Lead_Type__c`, `Region__c`, and `United_States_Time_Zone__c`.
A `Contact_Status.pathAssistant` was added on the `Contact_Status__c` field (master record type)
so reps see outreach progress as a visual path. A new `Contact_Compact_Layout` (Name, Account,
Title, Phone, Mobile, Email) drives the highlights panel. The Contact layout gained "Compliance &
Data Quality" (Blacklisted, HasOptedOutOfEmail, DoNotCall, Blacklisted Reason, Deceased,
Description) and address/region fields alongside `Contact_Status__c`.

**Lead** gained 6 of the same fields as Contact (no `Contact_Status__c`, since Leads use the
standard `Status` field): `Blacklisted__c`, `Blacklisted_Reason__c`, `Deceased__c`,
`Lead_Type__c`, `Region__c`, `United_States_Time_Zone__c`. The Lead layout gained an "Address
Information" section (Address, Region, US Time Zone) and a "Compliance & Data Quality" section
mirroring Contact's.

**Opportunity** is the largest change. 10 new fields were added: `Primary_Module__c` (picklist,
Beacon module), `Lead_Type__c` and `MIR__c` (a formula `Text` field — `IF(ISPICKVAL(LeadSource,
"Marketing"), "Yes", "No")` — flagging marketing-influenced revenue), `Director_Probability__c`
(Percent) and `Director_Expected_Revenue__c` (a formula `Currency` field, `Amount *
Director_Probability__c`), and 5 finance/invoicing fields: `Unique_Invoice_No__c`,
`Payment_Status__c` (Unpaid/Paid/Partially Paid), `Deposit_Amount__c`, `Deposit_Pay_Date__c`, and
`Full_Amount_Pay_Date__c`. A new `Opportunity_Companct_Layout` compact layout (Name, Account,
Amount, Close Date, Owner) was added — note the API name carries a typo ("Companct") though the
label reads correctly as "Opportunity Compact Layout"; see Post Deployment Items.

Three **Business Processes** define distinct stage sets for three new **Record Types**:

| Business Process / Record Type | Stages |
|---|---|
| Consulting | Needs Analysis → Proposal → Contract → Closed Won / Closed Lost |
| Subscription New | Demo Booked → Demo Completed → Proposal → Contract → Closed Won / Closed Lost |
| Subscription Renewal | Onboarding → Proposal → Contract → Closed Won / Closed Lost |

The `OpportunityStage` standard value set was extended to the full union of stages needed across
all three processes (Onboarding, Needs Analysis, Demo Booked, Demo Completed, Proposal, Contract,
Closed Won, Closed Lost) with forecast categories and probabilities assigned per stage (e.g.
Demo Booked = Pipeline/30%, Proposal = Best Case/60%, Contract = Forecast/90%). The
`LeadStatus` standard value set was also updated (Do Not Engage, Unqualified, New (default),
Working, Nurturing, Qualified (converted)) to align Lead qualification stages with the new
`Contact_Status__c` path.

Each of the 3 record types enables the full set of values for `Lead_Type__c`,
`Primary_Module__c`, `Payment_Status__c`, `Loss_Reason__c`, `Invoice_Terms__c`, `LeadSource`,
`Split_Payment__c`, `Split_Payment_1_Term__c`, `Split_Payment_2_Term__c`, and `Type` (no per-record-type
restrictions were applied — every value is available on every record type). The Opportunity
layout was reorganized into "Opportunity Influence" (LeadSource, Lead Type, MIR, Referred By),
"Forecasting" (demo/proposal dates, Expected Revenue, Director Expected Revenue), "CPQ" (Pricebook,
Synced Quote, Price Increase Value, Contract, Previous Yield), and "Finance and Invoicing" (the 5
new finance fields plus Invoice Terms, Payment Status, Date Payment Taken, Split Payment terms),
alongside `RecordTypeId`, `Primary_Module__c`, `Renewal_Date__c`, `Director_Probability__c`, and
`Loss_Reason__c` in the main section.

**Record pages.** Five new Lightning Record Pages were added — `Beacon_Account_Record_Page`,
`Beacon_Campaign_Record_Page`, `Beacon_Contact_Record_Page`, `Beacon_Lead_Record_Page`, and
`Beacon_Opportunity_Record_Page` — each built from Region/Facet components to host the
reorganized layouts.

**Team selling.** Two new standard layouts, `AccountTeamMember-Account Team Member Layout`
(Account, Team Member Role, Opportunity/Contact/Account/Case Access Levels, User) and
`OpportunityTeamMember-Opportunity Team Member Layout` (Opportunity, Team Member Role, User,
Opportunity Access Level), were added so Account Team and Opportunity Team related lists render
correctly now that AM/SDR/Sponsorship Manager roles exist.

**Access.** All 24 profiles in this repo (Admin, Standard, Read Only, MarketingProfile, and 20
integration/system profiles) were updated with 4 identical `layoutAssignments`: the new
Opportunity layout assigned to each of the 3 new record types, plus the new Opportunity Team
Member layout. The `sfdcInternalInt__sfdc_a360` (Salesforce Analytics/Einstein integration)
permission set picked up field-level access to 6 of the new fields it needs visibility into:
Edit on `Contact.Region__c`, `Contact.United_States_Time_Zone__c`, `Lead.Lead_Type__c`,
`Lead.Region__c`, `Lead.United_States_Time_Zone__c`, and Read-only on `Lead.Blacklisted__c`.

## Acceptance Criteria

1. In Object Manager, confirm the 5 new Global Value Sets exist (Setup > Picklist Value Sets):
   Blacklisted Reason (8 values), Lead Type (26 values), Primary Module (24 values), Region
   (7 values), United States Time Zones (4 values).
2. On Account, confirm the 7 new fields exist with the types and formulas described above;
   create/edit an Account and confirm `Segment__c` and `Size__c` recalculate when
   `LS_Company_Type__c` / `Total_Revenue_Last_365_Days__c` change, and that `Total_Revenue__c`
   rolls up won Opportunity Amounts.
3. On Campaign, confirm all 18 split/attribution fields are visible in the new "Splits" section
   and the "Hierarchy Statistics" section renders hierarchy roll-up values.
4. On Contact, confirm the Path Assistant appears on the record page keyed off
   `Contact_Status__c` with the 6 stages listed above, the "Compliance & Data Quality" section
   shows on the layout, and the Contact highlights panel uses the new Compact Layout
   (Name/Account/Title/Phone/Mobile/Email).
5. On Lead, confirm the "Address Information" and "Compliance & Data Quality" sections appear
   with the 6 new fields.
6. On Opportunity, create one record per new record type (Consulting, Subscription New,
   Subscription Renewal) and confirm each Business Process only exposes its own stage list, and
   that stage probability/forecast category matches the table in the Release Notes section.
7. Confirm `Director_Expected_Revenue__c` recalculates as `Amount * Director_Probability__c`,
   and `MIR__c` returns "Yes" only when Lead Source = Marketing.
8. Confirm the "Finance and Invoicing", "Forecasting", "CPQ", and "Opportunity Influence"
   sections render on the Opportunity layout with the fields listed in the Release Notes.
9. Confirm the 5 new Lightning Record Pages (`Beacon_*_Record_Page`) are assigned/activatable
   for Account, Campaign, Contact, Lead, and Opportunity.
10. Add an Account Team Member and an Opportunity Team Member to a test record and confirm the
    new team member layouts render Team Member Role, Access Levels, and User correctly.
11. For each of the 24 profiles, confirm the Opportunity layout is assigned to all 3 new record
    types, and the Opportunity Team Member layout is assigned.
12. Confirm the `sfdcInternalInt__sfdc_a360` permission set has Edit access to
    `Contact.Region__c`, `Contact.United_States_Time_Zone__c`, `Lead.Lead_Type__c`,
    `Lead.Region__c`, `Lead.United_States_Time_Zone__c`, and Read-only access to
    `Lead.Blacklisted__c`.
13. Confirm the full build deploys cleanly to a sandbox with no metadata errors.

## Post Deployment Items

- **Compact layout API name typo**: `Opportunity_Companct_Layout` (should read "Compact") was
  deployed with that misspelling as its API name; the label is correct ("Opportunity Compact
  Layout"). Renaming the API name now requires deleting and recreating the compact layout (API
  names are immutable in Salesforce) — confirm with the business whether that's worth doing, or
  leave as-is since the label is what users see.
- Assign the 3 new Opportunity record types (Consulting, Subscription New, Subscription Renewal)
  to the appropriate profiles/permission sets that need to create Opportunities of each type —
  this build only added the layout assignment, not record type visibility/default settings.
- Activate and assign the 5 new `Beacon_*_Record_Page` Lightning Record Pages as the default
  record page (App, org, or profile-level) for each object — this build added the pages but did
  not set page assignments.
- Backfill `LS_Company_Type__c`, `Region__c`, `United_States_Time_Zone__c`, and `Lead_Type__c` on
  existing Account/Contact/Lead/Opportunity records — these are net-new fields with no default
  values, so existing records will show blank until populated.
- Determine field-level security / permission set access for the ~50 new fields on the 8
  persona permission sets (Beacon Executive, Sales, Marketing, Customer Success, ResOps,
  Consulting, Product, Tech, Salesforce Admin) introduced in a prior branch — this build did not
  touch those permission sets, so the new fields are not yet exposed to non-admin personas.
- Confirm whether `sfdc_a360`'s Read-only access to `Lead.Blacklisted__c` (vs. Edit on the other
  5 fields it gained) is intentional or a Gearset comparison artifact.

## Component Manifest

Github Branch: https://github.com/aaroncrear/beaconimplementation/tree/claude/release-notes-05pbde

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Global Value Set | N/A | Blacklisted_Reason | Blacklisted Reason | Created | 8-value reason list (Competitor - Beacon/Event/Intelligence/Searchlight, Breach of Code of Conduct, Non-Paying Customer, Other, Sanctioned Country) shared by Contact and Lead. |
| 2 | Global Value Set | N/A | Lead_Type | Lead Type | Created | 26-value channel/source list (Active Inquiry, Content Download, Demo Request, Webinar Attendee, HW Conference, referral sources, etc.) shared by Contact, Lead, and Opportunity. |
| 3 | Global Value Set | N/A | Primary_Module | Primary Module | Created | 24 Life Sciences therapeutic/technology areas (ADC, Cell Therapy, Oncology, RNA, etc.) shared by Account and Opportunity. |
| 4 | Global Value Set | N/A | Region | Region | Created | 7 continents/regions shared by Account, Contact, and Lead. |
| 5 | Global Value Set | N/A | United_States_Time_Zones | United States Time Zones | Created | 4 US time zones shared by Account, Contact, and Lead. |
| 6 | Layout | Account | Account-Account Layout | Account Layout | Updated | Added the 7 new Account fields (LS Company Type, Segment, Size, Total Revenue, Total Revenue Last 365 Days, Region, US Time Zone) to the detail layout. |
| 7 | Layout | AccountTeamMember | AccountTeamMember-Account Team Member Layout | Account Team Member Layout | Created | Standard layout (Account, Team Member Role, Opportunity/Contact/Account/Case Access Levels, User) for the Account Team related list. |
| 8 | Layout | Campaign | Campaign-Campaign Layout | Campaign Layout | Updated | Added a Splits section (18 AM/SDR/Sponsorship Manager fields), a Hierarchy Statistics section, and Module/Content Family/Website/Channels fields. |
| 9 | Layout | Contact | Contact-Contact Layout | Contact Layout | Updated | Added Compliance & Data Quality and address/region sections with the 7 new Contact fields plus Contact Status. |
| 10 | Layout | Lead | Lead-Lead Layout | Lead Layout | Updated | Added Address Information and Compliance & Data Quality sections with the 6 new Lead fields. |
| 11 | Layout | Opportunity | Opportunity-Opportunity Layout | Opportunity Layout | Updated | Reorganized into Opportunity Influence, Forecasting, CPQ, and Finance and Invoicing sections; added the 10 new Opportunity fields plus RecordTypeId and Loss Reason. |
| 12 | Layout | OpportunityTeamMember | OpportunityTeamMember-Opportunity Team Member Layout | Opportunity Team Member Layout | Created | Standard layout (Opportunity, Team Member Role, User, Opportunity Access Level) for the Opportunity Team related list. |
| 13 | Field | Account | LS_Company_Type__c | LS Company Type | Created | Picklist classifying the account's Life Sciences company type (MarCap Pharma tiers, Academic, CDMO, CMO, CRO, etc.), used to drive Segment. |
| 14 | Field | Account | Region__c | Region | Created | Picklist from the Region global value set. |
| 15 | Field | Account | Segment__c | Segment | Created | Formula (Text) — derives a Beacon segment label from LS Company Type. |
| 16 | Field | Account | Size__c | Size | Created | Formula (Text) — derives a Beacon account size from Total Revenue Last 365 Days. |
| 17 | Field | Account | Total_Revenue_Last_365_Days__c | Total Revenue Last 365 Days | Created | Currency (18,2) — total Beacon revenue in the last 365 days, not currency-converted. |
| 18 | Field | Account | Total_Revenue__c | Total Revenue | Created | Summary (roll-up) of won Opportunity Amount for the account. |
| 19 | Field | Account | United_States_Time_Zone__c | United States Time Zone | Created | Picklist from the United States Time Zones global value set. |
| 20 | Field | Campaign | AM_Split_1__c | AM Split 1 | Created | Text (20) — Account Manager credit split 1. |
| 21 | Field | Campaign | AM_Split_2__c | AM Split 2 | Created | Text (20) — Account Manager credit split 2. |
| 22 | Field | Campaign | AM_Split_3__c | AM Split 3 | Created | Text (20) — Account Manager credit split 3. |
| 23 | Field | Campaign | SDR_1__c | SDR 1 | Created | Lookup(User) — SDR 1 assigned to the campaign. |
| 24 | Field | Campaign | SDR_2__c | SDR 2 | Created | Lookup(User) — SDR 2 assigned to the campaign. |
| 25 | Field | Campaign | SDR_3__c | SDR 3 | Created | Lookup(User) — SDR 3 assigned to the campaign. |
| 26 | Field | Campaign | SDR_4__c | SDR 4 | Created | Lookup(User) — SDR 4 assigned to the campaign. |
| 27 | Field | Campaign | SDR_5__c | SDR 5 | Created | Lookup(User) — SDR 5 assigned to the campaign. |
| 28 | Field | Campaign | SDR_6__c | SDR 6 | Created | Lookup(User) — SDR 6 assigned to the campaign. |
| 29 | Field | Campaign | SDR_Split_1__c | SDR Split 1 | Created | Text (20) — SDR credit split 1. |
| 30 | Field | Campaign | SDR_Split_2__c | SDR Split 2 | Created | Text (20) — SDR credit split 2. |
| 31 | Field | Campaign | SDR_Split_3__c | SDR Split 3 | Created | Text (20) — SDR credit split 3. |
| 32 | Field | Campaign | SDR_Split_4__c | SDR Split 4 | Created | Text (20) — SDR credit split 4. |
| 33 | Field | Campaign | SDR_Split_5__c | SDR Split 5 | Created | Text (20) — SDR credit split 5. |
| 34 | Field | Campaign | SDR_Split_6__c | SDR Split 6 | Created | Text (20) — SDR credit split 6. |
| 35 | Field | Campaign | Sponsorship_Manager_1__c | Sponsorship Manager 1 | Created | Lookup(User) — Sponsorship Manager 1 assigned to the campaign. |
| 36 | Field | Campaign | Sponsorship_Manager_2__c | Sponsorship Manager 2 | Created | Lookup(User) — Sponsorship Manager 2 assigned to the campaign. |
| 37 | Field | Campaign | Sponsorship_Manager_3__c | Sponsorship Manager 3 | Created | Lookup(User) — Sponsorship Manager 3 assigned to the campaign. |
| 38 | Compact Layout | Contact | Contact_Compact_Layout | Contact Compact Layout | Created | Highlights panel fields: Name, Account, Title, Phone, Mobile Phone, Email. |
| 39 | Field | Contact | Blacklisted_Reason__c | Blacklisted Reason | Created | Picklist from the Blacklisted Reason global value set. |
| 40 | Field | Contact | Blacklisted__c | Blacklisted | Created | Checkbox flagging the contact as blacklisted from outreach. |
| 41 | Field | Contact | Contact_Status__c | Contact Status | Created | Picklist (Do Not Engage, Unqualified, New, Nurturing, Working, Active Opp) — drives the Contact Status Path Assistant. |
| 42 | Field | Contact | Deceased__c | Deceased | Created | Checkbox flagging the contact as deceased. |
| 43 | Field | Contact | Lead_Type__c | Lead Type | Created | Picklist from the Lead Type global value set — more granular reporting than Lead Source. |
| 44 | Field | Contact | Region__c | Region | Created | Picklist from the Region global value set. |
| 45 | Field | Contact | United_States_Time_Zone__c | United States Time Zone | Created | Picklist from the United States Time Zones global value set. |
| 46 | Field | Lead | Blacklisted_Reason__c | Blacklisted Reason | Created | Picklist from the Blacklisted Reason global value set. |
| 47 | Field | Lead | Blacklisted__c | Blacklisted | Created | Checkbox flagging the lead as blacklisted from outreach. |
| 48 | Field | Lead | Deceased__c | Deceased | Created | Checkbox flagging the lead as deceased. |
| 49 | Field | Lead | Lead_Type__c | Lead Type | Created | Picklist from the Lead Type global value set — more granular reporting than Lead Source. |
| 50 | Field | Lead | Region__c | Region | Created | Picklist from the Region global value set. |
| 51 | Field | Lead | United_States_Time_Zone__c | United States Time Zone | Created | Picklist from the United States Time Zones global value set. |
| 52 | Business Process | Opportunity | Consulting | Consulting | Created | Stage set: Needs Analysis, Proposal, Contract, Closed Won, Closed Lost. |
| 53 | Business Process | Opportunity | Subscription New | Subscription New | Created | Stage set: Demo Booked, Demo Completed, Proposal, Contract, Closed Won, Closed Lost. |
| 54 | Business Process | Opportunity | Subscription Renewal | Subscription Renewal | Created | Stage set: Onboarding, Proposal, Contract, Closed Won, Closed Lost. |
| 55 | Compact Layout | Opportunity | Opportunity_Companct_Layout | Opportunity Compact Layout | Created | Highlights panel fields: Name, Account, Amount, Close Date, Owner. API name has a typo ("Companct") — see Post Deployment Items. |
| 56 | Field | Opportunity | Deposit_Amount__c | Deposit Amount | Created | Currency (18,2) — deposit amount collected. |
| 57 | Field | Opportunity | Deposit_Pay_Date__c | Deposit Pay Date | Created | Date the deposit was paid. |
| 58 | Field | Opportunity | Director_Expected_Revenue__c | Director Expected Revenue | Created | Formula (Currency, 18,2) — Amount * Director Probability. |
| 59 | Field | Opportunity | Director_Probability__c | Director Probability (%) | Created | Percent (3,0) — director-adjusted win probability. |
| 60 | Field | Opportunity | Full_Amount_Pay_Date__c | Full Amount Pay Date | Created | Date the full amount was paid. |
| 61 | Field | Opportunity | Lead_Type__c | Lead Type | Created | Picklist from the Lead Type global value set — more granular reporting than Lead Source. |
| 62 | Field | Opportunity | MIR__c | MIR | Created | Formula (Text) — "Yes" when Lead Source = Marketing, else "No"; flags marketing-influenced revenue. |
| 63 | Field | Opportunity | Payment_Status__c | Payment Status | Created | Picklist (Unpaid, Paid, Partially Paid). |
| 64 | Field | Opportunity | Primary_Module__c | Primary Module | Created | Picklist from the Primary Module global value set. |
| 65 | Field | Opportunity | Unique_Invoice_No__c | Unique Invoice No | Created | Text (15) — unique invoice identifier. |
| 66 | Record Type | Opportunity | Consulting | Consulting | Created | Uses the Consulting business process; enables full Lead Type/Primary Module/Payment Status/Loss Reason/Invoice Terms/LeadSource/Split Payment/Type value sets. |
| 67 | Record Type | Opportunity | Subscription_New | Subscription New | Created | Uses the Subscription New business process; enables the same value sets as Consulting. |
| 68 | Record Type | Opportunity | Subscription_Renewal | Subscription Renewal | Created | Uses the Subscription Renewal business process; enables the same value sets as Consulting. |
| 69 | Path Assistant | Contact | Contact_Status | Contact Status | Created | Active path on Contact.Contact_Status__c (master record type) visualizing outreach progress. |
| 70 | Permission Set | N/A | sfdcInternalInt__sfdc_a360 | (Salesforce Analytics/Einstein integration) | Updated | Added Edit access to Contact.Region__c, Contact.United_States_Time_Zone__c, Lead.Lead_Type__c, Lead.Region__c, Lead.United_States_Time_Zone__c; Read-only access to Lead.Blacklisted__c. |
| 71 | Flexipage | Account | Beacon_Account_Record_Page | Beacon Account Record Page | Created | New Lightning Record Page for Account built from Region components. |
| 72 | Flexipage | Campaign | Beacon_Campaign_Record_Page | Beacon Campaign Record Page | Created | New Lightning Record Page for Campaign built from Region components. |
| 73 | Flexipage | Contact | Beacon_Contact_Record_Page | Beacon Contact Record Page | Created | New Lightning Record Page for Contact built from Region components. |
| 74 | Flexipage | Lead | Beacon_Lead_Record_Page | Beacon Lead Record Page | Created | New Lightning Record Page for Lead built from Region/Facet components. |
| 75 | Flexipage | Opportunity | Beacon_Opportunity_Record_Page | Beacon Opportunity Record Page | Created | New Lightning Record Page for Opportunity built from Region components. |
| 76 | Standard Value Set | Lead | LeadStatus | Lead Status | Updated | Set to Do Not Engage, Unqualified, New (default), Working, Nurturing, Qualified (converted). |
| 77 | Standard Value Set | Opportunity | OpportunityStage | Opportunity Stage | Updated | Set to Onboarding, Needs Analysis, Demo Booked, Demo Completed, Proposal, Contract, Closed Won, Closed Lost, each with a forecast category and probability. |
| 78 | Profile | N/A | Admin | Admin | Updated | Added layout assignments: Opportunity layout for the 3 new record types + Opportunity Team Member layout. |
| 79 | Profile | N/A | Analytics Cloud Integration User | Analytics Cloud Integration User | Updated | Same 4 layout assignments as Admin. |
| 80 | Profile | N/A | Analytics Cloud Security User | Analytics Cloud Security User | Updated | Same 4 layout assignments as Admin. |
| 81 | Profile | N/A | CPQ Integration User | CPQ Integration User | Updated | Same 4 layout assignments as Admin. |
| 82 | Profile | N/A | Chatter External User | Chatter External User | Updated | Same 4 layout assignments as Admin. |
| 83 | Profile | N/A | Chatter Free User | Chatter Free User | Updated | Same 4 layout assignments as Admin. |
| 84 | Profile | N/A | Chatter Moderator User | Chatter Moderator User | Updated | Same 4 layout assignments as Admin. |
| 85 | Profile | N/A | ContractManager | Contract Manager | Updated | Same 4 layout assignments as Admin. |
| 86 | Profile | N/A | Einstein Agent User | Einstein Agent User | Updated | Same 4 layout assignments as Admin. |
| 87 | Profile | N/A | End User | Standard User | Updated | Same 4 layout assignments as Admin. |
| 88 | Profile | N/A | Executive Sponsor | Executive Sponsor | Updated | Same 4 layout assignments as Admin. |
| 89 | Profile | N/A | External Apps Login User | External Apps Login User | Updated | Same 4 layout assignments as Admin. |
| 90 | Profile | N/A | External Einstein Agent User | External Einstein Agent User | Updated | Same 4 layout assignments as Admin. |
| 91 | Profile | N/A | Guest License User | Guest License User | Updated | Same 4 layout assignments as Admin. |
| 92 | Profile | N/A | Identity User | Identity User | Updated | Same 4 layout assignments as Admin. |
| 93 | Profile | N/A | MarketingProfile | Marketing Profile | Updated | Same 4 layout assignments as Admin. |
| 94 | Profile | N/A | Minimum Access - API Only Integrations | Minimum Access - API Only Integrations | Updated | Same 4 layout assignments as Admin. |
| 95 | Profile | N/A | Minimum Access - Salesforce | Minimum Access - Salesforce | Updated | Same 4 layout assignments as Admin. |
| 96 | Profile | N/A | Read Only | Read Only | Updated | Same 4 layout assignments as Admin. |
| 97 | Profile | N/A | Sales Insights Integration User | Sales Insights Integration User | Updated | Same 4 layout assignments as Admin. |
| 98 | Profile | N/A | Salesforce API Only System Integrations | Salesforce API Only System Integrations | Updated | Same 4 layout assignments as Admin. |
| 99 | Profile | N/A | SalesforceIQ Integration User | SalesforceIQ Integration User | Updated | Same 4 layout assignments as Admin. |
| 100 | Profile | N/A | SolutionManager | Solution Manager | Updated | Same 4 layout assignments as Admin. |
| 101 | Profile | N/A | Standard | Standard User | Updated | Same 4 layout assignments as Admin. |
