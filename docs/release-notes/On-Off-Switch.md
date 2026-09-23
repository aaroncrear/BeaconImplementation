# "On/Off-Switch" – Release Notes

## Requirements

Admins need a way to turn Flows, Validation Rules and Apex off in bulk, for example during a data load or migration, without deactivating each component one at a time and then reactivating it.

- Provide one place to switch Flows, Validation Rules and Apex on or off.
- Allow the switch to be set for the whole org, for a profile, or for a single user, so that a data-migration or integration user can skip automation while everyone else is unaffected.
- Provide a checkbox on the User record for each of Validation Rules, Flows and Apex, so an admin can exempt a specific user directly from that user's record.
- Show the User bypass fields on the User Layout, and allow only Beacon Salesforce Admins to edit them.
- Leave all automation running by default.

## Release Notes

### On/Off Switch custom setting

A new **hierarchy custom setting**, **On/Off Switch** (`On_Off_Switch__c`), was added with three checkboxes, each defaulting to `true`:

- **`Run_Flows__c`** (Run Flows): when checked, Flows that reference the setting run.
- **`Run_Validation_Rules__c`** (Run Validation Rules): when checked, Validation Rules that reference the setting run.
- **`Run_Apex__c`** (Run Apex): when checked, Apex that references the setting runs.

A hierarchy custom setting was chosen because Salesforce resolves its value at the most specific level set (User, then Profile, then Org Default). Automation can be turned off for one user without affecting anyone else. Flows and Validation Rules can read it through the `$Setup` global variable, and Apex can read it through `On_Off_Switch__c.getInstance()`, with no SOQL query.

The setting's visibility is **Public**, so Flows and Validation Rules can read it for every user without extra permissions.

### User bypass fields

Three checkbox fields were added to the **User** object, each defaulting to `false`:

- **`User.Bypass_Val_Rules__c`** (Bypass Val Rules): when checked, Validation Rules that reference the field do not fire for this user.
- **`User.Bypass_Flows__c`** (Bypass Flows): when checked, Flows that reference the field do not run for this user.
- **`User.Bypass_Apex__c`** (Bypass Apex): when checked, Apex that references the field does not run for this user.

Each field's description explains how to reference it and gives the integration or data-migration user as the typical use.

The three fields were added to the **Additional Information** section of the **User Layout**, so admins can set them from the user's record. They are the first custom fields on that layout. Salesforce fixes the standard User fields on the detail page, so the layout's other sections are unchanged.

Read and edit access to the three fields was granted only in the **Beacon Salesforce Admin - Object, Tab, FLS** permission set (`Beacon_Salesforce_Admin_Object_Tab_FLS`). No other permission set or profile in this repo grants access, so other users can't see the fields or check them to bypass automation for themselves.

The User fields work the opposite way to the custom setting: **checked means bypass**. Every existing and new user therefore starts with automation running, with no data backfill. Unlike the custom setting, the fields sit on the User record, so admins can set them from the user's page and see them in reports and list views. Use the custom setting to turn automation off across the org or a profile, and the User fields to exempt individual users, such as an integration user, on a lasting basis.

### How automation checks the switch and fields

**Both are opt-in.** This build adds the setting and fields only. No existing Flow, Validation Rule or Apex checks them yet, so deploying them changes no behavior. Each component must be updated to check them before they affect it. They do not affect Workflow Rules, Process Builder, Duplicate Rules, required fields, lookup filters or managed-package components.

The `README.md` "On/Off Switch and User Bypass Fields" section documents the checks to add. Each check reads both the switch and the User field, so either one can turn a component off:

- **Validation Rules:** `$Setup.On_Off_Switch__c.Run_Validation_Rules__c && NOT($User.Bypass_Val_Rules__c) && ( <existing condition> )`
- **Record-triggered Flows:** add `{!$Setup.On_Off_Switch__c.Run_Flows__c} && NOT({!$User.Bypass_Flows__c})` to the entry conditions using **Formula Evaluates to True**. For other Flow types, add a Decision as the first element that ends the Flow when it is false.
- **Apex triggers:** call a shared `AutomationBypass.skipApex()` method at the top of each trigger or handler and return when it is true. The method checks `Run_Apex__c` and queries `Bypass_Apex__c` for the running user once per transaction, then caches the result.

## Acceptance Criteria

