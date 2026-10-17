# "Hubspot-Integration" – Release Notes

## Requirements

Set up a least-privilege permission set for the HubSpot–Salesforce integration user:

- The integration user must be able to sync **Accounts, Campaigns, Contacts, Leads, and
  Opportunities** with HubSpot. HubSpot requires **Modify All** on each object it syncs.
- HubSpot also requires **View Setup and Configuration**, **API Enabled**, and **Modify
  Metadata** (for the HubSpot Embed window and deal sync).
- The integration user must **never** have the org-wide **View All Data** or **Modify All
  Data** permissions, and must have no access to objects outside the five it syncs.

Add custom fields for the HubSpot integration, built outside the HubSpot managed package:

| Field | Object | Type | Purpose |
|-------|--------|------|---------|
| Tier | Account | Picklist (1-5) | Sales prioritisation; core segmentation dimension. Population method and ownership to be confirmed by Beacon. |
| HubSpot Lead Score | Lead / Contact | Number | Receives the HubSpot-calculated score. |
| ABM Flag | Account | Checkbox | Manual checkbox set by Beacon; flagged on the parent Salesforce account and applied to child accounts (approach to be confirmed). |
| Active Drug Count | Account | Number | Single total value; manual upload at go-live; per-module breakdown after the Beacon platform-Salesforce integration. |
| Funding | Account | Currency / text | Beacon platform signal; sourced from data providers. |
| Module Interest | Lead / Contact | Multi-select picklist | Receives module interest from HubSpot; used for white-space mapping. Uses the module global value set. |
| User Persona | Lead / Contact | Text formula | Assigns a Beacon persona group from the job title (see below). |

**User Persona.** Similar to the Seniority Score, assign a persona group when the job title
contains a value from the table below. If no value is found in the first group, the logic
checks the next, and so on. For example, "Chief Translation Officer" is assigned
Translational, because that group is checked before Senior Leadership.

| Group | Job title contains |
|-------|--------------------|
| Competitor Intelligence | competit, intelligence, competitor, market intelligence, strategic intelligence, commercial intelligence, portfolio intelligence, pipeline intelligence, landscape, forecast, forecasting, insights, analyst, analytics, benchmarking |
| Translational | translation, translational, biomarker, precision medicine, translational medicine, translational science, translational research, patient selection, companion diagnostic |
| Business Development | business development, BD, alliance, alliances, licensing, partner, partnership, partnering, corporate development, search and evaluation, search & evaluation, external innovation, deal, transaction, M&A, acquisitions, investor relations |
| Clinical Research | clinical, clinical trial, clinical development, medical affairs, medical, physician, investigator, clinical operations, clinical research, clinical scientist, clinical project, clinical programme, CRA, CRC, study manager, study director, patient recruitment |
| Research | research, scientist, scientific, researcher, fellow, postdoc, postgraduate, professor, lecturer, engineer, microbiologist, microbiology, biology, biologist, immunology, immunologist, chemistry, chemist, pharmacology, pharmacologist, discovery, preclinical, laboratory, lab, R&D, innovation |
| Senior Leadership | chief, executive, VP, vice president, SVP, EVP, AVP, head, leader, director, managing director, founder, founding, owner, president, chair, board, board member, board director, CFO, CHRO, CIO, CMO, COO, CPO, CRO, CSO, CEO, general counsel, partner, regional head, global head |

Field access:

- **Beacon - Hubspot User:** read access to all the new fields.
- **Beacon - Hubspot Integration:** read access to all the new fields, and edit access to
  HubSpot Lead Score and Module Interest.
- Every field description states that it is a custom field created specifically for the
  HubSpot integration, outside of the HubSpot managed package.

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

