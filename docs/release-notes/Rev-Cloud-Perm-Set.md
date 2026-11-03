# "Rev-Cloud-Perm-Set" – Release Notes

## Requirements

- Create a permission set group named **Beacon - Revenue Cloud User**.
- The group must contain every permission set a user needs to work in Revenue Cloud, so one
  group assignment gives a user full day-to-day Revenue Cloud access.

## Release Notes

A new permission set group, `Beacon_Revenue_Cloud_User` (**Beacon - Revenue Cloud User**), was
created. It holds the Salesforce-provided (`force` namespace) Revenue Cloud permission sets
that a standard Revenue Cloud user needs to run the full quote-to-contract process. It is meant
for users who sell, not for admins who set up the catalog or pricing.

| # | Permission Set API Name | Label | Permission Set License | Why it's included |
|---|---|---|---|---|
| 1 | `ProductCatalogManagementViewer` | Product Catalog Management Viewer | Product Catalog Management Viewer | View products, catalogs, categories and attributes. |
| 2 | `ProductDiscoveryUser` | Product Discovery User | Product Discovery User | Browse and search the catalog to add products to quotes. |
| 3 | `CorePricingRunTimeUser` | Salesforce Pricing Run Time User | Salesforce Pricing Run Time | Run price calculations with price books and pricing procedures. |
| 4 | `IndustriesConfiguratorPlatformApi` | Product Configurator | Product Configuration User | Configure bundles and attributes on quote lines. |
| 5 | `BRERuntime` | Rule Engine Runtime | Business Rules Engine Runtime | Run the decision tables and expression sets that pricing and configuration rules use. |
| 6 | `DecimalQuantityRuntime` | DecimalQuantityRuntime | Decimal Quantity Runtime User | Enter decimal quantities on quote and order lines. |
| 7 | `RevLifecycleManagementQuotePricesTaxes` | Price and Tax Calculation for Quoting | Revenue Cloud User | Calculate prices and taxes on quotes. |
| 8 | `RevLifecycleManagementCreateOrderFromQuote` | Create Orders from Quotes | Revenue Cloud User | Create orders from accepted quotes. |
| 9 | `RevLifecycleManagementCreateContractApi` | CreateContract API | Revenue Cloud User | Create contracts from quotes and orders. |
| 10 | `RevLifecycleManagementCoreCPQAssetization` | Assetize Order | Revenue Cloud User | Turn activated orders into assets. |
| 11 | `RevLifecycleManagementInitiateAmendmentApi` | InitiateAmendment API | Revenue Cloud User | Start amendments on assets. |
| 12 | `RevLifecycleManagementInitiateRenewalApi` | InitiateRenewal API | Revenue Cloud User | Start renewals on assets. |
| 13 | `RevLifecycleManagementInitiateCancellationApi` | InitiateCancellation API | Revenue Cloud User | Start cancellations on assets. |
| 14 | `DROOrderSubmitInitiateUser` | Submit Transactions User | Fulfillment User PSL | Submit orders to Dynamic Revenue Orchestrator for fulfillment. |
| 15 | `DocGenUser` | DocGen User | DocGen Designer | Generate quote and contract documents. |
| 16 | `OmniStudioExecution` | Omnistudio User | OmniStudio | Run the OmniStudio components that Document Generation and guided flows use. |

`hasActivationRequired` is false and the status is `Updated`, the same as `Beacon_Baseline`.

**Why these permission sets:** the list was taken from the Revenue Cloud permission sets in Beacon
HTC Dev and Beacon Prod, and covers each step a user takes: find a product, configure it, price
it, quote it, create the order and contract, submit it for fulfillment, and later amend, renew
or cancel the asset.

**What was left out, and why:**

- **Admin and designer permission sets** (Product Catalog Management Designer, Salesforce Pricing
  Admin/Design Time/Manager, Product Configuration Rules/Constraints Designer, Rule Engine
  Designer, DecimalQuantityDesigntime, DocGen Designer, Omnistudio Admin, Fulfillment Designer,
  DRO Admin User, Usage: Design User, Tax Configuration, Product Discovery Admin). These are for
  people who set up Revenue Cloud, not people who use it. They belong in a separate admin group.
- **Billing permission sets** (Billing Admin, Billing Operations, Billing Customer Service, Credit
  Memo Operations, Accounts Receivables Admin, Tax Admin, and the Billing API sets). These are for
  Finance and billing operations, not every Revenue Cloud user.
