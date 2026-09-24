# "Traffic-Light-System" – Release Notes

## Requirements

Users need to see a record's engagement status at a glance, as a colored flag icon, on Account, Contact, Lead and Opportunity records, in list views and in reports.

- Add an icon for each status: **Blacklisted**, **Do Not Contact**, **Do Not Call**, **Do Not Email**, **Customer** and **Prospect**.
- Store the icons in Salesforce so formula fields can display them with the `IMAGE()` function.
- Add an **Engagement Status** formula field to Accounts, Contacts, Leads and Opportunities that shows one icon, checking in this order. The first match wins:
  1. Blacklisted is checked → **Blacklisted** flag.
  2. Do Not Call and Email Opt Out are both checked → **Do Not Contact** flag.
  3. Do Not Call is checked → **Do Not Call** flag.
  4. Email Opt Out is checked → **Do Not Email** flag.
  5. The Account's Type is Customer → **Customer** flag.
  6. The Account's Type is Prospect → **Prospect** flag.
- On Leads and Contacts, use the standard **Do Not Call** (`DoNotCall`) and **Email Opt Out** (`HasOptedOutOfEmail`) fields.
- For the Account Type, Leads use the custom **Account** lookup. Contacts and Opportunities use the standard **Account** field.
- Add the field as the last field on each object's custom compact layout.
- Give read access to the field in the nine **Beacon … - Object, Tab, FLS** permission sets.

## Release Notes

### Flag icon static resources

Six **static resources** were added, one for each status icon. Each is a PNG image, 40 pixels high, showing a colored flag and the status label in bold on a white rounded badge with a light gray border:

| Static Resource | Flag Color | Text | Shown at (pixels) |
|-----------------|------------|------|-------------------|
| `Blacklisted` | Black | Blacklisted | 89 × 20 |
| `Do_Not_Contact` | Red | Do Not Contact | 115 × 20 |
| `Do_Not_Call` | Orange | Do Not Call | 90 × 20 |
| `Do_Not_Email` | Orange | Do Not Email | 101 × 20 |
| `Customer` | Green | Customer | 81 × 20 |
| `Prospect` | Green | Prospect | 76 × 20 |

Each resource has the description "Used in formula fields to display icons on records, list views and reports."

The icons were drawn so they stay readable anywhere they appear:

- **White badge background.** The first version had a transparent background, so the black "Blacklisted" text disappeared on dark backgrounds. The white badge keeps every label readable on light and dark pages.
- **Double resolution.** The images are 40 pixels high. The formula fields show them at 20 pixels, so they stay sharp on high-resolution screens instead of looking blurry. Each image is an even number of pixels wide, so it scales to exactly half size.
- **Larger text.** The label fills most of the badge's height, so on screen the text is about 13 pixels, the same size as Salesforce's standard body text. An earlier version showed the icons at 16 pixels high, which made the text too small to read comfortably.
- **Readable text colors.** Each label uses a darker shade of its flag color so the text has enough contrast against white (at least 4.5:1, the WCAG AA standard). The flags keep the brighter colors.

Static resources were used because Salesforce serves them from a stable URL, `/resource/<Name>`, which the `IMAGE()` function can reference in a formula field. Unlike Documents or Files, they deploy with the rest of the metadata, so the icons stay the same in every org.

The cache control is set to **Public**. This lets Salesforce cache the images, so list views and reports with many rows load quickly. The icons contain no sensitive data.

### Engagement Status formula fields

A Text formula field, **Engagement Status** (`Engagement_Status__c`), was added to **Account**, **Contact**, **Lead** and **Opportunity**. Its description is "Used to display colored icons for engagement status using Static Resources."

Each formula is a chain of `IF()` checks in the required order, so the first matching status wins. For example, a blacklisted record always shows the Blacklisted flag, even if it is also opted out. When no status matches, the field is blank.

Each object reads these fields:

