# "Beacon-Subscriptions" – Release Notes

## Requirements

This build was deployed directly to the `Beacon-Subscriptions` branch via Gearset (no written
requirements doc was supplied alongside the deploy). Based on the metadata that was pushed, and
the object description, the business need is:

- Track **individual subscribers** to Beacon products. A standard `Asset` record can carry a
  quantity of subscriptions (seats), but it cannot capture *which* people hold those seats
  without splitting the Asset into one line item per user.
- Each subscription record should link one **Contact** (the subscriber) to one **Asset** (the
  subscribed product), with an optional link to the **Account**.
- Subscription records should be visible to whoever can see the related Contact and Asset, and
  changes to them should be auditable.
- Each subscription should record its term (Start Date and End Date, matching the Asset Time
  Period), link to the Asset Time Period (Asset State Period) record it covers, and capture the
  date access was removed if it ended early.
- An **Active** flag should show whether the subscription is live today: within its Start and
  End Date and not removed early. It must be usable as a filter in list views and reports.
- A **Status** field should show the same thing visually, as a green "Active" or red "Inactive"
  flag icon in the same style as the Engagement Status icons.
- Every Beacon persona should be able to **read** Beacon Subscriptions. Only Beacon Salesforce
  Admins should be able to create, edit and delete them, with full Modify All / View All access.
  The baseline permission sets should not grant access.

## Release Notes

A new custom object, `Beacon_Subscription__c` ("Beacon Subscription" / "Beacon Subscriptions"),
was created as a **junction object** between `Contact` and `Asset`. Each record represents one
Contact's subscription to one Asset, so an Asset with a quantity of 10 can have up to 10 Beacon
Subscription records, one for each named user. This keeps `Asset` as the commercial record (product,
quantity, dates) and holds the per-user detail on the child object, so Assets don't have to be
split into one line item per user.

Object settings:

| Setting | Value | Notes |
|---|---|---|
| Record name | Auto Number, `Beacon Subs - {000000}` | Records are system-named. The name is read-only on the layout. |
| Sharing model | Controlled by Parent (internal and external) | Access is inherited from the master Contact and Asset. |
| Field history tracking | Enabled at object level | No individual fields are tracked yet (see Post Deployment Items). |
| Activities / Reports / Bulk API / Streaming API | Enabled | |
| Search | Disabled | Records are reached through the Contact/Asset related lists, not global search. |
| Chatter feed | Disabled | |

Three relationship fields were created:

| Field | Type | Required | Purpose |
|---|---|---|---|
| `Contact__c` | Master-Detail(Contact), primary master | Yes | The subscriber. |
| `Asset__c` | Master-Detail(Asset), secondary master | Yes | The subscribed product. |
| `Account__c` | Lookup(Account), delete = Set Null | No | Optional link to the Account, for reporting. Populated by hand. |
| `Asset_Time_Period__c` | Lookup(Asset State Period), delete = Set Null | No (see below) | The Asset Time Period this subscription covers. |

Five fields track the subscription term and status:

| Field | Type | Description |
|---|---|---|
| `Start_Date__c` | Date | Subscription start date. Corresponds to Start Date on the related Asset Time Period. |
| `End_Date__c` | Date | Subscription end date. Corresponds to End Date on the related Asset Time Period. |
| `Date_Access_Removed__c` | Date | Date access was removed if done prior to end date. |
| `Active__c` | Formula (Checkbox) | True when today is between Start Date and End Date (inclusive) and Date Access Removed is blank. Otherwise false, including when either date is blank. |
| `Status__c` | Formula (Text) | Shows a green **Active** flag when `Active__c` is true, otherwise a red **Inactive** flag. |

"Asset Time Period" is the standard Revenue Cloud object **Asset State Period**
(`AssetStatePeriod`). It was requested as a master-detail, but Salesforce allows at most two
master-detail relationships per object and Contact and Asset already use both. It was therefore
built as a **Lookup** (agreed with the requester). It isn't required at the field level, so it
can still be given field-level security. It uses Set Null rather than Restrict because Revenue
Cloud rebuilds Asset State Periods on amendments, and Restrict would block that.

