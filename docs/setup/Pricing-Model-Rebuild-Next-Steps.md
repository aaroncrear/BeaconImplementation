# Pricing Model Rebuild – Next Steps (HTCDEV)

This page is kept up to date. Work from **Now** down.

---

## Now – do these in order

_Last updated: MAX works on standard fields; next, a real-quote test._

MAX works (`MAX(LineItemQuantity)` gave £11,500 as expected). It only fails on our custom `BeaconTier__c` **in Simulate**. Simulate has already failed on custom tags once where the real engine may not, so the next test is a **real quote**. Everything else is proven.

### Step 1. Put the real MAX back
In Scratch Test V3, change the second Aggregate step's formula from `MAX(LineItemQuantity)` back to **`MAX(BeaconTier__c)`** (output stays `BeaconMaxUsers__c`). **Save.**

Check the steps are in this order:
1. Pricing Setting
2. Formula Based Pricing → `BeaconTier__c` (tick **Exclude Price Waterfall**)
3. Aggregate Price `SUM(LineItemQuantity)` → `BeaconModuleCount__c`
4. Aggregate Price `MAX(BeaconTier__c)` → `BeaconMaxUsers__c`
5. Price Adjustment Matrix – Beacon Tier Price
6. Price Adjustment Matrix – Beacon Multi-Module Discount
7. Price Adjustment Matrix – Beacon Module Count Price

### Step 2. Make Scratch Test the live procedure (HTCDEV only)
1. **Activate** Scratch Test V3.
2. **Setup → Salesforce Pricing Setup** → set the **default pricing procedure** to **Scratch Test**.
3. **Sync Pricing Data** and wait for it to finish.

### Step 3. Price a real quote
1. Open quote **Product Config 1** (<50 Heads, ADC at 4 users) in Browse Catalogs.
2. Add **Oncology Module** with **Number of Users = 2**. Save / reprice.
3. **Expected:** ADC **£13,000**, Oncology **£13,000**, total **£26,000** (Starter, Enterprise).
4. Tell Claude when it's saved – Claude will check the line prices, Pricing Tier, Pricing Module Count and Pricing Max User Tier in HTCDEV.

If pricing errors, screenshot the message. Either way, leave the default on Scratch Test until Claude says to switch it back (HTCDEV quotes priced with the standard procedure until now anyway).

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
- Default pricing procedure set to Beacon Pricing Procedure.

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
