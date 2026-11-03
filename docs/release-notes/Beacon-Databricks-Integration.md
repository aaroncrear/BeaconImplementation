# "Beacon-Databricks-Integration" – Release Notes

## Requirements

The business needs a permission set for the Databricks integration, named
**Beacon - Databricks Integration**. It must give **Read**, **View All Records**, and
**View All Fields** access to these objects:

Accounts, Contacts, Leads, Opportunities, Campaigns, Products, Price Books, Quotes, Contracts,
Orders, Assets, Beacon Subscriptions, Beacon Feedback, Cases, Tasks, Events, Account Teams, and
Opportunity Teams.

It must also cover any child objects whose access isn't fully inherited from the parent through
a master-detail relationship.

## Release Notes

A new permission set, `Beacon_Databricks_Integration`, was created. It is read only: Create,
Edit, Delete, and Modify All are off everywhere, so the integration can extract data but can't
change it.

**Object permissions.** Read, View All Records, and View All Fields are on for these 14 objects:

| Object | API Name |
|---|---|
| Account | `Account` |
| Asset | `Asset` |
| Beacon Feedback | `Beacon_Feedback__c` |
| Beacon Subscription | `Beacon_Subscription__c` |
| Campaign | `Campaign` |
| Case | `Case` |
| Contact | `Contact` |
| Contract | `Contract` |
| Lead | `Lead` |
| Opportunity | `Opportunity` |
| Order | `Order` |
| Price Book | `Pricebook2` |
| Product | `Product2` |
| Quote | `Quote` |

View All Fields gives Read access to every field on these objects, including fields added later,
so no field permissions are needed for them.

`Beacon_Subscription__c` is a master-detail child of Account and Asset. Custom detail objects
still need their own object permission, so it has its own entry above.

**Tasks and Events.** Salesforce doesn't allow object permissions on Task and Event. Access is
given with the **Access Activities** (`ActivitiesAccess`) user permission. The user can then see
every Task and Event linked (through Related To or Name) to a record they can read. With View All
Records on Account, Contact, Lead, Opportunity, and the other objects above, that covers every
linked activity.

**View All Activities** (`ViewAllActivities`) isn't included because the Salesforce API
Integration permission set license doesn't allow it. Without it, the user can't see Tasks and
Events that aren't linked to any record (no Related To and no Name), because those are only
visible to their owner and users above the owner in the role hierarchy. In Production on
2026-11-03, that was 1,999 of 173,036 Tasks. Every other Task was linked to an Account or an
Opportunity. Production had no Events.

**Child objects without their own object permissions.** These objects get their record access
from the parent (Read on the parent, plus View All Records on the parent, gives access to all of
their records). Salesforce doesn't allow object permissions, or View All Fields, on them. Their
field level security is still set separately, so every field that can have field permissions was
added as **Read only**:

| Parent | Child Object | Fields |
|---|---|---|
| Account | Account Team Member (`AccountTeamMember`) | 1 |
| Account / Contact | Account Contact Relationship (`AccountContactRelation`) | 5 |
| Asset | Asset Relationship (`AssetRelationship`) | 6 |
| Campaign | Campaign Member (`CampaignMember`) | 1 |
| Opportunity | Opportunity Product (`OpportunityLineItem`) | 9 |
| Opportunity | Opportunity Contact Role (`OpportunityContactRole`) | 1 |
| Quote | Quote Line Item (`QuoteLineItem`) | 53 |
| Order | Order Product (`OrderItem`) | 47 |
| Activity | Task (`Task`) | 27 |
| Activity | Event (`Event`) | 28 |

That's 178 fields in total. The list came from querying the Beacon Production org
(`EntityParticle` where `IsPermissionable = true`). On Task and Event it includes the
Gong and Dialpad managed package fields and `HW_Record_ID__c`.

These child objects have no fields that can have field permissions, so nothing was needed for
them: Opportunity Team Member, Price Book Entry, Account Contact Role, Contract Contact Role,
Case Contact Role, and Opportunity Competitor. Their records and fields are readable through the
parent.

**Not included:**

- Managed package objects that look up to these objects (for example Gong, Dialpad, DocuSign,
  and ZoomInfo objects). They belong to their apps and weren't in the request.
- `Project__c`, `Project_Team_Member__c`, and `Project_Time__c`. `Project__c` looks up to Account
  and Contact, but it isn't in this repository and has no records in Production.

