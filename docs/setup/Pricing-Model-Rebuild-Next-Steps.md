# Pricing Model Rebuild – Next Steps (HTCDEV)

This page is kept up to date. Work from **Now** down.

---

## Now – do these in order

_Last updated: rebuilt V2 zip (Single Package unticked)._

**Beacon Pricing Procedure V2** = your current V1 (all 30 standard steps, unchanged) + the six proven Beacon steps as **steps 16–21**, after list price and volume discounts and **before manual discounts** (so reps can still discount on top):

| Step | Name | What it does |
|---|---|---|
| 16 | BeaconSetLineTier | Tier 1-6 from the line's Number of Users |
| 17 | BeaconCountModules | `SUM(LineItemQuantity)` → module count |
| 18 | BeaconHighestTier | `MAX(BeaconTier__c)` → highest tier |
| 19 | BeaconTierPrice | Line price from Beacon Tier Price |
| 20 | BeaconMultiModuleDiscount | 10/20/30% off (Per Module books) |
| 21 | BeaconModuleCountPrice | Quote total ÷ modules per line (Module Count books) |

V1 stays as it is. V2 deploys as **Draft**.

### Step 1. Deploy with Workbench
1. Download **Beacon_Pricing_Procedure_V2.zip** (sent in chat).
2. Workbench → **migration → Deploy** → choose the zip → leave **Single Package UNticked** → **Next → Deploy**. (Use the rebuilt zip – its files sit in an `unpackaged` folder, like Workbench's own retrieve zips.)
3. If it fails, screenshot the error for Claude.

### Step 2. Activate V2 and point both settings at it
1. **Setup → Pricing Procedures → Beacon Pricing Procedure** → open **V2** → **Activate**. (If it asks, deactivate V1.)
2. **Revenue Settings** → pricing procedure → **Beacon Pricing Procedure**.
3. **Salesforce Pricing Setup** → default pricing procedure → **Beacon Pricing Procedure**.
4. **Sync Pricing Data.**

### Step 3. Reprice Product Config 1
Change Oncology to 3 users and back to 2 (or any edit that reprices). **Expected:** ADC £13,000 + Oncology £13,000 = **£26,000**. Tell Claude – Claude checks the quote.

---

## After that

- [ ] Test a **Per Module** book with the discount: Top 1-50 Pharma (Pricebook `01sS9000008iwwXIAQ`), 3 lines → 20% off each line's tier price.
- [ ] Claude writes the final step list for **Beacon Pricing Procedure** (the real one) from what Scratch Test proves.
- [ ] Build it, **Activate**, then **Salesforce Pricing Setup** → set the default pricing procedure to **Beacon Pricing Procedure**. (Today the default is Salesforce's *Revenue Management Default Pricing Procedure Auto*, so live quotes don't run any Beacon steps yet.)
- [ ] **Sync Pricing Data**, then test real quotes (Product Config 1: ADC at 4 users → £21,000).
- [ ] Configuration rule **Beacon Module Quantity Must Be 1**: check it works on ADC, then widen it to all 17 modules (scope by Product Classification **Beacon Module**).
- [ ] Claude updates the setup guide and release notes with the proven build, including the UAT/Prod steps below.

---

## Proven so far

- **Real quote works end to end** (Product Config 1, <50 Heads): ADC 4 users (Tier 2) + Oncology 2 users (Tier 1) → Module Count 2, Max Tier 2 → **£13,000 + £13,000 = £26,000**. `MAX(BeaconTier__c)` works on real quotes – its error was Simulate-only.
- The procedure used by quotes is set in **two** places: **Revenue Settings** (pricing procedure) and **Salesforce Pricing Setup** (default pricing procedure). Both must point to the Beacon procedure.

- **Module count pricing works:** SUM(LineItemQuantity) → `BeaconModuleCount__c` = 2, and the Module Count matrix with max tier 2 overrode both lines to **£13,000** (<50 Heads, Starter, Enterprise). Discount step correctly did nothing on a Module Count book.
- `MAX(LineItemQuantity)` works in Aggregate Price; `MAX(BeaconTier__c)` fails **in Simulate** with *Invalid tag attribute name key: BeaconTier__c* – being tested on a real quote.

- Price Adjustment Matrix can read the Beacon tables once each table is **registered to it in the Pricing Recipe** (done in HTCDEV for all three tables).
- Tables need **Adjustment Type** and **Adjustment Value** outputs (added).
- Formula Based Pricing reads the line's Number of Users from `AttributeValue` and sets `BeaconTier__c`: 4 users → Tier 2 → £21,000; 2 users → Tier 1 → £18,000.
- Custom context attributes must be **mapped** in QuoteEntitiesMapping / OrderEntitiesMapping (done), and Simulate must use **QuoteEntitiesMapping**.
- Aggregate Price accepts `SUM(LineItemQuantity)`; `COUNT(LineItem)` won't save.
- An **active** version can't be edited – Deactivate first. The page may need a refresh after deactivating.

## Items UAT and Prod will need (not metadata)

- Pricing Recipe registrations: Beacon Tier Price, Beacon Module Count Price and Beacon Multi-Module Discount → Price Adjustment Matrix.
- Context definition SalesTransactionContextAuto: attributes and tags `BeaconTier__c`, `BeaconModuleCount__c`, `BeaconMaxUsers__c`, mapped in QuoteEntitiesMapping and OrderEntitiesMapping to the `Pricing_…` fields.
- Decision table changes (outputs and Tier conditions).
- Scripts: tier prices, adjustment fields, module count / discount prep.
- Default pricing procedure set to Beacon Pricing Procedure in **both** Revenue Settings and Salesforce Pricing Setup.

## Reference

| Item | Value |
|---|---|
| Developer Console | https://beaconintel--htcdev.sandbox.my.salesforce.com/_ui/common/apex/debug/ApexCSIPage |
| <50 Heads | `01sS9000008iu6kIAA` |
| Top 1-50 Pharma | `01sS9000008iwwXIAQ` |
| >200 Heads | `01sS9000008iwy9IAA` |
| ADC Module | `01tS900000OBbT3IAL` |
| Oncology Module | `01tS900000OBbKzIAL` |
| Test quote Product Config 1 | `0Q0S9000004wzSDKAY` |
| Tier formula | `IF(VALUE(AttributeValue) <= 3, 1, IF(VALUE(AttributeValue) <= 5, 2, IF(VALUE(AttributeValue) <= 10, 3, IF(VALUE(AttributeValue) <= 20, 4, IF(VALUE(AttributeValue) <= 50, 5, 6)))))` |
