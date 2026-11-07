# Beacon Pricing & Renewals – Production Deployment Guide

_Branch: `Pricing-Model-Rebuild` · Target: **Beacon Production** · Last updated: 2026-11-06_

Work top to bottom. Steps marked **Claude** are done by Claude via the Production connection — tell Claude when the step before is finished.

---

## 0. Already done in Production (by Claude)

| # | Item | Detail |
|---|---|---|
| 0.1 | Old seat-band and escalator pricing removed | Deleted 7 Price Adjustment Schedules (6 "Seat Band Pricing" + "Top 1-50 Pharma - Multi-Year Term Escalation") and their 238 tiers |
| 0.2 | Bundles retired | Deactivated the 5 bundle products (Entry Level, Starter, Core, Pro, Platform) and their 25 price book entries. Not deleted – recoverable |
| 0.3 | Number of Users attribute | Attribute Definition **Number of Users** (`Number_of_Users`, Number) |
| 0.4 | Beacon Module classification | Product Classification **Beacon Module** with Number of Users (required, price impacting, Number display) |
| 0.5 | 17 modules set up | All 17 modules based on **Beacon Module**, Configure During Sale = **Allowed** |

Production had no quote lines, so nothing existing was affected.

---

## 1. Deploy the metadata (Gearset)

Deploy from branch **`Pricing-Model-Rebuild`** to **Beacon Production** using the manifest **`manifest/Production-Pricing-and-Renewals-package.xml`** (92 components). Use **Run specified tests / no tests** as your Production policy allows (no Apex in this package).

| Type | Components |
|---|---|
| **Custom objects (3) + tabs (3)** | `Beacon_Tier_Price__c`, `Beacon_Module_Count_Price__c`, `Beacon_Multi_Module_Discount__c` |
| **Beacon Tier Price fields** | `Price_Book__c`, `Product__c`, `Tier__c`, `Adjustment_Type__c`, `Adjustment_Value__c` (label *Price*), `Price_Key__c` |
| **Beacon Module Count Price fields** | `Price_Book__c`, `Module_Level__c`, `User_Band__c`, `Min_Modules__c`, `Max_Modules__c`, `Min_Tier__c`, `Max_Tier__c`, `Quote_Total__c`, `Adjustment_Type__c`, `Adjustment_Value__c` (label *Price Per Line*), `Price_Key__c` |
| **Beacon Multi-Module Discount fields** | `Price_Book__c`, `Min_Modules__c`, `Max_Modules__c`, `Adjustment_Type__c`, `Adjustment_Value__c` (label *Discount %*), `Price_Key__c` |
| **Quote fields** | `Max_Number_of_Users__c`, `Lines_With_Users__c`, `Lines_Missing_Users__c`, `Lines_Wrong_Quantity__c`, `Pricing_Module_Count__c`, `Pricing_Max_Users__c` |
| **Quote Line Item fields** | `Number_of_Users__c`, `Pricing_Tier__c` |
| **Opportunity Product / Order / Order Product / Asset fields** | `OpportunityLineItem.Number_of_Users__c`; `Order.Assets_Created__c`, `Order.Pricing_Module_Count__c`, `Order.Pricing_Max_Users__c`; `OrderItem.Number_of_Users__c`, `OrderItem.Pricing_Tier__c`; `Asset.Number_of_Users__c` |
| **Opportunity fields** | `Closed_Won_Automation_Complete__c`, `Closed_Won_Automation_Error__c`, `Previous_Opportunity__c`, `Renewal_Opportunity__c` |
| **Validation rules (6)** | `Quote.Lines_Valid_Before_Leaving_Draft`, `Quote.Closed_Won_Quote_Locked`, `QuoteLineItem.Quantity_Must_Be_One`, `QuoteLineItem.Number_of_Users_At_Least_One`, `OpportunityLineItem.Quantity_Must_Be_One`, `Opportunity.Closed_Opportunity_Locked` |
| **Flows (17)** | Pricing: `Quote_Line_Item_On_Create_Before_Save`, `Quote_Line_Item_On_Create_Update_After_Save`, `Opportunity_Product_On_Create_Before_Save`, `Order_Product_On_Create_Before_Save`. Renewals / Closed Won: `Closed_Won_Revenue_Automation`, `Opportunity_Closed_Won_After_Save`, `Opportunity_On_Create_After_Save`, `Opportunity_On_Update_After_Save`, `Quote_On_Create_Before_Save`, `Quote_Create_Order_Screen_Flow`, `Beacon_Create_Contract_From_Quote`, `Contract_On_Create_Before_Save`, `Order_On_Create_Before_Save`, `Order_Create_Assets`, `Create_Asset_Order_Event_Mark_Order_Assets_Created`, `Order_Assets_Created_Create_Renewal`, `Asset_On_Create_Or_Update_After_Save` |
| **Layouts (5)** | Quote, Quote Line Item, Opportunity Product, Order Product, Asset |
| **Permission sets (12)** | The 10 persona `Beacon_*_Object_Tab_FLS` sets, plus `Edit_Closed_Opportunities`, `Edit_Closed_Won_Quotes` |
| **Permission set groups (2)** | `Beacon_Revenue_Cloud_User` (17 Salesforce Revenue Cloud permission sets for quoting through renewal), `Beacon_Revenue_Cloud_Admin` (14 setup/designer permission sets) |
| **Custom permissions (2)** | `Edit_Closed_Opportunities`, `Edit_Closed_Won_Quotes` |

