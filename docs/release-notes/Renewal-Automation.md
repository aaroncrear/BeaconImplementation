# "Renewal-Automation" – Release Notes

## Requirements

Today, after a Quote is accepted and the Opportunity is Closed Won, users have to click through
several Revenue Cloud buttons to finish the deal. They create the Contract, activate it, create the
Order, activate it, renew the Assets and create the Beacon Subscriptions by hand. The business
wants to keep the native Revenue Cloud functionality and triggers, but remove these manual
steps:

- When a new-business Opportunity moves to **Closed Won**, automatically create and activate the
  **Contract** from the approved (Accepted) Quote. Then create and activate the **Order** from
  the Quote lines.
- Order activation already creates the **Assets** on the Account through the existing
  `Order - Create Assets` flow. This must keep working unchanged.
- When the Assets are created, automatically create one **Beacon Subscription** per purchased
  seat. Each subscription is linked to the Asset and Account and carries the term's Start Date
  and End Date. The subscriber Contact is left blank; Contacts will be data loaded later.
- Automatically create the **renewal Opportunity and renewal Quote** for the next term.
- Track the link between the original and renewal Opportunities in both directions.
- The automation must not run twice for the same Opportunity. If a step fails, the error must be
  visible on the Opportunity and the admins must be notified.
- Build and test in Beacon HTCDEV first, then UAT, then Prod.

Out of scope for v1: changing the number of Beacon Subscriptions when the seat count changes at
renewal or amendment, and running the automation for Subscription Renewal Opportunities.

## Release Notes

### How it works end to end

```
Quote Accepted → Opportunity Stage = Contract → Opportunity Stage = Closed Won
  └─ Opportunity - Closed Won - After Save (async path)
       └─ Closed Won Revenue Automation (subflow)
            ├─ Create Contract (native createContract) → Activate Contract
            ├─ Create Order (native createOrdersFromQuote) → Activate Order
            └─ Mark Opportunity complete, link Contract
                 └─ Order - Create Assets (existing, async) → Assets created
                      ├─ Asset - On Create or Update - After Save → Beacon Subscriptions
                      └─ Create Asset Order Event (native platform event)
                           └─ Order - Assets Created - Create Renewal
                                └─ Create Renewal Quote (native) → renewal Opportunity + Quote
                                     → set up renewal Opportunity, link both Opportunities
```

### What changed from the original design

These were found in HTCDEV during the build, and the design was changed to match (agreed with
Aaron):

1. **The renewal step moved to after assetization.** The native `Create Renewal Quote` flow
   (`quotingAI__createRenewalQuote`) takes **Asset Ids**. It has no Opportunity input, and it
   creates its **own** "Renewal Opportunity" along with the "Renewal Quote". So it can't be
   called on a renewal Opportunity we create from the Contract, and it can't run until the
   Assets exist. The Contract side now ends at Activate Contract. The renewal runs off the
   native **Create Asset Order Event**, which Revenue Cloud publishes once an Order's Assets have
   been created.
2. **Seat count is `Asset.CurrentQuantity`, not `Asset.Quantity`.** On Revenue Cloud assets,
   `Quantity` is blank. The seat count lives on the Asset State Period and is rolled up to
   `CurrentQuantity` just after the Asset is inserted. The Asset flow therefore runs on create
   **or update** when Current Quantity is set or changes.
3. **Quote status is "Accepted".** The approved status on Quote in HTCDEV is `Accepted`.
   `Approved` isn't a value.
4. **Separate Closed Won trigger flow.** The existing `Opportunity - On Update - After Save`
   (ResOps Contract Cleanup Case) is being finished on the `ResOps-automation` branch. The
   Closed Won trigger is its own flow so the two branches don't overwrite each other. They can
   be merged into one flow later if preferred.

### Opportunity - Closed Won - After Save (new flow)

`Opportunity_Closed_Won_After_Save` is a thin record-triggered flow on Opportunity update. It
runs when all of these are true:

