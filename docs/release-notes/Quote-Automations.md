# "Quote-Automations" – Release Notes

## Requirements

When a Quote is created, it should automatically become the primary Quote and sync to its Opportunity, so users don't have to click **Start Sync** by hand.

When a synced Quote's Status is changed to **Accepted**, its Opportunity's Stage should move to **Contract**.

## Release Notes

### Quote - On Create - After Save Flow

A new record-triggered Flow, **Quote - On Create - After Save** (`Quote_On_Create_After_Save`), runs when a Quote is created. It updates the Quote's parent Opportunity and sets its **Synced Quote** field (`SyncedQuoteId`) to the new Quote. This makes the new Quote the Opportunity's synced (primary) Quote.

**Entry conditions** (Formula Evaluates to True):

```
AND(
    {!$Setup.On_Off_Switch__c.Run_Flows__c},
    NOT(ISBLANK({!$Record.OpportunityId}))
)
```

- The Flow honors the **On/Off Switch** custom setting, like the other Beacon Flows.
- It only runs for Quotes that have an Opportunity.

**Why After Save and not Before Save:** Salesforce controls syncing from the Opportunity side, through `Opportunity.SyncedQuoteId`. The Quote's **Syncing** field (`IsSyncing`) is read-only. A Before Save Flow can only change the record that triggered it, so it can't update the Opportunity. A new Quote also has no Id yet during a Before Save Flow. An After Save Flow is the only Flow type that can start the sync.

**Why the Run Asynchronously path:** when a Quote is created from an Opportunity that has products, Salesforce copies those products to the Quote as Quote Line Items after the Quote itself is saved. Starting the sync copies the Quote's line items to the Opportunity's products. If the sync started on the immediate path, it could run before the line items exist and clear the Opportunity's products. The Run Asynchronously path runs after the whole save has finished, so the Quote already has its line items when the sync starts.

**Only one Quote syncs per Opportunity.** If the Opportunity already has a synced Quote, the new Quote replaces it and the older Quote stops syncing. The newest Quote is always the primary one.

If the update fails, the Flow calls the existing **Fault Path Subflow** to send the error notification.

### Quote - On Update - After Save Flow

A new record-triggered Flow, **Quote - On Update - After Save** (`Quote_On_Update_After_Save`), runs when a Quote is updated. When the Quote's **Status** is changed to **Accepted** and the Quote is syncing, it sets the Opportunity's **Stage** to **Contract**.

**Entry conditions** (Formula Evaluates to True):

```
AND(
    {!$Setup.On_Off_Switch__c.Run_Flows__c},
    ISCHANGED({!$Record.Status}),
    ISPICKVAL({!$Record.Status}, "Accepted"),
    {!$Record.IsSyncing},
    NOT(ISBLANK({!$Record.OpportunityId}))
)
```

- **`ISCHANGED`** makes the Flow run only when the Status changes to Accepted. Later edits to an already Accepted Quote don't move the Stage again.
- **`IsSyncing`** limits the Flow to the Opportunity's synced Quote, so approving a Quote that isn't syncing doesn't change the Opportunity.
- The Flow honors the **On/Off Switch**.

**Closed Opportunities are left alone.** The Update Records step only updates the Opportunity when it isn't closed (`IsClosed = false`). A Closed Won or Closed Lost Opportunity is never moved back to Contract.

**Contract is in every Opportunity sales process** (Consulting, Subscription New and Subscription Renewal), so the update works for all Opportunity record types. The only Opportunity Validation Rule, **Required Fields Demo Booked**, only applies at the Demo Booked stage and doesn't block the update.

This Flow runs on the immediate path, because nothing else needs to finish first. If the update fails, for example because of a Validation Rule added later, the Flow calls the **Fault Path Subflow** and the Quote's Status change is rolled back with the error.

## Acceptance Criteria