> **Check the Gearset comparison before deploying.** Layouts, permission sets and `Opportunity_On_Create_After_Save` already exist in Production and deploy as whole files. If Gearset shows differences you don't recognise (changes made directly in Production), stop and tell Claude.

**Not deployed on purpose** (built during testing, no longer used): `Quote_Pricing_Complete_Sync_Number_of_Users` flow; fields `QuoteLineItem.Pricing_Users__c`, `QuoteLineItem.User_Tier__c`, `Quote.Module_Count__c`, `Pricebook2.Pricing_Method__c`; the Scratch Test and Beacon Pricing Test procedures; HTCDEV-only scripts. The pricing procedure is deployed separately in step 5 (it needs Production IDs).

After the deploy: **Setup → Flows** – confirm the 17 flows are **Active**.

---

## 2. Load the price data (Developer Console, Production)

**Developer Console → Debug → Open Execute Anonymous Window.** Run the 8 scripts in `scripts/apex/production/` **in order** (each is small enough for the console):

| # | Script | Loads |
|---|---|---|
| 1–6 | `1_…` to `6_Load_Tier_Prices_…` | 102 tier prices per price book (612 total) |
| 7 | `7_Load_Module_Count_Prices_Less_Than_50_51_200_PE_VC` | 136 Module Count prices |
| 8 | `8_Load_Module_Count_Contract_Orgs_Discounts_Tier1_Prices` | 85 Module Count prices, 32 discount rows, and sets each module's price book entry to its Tier 1 price (68 entries are £0 today) |

Each script is safe to re-run. Tell Claude when done – **Claude** checks the counts (612 / 221 / 32, no £0 entries).

---

## 3. Context definition (Setup → Context Definitions → SalesTransactionContextAuto)