1. In **Setup → Custom Settings**, confirm **On/Off Switch** (`On_Off_Switch__c`) exists with Setting Type **Hierarchy** and Visibility **Public**.
2. Open the setting and confirm the fields **Run Flows** (`Run_Flows__c`), **Run Validation Rules** (`Run_Validation_Rules__c`) and **Run Apex** (`Run_Apex__c`) exist as Checkbox fields that default to checked.
3. Click **Manage**, create the **Org Default** record, and confirm all three checkboxes are checked by default. Save it.
4. In **Object Manager → User → Fields & Relationships**, confirm **Bypass Val Rules** (`Bypass_Val_Rules__c`), **Bypass Flows** (`Bypass_Flows__c`) and **Bypass Apex** (`Bypass_Apex__c`) exist as Checkbox fields that default to unchecked, each with a description of how to use it.
5. Open any existing user's record and confirm all three bypass fields are unchecked.
6. As a user with the **Beacon Salesforce Admin - Object, Tab, FLS** permission set, open a user's record and confirm **Bypass Val Rules**, **Bypass Flows** and **Bypass Apex** appear in the **Additional Information** section. Edit the record and confirm the fields can be checked and saved. Uncheck them again.
7. In **Setup → Permission Sets → Beacon Salesforce Admin - Object, Tab, FLS → Object Settings → Users**, confirm all three bypass fields have **Read** and **Edit** access.
8. As a user without that permission set and without System Administrator permissions, open a user's record and confirm the three bypass fields are not shown and can't be edited.
9. To confirm a Validation Rule honors the switch and the User field, create a test Validation Rule in a sandbox with the formula `$Setup.On_Off_Switch__c.Run_Validation_Rules__c && NOT($User.Bypass_Val_Rules__c) && ISBLANK(Description)` on an object of your choice.
   1. Save a record with a blank Description and confirm the error appears.
   2. Add a **User** level On/Off Switch record for your user with **Run Validation Rules** unchecked. Save the same record again and confirm it saves without the error.
   3. Delete the User level record, save again, and confirm the error returns.
   4. Check **Bypass Val Rules** on your User record. Save the same record again and confirm it saves without the error.
   5. Uncheck **Bypass Val Rules**, save again, and confirm the error returns.
10. To confirm a record-triggered Flow honors the switch and the User field, add `{!$Setup.On_Off_Switch__c.Run_Flows__c} && NOT({!$User.Bypass_Flows__c})` (Formula Evaluates to True) to a test Flow's entry conditions in a sandbox.
    1. Confirm the Flow runs when the switch is checked and **Bypass Flows** is unchecked.
    2. Uncheck **Run Flows** at your User level and confirm the Flow does not run. Then check it again.
    3. Check **Bypass Flows** on your User record and confirm the Flow does not run. Then uncheck it again.
11. Confirm both only affect the intended user: with the Org Default all checked, and one user's User level On/Off Switch record or bypass fields set to bypass, confirm a second user still gets the Validation Rule error and the Flow still runs.
12. Remove the test Validation Rule and Flow after testing.

## Post Deployment Items

- In **Setup → Custom Settings → On/Off Switch → Manage**, create the **Org Default** record with **Run Flows**, **Run Validation Rules** and **Run Apex** all **checked**. The field defaults do not create this record. Create it before any Flow, Validation Rule or Apex is updated to check the switch.
- Confirm the admins who should set the bypass fields are assigned the **Beacon Salesforce Admin - Object, Tab, FLS** permission set.
- Restrict the **Customize Application** permission to trusted admins, since it allows editing the custom setting.
- Update the Flows, Validation Rules and Apex that should obey the switch and the bypass fields, as described above. Until then, they have no effect.

## Component Manifest

Github Branch: https://github.com/aaroncrear/BeaconImplementation/tree/On/Off-Switch

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | CustomObject | On_Off_Switch__c | On_Off_Switch__c | On/Off Switch | Created | Public hierarchy custom setting used to turn off Flows, Validation Rules and Apex in bulk, at the Org, Profile or User level. |
| 2 | CustomField | On_Off_Switch__c | Run_Flows__c | Run Flows | Created | Checkbox (default true). When checked, Flows that reference this setting run. |
| 3 | CustomField | On_Off_Switch__c | Run_Validation_Rules__c | Run Validation Rules | Created | Checkbox (default true). When checked, Validation Rules that reference this setting run. |
| 4 | CustomField | On_Off_Switch__c | Run_Apex__c | Run Apex | Created | Checkbox (default true). When checked, Apex that references this setting runs. |
| 5 | CustomField | User | Bypass_Val_Rules__c | Bypass Val Rules | Created | Checkbox (default false). When checked, Validation Rules that include NOT($User.Bypass_Val_Rules__c) do not fire for this user. |
| 6 | CustomField | User | Bypass_Flows__c | Bypass Flows | Created | Checkbox (default false). When checked, Flows that check NOT({!$User.Bypass_Flows__c}) in their entry conditions or a starting Decision do not run for this user. |
| 7 | CustomField | User | Bypass_Apex__c | Bypass Apex | Created | Checkbox (default false). When checked, Apex that queries this field for the running user returns early. |
| 8 | Layout | User | User-User Layout | User Layout | Updated | Added Bypass Val Rules, Bypass Flows and Bypass Apex to the Additional Information section as editable fields. |
| 9 | PermissionSet | N/A | Beacon_Salesforce_Admin_Object_Tab_FLS | Beacon Salesforce Admin - Object, Tab, FLS | Updated | Granted Read and Edit access to User.Bypass_Val_Rules__c, User.Bypass_Flows__c and User.Bypass_Apex__c. |
