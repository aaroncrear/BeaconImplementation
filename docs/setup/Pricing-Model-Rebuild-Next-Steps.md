# Pricing Model Rebuild – Next Steps (HTCDEV)

This page is kept up to date. Work from **Now** down.

---

## Now

### Isolate the MAX step
Simulate fails with *Invalid tag attribute name key: BeaconTier__c* even with BeaconTier__c set to 0. The only step that reads BeaconTier__c across lines is the **MAX** Aggregate, so test without it:

1. Deactivate the version if it's active, then **delete** the `MAX(BeaconTier__c)` Aggregate step. Keep everything else. **Save.**
2. **Simulate** with the step C JSON below (Context Mapping **QuoteEntitiesMapping**). You can drop the `"BeaconTier__c": "0"` lines if the simulator complains about them.
3. Expected without the MAX step (the module count lookup finds no band, so lines keep their tier price):
   - ADC (4 users): **£21,000**
   - Oncology (2 users): **£18,000**
4. Send Claude the result:
   - **It runs:** the MAX step is the problem. Claude will give you a different way to get the quote's highest tier.
   - **Same error:** the problem is elsewhere (Claude will check the SUM step next).

### A. (done) Max-tier step – being isolated above

### B. Add the two Price Adjustment Matrix steps
Add them **after** the Beacon Tier Price step, in this order.

**Beacon Multi-Module Discount**

| Section | Field | Value |
|---|---|---|
| Input Rule Variables | Price Book | `PriceBooks` |
| | Min Modules | `BeaconModuleCount__c` |
| | Max Modules | `BeaconModuleCount__c` |
| Input Variables | Adjustment Type / Value Field | leave as filled in (check the constants hold `Adjustment_Type__c` / `Adjustment_Value__c`) |
| | Quantity | `LineItemQuantity` |
| | Input Unit Price | `NetUnitPrice` |
| Output Variables | Net Unit Price | `NetUnitPrice` |
| | Subtotal | `ItemNetTotalPrice` |

**Beacon Module Count Price**

| Section | Field | Value |
|---|---|---|
| Input Rule Variables | Price Book | `PriceBooks` |
| | Min Modules | `BeaconModuleCount__c` |
| | Max Modules | `BeaconModuleCount__c` |
| | Min Tier | `BeaconMaxUsers__c` |
| | Max Tier | `BeaconMaxUsers__c` |
| Input Variables | Adjustment Type / Value Field | leave as filled in (constants `Adjustment_Type__c` / `Adjustment_Value__c`) |
| | Quantity | `LineItemQuantity` |
| | Input Unit Price | `NetUnitPrice` |
| Output Variables | Net Unit Price | `NetUnitPrice` |
| | Subtotal | `ItemNetTotalPrice` |

Then **Save**. If the builder flags empty constants, set their values in the **Resource Manager** (same fix as before).

### C. Simulate
1. **Context Mapping:** `QuoteEntitiesMapping` (it resets to SalesTransaction each run, so check it every time).
2. **Input Mode:** switch to **Advanced** and paste this JSON (easiest way to get two lines). Leave Context Mapping on QuoteEntitiesMapping.

```json
{
  "SalesTransaction": [
    {
      "PriceBooks": "01sS9000008iu6kIAA",
      "SalesTransactionItem": [
        {
          "LineItem": "line1",
          "LineItemQuantity": "1",
          "Product": "01tS900000OBbT3IAL",
          "ListPrice": "18000",
          "DerivedPricingAttribute": "false",
          "ItemContract": "",
          "BeaconTier__c": "0",
          "SalesTransactionItemAttribute": [ { "AttributeValue": "4" } ]
        },
        {
          "LineItem": "line2",
          "LineItemQuantity": "1",
          "Product": "01tS900000OBbKzIAL",
          "ListPrice": "18000",
          "DerivedPricingAttribute": "false",
          "ItemContract": "",
          "BeaconTier__c": "0",
          "SalesTransactionItemAttribute": [ { "AttributeValue": "2" } ]
        }
      ]
    }
  ]
}
```

   `BeaconTier__c` is in the JSON as `0` because the simulator now lists it as an input (the formula step overwrites it). Without it, Simulate fails with *Invalid tag attribute name key: BeaconTier__c*. Or, in Simplified mode, the same values as below (copy icon on the line adds line 2):

| | Line 1 | Line 2 |
|---|---|---|
| LineItem | `line1` | `line2` |
| LineItemQuantity | `1` | `1` |
| Product | `01tS900000OBbT3IAL` (ADC) | `01tS900000OBbKzIAL` (Oncology) |
| ListPrice | `18000` | `18000` |
| DerivedPricingAttribute | `false` | `false` |
| AttributeValue | `4` | `2` |

   PriceBooks: `01sS9000008iu6kIAA` (<50 Heads)

3. **Expected:** £13,000 per line, £26,000 total (Starter, Enterprise).

Send Claude a screenshot of the result.

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