No need to deactivate (it's referenced by rules). Same screens as HTCDEV.

**3a. Attributes** – **Edit** → Next to the attributes step → select the node → **Add Attributes** (Type **INPUT OUTPUT**, Data Type **NUMBER**):

| Node | Attribute name |
|---|---|
| SalesTransactionItem | `BeaconTier` |
| SalesTransactionItem | `BeaconUsers` |
| SalesTransaction | `BeaconModuleCount` |
| SalesTransaction | `BeaconMaxUsers` |

**3b. Tags** – **Context Tags** tab → give each the same name as a tag (Salesforce adds `__c`).

**3c. Mappings** – **Map Data → Edit SObject Mapping**, then **Save and Publish**:

| Attribute | QuoteEntitiesMapping | OrderEntitiesMapping |
|---|---|---|
| `BeaconTier__c` | QuoteLineItem `Pricing_Tier__c` | OrderItem `Pricing_Tier__c` |
| `BeaconUsers__c` | QuoteLineItem `Number_of_Users__c` | OrderItem `Number_of_Users__c` |
| `BeaconModuleCount__c` | Quote `Pricing_Module_Count__c` | Order `Pricing_Module_Count__c` |
| `BeaconMaxUsers__c` | Quote `Pricing_Max_Users__c` | Order `Pricing_Max_Users__c` |

Tell Claude – **Claude** checks attributes, tags and all 8 mappings.

---

## 4. Decision tables (Setup → Decision Tables → New) – after step 2

For all three: **Usage Type** Pricing (Default Pricing) · **Source** Single Object · **Filter Result By** Output Order (or First Match) · **Consider Null Value** off · then **Save → Activate → Refresh**.

| Decision table (name) | Object | Conditions (field – operator) | Outputs |
|---|---|---|---|
| **Beacon Tier Price** | Beacon Tier Price | Price Book – Equals · Product – Equals · Tier – Equals | Adjustment Type, Adjustment Value (`Adjustment_Value__c`) |
| **Beacon Module Count Price** | Beacon Module Count Price | Price Book – Equals · Min Modules – Equals · Max Modules – Equals · Min Tier – Greater Or Equal · Max Tier – Less Or Equal | Adjustment Type, Adjustment Value (`Adjustment_Value__c`), Quote Total |
| **Beacon Multi-Module Discount** | Beacon Multi-Module Discount | Price Book – Equals · Min Modules – Equals · Max Modules – Equals | Adjustment Type, Adjustment Value (`Adjustment_Value__c`) |

Use exactly these names (the pricing procedure refers to their API names `Beacon_Tier_Price`, `Beacon_Module_Count_Price`, `Beacon_Multi_Module_Discount`). Tell Claude when all three are active.

**Claude** then: registers the three tables to **Price Adjustment Matrix** in the Pricing Recipe, and builds the Production pricing procedure zip with the Production IDs.

---

## 5. Pricing procedure (Workbench)

1. **workbench.developerforce.com** → Environment **Production** → log in.
2. **migration → Deploy** → `Beacon_Pricing_Procedure_PROD.zip` (from Claude) → **Single Package unticked**, **Rollback On Error ticked**, Test Level **RunLocalTests** (Production refuses NoTestRun) → Deploy.
3. **Builder edits (before activating)** – open **Beacon Pricing Procedure V1** in the builder:
   - Add a **Formula Based Pricing** step directly **above BeaconSetLineTier**: Formula `IF(BeaconUsers__c >= 1, BeaconUsers__c, VALUE(AttributeValue))`, Output Variable `BeaconUsers__c`, tick **Exclude Price Waterfall**.
   - Change **BeaconSetLineTier**'s formula to `IF(BeaconUsers__c >= 51, 6, IF(BeaconUsers__c >= 21, 5, IF(BeaconUsers__c >= 11, 4, IF(BeaconUsers__c >= 6, 3, IF(BeaconUsers__c >= 4, 2, 1)))))`.
   - **Save.** (The zip deploys the attribute-based version because the field-based one fails to deploy with *Property 'dataType' not valid*; these two edits are the difference, same as HTCDEV V3.)
4. **Setup → Pricing Procedures → Beacon Pricing Procedure → V1 → Activate.**
5. **Revenue Settings** → pricing procedure → **Beacon Pricing Procedure**.
6. **Salesforce Pricing Setup** → default pricing procedure → **Beacon Pricing Procedure**.
7. **Salesforce Pricing Setup** → **Turn On Price Waterfall Persistence** (leave the API waterfall and Price Tracking History off).
8. **Sync Pricing Data** and wait for it to finish.

If the deploy fails, send Claude the *problem* line. Fallback: Claude gives builder steps (same 7 Beacon steps you built in HTCDEV Scratch Test).

---

## 6. Quote page – Number of Users column

Open any quote → ⚙ → **Edit Page** → click the **Quote Line Items** (Transaction Line Editor) component → in its column setting add **Number of Users** → **Save**. (Same setting you found in HTCDEV.)

---

## 7. Quantity = 1 configuration rule (Browse Catalogs warning)

1. Assign yourself the permission sets used in HTCDEV for rule building (**Product Configuration Rules Designer**, **BRE Designer** and the Context Service designer set, as offered).
2. **Rule Library**: create **Beacon Configuration Rules**, version **V1**, activate it.
3. **Sub-Type Mapping**: `PC_ProductBasedOn` → `ProductBasedOn` (lets a rule target the Beacon Module classification).
4. **Product Configuration Rule** "Beacon Module Quantity Must Be 1" – Usage Sub Type **Product Classification**, effective to 2099:
   - **Condition:** Product Classification (ProductBasedOn) **equals Beacon Module**, and Quantity (ItemDetailQuantity) **not equals 1**.
   - **Action:** Validate, message *"Quantity must be 1. Enter the number of users in Number of Users."* – set the action's **target to the Beacon Module classification**, not to a single product. (HTCDEV's rule has the right condition but its action targets ADC only.)
   - Validate → Activate.