Start Date and End Date are plain date fields that users enter. They are **not** copied
automatically from the Asset Time Period.

`Active__c` is a checkbox formula, so it can be used to filter list views and reports
(Active equals True/False). `Status__c` is a separate text formula that reads `Active__c` and uses
`IMAGE()` to show one of two new static resources: `Active` (green flag, "Active") or `Inactive`
(red flag, "Inactive"). Splitting them this way keeps the active rule in one place, `Active__c`,
while still giving users a visual flag. An image formula can't be used as a true/false filter,
which is why the checkbox is kept as well. (On this branch, Active was briefly changed to an
image formula and then changed back.)

The icons were built in the same style as the Engagement Status icons from the
`Traffic-Light-System` branch. They reuse the same rounded white badge, the same green flag as
`Customer` and the same red flag as `Do_Not_Contact`, with the same bold label font and colours.
Like those icons, they are stored at 40px high and displayed at 20px (`IMAGE(..., 20, 60)` and
`IMAGE(..., 20, 69)`) so they stay sharp on high-resolution screens.

Both fields are calculated each time the record is read, using `TODAY()`, so they change
overnight with no automation. Because they are formulas, they can't trigger flows and aren't
stored for field history.

Because `Contact__c` and `Asset__c` are both master-detail, **deleting a Contact or an Asset
also deletes its Beacon Subscription records**, and neither master can be reparented
(`reparentableMasterDetail = false`). `Contact__c` is the primary master, so the record's owner
and its default report type come from the Contact.

A page layout, `Beacon Subscription Layout`, was created. Its **Information** section shows Name
(read-only), Contact (required), Asset (required) and Account in the left column, and Currency in
the right column. Asset Time Period was added to the left column. Status and Active (both read-only), Start Date,
End Date and Date Access Removed were added to the right column above Currency. Its **System Information** section shows the standard created/modified fields.
The layout is assigned to all 25 profiles in the repo. (Gearset also moved the `<userLicense>`
element higher in the `Beacon Standard User` profile. This is a reorder only; nothing changed.)

**Permission sets.** Access was added to the persona "Object, Tab, FLS" permission sets, following
the pattern from the `beacon-permission-sets-jaq4s2` branch:

| Permission Set | Object access | Field-level security |
|---|---|---|
| Beacon Consulting, Customer Success, Executive, Finance, Marketing, Product, ResOps, Sales, Tech – Object, Tab, FLS | Read only | Read on all custom fields |
| Beacon Salesforce Admin – Object, Tab, FLS | Create, Read, Edit, Delete, View All Fields, View All Records, Modify All Records | Read + Edit on all custom fields (Active and Status are formulas, so they are Read only) |

The two baseline permission sets (`Beacon - Baseline - Standard Field Access` and `Beacon -
Baseline - System & App Access`) were deliberately left alone.

`Contact__c` and `Asset__c` have no field permission entries. Master-detail fields are always
required, and Salesforce doesn't allow field-level security on required fields. Anyone with
access to the object can read them, and anyone who can edit the object can edit them. Users
also need Read access to the parent Contact and Asset to see a subscription. Every persona set
already grants Read on Contact. Asset access comes from the user's profile and the Asset's Account.

## Acceptance Criteria

1. **Object exists:** In Setup → Object Manager, confirm `Beacon Subscription`
   (`Beacon_Subscription__c`) exists with the fields Contact, Asset, Account and Beacon
   Subscription Name.
2. **Create from a Contact:** Open a Contact that has a related Asset. In the Beacon
   Subscriptions related list (once it has been added — see Post Deployment Items), click New.
   Confirm Contact is pre-filled and Contact and Asset are required. Choose an Asset, optionally
   an Account, and save.
3. **Auto Number:** Confirm the saved record is named `Beacon Subs - 000001` (or the next number)
   and that the name can't be edited.
4. **Required masters:** Try to save a new Beacon Subscription without a Contact, and then
   without an Asset. Both saves should be blocked.
5. **Related lists:** Confirm the record appears in the Beacon Subscriptions related list on the
   Contact, the Asset and (if it was filled in) the Account.
