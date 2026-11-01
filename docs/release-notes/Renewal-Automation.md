# "Renewal-Automation" – Release Notes

> **Status: in progress.** This branch has the Beacon Subscription automation and the Opportunity
> tracking fields so far. The Closed Won Contract/Order automation and the renewal Quote step are
> still to be built (see Post Deployment Items, item 1). They depend on the native Revenue Cloud
> flows being retrieved into this branch. These notes will be updated as each piece is added.

## Requirements

Today, after a Quote is approved and the Opportunity is Closed Won, users have to click through
several Revenue Cloud buttons to finish the deal. They create the Contract, activate it, create the
Order, activate it, renew the Assets and create the Beacon Subscriptions by hand. The business
wants to keep the native Revenue Cloud functionality and triggers, but remove these manual
steps:

- When an Opportunity moves to **Closed Won**, automatically create and activate the **Contract**
  from the approved (Accepted) Quote. Then create and activate the **Order** from the Quote lines.
- Order activation already creates the **Assets** on the Account through the existing
  `Order - Create Assets` flow. This must keep working unchanged.
- When the Assets are created, automatically create one **Beacon Subscription** per purchased
  seat. Each subscription is linked to the Asset and Account and carries the term's Start Date
  and End Date. The subscriber Contact is left blank; Contacts will be data loaded later.
- Automatically create the **renewal Opportunity and renewal Quote** for the next term.
- The automation must not run twice for the same Opportunity. If a step fails, the error must be
  visible on the Opportunity and the admins must be notified.
- Build and test in Beacon HTCDEV first, then UAT, then Prod.

Out of scope for v1: changing the number of Beacon Subscriptions when the seat count changes at
renewal or amendment.

## Release Notes

### What changed from the original design

These were found in HTCDEV during the build, and the design was changed to match (agreed with
Aaron):

1. **The renewal step moved to after assetization.** The native `Create Renewal Quote` action
   (`quotingAI__createRenewalQuote`) takes **Asset Ids** plus renewal start/end dates. It has no
   Opportunity input, and it creates its **own** "Renewal Opportunity" along with the "Renewal
   Quote". In HTCDEV, Renewal Opportunity / Renewal Quote pairs were created in the same second.
   So it can't be called "on a renewal Opportunity we created from the Contract", and it can't
   run until the Assets exist. Assets are created asynchronously after Order activation. The
   renewal step will run after the Assets are created. It will call `createRenewalQuote` once
   with all of the Order's Assets, then update the Opportunity it creates. The Contract side of
   the flow now ends at Activate Contract.
2. **Seat count is `Asset.CurrentQuantity`, not `Asset.Quantity`.** On Revenue Cloud assets,
   `Quantity` is blank. The seat count lives on the Asset State Period and is rolled up to
   `CurrentQuantity`. `CurrentQuantity` is filled in just after the Asset is inserted, so an
   "on create, Quantity > 0" trigger would never fire. The Asset flow therefore runs on create
   **or update** when Current Quantity is set or changes.
3. **Quote status is "Accepted".** The approved status on Quote in HTCDEV is `Accepted`.
   `Approved` isn't a value. The Closed Won automation will look for the Opportunity's Accepted
   Quote.
4. **The existing `Opportunity - On Update - After Save` flow is left alone.** It lives on the
   unmerged `ResOps-automation` branch and is active in HTCDEV. It only fires on Stage =
   Contract. The Closed Won trigger will be a separate flow so that this branch doesn't
   overwrite it.

### Asset - On Create or Update - After Save (new flow)

`Asset_On_Create_Or_Update_After_Save` is a record-triggered, after-save flow on Asset. It runs
on create and update when all of these are true:

- Run Flows is checked on the On/Off Switch custom setting
- the Asset has an Account and a Product
- the Asset's Product Family is not **Platform Bundle** (subscriptions are created on the
  module Assets, not on a bundle parent)
- Current Quantity is 1 or more
- the Asset is new, or Current Quantity has changed

The flow gets the Beacon Subscriptions already linked to the Asset and counts them. It then
works out the seats to create: Current Quantity (rounded down) minus the existing count. If that
is above zero, it adds one Beacon Subscription per missing seat to a collection and creates them
all in a **single Create Records** step. This keeps DML to one statement per transaction even
when a whole Order is assetized at once. Because it only creates the missing seats, the flow is
safe to run again. It doesn't create duplicates when Current Quantity is set after the insert,
or if an admin re-saves the Asset.

