# "Flow-and-Val-Rule-On-Off-Switch-Updates" – Release Notes

## Requirements

The **On/Off Switch** custom setting (`On_Off_Switch__c`) lets admins turn Flows and Validation Rules off for the whole org, a profile or a single user. It only affects components that check it. Most of the custom Flows and Validation Rules built so far didn't check it, so the switch had little effect.

- Update every custom Flow and Validation Rule we built so that it obeys the switch.
- Leave out the **Fault Path Subflow**. It only runs when another Flow's fault path calls it, so the calling Flow is the one to switch off.
- Make no other change to how these components behave while the switch is on.

## Release Notes

### Record-triggered Flows

`{!$Setup.On_Off_Switch__c.Run_Flows__c}` was added to each Flow's entry conditions, using **Formula Evaluates to True**. When **Run Flows** is unchecked for the running user, the Flow does not start. This is the pattern documented in the `README.md` "On/Off Switch" section, and the one already used by **Opportunity - On Create - After Save**.

A record-triggered Flow's entry conditions can be either field filters or a formula, not both. Flows that used field filters were changed to an equivalent formula:

| Flow | Previous entry conditions | New entry formula |
|---|---|---|
| Account - On Update - After Save | Blacklisted, Blacklisted Reason, Do Not Call **or** Email Opt Out *Is Changed* | `AND(Run_Flows__c, OR(ISCHANGED(...) x4))` |
| Contact - On Create - Before Save | Title *Is Null* = false | `AND(Run_Flows__c, NOT(ISBLANK(Title)))` |
| Lead - On Create - Before Save | Title *Is Null* = false | `AND(Run_Flows__c, NOT(ISBLANK(Title)))` |
| Lead - On Create - After Save | None | `Run_Flows__c` |

Flows that already used a formula had it wrapped as `AND(Run_Flows__c, <existing formula>)`: **Campaign - On Create - Before Save**, **Contact - On Update - Before Save** and **Lead - On Update - Before Save**.

The "when to run" setting of each Flow is unchanged. Each Flow's description now ends with "Only runs when Run Flows is checked on the On/Off Switch custom setting."

### Validation Rules

Each rule's error condition was wrapped as:

```
$Setup.On_Off_Switch__c.Run_Validation_Rules__c && (
    <existing error condition>
)
```

When **Run Validation Rules** is unchecked for the running user, the rule never fires. The existing conditions and error messages are unchanged. Each rule's description now ends with "Honors the On/Off Switch (Run Validation Rules)."

Updated rules: the ten **Beacon Feedback** rules, plus **First Name Required** on Contact and on Lead.

### Related updates on other branches

Six components in scope exist only on branches that haven't been merged to `master` yet. They were updated on their own branches, so they deploy with the rest of that work rather than with this branch. Each branch's release notes were updated too.

| Branch | Component | Change |
|---|---|---|
| `Automations` | Flow `Opportunity_Contact_Role_On_Create_Afrer_Save` | Added `Run_Flows__c` as the entry formula. The branch has no release notes file to update. |
| `Test-Flow` | Flow `Opportunity_On_Create_Update_After_Save` | The IsWon and AccountId filters became `AND(Run_Flows__c, IsWon, NOT(ISBLANK(AccountId)))`. It still runs only when a record is updated to meet the criteria. |
| `Lead-Routing` | Flow `Lead_Routing_Engine` (autolaunched subflow) | A new first Decision, **Flows Enabled?**, ends the Flow with a blank owner and routing reason when Run Flows is unchecked. This matches the existing decision in CampaignMember - On Create - After Save. |
| `Beacon-Custom-PM-App` | Validation Rules `Project__c.Deadline_After_Kickoff`, `Project__c.Project_Type_Other_Required`, `Project_Time__c.Hours_Must_Be_Positive` | Wrapped in `Run_Validation_Rules__c && (...)`. |

### Not changed

- **Fault Path Subflow**, at your request.
- **Opportunity - On Create - After Save** and **Opportunity.Required_Fields_Demo_Booked**, which already check the switch.
- Components from installed packages (the `Milestone1_*` rules) and the Salesforce default `sfdc_default_ReportExport_Protection_Flow`.

## Acceptance Criteria

Run these in a sandbox where the **On/Off Switch** Org Default record exists with all boxes checked.

**With the switch on (no behavior change)**

1. Create a Lead with a Title (for example "VP Sales"). Confirm Seniority Level is set and, if the Email Domain and Country match an Account, the Account lookup is filled.
2. Create a Contact with a Title. Confirm Seniority Level is set.
3. Update a Lead's and a Contact's Title. Confirm Seniority Level updates. Check Blacklisted on one and confirm Status becomes Do Not Engage.
4. Create a Sub Campaign under a Parent Campaign that has a Primary Module. Confirm the Primary Module is copied.
5. On an Account with related Contacts, Leads and open Opportunities, change Do Not Call. Confirm the value is copied to the related records. Edit an unrelated Account field and confirm the related records aren't updated.
6. Try to save a Lead and a Contact without a First Name. Confirm the "First Name is required." error.
7. On a Beacon Feedback record, enter 6 in Quality Of Data and confirm the "Select a number between 1 and 5" error. On a Sales Demo survey, set Survey Completed to Yes with no Next Steps Date and confirm the error.