**System permissions.** This build is about object permissions, and system permissions are
kept as configured in the org with two exceptions. **Import Solutions** depends on Create,
Read, Edit and Delete on Solutions, so the deployment failed once Solution was removed.
Import Solutions and the related **Manage Categories** were removed rather than giving
the integration user access to Solutions, which HubSpot doesn't use. The remaining 14 are
unchanged: Convert Leads, Edit Events, Edit Tasks, Import Leads, Manage Quotas, Modify
Metadata, Override Forecasts, Password Never Expires, Transfer Record, Transfer Leads, Use
Team Reassignment Wizards, View All Forecasts, View Roles and Role Hierarchy, and View
Setup and Configuration. View All Data, Modify All Data, and Download AppExchange Packages
were already removed in the org before the file was retrieved.

**Beacon Integration User profile.** The profile was retrieved from the org so it is
included with the integration build. Its 218 tab settings were removed from the file. On
deployment Salesforce rejected `standard-PricebookEntry` ("not a valid tab"), because some
standard tabs can be retrieved but not deployed. This profile is API Only, so its users
never see tabs, and a profile deployment leaves any tab setting that isn't in the file
unchanged in the org. Removing the tab settings therefore changes nothing in the org and
avoids the same error on other tabs. Everything else in the profile (API Enabled, API Only
User, field permissions, layout assignments, record type and app visibility) is as
retrieved.

**Beacon - Hubspot User permission set.** A new, empty permission set,
`Beacon_Hubspot_User`, on the Salesforce licence for Beacon users who work with HubSpot.
It will hold any access to customizations built outside the HubSpot managed package, so
that this access stays separate from the package's own permission sets and from the
integration user's `Beacon_Hubspot_Integration`. It grants no permissions yet. Permissions
will be added as the HubSpot customizations are built.

**HubSpot custom fields.** Ten fields were created. Every description ends with "Custom
field created specifically for the HubSpot integration, outside of the HubSpot managed
package." so admins can tell them apart from the package's own fields.

- `Account.Tier__c` – restricted picklist with values 1, 2, 3, 4, 5 and no default.
- `Account.ABM_Flag__c` – checkbox, default unchecked. Copying the flag from parent to
  child accounts is not built, because the approach is still to be confirmed.
- `Account.Active_Drug_Count__c` – Number(18, 0).
- `Account.Funding__c` – Currency(18, 0). The requirement allowed currency or text.
  Currency was chosen so funding can be sorted, filtered, summed in reports and converted
  between currencies. If data providers send values such as "Series B", this needs to
  become a text field before any data is loaded.
- `Lead.HubSpot_Lead_Score__c` and `Contact.HubSpot_Lead_Score__c` – Number(18, 0).
- `Lead.Module_Interest__c` and `Contact.Module_Interest__c` – restricted multi-select
  picklist using the existing **Primary Module** global value set (`Primary_Module`), the
  same set used by Opportunity and Campaign Primary Module and Campaign Related Modules.
  New modules only need to be added once, in the global value set.
- `Lead.User_Persona__c` and `Contact.User_Persona__c` – Text formula on Title. The two
  formulas are identical.

**How the User Persona formula works.** The formula checks the groups in the order of the
requirements table (Competitor Intelligence, Translational, Business Development, Clinical
Research, Research, Senior Leadership) and returns the first group with a matching
keyword. It returns blank when the title is empty or no keyword matches. Design choices:

- **Case.** Words are matched case-insensitively (`CONTAINS( LOWER( Title ), "head" )`), so
  "Head of Research", "head of research" and "HEAD OF RESEARCH" all match. Acronyms (BD,
  CRA, CRC, VP, CFO, CHRO, CIO, CMO, COO, CPO, CRO, CSO, CEO) are matched case-sensitively
  in capitals. Otherwise "bd", "vp" or "cra" would match inside ordinary words, for
  example "democracy" containing "cra".
- **"lab"** only matches at the start of a word (`" " & LOWER( Title )` contains `" lab"`),
  so "Lab Manager" matches Research but "Collaboration Manager" does not.
