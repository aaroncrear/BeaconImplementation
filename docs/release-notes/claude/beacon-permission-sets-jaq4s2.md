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

Field Level Security (FLS) was **not** configured in this build — the source file provided only
object-level (CRUD) access requirements, with no field-by-field breakdown. The permission sets
are structured to hold field permissions once that requirement is provided (see Post Deployment
Items below).

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
5. Assign each permission set to a test user for the corresponding persona and confirm the user
   can access each object per the CRUD matrix (e.g., a Sales-assigned user can create/edit
   Leads, Accounts, Contacts, and Opportunities but only view Campaigns).

## Post Deployment Items

- Field Level Security (FLS) values were not provided in the source file and are not yet
  configured on these permission sets. Obtain the field-level access matrix per persona and
  update each permission set's `fieldPermissions` accordingly.
- Assign each permission set to the appropriate users/groups per persona.

## Component Manifest

Github Branch: https://github.com/aaroncrear/beaconimplementation/tree/claude/beacon-permission-sets-jaq4s2

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Permission Set | N/A | Beacon_Executive | Beacon Executive | Created | Object/Tab access for the Executive persona: Read on Lead, Account, Contact, Opportunity, Campaign. |
| 2 | Permission Set | N/A | Beacon_Sales | Beacon Sales | Created | Object/Tab access for the Sales persona: Create/Read/Edit on Lead, Account, Contact, Opportunity; Read on Campaign. |
| 3 | Permission Set | N/A | Beacon_Marketing | Beacon Marketing | Created | Object/Tab access for the Marketing persona: Create/Read/Edit on Lead; Read on Account, Contact; Read/Edit on Opportunity; Create/Read/Edit/Delete on Campaign. |
| 4 | Permission Set | N/A | Beacon_Customer_Success | Beacon Customer Success | Created | Object/Tab access for the Customer Success persona: Create/Read/Edit on Lead, Contact; Read on Account, Opportunity, Campaign. |
| 5 | Permission Set | N/A | Beacon_ResOps | Beacon ResOps | Created | Object/Tab access for the ResOps persona: Create/Read/Edit on Lead, Account, Contact; Read on Opportunity, Campaign. |
| 6 | Permission Set | N/A | Beacon_Consulting | Beacon Consulting | Created | Object/Tab access for the Consulting persona: Create/Read/Edit on Lead, Account, Contact, Opportunity; Read on Campaign. |
| 7 | Permission Set | N/A | Beacon_Product | Beacon Product | Created | Object/Tab access for the Product persona: Create/Read/Edit on Lead, Account, Contact; Read on Opportunity, Campaign. |
| 8 | Permission Set | N/A | Beacon_Tech | Beacon Tech | Created | Object/Tab access for the Tech persona: Read on Lead, Account, Contact, Opportunity, Campaign. |