| Object | Blacklisted | Do Not Call | Email Opt Out | Account Type |
|--------|-------------|-------------|---------------|--------------|
| Account | `Blacklisted__c` | `Do_Not_Call__c` | `Email_Opt_Out__c` | `Type` |
| Contact | `Blacklisted__c` | `DoNotCall` | `HasOptedOutOfEmail` | `Account.Type` |
| Lead | `Blacklisted__c` | `DoNotCall` | `HasOptedOutOfEmail` | `Account__r.Type` (custom Account lookup) |
| Opportunity | `Blacklisted__c` | `Do_Not_Call__c` | `Email_Opt_Out__c` | `Account.Type` |

The Opportunity uses its own Blacklisted, Do Not Call and Email Opt Out fields. The **Account - On Update - After Save** flow already keeps them in sync with the related Account.

For example, the Lead formula is:

```
IF( Blacklisted__c,
    IMAGE("/resource/Blacklisted", "Blacklisted", 20, 89),
IF( AND( DoNotCall, HasOptedOutOfEmail ),
    IMAGE("/resource/Do_Not_Contact", "Do Not Contact", 20, 115),
IF( DoNotCall,
    IMAGE("/resource/Do_Not_Call", "Do Not Call", 20, 90),
IF( HasOptedOutOfEmail,
    IMAGE("/resource/Do_Not_Email", "Do Not Email", 20, 101),
IF( ISPICKVAL( Account__r.Type, "Customer" ),
    IMAGE("/resource/Customer", "Customer", 20, 81),
IF( ISPICKVAL( Account__r.Type, "Prospect" ),
    IMAGE("/resource/Prospect", "Prospect", 20, 76),
    ""
))))))
```

Each `IMAGE()` call sets an exact height and width. This shows every icon at 20 pixels high with its correct proportions. Each also sets alternate text, which screen readers read aloud and which shows if the image cannot load.

### Compact layouts

**Engagement Status** was added as the last field on each custom compact layout:

- **Account:** Account Compact Layout
- **Contact:** Contact Compact Layout
- **Lead:** Leads Custom Compact Layout. This layout also gained **Lead Source** (`LeadSource`), after Title, from the org in the Gearset commit that synced the compact layouts to this branch.
- **Opportunity:** New Awesome Compact Layout and Opportunity Compact Layout. The Opportunity has two custom compact layouts, so the field was added to both.

Lightning Experience shows up to seven fields of a compact layout in the record highlights panel. The Leads Custom Compact Layout has eight fields, but **Phone** and **Mobile** display as one field with a dropdown to switch between them. That leaves seven items, so Engagement Status still shows in the Lead highlights panel.

The Account, Lead and Opportunity (New Awesome Compact Layout) layouts are assigned as their object's primary compact layout, so the icon shows in the record highlights panel. The **Contact Compact Layout is not assigned**. Contacts still use the System Default compact layout, so the icon will not show in the Contact highlights panel until the layout is assigned. See Post Deployment Items.

### Field access

Read-only access to **Engagement Status** on all four objects was added to these permission sets:

- Beacon Consulting - Object, Tab, FLS
- Beacon Customer Success - Object, Tab, FLS
- Beacon Executive - Object, Tab, FLS
- Beacon Marketing - Object, Tab, FLS
- Beacon Product - Object, Tab, FLS
- Beacon ResOps - Object, Tab, FLS
- Beacon Sales - Object, Tab, FLS
- Beacon Salesforce Admin - Object, Tab, FLS
- Beacon Tech - Object, Tab, FLS

Formula fields cannot be edited, so only read access is granted.

## Acceptance Criteria

1. In **Setup → Static Resources**, confirm these six static resources exist: **Blacklisted**, **Do_Not_Contact**, **Do_Not_Call**, **Do_Not_Email**, **Customer** and **Prospect**.
2. For each one, confirm:
   1. **MIME Type** is `image/png`.
   2. **Cache Control** is **Public**.
   3. **Description** is "Used in formula fields to display icons on records, list views and reports."
3. For each one, click **View file** and confirm the image shows the correct flag and bold text on a white badge, sharp and readable:
   1. **Blacklisted**: black flag, "Blacklisted".
   2. **Do_Not_Contact**: red flag, "Do Not Contact".
   3. **Do_Not_Call**: orange flag, "Do Not Call".
   4. **Do_Not_Email**: orange flag, "Do Not Email".
   5. **Customer**: green flag, "Customer".
   6. **Prospect**: green flag, "Prospect".