6. **Sharing:** Log in as (or impersonate) a user who can't see the parent Contact or Asset.
   Confirm they can't see the Beacon Subscription.
7. **Cascade delete:** In a sandbox, delete a test Asset that has Beacon Subscriptions. Confirm
   its subscriptions are deleted too. Repeat with a test Contact.
8. **Account lookup Set Null:** In a sandbox, delete a test Account referenced in
   `Account__c` on a subscription whose Contact and Asset sit under a different Account. Confirm
   the subscription survives and `Account__c` is blank.
9. **Persona read access:** Log in as (or impersonate) a user who has only a persona permission
   set (e.g. Beacon Sales – Object, Tab, FLS) plus the baseline sets. Confirm they can open a
   Beacon Subscription and see Contact, Asset and Account. Confirm they have no New, Edit or
   Delete buttons, and that the Account field is read-only.
10. **Admin access:** Log in as a user with the Beacon Salesforce Admin – Object, Tab, FLS
    permission set. Confirm they can create, edit and delete Beacon Subscriptions, edit Account,
    and see subscriptions on Contacts and Assets they don't otherwise have access to (View All /
    Modify All).
11. **Baseline sets untouched:** In Setup, open the two Beacon baseline permission sets. Confirm
    neither has access to Beacon Subscription.
12. **New fields on layout:** Open a Beacon Subscription as an admin. Confirm Asset Time
    Period, Start Date, End Date, Date Access Removed, Status and Active (both read-only) are on the layout.
13. **Asset Time Period lookup:** Choose an Asset Time Period and save. Confirm the
    subscription shows in the Beacon Subscriptions related list on that Asset State Period.
14. **Active – current term:** Set Start Date to yesterday, End Date to tomorrow and leave Date
    Access Removed blank. Save. Confirm Active is checked and Status shows the green Active flag.
15. **Active – boundary days:** Set Start Date = today, then End Date = today. Confirm Active
    is checked and Status shows the green Active flag in both cases.
16. **Active – future / expired:** Set Start Date to tomorrow and confirm Active is unchecked and
    Status shows the red Inactive flag. Then set dates entirely in the past and confirm the same.
17. **Active – access removed:** With a current term, enter today in Date Access Removed.
    Confirm Active is unchecked and Status shows the red Inactive flag. Clear it and confirm Active is
    checked and Status shows the green Active flag again.
18. **Active – blank dates:** Clear Start Date or End Date. Confirm Active is unchecked and Status
    shows the red Inactive flag.
19. **List view / report filter:** Create a Beacon Subscriptions list view filtered on Active
    equals True. Confirm only current subscriptions appear. Add Status as a column and confirm
    each row shows the green flag. Repeat with Active equals False (red flags).
20. **Persona FLS:** As a persona user, confirm the six new fields are visible and read-only.
21. **Reporting:** Create a report on Beacon Subscriptions (via the Contacts with Beacon
   Subscriptions report type). Confirm Contact, Asset and Account columns are available.

## Post Deployment Items

The branch contains the object, its fields, its layout, the profile layout assignments and the
persona permission set access. The following are **not** in this branch and must be done in the target org (or added to this
branch in a later deploy):

1. **Related lists:** Add the Beacon Subscriptions related list to the Contact, Asset, Account
   and Asset State Period page layouts or Lightning record pages so users can create and see subscriptions.
2. **Tab (optional):** No custom tab was created. Add one, and add it to the Beacon app, if users
   need a list view of all subscriptions.
3. **Field history (optional):** Object-level history is on, but no fields are tracked. Turn on
   tracking for `Contact__c`, `Asset__c`, `Account__c`, `Asset_Time_Period__c`, the date fields
   and `Date_Access_Removed__c` if an audit trail is needed.
4. **Date population (optional):** Start Date and End Date are entered by hand. If they should
   default from the selected Asset Time Period, that needs a flow (not in this branch).
5. **Data load (optional):** If subscriptions already exist on Assets, load the per-user Beacon
   Subscription records once access has been granted.

## Component Manifest

