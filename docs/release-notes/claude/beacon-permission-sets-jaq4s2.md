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

## Post Deployment Items

- Assign each permission set to the appropriate users/groups per persona.
- The `CampaignMember.Account_Status__c` field was granted using each persona's **Campaign**
  object access level as a stand-in, since none of the eight personas were granted a
  CampaignMember object-access entry in the original object-access matrix. If CampaignMember
  object access is formally required later, add `objectPermissions` for CampaignMember to each
  permission set.

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