If the classification scope isn't offered, add the 17 modules to the same rule and tell Claude.

---

## 7b. Revenue Settings – order creation

**Setup → Revenue Settings** → turn on **Advanced Order Creation From Quote** (top of the page). Without it, the Closed Won automation's Create Orders step fails with *"Can't create an order from this type of quote."* Leave **Set Up Flow for Creating Orders from Quotes**, **Managing Assets** and **Creating Contracts from Quotes** as they are (they match HTCDEV).

## 8. Users and permissions

- **Permission set licenses first.** A group can only be assigned to users who hold the licenses of its permission sets. For **Beacon - Revenue Cloud User**: Revenue Cloud User, Product Catalog Management Viewer, Product Discovery User, Salesforce Pricing Run Time, Product Configuration User, Business Rules Engine Runtime, Context Service Runtime, Decimal Quantity Runtime User, Fulfillment User PSL, DocGen Designer, OmniStudio. Admins additionally need: Product Catalog Management Administrator, Salesforce Pricing Design Time, Business Rules Engine Designer, Context Service Admin, Decimal Quantity DesignTime User.
- Assign **Beacon - Revenue Cloud User** to everyone who quotes; assign **Beacon - Revenue Cloud Admin** *and* the User group to Revenue Cloud admins.

- Confirm reps have their persona `Beacon_*_Object_Tab_FLS` permission set (new fields are included).
- Assign **Edit Closed Opportunities** / **Edit Closed Won Quotes** only to the people allowed to change closed records.
- **Setup → Custom Settings → On/Off Switch**: confirm **Run Flows** is on (the renewal flows check it).

---

## 9. Test in Production

Create quotes in Browse Catalogs (set Number of Users in the gear), then check in the line editor. Tell Claude the quote names – **Claude** checks every line.

| # | Price book | Lines (users) | Expected |
|---|---|---|---|
| 1 | <50 Heads | ADC 4, Oncology 2 | £13,000 + £13,000 = **£26,000** |
| 2 | <50 Heads | ADC 3, Oncology 2 | £11,500 + £11,500 = **£23,000** |
| 3 | Top 1-50 Pharma | ADC 3, Oncology 8 | £54,000 + £139,500 = **£193,500** (10% off) |
| 4 | Contract Orgs (>200 Heads) | ADC 3, Autoimmune 15 | £75,000 + £75,000 = **£150,000** |
| 5 | Contract Orgs (>200 Heads) | 4 modules, highest 40 users | 4 × £62,500 = **£250,000** |
| 6 | Any | Change a line's users in the **column** | Price updates on repricing |
| 7 | Any | Manual 10% discount on a line | Applied on top of the Beacon price |
| 8 | Closed Won → Order → Assets | Any quote | Assets carry Number of Users; Beacon Subscriptions created; renewal opportunity created |

---

## Reference – Production IDs

| Item | Id |
|---|---|
| Number of Users attribute | `0tjQ300000001P7IAI` |
| Beacon Module classification | `11BQ300000DmB89MAF` |
| <50 Heads / 51-200 Heads / PE-VC | `01sQ300000dyjIOIAY` / `01sQ300000dypFkIAI` / `01sQ300000dykxiIAA` |
| Contract Orgs (>200 Heads) / >200 Heads / Top 1-50 Pharma | `01sQ300000dyv4zIAA` / `01sQ300000dyv1lIAA` / `01sQ300000dyuyXIAQ` |
| Pricing Recipe (NGPDefaultRecipe) | `12GQ3000002KA8XMAW` |
