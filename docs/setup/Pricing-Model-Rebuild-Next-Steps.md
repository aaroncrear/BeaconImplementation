# Pricing Model Rebuild – Next Steps (HTCDEV)

This page is kept up to date. Work from **Now** down.

---

## Now – do these in order

_Last updated: matrix constants and MAX test._

### Step 1. Fill in the four empty constants
In Scratch Test V3, open the **Resource Manager** and search **Constant_Adjustment**. Set the **Value** of the four without one:

| Constant (starts with) | Value |
|---|---|
| `Constant_AdjustmentType_Beacon_Module_Count_Price` | `Adjustment_Type__c` |
| `Constant_AdjustmentValue_Beacon_Module_Count_Price` | `Adjustment_Value__c` |
| `Constant_AdjustmentType_Beacon_Multi_Module_Discount` | `Adjustment_Type__c` |
| `Constant_AdjustmentValue_Beacon_Multi_Module_Discount` | `Adjustment_Value__c` |

(The two Beacon Tier Price constants already have values.)

### Step 2. Check both new matrix steps
On **Beacon Multi-Module Discount** and **Beacon Module Count Price**:
- **Output Rule Variables:** leave all empty.
- **Input Variables:** Quantity → `LineItemQuantity`, Input Unit Price → `NetUnitPrice`.
- **Output Variables:** Net Unit Price → `NetUnitPrice`, Subtotal → `ItemNetTotalPrice`.

Input Rule Variables:

| Step | Field | Value |
|---|---|---|
| Discount | Price Book | `PriceBooks` |
| Discount | Min Modules, Max Modules | `BeaconModuleCount__c` |
| Module Count | Price Book | `PriceBooks` |
| Module Count | Min Modules, Max Modules | `BeaconModuleCount__c` |
| Module Count | Min Tier, Max Tier | `BeaconMaxUsers__c` |

### Step 3. Delete the MAX step, then Save
Delete the `MAX(BeaconTier__c)` Aggregate step (it's the likely cause of *Invalid tag attribute name key: BeaconTier__c*). Keep the `SUM(LineItemQuantity)` step. **Save.**

### Step 4. Simulate
1. **Context Mapping:** `QuoteEntitiesMapping` (check it every run – it resets).
2. **Input Mode:** Advanced. Paste:

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
          "SalesTransactionItemAttribute": [ { "AttributeValue": "4" } ]
        },
        {
          "LineItem": "line2",
          "LineItemQuantity": "1",
          "Product": "01tS900000OBbKzIAL",
          "ListPrice": "18000",
          "DerivedPricingAttribute": "false",
          "ItemContract": "",
          "SalesTransactionItemAttribute": [ { "AttributeValue": "2" } ]
        }
      ]
    }
  ]
}
```

3. **Expected without the MAX step:** ADC **£21,000**, Oncology **£18,000** (each line keeps its tier price; the module count lookup has no tier to match yet).
4. Send Claude a screenshot:
   - **Runs:** the MAX step was the problem – Claude gives you another way to get the highest tier.
   - **Fails:** send the JSON Details from the Output tab.

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
