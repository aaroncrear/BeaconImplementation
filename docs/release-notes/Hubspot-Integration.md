# "Hubspot-Integration" – Release Notes

## Requirements

Set up a least-privilege permission set for the HubSpot–Salesforce integration user:

- The integration user must be able to sync **Accounts, Campaigns, Contacts, Leads, and
  Opportunities** with HubSpot. HubSpot requires **Modify All** on each object it syncs.
- HubSpot also requires **View Setup and Configuration**, **API Enabled**, and **Modify
  Metadata** (for the HubSpot Embed window and deal sync).
- The integration user must **never** have the org-wide **View All Data** or **Modify All
  Data** permissions, and must have no access to objects outside the five it syncs.

## Release Notes

**Why the permission set had full access.** `Beacon_Hubspot_Integration` was first set up
with **Download AppExchange Packages**, which HubSpot lists as a requirement. When that
permission is enabled, Salesforce automatically turns on **Modify All Data**, **View All
Data**, **Manage Users**, **Customize Application**, and related permissions. Modify All
Data in turn writes an object permission with full access, View All and Modify All on
every object in the org (613 objects in the retrieved file). Unticking the system
permissions afterwards does not remove those per-object records, so the permission set
still had full access to every object.

**Object permissions trimmed to the five synced objects.** The permission set now holds
object permissions only for `Account`, `Campaign`, `Contact`, `Lead`, and `Opportunity`.
Each has Read, Create, Edit, Delete, View All, and Modify All, as HubSpot requires. All
other object permissions (608) were removed from the file.

**System permissions trimmed.** Sixteen system permissions came over in the retrieved file.
Most of them were switched on along with Modify All Data, such as Transfer Any Record,
Manage Quotas, Override Forecasts, View All Forecasts, Import Leads, Convert Leads, and
Password Never Expires. Only these four are kept:

- `ViewSetup` – View Setup and Configuration, required by HubSpot.
- `ModifyMetadata` – required by HubSpot for the Embed window and deal sync.
- `EditTask` and `EditEvent` – let HubSpot sync activities as Salesforce Tasks and Events.

**What was not added, and why.**

- **API Enabled** is not in the permission set. On the Salesforce Integration user licence
  it comes from the user's profile. The **Beacon Integration User** profile already has
  API Enabled and API Only User.
- **Download AppExchange Packages** and **Customize Application** are left out on purpose,
  because enabling them brings back org-wide Modify All Data. A System Administrator
  installs and upgrades the HubSpot package instead (see Post Deployment Items).
- **Field-level security** is not included yet. The permission set has object access only,
  so the integration user can see only fields that aren't controlled by field-level
  security. Field access for the synced fields, including `Task.Type` (which HubSpot
  requires to be visible), will be added once the field mapping is agreed.

## Acceptance Criteria

1. In Setup, open **Permission Sets → Beacon - Hubspot Integration → Object Settings**.
   Confirm that only Accounts, Campaigns, Contacts, Leads, and Opportunities show access,
   and that each has Read, Create, Edit, Delete, View All, and Modify All.
2. Open any other object (for example Cases or Products) and confirm it has no access.
3. Open **System Permissions** and confirm that only View Setup and Configuration, Modify
   Metadata, Edit Tasks, and Edit Events are enabled. Confirm that View All Data, Modify
   All Data, Download AppExchange Packages, Customize Application, Manage Users, and
   Transfer Record are all unchecked.
4. In the Developer Console, run this query and confirm it returns exactly 5 rows (Account,
   Campaign, Contact, Lead, Opportunity):
   `SELECT SobjectType FROM ObjectPermissions WHERE Parent.Name = 'Beacon_Hubspot_Integration'`
5. Create a user on the **Beacon Integration User** profile and assign this permission
   set. In HubSpot, connect to Salesforce while logged in as that user. Confirm the
   connection succeeds and that a test Contact and Lead sync in both directions.

## Post Deployment Items

1. **Clear the leftover object permissions in the org before or during deployment.** A
   permission set deployment only updates the objects listed in the file and leaves every
   other object in the org unchanged. Deploying this file on its own would leave Modify
   All on the other objects. Do one of the following:
   - Delete `Beacon_Hubspot_Integration` in the target org (nobody is assigned to it) and
     deploy this file as a new permission set, **or**
   - In Gearset, deploy with the object permission removals included, so the org matches
     the file.
   Then run Acceptance Criteria step 4 to confirm only 5 object permissions remain.
2. A System Administrator installs the HubSpot package from AppExchange, choosing
   "Install for Admins Only" or for specific profiles. The integration user is not used
   for the install.
3. Create the HubSpot integration user on the **Beacon Integration User** profile and
   assign `Beacon_Hubspot_Integration`.
4. Connect HubSpot to Salesforce as the integration user. If the login fails because the
   user is API Only, the integration user will need a full Salesforce licence and the
   permission set's licence will need to change.
5. Make the Task **Type** field visible to the integration user, as HubSpot requires.

## Component Manifest

Github Branch: [Hubspot-Integration](https://github.com/aaroncrear/BeaconImplementation/tree/Hubspot-Integration)

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|-------------|
| 1 | Permission Set | N/A | Beacon_Hubspot_Integration | Beacon - Hubspot Integration | Created | Integration user permission set on the Salesforce API Integration licence. Holds Modify All on Account, Campaign, Contact, Lead, and Opportunity only, plus View Setup and Configuration, Modify Metadata, Edit Tasks, and Edit Events. |
