# "Beacon-Subscriptions" – Release Notes

## Requirements

This build was deployed directly to the `Beacon-Subscriptions` branch via Gearset (no written
requirements doc was supplied alongside the deploy). Based on the metadata that was pushed, and
the object description, the business need is:

- Track **individual subscribers** to Beacon products. A standard `Asset` record can carry a
  quantity of subscriptions (seats), but it cannot capture *which* people hold those seats
  without splitting the Asset into one line item per user.
- Subscriptions are **purchased by an Account** before the subscriber is known. Each record must
  link to the purchasing **Account** and the subscribed **Asset** when it is created. The
  **Contact** (the subscriber) is added later, once the person is known.
- Subscription records should be visible to whoever can see the related Account and Asset, and
  changes to them should be auditable.
- Each subscription should record its term (Start Date and End Date, matching the Asset Time
  Period) and capture the date access was removed if it ended early.
- An **Active** flag should show whether the subscription is live today: within its Start and
  End Date and not removed early. It must be usable as a filter in list views and reports.
- A **Status** field should show the same thing visually, as a green "Active" or red "Inactive"
  flag icon in the same style as the Engagement Status icons.
- Every Beacon persona should be able to **read** Beacon Subscriptions. Only Beacon Salesforce
  Admins should be able to create, edit and delete them, with full Modify All / View All access.
  The baseline permission sets should not grant access.

## Release Notes

A new custom object, `Beacon_Subscription__c` ("Beacon Subscription" / "Beacon Subscriptions"),
was created as a **junction object** between `Account` and `Asset`. Each record represents one
purchased seat on an Asset, so an Asset with a quantity of 10 can have up to 10 Beacon
Subscription records. The subscriber's Contact is added to each seat once it is known. This keeps `Asset` as the commercial record (product,
quantity, dates) and holds the per-user detail on the child object, so Assets don't have to be
split into one line item per user.

Object settings:

| Setting | Value | Notes |
|---|---|---|
| Record name | Auto Number, `Beacon Subs - {000000}` | Records are system-named. The name is read-only on the layout. |
| Sharing model | Controlled by Parent (internal and external) | Access is inherited from the master Account and Asset. |
| Field history tracking | Enabled at object level | No individual fields are tracked yet (see Post Deployment Items). |
| Activities / Reports / Bulk API / Streaming API | Enabled | |
| Search | Disabled | Records are reached through the Account/Asset/Contact related lists, not global search. |
| Chatter feed | Disabled | |

Three relationship fields were created:

| Field | Type | Required | Purpose |
|---|---|---|---|
| `Account__c` | Master-Detail(Account), primary master | Yes | The Account that purchased the subscription. |
| `Asset__c` | Master-Detail(Asset), secondary master | Yes | The subscribed product. |
| `Contact__c` | Lookup(Contact), delete = Set Null | No | The subscriber. Left blank at purchase and filled in once the person is known. |

Five fields track the subscription term and status:

| Field | Type | Description |
|---|---|---|
| `Start_Date__c` | Date | Subscription start date. Corresponds to Start Date on the Asset's Asset Time Period. |
| `End_Date__c` | Date | Subscription end date. Corresponds to End Date on the Asset's Asset Time Period. |
| `Date_Access_Removed__c` | Date | Date access was removed if done prior to end date. |
| `Active__c` | Formula (Checkbox) | True when today is between Start Date and End Date (inclusive) and Date Access Removed is blank. Otherwise false, including when either date is blank. |
| `Status__c` | Formula (Text) | Shows a green **Active** flag when `Active__c` is true, otherwise a red **Inactive** flag. |

**No link to the Asset Time Period.** "Asset Time Period" is the standard Revenue Cloud object
**Asset State Period** (`AssetStatePeriod`). A link to it was requested, first as a master-detail
and then as a lookup. Neither is possible. Salesforce allows only two master-detail fields per
object, and Account and Asset already use both. A lookup was built, but the deploy failed with
"referenceTo value of 'AssetStatePeriod' does not resolve to a valid sObject type", because
Asset State Period can't be the target of a custom lookup. The field was removed (agreed with
the requester). Each subscription still links to its Asset, and the Asset's time periods can be
seen on the Asset.

Start Date and End Date are plain date fields that users enter. They are **not** copied
automatically from the Asset's time periods.

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

**Why Account is the master and Contact is a lookup.** Contact was first built as a
master-detail and Account as an optional lookup. That was changed on this branch: subscriptions
are purchased before the subscriber is known, and a master-detail field is always required, so
records couldn't be created without a Contact. Account is now the primary master and is
required. Contact is an optional lookup that is filled in later. If a Contact is deleted, its
subscriptions stay and the Contact field is cleared, so the seat can be given to someone else.

