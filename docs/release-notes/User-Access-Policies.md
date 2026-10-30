# "User-Access-Policies" – Release Notes

## Requirements

- Every Beacon user should automatically get the **Beacon - Baseline** permission set group
  (`Beacon_Baseline`). That group holds the baseline system, app and standard field access.
- Each user should also automatically get the persona-based **Beacon <Persona> - Object, Tab,
  FLS** permission set that matches their persona.
- When a user's persona changes, the permission set for their old persona must be removed and
  the one for their new persona granted.
- Access is driven by the custom **Persona** field on User (`User.Persona__c`), not by Role.
  Beacon has 29 roles, and several roles share each persona. User Access Policy criteria can't
  combine roles with OR logic, so a role-based design would need one policy per role and
  would break whenever a role is added or renamed.

## Release Notes

Ten **User Access Policies** were created, one for each persona value on `User.Persona__c` that
has a matching persona permission set:

| Order | Policy API Name | Label | Criteria | Persona Permission Set Granted |
|---|---|---|---|---|
| 1 | `Beacon_Persona_Consulting` | Beacon Persona - Consulting | `Persona__c` = Consulting | `Beacon_Consulting_Object_Tab_FLS` |
| 2 | `Beacon_Persona_Customer_Success` | Beacon Persona - Customer Success | `Persona__c` = Customer Success | `Beacon_Customer_Success_Object_Tab_FLS` |
| 3 | `Beacon_Persona_Executive` | Beacon Persona - Executive | `Persona__c` = Executive | `Beacon_Executive_Object_Tab_FLS` |
| 4 | `Beacon_Persona_Finance` | Beacon Persona - Finance | `Persona__c` = Finance | `Beacon_Finance_Object_Tab_FLS` |
| 5 | `Beacon_Persona_Marketing` | Beacon Persona - Marketing | `Persona__c` = Marketing | `Beacon_Marketing_Object_Tab_FLS` |
| 6 | `Beacon_Persona_Product` | Beacon Persona - Product | `Persona__c` = Product | `Beacon_Product_Object_Tab_FLS` |
| 7 | `Beacon_Persona_ResOps` | Beacon Persona - ResOps | `Persona__c` = ResOps | `Beacon_ResOps_Object_Tab_FLS` |
| 8 | `Beacon_Persona_Sales` | Beacon Persona - Sales | `Persona__c` = Sales | `Beacon_Sales_Object_Tab_FLS` |
| 9 | `Beacon_Persona_Salesforce_Admin` | Beacon Persona - Salesforce Admin | `Persona__c` = Salesforce Admin | `Beacon_Salesforce_Admin_Object_Tab_FLS` |
| 10 | `Beacon_Persona_Tech` | Beacon Persona - Tech | `Persona__c` = Tech | `Beacon_Tech_Object_Tab_FLS` |

**What each policy does:**

1. **Criteria:** a single filter, `Persona__c` equals the persona value. Persona is a
   restricted, single-select picklist, so a user can match only one policy. The **Order**
   values (1–10) therefore never decide between competing policies. They are set only because
   the field requires a value.
2. **Grant:** the `Beacon_Baseline` permission set group and that persona's
   `Beacon_<Persona>_Object_Tab_FLS` permission set.
3. **Revoke:** the other nine persona `Object_Tab_FLS` permission sets.
4. **Trigger:** `CreateAndUpdate`, so the policy runs when a user is created and whenever an
   existing user is updated and matches its criteria.

**Why removal is handled with Revoke actions:** a User Access Policy never undoes its own
grants when a user stops matching. To meet the "remove on persona change" requirement, each
policy explicitly revokes every other persona permission set. When a user's Persona changes
from Marketing to Sales, the Sales policy fires on that update, grants Sales and revokes
Marketing (and the other eight) in one step. No Flow is needed and no separate cleanup policy
is required.

**Why the Baseline group is granted by every policy, not by a separate policy:** when a user
matches more than one active policy, Salesforce applies only the policy with the lowest Order.
A standalone "all users get Baseline" policy would compete with the persona policies, so only
one of the two would ever run. Putting the Baseline grant inside each persona policy avoids
that.

**Personas intentionally not covered:** the `Portal` and `Integration` values on
`Persona__c` have no Beacon persona permission set, so no policy was built for them. Users
with those values, or with a blank Persona, match no policy and receive nothing from this
build.

**Status on deploy:** the policies deploy in **Design** status. A Salesforce admin activates
each policy in Setup by automating it (see Post Deployment Items).

## Acceptance Criteria

Run these in the target sandbox after the Post Deployment activation steps.

1. **Policies exist.** Go to Setup → User Access Policies. Confirm all ten "Beacon Persona – …"
   policies are listed and Active, with Order 1–10.
2. **Policy definition.** Open **Beacon Persona - Sales**. Confirm:
   - The criteria is Persona equals Sales.
   - The actions grant Beacon - Baseline (permission set group) and Beacon Sales - Object, Tab,
     FLS.
   - The actions revoke the other nine persona permission sets.
   - It runs when a user is created or updated.
3. **New user grant.** Create an internal Salesforce user with Persona = **Marketing** and save.
   On the user's Permission Set Group Assignments, confirm **Beacon - Baseline** is assigned. On
   Permission Set Assignments, confirm **Beacon Marketing - Object, Tab, FLS** is assigned and no
   other persona Object, Tab, FLS set is assigned.
4. **Persona change swaps access.** Edit the same user and change Persona to **Sales**. Confirm
   **Beacon Sales - Object, Tab, FLS** is now assigned, **Beacon Marketing - Object, Tab, FLS**
   has been removed, and Beacon - Baseline is still assigned.
