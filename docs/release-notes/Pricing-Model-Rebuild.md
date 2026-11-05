# "Pricing-Model-Rebuild" – Release Notes

## Requirements

- Remove every bundle that was built in Revenue Cloud and start over. Reps sell each module on its own quote line.
- Every product is sold at **Quantity 1**. The number of users is captured in a new field, not in Quantity.
- Price modules from user tiers (slab pricing) using the Rev Ops price sheets. Each tab of the sheet is a price book.
- Users are always entered on the quote line, as **Number of Users**.
- Number of Users must be reportable on the Quote Line, Opportunity Product, Order Product and Asset, and must carry through to the Asset.
- Beacon Subscriptions are created from the Asset's Number of Users (one per user), instead of from quantity.
- Renewal quotes start with the Asset's Number of Users.
- Price books that didn't have bundles (**Top 1-50 Pharma**, **>200 Heads**) price each module from its own Number of Users. Tiers: 1–3, 4–5, 6–10, 11–20, 21–50, 51+ users.
- On those two price books, apply an automatic multi-module discount to every module line: 2 modules = 10%, 3 = 20%, 4 or more = 30%.
- Price books that had bundles (**<50 Heads**, **51-200 Heads**, **PE-VC**, **Contract Orgs (>200 Heads)**) price the whole quote from the number of modules and the **highest** Number of Users on any module. When one module moves into a higher user band, every module on the quote moves with it.
- Module levels on those price books: 1 module = Entry, 2 = Starter, 3–4 = Core, 5 = Pro, 6 or more = Platform. These are price points, not bundles.
- Remove all multi-year escalators from every price book.
- Price books are still chosen by the rep. Salesforce doesn't produce customer pricing documents, because Rev Ops builds those in PowerPoint.

The design was reviewed with Rev Ops in the Beacon Pricing Model Rebuild guide, which includes a quote calculator that follows these rules.

## Release Notes

### How pricing works now

Each price book has a new **Pricing Method** field (`Pricebook2.Pricing_Method__c`):

| Price book | Pricing Method | Users that set the price | User bands | Multi-module pricing |
|---|---|---|---|---|
| Top 1-50 Pharma | Per Module | Each line's own Number of Users | 1–3 · 4–5 · 6–10 · 11–20 · 21–50 · 51+ | 10 / 20 / 30% discount |
| >200 Heads | Per Module | Each line's own Number of Users | 1–3 · 4–5 · 6–10 · 11–20 · 21–50 · 51+ | 10 / 20 / 30% discount |
| <50 Heads | Module Count | Highest Number of Users on the quote | 1–3 · 4+ | Built into the total |
| 51-200 Heads | Module Count | Highest Number of Users on the quote | 1–3 · 4–10 · 11+ | Built into the total |
| PE-VC | Module Count | Highest Number of Users on the quote | 1–5 · 6–10 · 11+ | Built into the total |
| Contract Orgs (>200 Heads) | Module Count | Highest Number of Users on the quote | 1–5 · 6–10 · 11–20 · 21–50 · 51+ | Built into the total |

**Quote line fields.** Reps enter **Number of Users** (`QuoteLineItem.Number_of_Users__c`) on every line. Two formula fields work out the price tier:

- **Pricing Users** (`Pricing_Users__c`) is the line's own Number of Users on Per Module price books, and the quote's **Max Number of Users** on Module Count price books.
- **User Tier** (`User_Tier__c`) turns Pricing Users into Tier 1–6: 1–3, 4–5, 6–10, 11–20, 21–50, 51+.

Splitting this into two formulas keeps each one short and easy to read. Every price book's bands line up with these six tiers. For example, the 51-200 Heads band "Up to 10 users" (4–10) is Tiers 2 and 3, so one tier field works for every price book.

**Quote roll-ups.** **Max Number of Users** (`Quote.Max_Number_of_Users__c`, roll-up MAX of line users) and **Module Count** (`Quote.Module_Count__c`, roll-up COUNT of lines) show reps the numbers that drive Module Count pricing and the multi-module discount.

