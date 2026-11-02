# "Persona-Permission-Set-Groups" – Release Notes

## Requirements

- Each Beacon persona, except Integration, needs its own permission set group named
  **Beacon - {Persona} Integrations**. The group holds the permission sets for every integration
  that persona's users need.
- The integrations are connected only in Production, so the integration permission sets are
  added to these groups in Production. The groups are deployed empty.
- The existing persona User Access Policies must also assign the persona's Integrations group,
  and remove it when the user's persona changes, on top of what they already do.

## Release Notes

**Ten new permission set groups** were created, one per persona that has a User Access Policy:

| Persona | API Name | Label |
|---|---|---|
| Consulting | `Beacon_Consulting_Integrations` | Beacon - Consulting Integrations |
| Customer Success | `Beacon_Customer_Success_Integrations` | Beacon - Customer Success Integrations |
| Executive | `Beacon_Executive_Integrations` | Beacon - Executive Integrations |
| Finance | `Beacon_Finance_Integrations` | Beacon - Finance Integrations |
| Marketing | `Beacon_Marketing_Integrations` | Beacon - Marketing Integrations |
| Product | `Beacon_Product_Integrations` | Beacon - Product Integrations |
| ResOps | `Beacon_ResOps_Integrations` | Beacon - ResOps Integrations |
| Sales | `Beacon_Sales_Integrations` | Beacon - Sales Integrations |
| Salesforce Admin | `Beacon_Salesforce_Admin_Integrations` | Beacon - Salesforce Admin Integrations |
| Tech | `Beacon_Tech_Integrations` | Beacon - Tech Integrations |

Each group is deployed with no permission sets, so it grants nothing until integration
permission sets are added to it in Production. `hasActivationRequired` is false, the same as
`Beacon_Baseline`.

**The ten existing `Beacon_Persona_*` User Access Policies were updated.** Each one now also:

1. **Grants** that persona's `Beacon_<Persona>_Integrations` group.
2. **Revokes** the other nine `Beacon_<Persona>_Integrations` groups.

The criteria, order, trigger (`CreateAndUpdate`), status (`Design`) and existing actions are
unchanged. The description on each policy was rewritten to cover the new actions and kept under the 255-character limit for User Access Policy descriptions. Each policy
now has 21 actions: 3 grants and 18 revokes.

**Why the groups are granted by the existing persona policies:** a user who matches more than
one active policy gets only the policy with the lowest Order. A separate set of
"Integrations" policies would compete with the persona policies, and only one of them would
run. Putting the actions into the existing policies avoids that. It also means the
Integrations group swaps in the same step as the Object, Tab, FLS permission set when Persona
changes.

**Why removal uses Revoke actions:** a User Access Policy never undoes its own grants when a
user stops matching. Each policy revokes every other persona's Integrations group, so changing
a user from Marketing to Sales grants Beacon - Sales Integrations and removes Beacon Marketing
Integrations.

**Why the groups are deployed empty:** the integration packages and their permission sets exist
only in Production. If a group referenced those permission sets, the deploy would fail in
Beacon HTC Dev and Beacon UAT. Deploying the groups empty keeps the same metadata deployable to
every org. The integration permission sets are added in Production after deployment.

**Personas not covered:** `Integration` was excluded as requested. `Portal` was also not given a
group, because it has no persona permission set or User Access Policy to assign one. Users with
a blank Persona match no policy and receive nothing from this build.

## Acceptance Criteria

Run these in the target org after deployment. Policies that are already Active stay Active.
Policies still in Design need the activation steps in the User-Access-Policies release notes.

1. **Groups exist.** Go to Setup → Permission Set Groups. Confirm all ten "Beacon {Persona}
   Integrations" groups are listed with the API names in the table above.
2. **Groups are empty outside Production.** Open **Beacon - Sales Integrations** in a sandbox.
   Confirm it has no permission sets and its status is Updated.
3. **Policy definition.** Go to Setup → User Access Policies and open **Beacon Persona - Sales**.
   Confirm:
   - It still grants Beacon - Baseline and Beacon Sales - Object, Tab, FLS.
   - It also grants **Beacon - Sales Integrations**.
   - It still revokes the other nine persona Object, Tab, FLS permission sets.
   - It also revokes the other nine Beacon - {Persona} Integrations groups.
4. **New user grant.** Create an internal user with Persona = **Marketing**. On Permission Set
   Group Assignments, confirm **Beacon - Baseline** and **Beacon - Marketing Integrations** are
   assigned, and no other Integrations group is assigned.
5. **Persona change swaps the group.** Change the same user's Persona to **Sales** and save.
   Confirm **Beacon - Sales Integrations** is assigned, **Beacon - Marketing Integrations** has been
   removed, and Beacon - Baseline and Beacon Sales - Object, Tab, FLS are assigned.
6. **Every persona.** Repeat step 5 for Consulting, Customer Success, Executive, Finance,
   Product, ResOps, Salesforce Admin and Tech. Each time, confirm exactly one Integrations group
   is assigned and it matches the Persona.
7. **Integration persona.** Create or edit a user with Persona = **Integration**. Confirm no
   Beacon Integrations group is assigned by a policy.
8. **Production only: integration access.** After adding integration permission sets to a
   group in Production, confirm a user with that persona gets the integration access. Check that
   the group's status is Updated, not Outdated or Failed.

## Post Deployment Items

- **Production: add integration permission sets.** In Setup → Permission Set Groups, open each
  Beacon - {Persona} Integrations group and add the integration permission sets that persona
  needs. Wait for each group's status to return to Updated.
