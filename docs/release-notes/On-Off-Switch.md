# "On/Off-Switch" – Release Notes

## Requirements

Admins need a way to turn Flows, Validation Rules and Apex off in bulk, for example during a data load or migration, without deactivating each component one at a time and then reactivating it.

- Provide one place to switch Flows, Validation Rules and Apex on or off.
- Allow the switch to be set for the whole org, for a profile, or for a single user, so that a data-migration or integration user can skip automation while everyone else is unaffected.
- Leave all automation running by default.

## Release Notes

A new **hierarchy custom setting**, **On/Off Switch** (`On_Off_Switch__c`), was added with three checkboxes, each defaulting to `true`:

- **`Run_Flows__c`** (Run Flows): when checked, Flows that reference the setting run.
- **`Run_Validation_Rules__c`** (Run Validation Rules): when checked, Validation Rules that reference the setting run.
- **`Run_Apex__c`** (Run Apex): when checked, Apex that references the setting runs.

A hierarchy custom setting was chosen because Salesforce resolves its value at the most specific level set (User, then Profile, then Org Default). Automation can be turned off for one user without affecting anyone else. Flows and Validation Rules can read it through the `$Setup` global variable, and Apex can read it through `On_Off_Switch__c.getInstance()`, with no SOQL query.

The setting's visibility is **Public**, so Flows and Validation Rules can read it for every user without extra permissions.

**The switch is opt-in.** This build adds the setting only. No existing Flow, Validation Rule or Apex checks it yet, so deploying it changes no behavior. Each component must be updated to check the switch before the switch affects it. The switch does not affect Workflow Rules, Process Builder, Duplicate Rules, required fields, lookup filters or managed-package components. The `README.md` "On/Off Switch" section documents the checks to add:

- **Validation Rules:** `$Setup.On_Off_Switch__c.Run_Validation_Rules__c && ( <existing condition> )`
- **Record-triggered Flows:** add `{!$Setup.On_Off_Switch__c.Run_Flows__c}` to the entry conditions using **Formula Evaluates to True**. For other Flow types, add a Decision as the first element that ends the Flow when it is false.
- **Apex triggers:** `if (!On_Off_Switch__c.getInstance().Run_Apex__c) { return; }` at the top of the trigger or handler.

## Acceptance Criteria

1. In **Setup → Custom Settings**, confirm **On/Off Switch** (`On_Off_Switch__c`) exists with Setting Type **Hierarchy** and Visibility **Public**.
2. Open the setting and confirm the fields **Run Flows** (`Run_Flows__c`), **Run Validation Rules** (`Run_Validation_Rules__c`) and **Run Apex** (`Run_Apex__c`) exist as Checkbox fields that default to checked.
3. Click **Manage**, create the **Org Default** record, and confirm all three checkboxes are checked by default. Save it.
4. To confirm a Validation Rule honors the switch, create a test Validation Rule in a sandbox with the formula `$Setup.On_Off_Switch__c.Run_Validation_Rules__c && ISBLANK(Description)` on an object of your choice.
   1. Save a record with a blank Description and confirm the error appears.
   2. Add a **User** level record for your user with **Run Validation Rules** unchecked. Save the same record again and confirm it saves without the error.
   3. Delete the User level record, save again, and confirm the error returns.
5. To confirm a record-triggered Flow honors the switch, add `{!$Setup.On_Off_Switch__c.Run_Flows__c}` (Formula Evaluates to True) to a test Flow's entry conditions in a sandbox.
   1. Confirm the Flow runs when the switch is checked.
   2. Uncheck **Run Flows** at your User level. Confirm the Flow does not run.
6. Confirm the hierarchy: with the Org Default all checked and one user's User level record unchecked, confirm a second user still gets the Validation Rule error and the Flow still runs.
7. Remove the test Validation Rule and Flow after testing.

## Post Deployment Items

- In **Setup → Custom Settings → On/Off Switch → Manage**, create the **Org Default** record with **Run Flows**, **Run Validation Rules** and **Run Apex** all **checked**. The field defaults do not create this record. Create it before any Flow, Validation Rule or Apex is updated to check the switch.
- Restrict the **Customize Application** permission to trusted admins, since it allows editing the setting.
- Update the Flows, Validation Rules and Apex that should obey the switch, as described above. Until then, the switch has no effect.

## Component Manifest

Github Branch: https://github.com/aaroncrear/BeaconImplementation/tree/On/Off-Switch

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | CustomObject | On_Off_Switch__c | On_Off_Switch__c | On/Off Switch | Created | Public hierarchy custom setting used to turn off Flows, Validation Rules and Apex in bulk, at the Org, Profile or User level. |
| 2 | CustomField | On_Off_Switch__c | Run_Flows__c | Run Flows | Created | Checkbox (default true). When checked, Flows that reference this setting run. |
| 3 | CustomField | On_Off_Switch__c | Run_Validation_Rules__c | Run Validation Rules | Created | Checkbox (default true). When checked, Validation Rules that reference this setting run. |
| 4 | CustomField | On_Off_Switch__c | Run_Apex__c | Run Apex | Created | Checkbox (default true). When checked, Apex that references this setting runs. |