1. In **Setup → Quote Settings**, confirm **Enable Quotes** is on.
2. In **Setup → Flows**, confirm **Quote - On Create - After Save** is **Active**.
3. **New Quote on an Opportunity with no Quotes:**
   1. Open an Opportunity with no Quotes. Add two products to it.
   2. From the **Quotes** related list, click **New Quote**, fill in the required fields and save.
   3. Refresh the Quote after a few seconds. Confirm the **Syncing** checkbox is checked.
   4. Open the Opportunity. Confirm **Synced Quote** shows the new Quote, and both products are still on the Opportunity with the same quantities and prices.
4. **Second Quote replaces the first:**
   1. On the same Opportunity, create a second Quote.
   2. Refresh both Quotes after a few seconds. Confirm the second Quote is **Syncing** and the first Quote is not.
   3. Confirm the Opportunity's **Synced Quote** shows the second Quote, and its products still match the second Quote's line items.
5. **Sync keeps working after the Quote is created:**
   1. On the synced Quote, change a line item's quantity and save.
   2. Confirm the matching Opportunity product shows the new quantity.
6. **On/Off Switch:**
   1. Add a **User** level On/Off Switch record for your user with **Run Flows** unchecked.
   2. Create a Quote on an Opportunity. Confirm it is **not** Syncing.
   3. Delete the User level record. Create another Quote and confirm it **is** Syncing.

7. **Accepted synced Quote moves the Stage to Contract:**
   1. Open an open Opportunity at a stage before Contract (e.g. Proposal) with a synced Quote.
   2. Change the synced Quote's **Status** to **Accepted** and save.
   3. Open the Opportunity. Confirm its **Stage** is **Contract**.
8. **Quote that isn't syncing doesn't move the Stage:**
   1. On an Opportunity at Proposal with two Quotes, open the Quote that is **not** Syncing.
   2. Change its **Status** to **Accepted** and save.
   3. Confirm the Opportunity's **Stage** is still **Proposal**.
9. **Other Status values don't move the Stage:**
   1. On an Opportunity at Proposal, change its synced Quote's **Status** to a value other than Accepted (e.g. **Approved**) and save.
   2. Confirm the Opportunity's **Stage** is still **Proposal**.
10. **Closed Opportunities are left alone:**
    1. On a **Closed Won** Opportunity with a synced Quote, change the Quote's **Status** to **Accepted** and save.
    2. Confirm the Opportunity's **Stage** is still **Closed Won**.
11. **On/Off Switch:**
    1. Add a **User** level On/Off Switch record for your user with **Run Flows** unchecked.
    2. Change a synced Quote's **Status** to **Accepted** on an Opportunity at Proposal. Confirm the Stage is still **Proposal**.
    3. Delete the User level record afterwards.

## Post Deployment Items

- Confirm **Enable Quotes** is on in **Setup → Quote Settings** in the target org. The Flow can't start syncing if Quotes are off.
- Confirm the Quote **Status** picklist in the target org has an **Accepted** value with the API name `Accepted`. The Flow checks for that exact value.
- Tell users that new Quotes now sync automatically and replace the Opportunity's existing synced Quote. To make an older Quote primary again, open it and click **Start Sync**.

## Component Manifest

Github Branch: https://github.com/aaroncrear/BeaconImplementation/tree/Quote-Automations

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Flow | Quote | Quote_On_Create_After_Save | Quote - On Create - After Save | Created | Record-triggered After Save Flow. When a Quote is created, sets the parent Opportunity's Synced Quote to the new Quote on the Run Asynchronously path, so the Quote becomes the primary, synced Quote. Honors the On/Off Switch. |
| 2 | Flow | Quote | Quote_On_Update_After_Save | Quote - On Update - After Save | Created | Record-triggered After Save Flow. When a syncing Quote's Status is changed to Accepted, sets the Opportunity's Stage to Contract, unless the Opportunity is already closed. Honors the On/Off Switch. |
