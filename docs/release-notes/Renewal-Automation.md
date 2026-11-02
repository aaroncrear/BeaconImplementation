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
  └─ Opportunity - Closed Won - After Save (Run Asynchronously path)
       └─ Closed Won Revenue Automation (subflow)
            ├─ Create Contract (native createContract) → Activate Contract
            ├─ Create Order (native createOrdersFromQuote) → Activate Order
            └─ Mark Opportunity complete, link Contract
                 └─ Order - Create Assets (existing, async) → Assets created
                      ├─ Asset - On Create or Update - After Save → Beacon Subscriptions
                      └─ Create Asset Order Event (native platform event)
                           └─ Create Asset Order Event - Mark Order Assets Created
                                └─ Order.Assets_Created__c = true
                                     └─ Order - Assets Created - Create Renewal (async path)
                                          └─ Create Renewal Quote (native) → renewal Opp + Quote
                                               → set up renewal Opp, link both Opportunities
```

### What changed from the original design

These were found in HTCDEV during the build, and the design was changed to match (agreed with
Aaron):

1. **The renewal step moved to after assetization.** The native `Create Renewal Quote` flow
   (`quotingAI__createRenewalQuote`) takes **Asset Ids**. It has no Opportunity input, and it
   creates its **own** "Renewal Opportunity" along with the "Renewal Quote". So it can't be
   called on a renewal Opportunity we create from the Contract, and it can't run until the
   Assets exist. The Contract side now ends at Activate Contract. The renewal is started by the
   native **Create Asset Order Event**, which Revenue Cloud publishes once an Order's Assets have
   been created.
5. **The renewal is handed from the event to an Order flow.** Salesforce doesn't allow a
   platform event-triggered flow to call another flow, either as a Subflow element or as a flow
   Action (both were rejected at validation). The event flow therefore only checks a new
   **Assets Created** box on the Order. A record-triggered flow on Order does the renewal work,
   because record-triggered flows can call `createRenewalQuote` and the Fault Path Subflow as
   subflows.
2. **Seat count is `Asset.CurrentQuantity`, not `Asset.Quantity`.** On Revenue Cloud assets,
   `Quantity` is blank. The seat count lives on the Asset State Period and is rolled up to
   `CurrentQuantity` just after the Asset is inserted. The Asset flow therefore runs on create
   **or update** when Current Quantity is set or changes.
3. **Quote status is "Accepted".** The approved status on Quote in HTCDEV is `Accepted`.
   `Approved` isn't a value.
4. **The Closed Won trigger is its own flow.** It was briefly folded into `Opportunity - On
   Update - After Save` (the ResOps Contract Cleanup Case flow) as a Run Asynchronously path.
   That broke it in HTCDEV. An asynchronous path requires "only when a record is updated to
   meet the condition requirements", which can't be combined with `ISCHANGED`. With a combined
   "Contract *or* Closed Won" condition, moving from Contract to Closed Won doesn't count as
   newly meeting the criteria, so the automation never ran (seen on the "Hat-Trick Consulting-
   Test" Opportunity, 2 Nov 2026). The trigger is back in its own flow with a Closed Won-only
   condition. `Opportunity - On Update - After Save` is on this branch only as the unchanged
   `ResOps-automation` version (Contract Cleanup Case only, no Closed Won path), so it isn't
   listed in the Component Manifest.

### Opportunity - Closed Won - After Save (new flow)

`Opportunity_Closed_Won_After_Save` is a thin record-triggered flow on Opportunity update. Its
entry formula is all of:

- Run Flows is checked on the On/Off Switch
- the record type is **Subscription New**
- the Stage is **Closed Won**
- Closed Won Automation Complete is unchecked

**"Only when a record is updated to meet the condition requirements"** is on. Salesforce
requires it for a flow with a Run Asynchronously path. So the flow runs when an Opportunity
*moves into* that state, for example its Stage changing to Closed Won from any other Stage.
Editing other fields on a Closed Won Opportunity doesn't re-run it. Unchecking Closed Won
Automation Complete on a Closed Won Opportunity *does* re-run it (a deliberate admin re-run).

It calls the **Closed Won Revenue Automation** subflow with the Opportunity Id on the **Run
Asynchronously** path. The Stage change saves straight away for the user, and the Revenue Cloud
actions run in their own transaction afterwards.

### Closed Won Revenue Automation (new subflow)

`Closed_Won_Revenue_Automation` is an autolaunched subflow, called from `Opportunity - Closed Won - After Save`.

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

### Create Asset Order Event - Mark Order Assets Created (new flow)

`Create_Asset_Order_Event_Mark_Order_Assets_Created` is a platform-event-triggered flow on the
native **Create Asset Order Event** (`CreateAssetOrderEvent`). Its first decision only lets
through the final event for an Order (`IsLastEvent` = true), and only when Run Flows is checked.
This check is a decision because platform event-triggered flows can't filter in the Start
element. It then checks **Assets
Created** on the Order named in the event (`OrderIdentifier`) if it isn't already checked.
Nothing else happens here. The flow only listens to the event, so Revenue Cloud and any other
subscribers still receive it as normal.

### Order - Assets Created - Create Renewal (new flow)

`Order_Assets_Created_Create_Renewal` is a record-triggered after-save flow on Order update. It
runs on the **Run Asynchronously** path when all of these are true:

- Run Flows is checked
- Assets Created is checked (it only runs when the box *becomes* checked)
- the Order has a Quote

It then:

1. Gets the Order's Quote and the Quote's Opportunity. It only continues when that Opportunity
   is **Subscription New**, Closed Won Automation Complete is checked, and **Renewal
   Opportunity is blank**. This means each deal gets one renewal, and Orders from renewal or
   amendment quotes and manual Orders are skipped.
2. Finds the Assets created from the Order: Order Products → Asset Action Sources
   (`ReferenceEntityItemId`) → Asset Actions → Asset Ids. Asset has no direct link to its Order,
   so this is the reliable path.
3. Sets **Renewal Term** and **Renewal Term Unit** on the Order's Assets where they're blank,
   using the **Pricing Term** and **Pricing Term Unit** of the Order's Product Selling Model
   (Annual Subscription = 1 / Annual). Create Renewal Quote requires both on every Asset ("All
   assets in a request must have values for RenewalTermUnit and RenewalTerm"). Assetization
   leaves them blank, and neither the Contract nor the Product supplies them. Values already set
   on an Asset are kept. Found in HTCDEV on 2 Nov 2026.
4. Drops any Asset that is a **bundle component** of another Asset. Revenue Cloud stores bundle
   structure in **Asset Relationship** (the bundle Asset is `AssetId` and each component is
   `RelatedAssetId`). It leaves `Asset.ParentId` blank. Create Renewal Quote rejects component
   Assets ("the asset is a bundle component. Provide the top-level asset"), and it renews the
   components together with their bundle. Found in HTCDEV on 2 Nov 2026 with a Core Bundle
   quote.
5. Calls the native **Create Renewal Quote** flow (as a subflow) once with the top-level Asset
   Ids.
   Renewal dates are left to the flow's defaults (the term after the current one). This creates
   the renewal Opportunity and renewal Quote.
6. Sets up the renewal Opportunity:

   | Field | Value |
   |---|---|
   | Record Type | Subscription Renewal |
   | Name | `<original Opportunity name> - Renewal` |
   | Type | Existing Business |
   | Owner | Owner of the original Opportunity |
   | Contract | The Contract on the Order |
   | Previous Opportunity | The original Opportunity |

7. Sets **Renewal Opportunity** on the original Opportunity and clears Closed Won Automation
   Error (left over from any earlier failed renewal attempt).

If Create Renewal Quote reports a failure (`isSuccess` false), or any other step faults, the error
is written to Closed Won Automation Error on the original Opportunity and sent through the Fault
Path Subflow. Salesforce doesn't allow a fault path on a Subflow element. If Create Renewal Quote
throws an unhandled error instead of returning `isSuccess` false, the interview fails with the
standard flow error email.

### Asset - On Create or Update - After Save (new flow)

`Asset_On_Create_Or_Update_After_Save` is a record-triggered after-save flow on Asset. It runs on
create and update when all of these are true:

- Run Flows is checked
- the Asset has an Account and a Product
- the Asset's Product's Family is not **Platform Bundle** (subscriptions are created on the module Assets)
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

**Quote setup matters.** Each quote line must have a term-defined Product Selling Model (e.g.
**Annual Subscription**) with a Start Date and Subscription Term. Lines without one create
Assets with no end date, so the Beacon Subscriptions get a blank End Date and the Assets can't
be renewed.

**Happy path**

1. Create a Subscription New Opportunity and a Quote with two module products (e.g. ADC Module,
   Autoimmune Module), quantity 1 each, on Annual Subscription. Set the Quote Status to **Accepted**. Move the
   Opportunity to Contract, then to **Closed Won**.
2. Wait a minute and refresh. On the Opportunity, confirm Closed Won Automation Complete is
   checked, Closed Won Automation Error is blank and Contract is filled in.
3. Open the Contract. Confirm Status = Activated, it's linked to the Quote (Quote → Contract),
   and it has Contract Item Prices matching the quote lines' net unit prices.
4. Open the Order (Quote → Orders). Confirm there is exactly one Order, Status = Activated, with
   both products and the Contract filled in.
5. On the Account, confirm one Asset per product with Lifecycle Start/End Dates and Current
   Quantity 1.
   Then open the Order and confirm **Assets Created** is checked. If it isn't, the Create Asset
   Order Event wasn't received as the final event, and no renewal will be created.
6. On each Asset, confirm Renewal Term = 1 and Renewal Term Unit = Annual (set by the renewal
   flow), and one Beacon Subscription with Account and Asset filled in, Contact blank,
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

**Bundles**

- **Bundle quote:** repeat steps 1–7 with a Core Bundle quote (the bundle plus its modules, on
  Annual Subscription). Confirm Beacon Subscriptions are created on the module Assets and not on
  the Core Bundle Asset. Confirm the renewal is created without the "asset is a bundle
  component" error, and that the Renewal Quote contains the bundle and its modules.

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
13. **No re-trigger on other edits:** on a completed Closed Won Opportunity, edit another field
    (e.g. Next Step). Confirm nothing new is created.

**Scope checks**

14. Close Won a **Subscription Renewal** Opportunity. Confirm the automation doesn't run.
15. Raise an Asset's Current Quantity from 1 to 3 (as an admin, in a sandbox). Confirm exactly
    two more Beacon Subscriptions. Lower it and confirm none are deleted.
16. Confirm no Beacon Subscription is created on a Platform Bundle Asset.
17. Uncheck Run Flows, Close Won a test Opportunity, and confirm nothing runs. Re-check Run Flows
    afterwards.

**Access**

18. As a Beacon Salesforce Admin, confirm the four new Opportunity fields can be edited. As a
    persona user (e.g. Beacon Sales), confirm they're visible and read-only.

## Post Deployment Items

1. **Deploy order:** deploy the four Opportunity fields, the Order **Assets Created** field and
   the permission sets first, then the flows. The flows reference the new fields.
   `Closed_Won_Revenue_Automation` must be deployed before (or with)
   `Opportunity_Closed_Won_After_Save`.
2. **HTCDEV clean-up:** an earlier version of this branch deployed `Opportunity - On Update -
   After Save` to HTCDEV with a Closed Won path. Redeploy that flow from the `ResOps-automation`
   branch, or remove the Closed Won path in Flow Builder. Otherwise Closed Won Opportunities
   could call the automation twice. The subflow's checks stop duplicate records, but it's
   wasted work.
3. **Page layouts:** add Closed Won Automation Complete, Closed Won Automation Error, Renewal
   Opportunity and Previous Opportunity to the Opportunity layouts or the Beacon Opportunity
   Record Page. Add the **Renewal Opportunities** related list too.
4. **Gearset comparison:** when deploying the permission sets, include the Opportunity object
   (at least the four new fields) in the comparison. Otherwise Gearset strips the new field
   permissions.
5. **Create Contract override:** `Beacon - Create Contract From Quote` overrides the managed
   Create Contract From Quote flow. Confirm this is wanted before deploying it to UAT and Prod.
6. **Re-running a failed deal:** fix the cause shown in Closed Won Automation Error, then move
   the Opportunity off Closed Won and back. Alternatively, an admin can check and then uncheck
   Closed Won Automation Complete; unchecking it on a Closed Won Opportunity re-runs the
   automation. Existing Contracts and Orders are reused, so nothing is duplicated. If the renewal step failed (the Contract and Order are done), raise it with the admin
   team: with Renewal Opportunity blank, uncheck and re-check **Assets Created** on the Order, or do a manual
   Renew from the Assets.
7. **Review `Order - Create Assets`:** see the note above about its Test element.
8. **Existing deals:** Assets and Opportunities from before this build don't get subscriptions or
   renewals automatically. Data load subscriptions where needed, and renew existing Assets
   manually.

9. **Annual Subscription price book entries (data, per org).** Quote lines only get a term
   (Start/End Date, Subscription Term) when they're priced from a price book entry with a
   term-defined Product Selling Model. In HTCDEV, most entries had no selling model, so quotes
   created Assets with no end date that couldn't be renewed. On 2 Nov 2026, 110 **Annual
   Subscription** entries were created in HTCDEV. There's one for every product that had an
   active entry with no selling model in each price book (Standard: the 5 bundles; <50 Heads,
   51-200 Heads, Contract Orgs (>200 Heads) and PE-VC: all 22 products; >200 Heads: the 17
   modules). Each copies the price of the existing entry. The 110 matching entries with no
   selling model were then **deactivated** (not deleted, so existing quote lines keep their
   link), so reps can't pick a term-less entry. The 17 Standard Price Book module entries with no
   selling model are still active, because they already had Annual Subscription twins and
   weren't part of this change. After the change, **re-run the pricing sync** so Revenue Cloud
   prices from the Annual Subscription entries, and use a new quote: existing quote lines stay on
   the old entries. Repeat all of this in **UAT and Prod** before testing there.

## Component Manifest

Github Branch: https://github.com/aaroncrear/BeaconImplementation/tree/Renewal-Automation

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Flow | Opportunity | Opportunity_Closed_Won_After_Save | Opportunity - Closed Won - After Save | Created | Record-triggered (update) flow. When a Subscription New Opportunity moves to Closed Won with Closed Won Automation Complete unchecked, calls Closed Won Revenue Automation on the Run Asynchronously path. |
| 2 | Flow | Opportunity | Closed_Won_Revenue_Automation | Closed Won Revenue Automation | Created | Autolaunched subflow. Creates (or reuses) and activates the Contract (native createContract, net unit prices) and Order (native createOrdersFromQuote) from the Accepted Quote, then marks the Opportunity complete. Errors go to the Opportunity and the fault email. |
| 3 | Flow | CreateAssetOrderEvent | Create_Asset_Order_Event_Mark_Order_Assets_Created | Create Asset Order Event - Mark Order Assets Created | Created | Platform-event flow. On the final Create Asset Order Event for an Order, checks Assets Created on the Order. |
| 4 | Flow | Order | Order_Assets_Created_Create_Renewal | Order - Assets Created - Create Renewal | Created | Record-triggered flow (async path). When Assets Created becomes checked, calls native Create Renewal Quote with the Order's Assets, sets up the renewal Opportunity and links it to the original. |
| 5 | Field | Order | Assets_Created__c | Assets Created | Created | Checkbox. Checked when Revenue Cloud has created the Order's Assets. Hands off from the platform event flow to the renewal flow. |
| 6 | Flow | Asset | Asset_On_Create_Or_Update_After_Save | Asset - On Create or Update - After Save | Created | Record-triggered flow. Creates one Beacon Subscription per missing seat (Current Quantity minus existing) with Asset, Account, Start and End Date. Excludes Platform Bundle Assets. |
| 7 | Flow | Quote | Beacon_Create_Contract_From_Quote | Beacon - Create Contract From Quote | Created | Unmanaged clone of rev_contracts__CreateCntrFromQuote (screen flow, overrides it). Added by Aaron so the createContract action could be read. Not called by the automation. |
| 8 | Field | Opportunity | Closed_Won_Automation_Complete__c | Closed Won Automation Complete | Created | Checkbox. Set once the Contract and Order are created and activated. Prevents duplicate runs. |
| 9 | Field | Opportunity | Closed_Won_Automation_Error__c | Closed Won Automation Error | Created | Long Text Area. Error from the last failed run. |
| 10 | Field | Opportunity | Renewal_Opportunity__c | Renewal Opportunity | Created | Lookup(Opportunity), Set Null. On the original Opportunity, its renewal Opportunity. |
| 11 | Field | Opportunity | Previous_Opportunity__c | Previous Opportunity | Created | Lookup(Opportunity), Set Null. On a renewal Opportunity, the Opportunity it renews. |
| 12 | Permission Set | Opportunity | Beacon_Consulting_Object_Tab_FLS | Beacon Consulting - Object, Tab, FLS | Updated | Read FLS on the four new Opportunity fields. |
| 13 | Permission Set | Opportunity | Beacon_Customer_Success_Object_Tab_FLS | Beacon Customer Success - Object, Tab, FLS | Updated | Read FLS on the four new Opportunity fields. |
| 14 | Permission Set | Opportunity | Beacon_Executive_Object_Tab_FLS | Beacon Executive - Object, Tab, FLS | Updated | Read FLS on the four new Opportunity fields. |
| 15 | Permission Set | Opportunity | Beacon_Finance_Object_Tab_FLS | Beacon Finance - Object, Tab, FLS | Updated | Read FLS on the four new Opportunity fields. |
| 16 | Permission Set | Opportunity | Beacon_Marketing_Object_Tab_FLS | Beacon Marketing - Object, Tab, FLS | Updated | Read FLS on the four new Opportunity fields. |
| 17 | Permission Set | Opportunity | Beacon_Product_Object_Tab_FLS | Beacon Product - Object, Tab, FLS | Updated | Read FLS on the four new Opportunity fields. |
| 18 | Permission Set | Opportunity | Beacon_ResOps_Object_Tab_FLS | Beacon ResOps - Object, Tab, FLS | Updated | Read FLS on the four new Opportunity fields. |
| 19 | Permission Set | Opportunity | Beacon_Sales_Object_Tab_FLS | Beacon Sales - Object, Tab, FLS | Updated | Read FLS on the four new Opportunity fields. |
| 20 | Permission Set | Opportunity | Beacon_Salesforce_Admin_Object_Tab_FLS | Beacon Salesforce Admin - Object, Tab, FLS | Updated | Read + Edit FLS on the four new Opportunity fields. |
| 21 | Permission Set | Opportunity | Beacon_Tech_Object_Tab_FLS | Beacon Tech - Object, Tab, FLS | Updated | Read FLS on the four new Opportunity fields. |