4. In **Object Manager**, confirm **Engagement Status** (`Engagement_Status__c`) exists on Account, Contact, Lead and Opportunity as a **Formula (Text)** field with the description "Used to display colored icons for engagement status using Static Resources."
5. Log in as, or assign the permission set to, a user with one of the nine **Beacon … - Object, Tab, FLS** permission sets. Confirm the user can see **Engagement Status** on all four objects and cannot edit it.
6. **Account:** on one Account, work through each status and confirm the icon in the highlights panel. Uncheck everything before each step unless it says otherwise.
   1. Set **Type** to **Customer**. Confirm the green **Customer** flag.
   2. Set **Type** to **Prospect**. Confirm the green **Prospect** flag.
   3. Set **Type** to any other value, or leave it blank. Confirm the field is blank.
   4. Check **Email Opt Out**. Confirm the orange **Do Not Email** flag.
   5. Check **Do Not Call** only. Confirm the orange **Do Not Call** flag.
   6. Check both **Do Not Call** and **Email Opt Out**. Confirm the red **Do Not Contact** flag.
   7. With both still checked, and **Type** set to **Customer**, check **Blacklisted**. Confirm the black **Blacklisted** flag, because Blacklisted is checked first.
7. **Contact:** on a Contact whose Account has **Type** = Customer, repeat step 6 using the Contact's **Blacklisted**, **Do Not Call** and **Email Opt Out** fields. Confirm the Customer and Prospect flags follow the Account's Type. Then remove the Account from the Contact and confirm the field is blank when no other status applies.
8. **Lead:** on a Lead, set the custom **Account** lookup to an Account with **Type** = Customer, then Prospect. Confirm the Customer and Prospect flags. Repeat the checkbox steps from step 6 using the Lead's **Blacklisted**, **Do Not Call** and **Email Opt Out** fields.
9. **Opportunity:** on an Opportunity, confirm the Customer and Prospect flags follow the Account's **Type**. Check **Blacklisted**, **Do Not Call** and **Email Opt Out** on the related Account, and confirm the Opportunity's icon updates to match once the flow syncs them.
10. On each object, add **Engagement Status** to a list view and to a report. Confirm the icons show at the same 20-pixel height as on the record, sharp and readable.
11. Open a Lead and confirm **Engagement Status** shows in the highlights panel, with **Phone** and **Mobile** shown as one field with a dropdown.
12. Open each compact layout in **Object Manager → Compact Layouts** and confirm **Engagement Status** is the last field. For Opportunity, check both **New Awesome Compact Layout** and **Opportunity Compact Layout**.

## Post Deployment Items

- Confirm the Account **Type** picklist has values whose API names are exactly `Customer` and `Prospect`. The formulas match those exact API names. If the org uses different values, such as `Customer - Direct`, update the formulas to match.
- To show the icon in the Contact highlights panel, assign the **Contact Compact Layout** as the primary compact layout in **Object Manager → Contact → Compact Layouts → Compact Layout Assignment**. It is currently the System Default. Skip this if Contacts should keep the System Default.

## Component Manifest