Field mapping for each new `Beacon_Subscription__c`:

| Field | Value |
|---|---|
| `Asset__c` | The triggering Asset |
| `Account__c` | `Asset.AccountId` |
| `Start_Date__c` | Date part of `Asset.LifecycleStartDate` |
| `End_Date__c` | Date part of `Asset.CurrentLifecycleEndDate` (the end of the current term), falling back to `Asset.LifecycleEndDate` |
| `Contact__c` | Left blank. It will be filled in when Contacts are data loaded. |
| `Active__c`, `Status__c` | Not set. These are formulas. |

Any error goes to the standard `Fault Path Subflow` email. The flow never deletes subscriptions
when the quantity goes down (out of scope for v1).

### Opportunity tracking fields (new)

| Field | Type | Purpose |
|---|---|---|
| `Closed_Won_Automation_Complete__c` | Checkbox, default unchecked | Set by the Closed Won automation once the Contract and Order are created and activated. Both the trigger flow and the subflow check it, so the automation can't run twice for the same Opportunity. Uncheck it only to deliberately re-run. |
| `Closed_Won_Automation_Error__c` | Long Text Area (32,768) | Holds the error from the last failed run so users can see why a deal didn't process. Cleared on success. |

Field-level security was added to every persona "Object, Tab, FLS" permission set (Read), and to
Beacon Salesforce Admin – Object, Tab, FLS (Read + Edit, so admins can reset the flag).

## Acceptance Criteria

Test in Beacon HTCDEV with Run Flows checked on the On/Off Switch.

**Beacon Subscriptions**

1. **New Order:** Take a Quote with at least two module products (e.g. ADC Module, Autoimmune
   Module) through to an activated Order. Wait for the Assets to be created on the Account.
   Open each Asset and confirm it has as many Beacon Subscriptions as its Current Quantity.
2. **Field values:** On one of those subscriptions, confirm Account and Asset are filled in and
   Contact is blank. Confirm Start Date equals the Asset's Lifecycle Start Date and End Date
   equals its Current Lifecycle End Date. Confirm Active is checked and Status shows the green
   Active flag (if the term has started).
3. **No duplicates on re-save:** Edit and save one of the Assets without changing Current
   Quantity. Confirm no extra subscriptions are created.
4. **Quantity increase:** In a sandbox, raise an Asset's Current Quantity from 1 to 3 (through an
   amendment, or by hand as an admin). Confirm exactly two more subscriptions are created, for a
   total of 3.
5. **Quantity decrease:** Lower Current Quantity. Confirm no subscriptions are created or
   deleted.
6. **Bundle excluded:** Create (or find) an Asset whose Product Family is Platform Bundle with a
   Current Quantity of 1. Confirm no Beacon Subscription is created on it.
7. **On/Off Switch:** Uncheck Run Flows, create an Asset with a Current Quantity of 1, and
   confirm no subscription is created. Re-check Run Flows afterwards.
8. **Fault path:** In a sandbox, temporarily remove the Account from a test Asset's data so the
   create fails (or deactivate a required permission). Confirm the Fault Path Subflow email
   arrives.

**Opportunity fields**

9. As a Beacon Salesforce Admin, open an Opportunity and confirm **Closed Won Automation
   Complete** and **Closed Won Automation Error** can be read and edited (once they are on the
   layout; see Post Deployment Items).
10. As a persona user (e.g. Beacon Sales – Object, Tab, FLS), confirm both fields are visible and
    read-only.

## Post Deployment Items

1. **Still to build on this branch.** These depend on the native flow definitions, which can't be
   read from the Claude session.
   - Retrieve and push `Order_Create_Assets` and `Quote_Create_Order_Screen_Flow` to this branch
     (for example `sf project retrieve start -m Flow:Order_Create_Assets -m
     Flow:Quote_Create_Order_Screen_Flow`, or through Gearset). Then build the Closed Won trigger
     flow and the `Closed_Won_Revenue_Automation` subflow (Contract create + activate, Order
     create + activate, completed flag and error handling) using the same native actions.
   - Build the renewal step. After assetization, call `createRenewalQuote` with the Order's
     Asset Ids. Then set the record type of the Renewal Opportunity it creates to
     Subscription Renewal, and fix its name.