- **Rate Management** (`RatingRunTimeUser`). Only needed for usage-based products.
- **Place Supplemental Orders** (`PlaceSupplementalOrders`). Only needed to amend an order that is
  still in fulfillment.
- **API-only permission sets** (CalculatePrices API, CalculateTaxes API, PlaceOrder API,
  ProductAndPriceConfiguration API, ProductImport API). These are for integrations that call the
  Revenue Cloud APIs directly. The quoting UI does not need them.
- **External Apps Login, C2C (`Cloud Integration User`) and Self-Service Agent** permission sets.
  These are for other license types or system users.

Any of these can be added to the group later if the business needs them.

**Licenses:** permission set groups don't use licenses, but each user assigned this group must
also have every permission set license listed in the table above. Without them, the assignment
fails.

## Acceptance Criteria

1. **Group exists.** Go to Setup → Permission Set Groups. Confirm **Beacon - Revenue Cloud User**
   is listed with API name `Beacon_Revenue_Cloud_User` and status **Updated**.
2. **Group contents.** Open the group and click **Permission Sets in Group**. Confirm the 16
   permission sets in the table above are listed, and no others.
3. **Assign licenses.** Pick a test user with a Salesforce license. On the user record, assign the
   permission set licenses: Revenue Cloud User, Product Catalog Management Viewer, Product
   Discovery User, Salesforce Pricing Run Time, Product Configuration User, Business Rules Engine
   Runtime, Decimal Quantity Runtime User, Fulfillment User PSL, DocGen Designer and OmniStudio.
4. **Assign the group.** On the same user, open Permission Set Group Assignments and assign
   **Beacon - Revenue Cloud User**. Confirm the assignment saves with no license errors.
5. **Browse the catalog.** Log in as the test user. Open the Product Catalog Management app.
   Confirm catalogs and products can be viewed but not edited.
6. **Build a quote.** From an Opportunity, create a Quote. Use **Browse Catalogs** to add a
   product and a bundle. Configure the bundle and confirm the configurator opens and saves.
7. **Price the quote.** Confirm prices and taxes calculate on the quote lines. Enter a decimal
   quantity on a line and confirm it saves.
8. **Generate a document.** Generate a quote document. Confirm the document is created.
9. **Create an order and contract.** Accept the quote and create an order from it. Create a
   contract. Confirm both are created.
10. **Submit the order.** Activate and submit the order. Confirm it is sent for fulfillment and
    assets are created once it is fulfilled.
11. **Amend, renew and cancel.** From an asset on the account, start an amendment, a renewal and a
    cancellation. Confirm each one creates a new quote.
12. **Negative test.** Remove the group from the test user. Confirm the user can no longer use
    Browse Catalogs or create an order from a quote.

## Post Deployment Items

- **Beacon UAT does not have all of these permission sets yet.** UAT is missing the Revenue Cloud
  User license permission sets (`RevLifecycleManagement*`) and `IndustriesConfiguratorPlatformApi`.
  A deploy to UAT will fail until Revenue Cloud is provisioned there. Either provision Revenue
  Cloud in UAT first, or deploy to Beacon HTC Dev and Production only. All 16 permission sets
  exist in Beacon HTC Dev and Beacon Prod.
- **Check license counts.** Beacon HTC Dev has 5 seats for most of the licenses above. Before
  assigning the group, confirm each org has enough seats for the users who need it.
- **Assign licenses and the group** to every Revenue Cloud user (steps 3 and 4 above).
- **Remove direct assignments.** If any of these permission sets were assigned to users directly,
  remove them once the user has the group.
- **Not added to the persona User Access Policies.** Revenue Cloud access depends on licenses, not
  only Persona, so the group is assigned by hand. If it should be assigned automatically, a User
  Access Policy can be added later that also grants the licenses.

## Component Manifest

Github Branch: [Rev-Cloud-Perm-Set](https://github.com/aaroncrear/BeaconImplementation/tree/Rev-Cloud-Perm-Set)

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Permission Set Group | N/A | `Beacon_Revenue_Cloud_User` | Beacon - Revenue Cloud User | Created | Holds the 16 Salesforce Revenue Cloud permission sets a standard user needs to browse the catalog, configure and price quotes, generate documents, create orders and contracts, submit orders, and amend, renew or cancel assets. |
