# "Pendo-Integration" – Release Notes

## Requirements

- Add Pendo usage fields to **Account** and **Contact** so Pendo data can sync into Salesforce. These fields are used only by the Pendo integration.
- Give each Pendo field a description.
- Create a **Beacon - Pendo Integration** permission set with the **Salesforce API Integration** license. It gives edit access to the Pendo fields, and read and edit access to the objects they're on (Account and Contact).
- Create a **Beacon - Pendo User** permission set that gives read access to the Pendo fields.
- Create a **Beacon - Pendo Connected App** permission set with no license.
- Give read access to the Pendo fields in these **Beacon … - Object, Tab, FLS** permission sets: Customer Success, Marketing, Executive, Product, Sales and Tech.
- Give edit access to the Pendo fields in the **Beacon Salesforce Admin - Object, Tab, FLS** permission set.
- Base the new permission set descriptions on the existing **Beacon - Hubspot Integration**, **Beacon - Hubspot User** and **Beacon - Hubspot Connected App** permission sets.

## Release Notes

### Pendo fields

Fifteen custom fields were added: nine on Account and six on Contact. Each one has a description saying what Pendo data it holds and that it's used only by the Pendo integration.

| Object | API Name | Label | Type |
|--------|----------|-------|------|
| Account | Account_Id_Pendo__c | Account Id Pendo | Text(10) |
| Account | Pendo_Days_Active_Last_30_Days__c | Pendo Days Active Last 30 Days | Number(18, 0) |
| Account | Pendo_Days_Active_Year_To_Date__c | Pendo Days Active Year To Date | Number(18, 0) |
| Account | Pendo_Events_Last_30_Days__c | Pendo Events Last 30 Days | Number(18, 0) |
| Account | Pendo_Events_Year_To_Date__c | Pendo Events Year To Date | Number(18, 0) |
| Account | Pendo_NPS_Last_30_Days__c | Pendo NPS Last 30 Days | Number(18, 2) |
| Account | Pendo_NPS_Year_To_Date__c | Pendo NPS Year To Date | Number(18, 2) |
| Account | Pendo_Visitors_Last_30_Days__c | Pendo No. Of Visitors Last 30 Days (MAU) | Number(18, 0) |
| Account | Pendo_Visitors_Year_To_Date__c | Pendo No. Of Visitors Year To Date (MAU) | Number(18, 0) |
| Contact | Pendo_Days_Active_Last_30_Days__c | Pendo Days Active Last 30 Days | Number(18, 0) |
| Contact | Pendo_Days_Active_Year_To_Date__c | Pendo Days Active Year To Date | Number(18, 0) |
| Contact | Pendo_Events_Last_30_Days__c | Pendo Events Last 30 Days | Number(18, 0) |
| Contact | Pendo_Events_Year_To_Date__c | Pendo Events Year To Date | Number(18, 0) |
| Contact | Pendo_NPS_Last_30_Days__c | Pendo NPS Last 30 Days | Number(18, 0) |
| Contact | Pendo_NPS_Year_To_Date__c | Pendo NPS Year To Date | Number(18, 0) |

**Account Id Pendo** links a Salesforce Account to its Account in Pendo. An admin fills it in with the Pendo Account Id, and Pendo uses it to find the right Account. The other fields are filled in by Pendo, and users shouldn't edit them.

### Beacon - Pendo Integration permission set

A new permission set, **Beacon - Pendo Integration** (`Beacon_Pendo_Integration`), uses the **Salesforce API Integration** license, the same as Beacon - Hubspot Integration. Salesforce API Integration is a permission set license, not a user license. So the metadata names it by its developer name, `SalesforceAPIIntegrationPsl`. The deploy fails with "License: Salesforce API Integration doesn't exist" if the label is used instead. Its description matches the HubSpot one: "Holds system and Object level permission for the Pendo integration. This is not part of a Pendo package."

It gives:

- **Read and edit** access to all 15 Pendo fields.
- **Read and edit** access to Account and Contact. Create, delete, View All and Modify All aren't given, because Pendo only updates existing records.

### Beacon - Pendo User permission set

A new permission set, **Beacon - Pendo User** (`Beacon_Pendo_User`), uses the **Salesforce** license, the same as Beacon - Hubspot User. Its description follows the HubSpot one: "Holds customization made for the Pendo integration. This is not part of a Pendo package."

It gives **read** access to all 15 Pendo fields and to Account and Contact. Users who don't have one of the persona permission sets below can be given this one to see Pendo data.

### Beacon - Pendo Connected App permission set

