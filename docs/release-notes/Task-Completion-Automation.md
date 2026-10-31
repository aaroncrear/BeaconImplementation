# "Task-Completion-Automation" – Release Notes

## Requirements

When a rep completes an activity with a Lead or Contact, the Lead or Contact should move out of `New` and into `Working`. The business need was:

- When a Task is **created** with a Status of `Completed` and is related to a Lead or Contact, set the Lead `Status` or the Contact `Contact Status` to `Working`.
- Only change the status when its current value is `New`. Leads and Contacts in any other status are left alone.
- Only do this when the Task Subtype is **not** `Task` (for example Calls, Emails and other logged activities count; plain to-do Tasks do not).
- Build this in a new `Task - On Create - After Save` flow.
- Build a new `Task - On Update - After Save` flow that does the same when a Task is updated.

## Release Notes

Two new record-triggered flows were added on Task. No fields or picklist values were added: `Working` and `New` already exist on both Lead `Status` and Contact `Contact Status` (`Contact_Status__c`).

**After-save** was used because the flows update other records (the related Lead or Contact). Before-save flows can only change the record being saved.

### Task - On Create - After Save (`Task_On_Create_After_Save`)

- **Entry criteria (formula):**
  ```
  AND(
      {!$Setup.On_Off_Switch__c.Run_Flows__c},
      ISPICKVAL({!$Record.Status}, "Completed"),
      NOT(ISPICKVAL({!$Record.TaskSubtype}, "Task")),
      NOT(ISBLANK({!$Record.WhoId}))
  )
  ```
  Tasks that are not Completed, have a Task Subtype of `Task`, or have no Name (Lead/Contact) don't start the flow.
- **Decision `Related To Lead Or Contact?`:** checks the Task's Name (`WhoId`). Ids that start with `00Q` are Leads, and ids that start with `003` are Contacts.
- **`Update Lead Status To Working`:** updates the Lead where `Id = WhoId`, `Status = New` and `IsConverted = false`, setting `Status` to `Working`.
- **`Update Contact Status To Working`:** updates the Contact where `Id = WhoId` and `Contact Status = New`, setting `Contact Status` to `Working`.
- The "previous value was New" check is done with filters on the Update Records elements, not a separate Get Records. A Lead or Contact that is not `New` doesn't match the filter, so it isn't updated and no extra query is used.
- Converted Leads are filtered out, since Salesforce does not allow converted Leads to be updated.
- Both updates send faults to the `Fault Path Subflow`, the same as the other flows in the org.

### Task - On Update - After Save (`Task_On_Update_After_Save`)

Same elements and logic as the create flow. The entry formula adds one more condition so the flow only runs when something relevant changed:

```
AND(
    {!$Setup.On_Off_Switch__c.Run_Flows__c},
    ISPICKVAL({!$Record.Status}, "Completed"),
    NOT(ISPICKVAL({!$Record.TaskSubtype}, "Task")),
    NOT(ISBLANK({!$Record.WhoId})),
    OR(
        ISCHANGED({!$Record.Status}),
        ISCHANGED({!$Record.WhoId})
    )
)
```

- The flow runs when a Task is changed **to** `Completed`, or when a Task that is already `Completed` is moved to a different Lead or Contact.
- Editing other fields (Subject, Comments, etc.) on a Task that is already Completed does not start the flow.

### Notes

