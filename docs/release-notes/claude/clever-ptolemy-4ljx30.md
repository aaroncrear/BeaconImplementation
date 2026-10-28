# "claude/clever-ptolemy-4ljx30" – Release Notes

## Requirements

- Create an Opportunity Validation Rule named **Required Fields - Demo Booked**.
- When an Opportunity's Stage is moved to **Demo Booked**, the following fields must be populated:
  - Primary Campaign Source
  - Type
  - Primary Module
  - Lead Source
  - Lead Type

## Release Notes

### Required Fields - Demo Booked validation rule

A new Opportunity Validation Rule, `Required_Fields_Demo_Booked`, was added. Salesforce rule names can only contain letters, numbers and underscores, so the requested name **Required Fields - Demo Booked** is stored as `Required_Fields_Demo_Booked`.

The rule blocks the save when the Stage is **Demo Booked** and any of these fields is blank:

| Field Label | API Name | Type |
|-------------|----------|------|
| Primary Campaign Source | `CampaignId` | Lookup (Campaign) |
| Type | `Type` | Picklist |
| Primary Module | `Primary_Module__c` | Picklist |
| Lead Source | `LeadSource` | Picklist |
| Lead Type | `Lead_Type__c` | Picklist |

Error message (shown at the top of the page, because several fields can be missing at once):

> Before moving the Opportunity to Demo Booked, please complete the following fields: Primary Campaign Source, Type, Primary Module, Lead Source and Lead Type.

Formula:

```
$Setup.On_Off_Switch__c.Run_Validation_Rules__c && (
    ISPICKVAL(StageName, "Demo Booked") &&
    (
        ISBLANK(CampaignId) ||
        ISBLANK(TEXT(Type)) ||
        ISBLANK(TEXT(Primary_Module__c)) ||
        ISBLANK(TEXT(LeadSource)) ||
        ISBLANK(TEXT(Lead_Type__c))
    )
)
```

Design decisions:

- **The rule checks the current Stage, not only the change of Stage.** It fires on every save while the Opportunity is at Demo Booked, not only on the save that moves it there. Otherwise a user could move the Opportunity to Demo Booked and then clear a required field in a later edit. Opportunities created directly at Demo Booked are also covered.
- **Later stages are not covered.** Once the Opportunity moves past Demo Booked, the rule no longer applies, as requested.
- **Picklists are wrapped in `TEXT()`.** `ISBLANK` does not work directly on picklist fields, so each picklist is converted to text first.
- **The rule honors the On/Off Switch.** The condition is wrapped in `$Setup.On_Off_Switch__c.Run_Validation_Rules__c`, as the `README.md` "On/Off Switch" section describes, so admins can turn it off for data loads or for an integration user.
- **The rule applies to all record types.** Demo Booked is currently only in the **Subscription New** sales process, so in practice only Subscription New Opportunities reach it. If Demo Booked is added to another sales process later, the rule will apply there too.

## Acceptance Criteria

1. In **Setup → Object Manager → Opportunity → Validation Rules**, confirm **Required_Fields_Demo_Booked** exists and is **Active**.
2. Open a **Subscription New** Opportunity at a stage before Demo Booked, with **Primary Campaign Source**, **Type**, **Primary Module**, **Lead Source** and **Lead Type** all blank.
3. Change the Stage to **Demo Booked** and save. Confirm the save is blocked and the error message above appears at the top of the page.
4. Populate four of the five fields, leaving **Primary Campaign Source** blank, and save. Confirm the error still appears.
5. Repeat step 4 once for each of the other fields (**Type**, **Primary Module**, **Lead Source**, **Lead Type**), leaving only that field blank each time. Confirm the error appears every time.
6. Populate all five fields and save. Confirm the Opportunity saves at **Demo Booked**.
7. With the Opportunity still at Demo Booked, clear **Lead Type** and save. Confirm the error appears.
8. Restore **Lead Type**, move the Opportunity to **Demo Completed**, then clear **Lead Type** and save. Confirm it saves, since the rule only applies at Demo Booked.
9. Create a new Subscription New Opportunity with the Stage set to **Demo Booked** and one of the five fields blank. Confirm the save is blocked.
10. Edit an Opportunity at a stage before Demo Booked with all five fields blank (for example, change the Name). Confirm it saves.
11. On/Off Switch check: in **Setup → Custom Settings → On/Off Switch → Manage**, add a **User** level record for your user with **Run Validation Rules** unchecked. Repeat step 3 and confirm the Opportunity saves at Demo Booked. Delete the User level record afterwards and confirm the error returns.

## Post Deployment Items

- Confirm the **On/Off Switch** Org Default record exists with **Run Validation Rules** checked (**Setup → Custom Settings → On/Off Switch → Manage**). If it does not exist, the rule will not fire for anyone.
- Opportunities already at Demo Booked with any of the five fields blank will be blocked on their next edit until the fields are filled in. Before or right after deployment, run a report on Opportunities at Demo Booked where any of the five fields is blank, and backfill them or tell the owners.
- Let Sales users know about the new requirement.

## Component Manifest

Github Branch: https://github.com/aaroncrear/BeaconImplementation/tree/claude/clever-ptolemy-4ljx30

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | ValidationRule | Opportunity | Opportunity.Required_Fields_Demo_Booked | Required Fields - Demo Booked | Created | Requires Primary Campaign Source, Type, Primary Module, Lead Source and Lead Type when the Stage is Demo Booked. Honors the On/Off Switch (Run Validation Rules). |
