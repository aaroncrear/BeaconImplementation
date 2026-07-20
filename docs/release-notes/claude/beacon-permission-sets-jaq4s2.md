# "claude/beacon-permission-sets-jaq4s2" – Release Notes

## Requirements

The business requested eight new permission sets — one per Beacon persona (Executive, Sales,
Marketing, Customer Success, ResOps, Consulting, Product, and Tech) — to provide standardized
Object, Tab, and Field Level Security (FLS) access for the core sales objects: Lead, Account,
Contact, Opportunity, and Campaign. Object-level access requirements for each persona were
supplied in the `Object_Access.xlsx` reference file.

## Release Notes

Eight new Permission Sets were created, each named `Beacon <Persona>` with the description
"Used to provide Object, Tab and Field level access." Object permissions (Create/Read/Update/
Delete) were configured per persona exactly as specified in the supplied `Object_Access.xlsx`
matrix:

| Persona | Lead | Account | Contact | Opportunity | Campaign |
|---|---|---|---|---|---|
| Executive | R | R | R | R | R |
| Sales | CRU | CRU | CRU | CRU | R |
| Marketing | CRU | R | R | RU | CRUD |
| Customer Success | CRU | R | CRU | R | R |
| ResOps | CRU | CRU | CRU | R | R |
| Consulting | CRU | CRU | CRU | CRU | R |
| Product | CRU | CRU | CRU | R | R |
| Tech | R | R | R | R | R |

For each object where a persona was granted at least Read access, the corresponding standard
object tab was set to `DefaultOn` visibility so the persona can navigate to the object in the
Salesforce UI, satisfying the "Tab" portion of each permission set's description.

Field Level Security (FLS) was added for all 39 custom fields introduced on Account, Campaign,
Contact, Lead, and Opportunity by the `Custom-Fields` branch (merged to master in PR #2). Access
was derived directly from each persona's object-level access on the parent object:

- Object access is Read only → field access is Read only (`readable=true`, `editable=false`).
- Object access is more than Read (Create/Edit/Delete) → field access is Read/Edit
  (`readable=true`, `editable=true`).
- Exception: formula fields (`Beacon_Account_Segment__c`, `Beacon_Account_Type__c`,
  `Seat_Utilisation_Rate_Last_30_Days__c`, `Seat_Utilisation_Rate_YTD__c` on Account;
  `Email_Communication__c`, `NAICS_Code__c`, `NAICS_Description__c`, `Phone_Communication__c` on
  Contact; `Email_Communication__c`, `Phone_Communication__c` on Lead; `Price_Increase_Value__c`
  on Opportunity) are always system read-only in Salesforce, so `editable` is `false` for these
  regardless of the persona's object access.

Additionally, `CampaignMember.Account_Status__c` (the remaining custom field from the
Custom-Fields branch, on the CampaignMember object) was added to every permission set using each
persona's **Campaign** object access level to decide field access, since these permission sets
don't grant CampaignMember object access directly. It is also a formula field, so `editable` is
`false` for every persona, including Beacon Marketing (which has Create/Read/Edit/Delete on
Campaign); `readable` is `true` for all eight.

Finally, field `description` values were populated on 83 fields across Account, Campaign,
CampaignMember, Contact, Lead, Opportunity, and Task, using
`Salesforce_Fields__Based_on_current_instance_2.xlsx` (the current-instance field inventory) as
the source of truth. Only fields that already exist as local field metadata in this repo were
updated — API names in the workbook that don't correspond to a field currently tracked here
(188 rows, mostly fields that exist in the org but haven't been added to this metadata project
yet) were left untouched. One row in the workbook's Campaign sheet ("Module" → API name
`Beacon_Module_Family__c`) appears to be a data-entry error, since that API name is already
correctly used by the "Beacon Module Family" row; that row was skipped. Where a field already had
a `description`, the workbook's value replaced it.

All eight permission sets were then updated to add `<license>Salesforce</license>`, restricting
assignment to users holding the standard Salesforce (full CRM) user license. Tab visibility was
re-verified at the same time: every object each permission set grants access to (Lead, Account,
Contact, Opportunity, Campaign) already had its standard tab set to `DefaultOn`, so no tab
changes were needed — this confirms the "Tab" portion of each permission set's description is
fully satisfied alongside the license restriction.

