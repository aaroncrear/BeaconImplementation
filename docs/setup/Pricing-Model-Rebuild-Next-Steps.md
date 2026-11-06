# Pricing Model Rebuild – Next Steps (HTCDEV)

This page is kept up to date. Work from **Now** down.

---

## Now – do these in order

_Last updated: full pricing proven on a real quote; next, retrieve Scratch Test._

### Step 1. Retrieve Scratch Test with Workbench
Claude will build the real **Beacon Pricing Procedure** (new Draft version) from Scratch Test's exact settings.

1. Download `Scratch_Test_and_Beacon_package.xml` (sent in chat; also in the branch under `scripts/retrieve/`).
2. **workbench.developerforce.com** → Sandbox → log in to HTCDEV.
3. **migration → Retrieve** → Unpackaged Manifest: choose the file → **Next → Retrieve → Download ZIP File**.
4. Upload the zip in chat.

### Leave as-is for now
- **Revenue Settings** and **Salesforce Pricing Setup** both point to **Scratch Test**. Leave them – HTCDEV quotes price with Scratch Test until the Beacon procedure is ready. (Scratch Test doesn't have manual discounts or the standard subscription steps, so don't rely on HTCDEV quote totals for anything else meanwhile.)

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
