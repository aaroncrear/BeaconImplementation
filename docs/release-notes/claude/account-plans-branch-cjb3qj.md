# "claude/account-plans-branch-cjb3qj" – Release Notes

## Requirements

- Enable Salesforce's standard Account Plans feature (Account Plan, Account Plan Objective, Account Plan Objective Measure, Account Plan Objective Measure Relation) so Consulting, Customer Success, and Sales can build out account strategy, objectives, and measurable targets directly against Account records.
- Extend the standard Action Plans feature (Action Plan, Action Plan Template) so the same teams can execute against Account Plan Objectives with trackable action items.
- Grant object, tab, and field-level security (FLS) for the new Account Plan / Action Plan objects across all existing Beacon permission sets, scoped by role:
  - **Beacon Consulting**, **Beacon Customer Success**, **Beacon Sales**: full working access (Read, Create, Edit) to all six objects and all of their permissionable fields.
  - **Beacon Executive**, **Beacon Marketing**, **Beacon Product**, **Beacon ResOps**, **Beacon Tech**: Read-only visibility into all six objects and all of their permissionable fields.

## Release Notes

- Deployed the standard `AccountPlan`, `AccountPlanObjective`, `AccountPlanObjectiveMeasure`, and `AccountPlanObjMeasRela` objects with Beacon-specific custom fields (`Beacon_Strategy__c`, `CS_Overview__c`, `Consulting_Overview__c`, `Customer_Strategy__c`) added to `AccountPlan` to capture team-specific account strategy notes, plus record page layouts and a compact layout for Account Plan.
- The existing `ActionPlan` object (already present in the org from prior work) is now included in the permission model alongside its companion `ActionPlanTemplate` object so users can execute Action Plans against Account Plan Objectives (`ActionPlan.TargetId` supports `AccountPlanObjective` as a target).
- Updated `Beacon_Salesforce_Admin_Object_Tab_FLS` (via the org metadata sync) to grant full object and field permissions on `AccountPlan`, `AccountPlanObjMeasRela`, `AccountPlanObjective`, and `AccountPlanObjectiveMeasure`.
- Added object permissions and field-level security for all six Account Plan / Action Plan objects to the eight remaining Beacon role permission sets (`Beacon_Consulting_Object_Tab_FLS`, `Beacon_Customer_Success_Object_Tab_FLS`, `Beacon_Sales_Object_Tab_FLS`, `Beacon_Executive_Object_Tab_FLS`, `Beacon_Marketing_Object_Tab_FLS`, `Beacon_Product_Object_Tab_FLS`, `Beacon_ResOps_Object_Tab_FLS`, `Beacon_Tech_Object_Tab_FLS`).
- Field-level security was granted only on fields Salesforce reports as permissionable for these objects. Several fields are intentionally excluded from FLS because Salesforce does not support field-level security on them: the `Name` field on all four Account Plan objects, `OwnerId`/owner-style lookups (`AccountPlan.AccountId`, `ActionPlan.TargetId`, `ActionPlan.ActionPlanTemplateVersionId`), master-detail relationship fields (`AccountPlanObjective.AccountPlanId`, `AccountPlanObjectiveMeasure.AccountPlanObjectiveId`), calculated/shadow value fields on `AccountPlanObjectiveMeasure`, and the two reference fields on `AccountPlanObjMeasRela` (which has no permissionable fields at all — object-level access only). No tab settings were added for these objects since none of them have a dedicated app tab; they are surfaced via related lists on the Account record.
- No permission set grants `Delete` or `Modify All`/`View All` on these objects for any of the eight updated sets, consistent with the existing pattern used for other business objects (Account, Contact, Lead, Opportunity) in those same permission sets.

## Acceptance Criteria

1. As a user assigned the **Beacon Consulting**, **Beacon Customer Success**, or **Beacon Sales** permission set:
   - Navigate to an Account record and confirm an Account Plan can be created, viewed, and edited from the related list.
   - Confirm all fields on the Account Plan layout (including Beacon Strategy, CS Overview, Consulting Overview, Customer Strategy) are visible and editable.
   - Create an Account Plan Objective under the Account Plan and confirm it can be created/edited, including setting the Objective Owner.
   - Create an Account Plan Objective Measure under the Objective and confirm Current Value, Target Value, and Value Type can be set and edited.
   - Confirm an Account Plan Objective Measure Relation can be created linking a measure to a Campaign/Case/Contact/Opportunity record.
   - Create an Action Plan targeting an Account Plan Objective and confirm it can be created/edited, including Status and dates.
   - Confirm an Action Plan Template can be selected/viewed when creating an Action Plan.
2. As a user assigned **Beacon Executive**, **Beacon Marketing**, **Beacon Product**, **Beacon ResOps**, or **Beacon Tech**:
   - Confirm all six objects (Account Plan, Account Plan Objective, Account Plan Objective Measure, Account Plan Objective Measure Relation, Action Plan, Action Plan Template) and their records are visible/read-only.
   - Confirm no Create, Edit, or Delete actions are available on any of the six objects.
