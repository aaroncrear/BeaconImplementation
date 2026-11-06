# Pricing Model Rebuild – Next Steps (HTCDEV)

This page is kept up to date. Work from **Now** down.

---

## Now – Number of Users column in the Transaction Line Editor

_Last updated: V3 active (V2 deactivated); column setting found on the Lightning page component._

Reps add modules with Browse Catalogs, then set **Number of Users** in a column in the Transaction Line Editor. Pricing reads the quote line field instead of the product attribute. Tier, discount and module count pricing don't change.

### Step 1. Add a context field for Number of Users ✅ Done
`BeaconUsers__c` mapped to `Number_of_Users__c` in QuoteEntitiesMapping and OrderEntitiesMapping (checked by Claude).

### Step 2. Make V3 in the builder (instead of the Workbench deploy)
The V4 Workbench deploy fails with *Property 'dataType' not valid* at a line that doesn't contain one, so make the two small changes in the builder instead.

1. **Pricing Procedures → Beacon Pricing Procedure → V2** → **Save As → Save as New Version**. Name **Beacon Pricing Procedure V3**, version **3**.
2. Open V3. Find step **BeaconSetLineTier** (Formula Based Pricing, after the volume discount steps).
3. **Add a Formula Based Pricing step just above it:**
   - **Formula:** `IF(BeaconUsers__c >= 1, BeaconUsers__c, VALUE(AttributeValue))`
   - **Output Variable:** `BeaconUsers__c`
   - Tick **Exclude Price Waterfall**.
4. **Change BeaconSetLineTier's formula to:**
   `IF(BeaconUsers__c >= 51, 6, IF(BeaconUsers__c >= 21, 5, IF(BeaconUsers__c >= 11, 4, IF(BeaconUsers__c >= 6, 3, IF(BeaconUsers__c >= 4, 2, 1)))))`
   (Output stays `BeaconTier__c`.)
5. **Save → Activate** (deactivate V2 if asked). **Sync Pricing Data.**

What it does: if a line's Number of Users field is empty, the catalog (gear) value is copied in; the tier then comes from the field. No users anywhere → Tier 1. After a line is added, change users in the **Transaction Line Editor column**.

### Step 3. Turn off the sync flow
**Setup → Flows → Quote Pricing Complete: Sync Number of Users → Deactivate.** (Pricing now fills the field itself; the flow would overwrite column edits.)
**Keep** the Number of Users attribute on the **Beacon Module** classification (still required in the catalog).

### Step 4. Add the column to the Transaction Line Editor
The columns are set **on the line editor component in the Quote Lightning page**: quote → ⚙ → **Edit Page** → click the Quote Line Items component → add **Number of Users** in its column setting → **Save**. (Do Step 3 first, or the sync flow overwrites edits in the column.)

### Step 5. Test
On **Product Config 1**, change ADC's Number of Users in the line editor column (4 → 6). Also add a new module through the catalog with users set in the gear → after pricing, its column should show that number. **Expected for ADC 6:** ADC Tier 3, max tier 3 → for <50 Heads still the Enterprise band → £13,000 + £13,000. Then set ADC to 3 → both Tier 1 → "Up to 3 users" → **£11,500 + £11,500**.

> **Required:** a column can't be hard-required at the moment a line is added (the catalog adds lines before users are entered). The existing rule **Lines Valid Before Leaving Draft** blocks the quote from leaving Draft while any line has no Number of Users – reps see no errors while they work.

---

---

## Then – test all price books

| Price books | Each line | Quote total |
|---|---|---|
| Top 1-50 Pharma, >200 Heads (Per Module) | Its own tier price (from its users) | Sum of lines less 10% (2 modules), 20% (3), 30% (4+) |
| <50 Heads, 51-200 Heads, PE-VC, Contract Orgs (Module Count) | Equal share of the total | Module level (1, 2, 3-4, 5, 6+) × user band from the **highest** users on any line |

Send Claude the quote names – Claude checks every line. A total can be a penny over when it doesn't divide evenly (e.g. 3 lines).

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

- **Beacon Pricing Procedure V2 is live in HTCDEV** (active, default in Revenue Settings and Salesforce Pricing Setup). Product Config 1 → £13,000 + £13,000 = **£26,000**.

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

- Quote Lightning page: Number of Users column on the line editor component (retrieve the FlexiPage with Gearset once settled).

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
