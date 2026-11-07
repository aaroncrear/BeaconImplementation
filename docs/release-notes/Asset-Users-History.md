# Asset-Users-History – Release Notes

## Requirements

- A module's Number of Users can change from year to year (at renewal) or during the term (amendment). That change needs to be visible in the Asset's history, not just the current value.
- Record **Number of Users** on each **Asset Action** and on each **Asset State Period** (the asset's time periods).
- Record **Change in Users** on each **Asset Action**.
- Keep the fields up to date automatically.

## Release Notes

### Why this was needed

Modules are sold with Quantity 1 and the users in **Number of Users**, because Beacon prices by user tier and module count, not per user. Revenue Cloud's asset history (Asset Actions and Asset State Periods) tracks Quantity, Amount and MRR, so it recorded price changes but never the user count. Asset → Number of Users only holds the current value.

### What was built

**New fields** (Number, read-only for everyone except the Salesforce Admin persona):

| Object | Field | Meaning |
|---|---|---|
| Asset Action | **Number of Users** | Users on the module after this action. 0 for a cancellation. |
| Asset Action | **Change in Users** | This action's Number of Users minus the Asset's Number of Users before it, e.g. +15 at a renewal from 10 to 25. On the initial sale it equals Number of Users. |
| Asset State Period | **Number of Users** | Users on the module during that period. |

**Automation.** The existing flow **Create Asset Order Event - Mark Order Assets Created** already ran after Revenue Cloud creates or updates the Assets for any Order (new business, renewal or amendment), and already matched each Order Product to its Asset Action and Asset. It now also:

1. Reads each Asset's Number of Users **before** the Order (blank for a new Asset).
2. Sets **Number of Users** and **Change in Users** on the Asset Action from the Order Product.
3. Sets **Number of Users** on the Asset's State Periods that start on or after the action's start date. A renewal or amendment starts a new period on that date, so earlier periods keep their old user count.
4. Updates **Asset → Number of Users** as before, which keeps creating the Beacon Subscriptions.

**Cancellations** record 0 users and a negative Change in Users on the action and the periods from the cancellation date, but leave Asset → Number of Users and its Beacon Subscriptions unchanged.

This was added to the existing flow rather than a new one, because that flow already walks Order Product → Asset Action Source → Asset Action → Asset at the point where Revenue Cloud has finished building the asset history.

### Asset → Number of Users stays

It's still the current value that renewal quote lines copy, that creates the Beacon Subscriptions (one per seat), and that Change in Users is measured against. The new fields add the history alongside it.

### Backfill

`scripts/apex/Asset_Users_History_Backfill.apex` fills the new fields for existing Asset Actions and State Periods from their Order Products, using the same rules. Set `PREVIEW = true` to check the counts first.

## Acceptance Criteria

1. **New business.** Close Won a Subscription New Opportunity whose Approved quote has ADC at 5 users and Oncology at 12 users. When the Order's Assets are created, open the ADC Asset → Asset Actions. Confirm the Initial Sale action shows Number of Users 5 and Change in Users 5. Open its Asset State Period and confirm Number of Users 5. Repeat for Oncology (12 / 12).
2. **Renewal with more users.** On the renewal Opportunity's quote, change ADC to 8 users, approve it and Close Won it. When the renewal Order's Assets are updated, confirm:
   - the ADC Renewal action shows Number of Users 8 and Change in Users 3;
   - the first-year State Period still shows 5 and the renewal-year period shows 8;
   - Asset → Number of Users is 8 and the Asset has 8 Beacon Subscriptions.
3. **Renewal with fewer users.** Renew Oncology from 12 to 10. Confirm Change in Users is -2 and the new period shows 10.
4. **Renewal with no change.** Renew a module with the same users. Confirm Change in Users is 0 and the new period shows the same Number of Users.
5. **Mid-term amendment.** Amend a module's users mid-term (e.g. 8 → 10). Confirm the Amendment action shows 10 / +2, the period from the amendment date shows 10 and the period before it keeps 8.
6. **Cancellation.** Cancel a module. Confirm the Cancellation action shows Number of Users 0 and Change in Users equal to minus the previous users, and that Asset → Number of Users and its Beacon Subscriptions are unchanged.
7. **Backfill.** In an org with existing Assets, run the backfill script with `PREVIEW = true`, check the counts in the debug log, then run it with `PREVIEW = false`. Confirm existing Initial Sale and Renewal actions and periods have Number of Users.
8. **Access.** As a Sales user, open an Asset Action and an Asset State Period. Confirm the new fields are visible and can't be edited.

## Post Deployment Items

1. **Page layouts and related lists.** Add **Number of Users** and **Change in Users** to the Asset Action page layout and to the Asset Actions related list on the Asset page; add **Number of Users** to the Asset State Period layout and its related list on the Asset page (Setup → Object Manager → Asset Action / Asset State Period → Page Layouts; Asset → Lightning page). These layouts aren't in the repository yet. Retrieve them with Gearset afterwards so the next org gets them by deployment.
2. **Backfill.** Run `scripts/apex/Asset_Users_History_Backfill.apex` once in each org after the deploy (Developer Console → Execute Anonymous).
3. **Gearset.** The ten persona permission sets are deployed for the new field permissions only. Select just the new Asset Action and Asset State Period field permissions in the comparison, so other differences in those permission sets aren't deployed with them.

## Component Manifest

Github Branch: [Asset-Users-History](https://github.com/aaroncrear/BeaconImplementation/tree/Asset-Users-History)

Package manifest: `manifest/Asset-Users-History-package.xml`

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | CustomField | AssetAction | Number_of_Users__c | Number of Users | Created | Users on the module after this action; 0 for a cancellation. Set by flow. |
| 2 | CustomField | AssetAction | Change_in_Users__c | Change in Users | Created | This action's Number of Users minus the Asset's Number of Users before it. Set by flow. |
| 3 | CustomField | AssetStatePeriod | Number_of_Users__c | Number of Users | Created | Users on the module during the period. Set by flow. |
| 4 | Flow | CreateAssetOrderEvent | Create_Asset_Order_Event_Mark_Order_Assets_Created | Create Asset Order Event - Mark Order Assets Created | Updated | Also sets Number of Users and Change in Users on each Asset Action and Number of Users on the Asset State Periods from the action's start date; cancellations record 0 and leave the Asset unchanged. |
| 5 | PermissionSet | — | Beacon_Consulting_Object_Tab_FLS | Beacon Consulting - Object, Tab, FLS | Updated | Read access to the three new fields. |
| 6 | PermissionSet | — | Beacon_Customer_Success_Object_Tab_FLS | Beacon Customer Success - Object, Tab, FLS | Updated | Read access to the three new fields. |
| 7 | PermissionSet | — | Beacon_Executive_Object_Tab_FLS | Beacon Executive - Object, Tab, FLS | Updated | Read access to the three new fields. |
| 8 | PermissionSet | — | Beacon_Finance_Object_Tab_FLS | Beacon Finance - Object, Tab, FLS | Updated | Read access to the three new fields. |
| 9 | PermissionSet | — | Beacon_Marketing_Object_Tab_FLS | Beacon Marketing - Object, Tab, FLS | Updated | Read access to the three new fields. |
| 10 | PermissionSet | — | Beacon_Product_Object_Tab_FLS | Beacon Product - Object, Tab, FLS | Updated | Read access to the three new fields. |
| 11 | PermissionSet | — | Beacon_ResOps_Object_Tab_FLS | Beacon ResOps - Object, Tab, FLS | Updated | Read access to the three new fields. |
| 12 | PermissionSet | — | Beacon_Sales_Object_Tab_FLS | Beacon Sales - Object, Tab, FLS | Updated | Read access to the three new fields. |
| 13 | PermissionSet | — | Beacon_Salesforce_Admin_Object_Tab_FLS | Beacon Salesforce Admin - Object, Tab, FLS | Updated | Read and edit access to the three new fields. |
| 14 | PermissionSet | — | Beacon_Tech_Object_Tab_FLS | Beacon Tech - Object, Tab, FLS | Updated | Read access to the three new fields. |
| 15 | Apex script | AssetAction, AssetStatePeriod | scripts/apex/Asset_Users_History_Backfill.apex | Asset Users History Backfill | Created | One-time backfill of the new fields for existing Asset Actions and State Periods. |