Because `Account__c` and `Asset__c` are both master-detail, **deleting an Account or an Asset
also deletes its Beacon Subscription records**, and neither master can be changed after the
record is saved (`reparentableMasterDetail = false`). `Account__c` is the primary master, so the
record's owner and its default report type ("Accounts with Beacon Subscriptions") come from the
Account.

A page layout, `Beacon Subscription Layout`, was created. Its **Information** section shows Name
(read-only), Account (required), Asset (required) and Contact in the left column, and Currency in
the right column. Status and Active (both read-only), Start Date,
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

`Account__c` and `Asset__c` have no field permission entries. Master-detail fields are always
required, and Salesforce doesn't allow field-level security on required fields. Anyone with
access to the object can read them, and anyone who can edit the object can edit them. (When
Account was a lookup it had its own field permission entries. These were removed when it became
a master-detail. The new Contact lookup was given field permissions in their place.) Users also
need Read access to the parent Account and Asset to see a subscription. Every persona set
already granted Read on Account. **Read on Asset was added to every persona set**, and full
access to Asset (Create, Read, Edit, Delete, View All, Modify All) was added to the Salesforce
Admin set, matching its access to the other objects. Without this, the deploy failed with
"Permission Read Beacon_Subscription__c depends on permission(s): Read Asset". The persona sets
can now read Asset records the user has sharing access to, but can't create, edit or delete them.

## Acceptance Criteria

1. **Object exists:** In Setup → Object Manager, confirm `Beacon Subscription`
   (`Beacon_Subscription__c`) exists with the fields Contact, Asset, Account and Beacon
   Subscription Name.
2. **Create at purchase, without a Contact:** Open an Account that has an Asset. In the Beacon
   Subscriptions related list (once it has been added — see Post Deployment Items), click New.
   Confirm Account is pre-filled and Account and Asset are required. Choose the Asset, leave
   Contact blank, and save. The record should save.
3. **Auto Number:** Confirm the saved record is named `Beacon Subs - 000001` (or the next number)
   and that the name can't be edited.
4. **Required masters:** Try to save a new Beacon Subscription without an Account, and then
   without an Asset. Both saves should be blocked.
5. **Add the Contact later:** Edit the subscription from step 2, choose a Contact and save.
   Confirm the record appears in the Beacon Subscriptions related list on the Account, the
   Asset and the Contact.
6. **Sharing:** Log in as (or impersonate) a user who can't see the parent Account or Asset.
   Confirm they can't see the Beacon Subscription.
7. **Cascade delete:** In a sandbox, delete a test Asset that has Beacon Subscriptions. Confirm
   its subscriptions are deleted too. Repeat with a test Account.
8. **Contact lookup Set Null:** In a sandbox, delete a test Contact that is on a subscription.
   Confirm the subscription survives and `Contact__c` is blank.
9. **Persona read access:** Log in as (or impersonate) a user who has only a persona permission
   set (e.g. Beacon Sales – Object, Tab, FLS) plus the baseline sets. Confirm they can open a
   Beacon Subscription and see Account, Asset and Contact. Confirm they have no New, Edit or
   Delete buttons, and that the Contact field is read-only.
10. **Admin access:** Log in as a user with the Beacon Salesforce Admin – Object, Tab, FLS
    permission set. Confirm they can create, edit and delete Beacon Subscriptions, edit Contact,
    and see subscriptions on Accounts and Assets they don't otherwise have access to (View All /
    Modify All).
11. **Baseline sets untouched:** In Setup, open the two Beacon baseline permission sets. Confirm
    neither has access to Beacon Subscription.
12. **New fields on layout:** Open a Beacon Subscription as an admin. Confirm Start Date,
    End Date, Date Access Removed, Status and Active (both read-only) are on the layout.
13. **Asset access:** As a persona user, open an Asset on an Account they can see. Confirm they
    can view it but have no New, Edit or Delete buttons. As an admin, confirm Assets can be
    created and edited.
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
20. **Persona FLS:** As a persona user, confirm Contact, Start Date, End Date, Date Access
    Removed, Active and Status are visible and read-only.
21. **Reporting:** Create a report using the Accounts with Beacon Subscriptions report type.
    Confirm Account, Asset and Contact columns are available. Filter on Contact equals blank to
    list seats that haven't been assigned yet.

## Post Deployment Items

The branch contains the object, its fields, its layout, the profile layout assignments and the
persona permission set access. The following are **not** in this branch and must be done in the target org (or added to this
branch in a later deploy):

