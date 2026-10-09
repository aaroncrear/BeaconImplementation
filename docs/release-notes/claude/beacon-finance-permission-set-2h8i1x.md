# "claude/beacon-finance-permission-set-2h8i1x" – Release Notes

## Requirements

The business requested a new permission set for the Beacon Finance persona, named
**Beacon Finance - Object, Tab, FLS** with the description "Used to provide Object, Tab and Field
level access." It must grant:

- **Read** access to Lead and Campaign.
- **Read, Create, Update** access to Account, Contact, and Opportunity.
- The same tab and field level access, per object, as the existing
  **Beacon Sales - Object, Tab, FLS** permission set.

## Release Notes

A new permission set, `Beacon_Finance_Object_Tab_FLS`, was created by using
`Beacon_Sales_Object_Tab_FLS` as the starting point. That way the Finance tab and field access
matches Sales exactly for the five objects in scope.

**Object permissions.** Delete, View All, and Modify All are `false` on every object.

| Object | Read | Create | Edit | Delete |
|---|---|---|---|---|
| Account | ✔ | ✔ | ✔ | |
| Contact | ✔ | ✔ | ✔ | |
| Opportunity | ✔ | ✔ | ✔ | |
| Lead | ✔ | | | |
| Campaign | ✔ | | | |

**Tab settings.** These are the same as Sales: the standard Account, Contact, Opportunity, Lead,
and Campaign tabs are set to `Visible`.

**Field Level Security.** All 124 field permissions on Account (17), Contact (13),
Opportunity (34), Lead (16), and Campaign (44) were copied from the Sales permission set without
changes. The Read and Edit values match Sales field by field.

**Out of scope.** The Sales permission set also covers Account Plan, Account Plan Objective,
Account Plan Objective Measure, Account Plan Objective Measure Relationship, Action Plan, and
Action Plan Template. The request did not ask for those objects, so they were left out of the
Finance permission set, along with their field permissions.

**Lead field access note.** In Sales, Lead is Create/Read/Edit, so 9 Lead fields have Edit FLS
(`Account__c`, `Department__c`, `Lead_Type__c`, `NAICS_Code__c`, `NAICS_Description__c`,
`Region__c`, `Second_Email__c`, `United_States_Time_Zone__c`, `Unqualified_Reason__c`). The
request asked for the same FLS, so those values were kept. Finance has Read only on the Lead
object, though, so in practice Finance users can't edit these fields. They only get Read access.

The permission set uses the `Salesforce` license, like the other Beacon persona permission sets.

## Acceptance Criteria

1. Deploy the branch to the target org.
2. Go to **Setup → Permission Sets** and open **Beacon Finance - Object, Tab, FLS**. Check that
   the description reads "Used to provide Object, Tab and Field level access." and that the
   license is Salesforce.
3. Under **Object Settings**, check each object:
   - Account, Contact, Opportunity: Read, Create, and Edit checked. Delete, View All, and Modify
     All unchecked.
   - Lead, Campaign: only Read checked.
   - Tab Settings for all five objects: **Visible**.
4. For each of the five objects, compare the Field Permissions with **Beacon Sales - Object, Tab,
   FLS**. Read and Edit should match field for field.
5. Assign the permission set to a test Finance user who has no other Beacon object permission
   sets. Log in as that user and check that:
   - The Account, Contact, Opportunity, Lead, and Campaign tabs appear in the App Launcher.
   - The user can create and edit an Account, a Contact, and an Opportunity, but can't delete
     them.
   - The user can view Leads and Campaigns, but sees no New or Edit buttons and can't delete
     them.

## Post Deployment Items

- Assign **Beacon Finance - Object, Tab, FLS** to the Finance users (or add it to the Finance
  permission set group, if one is used).

## Component Manifest

Github Branch: [claude/beacon-finance-permission-set-2h8i1x](https://github.com/aaroncrear/BeaconImplementation/tree/claude/beacon-finance-permission-set-2h8i1x)

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Permission Set | N/A | Beacon_Finance_Object_Tab_FLS | Beacon Finance - Object, Tab, FLS | Created | Read on Lead and Campaign; Create/Read/Edit on Account, Contact, and Opportunity; tab and field access copied from Beacon Sales - Object, Tab, FLS for those objects. |
