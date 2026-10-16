# "claude/beacon-finance-permission-set-2h8i1x" – Release Notes

## Requirements

The business requested a new permission set for the Beacon Finance persona, named
**Beacon Finance - Object, Tab, FLS** with the description "Used to provide Object, Tab and Field
level access." It must grant:

- **Read** access to Lead and Campaign.
- **Read, Create, Update** access to Account, Contact, and Opportunity.
- The same tab and field level access, per object, as the existing
  **Beacon Sales - Object, Tab, FLS** permission set.
- Read only access to Lead fields, to match Read only access to the Lead object.
- Read only access to the Account Plan and Action Plan objects and their fields.

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
| Account Plan | ✔ | | | |
| Account Plan Objective | ✔ | | | |
| Account Plan Objective Measure | ✔ | | | |
| Account Plan Objective Measure Relationship (`AccountPlanObjMeasRela`) | ✔ | | | |
| Action Plan | ✔ | | | |
| Action Plan Template | ✔ | | | |

**Tab settings.** These are the same as Sales: the standard Account, Contact, Opportunity, Lead,
and Campaign tabs are set to `Visible`.

**Field Level Security.** All field permissions on Account (17), Contact (13), Opportunity (34),
and Campaign (44) were copied from the Sales permission set without changes. The Read and Edit
values match Sales field by field.

Lead (16 fields) was copied from Sales too, but every Lead field is **Read only**, to match the
Read only access on the Lead object. In Sales, 9 of these fields have Edit access because Sales
can create and edit Leads: `Account__c`, `Department__c`, `Lead_Type__c`, `NAICS_Code__c`,
`NAICS_Description__c`, `Region__c`, `Second_Email__c`, `United_States_Time_Zone__c`, and
`Unqualified_Reason__c`. Those 9 were set to Read only for Finance.

**Account Plan and Action Plan.** Object access was added for Account Plan, Account Plan
Objective, Account Plan Objective Measure, Account Plan Objective Measure Relationship, Action
Plan, and Action Plan Template. Each one is **Read only** (Create, Edit, and Delete are off). The
same 34 fields that Sales covers on these objects were added: Account Plan (20), Account Plan
Objective (5), Account Plan Objective Measure (3), and Action Plan (6). All of them are
**Read only**. Sales doesn't set tab visibility for these objects, so none was added for
Finance.

The permission set uses the `Salesforce` license, like the other Beacon persona permission sets.

## Acceptance Criteria

1. Deploy the branch to the target org.
2. Go to **Setup → Permission Sets** and open **Beacon Finance - Object, Tab, FLS**. Check that
   the description reads "Used to provide Object, Tab and Field level access." and that the
   license is Salesforce.
3. Under **Object Settings**, check each object:
   - Account, Contact, Opportunity: Read, Create, and Edit checked. Delete, View All, and Modify
     All unchecked.
   - Lead, Campaign, Account Plan, Account Plan Objective, Account Plan Objective Measure,
     Account Plan Objective Measure Relationship, Action Plan, Action Plan Template: only Read
     checked.
   - Tab Settings for all five objects: **Visible**.
4. Check the Field Permissions:
   - Account, Contact, Opportunity, Campaign: Read and Edit match **Beacon Sales - Object, Tab,
     FLS** field for field.
   - Lead: all 16 fields have Read checked and Edit unchecked.
   - Account Plan (20 fields), Account Plan Objective (5), Account Plan Objective Measure (3),
     Action Plan (6): all fields have Read checked and Edit unchecked.
5. Assign the permission set to a test Finance user who has no other Beacon object permission
   sets. Log in as that user and check that:
   - The Account, Contact, Opportunity, Lead, and Campaign tabs appear in the App Launcher.
   - The user can create and edit an Account, a Contact, and an Opportunity, but can't delete
     them.
   - The user can view Leads and Campaigns, but sees no New or Edit buttons and can't delete
     them.
   - The user can open an existing Account Plan and Action Plan (for example from the related
     list on an Account) and view their fields, but can't create, edit, or delete them.

## Post Deployment Items

- Assign **Beacon Finance - Object, Tab, FLS** to the Finance users (or add it to the Finance
  permission set group, if one is used).

## Component Manifest

Github Branch: [claude/beacon-finance-permission-set-2h8i1x](https://github.com/aaroncrear/BeaconImplementation/tree/claude/beacon-finance-permission-set-2h8i1x)

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Permission Set | N/A | Beacon_Finance_Object_Tab_FLS | Beacon Finance - Object, Tab, FLS | Created | Create/Read/Edit on Account, Contact, and Opportunity; Read only on Lead, Campaign, Account Plan (and its Objective, Objective Measure, and Objective Measure Relationship objects), Action Plan, and Action Plan Template. Tab and field access copied from Beacon Sales - Object, Tab, FLS, with all Lead, Account Plan, and Action Plan fields set to Read only. |