A new permission set, **Beacon - Pendo Connected App** (`Beacon_Pendo_Connected_App`), has no license, the same as Beacon - Hubspot Connected App. With no license, it can be assigned to users with any user license, including the Pendo integration user. Its description matches the HubSpot one: "Gives access to the Pendo Connected App".

The HubSpot version gives access to the HubSpot connected app. There's no Pendo connected app in the org yet, so this permission set doesn't give access to any app for now. Once Pendo is connected, the Pendo connected app is added to it (see Post Deployment Items).

### Persona permission sets

All 15 Pendo fields were added to these persona permission sets, in alphabetical order with the existing field permissions:

| Permission Set | Access |
|----------------|--------|
| Beacon Customer Success - Object, Tab, FLS | Read |
| Beacon Executive - Object, Tab, FLS | Read |
| Beacon Marketing - Object, Tab, FLS | Read |
| Beacon Product - Object, Tab, FLS | Read |
| Beacon Sales - Object, Tab, FLS | Read |
| Beacon Tech - Object, Tab, FLS | Read |
| Beacon Salesforce Admin - Object, Tab, FLS | Read and edit |

These permission sets already had access to Account and Contact, so their object permissions didn't change. Consulting, Finance and ResOps weren't included because they weren't in the requirements.

## Acceptance Criteria

**Fields**

1. Go to **Setup → Object Manager → Account → Fields & Relationships**. Confirm the nine Account fields in the table above exist, each with a description.
2. Repeat for **Contact** and confirm the six Contact fields exist, each with a description.

**Beacon - Pendo Integration**

3. Go to **Setup → Permission Sets → Beacon - Pendo Integration**. Confirm the license is **Salesforce API Integration**.
4. Open **Object Settings → Accounts**. Confirm Read and Edit are checked, Create, Delete, View All and Modify All aren't, and all nine Account Pendo fields have Read and Edit access.
5. Open **Object Settings → Contacts**. Confirm Read and Edit are checked and all six Contact Pendo fields have Read and Edit access.
6. Assign the permission set to the Pendo integration user. Using that user, update a Pendo field on an Account and a Contact through the API, such as with Workbench or the Pendo sync. Confirm the values save.

**Beacon - Pendo User**

7. Go to **Setup → Permission Sets → Beacon - Pendo User**. Confirm the license is **Salesforce**, and Account and Contact have Read access only.
8. Confirm all 15 Pendo fields have Read access and not Edit access.

**Beacon - Pendo Connected App**

9. Go to **Setup → Permission Sets → Beacon - Pendo Connected App**. Confirm the license is **--None--** and the description is "Gives access to the Pendo Connected App".

**Persona permission sets**

10. Open each of the Customer Success, Executive, Marketing, Product, Sales and Tech **Object, Tab, FLS** permission sets. Under Accounts and Contacts, confirm the Pendo fields have Read access and not Edit access.
11. Log in as a user in one of those personas. Confirm they can see the Pendo fields on an Account and a Contact, but can't edit them.
12. Open **Beacon Salesforce Admin - Object, Tab, FLS** and confirm the Pendo fields have Read and Edit access. As a Salesforce Admin persona user, edit **Account Id Pendo** on an Account and confirm it saves.

## Post Deployment Items

- Assign **Beacon - Pendo Integration** to the Pendo integration user. The user needs the **Salesforce API Integration** permission set license first.
- Connect Pendo to Salesforce with the integration user, and map the Pendo fields to the Salesforce fields above.
- Once the Pendo connected app is in the org, open **Beacon - Pendo Connected App → Assigned Connected Apps**, add the Pendo connected app, and assign the permission set to the Pendo integration user. If the connected app is set to **Admin approved users are pre-authorized**, only users with this permission set can use it.
- Fill in **Account Id Pendo** on customer Accounts with their Pendo Account Ids, so Pendo data lands on the right Accounts.
- If users outside the persona permission sets need to see Pendo data, assign them **Beacon - Pendo User**. In Production, it can also be added to the persona **Integrations** permission set groups, where integration permission sets are managed.
- Add the Pendo fields to Account and Contact page layouts or Lightning pages if users should see them there. This build doesn't change any layouts.

## Component Manifest