**With the switch off**

8. In **Setup → Custom Settings → On/Off Switch → Manage**, add a **User** level record for your user with **Run Flows** and **Run Validation Rules** unchecked.
9. Repeat steps 1–5. Confirm none of the Flows run: Seniority Level, Status, Account lookup and Primary Module stay blank or unchanged, and the Account's related records are not updated.
10. Repeat steps 6–7. Confirm the records save without errors.
11. Log in as (or ask) a second user with no User level record. Confirm that user still gets the Flow results and Validation Rule errors.
12. Delete your User level record and confirm the Flows and errors return for you.

## Post Deployment Items

- **Before deploying**, confirm the **On/Off Switch** Org Default record exists in the target org with **Run Flows** and **Run Validation Rules** checked. Create it in **Setup → Custom Settings → On/Off Switch → Manage**, using the **New** button in the **Default Organization Level Value** section. The field defaults don't create this record. Without it, Flows and Validation Rules read the switch as unchecked, and all 19 components stop running for everyone.
- Deploy the related branch updates (`Automations`, `Test-Flow`, `Lead-Routing`, `Beacon-Custom-PM-App`) as part of their own releases.

## Component Manifest

Github Branch: [Flow-and-Val-Rule-On-Off-Switch-Updates](https://github.com/aaroncrear/BeaconImplementation/tree/Flow-and-Val-Rule-On-Off-Switch-Updates)

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Flow | Account | Account_On_Update_After_Save | Account - On Update - After Save | Updated | Entry conditions changed from four Is Changed filters to an equivalent formula that also requires Run Flows. |
| 2 | Flow | Campaign | Campaign_On_Create_Before_Save | Campaign - On Create - Before Save | Updated | Entry formula now also requires Run Flows. |
| 3 | Flow | Contact | Contact_On_Create_Before_Save | Contact - On Create - Before Save | Updated | Title filter changed to a formula that also requires Run Flows. |
| 4 | Flow | Contact | Contact_On_Update_Before_Save | Contact - On Update - Before Save | Updated | Entry formula now also requires Run Flows. |
| 5 | Flow | Lead | Lead_On_Create_After_Save | Lead - On Create - After Save | Updated | Added an entry formula that requires Run Flows. |
| 6 | Flow | Lead | Lead_On_Create_Before_Save | Lead - On Create - Before Save | Updated | Title filter changed to a formula that also requires Run Flows. |
| 7 | Flow | Lead | Lead_On_Update_Before_Save | Lead - On Update - Before Save | Updated | Entry formula now also requires Run Flows. |
| 8 | Validation Rule | Contact | First_Name_Required | First Name Required | Updated | Only fires when Run Validation Rules is checked. |
| 9 | Validation Rule | Lead | First_Name_Required | First Name Required | Updated | Only fires when Run Validation Rules is checked. |
| 10 | Validation Rule | Beacon_Feedback__c | Any_Further_Feedback_Mandatory | Any Further Feedback Mandatory | Updated | Only fires when Run Validation Rules is checked. |
| 11 | Validation Rule | Beacon_Feedback__c | Data_Comprehensiveness | Data Comprehensiveness | Updated | Only fires when Run Validation Rules is checked. |
| 12 | Validation Rule | Beacon_Feedback__c | Monthly_Digest_Content | Monthly Digest Content | Updated | Only fires when Run Validation Rules is checked. |
| 13 | Validation Rule | Beacon_Feedback__c | Next_Steps_Date_Mandatory | Next Steps Date Mandatory | Updated | Only fires when Run Validation Rules is checked. |
| 14 | Validation Rule | Beacon_Feedback__c | Number_Of_Customers_On_Call | Number Of Customers On Call | Updated | Only fires when Run Validation Rules is checked. |
| 15 | Validation Rule | Beacon_Feedback__c | Overall_Demo_Rank | Overall Demo Rank | Updated | Only fires when Run Validation Rules is checked. |
| 16 | Validation Rule | Beacon_Feedback__c | Quality_Of_Data | Quality Of Data | Updated | Only fires when Run Validation Rules is checked. |
| 17 | Validation Rule | Beacon_Feedback__c | Speed_Of_Platform | Speed Of Platform | Updated | Only fires when Run Validation Rules is checked. |
| 18 | Validation Rule | Beacon_Feedback__c | Usability_Of_Platform | Usability Of Platform | Updated | Only fires when Run Validation Rules is checked. |
| 19 | Validation Rule | Beacon_Feedback__c | User_Friendly_Beacon | User Friendly Beacon | Updated | Only fires when Run Validation Rules is checked. |
