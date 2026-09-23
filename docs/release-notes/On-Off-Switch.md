# "On/Off-Switch" – Release Notes

## Requirements

Admins need a way to turn Flows, Validation Rules and Apex off in bulk, for example during a data load or migration, without deactivating each component one at a time and then reactivating it.

- Provide one place to switch Flows, Validation Rules and Apex on or off.
- Allow the switch to be set for the whole org, for a profile, or for a single user, so that a data-migration or integration user can skip automation while everyone else is unaffected.
- Leave all automation running by default.
- Remove the User bypass fields (Bypass Val Rules, Bypass Flows and Bypass Apex) added in [PR #24](https://github.com/aaroncrear/BeaconImplementation/pull/24). They are no longer needed.

## Release Notes

### On/Off Switch custom setting

A new **hierarchy custom setting**, **On/Off Switch** (`On_Off_Switch__c`), was added with three checkboxes, each defaulting to `true`:

- **`Run_Flows__c`** (Run Flows): when checked, Flows that reference the setting run.
- **`Run_Validation_Rules__c`** (Run Validation Rules): when checked, Validation Rules that reference the setting run.
- **`Run_Apex__c`** (Run Apex): when checked, Apex that references the setting runs.

A hierarchy custom setting was chosen because Salesforce resolves its value at the most specific level set (User, then Profile, then Org Default). Automation can be turned off for one user without affecting anyone else. Flows and Validation Rules can read it through the `$Setup` global variable, and Apex can read it through `On_Off_Switch__c.getInstance()`, with no SOQL query.

The setting's visibility is **Public**, so Flows and Validation Rules can read it for every user without extra permissions.

### User bypass fields removed

[PR #24](https://github.com/aaroncrear/BeaconImplementation/pull/24) also added three checkbox fields to the **User** object: **Bypass Val Rules** (`Bypass_Val_Rules__c`), **Bypass Flows** (`Bypass_Flows__c`) and **Bypass Apex** (`Bypass_Apex__c`). They were added to the **User Layout**, and edit access was granted in the **Beacon Salesforce Admin - Object, Tab, FLS** permission set.

This change deletes the three fields and reverses the related changes:

- The fields were removed from the **Additional Information** section of the **User Layout**, which is empty again.
- Their field permissions were removed from the **Beacon Salesforce Admin - Object, Tab, FLS** permission set.
- The `README.md` "On/Off Switch" section now covers only the custom setting.

No Flow, Validation Rule or Apex referenced the fields, so deleting them changes no automation behavior. A User level On/Off Switch record still turns automation off for one user, as the fields were meant to.

### How automation checks the switch

**The switch is opt-in.** No existing Flow, Validation Rule or Apex checks it yet, so deploying it changes no behavior. Each component must be updated to check it before it takes effect. It does not affect Workflow Rules, Process Builder, Duplicate Rules, required fields, lookup filters or managed-package components.

The `README.md` "On/Off Switch" section documents the checks to add:

- **Validation Rules:** `$Setup.On_Off_Switch__c.Run_Validation_Rules__c && ( <existing condition> )`
- **Record-triggered Flows:** add `{!$Setup.On_Off_Switch__c.Run_Flows__c}` to the entry conditions using **Formula Evaluates to True**. For other Flow types, add a Decision as the first element that ends the Flow when it is false.
- **Apex triggers:** return early at the top of each trigger or handler when `On_Off_Switch__c.getInstance().Run_Apex__c` is false.

## Acceptance Criteria

1. In **Setup → Custom Settings**, confirm **On/Off Switch** (`On_Off_Switch__c`) exists with Setting Type **Hierarchy** and Visibility **Public**.
2. Open the setting and confirm the fields **Run Flows** (`Run_Flows__c`), **Run Validation Rules** (`Run_Validation_Rules__c`) and **Run Apex** (`Run_Apex__c`) exist as Checkbox fields that default to checked.
3. Click **Manage**, then click the **New** button in the **Default Organization Level Value** section at the top of the page (the lower **New** button only offers Profile or User). Create the **Org Default** record, and confirm all three checkboxes are checked by default. Save it.
4. In **Object Manager → User → Fields & Relationships**, confirm **Bypass Val Rules**, **Bypass Flows** and **Bypass Apex** no longer exist. Also check **Deleted Fields** and erase them there if they are listed.
5. Open a user's record and confirm the **Additional Information** section no longer shows the bypass fields.
6. In **Setup → Permission Sets → Beacon Salesforce Admin - Object, Tab, FLS → Object Settings → Users**, confirm the bypass fields are no longer listed.
7. To confirm a Validation Rule honors the switch, create a test Validation Rule in a sandbox with the formula `$Setup.On_Off_Switch__c.Run_Validation_Rules__c && ISBLANK(Description)` on an object of your choice.
   1. Save a record with a blank Description and confirm the error appears.
   2. Add a **User** level On/Off Switch record for your user with **Run Validation Rules** unchecked. Save the same record again and confirm it saves without the error.
   3. Delete the User level record, save again, and confirm the error returns.
8. To confirm a record-triggered Flow honors the switch, add `{!$Setup.On_Off_Switch__c.Run_Flows__c}` (Formula Evaluates to True) to a test Flow's entry conditions in a sandbox.
   1. Confirm the Flow runs when the switch is checked.
   2. Uncheck **Run Flows** at your User level and confirm the Flow does not run. Then check it again.
9. Confirm the switch only affects the intended user: with the Org Default all checked and one user's User level record unchecked, confirm a second user still gets the Validation Rule error and the Flow still runs.
10. Remove the test Validation Rule and Flow after testing.

## Post Deployment Items

- In **Setup → Custom Settings → On/Off Switch → Manage**, create the **Org Default** record with **Run Flows**, **Run Validation Rules** and **Run Apex** all **checked**. Use the **New** button at the top of the page, in the **Default Organization Level Value** section. The **New** button lower down, next to the list of records, only offers Profile or User. The field defaults do not create this record. Create it before any Flow, Validation Rule or Apex is updated to check the switch.
- In any org where the User bypass fields were already deployed, delete them. Deploy the updated User Layout and permission set first, then delete the fields. In Gearset, include the deleted fields in the comparison. Otherwise, delete them in **Object Manager → User → Fields & Relationships**. Any values stored in the fields are lost.
- Restrict the **Customize Application** permission to trusted admins, since it allows editing the custom setting.
- Update the Flows, Validation Rules and Apex that should obey the switch, as described above. Until then, it has no effect.

## Component Manifest

Github Branch: https://github.com/aaroncrear/BeaconImplementation/tree/On/Off-Switch

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | CustomObject | On_Off_Switch__c | On_Off_Switch__c | On/Off Switch | Created | Public hierarchy custom setting used to turn off Flows, Validation Rules and Apex in bulk, at the Org, Profile or User level. |
| 2 | CustomField | On_Off_Switch__c | Run_Flows__c | Run Flows | Created | Checkbox (default true). When checked, Flows that reference this setting run. |
| 3 | CustomField | On_Off_Switch__c | Run_Validation_Rules__c | Run Validation Rules | Created | Checkbox (default true). When checked, Validation Rules that reference this setting run. |
| 4 | CustomField | On_Off_Switch__c | Run_Apex__c | Run Apex | Created | Checkbox (default true). When checked, Apex that references this setting runs. |
| 5 | CustomField | User | Bypass_Val_Rules__c | Bypass Val Rules | Deleted | Checkbox added in PR #24 to bypass Validation Rules for one user. No longer needed. |
| 6 | CustomField | User | Bypass_Flows__c | Bypass Flows | Deleted | Checkbox added in PR #24 to bypass Flows for one user. No longer needed. |
| 7 | CustomField | User | Bypass_Apex__c | Bypass Apex | Deleted | Checkbox added in PR #24 to bypass Apex for one user. No longer needed. |
| 8 | Layout | User | User-User Layout | User Layout | Updated | Removed Bypass Val Rules, Bypass Flows and Bypass Apex from the Additional Information section. |
| 9 | PermissionSet | N/A | Beacon_Salesforce_Admin_Object_Tab_FLS | Beacon Salesforce Admin - Object, Tab, FLS | Updated | Removed the field permissions for User.Bypass_Val_Rules__c, User.Bypass_Flows__c and User.Bypass_Apex__c. |
