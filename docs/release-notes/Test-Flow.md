# "Test-Flow" – Release Notes

## Requirements

When an Opportunity is Closed Won, its Account should be marked as a customer automatically. Reps should not have to update the Account's **Type** field by hand.

## Release Notes

A new record-triggered flow, **Opportunity - On Create Update - After Save** (`Opportunity_On_Create_Update_After_Save`), sets **Type** = `Customer` on the Opportunity's Account when the Opportunity is Closed Won.

- **Trigger:** runs after save when an Opportunity is created or updated.
- **Entry criteria:** `IsWon = true` AND `AccountId` is not blank. The flow is set to run **only when a record is updated to meet the criteria**. It fires once, when the Opportunity becomes Closed Won (or is created as Closed Won). It does not fire again on later edits to an Opportunity that is already won.
- **Update:** one Update Records element updates the Account where `Id = $Record.AccountId` and `Type != Customer`. The `Type != Customer` filter skips the DML when the Account is already a Customer.
- **Fault handling:** the update's fault path calls the existing **Fault Path Subflow**, which emails an automation-failure notification. This matches the other record-triggered flows in the org.

`IsWon` is used instead of a specific Stage name, so the flow still works if the Closed Won stage is renamed or another won stage is added. An after-save flow is needed because the update is on a related record (the Account), not on the Opportunity itself. The picklist value `Customer` matches the value used by the Account `Engagement_Status__c` formula.

## Acceptance Criteria

1. Open an Account whose **Type** is not `Customer` (for example `Prospect` or blank). Create an open Opportunity on it, then change its Stage to **Closed Won** and save. Confirm the Account's **Type** is now `Customer`.
2. Create a new Opportunity with Stage **Closed Won** on an Account that is not a Customer. Confirm the Account's **Type** is now `Customer`.
3. Change an Opportunity to **Closed Lost** on an Account that is not a Customer. Confirm the Account's **Type** does not change.
4. Change an open Opportunity to a different open stage. Confirm the Account's **Type** does not change.
5. Close Won an Opportunity on an Account that is already `Customer`. Confirm the save succeeds and **Type** stays `Customer`.
6. On the Account from step 1, set its **Type** back to `Prospect`. Then edit a field on the won Opportunity, such as Description, and save. Confirm the Account's **Type** stays `Prospect`, because the flow only fires when the Opportunity first becomes won.
7. Confirm the Account's **Engagement Status** shows the Customer image after steps 1 and 2.

## Post Deployment Items

- Confirm the Account **Type** picklist in the target org has an active `Customer` value. If it does not, add it before activating the flow.
- Optional: to set existing Accounts that already have Closed Won Opportunities to `Customer`, run a one-time data update. The flow only fires on new changes.

## Component Manifest

Github Branch: [Test-Flow](https://github.com/aaroncrear/BeaconImplementation/tree/Test-Flow)

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Flow | Opportunity | Opportunity_On_Create_Update_After_Save | Opportunity - On Create Update - After Save | Created | Record-triggered after-save flow that sets Account Type to Customer when an Opportunity is created as, or updated to, Closed Won. |