**Why the highest line and not a total:** the same people usually use several modules. On Contract Orgs, ADC for 3 users plus Cell Therapy for 8 users is 8 people, which is the "Up to 10 users" band. Two modules is Starter, so the total is £100,000. Adding the lines up (11 users) would wrongly move the quote to "Up to 20 users" (£150,000).

### Price tables Rev Ops maintains

The prices live in three new custom objects, so Rev Ops can change a price by editing a record instead of rebuilding price adjustment schedules. Each has a tab for Salesforce Admins.

| Object | Rows | What one row is |
|---|---|---|
| **Beacon Tier Price** (`Beacon_Tier_Price__c`) | 612 | List price for one module, on one price book, at one tier (6 books × 17 modules × 6 tiers) |
| **Beacon Module Count Price** (`Beacon_Module_Count_Price__c`) | 65 | Quote total for one module level and one user band on a Module Count price book |
| **Beacon Multi-Module Discount** (`Beacon_Multi_Module_Discount__c`) | 6 | Discount for 2, 3 and 4+ modules on each Per Module price book |

Each row has a unique **Price Key** (for example `Contract Orgs (>200 Heads)|Starter|Up to 10 users`). That makes the load script safe to run again: it updates rows instead of creating duplicates.

On Module Count price books, each module line keeps its list price from the tier table. A pricing adjustment then brings the lines down to the module count total, split evenly across the lines. Every module has the same list price on these books, so the split is always even. On those books, the Entry row (1 module) is the same as the per-module list price, so a single module gets no adjustment.

### Quantity and users rules

- **Quantity Must Be One** validation rules on Quote Line Item and Opportunity Product block any quantity other than 1.
- **Number of Users At Least One** on Quote Line Item blocks a value below 1. A blank value is allowed, because **Browse Catalogs adds lines without it**: Browse Catalogs saves new lines as soon as products are added, and it can't show or require a custom quote line field. A rule that required the field on every line would stop reps adding products.
- **Lines Missing Users** (`Quote.Lines_Missing_Users__c`) counts the lines with no Number of Users. **Users Required Before Leaving Draft** on Quote blocks any Status change away from Draft while that count is above 0. Reps enter users in the quote line editor after adding products. A line with no users has no User Tier, so it isn't priced from the tier table until users are entered.

### Number of Users from quote to Asset and renewal

Number of Users is a number field at every step, so it can be reported on and summed at each level.