- Run Flows is checked on the On/Off Switch
- the record type is **Subscription New**
- the Stage has just changed to **Closed Won**
- Closed Won Automation Complete is unchecked

It calls the subflow on the **Run Asynchronously** path. The Stage change saves straight away for
the user, and the Revenue Cloud actions run in their own transaction afterwards.

### Closed Won Revenue Automation (new subflow)

`Closed_Won_Revenue_Automation` is an autolaunched subflow.

- **Input:** `opportunityId`.
- **Outputs:** `contractId`, `orderId`, `isSuccess`, `errorMessage`.

The steps are:

1. Gets the Opportunity. **Stops if Closed Won Automation Complete is already checked**, so a
   direct call can't create duplicates.
2. Gets the most recently modified **Accepted** Quote on the Opportunity. If there isn't one,
   writes "no Accepted Quote was found…" to Closed Won Automation Error, sends the fault email
   and stops.
3. **Contract:** if the Quote already has a Contract (for example from an earlier failed run),
   it's reused. Otherwise the native **Create Contract** action (`createContract`) creates it,
   with `sourceId` = the Quote and `contractPriceOption` = `NET_UNIT_PRICE_ONLY`. This is the
   same action and option as the "Net Unit Price" choice on the Create Contract From Quote screen,
   and it saves the quote's net unit prices as Contract Item Prices. The existing HTCDEV contracts
   had prices saved this way. The Contract is then **activated** (Status = Activated) if it
   isn't already.
4. **Order:** if an Order already exists for the Quote, it's reused. Otherwise the native
   **Create Orders From Quote** action (`createOrdersFromQuote`) creates it with just the Quote
   Id. This creates a single Order from all of the quote lines. It's the same action used by
   `Quote - Create Order - Screen Flow`, and the Order picks up the Contract from the Quote.
   Every Order for the Quote that isn't active is then **activated**. Activation fires the
   existing `Order - Create Assets` flow, which creates the Assets asynchronously.
5. Checks **Closed Won Automation Complete**, clears **Closed Won Automation Error** and sets the
   Opportunity's **Contract** lookup.

Every step has a fault path. The error is written to Closed Won Automation Error and sent through
the standard `Fault Path Subflow` email. Steps that already succeeded are not rolled back.
Because the Contract and Order are reused when they already exist, an admin can fix the cause,
re-run the automation, and it carries on where it stopped (see Post Deployment Items).

### Order - Assets Created - Create Renewal (new flow)

`Order_Assets_Created_Create_Renewal` is a platform-event-triggered flow on the native **Create
Asset Order Event** (`CreateAssetOrderEvent`). It only runs on the final event for an Order
(`IsLastEvent` = true), and only when Run Flows is checked. It then:

1. Gets the Order (`OrderIdentifier`), its Quote and the Quote's Opportunity. It only continues
   when that Opportunity is **Subscription New**, Closed Won Automation Complete is checked, and
   **Renewal Opportunity is blank**. This means each deal gets one renewal, and Orders from
   renewal or amendment quotes and manual Orders are skipped.
2. Finds the Assets created from the Order: Order Products → Asset Action Sources
   (`ReferenceEntityItemId`) → Asset Actions → Asset Ids. Asset has no direct link to its Order,
   so this is the reliable path.
3. Calls the native **Create Renewal Quote** flow once with all of the Asset Ids. Renewal dates
   are left to the action's defaults (the term after the current one). This creates the renewal
   Opportunity and renewal Quote.
4. Sets up the renewal Opportunity:

   | Field | Value |
   |---|---|
   | Record Type | Subscription Renewal |
   | Name | `<original Opportunity name> - Renewal` |
   | Type | Existing Business |
   | Owner | Owner of the original Opportunity |
   | Contract | The Contract on the Order |
   | Previous Opportunity | The original Opportunity |

5. Sets **Renewal Opportunity** on the original Opportunity.

If Create Renewal Quote fails, or any step faults, the error is written to Closed Won Automation
Error on the original Opportunity and sent through the Fault Path Subflow.

### Asset - On Create or Update - After Save (new flow)