1. **Deployment order (orgs where the object already exists):** Salesforce allows only two
   master-detail fields at a time, and it won't create a new master-detail on an object that
   already has records. In any org that already has `Beacon_Subscription__c` with Contact as a
   master-detail, do this before deploying:
   1. Delete or back up the existing Beacon Subscription records. Alternatively, create
      `Account__c` as a lookup, fill it in on every record, and then convert it to master-detail.
   2. In Setup, change `Contact__c` from Master-Detail to Lookup **before** `Account__c`
      becomes a master-detail.

   **Status:** done by hand in the HTCDEV sandbox on 2026-10-25. The test record
   `Beacon Subs - 000001` was deleted, `Contact__c` changed to Lookup(Contact) and `Account__c`
   created as Master-Detail(Account). The object doesn't exist in UAT yet, so a first deploy
   there creates the fields in their final form and these steps aren't needed.
2. **Related lists:** Add the Beacon Subscriptions related list to the Account, Asset and
   Contact page layouts or Lightning record pages so users can create and see subscriptions.
3. **Tab (optional):** No custom tab was created. Add one, and add it to the Beacon app, if users
   need a list view of all subscriptions.
4. **Field history (optional):** Object-level history is on, but no fields are tracked. Turn on
   tracking for `Account__c`, `Asset__c`, `Contact__c`, the date fields
   and `Date_Access_Removed__c` if an audit trail is needed.
5. **Date population (optional):** Start Date and End Date are entered by hand. If they should
   default from the Asset's current time period, that needs a flow (not in this branch).
6. **Data load (optional):** If subscriptions already exist on Assets, load one Beacon
   Subscription record per purchased seat (Account and Asset required, Contact where known).

## Component Manifest