- **Duplicate keywords removed.** Salesforce limits a formula to 3,900 characters, so
  keywords that a shorter keyword in the same or an earlier group already matches are left
  out. The results are the same. For example, "director" matches "managing director" and
  "board director", "intelligence" matches "market intelligence", "translation" matches
  "translational medicine", "clinical" matches "clinical trial", "partner" matches
  "partnership", "chemist" matches "chemistry", and "VP" matches SVP, EVP and AVP. The
  formula is 3,361 characters.
- **Order decides overlaps.** "partner" appears in both Business Development and Senior
  Leadership, so it always returns Business Development. Likewise "Clinical Research
  Director" returns Clinical Research and "Director of Research" returns Research, because
  those groups are checked before Senior Leadership.

**Field access.** `Beacon_Hubspot_User` has read access to all ten fields.
`Beacon_Hubspot_Integration` has read access to all ten fields and edit access to
HubSpot Lead Score and Module Interest on Lead and Contact, the two fields HubSpot writes
to. The formula fields are read-only by definition. No page layouts were changed.

**What was not added, and why.**

- **API Enabled** is not in the permission set. On the Salesforce Integration user licence
  it comes from the user's profile. The **Beacon Integration User** profile already has
  API Enabled and API Only User.
- **Download AppExchange Packages** and **Customize Application** are left out on purpose,
  because enabling them brings back org-wide Modify All Data. A System Administrator
  installs and upgrades the HubSpot package instead (see Post Deployment Items).
- **Field-level security for standard and other existing fields** is not included yet.
  Apart from the ten new HubSpot fields, the integration permission set has object access
  only, so the integration user can see only fields that aren't controlled by field-level
  security. Field access for the other synced fields, including `Task.Type` (which HubSpot
  requires to be visible), will be added once the field mapping is agreed.

## Acceptance Criteria

1. In Setup, open **Permission Sets → Beacon - Hubspot Integration → Object Settings**.
   Confirm that only Accounts, Campaigns, Contacts, Leads, and Opportunities show access,
   and that each has Read, Create, Edit, Delete, View All, and Modify All.
2. Open any other object (for example Cases or Products) and confirm it has no access.
3. Open **System Permissions** and confirm that View All Data, Modify All Data, Download
   AppExchange Packages, Customize Application, and Manage Users are all unchecked, and
   that View Setup and Configuration and Modify Metadata are checked.
4. In the Developer Console, run this query and confirm it returns exactly 5 rows (Account,
   Campaign, Contact, Lead, Opportunity):
   `SELECT SobjectType FROM ObjectPermissions WHERE Parent.Name = 'Beacon_Hubspot_Integration'`
5. Create a user on the **Beacon Integration User** profile and assign this permission
   set. In HubSpot, connect to Salesforce while logged in as that user. Confirm the
   connection succeeds and that a test Contact and Lead sync in both directions.
6. In Setup, open **Permission Sets** and confirm **Beacon - Hubspot User** exists, with
   API Name `Beacon_Hubspot_User`, License **Salesforce**, and the description "Holds
   customization made outside of the Hubspot managed package."
7. In **Object Manager**, confirm each new field exists with the type above and that its
   description ends with "Custom field created specifically for the HubSpot integration,
   outside of the HubSpot managed package.": Account Tier, ABM Flag, Active Drug Count
   and Funding; Lead and Contact HubSpot Lead Score, Module Interest and User Persona.
8. Open **Tier** and confirm the values are 1, 2, 3, 4, 5 with no default. Open **Module
   Interest** on Lead and Contact and confirm it uses the **Primary Module** global value
   set.
9. Open **Permission Sets → Beacon - Hubspot User → Object Settings** for Account, Lead and
   Contact. Confirm all the new fields are **Read Access** only.
10. Open **Beacon - Hubspot Integration** the same way. Confirm all the new fields have
    Read Access, and that HubSpot Lead Score and Module Interest on Lead and Contact also
    have **Edit Access**.