`Asset_On_Create_Or_Update_After_Save` is a record-triggered after-save flow on Asset. It runs on
create and update when all of these are true:

- Run Flows is checked
- the Asset has an Account and a Product
- the Product Family is not **Platform Bundle** (subscriptions are created on the module Assets)
- Current Quantity is 1 or more
- the Asset is new, or Current Quantity has changed

The flow counts the Asset's existing Beacon Subscriptions. It then builds one subscription per
missing seat (Current Quantity rounded down, minus the existing count) and creates them all in a
**single Create Records** step. Because it only creates the missing seats, it never creates
duplicates, even when Current Quantity is set after the insert or the Asset is saved again.

| Beacon Subscription field | Value |
|---|---|
| `Asset__c` | The triggering Asset |
| `Account__c` | `Asset.AccountId` |
| `Start_Date__c` | Date part of `Asset.LifecycleStartDate` |
| `End_Date__c` | Date part of `Asset.CurrentLifecycleEndDate`, falling back to `Asset.LifecycleEndDate` |
| `Contact__c` | Left blank. It will be filled in when Contacts are data loaded. |
| `Active__c`, `Status__c` | Not set. These are formulas. |

The flow never deletes subscriptions when the quantity goes down (out of scope for v1).

### Beacon - Create Contract From Quote (cloned flow)

`Beacon_Create_Contract_From_Quote` is Aaron's unmanaged clone of the managed Revenue Cloud
screen flow `rev_contracts__CreateCntrFromQuote`. It was added to the branch so the native
`createContract` action and its inputs could be read. It is unchanged from the managed version.
It is set as an **override** of the managed flow (`overriddenFlow`), so the Create Contract
button on Quote will run this copy. The automation doesn't call it; the subflow calls the
`createContract` action directly.

### Opportunity fields (new)

| Field | Type | Purpose |
|---|---|---|
| `Closed_Won_Automation_Complete__c` | Checkbox | Set once the Contract and Order have been created and activated. Stops the automation running twice. Uncheck only to deliberately re-run. |
| `Closed_Won_Automation_Error__c` | Long Text Area (32,768) | Error from the last failed run, so users can see why a deal didn't process. Cleared on success. |
| `Renewal_Opportunity__c` | Lookup(Opportunity), Set Null | On the original Opportunity: its renewal Opportunity. Also stops a second renewal being created. |
| `Previous_Opportunity__c` | Lookup(Opportunity), Set Null | On a renewal Opportunity: the Opportunity it renews. Its related list on the original Opportunity is "Renewal Opportunities". |

Field-level security was added to every persona "Object, Tab, FLS" permission set (Read), and to
Beacon Salesforce Admin – Object, Tab, FLS (Read + Edit).

### Existing flows (unchanged, for reference)

`Order_Create_Assets` and `Quote_Create_Order_Screen_Flow` were retrieved into the branch so the
native actions could be read. They are not changed by this build. Note: `Order - Create Assets`
has an element called **Test** on its run-immediately path. It updates the triggering Order's
Ordered Date every time an Order is activated. It may be related to the error seen earlier on
Order 00000105 and should be reviewed.

## Acceptance Criteria

Test in Beacon HTCDEV with Run Flows checked on the On/Off Switch. Use a test Account with no
existing Assets.

**Happy path**

1. Create a Subscription New Opportunity and a Quote with two module products (e.g. ADC Module,
   Autoimmune Module), quantity 1 each. Set the Quote Status to **Accepted**. Move the
   Opportunity to Contract, then to **Closed Won**.
2. Wait a minute and refresh. On the Opportunity, confirm Closed Won Automation Complete is
   checked, Closed Won Automation Error is blank and Contract is filled in.
3. Open the Contract. Confirm Status = Activated, it's linked to the Quote (Quote → Contract),
   and it has Contract Item Prices matching the quote lines' net unit prices.
4. Open the Order (Quote → Orders). Confirm there is exactly one Order, Status = Activated, with
   both products and the Contract filled in.
5. On the Account, confirm one Asset per product with Lifecycle Start/End Dates and Current
   Quantity 1.