- **Do not retrieve the Production groups into this branch** once their permission sets are
  added. Those permission sets don't exist in Beacon HTC Dev or Beacon UAT, so a later deploy
  of the retrieved groups to a sandbox would fail. If the groups need to be redeployed to
  Production, retrieve them from Production first so the added permission sets aren't removed.
- **Apply to existing users.** Active policies only fire on future user creates and updates. On
  each policy, run it against users who already match its criteria so existing users get
  their Integrations group.
- **Remove manual assignments.** Any integration permission sets assigned to users directly
  will stay in place alongside the group. Remove them once the user has the group.
- **When a new persona is added** to `Persona__c`, it needs its own Integrations group, a Grant
  action in its new policy, and a Revoke action for its group in each of the existing ten
  policies.

## Component Manifest

Github Branch: [Persona-Permission-Set-Groups](https://github.com/aaroncrear/BeaconImplementation/tree/Persona-Permission-Set-Groups)

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Permission Set Group | N/A | `Beacon_Consulting_Integrations` | Beacon - Consulting Integrations | Created | Empty group for the integration permission sets Consulting users need. Integration permission sets are added in Production only. |
| 2 | Permission Set Group | N/A | `Beacon_Customer_Success_Integrations` | Beacon - Customer Success Integrations | Created | Empty group for the integration permission sets Customer Success users need. Integration permission sets are added in Production only. |
| 3 | Permission Set Group | N/A | `Beacon_Executive_Integrations` | Beacon - Executive Integrations | Created | Empty group for the integration permission sets Executive users need. Integration permission sets are added in Production only. |
| 4 | Permission Set Group | N/A | `Beacon_Finance_Integrations` | Beacon - Finance Integrations | Created | Empty group for the integration permission sets Finance users need. Integration permission sets are added in Production only. |
| 5 | Permission Set Group | N/A | `Beacon_Marketing_Integrations` | Beacon - Marketing Integrations | Created | Empty group for the integration permission sets Marketing users need. Integration permission sets are added in Production only. |
| 6 | Permission Set Group | N/A | `Beacon_Product_Integrations` | Beacon - Product Integrations | Created | Empty group for the integration permission sets Product users need. Integration permission sets are added in Production only. |
| 7 | Permission Set Group | N/A | `Beacon_ResOps_Integrations` | Beacon - ResOps Integrations | Created | Empty group for the integration permission sets ResOps users need. Integration permission sets are added in Production only. |
| 8 | Permission Set Group | N/A | `Beacon_Sales_Integrations` | Beacon - Sales Integrations | Created | Empty group for the integration permission sets Sales users need. Integration permission sets are added in Production only. |
| 9 | Permission Set Group | N/A | `Beacon_Salesforce_Admin_Integrations` | Beacon - Salesforce Admin Integrations | Created | Empty group for the integration permission sets Salesforce Admin users need. Integration permission sets are added in Production only. |
| 10 | Permission Set Group | N/A | `Beacon_Tech_Integrations` | Beacon - Tech Integrations | Created | Empty group for the integration permission sets Tech users need. Integration permission sets are added in Production only. |
| 11 | User Access Policy | User | `Beacon_Persona_Consulting` | Beacon Persona - Consulting | Updated | Added a Grant for `Beacon_Consulting_Integrations` and Revokes for the other nine Integrations groups. Description updated. Existing actions unchanged. |
| 12 | User Access Policy | User | `Beacon_Persona_Customer_Success` | Beacon Persona - Customer Success | Updated | Added a Grant for `Beacon_Customer_Success_Integrations` and Revokes for the other nine Integrations groups. Description updated. Existing actions unchanged. |
| 13 | User Access Policy | User | `Beacon_Persona_Executive` | Beacon Persona - Executive | Updated | Added a Grant for `Beacon_Executive_Integrations` and Revokes for the other nine Integrations groups. Description updated. Existing actions unchanged. |
| 14 | User Access Policy | User | `Beacon_Persona_Finance` | Beacon Persona - Finance | Updated | Added a Grant for `Beacon_Finance_Integrations` and Revokes for the other nine Integrations groups. Description updated. Existing actions unchanged. |
| 15 | User Access Policy | User | `Beacon_Persona_Marketing` | Beacon Persona - Marketing | Updated | Added a Grant for `Beacon_Marketing_Integrations` and Revokes for the other nine Integrations groups. Description updated. Existing actions unchanged. |
| 16 | User Access Policy | User | `Beacon_Persona_Product` | Beacon Persona - Product | Updated | Added a Grant for `Beacon_Product_Integrations` and Revokes for the other nine Integrations groups. Description updated. Existing actions unchanged. |
| 17 | User Access Policy | User | `Beacon_Persona_ResOps` | Beacon Persona - ResOps | Updated | Added a Grant for `Beacon_ResOps_Integrations` and Revokes for the other nine Integrations groups. Description updated. Existing actions unchanged. |
| 18 | User Access Policy | User | `Beacon_Persona_Sales` | Beacon Persona - Sales | Updated | Added a Grant for `Beacon_Sales_Integrations` and Revokes for the other nine Integrations groups. Description updated. Existing actions unchanged. |
| 19 | User Access Policy | User | `Beacon_Persona_Salesforce_Admin` | Beacon Persona - Salesforce Admin | Updated | Added a Grant for `Beacon_Salesforce_Admin_Integrations` and Revokes for the other nine Integrations groups. Description updated. Existing actions unchanged. |
| 20 | User Access Policy | User | `Beacon_Persona_Tech` | Beacon Persona - Tech | Updated | Added a Grant for `Beacon_Tech_Integrations` and Revokes for the other nine Integrations groups. Description updated. Existing actions unchanged. |