3. Confirm none of the eight updated permission sets grant "View All"/"Modify All" on the six objects.

## Post Deployment Items

None.

## Component Manifest

Github Branch: https://github.com/aaroncrear/BeaconImplementation/tree/claude/account-plans-branch-cjb3qj

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Custom Object | Account Plan | AccountPlan | Account Plan | Created | Standard Account Plan object enabled with layout and compact layout for account strategy planning. |
| 2 | Custom Object | Account Plan Objective | AccountPlanObjective | Account Plan Objective | Created | Standard object for tracking objectives tied to an Account Plan. |
| 3 | Custom Object | Account Plan Objective Measure | AccountPlanObjectiveMeasure | Account Plan Objective Measure | Created | Standard object for tracking measurable targets/current values against an Objective. |
| 4 | Custom Object | Account Plan Objective Measure Relation | AccountPlanObjMeasRela | Account Plan Objective Measure Relation | Created | Standard junction object linking a Measure to a reference record (Campaign/Case/Contact/Opportunity). |
| 5 | Custom Field | Account Plan | AccountPlan.Beacon_Strategy__c | Beacon Strategy | Created | Custom long text field capturing Beacon's overall strategy for the account. |
| 6 | Custom Field | Account Plan | AccountPlan.CS_Overview__c | CS Overview | Created | Custom long text field for Customer Success overview notes. |
| 7 | Custom Field | Account Plan | AccountPlan.Consulting_Overview__c | Consulting Overview | Created | Custom long text field for Consulting overview notes. |
| 8 | Custom Field | Account Plan | AccountPlan.Customer_Strategy__c | Customer Strategy | Created | Custom long text field capturing the customer's own stated strategy. |
| 9 | Page Layout | Account Plan | AccountPlan-Account Plan Layout | Account Plan Layout | Created | Record page layout for Account Plan. |
| 10 | Page Layout | Account Plan Objective | AccountPlanObjective-Account Plan Objective Layout | Account Plan Objective Layout | Created | Record page layout for Account Plan Objective. |
| 11 | Page Layout | Account Plan Objective Measure | AccountPlanObjectiveMeasure-Account Plan Objective Measure Layout | Account Plan Objective Measure Layout | Created | Record page layout for Account Plan Objective Measure. |
| 12 | Compact Layout | Account Plan | Beacon_Account_Plan_Compact_Layout | Beacon Account Plan Compact Layout | Created | Compact layout for Account Plan highlights panel. |
| 13 | Permission Set | Account Plan / Action Plan (Admin) | Beacon_Salesforce_Admin_Object_Tab_FLS | Beacon Salesforce Admin - Object, Tab, FLS | Updated | Full object and field permissions granted on AccountPlan, AccountPlanObjMeasRela, AccountPlanObjective, and AccountPlanObjectiveMeasure. |
| 14 | Permission Set | Account Plan / Action Plan | Beacon_Consulting_Object_Tab_FLS | Beacon Consulting - Object, Tab, FLS | Updated | Read/Create/Edit object permissions and FLS added for all six Account Plan / Action Plan objects. |
| 15 | Permission Set | Account Plan / Action Plan | Beacon_Customer_Success_Object_Tab_FLS | Beacon Customer Success - Object, Tab, FLS | Updated | Read/Create/Edit object permissions and FLS added for all six Account Plan / Action Plan objects. |
| 16 | Permission Set | Account Plan / Action Plan | Beacon_Sales_Object_Tab_FLS | Beacon Sales - Object, Tab, FLS | Updated | Read/Create/Edit object permissions and FLS added for all six Account Plan / Action Plan objects. |
| 17 | Permission Set | Account Plan / Action Plan | Beacon_Executive_Object_Tab_FLS | Beacon Executive - Object, Tab, FLS | Updated | Read-only object permissions and FLS added for all six Account Plan / Action Plan objects. |
| 18 | Permission Set | Account Plan / Action Plan | Beacon_Marketing_Object_Tab_FLS | Beacon Marketing - Object, Tab, FLS | Updated | Read-only object permissions and FLS added for all six Account Plan / Action Plan objects. |
| 19 | Permission Set | Account Plan / Action Plan | Beacon_Product_Object_Tab_FLS | Beacon Product - Object, Tab, FLS | Updated | Read-only object permissions and FLS added for all six Account Plan / Action Plan objects. |
| 20 | Permission Set | Account Plan / Action Plan | Beacon_ResOps_Object_Tab_FLS | Beacon ResOps - Object, Tab, FLS | Updated | Read-only object permissions and FLS added for all six Account Plan / Action Plan objects. |
| 21 | Permission Set | Account Plan / Action Plan | Beacon_Tech_Object_Tab_FLS | Beacon Tech - Object, Tab, FLS | Updated | Read-only object permissions and FLS added for all six Account Plan / Action Plan objects. |