Github Branch: https://github.com/aaroncrear/BeaconImplementation/tree/Beacon-Subscriptions

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Custom Object | Beacon_Subscription__c | Beacon_Subscription__c | Beacon Subscription | Created | Junction object between Account and Asset that tracks each purchased seat and its subscriber. Auto Number name `Beacon Subs - {000000}`, sharing Controlled by Parent. |
| 2 | Field | Beacon_Subscription__c | Account__c | Account | Created | Master-Detail(Account), primary master. The purchasing Account. |
| 3 | Field | Beacon_Subscription__c | Asset__c | Asset | Created | Master-Detail(Asset), secondary master. The subscribed product. |
| 4 | Field | Beacon_Subscription__c | Contact__c | Contact | Created | Optional Lookup(Contact), delete constraint Set Null. The subscriber, filled in once known. |
| 5 | Field | Beacon_Subscription__c | Start_Date__c | Start Date | Created | Date. Corresponds to Start Date on the Asset's Asset Time Period. |
| 6 | Field | Beacon_Subscription__c | End_Date__c | End Date | Created | Date. Corresponds to End Date on the Asset's Asset Time Period. |
| 7 | Field | Beacon_Subscription__c | Date_Access_Removed__c | Date Access Removed | Created | Date access was removed if done prior to end date. |
| 8 | Field | Beacon_Subscription__c | Active__c | Active | Created | Formula (Checkbox). True when today is within Start/End Date and Date Access Removed is blank. Usable in list view and report filters. |
| 9 | Field | Beacon_Subscription__c | Status__c | Status | Created | Formula (Text). Shows the Active static resource (green flag) when Active__c is true, otherwise the Inactive static resource (red flag). |
| 10 | Static Resource | N/A | Active | Active | Created | Green flag badge with the text "Active" (PNG, 120x40), used by Beacon_Subscription__c.Status__c. |
| 11 | Static Resource | N/A | Inactive | Inactive | Created | Red flag badge with the text "Inactive" (PNG, 138x40), used by Beacon_Subscription__c.Status__c. |
| 12 | Page Layout | Beacon_Subscription__c | Beacon_Subscription__c-Beacon Subscription Layout | Beacon Subscription Layout | Created | Information section (Name, Account, Asset, Contact, Status, Active, Start Date, End Date, Date Access Removed, Currency) and System Information section. |
| 13 | Profile | N/A | Admin | Admin | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 14 | Profile | N/A | Analytics Cloud Integration User | Analytics Cloud Integration User | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 15 | Profile | N/A | Analytics Cloud Security User | Analytics Cloud Security User | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 16 | Profile | N/A | Beacon Standard User | Beacon Standard User | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. Also moved the userLicense element (reorder only). |
| 17 | Profile | N/A | CPQ Integration User | CPQ Integration User | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 18 | Profile | N/A | Chatter External User | Chatter External User | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 19 | Profile | N/A | Chatter Free User | Chatter Free User | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 20 | Profile | N/A | Chatter Moderator User | Chatter Moderator User | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 21 | Profile | N/A | ContractManager | ContractManager | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 22 | Profile | N/A | Einstein Agent User | Einstein Agent User | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 23 | Profile | N/A | End User | End User | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 24 | Profile | N/A | Executive Sponsor | Executive Sponsor | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 25 | Profile | N/A | External Apps Login User | External Apps Login User | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 26 | Profile | N/A | External Einstein Agent User | External Einstein Agent User | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 27 | Profile | N/A | Guest License User | Guest License User | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 28 | Profile | N/A | Identity User | Identity User | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 29 | Profile | N/A | MarketingProfile | MarketingProfile | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 30 | Profile | N/A | Minimum Access - API Only Integrations | Minimum Access - API Only Integrations | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 31 | Profile | N/A | Minimum Access - Salesforce | Minimum Access - Salesforce | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 32 | Profile | N/A | Read Only | Read Only | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 33 | Profile | N/A | Sales Insights Integration User | Sales Insights Integration User | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 34 | Profile | N/A | Salesforce API Only System Integrations | Salesforce API Only System Integrations | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 35 | Profile | N/A | SalesforceIQ Integration User | SalesforceIQ Integration User | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 36 | Profile | N/A | SolutionManager | SolutionManager | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 37 | Profile | N/A | Standard | Standard | Updated | Assigned the Beacon Subscription Layout to Beacon_Subscription__c. |
| 38 | Permission Set | Beacon_Subscription__c | Beacon_Consulting_Object_Tab_FLS | Beacon Consulting - Object, Tab, FLS | Updated | Added Read on Beacon_Subscription__c and Asset, and Read FLS on Contact__c, Start_Date__c, End_Date__c, Date_Access_Removed__c, Active__c and Status__c. |
| 39 | Permission Set | Beacon_Subscription__c | Beacon_Customer_Success_Object_Tab_FLS | Beacon Customer Success - Object, Tab, FLS | Updated | Added Read on Beacon_Subscription__c and Asset, and Read FLS on Contact__c, Start_Date__c, End_Date__c, Date_Access_Removed__c, Active__c and Status__c. |
| 40 | Permission Set | Beacon_Subscription__c | Beacon_Executive_Object_Tab_FLS | Beacon Executive - Object, Tab, FLS | Updated | Added Read on Beacon_Subscription__c and Asset, and Read FLS on Contact__c, Start_Date__c, End_Date__c, Date_Access_Removed__c, Active__c and Status__c. |
| 41 | Permission Set | Beacon_Subscription__c | Beacon_Finance_Object_Tab_FLS | Beacon Finance - Object, Tab, FLS | Updated | Added Read on Beacon_Subscription__c and Asset, and Read FLS on Contact__c, Start_Date__c, End_Date__c, Date_Access_Removed__c, Active__c and Status__c. |
| 42 | Permission Set | Beacon_Subscription__c | Beacon_Marketing_Object_Tab_FLS | Beacon Marketing - Object, Tab, FLS | Updated | Added Read on Beacon_Subscription__c and Asset, and Read FLS on Contact__c, Start_Date__c, End_Date__c, Date_Access_Removed__c, Active__c and Status__c. |
| 43 | Permission Set | Beacon_Subscription__c | Beacon_Product_Object_Tab_FLS | Beacon Product - Object, Tab, FLS | Updated | Added Read on Beacon_Subscription__c and Asset, and Read FLS on Contact__c, Start_Date__c, End_Date__c, Date_Access_Removed__c, Active__c and Status__c. |
| 44 | Permission Set | Beacon_Subscription__c | Beacon_ResOps_Object_Tab_FLS | Beacon ResOps - Object, Tab, FLS | Updated | Added Read on Beacon_Subscription__c and Asset, and Read FLS on Contact__c, Start_Date__c, End_Date__c, Date_Access_Removed__c, Active__c and Status__c. |
| 45 | Permission Set | Beacon_Subscription__c | Beacon_Sales_Object_Tab_FLS | Beacon Sales - Object, Tab, FLS | Updated | Added Read on Beacon_Subscription__c and Asset, and Read FLS on Contact__c, Start_Date__c, End_Date__c, Date_Access_Removed__c, Active__c and Status__c. |
| 46 | Permission Set | Beacon_Subscription__c | Beacon_Salesforce_Admin_Object_Tab_FLS | Beacon Salesforce Admin - Object, Tab, FLS | Updated | Added Create/Read/Edit/Delete, View All Fields, View All Records and Modify All Records on Beacon_Subscription__c and Asset, Read + Edit FLS on Contact__c, Start_Date__c, End_Date__c and Date_Access_Removed__c, and Read FLS on Active__c and Status__c. |
| 47 | Permission Set | Beacon_Subscription__c | Beacon_Tech_Object_Tab_FLS | Beacon Tech - Object, Tab, FLS | Updated | Added Read on Beacon_Subscription__c and Asset, and Read FLS on Contact__c, Start_Date__c, End_Date__c, Date_Access_Removed__c, Active__c and Status__c. |