Github Branch: [Pendo-Integration](https://github.com/aaroncrear/BeaconImplementation/tree/Pendo-Integration)

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | CustomField | Account | Account_Id_Pendo__c | Account Id Pendo | Created | Text(10). The Pendo Account Id, used to match Pendo data to the Account. |
| 2 | CustomField | Account | Pendo_Days_Active_Last_30_Days__c | Pendo Days Active Last 30 Days | Created | Number. Days the Account was active in the last 30 days, from Pendo. |
| 3 | CustomField | Account | Pendo_Days_Active_Year_To_Date__c | Pendo Days Active Year To Date | Created | Number. Days the Account was active this calendar year, from Pendo. |
| 4 | CustomField | Account | Pendo_Events_Last_30_Days__c | Pendo Events Last 30 Days | Created | Number. Pendo events for the Account in the last 30 days. |
| 5 | CustomField | Account | Pendo_Events_Year_To_Date__c | Pendo Events Year To Date | Created | Number. Pendo events for the Account this calendar year. |
| 6 | CustomField | Account | Pendo_NPS_Last_30_Days__c | Pendo NPS Last 30 Days | Created | Number (2 decimals). Average Pendo NPS for the Account in the last 30 days. |
| 7 | CustomField | Account | Pendo_NPS_Year_To_Date__c | Pendo NPS Year To Date | Created | Number (2 decimals). Average Pendo NPS for the Account this calendar year. |
| 8 | CustomField | Account | Pendo_Visitors_Last_30_Days__c | Pendo No. Of Visitors Last 30 Days (MAU) | Created | Number. Unique Pendo visitors for the Account in the last 30 days. |
| 9 | CustomField | Account | Pendo_Visitors_Year_To_Date__c | Pendo No. Of Visitors Year To Date (MAU) | Created | Number. Unique Pendo visitors for the Account this calendar year. |
| 10 | CustomField | Contact | Pendo_Days_Active_Last_30_Days__c | Pendo Days Active Last 30 Days | Created | Number. Days the Contact was active in the last 30 days, from Pendo. |
| 11 | CustomField | Contact | Pendo_Days_Active_Year_To_Date__c | Pendo Days Active Year To Date | Created | Number. Days the Contact was active this calendar year, from Pendo. |
| 12 | CustomField | Contact | Pendo_Events_Last_30_Days__c | Pendo Events Last 30 Days | Created | Number. Pendo events for the Contact in the last 30 days. |
| 13 | CustomField | Contact | Pendo_Events_Year_To_Date__c | Pendo Events Year To Date | Created | Number. Pendo events for the Contact this calendar year. |
| 14 | CustomField | Contact | Pendo_NPS_Last_30_Days__c | Pendo NPS Last 30 Days | Created | Number. The Contact's Pendo NPS in the last 30 days. |
| 15 | CustomField | Contact | Pendo_NPS_Year_To_Date__c | Pendo NPS Year To Date | Created | Number. The Contact's Pendo NPS this calendar year. |
| 16 | PermissionSet | N/A | Beacon_Pendo_Integration | Beacon - Pendo Integration | Created | Salesforce API Integration license. Read and edit on Account and Contact, and on all 15 Pendo fields. |
| 17 | PermissionSet | N/A | Beacon_Pendo_User | Beacon - Pendo User | Created | Salesforce license. Read on Account and Contact, and on all 15 Pendo fields. |
| 18 | PermissionSet | N/A | Beacon_Pendo_Connected_App | Beacon - Pendo Connected App | Created | No license. Gives access to the Pendo connected app once it's added after deployment. |
| 19 | PermissionSet | N/A | Beacon_Customer_Success_Object_Tab_FLS | Beacon Customer Success - Object, Tab, FLS | Updated | Added read access to the 15 Pendo fields. |
| 20 | PermissionSet | N/A | Beacon_Executive_Object_Tab_FLS | Beacon Executive - Object, Tab, FLS | Updated | Added read access to the 15 Pendo fields. |
| 21 | PermissionSet | N/A | Beacon_Marketing_Object_Tab_FLS | Beacon Marketing - Object, Tab, FLS | Updated | Added read access to the 15 Pendo fields. |
| 22 | PermissionSet | N/A | Beacon_Product_Object_Tab_FLS | Beacon Product - Object, Tab, FLS | Updated | Added read access to the 15 Pendo fields. |
| 23 | PermissionSet | N/A | Beacon_Sales_Object_Tab_FLS | Beacon Sales - Object, Tab, FLS | Updated | Added read access to the 15 Pendo fields. |
| 24 | PermissionSet | N/A | Beacon_Tech_Object_Tab_FLS | Beacon Tech - Object, Tab, FLS | Updated | Added read access to the 15 Pendo fields. |
| 25 | PermissionSet | N/A | Beacon_Salesforce_Admin_Object_Tab_FLS | Beacon Salesforce Admin - Object, Tab, FLS | Updated | Added read and edit access to the 15 Pendo fields. |