## Acceptance Criteria

1. In Setup > Permission Sets, confirm the following eight permission sets exist:
   Beacon Executive, Beacon Sales, Beacon Marketing, Beacon Customer Success, Beacon ResOps,
   Beacon Consulting, Beacon Product, Beacon Tech.
2. For each permission set, confirm the description reads "Used to provide Object, Tab and
   Field level access."
3. For each permission set, open Object Settings and confirm the Create/Read/Edit/Delete
   checkboxes for Lead, Account, Contact, Opportunity, and Campaign match the table in the
   Release Notes section above.
4. For each permission set, confirm the Lead, Account, Contact, Opportunity, and Campaign tabs
   are set to visible (Default On) in the permission set's assigned apps/tab settings.
5. For each permission set, open Object Settings for each of the 5 objects and confirm every
   custom field (`__c`) added by the Custom-Fields branch shows Read (and Edit, where the
   object has more than Read access) checked, and that the formula fields listed in the
   Release Notes section remain Read-only even when the object has Edit access.
6. Assign each permission set to a test user for the corresponding persona and confirm the user
   can access each object per the CRUD matrix (e.g., a Sales-assigned user can create/edit
   Leads, Accounts, Contacts, and Opportunities but only view Campaigns), and that the custom
   fields on each object are editable or read-only consistent with the object access level.
7. In Setup > Object Manager, spot-check the fields listed in rows 9–91 of the Component
   Manifest below and confirm each field's Description matches the value shown.
8. For each of the eight permission sets, confirm the "License" field on the permission set
   detail page reads "Salesforce," and confirm the permission set can only be assigned to users
   with a Salesforce (full CRM) user license.

## Post Deployment Items

- Assign each permission set to the appropriate users/groups per persona.
- The `CampaignMember.Account_Status__c` field was granted using each persona's **Campaign**
  object access level as a stand-in, since none of the eight personas were granted a
  CampaignMember object-access entry in the original object-access matrix. If CampaignMember
  object access is formally required later, add `objectPermissions` for CampaignMember to each
  permission set.
- 188 fields listed in `Salesforce_Fields__Based_on_current_instance_2.xlsx` do not yet have
  corresponding field metadata in this repo (e.g. `Middle_Name__c`, `Blacklisted__c`,
  `Second_Email__c`, most of the Contact "Beacon Exp Dt" / "Beacon - <Module>" fields, and
  several Opportunity fields). Their descriptions were not applied. If/when those fields are
  retrieved into this project, re-run the description update against the same workbook.
- The Campaign sheet's "Module" row (API name entered as `Beacon_Module_Family__c`) looks like a
  data-entry error in the source workbook — confirm with the workbook owner whether it should
  instead point at the existing `Module__c` field, which has no description of its own yet.

## Component Manifest

