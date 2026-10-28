# "Email-Subflow" – Release Notes

## Requirements

Email notifications are hard to find when each one lives inside one of dozens of record-triggered Flows. The business needs one central place to find, create, update or remove email notifications.

Parts that all emails use, such as the record link formula, need to live in one place. When one needs a change, it should only be updated once.

This branch builds the framework only. It doesn't send any emails yet. Later branches will add each email notification to this Subflow.

## Release Notes

### Email Subflow

A new autolaunched Flow, **Email Subflow** (`Email_Subflow`), is the one place every Beacon email notification is sent from. Record-triggered Flows call it as a Subflow, and its decision tree picks which email to send.

**Input variables** (all Text, available for input):

| Variable | Description |
|----------|-------------|
| `varObject` | The Object that triggered the Subflow, e.g. `Account`. |
| `varTrigger` | The name of the specific trigger in the record-triggered Flow, e.g. the event that should send the email. |
| `varRecordID` | The Id of the record that triggered the Subflow. |

**Decision tree:**

1. **Which Object?** (`Which_Object`) checks `varObject` and sends the Flow to that Object's trigger decision. It has outcomes for **Account**, **Contact**, **Lead**, **Opportunity** and **Case**.
2. Each Object has its own trigger decision, for example **Which Account Trigger?** (`Which_Account_Trigger`). It checks `varTrigger` to choose the email to send.
3. Each trigger decision has one **Placeholder** outcome for now (e.g. `Account_Placeholder`, which matches `varTrigger = "Placeholder"`). None of these outcomes connect to anything yet. Later branches will replace them with real triggers and Send Email actions.

If `varObject` or `varTrigger` doesn't match an outcome, the Flow takes the **Default Outcome** and ends without sending anything.

**Shared record link:** the **formRecordLink** formula builds a clickable link to the record from the org's base URL and `varRecordID`:

```
LEFT({!$Api.Partner_Server_URL_630}, FIND('/services', {!$Api.Partner_Server_URL_630})) + {!varRecordID}
```

Every email body can use this formula. If the link format needs to change, it only needs to be updated here.

**Why a Subflow:** keeping emails in one Subflow, rather than in each record-triggered Flow, makes them easy to find and audit. Shared parts like the record link are kept in one place. Passing the Object and Trigger as text keeps the Subflow simple, and any Flow on any Object can call it.

**Status:** the Flow was committed as a **Draft**. It can't send anything until real email paths are added, so it doesn't need to be active yet.

### Adding a new email in a later branch

1. In the record-triggered Flow, add a **Subflow** element that calls **Email Subflow**. Set `varObject` to the Object's API name, `varTrigger` to a short name for the event (e.g. `New_Lead_Assigned`), and `varRecordID` to `{!$Record.Id}`.
2. In **Email Subflow**, add an outcome for that `varTrigger` value to the Object's trigger decision. If the Object is new, first add an outcome for it to **Which Object?** and give it its own trigger decision.
3. Add a **Send Email** action (or a Get Records step first, if the email needs record fields) on the new outcome. Use **formRecordLink** for the link to the record.
4. Remove the Object's **Placeholder** outcome once it has a real outcome.
5. Activate **Email Subflow** and list the change in that branch's release notes.

## Acceptance Criteria

1. In **Setup → Flows**, confirm **Email Subflow** is present, with type **Autolaunched Flow (No Trigger)**.
2. Open the Flow in Flow Builder. Confirm it has:
   1. The input variables `varObject`, `varTrigger` and `varRecordID`, all Text and **Available for input**.
   2. The **Which Object?** decision with outcomes for Account, Contact, Lead, Opportunity and Case. Each outcome connects to that Object's trigger decision.
   3. The **formRecordLink** formula.
3. **Object routing:**
   1. Click **Debug**. Set `varObject` to `Account`, `varTrigger` to `Placeholder`, and `varRecordID` to the Id of any Account. Click **Run**.
   2. Confirm the debug log shows **Which Object?** taking the **Account** outcome, then **Which Account Trigger?** taking the **Account Placeholder** outcome.
   3. Repeat with `varObject` set to `Contact`, `Lead`, `Opportunity` and `Case`. Confirm each run reaches that Object's trigger decision and Placeholder outcome.
4. **No match:**
   1. Debug with `varObject` set to `Quote`. Confirm **Which Object?** takes the **Default Outcome** and the Flow ends without error.
   2. Debug with `varObject` set to `Account` and `varTrigger` set to `Test`. Confirm **Which Account Trigger?** takes the **Default Outcome** and the Flow ends without error.
5. **Record link:**
   1. In a debug run with `varRecordID` set to an Account Id, check the value of **formRecordLink** in the debug details. Confirm it reads like `https://<your domain>.my.salesforce.com/<Account Id>`.
   2. Open the link in a browser. Confirm it opens the Account.
6. Confirm no emails were sent during any of the debug runs.

## Post Deployment Items

None. The Flow deploys as a Draft and doesn't send emails yet. Activate it in the first branch that adds a real email path.

## Component Manifest

Github Branch: https://github.com/aaroncrear/BeaconImplementation/tree/Email-Subflow

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Flow | N/A | Email_Subflow | Email Subflow | Created | Autolaunched Subflow that is the central place for all email notifications. Takes text inputs for Object, Trigger and Record Id and uses a decision tree to pick the email to send. Includes the shared formRecordLink formula. Framework only: each Object has a Placeholder outcome and no emails are sent yet. |