- **Task Subtype:** a Task with a blank Task Subtype is treated as "not equal to Task" and will update the Lead or Contact. Salesforce normally sets Task Subtype on every Task (`Task`, `Call`, `Email`, `List Email`, `Cadence`, `LinkedIn`), so this should be rare.
- **Shared Activities:** if a Task is related to more than one Contact, only the primary Contact (the Task's `WhoId`) is updated.
- **Related To (`WhatId`) is not used.** A Task logged on an Account or Opportunity with no Name (Lead/Contact) does not update anything.
- Updating the Lead or Contact starts the existing `Lead - On Update - Before Save` and `Contact - On Update - Before Save` flows. Neither of them changes Status based on a Status change, so they don't conflict.
- **On/Off Switch:** both flows check `{!$Setup.On_Off_Switch__c.Run_Flows__c}` in their entry formula, the same as the other flows in the org.

## Acceptance Criteria

Use a test Lead and a test Contact. Before each test, set the Lead `Status` or the Contact `Contact Status` as described.

1. **Create – Completed Call on a New Lead:** Set a Lead's Status to `New`. From the Lead, use **Log a Call** (Task Subtype `Call`, Status `Completed`). Confirm the Lead's Status is now `Working`.
2. **Create – Completed Call on a New Contact:** Set a Contact's Contact Status to `New`. Log a Call on the Contact. Confirm the Contact Status is now `Working`.
3. **Create – Email:** Set a Lead to `New`. Send an email to the Lead from Salesforce (or log an email) so a Completed Task with Task Subtype `Email` is created. Confirm the Lead's Status is `Working`. Repeat for a Contact.
4. **Create – Task Subtype is Task:** Set a Lead to `New`. Use **New Task** on the Lead and save it with Status `Completed`. Confirm the Lead's Status stays `New`. Repeat for a Contact.
5. **Create – Not Completed:** Set a Contact to `New`. Create a Task with Task Subtype `Call` and Status `Open` through Data Loader. Confirm the Contact Status stays `New`.
6. **Create – Previous value not New:** Set a Lead's Status to `Nurturing`. Log a Call on the Lead. Confirm the Status stays `Nurturing`. Set a Contact's Contact Status to `Unqualified`, log a Call and confirm it stays `Unqualified`.
7. **Create – Already Working:** Log a Call on a Lead whose Status is `Working`. Confirm no error and the Status stays `Working`.
8. **Create – No Name:** Log a Call on an Account with no Contact selected in Name. Confirm no error and no Lead or Contact changes.
9. **Update – Changed to Completed:** Set a Contact to `New`. Using Data Loader or inline edit, create a Task on the Contact with Task Subtype `Call` and Status `Open`. Confirm the Contact Status stays `New`. Change the Task's Status to `Completed`. Confirm the Contact Status is now `Working`. Repeat for a Lead.
10. **Update – Task Subtype is Task:** Create an open Task with **New Task** on a `New` Lead. Change its Status to `Completed`. Confirm the Lead's Status stays `New`.
11. **Update – Name changed on a Completed Task:** Log a Call on Contact A. Set Contact B's Contact Status to `New`. Edit the Call and change Name from Contact A to Contact B. Confirm Contact B's Contact Status is now `Working`.
12. **Update – other field edits:** Set a Contact to `New` with an existing Completed Call already on it. Edit only the Call's Subject. Confirm the Contact Status stays `New`.
13. **Converted Lead:** Convert a Lead, then log a Call on the converted Lead's new Contact while its Contact Status is `New`. Confirm the Contact Status is `Working` and no fault email is sent.
14. **Bulk:** With Data Loader, insert 200 Completed Tasks with Task Subtype `Call` against 200 Leads and Contacts in `New`. Confirm they all move to `Working` and no fault emails are sent.
15. **On/Off Switch:** Create a User level On/Off Switch record for your user with `Run Flows` unchecked. Log a Call on a `New` Lead and confirm the Status stays `New`. Delete the User level record afterwards.

## Post Deployment Items

- Confirm both flows are **Active** in the target org after deployment.
- **Optional backfill:** the flows only run when a Task is created or updated. Leads and Contacts that are still `New` but already have Completed, non-`Task` subtype activities are not updated. If the business wants them fixed, export Completed Tasks where `TaskSubtype != 'Task'` and `WhoId` is not blank, match them to Leads with `Status = 'New'` (and `IsConverted = false`) and Contacts with `Contact_Status__c = 'New'`, set the status to `Working` and update with Data Loader. Confirm with the business before running it.

## Component Manifest

Github Branch: [Task-Completion-Automation](https://github.com/aaroncrear/BeaconImplementation/tree/Task-Completion-Automation)

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Flow | Task | Task_On_Create_After_Save | Task - On Create - After Save | Created | When a Completed Task with a Task Subtype other than Task is created on a Lead or Contact, sets the Lead Status or Contact Status from New to Working. |
| 2 | Flow | Task | Task_On_Update_After_Save | Task - On Update - After Save | Created | When a Task with a Task Subtype other than Task is changed to Completed (or a Completed Task's Name changes), sets the related Lead Status or Contact Status from New to Working. |
