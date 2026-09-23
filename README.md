# BeaconImplementation
Beacon implementation project

## On/Off Switch

The **On/Off Switch** is a hierarchy custom setting that lets an admin turn Flows, Validation Rules and Apex off in bulk. For example, you can switch them off for a data load or migration without deactivating each component one at a time.

### What's included

| Component | Type | Purpose |
| --- | --- | --- |
| `On_Off_Switch__c` | Hierarchy custom setting | Holds the switches. |
| `Run_Flows__c` | Checkbox (default `true`) | When checked, Flows that reference the setting run. |
| `Run_Validation_Rules__c` | Checkbox (default `true`) | When checked, Validation Rules that reference the setting run. |
| `Run_Apex__c` | Checkbox (default `true`) | When checked, Apex that references the setting runs. |

Because it is a hierarchy setting, you can set values at three levels. Salesforce uses the most specific one:

1. **User**: for example, turn everything off for an integration or data-migration user only.
2. **Profile**: for example, turn Validation Rules off for a system-admin profile.
3. **Org Default**: applies to everyone else.

### Important: the switch is opt-in

The switch only affects components that check it. A Flow, Validation Rule or Apex class that does not reference `On_Off_Switch__c` keeps running no matter what the switch is set to. Any new automation must include the check to be covered.

The switch does not affect Workflow Rules, Process Builder, duplicate rules, required fields, lookup filters or managed-package components.

### Setup

1. Deploy `unpackaged/main/default/objects/On_Off_Switch__c` to your org, using Gearset or `sf project deploy start`.
2. Go to **Setup → Custom Settings → On/Off Switch → Manage**, and create the **Org Default** record with all three checkboxes **checked**. The field defaults do not create this record for you. Create it before you add the checks below.
3. Limit who can change the setting. Anyone with the **Customize Application** permission can edit it.

### Wiring it up

#### Validation Rules

Wrap each rule's existing condition:

```
$Setup.On_Off_Switch__c.Run_Validation_Rules__c && (
    /* existing error condition */
)
```

#### Record-triggered Flows

Add this to the Flow's entry conditions using **Formula Evaluates to True**:

```
{!$Setup.On_Off_Switch__c.Run_Flows__c}
```

For other Flow types, add a Decision as the first element that ends the Flow when `{!$Setup.On_Off_Switch__c.Run_Flows__c}` is false.

#### Apex triggers

Return early at the top of the trigger or trigger handler:

```apex
if (!On_Off_Switch__c.getInstance().Run_Apex__c) {
    return;
}
```

### Turning automation off

1. Open **Setup → Custom Settings → On/Off Switch → Manage**.
2. Edit the Org Default, or add or edit a Profile or User record, and uncheck the switches you need.
3. Run your load or change.
4. Check the switches again. Automation that was off does **not** run again on records changed in the meantime.
