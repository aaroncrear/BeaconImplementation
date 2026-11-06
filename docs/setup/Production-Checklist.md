# Beacon Production – Go-Live Checklist

Tick each box as you go. 🤖 = tell Claude, who checks or completes that step before you continue. Full detail for every step is in `docs/setup/Production-Deployment-Guide.md`.

**Already done by Claude in Production:** old seat-band/escalator schedules deleted · 5 bundles and their price book entries deactivated · Number of Users attribute + Beacon Module classification created · 17 modules assigned to it.

---

## 1. Deploy metadata (Gearset)
- [ ] Compare branch `Pricing-Model-Rebuild` → **Beacon Production** using `manifest/Production-Pricing-and-Renewals-package.xml` (90 components)
- [ ] Review the comparison for the **5 layouts**, **12 permission sets** and **Opportunity_On_Create_After_Save** – stop and tell Claude if there are Production changes you don't recognise
- [ ] Deploy
- [ ] **Setup → Flows**: confirm all 17 deployed flows are **Active**

## 2. Load price data (Developer Console → Execute Anonymous, in order)
- [ ] `1_Load_Tier_Prices_Top_1_50_Pharma`
- [ ] `2_Load_Tier_Prices_200_Heads`
- [ ] `3_Load_Tier_Prices_51_200_Heads`
- [ ] `4_Load_Tier_Prices_50_Heads`
- [ ] `5_Load_Tier_Prices_PE_VC`
- [ ] `6_Load_Tier_Prices_Contract_Orgs_200_Heads`
- [ ] `7_Load_Module_Count_Prices_Less_Than_50_51_200_PE_VC`
- [ ] `8_Load_Module_Count_Contract_Orgs_Discounts_Tier1_Prices`
- [ ] 🤖 Claude checks: 612 tier prices, 221 module count prices, 32 discounts, no £0 module price book entries

## 3. Context definition – SalesTransactionContextAuto
- [ ] Add attribute **BeaconTier** (SalesTransactionItem, INPUT OUTPUT, NUMBER)
- [ ] Add attribute **BeaconUsers** (SalesTransactionItem, INPUT OUTPUT, NUMBER)
- [ ] Add attribute **BeaconModuleCount** (SalesTransaction, INPUT OUTPUT, NUMBER)
- [ ] Add attribute **BeaconMaxUsers** (SalesTransaction, INPUT OUTPUT, NUMBER)
- [ ] Context Tags: add a tag for each of the 4, same name
- [ ] QuoteEntitiesMapping → Edit SObject Mapping → map the 4 (Pricing_Tier__c, Number_of_Users__c, Pricing_Module_Count__c, Pricing_Max_Users__c) → **Save and Publish**
- [ ] OrderEntitiesMapping → same 4 on Order / Order Product → **Save and Publish**
- [ ] 🤖 Claude checks attributes, tags and all 8 mappings

## 4. Decision tables (Setup → Decision Tables → New)
- [ ] **Beacon Tier Price** – conditions Price Book =, Product =, Tier = · outputs Adjustment Type, Adjustment Value → Save, Activate, Refresh
- [ ] **Beacon Module Count Price** – conditions Price Book =, Min Modules =, Max Modules =, Min Tier ≥, Max Tier ≤ · outputs Adjustment Type, Adjustment Value, Quote Total → Save, Activate, Refresh
- [ ] **Beacon Multi-Module Discount** – conditions Price Book =, Min Modules =, Max Modules = · outputs Adjustment Type, Adjustment Value → Save, Activate, Refresh
- [ ] 🤖 Claude registers the 3 tables in the Pricing Recipe and sends you `Beacon_Pricing_Procedure_PROD.zip`

## 5. Pricing procedure and pricing settings
- [ ] Workbench (Production) → migration → Deploy the zip (**Single Package unticked**)
- [ ] Pricing Procedures → **Beacon Pricing Procedure V1** → **Activate**
- [ ] **Revenue Settings** → pricing procedure = **Beacon Pricing Procedure**
- [ ] **Salesforce Pricing Setup** → default pricing procedure = **Beacon Pricing Procedure**
- [ ] **Salesforce Pricing Setup** → turn on **Price Waterfall Persistence** (leave API waterfall and Price Tracking History off)
- [ ] **Sync Pricing Data** – wait until complete

## 6. Quote page
- [ ] Quote → ⚙ Edit Page → Quote Line Items (Transaction Line Editor) component → add **Number of Users** column → Save

## 7. Quantity = 1 configuration rule
- [ ] Assign yourself the rule-building permission sets (Product Configuration Rules Designer, BRE Designer, Context Service designer)
- [ ] Create Rule Library **Beacon Configuration Rules**, version **V1**, activate
- [ ] Sub-Type Mapping: `PC_ProductBasedOn` → `ProductBasedOn`
- [ ] Create rule **Beacon Module Quantity Must Be 1** – scope Product Classification **Beacon Module**, Quantity ≠ 1 → warning, effective to 2099 → Validate → Activate

## 8. Users and permissions
- [ ] Every rep has their persona `Beacon_*_Object_Tab_FLS` permission set
- [ ] Assign **Edit Closed Opportunities** / **Edit Closed Won Quotes** to the approved people only
- [ ] Custom Settings → **On/Off Switch** → **Run Flows** is on

## 9. Test (send Claude the quote names after each)
- [ ] <50 Heads: ADC 4 + Oncology 2 → **£26,000** (£13,000 each)
- [ ] <50 Heads: ADC 3 + Oncology 2 → **£23,000** (£11,500 each)
- [ ] Top 1-50 Pharma: ADC 3 + Oncology 8 → **£193,500** (10% off)
- [ ] Contract Orgs: ADC 3 + Autoimmune 15 → **£150,000** (£75,000 each)
- [ ] Contract Orgs: 4 modules, highest 40 users → **£250,000**
- [ ] Change a line's users in the **column** → price updates
- [ ] Manual 10% discount on a line → applied on top
- [ ] Price waterfall opens on a repriced quote
- [ ] Quantity ≠ 1 in Browse Catalogs shows the warning
- [ ] Quote can't leave Draft with a line missing Number of Users
- [ ] Closed Won → Order → Assets carry Number of Users → Beacon Subscriptions + renewal opportunity created
- [ ] 🤖 Claude signs off the test results