Github Branch: https://github.com/aaroncrear/BeaconImplementation/tree/Traffic-Light-System

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | StaticResource | N/A | Blacklisted | Blacklisted | Created | Black flag icon with the text "Blacklisted". Used in formula fields to display icons on records, list views and reports. |
| 2 | StaticResource | N/A | Do_Not_Contact | Do_Not_Contact | Created | Red flag icon with the text "Do Not Contact". Used in formula fields to display icons on records, list views and reports. |
| 3 | StaticResource | N/A | Do_Not_Call | Do_Not_Call | Created | Orange flag icon with the text "Do Not Call". Used in formula fields to display icons on records, list views and reports. |
| 4 | StaticResource | N/A | Do_Not_Email | Do_Not_Email | Created | Orange flag icon with the text "Do Not Email". Used in formula fields to display icons on records, list views and reports. |
| 5 | StaticResource | N/A | Customer | Customer | Created | Green flag icon with the text "Customer". Used in formula fields to display icons on records, list views and reports. |
| 6 | StaticResource | N/A | Prospect | Prospect | Created | Green flag icon with the text "Prospect". Used in formula fields to display icons on records, list views and reports. |
| 7 | CustomField | Account | Engagement_Status__c | Engagement Status | Created | Text formula showing the engagement status icon, based on Blacklisted__c, Do_Not_Call__c, Email_Opt_Out__c and Type. |
| 8 | CustomField | Contact | Engagement_Status__c | Engagement Status | Created | Text formula showing the engagement status icon, based on Blacklisted__c, DoNotCall, HasOptedOutOfEmail and Account.Type. |
| 9 | CustomField | Lead | Engagement_Status__c | Engagement Status | Created | Text formula showing the engagement status icon, based on Blacklisted__c, DoNotCall, HasOptedOutOfEmail and Account__r.Type. |
| 10 | CustomField | Opportunity | Engagement_Status__c | Engagement Status | Created | Text formula showing the engagement status icon, based on Blacklisted__c, Do_Not_Call__c, Email_Opt_Out__c and Account.Type. |
| 11 | CompactLayout | Account | Account_Compact_Layout | Account Compact Layout | Updated | Added Engagement_Status__c as the last field. |
| 12 | CompactLayout | Contact | Contact_Compact_Layout | Contact Compact Layout | Updated | Added Engagement_Status__c as the last field. |
| 13 | CompactLayout | Lead | Leads_Custom_Compact_Layout | Leads Custom Compact Layout | Updated | Added Engagement_Status__c as the last field. Also includes LeadSource, added after Title, synced from the org by Gearset. |
| 14 | CompactLayout | Opportunity | New_Awesome_Companct_Layout | New Awesome Compact Layout | Updated | Added Engagement_Status__c as the last field. |
| 15 | CompactLayout | Opportunity | Opportunity_Companct_Layout | Opportunity Compact Layout | Updated | Added Engagement_Status__c as the last field. |
| 16 | PermissionSet | N/A | Beacon_Consulting_Object_Tab_FLS | Beacon Consulting - Object, Tab, FLS | Updated | Added read access to Engagement_Status__c on Account, Contact, Lead and Opportunity. |
| 17 | PermissionSet | N/A | Beacon_Customer_Success_Object_Tab_FLS | Beacon Customer Success - Object, Tab, FLS | Updated | Added read access to Engagement_Status__c on Account, Contact, Lead and Opportunity. |
| 18 | PermissionSet | N/A | Beacon_Executive_Object_Tab_FLS | Beacon Executive - Object, Tab, FLS | Updated | Added read access to Engagement_Status__c on Account, Contact, Lead and Opportunity. |
| 19 | PermissionSet | N/A | Beacon_Marketing_Object_Tab_FLS | Beacon Marketing - Object, Tab, FLS | Updated | Added read access to Engagement_Status__c on Account, Contact, Lead and Opportunity. |
| 20 | PermissionSet | N/A | Beacon_Product_Object_Tab_FLS | Beacon Product - Object, Tab, FLS | Updated | Added read access to Engagement_Status__c on Account, Contact, Lead and Opportunity. |
| 21 | PermissionSet | N/A | Beacon_ResOps_Object_Tab_FLS | Beacon ResOps - Object, Tab, FLS | Updated | Added read access to Engagement_Status__c on Account, Contact, Lead and Opportunity. |
| 22 | PermissionSet | N/A | Beacon_Sales_Object_Tab_FLS | Beacon Sales - Object, Tab, FLS | Updated | Added read access to Engagement_Status__c on Account, Contact, Lead and Opportunity. |
| 23 | PermissionSet | N/A | Beacon_Salesforce_Admin_Object_Tab_FLS | Beacon Salesforce Admin - Object, Tab, FLS | Updated | Added read access to Engagement_Status__c on Account, Contact, Lead and Opportunity. |
| 24 | PermissionSet | N/A | Beacon_Tech_Object_Tab_FLS | Beacon Tech - Object, Tab, FLS | Updated | Added read access to Engagement_Status__c on Account, Contact, Lead and Opportunity. |
