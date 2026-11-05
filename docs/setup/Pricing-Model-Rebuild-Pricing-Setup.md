# Pricing Model Rebuild – Revenue Cloud Pricing Setup

Build these in **Setup** in Beacon HTCDEV, in order. When they're done and tested, retrieve them with Gearset so UAT and Prod get them by deployment.

**Steps**

1. [Decision tables](#step-1-decision-tables)
2. [Beacon Pricing Procedure](#step-2-beacon-pricing-procedure)
3. [Sync pricing data and test](#step-3-sync-pricing-data-and-test)

No context definition change is needed. The procedure doesn't need the price book's Pricing Method, because the price tables already separate the two kinds of price book (see [Step 2](#step-2-beacon-pricing-procedure)).

[Test cases](#test-cases) · [If something doesn't work](#if-something-doesnt-work)

---

## Step 1. Decision tables

Create three decision tables. For each one:

1. **Setup** → Quick Find **Decision Tables** → **New**.
2. Use these settings for all three:
   - **Usage Type:** Default Pricing
   - **Source Type:** Single Object
   - **Hit Policy / Collect Operator:** First Match (or Unique if First Match isn't offered)
3. Add the conditions and output below.
4. **Save** → **Activate** → **Refresh**.

### 1A. Beacon Tier Price

- **Object:** Beacon Tier Price (`Beacon_Tier_Price__c`), 612 rows
- **Conditions:**

  | Field | Operator |
  |---|---|
  | Price Book (`Price_Book__c`) | Equals |
  | Product (`Product__c`) | Equals |
  | Tier (`Tier__c`) | Equals |
- **Output:** List Price (`List_Price__c`)

### 1B. Beacon Module Count Price

- **Object:** Beacon Module Count Price (`Beacon_Module_Count_Price__c`), 65 rows
- **Conditions:**

  | Field | Operator | Compared to |
  |---|---|---|
  | Price Book (`Price_Book__c`) | Equals | the quote's price book |
  | Min Modules (`Min_Modules__c`) | Greater Or Equal | module count |
  | Max Modules (`Max_Modules__c`) | Less Or Equal | module count |
  | Min Users (`Min_Users__c`) | Greater Or Equal | highest Number of Users on the quote |
  | Max Users (`Max_Users__c`) | Less Or Equal | highest Number of Users on the quote |
- **Output:** Quote Total (`Quote_Total__c`)
- **Behaviours:** turn **Consider Null Value** on, so rows with a blank maximum (no upper limit) match.

The operator compares the **input** with the row's value: "module count Greater Or Equal Min Modules". This is how Revenue Cloud's own tier table is set up (LowerBound = Greater Or Equal, UpperBound = Less Or Equal, Consider Null Value on).

### 1C. Beacon Multi-Module Discount

- **Object:** Beacon Multi-Module Discount (`Beacon_Multi_Module_Discount__c`), 6 rows
- **Conditions:**

  | Field | Operator |
  |---|---|
  | Price Book (`Price_Book__c`) | Equals |
  | Min Modules (`Min_Modules__c`) | Greater Or Equal (module count) |
  | Max Modules (`Max_Modules__c`) | Less Or Equal (module count) |
- **Output:** Discount Percent (`Discount_Percent__c`)
- **Behaviours:** turn **Consider Null Value** on, so the 4+ modules row (blank Max Modules) matches.

### Check the tables

Some rows leave **Max Modules / Max Users** blank to mean "no upper limit" (Platform 6+, Enterprise, 4+ modules). Use each table's **Test / Preview** to check those rows match:

| Table | Inputs | Expected |
|---|---|---|
| 1A | Top 1-50 Pharma, Oncology Module, Tier 3 | £155,000 |
| 1B | <50 Heads, 1 module, 4 users | £21,000 |
| 1B | Contract Orgs (>200 Heads), 7 modules, 60 users | £400,000 |
| 1C | Top 1-50 Pharma, 5 modules | 30% |

If a blank-maximum row returns nothing, tell Claude. The fix is to fill the blank maximums with 9999 in the data.

[Back to steps](#pricing-model-rebuild--revenue-cloud-pricing-setup)

---

## Step 2. Beacon Pricing Procedure

The procedure runs the same steps on every quote. The price tables decide what applies:
- **Beacon Multi-Module Discount** only has rows for **Top 1-50 Pharma** and **>200 Heads** (Per Module price books).
- **Beacon Module Count Price** only has rows for **<50 Heads, 51-200 Heads, PE-VC** and **Contract Orgs** (Module Count price books).

So each quote gets either the discount or the module count total, never both. No branch on Pricing Method, and no context definition change.

### 2A. Clone the default procedure

1. **Setup** → Quick Find **Pricing Procedures**.
2. Open **Revenue Management Default Pricing Procedure Auto** → **Save As / Clone**.
3. Name it **Beacon Pricing Procedure**. Keep the context **SalesTransactionContextAuto**.
4. Open the new version in the builder.

### 2B. Leave the existing steps as they are

You don't need to remove anything. The old seat-band schedules, multi-year escalators and bundles were removed from the data, so the **Volume Discount**, **Tier Discount** and **Bundle-Based Price** steps find nothing and change no prices.

### 2C. Add the Beacon steps, after List Price

Add them in this order.

**1. Number of Users per line.** Add a **List Filter** on the line's attribute values, keeping attribute **Number of Users**. Store the value as a number in a new line variable `LineUsers`.

**2. Tier per line.** Add a **Calculation / Formula** element with output `LineTier`, from `LineUsers`:
- ≤3 = 1, ≤5 = 2, ≤10 = 3, ≤20 = 4, ≤50 = 5, otherwise 6.

**3. List price from the tier table.** Add a **Lookup Table** on **Beacon Tier Price** (1A):
- Inputs: the transaction's price book, the line's product, `LineTier`.
- Map the output **List Price** to the line's List Price / Unit Price tag. This replaces the price book entry price.

**4. Quote-level counts.** Add an **Aggregate** (or **List Group**) over the lines:
- Count of lines → `ModuleCount`
- Max of `LineUsers` → `QuoteMaxUsers`

**5. Multi-module discount.** Add a **Lookup Table** on **Beacon Multi-Module Discount** (1C), with inputs the price book and `ModuleCount`. Output → `DiscountPct`.
- Then a **Discount / Adjustment** element that applies `DiscountPct` as a percentage to every line **when a value was found**.
- No row found (1 module, or a Module Count price book) means no discount.

**6. Module count total.** Add a **Lookup Table** on **Beacon Module Count Price** (1B), with inputs the price book, `ModuleCount` and `QuoteMaxUsers`. Output → `QuoteTotal`.
- **When a value was found:** a **Calculation** sets each line's net price to `QuoteTotal ÷ ModuleCount`, then an **adjustment amount** of (list price − net price) is applied on each line, so the lines add up to the total. If the builder can't put any rounding pennies on the last line, accept the small rounding.
- No row found (a Per Module price book) means nothing changes.

**Note for Module Count price books:** each line's *list* price comes from that line's own users (step 3), not from the quote's highest users. The net price and the quote total are still the module count total, so this only affects the list price shown on each line.

### 2D. Test in the builder, then activate

1. Run the [test cases](#test-cases) with **Simulate / Test** in the builder.
2. **Activate** the version.
3. **Salesforce Pricing Setup** → set **Beacon Pricing Procedure** as the default pricing procedure.

[Back to steps](#pricing-model-rebuild--revenue-cloud-pricing-setup)

---

## Step 3. Sync pricing data and test

1. **Setup** → Quick Find **Salesforce Pricing Setup** → **Sync Pricing Data**. Wait a few minutes; it runs in the background.
2. Open quote **Product Config 1** (<50 Heads, ADC at 4 users) and reprice it. Expected **£21,000** (Entry, Enterprise). At 3 users it should drop to **£18,000**.
3. Run the [test cases](#test-cases) on real quotes from Browse Catalogs.
4. Run acceptance tests 8–17 in `docs/release-notes/Pricing-Model-Rebuild.md`.

**Sync Pricing Data again whenever pricing data changes:** price book entries, any of the three Beacon price tables, the decision tables or the pricing procedure.

[Back to steps](#pricing-model-rebuild--revenue-cloud-pricing-setup)

---

## Test cases

| Price book | Lines | Expected total |
|---|---|---|
| <50 Heads | ADC 4 users | **£21,000** |
| <50 Heads | Oncology 2 users, ADC 2 users | **£23,000** (Starter, Up to 3 users) |
| <50 Heads | Oncology 2 users, ADC 4 users | **£26,000** (Starter, Enterprise) |
| Contract Orgs (>200 Heads) | ADC 3 users, Cell Therapy 8 users | **£100,000** (Starter, Up to 10 users) |
| Top 1-50 Pharma | Oncology 8, CVRM 20, ADC 3 | **£324,000** (£405,000 less 20%) |

[Back to steps](#pricing-model-rebuild--revenue-cloud-pricing-setup)

---

## If something doesn't work

- **Prices still show the price book entry price:** check the Beacon Pricing Procedure is active and set as the default, then **Sync Pricing Data**.
- **A decision table returns nothing for Platform / Enterprise / 4+ rows:** the blank maximums aren't matching. Tell Claude to fill them with 9999.
- **The builder can't read the Number of Users attribute (2C, step 1):** send Claude a screenshot of the elements offered. The fallback is to price from the quote line's `Number_of_Users__c` field.
- **Anything else:** send Claude a screenshot of the error or the element.

[Back to steps](#pricing-model-rebuild--revenue-cloud-pricing-setup)