5. **Every persona.** Repeat step 3 (or step 4 on one user) for each remaining persona: Consulting,
   Customer Success, Executive, Finance, Product, ResOps, Salesforce Admin and Tech. Each time,
   confirm exactly one persona permission set plus Beacon - Baseline.
6. **Unrelated update.** Edit the user's Title (leave Persona unchanged) and save. Confirm the
   assignments are unchanged and no errors are raised.
7. **Non-persona values.** Create a user with Persona = **Integration**. Confirm no Beacon
   persona permission set and no Beacon - Baseline group is assigned by a policy.
8. **Existing users.** After running the policies against existing users (Post Deployment
   Items), spot-check users from at least three personas against the role-to-persona mapping.

## Post Deployment Items

- **Prerequisites (completed 30 Oct 2026):** User Access Policies are enabled, and the
  `Beacon_Baseline` permission set group is deployed, in Beacon HTC Dev, Beacon UAT and Beacon
  Prod. Before deploying to any other org, confirm the same, plus `User.Persona__c` and all ten
  `Beacon_<Persona>_Object_Tab_FLS` permission sets.
- **Validate the metadata format before the first real deploy.** The policy XML follows the
  Metadata API shape for `UserAccessPolicy` (`userAccessPolicyActions` with `action`/`target`/
  `type`, and `userAccessPolicyFilters` with `columnName`/`operation`/`sortOrder`/`target`/
  `type`/`value`). The `target` value used on the User-field filter (`user`) could not be
  confirmed against an org retrieve. Run a validation-only deploy. If it fails on the filter,
  retrieve the existing **AC Test** policy from Beacon HTC Dev (built in the UI on a User
  field) and match its filter element.
- **Populate Persona on existing users.** Set `Persona__c` on all active users using the
  role-to-persona mapping before activating the policies.
- **Activate each policy:** Setup → User Access Policies → open the policy → **Automate
  Policy**. This moves it from Design to Active and starts the create/update trigger.
- **Apply to existing users:** on each activated policy, use the option to run the policy
  against users who already match its criteria. Automation alone only fires on future creates
  and updates.
- **Clean up manual assignments.** Any persona permission sets or Baseline sets that were
  assigned to users by hand will stay in place where they match the user's persona, and will be
  revoked where they don't, once the policy runs for that user.
- **Delete the AC Test policy** in Beacon HTC Dev once the format is confirmed, so it doesn't
  interfere with testing.
- **When a new persona is added** to `Persona__c`, it needs its own persona permission set and
  policy. It also needs a Revoke action added for its permission set in each of the existing
  ten policies.

## Component Manifest

Github Branch: [User-Access-Policies](https://github.com/aaroncrear/BeaconImplementation/tree/User-Access-Policies)

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | User Access Policy | User | `Beacon_Persona_Consulting` | Beacon Persona - Consulting | Created | When Persona = Consulting, grants the Beacon - Baseline PSG and `Beacon_Consulting_Object_Tab_FLS`, and revokes the other nine persona permission sets. Order 1, runs on create and update. |
| 2 | User Access Policy | User | `Beacon_Persona_Customer_Success` | Beacon Persona - Customer Success | Created | When Persona = Customer Success, grants the Beacon - Baseline PSG and `Beacon_Customer_Success_Object_Tab_FLS`, and revokes the other nine persona permission sets. Order 2, runs on create and update. |
| 3 | User Access Policy | User | `Beacon_Persona_Executive` | Beacon Persona - Executive | Created | When Persona = Executive, grants the Beacon - Baseline PSG and `Beacon_Executive_Object_Tab_FLS`, and revokes the other nine persona permission sets. Order 3, runs on create and update. |
| 4 | User Access Policy | User | `Beacon_Persona_Finance` | Beacon Persona - Finance | Created | When Persona = Finance, grants the Beacon - Baseline PSG and `Beacon_Finance_Object_Tab_FLS`, and revokes the other nine persona permission sets. Order 4, runs on create and update. |
| 5 | User Access Policy | User | `Beacon_Persona_Marketing` | Beacon Persona - Marketing | Created | When Persona = Marketing, grants the Beacon - Baseline PSG and `Beacon_Marketing_Object_Tab_FLS`, and revokes the other nine persona permission sets. Order 5, runs on create and update. |
| 6 | User Access Policy | User | `Beacon_Persona_Product` | Beacon Persona - Product | Created | When Persona = Product, grants the Beacon - Baseline PSG and `Beacon_Product_Object_Tab_FLS`, and revokes the other nine persona permission sets. Order 6, runs on create and update. |
| 7 | User Access Policy | User | `Beacon_Persona_ResOps` | Beacon Persona - ResOps | Created | When Persona = ResOps, grants the Beacon - Baseline PSG and `Beacon_ResOps_Object_Tab_FLS`, and revokes the other nine persona permission sets. Order 7, runs on create and update. |
| 8 | User Access Policy | User | `Beacon_Persona_Sales` | Beacon Persona - Sales | Created | When Persona = Sales, grants the Beacon - Baseline PSG and `Beacon_Sales_Object_Tab_FLS`, and revokes the other nine persona permission sets. Order 8, runs on create and update. |
| 9 | User Access Policy | User | `Beacon_Persona_Salesforce_Admin` | Beacon Persona - Salesforce Admin | Created | When Persona = Salesforce Admin, grants the Beacon - Baseline PSG and `Beacon_Salesforce_Admin_Object_Tab_FLS`, and revokes the other nine persona permission sets. Order 9, runs on create and update. |
| 10 | User Access Policy | User | `Beacon_Persona_Tech` | Beacon Persona - Tech | Created | When Persona = Tech, grants the Beacon - Baseline PSG and `Beacon_Tech_Object_Tab_FLS`, and revokes the other nine persona permission sets. Order 10, runs on create and update. |
