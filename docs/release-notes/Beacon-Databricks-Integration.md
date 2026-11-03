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
given with two user permissions instead:

- **Access Activities** (`ActivitiesAccess`)
- **View All Activities** (`ViewAllActivities`). This is the activity version of View All
  Records.

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

**License.** The permission set uses the **Salesforce API Integration** permission set license,
the same one used by the existing Beacon Hubspot, Gong, Dialpad, and LinkedIn SN integration
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
5. Under **System Permissions**, check that **Access Activities** and **View All Activities**
   are checked, and that no other system permissions are on.
6. Assign the permission set to the Databricks integration user (a Salesforce Integration user
   with the Salesforce API Integration permission set license, whose profile has API Enabled
   and no other object access).
7. As that user, run these SOQL queries (for example from Workbench or the Databricks
   connector). Check that each one returns every record in the org, including records the user
   doesn't own, and that all fields come back:
   - `SELECT FIELDS(ALL) FROM Account LIMIT 200`, and the same for Contact, Lead, Opportunity,
     Campaign, Product2, Pricebook2, Quote, Contract, Order, Asset, Beacon_Subscription__c,
     Beacon_Feedback__c, and Case.
   - `SELECT FIELDS(ALL) FROM Task LIMIT 200` and `SELECT FIELDS(ALL) FROM Event LIMIT 200`
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
- When new custom fields are added to the child objects in the second table (for example a new
  field on Opportunity Product or Task), add Read access for them to this permission set. Fields
  on the 14 main objects are covered automatically by View All Fields.

## Component Manifest

Github Branch: [Beacon-Databricks-Integration](https://github.com/aaroncrear/BeaconImplementation/tree/Beacon-Databricks-Integration)

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Permission Set | N/A | Beacon_Databricks_Integration | Beacon - Databricks Integration | Created | Salesforce API Integration license. Read, View All Records, and View All Fields on Account, Asset, Beacon Feedback, Beacon Subscription, Campaign, Case, Contact, Contract, Lead, Opportunity, Order, Price Book, Product, and Quote. Access Activities and View All Activities for Tasks and Events. Read only field access on 178 fields across Account Team Member, Account Contact Relationship, Asset Relationship, Campaign Member, Opportunity Product, Opportunity Contact Role, Quote Line Item, Order Product, Task, and Event. |