2. **Page layouts:** Add Closed Won Automation Complete and Closed Won Automation Error to the
   Opportunity layouts or the Beacon Opportunity Record Page so users can see a failed run.
3. **Gearset comparison:** When deploying the permission sets, include the Opportunity object
   (at least the two new fields) in the comparison. Otherwise Gearset strips the new field
   permissions.
4. **Existing Assets (optional):** Assets created before this flow was activated don't get
   subscriptions automatically. Either data load them, or have an admin re-save each Asset after
   a Current Quantity change.

## Component Manifest

Github Branch: https://github.com/aaroncrear/BeaconImplementation/tree/Renewal-Automation

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Flow | Asset | Asset_On_Create_Or_Update_After_Save | Asset - On Create or Update - After Save | Created | Record-triggered after-save flow. Creates one Beacon Subscription per missing seat (Current Quantity minus existing subscriptions) with Asset, Account, Start Date and End Date. Excludes Platform Bundle Assets. Respects the On/Off Switch. |
| 2 | Field | Opportunity | Closed_Won_Automation_Complete__c | Closed Won Automation Complete | Created | Checkbox. Set once the Closed Won automation has created and activated the Contract and Order. Prevents duplicate runs. |
| 3 | Field | Opportunity | Closed_Won_Automation_Error__c | Closed Won Automation Error | Created | Long Text Area. Error message from the last failed Closed Won automation run. |
| 4 | Permission Set | Opportunity | Beacon_Consulting_Object_Tab_FLS | Beacon Consulting - Object, Tab, FLS | Updated | Read FLS on Closed_Won_Automation_Complete__c and Closed_Won_Automation_Error__c. |
| 5 | Permission Set | Opportunity | Beacon_Customer_Success_Object_Tab_FLS | Beacon Customer Success - Object, Tab, FLS | Updated | Read FLS on Closed_Won_Automation_Complete__c and Closed_Won_Automation_Error__c. |
| 6 | Permission Set | Opportunity | Beacon_Executive_Object_Tab_FLS | Beacon Executive - Object, Tab, FLS | Updated | Read FLS on Closed_Won_Automation_Complete__c and Closed_Won_Automation_Error__c. |
| 7 | Permission Set | Opportunity | Beacon_Finance_Object_Tab_FLS | Beacon Finance - Object, Tab, FLS | Updated | Read FLS on Closed_Won_Automation_Complete__c and Closed_Won_Automation_Error__c. |
| 8 | Permission Set | Opportunity | Beacon_Marketing_Object_Tab_FLS | Beacon Marketing - Object, Tab, FLS | Updated | Read FLS on Closed_Won_Automation_Complete__c and Closed_Won_Automation_Error__c. |
| 9 | Permission Set | Opportunity | Beacon_Product_Object_Tab_FLS | Beacon Product - Object, Tab, FLS | Updated | Read FLS on Closed_Won_Automation_Complete__c and Closed_Won_Automation_Error__c. |
| 10 | Permission Set | Opportunity | Beacon_ResOps_Object_Tab_FLS | Beacon ResOps - Object, Tab, FLS | Updated | Read FLS on Closed_Won_Automation_Complete__c and Closed_Won_Automation_Error__c. |
| 11 | Permission Set | Opportunity | Beacon_Sales_Object_Tab_FLS | Beacon Sales - Object, Tab, FLS | Updated | Read FLS on Closed_Won_Automation_Complete__c and Closed_Won_Automation_Error__c. |
| 12 | Permission Set | Opportunity | Beacon_Salesforce_Admin_Object_Tab_FLS | Beacon Salesforce Admin - Object, Tab, FLS | Updated | Read + Edit FLS on Closed_Won_Automation_Complete__c and Closed_Won_Automation_Error__c. |
| 13 | Permission Set | Opportunity | Beacon_Tech_Object_Tab_FLS | Beacon Tech - Object, Tab, FLS | Updated | Read FLS on Closed_Won_Automation_Complete__c and Closed_Won_Automation_Error__c. |
