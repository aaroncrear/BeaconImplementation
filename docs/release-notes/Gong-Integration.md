# "Gong-Integration" – Release Notes

## Requirements

Beacon is connecting Gong to Salesforce. Gong needs a dedicated integration user whose access
covers only the data Gong imports from Salesforce and the activities it writes back. The business
asked for:

- A single permission set, **Beacon - Gong Integration**, on the **Salesforce API Integration**
  permission set license. Gong's guide recommends two permission sets, one per license; this
  build uses one because the API Integration license allows standard object, field, and system
  permissions in the same permission set.
- The object and field level access listed in Gong's article
  [Salesforce fields the integration user needs access to](https://help.gong.io/docs/salesforce-fields-the-integration-user-needs-access-to).
- The system permissions Gong requires for writing activities: Access Activities, Edit Tasks,
  Edit Events, and View All Users. API Enabled is included with the license.
- Users who can see an Account or Opportunity must be able to see all of its activities, including
  activities owned by other users. Accounts and Opportunities are Public Read Only.

## Release Notes

The permission set `Beacon_Gong_Integration` was created in the org with its system permissions
already set: Access Activities, Edit Tasks, Edit Events, and View All Users. Object and field
access was then added to it to match the Gong article.

**Activity sharing.** The org-wide default for Activities was changed from Private to
**Controlled by Parent**. Activities can't use sharing rules, so under Private, users would only
see activities they own or that are owned by users below them in the role hierarchy. With
Accounts and Opportunities set to Public Read Only, that wouldn't meet the requirement. Under
Controlled by Parent, anyone who can see an Account, Contact, Lead, or Opportunity can see all of
its activities.

**Object permissions.** Read, Edit, Delete, View All, and Modify All were granted on Account,
Contact, Lead, and Opportunity. Create is off.

The Gong article says that when activity sharing is Controlled by Parent, the integration user
needs Edit and Modify All on these four objects. Under Controlled by Parent, editing an activity
requires edit access to its parent record. Opportunities and Accounts are Public Read Only, so
only Modify All lets Gong update activities on records it doesn't own. Salesforce requires Delete
before Modify All can be granted, so Delete is on too. The integration user can edit and delete
these records through the API, so its credentials should be protected like an admin login.

Task and Event access comes from the Access Activities, Edit Tasks, and Edit Events system
permissions. Salesforce doesn't allow object permissions on Task or Event.

**Field Level Security.** 30 field permissions were added. Account, Contact, Lead, and
Opportunity fields are **Read only**, because Gong only imports them. Task and Event fields are
**Read/Edit**, because Gong creates activities in Salesforce.

| Object | Fields | Access |
|---|---|---|
| Account | AccountSource, Industry, ParentId, Type, Website | Read |
| Contact | AccountId, Email, LeadSource, MobilePhone, Phone, Title | Read |
| Lead | Email, LeadSource, MobilePhone, Phone, Title | Read |
| Opportunity | AccountId, Amount, LeadSource, Probability, Type | Read |
| Task | ActivityDate, Description, Type, WhatId, WhoId | Read/Edit |
| Event | Description, Type, WhatId, WhoId | Read/Edit |

Task and Event share their activity fields. Granting Description, Type, WhatId, or WhoId on one
also grants it on the other.

**Fields in the article that aren't listed above.** Salesforce doesn't allow field level
security on these fields, so they couldn't be added. Some are required fields or system fields
(Id, Name, OwnerId, CloseDate, StageName, IsDeleted, SystemModstamp, and others), which are
always visible to a user who can read the object. Others are on objects that follow access to
their parent: Account Team Member, Opportunity Contact Role, Opportunity History, Opportunity
Team Member, Opportunity Stage, Record Type, and User. `Task.CallDisposition` is not available
for field level security in this org.

**Not included.** The article lists access that is only needed for optional features. None of
it was added:

- Campaign and Campaign Member View All (Gong Engage license).
- Opportunity Split, Opportunity Split Type, and Opportunity Product (Gong Forecast and Deals
  with splits or products).
- The Gong API User permission set (Gong for Salesforce managed package).

The second permission set, `Beacon_Gong_Integration_Object_FLS_Permission`, which is on the
Salesforce Integration user license, was left empty and is not needed.

The permission set was built in the Beacon HTCDEV org and then added to this branch as
`unpackaged/main/default/permissionsets/Beacon_Gong_Integration.permissionset-meta.xml`. It
matches the org exactly. The Activity, Task, and Event object files were updated from `Private`
to `ControlledByParent` to match the new org-wide default.

## Acceptance Criteria

1. In the Beacon HTCDEV org, go to **Setup → Permission Sets** and open **Beacon - Gong
   Integration**. Check that the license is **Salesforce API Integration**.
2. Open **System Permissions**. Check that Access Activities, Edit Tasks, Edit Events, and View
   All Users are on.
3. Open **Object Settings** and check each object:
   - Account, Contact, Lead, Opportunity: Read, Edit, Delete, View All, and Modify All checked.
     Create unchecked.
   - In **Setup → Sharing Settings**, check that the Default Internal Access for Activity is
     **Controlled by Parent**.
4. Check the field permissions for each object against the table in Release Notes:
   - Account (5 fields), Contact (6), Lead (5), Opportunity (5): Read checked, Edit unchecked.
   - Task (5 fields) and Event (4): Read and Edit checked.
5. Assign the permission set to the Gong integration user. That user should have the
   **Salesforce Integration** user license, the **Minimum Access – API Only Integrations**
   profile, and the **Salesforce API Integration** permission set license.
6. In Gong, connect Salesforce as the integration user. Check that:
   - The connection succeeds, and Gong shows no missing-permission warnings for required fields.
   - Accounts, Contacts, Leads, and Opportunities import into Gong, including records owned by
     users outside the integration user's role.
   - After a call or meeting syncs, Gong creates a Task or Event in Salesforce, linked to the
     right Contact or Lead (Name) and Account or Opportunity (Related To).
7. Log in as a sales user who doesn't own a particular Account or Opportunity. Open it and check
   that the Gong activity, and activities owned by other users, appear in the Activity timeline.

## Post Deployment Items

- Assign **Beacon - Gong Integration** to the Gong integration user, along with the **Salesforce
  API Integration** permission set license.
- If the target org isn't Beacon HTCDEV, set the Activity org-wide default to **Controlled by
  Parent** in **Setup → Sharing Settings** before connecting Gong.
- If Task record types are added later, give the permission set access to them.
- If Beacon later buys a Gong Engage license, uses Gong Forecast with Opportunity Splits or
  Products, or installs the Gong for Salesforce package, add the extra access listed under
  **Not included**.
- Delete the empty `Beacon_Gong_Integration_Object_FLS_Permission` permission set, or keep it
  for later use.

## Component Manifest

Github Branch: [Gong-Integration](https://github.com/aaroncrear/BeaconImplementation/tree/Gong-Integration)

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Permission Set | N/A | Beacon_Gong_Integration | Beacon - Gong Integration | Created | Integration user permission set on the Salesforce API Integration license. Read, Edit, Delete, View All, and Modify All on Account, Contact, Lead, and Opportunity. Read access to 21 fields on those objects, and Read/Edit access to 9 Task and Event fields. Includes the Access Activities, Edit Tasks, Edit Events, and View All Users system permissions. |
| 2 | Custom Object (Standard) | Activity | Activity | Activity | Updated | Sharing model changed from Private to ControlledByParent, so users see all activities on the records they can see. |
| 3 | Custom Object (Standard) | Task | Task | Task | Updated | Sharing model changed from Private to ControlledByParent to match Activity. |
| 4 | Custom Object (Standard) | Event | Event | Event | Updated | Sharing model changed from Private to ControlledByParent to match Activity. |