| Step | How it gets there |
|---|---|
| Quote Line → Opportunity Product | `Quote Line Item - On Create or Update - After Save` and `Opportunity Product - On Create - Before Save` (standard Quote sync doesn't copy custom fields) |
| Quote Line → Order Product | **New** `Order Product - On Create - Before Save` copies it from the Order Product's Quote Line Item when Create Orders From Quote creates the Order |
| Order Product → Asset | **Updated** `Create Asset Order Event - Mark Order Assets Created`. When Revenue Cloud finishes creating an Order's Assets, it sets each Asset's Number of Users from its Order Product (Order Product → Asset Action Source → Asset Action → Asset, the same path the renewal flow uses), **then** checks Assets Created. Asset has no direct link to its Order, so this is the only reliable path. |
| Asset → Beacon Subscriptions | **Updated** `Asset - On Create or Update - After Save` now creates one subscription per **Number of Users** (it used Current Quantity). It runs when Number of Users is set or changes, and still only creates the missing subscriptions. |
| Asset → renewal quote line | **New** `Quote Line Item - On Create - Before Save` copies the Asset's Number of Users onto lines created for an existing Asset (renewals and amendments), found through the line's Quote Action (Source Asset). Because Assets get their users before Assets Created is checked, the renewal quote created by `Order - Assets Created - Create Renewal` already has them. |

When a renewal Order is activated, the same event flow updates the Asset's Number of Users from the renewal Order Product. If the customer added users, the subscription flow creates the extra subscriptions. It never removes subscriptions.

**Built on the Renewal-Automation branch.** The renewal, order and asset flows are only in the `Renewal-Automation` branch, which has newer versions than HTCDEV. That branch is merged into this one, so this branch deploys the renewal automation and the pricing changes together. `Renewal-Automation` should be merged to master before, or together with, this branch.

### Copying users to the Opportunity

Standard Quote sync doesn't copy custom fields from quote lines to opportunity products, so two flows do it. Both match lines on Product, because each module is on a quote only once. Both follow the On/Off Switch.

- **Opportunity Product - On Create - Before Save**: when sync creates an opportunity product, copies Number of Users from the matching line on the Opportunity's synced Quote.
- **Quote Line Item - On Create or Update - After Save**: when a line on a syncing Quote is created or its Number of Users changes, updates the matching opportunity product. Errors go to the Fault Path Subflow.

### Security

New fields and objects are added to the persona permission sets:

- **Beacon Salesforce Admin**: full access to the three price objects and tabs, and edit access to Pricing Method.
- **Beacon Sales**: can edit Number of Users on quote lines and opportunity products. Read-only access to the price objects.
- **Beacon Finance** and **Beacon Executive**: read-only access to everything.

The formula and roll-up fields are read-only for everyone.

### Old pricing removed from HTCDEV

The following were removed in HTCDEV during this build. Bundles, schedules and price book entries are records, not metadata, so UAT and Prod are cleaned up with the script in Post Deployment Items.

| Record | Result |
|---|---|
| Entry Level, Starter, Pro, Platform and "Beacon Platform – Configurable" bundles | Deleted, with their 5 component groups, 85 bundle components and 43 price book entries |
| Core Bundle | **Deactivated, not deleted.** HTCDEV test orders (activated), assets, opportunities and quotes still use it, so it can't be deleted. Its price book entries are inactive. |
| 6 seat band price schedules (Volume, Slab) | Deleted, with 235 tiers |
| Top 1-50 Pharma - Multi-Year Term Escalation | Deleted, with 3 tiers |
| Module price book entries with no selling model | 104 deleted. 15 still used by test quotes and orders were deactivated. |

After cleanup, every price book has exactly 17 active entries (one per module, on the Annual Subscription selling model).

### Revenue Cloud pricing setup

The pricing procedure, decision tables and context mapping are Revenue Cloud setup. They're built in Setup in each org, as listed in Post Deployment Items, because they depend on the price objects and fields in this release. Once built in HTCDEV, retrieve them with Gearset into a follow-up branch so UAT and Prod can be deployed the same way.

## Acceptance Criteria

**Setup checks**

1. Open each of the 6 price books. Confirm **Pricing Method** is Per Module for Top 1-50 Pharma and >200 Heads, and Module Count for the other four.
2. Open the **Beacon Tier Prices** tab. Confirm there are 612 rows. Spot-check: Top 1-50 Pharma, Oncology Module, Tier 3 = £155,000.
3. Open **Beacon Module Count Prices**. Confirm there are 65 rows. Spot-check: Contract Orgs (>200 Heads), Starter, Up to 10 users = £100,000.
4. Open **Beacon Multi-Module Discounts**. Confirm there are 6 rows: 10%, 20% and 30% for Top 1-50 Pharma and for >200 Heads.
5. In the product picker on a quote, confirm no bundles appear and each module appears once.

**Quantity and users**

6. On a quote line, set Quantity to 2 and save. Confirm the error "Quantity must be 1. Enter the number of users in Number of Users."
7. Set Number of Users to 0 on a quote line and save. Confirm the error "Number of Users must be 1 or more."
8. From **Browse Catalogs**, add two modules to a Draft quote. Confirm they're added with Number of Users blank. Try to change the quote Status to Presented. Confirm the error "Enter Number of Users on every quote line before moving the quote out of Draft." Enter users on both lines and confirm the Status change now saves.

**Per Module pricing (Top 1-50 Pharma)**

9. Create a quote on Top 1-50 Pharma. Add Oncology with 8 users, CVRM with 20 users and ADC with 3 users.
10. Confirm User Tier is 3, 4 and 1. Confirm list prices are £155,000, £190,000 and £60,000.
11. Confirm Module Count is 3 and each line gets a 20% discount. Confirm net prices are £124,000, £152,000 and £48,000, and the quote total is £324,000.
12. Delete ADC. Confirm the discount changes to 10% on the two remaining lines.

**Module Count pricing**

13. Create a quote on Contract Orgs (>200 Heads). Add ADC with 3 users and Cell Therapy with 8 users.
14. Confirm Max Number of Users is 8 and both lines show Pricing Users 8 and User Tier 3. Confirm the quote total is **£100,000** (Starter, Up to 10 users), split £50,000 per line.
15. Change Cell Therapy to 12 users. Confirm both lines move to the Up to 20 users band and the total is £150,000.
16. Create a quote on <50 Heads with Oncology for 2 users and ADC for 2 users. Confirm the total is £23,000 (Starter, Up to 3 users). Change ADC to 4 users. Confirm the total is £26,000 (Starter, Enterprise).
17. On a Module Count quote, add 4 modules. Confirm the price is the Core total. Add 2 more (6 modules). Confirm the price is the Platform total.

**Opportunity sync**

18. On the synced quote from step 13, confirm the Opportunity's products show Number of Users 3 and 8.
19. Change a quote line's Number of Users. Confirm the matching opportunity product updates.
20. Add a User-level On/Off Switch record with Run Flows unchecked. Change Number of Users on a quote line. Confirm the opportunity product doesn't change. Delete the switch record.

**Order, Asset, subscriptions and renewal**

22. Accept and close won the Contract Orgs quote from step 13 (ADC 3 users, Cell Therapy 12 users). Wait for the Closed Won automation to finish.
23. Open the Order. Confirm each Order Product shows Number of Users 3 and 12.
24. Open the ADC and Cell Therapy Assets. Confirm Number of Users is 3 and 12, and that ADC has 3 Beacon Subscriptions and Cell Therapy has 12.
25. Open the renewal Quote created by the automation. Confirm each line shows the Asset's Number of Users (3 and 12) and the renewal is priced from them.
26. On a report of Assets, confirm Number of Users can be shown and summed.

**Access**

21. Log in as a Beacon Sales user. Confirm you can edit Number of Users and can view, but not edit, the price objects.

## Post Deployment Items

Run these in each org (UAT, then Prod) after Gearset deploys this branch. In HTCDEV, steps 1 and 2 are still needed after the metadata deploys. The cleanup in step 3 is already done there.

1. **Load the prices and backfill Assets.** Claude can do this through the org connection after the deploy. To run it yourself instead, open Developer Console, then **Debug → Open Execute Anonymous Window**, paste in `scripts/apex/Pricing_Model_Rebuild_Load_Prices.apex` and run it. The debug log should show "Price books updated: 6, tier prices: 612, module count prices: 65, discounts: 6" and the number of Assets backfilled. The script sets Pricing Method on each price book and upserts all price rows. It also sets Number of Users on existing module Assets from their Current Quantity, so renewals of those Assets get users. Those Assets already have one Beacon Subscription per seat, so no extra subscriptions are created. It's safe to run again.
2. **Build the Revenue Cloud pricing setup** (Setup):
   1. **Decision tables.** Create and activate three decision tables:
      - **Beacon Tier Price**, from Beacon Tier Price. Inputs: Price Book, Product, Tier (equals). Output: List Price.
      - **Beacon Module Count Price**, from Beacon Module Count Price. Inputs: Price Book (equals), Min Modules (≤ module count), Max Modules (≥ module count, blank = no limit), Min Users (≤ max users), Max Users (≥ max users, blank = no limit). Output: Quote Total.
      - **Beacon Multi-Module Discount**, from Beacon Multi-Module Discount. Inputs: Price Book (equals), Min Modules (≤ module count), Max Modules (≥ module count, blank = no limit). Output: Discount Percent.
   2. **Context definition.** Extend the sales transaction context used by quotes. Map the quote line's `User_Tier__c` and `Pricing_Users__c`, and the price book's `Pricing_Method__c`.
   3. **Pricing procedure.** Clone **Revenue Management Default Pricing Procedure Auto** as **Beacon Pricing Procedure**. Set up these steps:
      - Look up List Price from Beacon Tier Price by price book, product and User Tier, replacing the standard list price step.
      - Remove the volume (seat band) and term adjustment steps.
      - Count the module lines on the quote and find the highest Pricing Users.
      - On Per Module price books, apply the Beacon Multi-Module Discount percent to every line.
      - On Module Count price books, look up the Beacon Module Count Price total and set each line's net price to total ÷ module count, with any rounding on the last line.

      Activate it and set it as the default pricing procedure in **Salesforce Pricing Setup**.
   4. Retrieve the decision tables, context definition and pricing procedure with Gearset into a follow-up branch, so UAT and Prod get the same setup by deployment.
3. **Remove the old pricing** (UAT and Prod only). Run `scripts/apex/Pricing_Model_Rebuild_Remove_Old_Pricing.apex` the same way. To see what it would change first, set `PREVIEW = true`. The script:
   - deletes bundle components and groups, seat band and multi-year schedules, and unused entries with no selling model
   - deletes bundles, or deactivates any bundle still used on a quote, opportunity, order or asset (Prod has no quote or opportunity lines today).
4. **HTCDEV test data:** Core Bundle is deactivated, not deleted, because test orders, assets, opportunities and quotes use it. To remove it completely, those test records must be deleted first. Only do this with Rev Ops' go-ahead.

## Component Manifest

Github Branch: [Pricing-Model-Rebuild](https://github.com/aaroncrear/BeaconImplementation/tree/Pricing-Model-Rebuild)

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | CustomField | Pricebook2 | Pricing_Method__c | Pricing Method | Created | Restricted picklist: Per Module or Module Count. Tells pricing how to price quotes on this price book. |
| 2 | CustomField | Quote | Max_Number_of_Users__c | Max Number of Users | Created | Roll-up MAX of quote line Number of Users. Sets the band on Module Count price books. |
| 3 | CustomField | Quote | Module_Count__c | Module Count | Created | Roll-up COUNT of quote lines. Drives the multi-module discount and the module count level. |
| 4 | CustomField | QuoteLineItem | Number_of_Users__c | Number of Users | Created | Users for this module, entered by the rep. |
| 5 | CustomField | QuoteLineItem | Pricing_Users__c | Pricing Users | Created | Formula: the line's users on Per Module books, the quote's Max Number of Users on Module Count books. |
| 6 | CustomField | QuoteLineItem | User_Tier__c | User Tier | Created | Formula: Tier 1–6 from Pricing Users (1–3, 4–5, 6–10, 11–20, 21–50, 51+). |
| 7 | ValidationRule | QuoteLineItem | Quantity_Must_Be_One | Quantity Must Be One | Created | Blocks any quantity other than 1. |
| 8 | ValidationRule | QuoteLineItem | Number_of_Users_At_Least_One | Number of Users At Least One | Created | Blocks Number of Users below 1. Blank is allowed so Browse Catalogs can add lines. |
| 9 | CustomField | OpportunityLineItem | Number_of_Users__c | Number of Users | Created | Users for this module, copied from the synced quote line. |
| 10 | ValidationRule | OpportunityLineItem | Quantity_Must_Be_One | Quantity Must Be One | Created | Blocks any quantity other than 1. |
| 11 | CustomObject | Beacon_Tier_Price__c | Beacon_Tier_Price__c | Beacon Tier Price | Created | List price per price book, module and tier (612 rows). |
| 12 | CustomField | Beacon_Tier_Price__c | Price_Book__c | Price Book | Created | Lookup to Price Book. |
| 13 | CustomField | Beacon_Tier_Price__c | Product__c | Product | Created | Lookup to Product (module). |
| 14 | CustomField | Beacon_Tier_Price__c | Tier__c | Tier | Created | User tier 1–6. |
| 15 | CustomField | Beacon_Tier_Price__c | List_Price__c | List Price | Created | Annual list price at this tier. |
| 16 | CustomField | Beacon_Tier_Price__c | Price_Key__c | Price Key | Created | Unique external ID (book &#124; product code &#124; tier) used to upsert rows. |
| 17 | CustomObject | Beacon_Module_Count_Price__c | Beacon_Module_Count_Price__c | Beacon Module Count Price | Created | Quote total per Module Count price book, module level and user band (65 rows). |
| 18 | CustomField | Beacon_Module_Count_Price__c | Price_Book__c | Price Book | Created | Lookup to Price Book. |
| 19 | CustomField | Beacon_Module_Count_Price__c | Module_Level__c | Module Level | Created | Picklist: Entry, Starter, Core, Pro, Platform (labels only). |
| 20 | CustomField | Beacon_Module_Count_Price__c | Min_Modules__c | Min Modules | Created | Lowest module count for the level. |
| 21 | CustomField | Beacon_Module_Count_Price__c | Max_Modules__c | Max Modules | Created | Highest module count for the level. Blank = no limit. |
| 22 | CustomField | Beacon_Module_Count_Price__c | User_Band__c | User Band | Created | Band name from the price sheet, for example Up to 10 users. |
| 23 | CustomField | Beacon_Module_Count_Price__c | Min_Users__c | Min Users | Created | Lowest Max Number of Users for the band. |
| 24 | CustomField | Beacon_Module_Count_Price__c | Max_Users__c | Max Users | Created | Highest Max Number of Users for the band. Blank = Enterprise. |
| 25 | CustomField | Beacon_Module_Count_Price__c | Quote_Total__c | Quote Total | Created | Annual total for all modules at this level and band. |
| 26 | CustomField | Beacon_Module_Count_Price__c | Price_Key__c | Price Key | Created | Unique external ID (book &#124; level &#124; band) used to upsert rows. |
| 27 | CustomObject | Beacon_Multi_Module_Discount__c | Beacon_Multi_Module_Discount__c | Beacon Multi-Module Discount | Created | Multi-module discount per Per Module price book (6 rows). |
| 28 | CustomField | Beacon_Multi_Module_Discount__c | Price_Book__c | Price Book | Created | Lookup to Price Book. |
| 29 | CustomField | Beacon_Multi_Module_Discount__c | Min_Modules__c | Min Modules | Created | Lowest module count for the discount. |
| 30 | CustomField | Beacon_Multi_Module_Discount__c | Max_Modules__c | Max Modules | Created | Highest module count for the discount. Blank = no limit. |
| 31 | CustomField | Beacon_Multi_Module_Discount__c | Discount_Percent__c | Discount Percent | Created | Discount applied to every module line. |
| 32 | CustomField | Beacon_Multi_Module_Discount__c | Price_Key__c | Price Key | Created | Unique external ID (book &#124; min modules) used to upsert rows. |
| 33 | CustomTab | Beacon_Tier_Price__c | Beacon_Tier_Price__c | Beacon Tier Prices | Created | Tab for maintaining tier prices. |
| 34 | CustomTab | Beacon_Module_Count_Price__c | Beacon_Module_Count_Price__c | Beacon Module Count Prices | Created | Tab for maintaining module count totals. |
| 35 | CustomTab | Beacon_Multi_Module_Discount__c | Beacon_Multi_Module_Discount__c | Beacon Multi-Module Discounts | Created | Tab for maintaining multi-module discounts. |
| 36 | Flow | OpportunityLineItem | Opportunity_Product_On_Create_Before_Save | Opportunity Product - On Create - Before Save | Created | Copies Number of Users from the matching synced quote line when sync creates an opportunity product. |
| 37 | Flow | QuoteLineItem | Quote_Line_Item_On_Create_Update_After_Save | Quote Line Item - On Create or Update - After Save | Created | Copies Number of Users to the matching opportunity product when a syncing quote line is created or its users change. |
| 38 | Layout | QuoteLineItem | QuoteLineItem-Quote Line Item Layout | Quote Line Item Layout | Updated | Added Number of Users, Pricing Users and User Tier. |
| 39 | Layout | OpportunityLineItem | OpportunityLineItem-Opportunity Product Layout | Opportunity Product Layout | Updated | Added Number of Users (read-only). |
| 40 | Layout | Quote | Quote-Quote Layout | Quote Layout | Updated | Added Module Count, Max Number of Users and Lines Missing Users to Totals. |
| 41 | Layout | Pricebook2 | Pricebook2-Price Book Layout | Price Book Layout | Updated | Added Pricing Method. |
| 42 | PermissionSet | N/A | Beacon_Salesforce_Admin_Object_Tab_FLS | Beacon Salesforce Admin Object Tab FLS | Updated | Full access to the 3 price objects and tabs. Edit access to Pricing Method and Number of Users. Read access to the formula and roll-up fields. |
| 43 | PermissionSet | N/A | Beacon_Sales_Object_Tab_FLS | Beacon Sales Object Tab FLS | Updated | Edit access to Number of Users. Read access to the other new fields and the price objects. |
| 44 | PermissionSet | N/A | Beacon_Finance_Object_Tab_FLS | Beacon Finance Object Tab FLS | Updated | Read access to the new fields and price objects. |
| 45 | PermissionSet | N/A | Beacon_Executive_Object_Tab_FLS | Beacon Executive Object Tab FLS | Updated | Read access to the new fields and price objects. |
| 46 | PermissionSet | N/A | Beacon_Consulting, Beacon_Customer_Success, Beacon_Marketing, Beacon_Product, Beacon_ResOps, Beacon_Tech _Object_Tab_FLS | Persona Object Tab FLS | Updated | Read access to Asset and Order Product Number of Users and Quote Lines Missing Users (all 10 persona sets get these; Admin can edit the two Number of Users fields). |
| 47 | Anonymous Apex script | N/A | scripts/apex/Pricing_Model_Rebuild_Load_Prices.apex | Load Prices | Created | Sets Pricing Method, upserts 612 tier prices, 65 module count totals and 6 discounts, and backfills Asset Number of Users from Current Quantity. Run after deploy. |
| 48 | Anonymous Apex script | N/A | scripts/apex/Pricing_Model_Rebuild_Remove_Old_Pricing.apex | Remove Old Pricing | Created | Removes bundles, seat band and multi-year schedules, and price book entries with no selling model in UAT and Prod. |
| 49 | CustomField | Quote | Lines_Missing_Users__c | Lines Missing Users | Created | Roll-up COUNT of quote lines with no Number of Users. |
| 50 | ValidationRule | Quote | Users_Required_Before_Leaving_Draft | Users Required Before Leaving Draft | Created | Blocks a Status change away from Draft while any line has no Number of Users. |
| 51 | CustomField | OrderItem | Number_of_Users__c | Number of Users | Created | Users for this module, copied from the quote line. |
| 52 | CustomField | Asset | Number_of_Users__c | Number of Users | Created | Users for this module, set from the Order Product. Drives Beacon Subscriptions and renewal quote lines. |
| 53 | Flow | OrderItem | Order_Product_On_Create_Before_Save | Order Product - On Create - Before Save | Created | Copies Number of Users from the Order Product's quote line. |
| 54 | Flow | QuoteLineItem | Quote_Line_Item_On_Create_Before_Save | Quote Line Item - On Create - Before Save | Created | Copies Number of Users from the Source Asset onto renewal and amendment quote lines. |
| 55 | Flow | CreateAssetOrderEvent | Create_Asset_Order_Event_Mark_Order_Assets_Created | Create Asset Order Event - Mark Order Assets Created | Updated | Now sets each Asset's Number of Users from its Order Product before checking Assets Created. |
| 56 | Flow | Asset | Asset_On_Create_Or_Update_After_Save | Asset - On Create or Update - After Save | Updated | Creates one Beacon Subscription per Number of Users instead of per Current Quantity. |
| 57 | Layout | Asset | Asset-Asset Layout | Asset Layout | Updated | Added Number of Users (read-only). |
| 58 | Layout | OrderItem | OrderItem-Order Product Layout | Order Product Layout | Updated | Added Number of Users (read-only). |