6. On each Asset, confirm one Beacon Subscription with Account and Asset filled in, Contact blank,
   Start Date = the Asset's Lifecycle Start Date and End Date = its Current Lifecycle End Date.
7. Back on the original Opportunity, confirm **Renewal Opportunity** is filled in. Open it and
   confirm:
   - Record Type = Subscription Renewal
   - Name = `<original name> - Renewal`
   - Type = Existing Business
   - Owner = the original Owner
   - Contract = the new Contract
   - **Previous Opportunity** = the original Opportunity
   - it has a Renewal Quote for the next term containing both products
8. On the original Opportunity, confirm the renewal Opportunity appears in the **Renewal
   Opportunities** related list (once it's added to the layout).

**No duplicates**

9. Move the same Opportunity to another Stage and back to Closed Won. Confirm no second Contract,
   Order or renewal is created.
10. Edit and save one of the Assets without changing Current Quantity. Confirm no extra Beacon
    Subscriptions.

**Errors**

11. Create another Subscription New Opportunity with a Quote left in **Draft** and move it to
    Closed Won. Confirm Closed Won Automation Error says no Accepted Quote was found, Closed Won
    Automation Complete is unchecked, and the fault email arrives.
12. **Re-run:** on that Opportunity, set the Quote to Accepted. Move the Opportunity off Closed
    Won and back. Confirm the automation completes and the error is cleared.

**Scope checks**

13. Close Won a **Subscription Renewal** Opportunity. Confirm the automation doesn't run.
14. Raise an Asset's Current Quantity from 1 to 3 (as an admin, in a sandbox). Confirm exactly
    two more Beacon Subscriptions. Lower it and confirm none are deleted.
15. Confirm no Beacon Subscription is created on a Platform Bundle Asset.
16. Uncheck Run Flows, Close Won a test Opportunity, and confirm nothing runs. Re-check Run Flows
    afterwards.

**Access**

17. As a Beacon Salesforce Admin, confirm the four new Opportunity fields can be edited. As a
    persona user (e.g. Beacon Sales), confirm they're visible and read-only.

## Post Deployment Items

1. **Deploy order:** deploy the four Opportunity fields and permission sets first, then the
   flows. The flows reference the new fields. `Closed_Won_Revenue_Automation` must be deployed
   before (or with) `Opportunity_Closed_Won_After_Save`.
2. **Page layouts:** add Closed Won Automation Complete, Closed Won Automation Error, Renewal
   Opportunity and Previous Opportunity to the Opportunity layouts or the Beacon Opportunity
   Record Page. Add the **Renewal Opportunities** related list too.
3. **Gearset comparison:** when deploying the permission sets, include the Opportunity object
   (at least the four new fields) in the comparison. Otherwise Gearset strips the new field
   permissions.
4. **Create Contract override:** `Beacon - Create Contract From Quote` overrides the managed
   Create Contract From Quote flow. Confirm this is wanted before deploying it to UAT and Prod.
5. **Re-running a failed deal:** fix the cause shown in Closed Won Automation Error. Make sure
   Closed Won Automation Complete is unchecked, then move the Opportunity off Closed Won and
   back. If the renewal step failed (the Contract and Order are done), raise it with the admin
   team: it needs Renewal Opportunity blank and a new Create Asset Order Event, or a manual
   Renew from the Assets.
6. **Review `Order - Create Assets`:** see the note above about its Test element.
7. **Existing deals:** Assets and Opportunities from before this build don't get subscriptions or
   renewals automatically. Data load subscriptions where needed, and renew existing Assets
   manually.

## Component Manifest

Github Branch: https://github.com/aaroncrear/BeaconImplementation/tree/Renewal-Automation

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Flow | Opportunity | Opportunity_Closed_Won_After_Save | Opportunity - Closed Won - After Save | Created | Record-triggered (update) flow. When a Subscription New Opportunity moves to Closed Won and the automation hasn't completed, calls Closed Won Revenue Automation on the async path. |
| 2 | Flow | Opportunity | Closed_Won_Revenue_Automation | Closed Won Revenue Automation | Created | Autolaunched subflow. Creates (or reuses) and activates the Contract (native createContract, net unit prices) and Order (native createOrdersFromQuote) from the Accepted Quote, then marks the Opportunity complete. Errors go to the Opportunity and the fault email. |
| 3 | Flow | CreateAssetOrderEvent | Order_Assets_Created_Create_Renewal | Order - Assets Created - Create Renewal | Created | Platform-event flow. After an Order's Assets are created, calls native Create Renewal Quote with the Order's Assets, sets up the renewal Opportunity and links it to the original. |
| 4 | Flow | Asset | Asset_On_Create_Or_Update_After_Save | Asset - On Create or Update - After Save | Created | Record-triggered flow. Creates one Beacon Subscription per missing seat (Current Quantity minus existing) with Asset, Account, Start and End Date. Excludes Platform Bundle Assets. |
| 5 | Flow | Quote | Beacon_Create_Contract_From_Quote | Beacon - Create Contract From Quote | Created | Unmanaged clone of rev_contracts__CreateCntrFromQuote (screen flow, overrides it). Added by Aaron so the createContract action could be read. Not called by the automation. |
| 6 | Field | Opportunity | Closed_Won_Automation_Complete__c | Closed Won Automation Complete | Created | Checkbox. Set once the Contract and Order are created and activated. Prevents duplicate runs. |
| 7 | Field | Opportunity | Closed_Won_Automation_Error__c | Closed Won Automation Error | Created | Long Text Area. Error from the last failed run. |
| 8 | Field | Opportunity | Renewal_Opportunity__c | Renewal Opportunity | Created | Lookup(Opportunity), Set Null. On the original Opportunity, its renewal Opportunity. |
| 9 | Field | Opportunity | Previous_Opportunity__c | Previous Opportunity | Created | Lookup(Opportunity), Set Null. On a renewal Opportunity, the Opportunity it renews. |
| 10 | Permission Set | Opportunity | Beacon_Consulting_Object_Tab_FLS | Beacon Consulting - Object, Tab, FLS | Updated | Read FLS on the four new Opportunity fields. |
| 11 | Permission Set | Opportunity | Beacon_Customer_Success_Object_Tab_FLS | Beacon Customer Success - Object, Tab, FLS | Updated | Read FLS on the four new Opportunity fields. |
| 12 | Permission Set | Opportunity | Beacon_Executive_Object_Tab_FLS | Beacon Executive - Object, Tab, FLS | Updated | Read FLS on the four new Opportunity fields. |
| 13 | Permission Set | Opportunity | Beacon_Finance_Object_Tab_FLS | Beacon Finance - Object, Tab, FLS | Updated | Read FLS on the four new Opportunity fields. |
| 14 | Permission Set | Opportunity | Beacon_Marketing_Object_Tab_FLS | Beacon Marketing - Object, Tab, FLS | Updated | Read FLS on the four new Opportunity fields. |
| 15 | Permission Set | Opportunity | Beacon_Product_Object_Tab_FLS | Beacon Product - Object, Tab, FLS | Updated | Read FLS on the four new Opportunity fields. |
| 16 | Permission Set | Opportunity | Beacon_ResOps_Object_Tab_FLS | Beacon ResOps - Object, Tab, FLS | Updated | Read FLS on the four new Opportunity fields. |
| 17 | Permission Set | Opportunity | Beacon_Sales_Object_Tab_FLS | Beacon Sales - Object, Tab, FLS | Updated | Read FLS on the four new Opportunity fields. |
| 18 | Permission Set | Opportunity | Beacon_Salesforce_Admin_Object_Tab_FLS | Beacon Salesforce Admin - Object, Tab, FLS | Updated | Read + Edit FLS on the four new Opportunity fields. |
| 19 | Permission Set | Opportunity | Beacon_Tech_Object_Tab_FLS | Beacon Tech - Object, Tab, FLS | Updated | Read FLS on the four new Opportunity fields. |