Github Branch: https://github.com/aaroncrear/BeaconImplementation/tree/Beacon-Subscriptions

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Custom Object | Beacon_Subscription__c | Beacon_Subscription__c | Beacon Subscription | Created | Junction object between Contact and Asset that tracks each individual subscriber. Auto Number name `Beacon Subs - {000000}`, sharing Controlled by Parent. |
| 2 | Field | Beacon_Subscription__c | Contact__c | Contact | Created | Master-Detail(Contact), primary master. The subscriber. |
| 3 | Field | Beacon_Subscription__c | Asset__c | Asset | Created | Master-Detail(Asset), secondary master. The subscribed product. |
| 4 | Field | Beacon_Subscription__c | Account__c | Account | Created | Optional Lookup(Account), delete constraint Set Null. |
| 5 | Field | Beacon_Subscription__c | Asset_Time_Period__c | Asset Time Period | Created | Lookup(Asset State Period), delete constraint Set Null. |
| 6 | Field | Beacon_Subscription__c | Start_Date__c | Start Date | Created | Date. Corresponds to Start Date on the related Asset Time Period. |
| 7 | Field | Beacon_Subscription__c | End_Date__c | End Date | Created | Date. Corresponds to End Date on the related Asset Time Period. |
| 8 | Field | Beacon_Subscription__c | Date_Access_Removed__c | Date Access Removed | Created | Date access was removed if done prior to end date. |
| 9 | Field | Beacon_Subscription__c | Active__c | Active | Created | Formula (Checkbox). True when today is within Start/End Date and Date Access Removed is blank. Usable in list view and report filters. |
| 10 | Field | Beacon_Subscription__c | Status__c | Status | Created | Formula (Text). Shows the Active static resource (green flag) when Active__c is true, otherwise the Inactive static resource (red flag). |
| 11 | Static Resource | N/A | Active | Active | Created | Green flag badge with the text "Active" (PNG, 120x40), used by Beacon_Subscription__c.Status__c. |
| 12 | Static Resource | N/A | Inactive | Inactive | Created | Red flag badge with the text "Inactive" (PNG, 138x40), used by Beacon_Subscription__c.Status__c. |
| 13 | Page Layout | Beacon_Subscription__c | Beacon_Subscription__c-Beacon Subscription Layout | Beacon Subscription Layout | Created | Information section (Name, Contact, Asset, Account, Asset Time Period, Status, Active, Start Date, End Date, Date Access Removed, Currency) and System Information section. |
| 14 | Profile | N/A | Admin | Admin | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 15 | Profile | N/A | Analytics Cloud Integration User | Analytics Cloud Integration User | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 16 | Profile | N/A | Analytics Cloud Security User | Analytics Cloud Security User | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 17 | Profile | N/A | Beacon Standard User | Beacon Standard User | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. Also moved the userLicense element (reorder only). |
| 18 | Profile | N/A | CPQ Integration User | CPQ Integration User | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 19 | Profile | N/A | Chatter External User | Chatter External User | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 20 | Profile | N/A | Chatter Free User | Chatter Free User | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 21 | Profile | N/A | Chatter Moderator User | Chatter Moderator User | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 22 | Profile | N/A | ContractManager | ContractManager | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 23 | Profile | N/A | Einstein Agent User | Einstein Agent User | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 24 | Profile | N/A | End User | End User | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 25 | Profile | N/A | Executive Sponsor | Executive Sponsor | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 26 | Profile | N/A | External Apps Login User | External Apps Login User | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 27 | Profile | N/A | External Einstein Agent User | External Einstein Agent User | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 28 | Profile | N/A | Guest License User | Guest License User | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 29 | Profile | N/A | Identity User | Identity User | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 30 | Profile | N/A | MarketingProfile | MarketingProfile | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 31 | Profile | N/A | Minimum Access - API Only Integrations | Minimum Access - API Only Integrations | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 32 | Profile | N/A | Minimum Access - Salesforce | Minimum Access - Salesforce | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 33 | Profile | N/A | Read Only | Read Only | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 34 | Profile | N/A | Sales Insights Integration User | Sales Insights Integration User | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 35 | Profile | N/A | Salesforce API Only System Integrations | Salesforce API Only System Integrations | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 36 | Profile | N/A | SalesforceIQ Integration User | SalesforceIQ Integration User | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 37 | Profile | N/A | SolutionManager | SolutionManager | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 38 | Profile | N/A | Standard | Standard | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 39 | Permission Set | Beacon_Subscription__c | Beacon_Consulting_Object_Tab_FLS | Beacon Consulting - Object, Tab, FLS | Updated | Added Read on Beacon_Subscription__c and Read FLS on Account__c, Asset_Time_Period__c, Start_Date__c, End_Date__c, Date_Access_Removed__c, Active__c and Status__c. |
| 40 | Permission Set | Beacon_Subscription__c | Beacon_Customer_Success_Object_Tab_FLS | Beacon Customer Success - Object, Tab, FLS | Updated | Added Read on Beacon_Subscription__c and Read FLS on Account__c, Asset_Time_Period__c, Start_Date__c, End_Date__c, Date_Access_Removed__c, Active__c and Status__c. |
| 41 | Permission Set | Beacon_Subscription__c | Beacon_Executive_Object_Tab_FLS | Beacon Executive - Object, Tab, FLS | Updated | Added Read on Beacon_Subscription__c and Read FLS on Account__c, Asset_Time_Period__c, Start_Date__c, End_Date__c, Date_Access_Removed__c, Active__c and Status__c. |
| 42 | Permission Set | Beacon_Subscription__c | Beacon_Finance_Object_Tab_FLS | Beacon Finance - Object, Tab, FLS | Updated | Added Read on Beacon_Subscription__c and Read FLS on Account__c, Asset_Time_Period__c, Start_Date__c, End_Date__c, Date_Access_Removed__c, Active__c and Status__c. |
| 43 | Permission Set | Beacon_Subscription__c | Beacon_Marketing_Object_Tab_FLS | Beacon Marketing - Object, Tab, FLS | Updated | Added Read on Beacon_Subscription__c and Read FLS on Account__c, Asset_Time_Period__c, Start_Date__c, End_Date__c, Date_Access_Removed__c, Active__c and Status__c. |
| 44 | Permission Set | Beacon_Subscription__c | Beacon_Product_Object_Tab_FLS | Beacon Product - Object, Tab, FLS | Updated | Added Read on Beacon_Subscription__c and Read FLS on Account__c, Asset_Time_Period__c, Start_Date__c, End_Date__c, Date_Access_Removed__c, Active__c and Status__c. |
| 45 | Permission Set | Beacon_Subscription__c | Beacon_ResOps_Object_Tab_FLS | Beacon ResOps - Object, Tab, FLS | Updated | Added Read on Beacon_Subscription__c and Read FLS on Account__c, Asset_Time_Period__c, Start_Date__c, End_Date__c, Date_Access_Removed__c, Active__c and Status__c. |
| 46 | Permission Set | Beacon_Subscription__c | Beacon_Sales_Object_Tab_FLS | Beacon Sales - Object, Tab, FLS | Updated | Added Read on Beacon_Subscription__c and Read FLS on Account__c, Asset_Time_Period__c, Start_Date__c, End_Date__c, Date_Access_Removed__c, Active__c and Status__c. |
| 47 | Permission Set | Beacon_Subscription__c | Beacon_Salesforce_Admin_Object_Tab_FLS | Beacon Salesforce Admin - Object, Tab, FLS | Updated | Added Create/Read/Edit/Delete, View All Fields, View All Records and Modify All Records on Beacon_Subscription__c, Read + Edit FLS on Account__c, Asset_Time_Period__c, Start_Date__c, End_Date__c and Date_Access_Removed__c, and Read FLS on Active__c and Status__c. |
| 48 | Permission Set | Beacon_Subscription__c | Beacon_Tech_Object_Tab_FLS | Beacon Tech - Object, Tab, FLS | Updated | Added Read on Beacon_Subscription__c and Read FLS on Account__c, Asset_Time_Period__c, Start_Date__c, End_Date__c, Date_Access_Removed__c, Active__c and Status__c. |