**Fields pulled from Production.** Deploying the permission set failed because
`AccountTeamMember.HW_Record_ID__c` wasn't in the target org. The repo was compared with
Production for every object in the permission set, and 18 unmanaged custom fields existed in
Production but not in the repo. They were added so they deploy with the permission set:

- 14 HubSpot integration fields (on Account, Contact, and Lead) were copied from the
  `Hubspot-Integration` branch, which is the source that was deployed to Production. Their labels,
  types, and descriptions were checked against Production, and the Account Tier values (1 to 5)
  match.
- 4 fields weren't in any branch, so they were rebuilt from their Production definitions (label,
  type, length, External ID, and description): `HW_Record_ID__c` on Account Team Member, Campaign
  Member, and Opportunity Contact Role, and `LinkedIn_Profile__c` on Lead.

**License.** The permission set uses the **Salesforce API Integration** permission set license
(set in the metadata by its developer name, `SalesforceAPIIntegrationPsl`, because the Metadata
API doesn't accept the label). This is the same license used by the existing Beacon Hubspot, Gong, Dialpad, and LinkedIn SN integration
permission sets. It can only be assigned to a user with the **Salesforce Integration** user
license who has also been assigned the Salesforce API Integration permission set license. It
doesn't give API access by itself. The integration user's profile must have **API Enabled** (the
**Minimum Access - API Only Integrations** profile already has it).

## Acceptance Criteria

1. Deploy the branch to the target org.
2. Go to **Setup → Permission Sets** and open **Beacon - Databricks Integration**. Check that
   the API name is `Beacon_Databricks_Integration` and that the license is
   **Salesforce API Integration**.
3. Under **Object Settings**, open each of the 14 objects in the Object Permissions table. Check
   that **Read**, **View All Records**, and **View All Fields** are checked, and that **Create**,
   **Edit**, **Delete**, and **Modify All Records** are unchecked.
4. Open **Object Settings → Opportunity Products**, **Quote Line Items**, **Order Products**,
   **Tasks**, and **Events**. Check that every field listed has **Read Access** checked and
   **Edit Access** unchecked.
5. Under **System Permissions**, check that **Access Activities** is checked and that no other
   system permissions are on.
6. Assign the permission set to the Databricks integration user (a Salesforce Integration user
   with the Salesforce API Integration permission set license, whose profile has API Enabled
   and no other object access).
7. As that user, run these SOQL queries (for example from Workbench or the Databricks
   connector). Check that each one returns every record in the org, including records the user
   doesn't own, and that all fields come back:
   - `SELECT FIELDS(ALL) FROM Account LIMIT 200`, and the same for Contact, Lead, Opportunity,
     Campaign, Product2, Pricebook2, Quote, Contract, Order, Asset, Beacon_Subscription__c,
     Beacon_Feedback__c, and Case.
   - `SELECT COUNT() FROM Task WHERE WhatId != null OR WhoId != null`: as an admin, run the same
     query and check that both counts match. Repeat for Event.
   - `SELECT FIELDS(ALL) FROM Task LIMIT 200` and `SELECT FIELDS(ALL) FROM Event LIMIT 200`:
     check that all fields come back.
   - `SELECT Id, AccountId, UserId, TeamMemberRole FROM AccountTeamMember`
   - `SELECT Id, OpportunityId, UserId, TeamMemberRole FROM OpportunityTeamMember`
   - `SELECT FIELDS(ALL) FROM OpportunityLineItem LIMIT 200`, and the same for QuoteLineItem,
     OrderItem, PricebookEntry, CampaignMember, OpportunityContactRole, and
     AccountContactRelation.
8. As that user, try to update any Account record. Check that the update fails with an
   insufficient access error.

## Post Deployment Items

- Create the Databricks integration user with the **Salesforce Integration** user license and
  the **Minimum Access - API Only Integrations** profile (which has **API Enabled**).
- Assign the **Salesforce API Integration** permission set license to that user. Production has
  5 of these licenses and 4 are in use, so this uses the last one.
- Assign **Beacon - Databricks Integration** to the user.
- Tell the Databricks team that Tasks and Events with no Related To and no Name won't be
  extracted (1,999 Tasks in Production on 2026-11-03), because the license doesn't allow View All
  Activities. If they need these, someone has to link them to a record, or the integration
  needs a different user license.
- When new custom fields are added to the child objects in the second table (for example a new
  field on Opportunity Product or Task), add Read access for them to this permission set. Fields
  on the 14 main objects are covered automatically by View All Fields.
- **Sandbox deploys.** The permission set is built for Production. UAT and HTCDEV (checked on
  2026-11-03) don't have 47 of the fields it grants access to, so deploying it there fails. These
  fields can't be added from the repo:
  - 42 Gong (`Gong__`) and Dialpad (`Dialpad__`) managed package fields on Task and Event (21 on
    each). The Gong and Dialpad packages aren't installed in either sandbox.
  - 4 standard Opportunity Product fields: `Discount`, `Subtotal`, `NetUnitPrice`, and `AssetId`.
    They depend on org features that the sandboxes don't have turned on.
  - `Task.Type`, in HTCDEV only.

  To deploy to a sandbox, install the Gong and Dialpad packages there first, or leave these
  field permissions out of the sandbox deployment. Deploy the full version to Production.

## Component Manifest

Github Branch: [Beacon-Databricks-Integration](https://github.com/aaroncrear/BeaconImplementation/tree/Beacon-Databricks-Integration)

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Permission Set | N/A | Beacon_Databricks_Integration | Beacon - Databricks Integration | Created | Salesforce API Integration license. Read, View All Records, and View All Fields on Account, Asset, Beacon Feedback, Beacon Subscription, Campaign, Case, Contact, Contract, Lead, Opportunity, Order, Price Book, Product, and Quote. Access Activities for Tasks and Events. Read only field access on 178 fields across Account Team Member, Account Contact Relationship, Asset Relationship, Campaign Member, Opportunity Product, Opportunity Contact Role, Quote Line Item, Order Product, Task, and Event. |
| 2 | Custom Field | Account | ABM_Flag__c | ABM Flag | Created | Checkbox for ABM accounts, used by the HubSpot integration. Pulled from Production. |
| 3 | Custom Field | Account | Active_Drug_Count__c | Active Drug Count | Created | Number of active drugs, used by the HubSpot integration and Data Universe Tier. Pulled from Production. |
| 4 | Custom Field | Account | Funding__c | Funding | Created | Funding amount from data providers, used by the HubSpot integration. Pulled from Production. |
| 5 | Custom Field | Account | Tier__c | Tier | Created | Sales prioritisation picklist (1 to 5), used by the HubSpot integration. Pulled from Production. |
| 6 | Custom Field | Account Team Member | HW_Record_ID__c | HW Record ID | Created | External ID holding the record ID from the Hanson Wade org. Pulled from Production. |
| 7 | Custom Field | Campaign Member | HW_Record_ID__c | HW Record ID | Created | External ID holding the record ID from the Hanson Wade org. Pulled from Production. |
| 8 | Custom Field | Contact | Data_Universe_Tier__c | Data Universe Tier | Created | Formula for the Beacon Data Universe Tier (1 to 4). Pulled from Production. |
| 9 | Custom Field | Contact | HubSpot_Lead_Score__c | HubSpot Lead Score | Created | Lead score received from HubSpot. Pulled from Production. |
| 10 | Custom Field | Contact | Key_Job_Title__c | Key Job Title | Created | Formula checkbox, checked when the Title contains a key job title keyword. Pulled from Production. |
| 11 | Custom Field | Contact | Module_Interest__c | Module Interest | Created | Multi-select picklist using the Primary Module global value set, received from HubSpot. Pulled from Production. |
| 12 | Custom Field | Contact | User_Persona__c | User Persona | Created | Formula assigning a Beacon user persona from the Title. Pulled from Production. |
| 13 | Custom Field | Lead | Data_Universe_Tier__c | Data Universe Tier | Created | Formula for the Beacon Data Universe Tier (1 to 4). Pulled from Production. |
| 14 | Custom Field | Lead | HubSpot_Lead_Score__c | HubSpot Lead Score | Created | Lead score received from HubSpot. Pulled from Production. |
| 15 | Custom Field | Lead | Key_Job_Title__c | Key Job Title | Created | Formula checkbox, checked when the Title contains a key job title keyword. Pulled from Production. |
| 16 | Custom Field | Lead | LinkedIn_Profile__c | LinkedIn Profile | Created | LinkedIn profile URL for the Lead. Pulled from Production. |
| 17 | Custom Field | Lead | Module_Interest__c | Module Interest | Created | Multi-select picklist using the Primary Module global value set, received from HubSpot. Pulled from Production. |
| 18 | Custom Field | Lead | User_Persona__c | User Persona | Created | Formula assigning a Beacon user persona from the Title. Pulled from Production. |
| 19 | Custom Field | Opportunity Contact Role | HW_Record_ID__c | HW Record ID | Created | Holds the record ID from the Hanson Wade org. Pulled from Production. |