Github Branch: https://github.com/aaroncrear/beaconimplementation/tree/claude/beacon-permission-sets-jaq4s2

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Permission Set | N/A | Beacon_Executive | Beacon Executive | Created | Object/Tab/Field access for the Executive persona: Read only on Lead, Account, Contact, Opportunity, Campaign objects and their custom fields. |
| 2 | Permission Set | N/A | Beacon_Sales | Beacon Sales | Created | Object/Tab/Field access for the Sales persona: Create/Read/Edit on Lead, Account, Contact, Opportunity (and their custom fields); Read on Campaign (and its custom fields). |
| 3 | Permission Set | N/A | Beacon_Marketing | Beacon Marketing | Created | Object/Tab/Field access for the Marketing persona: Create/Read/Edit on Lead; Read on Account, Contact; Read/Edit on Opportunity; Create/Read/Edit/Delete on Campaign (custom fields follow the same Read vs Read/Edit split per object, formula fields excepted). |
| 4 | Permission Set | N/A | Beacon_Customer_Success | Beacon Customer Success | Created | Object/Tab/Field access for the Customer Success persona: Create/Read/Edit on Lead, Contact; Read on Account, Opportunity, Campaign (custom fields follow the same split). |
| 5 | Permission Set | N/A | Beacon_ResOps | Beacon ResOps | Created | Object/Tab/Field access for the ResOps persona: Create/Read/Edit on Lead, Account, Contact; Read on Opportunity, Campaign (custom fields follow the same split). |
| 6 | Permission Set | N/A | Beacon_Consulting | Beacon Consulting | Created | Object/Tab/Field access for the Consulting persona: Create/Read/Edit on Lead, Account, Contact, Opportunity; Read on Campaign (custom fields follow the same split). |
| 7 | Permission Set | N/A | Beacon_Product | Beacon Product | Created | Object/Tab/Field access for the Product persona: Create/Read/Edit on Lead, Account, Contact; Read on Opportunity, Campaign (custom fields follow the same split). |
| 8 | Permission Set | N/A | Beacon_Tech | Beacon Tech | Created | Object/Tab/Field access for the Tech persona: Read only on Lead, Account, Contact, Opportunity, Campaign objects and their custom fields. |
| 9 | Field | Account | Beacon_Account_Segment__c | Beacon Account Segment | Updated | Beacon account segment classification and grouping of LS Company Type values |
| 10 | Field | Account | Beacon_Account_Type__c | Beacon Account Type | Updated | Value of the Account based on revenue spent in last 365 days |
| 11 | Field | Account | BillingAddress | BillingAddress | Updated | Main Address for the account. |
| 12 | Field | Account | Invoice_Email__c | Invoice Email | Updated | Email address used for company or invoicing communications. |
| 13 | Field | Account | Name | Name | Updated | Account associated with the record. |
| 14 | Field | Account | OwnerId | OwnerId | Updated | User responsible for owning this record. |
| 15 | Field | Account | Phone | Phone | Updated | Phone number for the individual or organization. |
| 16 | Field | Account | Seat_Utilisation_Rate_Last_30_Days__c | Seat Utilisation Rate Last 30 Days (%) | Updated | Seat utilisation rate for the last 30 days. |
| 17 | Field | Account | Seat_Utilisation_Rate_YTD__c | Seat Utilisation Rate YTD (%) | Updated | Seat utilisation rate year to date. |
| 18 | Field | Account | ShippingAddress | ShippingAddress | Updated | Billing Address for the account. |
| 19 | Field | Account | Total_Number_Of_Seats__c | Total Number Of Seats | Updated | Total number of seats associated with the account. |
| 20 | Field | Account | Website | Website | Updated | Website associated with the record. |
| 21 | Field | Campaign | Beacon_Module_Family__c | Beacon Module Family | Updated | Beacon module family associated with the campaign. |
| 22 | Field | Campaign | Channels__c | Channels | Updated | Channels used for the campaign. |
| 23 | Field | Campaign | Content_Family__c | Content Family | Updated | Content family associated with the campaign. |
| 24 | Field | Campaign | IsActive | IsActive | Updated | Indicates whether the campaign is active. |
| 25 | Field | Campaign | Name | Name | Updated | Name of the campaign. |
| 26 | Field | Campaign | OwnerId | OwnerId | Updated | User responsible for owning this record. |
| 27 | Field | Campaign | ParentId | ParentId | Updated | Parent record associated with this record. |
| 28 | Field | Campaign | StartDate | StartDate | Updated | Start date of the campaign. |
| 29 | Field | Campaign | Type | Type | Updated | Parent or Sub Campaign |
| 30 | Field | Campaign | Website__c | Website | Updated | Website associated with the record. |
| 31 | Field | CampaignMember | Account_Status__c | Account Status | Updated | Status of the associated account. |
| 32 | Field | CampaignMember | CampaignId | CampaignId | Updated | Campaign associated with the campaign member. |
| 33 | Field | CampaignMember | CompanyOrAccount | CompanyOrAccount | Updated | Company or account associated with the campaign member. |
| 34 | Field | CampaignMember | ContactId | ContactId | Updated | Contact associated with the campaign member. |
| 35 | Field | CampaignMember | FirstRespondedDate | FirstRespondedDate | Updated | Indicates when the individual was first associated with the campaign |
| 36 | Field | CampaignMember | LeadId | LeadId | Updated | Lead associated with the campaign member. |
| 37 | Field | CampaignMember | Status | Status | Updated | Status of the camapaign member record. |
| 38 | Field | Contact | Email | Email | Updated | Email address of the individual. |
| 39 | Field | Contact | Email_Communication__c | Email Communication | Updated | Indicates whether email communication is permitted or available. |
| 40 | Field | Contact | HasOptedOutOfEmail | HasOptedOutOfEmail | Updated | Indicates whether the individual has opted out of email communications. |
| 41 | Field | Contact | LeadSource | LeadSource | Updated | Source from which the lead or contact originated. |
| 42 | Field | Contact | Linkedin_Profile__c | Linkedin Profile | Updated | LinkedIn profile URL or identifier for the contact. |
| 43 | Field | Contact | MailingAddress | MailingAddress | Updated | Mailing address for the individual. |
| 44 | Field | Contact | MobilePhone | MobilePhone | Updated | Mobile number for the individual or organization. |
| 45 | Field | Contact | Name | Name | Updated | Name of the contact record or individual. |
| 46 | Field | Contact | OwnerId | OwnerId | Updated | User who owns the contact |
| 47 | Field | Contact | Phone | Phone | Updated | Phone number for the individual or organization. |
| 48 | Field | Contact | Phone_Communication__c | Phone Communication | Updated | Indicates whether phone communication is permitted or available. |
| 49 | Field | Contact | Title | Title | Updated | Job title of the individual. |
| 50 | Field | Lead | Company | Company | Updated | Company of the individual |
| 51 | Field | Lead | DoNotCall | DoNotCall | Updated | Indicates whether the individual should not be called. |
| 52 | Field | Lead | Email | Email | Updated | Email address of the contact |
| 53 | Field | Lead | Email_Communication__c | Email Communication | Updated | Visual to showwhether we can email the contact |
| 54 | Field | Lead | HasOptedOutOfEmail | HasOptedOutOfEmail | Updated | Indicates whether the individual has opted out of email communications. |
| 55 | Field | Lead | MobilePhone | MobilePhone | Updated | Mobile number for the individual or organization. |
| 56 | Field | Lead | Name | Name | Updated | Name of the individual |
| 57 | Field | Lead | Phone_Communication__c | Phone Communication | Updated | Indicates whether phone communication is permitted or available. |
| 58 | Field | Lead | Title | Title | Updated | Job-Title of the Individual |
| 59 | Field | Lead | Website | Website | Updated | Website associated with the record. |
| 60 | Field | Opportunity | Accounting_Date__c | Accounting Date | Updated | Date of Invoice |
| 61 | Field | Opportunity | Amount | Amount | Updated | Monetary amount of the opportunity. |
| 62 | Field | Opportunity | Beacon_Demo_on__c | Beacon Demo on | Updated | Date the demo is booked for |
| 63 | Field | Opportunity | CampaignId | CampaignId | Updated | Name of the campaign. |
| 64 | Field | Opportunity | CloseDate | CloseDate | Updated | Expected or actual close date of the opportunity. |
| 65 | Field | Opportunity | Date_Demo_Booked__c | Date Demo Booked | Updated | Date the demo was booked. |
| 66 | Field | Opportunity | Date_Demo_Completed__c | Date Demo Completed | Updated | Date the demo was completed. |
| 67 | Field | Opportunity | Date_Proposal_Sent__c | Date Proposal Sent | Updated | Date the proposal was sent. |
| 68 | Field | Opportunity | Invoice_Terms__c | Invoice Terms | Updated | Terms agreed for the invoice which comes into the invoicing body to buiild customer invoice |
| 69 | Field | Opportunity | LeadSource | LeadSource | Updated | Source from which the lead or contact originated. |
| 70 | Field | Opportunity | License_End_Date__c | License End Date | Updated | License end date. |
| 71 | Field | Opportunity | License_Start_Date__c | License Start Date | Updated | Start date of the campaign. |
| 72 | Field | Opportunity | Name | Name | Updated | Name or code used to identify the opportunity. |
| 73 | Field | Opportunity | OwnerId | OwnerId | Updated | User responsible for owning this record. |
| 74 | Field | Opportunity | Previous_Yield__c | Previous Yield | Updated | Previous yield value associated with the renewal. |
| 75 | Field | Opportunity | Price_Increase_Value__c | Price Increase Value | Updated | Value of the price increase for the renewal. |
| 76 | Field | Opportunity | Pricebook2Id | Pricebook2Id | Updated | Price book associated with the opportunity. |
| 77 | Field | Opportunity | Referred_By__c | Referred By | Updated | Person or source that referred the opportunity. |
| 78 | Field | Opportunity | Renewal_Date__c | Renewal Date | Updated | Renewal date for the opportunity. |
| 79 | Field | Opportunity | Rep_Notes__c | Rep Notes | Updated | Sales representative notes for the opportunity. |
| 80 | Field | Opportunity | Split_Payment_1_Term__c | Split Payment 1 Term | Updated | What is the first portion of the split terms |
| 81 | Field | Opportunity | Split_Payment_2_Term__c | Split Payment 2 Term | Updated | What is the second portion of the split terms |
| 82 | Field | Opportunity | Split_Payment__c | Split Payment | Updated | Confirms whether the payment terms are split and will come into the invoicing body |
| 83 | Field | Opportunity | StageName | StageName | Updated | Current sales stage of the opportunity. |
| 84 | Field | Task | ActivityDate | ActivityDate | Updated | Date of the task activity. |
| 85 | Field | Task | Description | Description | Updated | Free-text comments or description for the task. |
| 86 | Field | Task | OwnerId | OwnerId | Updated | Who completed the task |
| 87 | Field | Task | Status | Status | Updated | Whether the task is open or complete |
| 88 | Field | Task | Subject | Subject | Updated | Subject of the task. |
| 89 | Field | Task | Type | Type | Updated | Type classification for the task record. |
| 90 | Field | Task | WhatId | WhatId | Updated | Record that the task is related to. |
| 91 | Field | Task | WhoId | WhoId | Updated | Name of the task record or individual. |
| 92 | Permission Set | N/A | Beacon_Executive | Beacon Executive | Updated | Added `license` = Salesforce (full CRM user license required for assignment); confirmed Lead, Account, Contact, Opportunity, Campaign tabs are visible (`DefaultOn`). |
| 93 | Permission Set | N/A | Beacon_Sales | Beacon Sales | Updated | Added `license` = Salesforce; confirmed Lead, Account, Contact, Opportunity, Campaign tabs are visible (`DefaultOn`). |
| 94 | Permission Set | N/A | Beacon_Marketing | Beacon Marketing | Updated | Added `license` = Salesforce; confirmed Lead, Account, Contact, Opportunity, Campaign tabs are visible (`DefaultOn`). |
| 95 | Permission Set | N/A | Beacon_Customer_Success | Beacon Customer Success | Updated | Added `license` = Salesforce; confirmed Lead, Account, Contact, Opportunity, Campaign tabs are visible (`DefaultOn`). |
| 96 | Permission Set | N/A | Beacon_ResOps | Beacon ResOps | Updated | Added `license` = Salesforce; confirmed Lead, Account, Contact, Opportunity, Campaign tabs are visible (`DefaultOn`). |
| 97 | Permission Set | N/A | Beacon_Consulting | Beacon Consulting | Updated | Added `license` = Salesforce; confirmed Lead, Account, Contact, Opportunity, Campaign tabs are visible (`DefaultOn`). |
| 98 | Permission Set | N/A | Beacon_Product | Beacon Product | Updated | Added `license` = Salesforce; confirmed Lead, Account, Contact, Opportunity, Campaign tabs are visible (`DefaultOn`). |
| 99 | Permission Set | N/A | Beacon_Tech | Beacon Tech | Updated | Added `license` = Salesforce; confirmed Lead, Account, Contact, Opportunity, Campaign tabs are visible (`DefaultOn`). |
