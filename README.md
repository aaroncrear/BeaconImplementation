# BeaconImplementation
Beacon implementation project

## On/Off Switch and User Bypass Fields

Metadata for turning Flows, Validation Rules and Apex off without deactivating each component one at a time. For example, you can switch them off for a data load or migration. There are two ways to do it, and automation can check both:

- **On/Off Switch**: a hierarchy custom setting that turns automation off for the whole org, a profile or a user.
- **User bypass fields**: three checkboxes on the User record that turn automation off for that user.

### What's included

#### On/Off Switch custom setting

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

#### User bypass fields

| Field | Label | Type | Purpose |
| --- | --- | --- | --- |
| `User.Bypass_Val_Rules__c` | Bypass Val Rules | Checkbox (default `false`) | When checked, Validation Rules that reference the field do not fire for this user. |
| `User.Bypass_Flows__c` | Bypass Flows | Checkbox (default `false`) | When checked, Flows that reference the field do not run for this user. |
| `User.Bypass_Apex__c` | Bypass Apex | Checkbox (default `false`) | When checked, Apex that references the field does not run for this user. |

Note that these fields work the opposite way to the custom setting: **checked means bypass**, so automation runs for everyone by default.

#### Which one to use

| | On/Off Switch | User bypass fields |
| --- | --- | --- |
| Scope | Whole org, a profile or a user | One user |
| Where you set it | Setup → Custom Settings | The User record |
| Typical use | Turning everything off during a release or a large migration | Permanently exempting an integration user, or a one-off data load by one user |
| Visible in reports and list views | No | Yes |

The wiring below checks both, so either one can turn a component off.

### Important: both are opt-in

The switch and the bypass fields only affect components that check them. A Flow, Validation Rule or Apex class that does not reference them keeps running whatever they are set to. Any new automation must include the check to be covered.

They do not affect Workflow Rules, Process Builder, duplicate rules, required fields, lookup filters or managed-package components.

### Setup

1. Deploy `unpackaged/main/default/objects/On_Off_Switch__c` and the three `User` bypass fields to your org, using Gearset or `sf project deploy start`.
2. Go to **Setup → Custom Settings → On/Off Switch → Manage**, and create the **Org Default** record with all three checkboxes **checked**. The field defaults do not create this record for you. Create it before you add the checks below.
3. Give admins **Edit** access to the three User bypass fields through field-level security or a permission set, and add them to the User page layout if you want to set them there. Keep other users at read-only or no access, so users can't bypass automation for themselves.
4. Limit who can change the custom setting. Anyone with the **Customize Application** permission can edit it.

### Wiring it up

#### Validation Rules

Wrap each rule's existing condition:

```
$Setup.On_Off_Switch__c.Run_Validation_Rules__c &&
NOT($User.Bypass_Val_Rules__c) && (
    /* existing error condition */
)
```

#### Record-triggered Flows

Add this to the Flow's entry conditions using **Formula Evaluates to True**:

```
{!$Setup.On_Off_Switch__c.Run_Flows__c} && NOT({!$User.Bypass_Flows__c})
```

For other Flow types, add a Decision as the first element that ends the Flow when that formula is false.

#### Apex triggers

Return early at the top of the trigger or trigger handler. The User field needs a query, so put the check in a shared class that caches the result and call it from each trigger:

```apex
public class AutomationBypass {
    private static Boolean cachedSkipApex;

    public static Boolean skipApex() {
        if (cachedSkipApex == null) {
            cachedSkipApex = !On_Off_Switch__c.getInstance().Run_Apex__c
                || [SELECT Bypass_Apex__c FROM User WHERE Id = :UserInfo.getUserId()].Bypass_Apex__c;
        }
        return cachedSkipApex;
    }
}
```

```apex
if (AutomationBypass.skipApex()) {
    return;
}
```

### Turning automation off

#### For the org, a profile or a user, with the On/Off Switch

1. Open **Setup → Custom Settings → On/Off Switch → Manage**.
2. Edit the Org Default, or add or edit a Profile or User record, and uncheck the switches you need.
3. Run your load or change.
4. Check the switches again.

#### For one user, with the bypass fields

1. Open the user's record in **Setup → Users** and click **Edit**.
2. Check **Bypass Val Rules**, **Bypass Flows** and/or **Bypass Apex**, and save.
3. Run the load or change as that user.
4. Uncheck the fields again, unless the user should always bypass automation, for example an integration user.

Automation that was off does **not** run again on records changed in the meantime.