11. Test **User Persona** on a Lead and on a Contact by setting the Title and checking the
    result:

    | Title | Expected User Persona |
    |-------|-----------------------|
    | Market Intelligence Analyst | Competitor Intelligence |
    | Chief Translation Officer | Translational |
    | Head of Biomarker Strategy | Translational |
    | VP Business Development | Business Development |
    | Senior Partner | Business Development |
    | BD Manager | Business Development |
    | Clinical Research Director | Clinical Research |
    | CRA | Clinical Research |
    | Senior Scientist | Research |
    | Lab Manager | Research |
    | Collaboration Manager | (blank) |
    | Head of Operations | Senior Leadership |
    | CEO | Senior Leadership |
    | Office Manager | (blank) |
    | (no title) | (blank) |

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
6. Add the new fields to the Account, Lead and Contact page layouts or Lightning pages
   where users need to see them. This build does not change any layouts.
7. Assign **Beacon - Hubspot User** to the Beacon users who need to see the HubSpot fields.

## Component Manifest

Github Branch: [Hubspot-Integration](https://github.com/aaroncrear/BeaconImplementation/tree/Hubspot-Integration)

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|-------------|
| 1 | Permission Set | N/A | Beacon_Hubspot_Integration | Beacon - Hubspot Integration | Created | Integration user permission set on the Salesforce API Integration licence. Object permissions limited to Modify All on Account, Campaign, Contact, Lead, and Opportunity. Read access to the ten HubSpot custom fields, with edit on HubSpot Lead Score and Module Interest; 608 other object permissions removed. Import Solutions and Manage Categories system permissions removed; other system permissions unchanged. |
| 2 | Profile | N/A | Beacon Integration User | Beacon Integration User | Updated | Salesforce Integration licence profile for integration users (API Enabled, API Only User). Tab settings removed from the file so the profile deploys; no change in the org. |
| 3 | Permission Set | N/A | Beacon_Hubspot_User | Beacon - Hubspot User | Created | Salesforce licence permission set for Beacon users. Holds customization made outside of the HubSpot managed package. Read access to the ten HubSpot custom fields. |
| 4 | Custom Field | Account | Account.Tier__c | Tier | Created | Restricted picklist, values 1-5. Sales prioritisation and core segmentation. HubSpot integration field, outside the HubSpot managed package. |
| 5 | Custom Field | Account | Account.ABM_Flag__c | ABM Flag | Created | Checkbox set manually by Beacon on the parent account. HubSpot integration field, outside the HubSpot managed package. |
| 6 | Custom Field | Account | Account.Active_Drug_Count__c | Active Drug Count | Created | Number(18, 0). Total active drug count, uploaded manually at go-live. HubSpot integration field, outside the HubSpot managed package. |
| 7 | Custom Field | Account | Account.Funding__c | Funding | Created | Currency(18, 0). Beacon platform signal sourced from data providers. HubSpot integration field, outside the HubSpot managed package. |
| 8 | Custom Field | Lead | Lead.HubSpot_Lead_Score__c | HubSpot Lead Score | Created | Number(18, 0). Receives the HubSpot-calculated score. HubSpot integration field, outside the HubSpot managed package. |
| 9 | Custom Field | Lead | Lead.Module_Interest__c | Module Interest | Created | Multi-select picklist on the Primary Module global value set. Receives module interest from HubSpot. HubSpot integration field, outside the HubSpot managed package. |
| 10 | Custom Field | Lead | Lead.User_Persona__c | User Persona | Created | Text formula. Assigns a Beacon persona group from the Title. HubSpot integration field, outside the HubSpot managed package. |
| 11 | Custom Field | Contact | Contact.HubSpot_Lead_Score__c | HubSpot Lead Score | Created | Number(18, 0). Receives the HubSpot-calculated score. HubSpot integration field, outside the HubSpot managed package. |
| 12 | Custom Field | Contact | Contact.Module_Interest__c | Module Interest | Created | Multi-select picklist on the Primary Module global value set. Receives module interest from HubSpot. HubSpot integration field, outside the HubSpot managed package. |
| 13 | Custom Field | Contact | Contact.User_Persona__c | User Persona | Created | Text formula. Assigns a Beacon persona group from the Title. HubSpot integration field, outside the HubSpot managed package. |
