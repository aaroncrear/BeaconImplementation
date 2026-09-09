# "claude/revenue-cloud-perm-sets" – Release Notes

## Requirements

Beacon needs two Permission Set Groups so Revenue Cloud access can be assigned in two clean
tiers instead of hand-picking individual permission sets per user:

- **Revenue Cloud Admin** – bundles the Permission Sets needed to configure and administer
  Revenue Cloud (catalog setup, product discovery configuration, context service setup, and order
  operations monitoring).
- **Revenue Cloud User** – bundles the Permission Sets needed for day-to-day Revenue Cloud usage
  (browsing/viewing the product catalog and consuming context data at runtime).

## Release Notes

Two new custom Permission Set Groups were added under `unpackaged/main/default/permissionsetgroups`.
Both reference standard (`force`-namespaced) Permission Sets already available in the org for the
native Revenue Cloud (Revenue Lifecycle Management) feature set — no new custom Permission Sets
were created, since Revenue Cloud's setup and usage capabilities are exposed entirely through
Salesforce's own standard Permission Sets.

**Revenue Cloud Admin** groups the Permission Sets used to configure and administer Revenue Cloud:
`Command Center` (monitor/troubleshoot order fulfillment), `Context Service Admin` (CRUD on context
entities), `Product Catalog Management Designer` (configure the product catalog), `Product
Discovery Admin` (customize the product browsing/discovery experience), `Unified Catalog Admin`
(set up the unified catalog), and `Unified Catalog Agent` (run the unified catalog's service
process).

**Revenue Cloud User** groups the Permission Sets used for day-to-day usage: `Context Service
Runtime` (read context entities), `Product Catalog Management Viewer` (read-only catalog access),
and `Product Discovery User` (use the product browsing/discovery experience).

The specific Permission Sets included reflect what's standard for Revenue Cloud's native Product
Catalog Management, Unified Catalog, Product Discovery, Context Service, and Order Management
Command Center capabilities as verified in a connected Revenue Cloud-enabled org. Salesforce CPQ,
Salesforce Billing, and industry-vertical features (e.g. Rebate Management, Channel Inventory) are
separate, license-gated products and were intentionally excluded — see Post Deployment Items if
Beacon's org also uses those.

## Acceptance Criteria

1. In Setup > Permission Set Groups, confirm `Revenue Cloud Admin` and `Revenue Cloud User` both
   exist and show Status = Updated (no compile/merge errors on the group).
2. Open `Revenue Cloud Admin` and confirm its description reads "Contains Permission Sets for
   Revenue Cloud configuration and administration." and that it contains exactly: Command Center,
   Context Service Admin, Product Catalog Management Designer, Product Discovery Admin, Unified
   Catalog Admin, and Unified Catalog Agent.
3. Open `Revenue Cloud User` and confirm its description reads "Contains Permission Sets for
   Revenue Cloud usage." and that it contains exactly: Context Service Runtime, Product Catalog
   Management Viewer, and Product Discovery User.
4. Assign `Revenue Cloud Admin` to a test admin user and confirm they can access Product Catalog
   Management setup, Product Discovery configuration, Context Service setup, the Unified Catalog
   setup pages, and the Command Center app.
5. Assign `Revenue Cloud User` to a test end user and confirm they can view the product catalog and
   use the product discovery/browsing experience, without access to the admin configuration pages
   above.
6. Confirm neither group has `hasActivationRequired` enabled, so assignment takes effect
   immediately without a separate activation step.

## Post Deployment Items

- Confirm with Beacon whether Salesforce CPQ, Salesforce Billing, or any industry-vertical add-ons
  (Rebate Management, Channel Inventory, Ship and Debit, Price Protection, Design Registration) are
  also in scope for Revenue Cloud access — those were excluded from both groups since they are
  separate, license-gated products not confirmed to be part of Beacon's Revenue Cloud footprint.
- Assign `Revenue Cloud Admin` and `Revenue Cloud User` to the appropriate Beacon users/groups;
  this deploy only creates the Permission Set Groups, it does not assign them.

## Component Manifest

Github Branch: https://github.com/aaroncrear/BeaconImplementation/tree/claude/revenue-cloud-perm-sets

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Permission Set Group | N/A | Revenue_Cloud_Admin | Revenue Cloud Admin | Created | Bundles force\_\_CommandCenter, force\_\_ContextServiceAdminPsl, force\_\_ProductCatalogManagementAdministrator, force\_\_ProductDiscoveryAdmin, force\_\_UnifiedCatalogAdmin, and force\_\_UnifiedCatalogAgent for Revenue Cloud configuration/administration. |
| 2 | Permission Set Group | N/A | Revenue_Cloud_User | Revenue Cloud User | Created | Bundles force\_\_ContextServiceRuntimePsl, force\_\_ProductCatalogManagementViewer, and force\_\_ProductDiscoveryUser for day-to-day Revenue Cloud usage. |
