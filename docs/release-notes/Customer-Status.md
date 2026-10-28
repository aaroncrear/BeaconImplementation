# "Customer-Status" – Release Notes

## Requirements

- In the **Type** field on Account:
  - Deactivate **Analyst**, **Integrator**, **Investor** and **Press**.
  - Add **Former Customer**.
  - Sort the values alphabetically, with **Other** kept at the bottom.
- In the **Engagement Status** field on Accounts, Leads, Contacts and Opportunities:
  - Remove the **Customer** and **Prospect** values.
  - Add a new **Contactable** value. It shows when no other criteria are met.
  - Create a new static resource for Contactable: a green flag that looks like the Prospect icon.
- Add a **Customer Status** formula field to Leads, Contacts and Opportunities:
  - On Leads and Opportunities, show the Account's **Type**.
  - On Contacts, show the Account's Type, except when it's **Customer**. Then show **Customer - User** if the Contact has an active Beacon Subscription, or **Customer - Non-User** if not.
- Add an **Active Beacon Subscription** field on Contacts, kept up to date by a daily scheduled flow, so the Contact formula can read it. The flow only needs to run on Contacts whose Account Type is Customer.
- Give read access to the new fields in the ten **Beacon … - Object, Tab, FLS** permission sets: Consulting, Customer Success, Executive, Finance, Marketing, Product, ResOps, Sales, Salesforce Admin and Tech.
- Add **Customer Status** right after **Engagement Status** on the custom compact layouts for Leads, Contacts and Opportunities.
- Remove **Lead Source** from the Lead compact layout.

## Release Notes

### Account Type picklist

The Account **Type** field is a standard picklist, so its values live in the `AccountType` standard value set. This file wasn't in the repository before, so it was added from the values currently in the org, with these changes:

| Value | Status |
|-------|--------|
| Competitor | Active |
| Customer | Active |
| Former Customer | Active (new) |
| Partner | Active |
| Prospect | Active |
| Reseller | Active |
| Other | Active (kept at the bottom) |
| Analyst | Inactive |
| Integrator | Inactive |
| Investor | Inactive |
| Press | Inactive |

The value set stays unsorted (`sorted` = false), so the order in the file is the order users see. Alphabetical sorting would have moved **Other** up between Customer and Partner.

The four values were deactivated rather than deleted. Any existing Accounts that use them keep their value, and reports on them keep working, but users can't choose these values anymore. Account has no record types, so no record type picklist settings needed to change.

### Engagement Status formula fields

The **Engagement Status** (`Engagement_Status__c`) formula on **Account**, **Contact**, **Lead** and **Opportunity** no longer checks the Account Type. The Customer and Prospect branches were removed, and the final default now shows the new **Contactable** flag. The formula checks these in order, and the first match wins:

1. Blacklisted is checked → **Blacklisted** flag.
2. Do Not Call and Email Opt Out are both checked → **Do Not Contact** flag.
3. Do Not Call is checked → **Do Not Call** flag.
4. Email Opt Out is checked → **Do Not Email** flag.
5. None of the above → **Contactable** flag.

The fields each object reads for the first four checks haven't changed. Because the Account Type is no longer used, the Account Type on a Contact, Lead or Opportunity's Account no longer changes the flag, and records with no Account still show Contactable.

### Contactable static resource

A new static resource, `Contactable`, was added. It follows the same design as the existing flag icons from the Traffic Light System build:

- A green flag with the bold label "Contactable" in dark green, on a white rounded badge with a light gray border.
- The flag, badge edges and colors were copied directly from `Prospect.png`, so the two icons match exactly.
- The image is 190 × 40 pixels. The formula shows it at 95 × 20, half size, so it stays sharp on high-resolution screens.
- The cache control is **Public** and the description is "Used in formula fields to display icons on records, list views and reports.", the same as the other flag icons.

The `Customer` and `Prospect` static resources are no longer used by the Engagement Status formulas, but they were left in place, not deleted. They can be removed later if nothing else needs them.

### Customer Status formula fields

A Text formula field, **Customer Status** (`Customer_Status__c`), was added to **Lead**, **Contact** and **Opportunity**:

| Object | Formula | Result |
|--------|---------|--------|
| Lead | `TEXT( Account__r.Type )` | The Type of the Account in the Lead's custom **Account** lookup. |
| Opportunity | `TEXT( Account.Type )` | The Type of the Opportunity's Account. |
| Contact | `IF( ISPICKVAL( Account.Type, "Customer" ), IF( Active_Beacon_Subscription__c, "Customer - User", "Customer - Non-User" ), TEXT( Account.Type ) )` | The Account's Type, with Customer split into Customer - User and Customer - Non-User. |

The field is blank when the record has no Account or the Account has no Type. Leads use the custom Account lookup (`Account__c`) because it's the same lookup the Engagement Status formula uses.

### Active Beacon Subscription field

A Checkbox field, **Active Beacon Subscription** (`Active_Beacon_Subscription__c`), was added to **Contact**, unchecked by default. It's checked when the Contact has at least one Beacon Subscription whose **Active** field is true.

A formula can't look at a Contact's Beacon Subscriptions, because they're child records. So the value is stored on the Contact and kept up to date by a flow. The field is read-only in every permission set, because only the flow should change it.

### Contact - Active Beacon Subscriptions - Scheduled flow

A new schedule-triggered flow, **Contact - Active Beacon Subscriptions - Scheduled**, runs every day at 01:00 for Contacts:

1. **Run Flows and Customer Account?** The flow continues only when **Run Flows** is checked on the On/Off Switch custom setting and the Contact's Account Type is **Customer**. Other Contacts are skipped, because Customer Status only reads Active Beacon Subscription when the Type is Customer.
2. **Get Active Beacon Subscription** looks for one Beacon Subscription linked to the Contact (`Contact__c`) with **Active** = true. It uses the subscription's existing Active formula, so the active rule (between Start Date and End Date, with Date Access Removed blank) stays in one place.
3. **Active Beacon Subscription Changed?** compares the result with the Contact's current value.
4. **Update Active Beacon Subscription** saves the new value, but only when it has changed. This avoids updating every Customer Contact every day, which would fill Last Modified dates and run Contact automation for no reason.

Both the Get and Update elements have a fault path to the **Fault Path Subflow**, like the other flows in the org.

The Account Type check is in the first decision instead of the start conditions, because a scheduled flow's start conditions can only use the Contact's own fields, not the Account's. The flow still starts for each Contact, but ends right away for non-Customer Contacts without querying or updating anything.

Some things to know about how this behaves:

- **Updated once a day.** If a subscription starts, ends or has its access removed during the day, Customer Status changes after the next nightly run.
- **When an Account stops being a Customer**, its Contacts aren't checked anymore, so their Active Beacon Subscription value can be out of date. This doesn't affect Customer Status, which only reads the field when the Type is Customer. If the Account becomes a Customer again, the next run fixes the value.

### Compact layouts

**Customer Status** was added right after **Engagement Status**, the last field, on each object's custom compact layout. In the record highlights panel, it shows to the right of Engagement Status:

| Object | Compact Layout | Fields after the change |
|--------|----------------|-------------------------|
| Lead | Leads Custom Compact Layout | Name, Company, Title, Phone, Mobile, Email, Engagement Status, Customer Status |
| Contact | Contact Compact Layout | Name, Account, Title, Phone, Mobile, Email, Engagement Status, Customer Status |
| Opportunity | New Awesome Compact Layout | Name, Account, Close Date, Amount, Owner, Engagement Status, Customer Status |
| Opportunity | Opportunity Compact Layout | Name, Account, Amount, Close Date, Owner, Engagement Status, Customer Status |

**Lead Source** was also removed from the Lead compact layout. It now has the same number of fields as the Contact layout, so the header doesn't get more crowded.

Opportunity has two custom compact layouts, and both were updated so the field shows whichever one is assigned. This matches how Engagement Status was added in the Traffic Light System build.

## Acceptance Criteria

**Account Type**

1. Go to **Setup → Object Manager → Account → Fields & Relationships → Type**.
2. Confirm the active values, in this order: Competitor, Customer, Former Customer, Partner, Prospect, Reseller, Other.
3. Confirm Analyst, Integrator, Investor and Press appear under **Inactive Values**.
4. Open an Account, edit **Type**, and confirm the dropdown shows only the seven active values in the order above, with **Former Customer** available.
5. Set Type to **Former Customer**, save, and confirm the value saves.

**Contactable static resource**

6. Go to **Setup → Static Resources** and confirm **Contactable** exists with MIME type `image/png` and cache control **Public**.
7. Click **View File** and confirm it shows a green flag with the label "Contactable", in the same style as the Prospect icon.

**Engagement Status**

8. On an Account with Blacklisted, Do Not Call and Email Opt Out all unchecked, confirm **Engagement Status** shows the green **Contactable** flag.
9. Set the Account's Type to **Customer**, save, and confirm the field still shows **Contactable**. Repeat with **Prospect**, **Former Customer** and blank.
10. Check **Email Opt Out** and confirm the field shows **Do Not Email**. Also check **Do Not Call** and confirm it shows **Do Not Contact**. Uncheck both, check **Blacklisted**, and confirm it shows **Blacklisted**.
11. Repeat steps 8 and 10 on a Contact, a Lead and an Opportunity. On Contacts and Leads, use the standard **Do Not Call** and **Email Opt Out** fields.
12. Confirm a Contact with no Account, and a Lead with no Account, show **Contactable**.
13. Open a list view or report that includes Engagement Status and confirm the Contactable flag shows clearly at full size, not cut off.

**Customer Status – Lead and Opportunity**

14. Open a Lead whose **Account** lookup points to an Account with Type **Partner**. Confirm **Customer Status** shows "Partner". Change the Account's Type and confirm the Lead's value follows it.
15. Open an Opportunity on a **Customer** Account and confirm Customer Status shows "Customer". Confirm a Lead with no Account shows a blank value.

**Customer Status – Contact**

16. Open a Contact whose Account's Type is **Prospect**. Confirm Customer Status shows "Prospect".
17. Change the Account's Type to **Customer**. Confirm the Contact shows "Customer - Non-User" while Active Beacon Subscription is unchecked.
18. Create a Beacon Subscription linked to the Contact with Start Date yesterday, End Date next month and Date Access Removed blank. Confirm its **Active** field is checked.
19. Run the flow. In Setup → Flows, open **Contact - Active Beacon Subscriptions - Scheduled** and click **Debug**, choosing this Contact, without rolling back changes. Or wait for the nightly run. Confirm **Active Beacon Subscription** is checked and Customer Status shows "Customer - User".
20. Enter today in the subscription's **Date Access Removed** and run the flow again. Confirm Active Beacon Subscription is unchecked and Customer Status shows "Customer - Non-User".
21. Run the flow on a Contact whose Account Type is **Prospect** and that has an active subscription. Confirm the flow skips it and Active Beacon Subscription doesn't change.
22. Run the flow again on a Customer Contact whose value is already correct. Confirm the Contact's **Last Modified** date doesn't change.
23. Uncheck **Run Flows** on the On/Off Switch custom setting, run the flow, and confirm no Contacts change. Check it again afterwards.

**Field access**

24. Log in as, or check a user with, each of the ten Beacon … - Object, Tab, FLS permission sets. Confirm they can see Customer Status on Leads, Contacts and Opportunities, and Active Beacon Subscription on Contacts, and can't edit Active Beacon Subscription.

**Compact layouts**

25. Open a Lead, a Contact and an Opportunity in Lightning. Confirm **Customer Status** shows in the highlights panel at the top of the record, right after Engagement Status. On the Lead, also confirm **Lead Source** no longer shows in the highlights panel.
26. In **Setup → Object Manager → Opportunity → Compact Layouts**, confirm both custom compact layouts list Customer Status right after Engagement Status.

## Post Deployment Items

- In each target org, run a report or query to find Accounts whose Type is Analyst, Integrator, Investor or Press, and decide whether to update them to an active value. None exist in the dev org (Beacon HTC DEV). Deactivated values stay on existing records until someone changes them.
- Deploy the `Contactable` static resource together with, or before, the four Engagement Status fields. Otherwise the formulas point to an image that doesn't exist yet.
- After deploying, populate **Active Beacon Subscription** straight away, instead of waiting for the first nightly run. Either run the flow from Flow Builder's Debug tool, or update the field with a data load. Until then, every Customer Contact shows "Customer - Non-User".
- Confirm the flow's schedule in **Setup → Scheduled Jobs**. It's set to run daily at 01:00 in the org's default time zone, starting 29 October 2026. If the deployment happens after that date, open the flow and set a new start date. Activating it schedules the next run.
- The flow starts once per Contact each day, and Salesforce allows 250,000 scheduled flow interviews per 24 hours (or 200 per user license, if that's higher). Contacts on non-Customer Accounts end straight away, but they still count. Check the Contact count in production before deploying.
- Add **Customer Status** to page layouts or list views if users should see it there. This build only adds it to the compact layouts.

## Component Manifest

Github Branch: [Customer-Status](https://github.com/aaroncrear/BeaconImplementation/tree/Customer-Status)

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | StandardValueSet | Account | AccountType | Account Type | Updated | Added Former Customer; deactivated Analyst, Integrator, Investor and Press; set the order to alphabetical with Other last. First time this value set is tracked in the repository. |
| 2 | StaticResource | N/A | Contactable | Contactable | Created | Green-flag "Contactable" badge (190 × 40 PNG), matching the Prospect icon, used by the Engagement Status formulas. |
| 3 | CustomField | Account | Engagement_Status__c | Engagement Status | Updated | Removed the Customer and Prospect branches; the default now shows the Contactable flag. |
| 4 | CustomField | Contact | Engagement_Status__c | Engagement Status | Updated | Removed the Customer and Prospect branches; the default now shows the Contactable flag. |
| 5 | CustomField | Lead | Engagement_Status__c | Engagement Status | Updated | Removed the Customer and Prospect branches; the default now shows the Contactable flag. |
| 6 | CustomField | Opportunity | Engagement_Status__c | Engagement Status | Updated | Removed the Customer and Prospect branches; the default now shows the Contactable flag. |
| 7 | CustomField | Contact | Active_Beacon_Subscription__c | Active Beacon Subscription | Created | Checkbox, unchecked by default. Checked when the Contact has an active Beacon Subscription; set daily by the scheduled flow. |
| 8 | CustomField | Contact | Customer_Status__c | Customer Status | Created | Formula (Text). The Account Type, or Customer - User / Customer - Non-User when the Type is Customer, based on Active Beacon Subscription. |
| 9 | CustomField | Lead | Customer_Status__c | Customer Status | Created | Formula (Text). The Type of the Account in the Lead's Account lookup. |
| 10 | CustomField | Opportunity | Customer_Status__c | Customer Status | Created | Formula (Text). The Type of the Opportunity's Account. |
| 11 | Flow | Contact | Contact_Active_Beacon_Subscriptions_Scheduled | Contact - Active Beacon Subscriptions - Scheduled | Created | Daily schedule-triggered flow. For Contacts whose Account Type is Customer, sets Active Beacon Subscription from their active Beacon Subscriptions, and only updates when it changes. |
| 12 | CompactLayout | Contact | Contact_Compact_Layout | Contact Compact Layout | Updated | Added Customer_Status__c right after Engagement_Status__c. |
| 13 | CompactLayout | Lead | Leads_Custom_Compact_Layout | Leads Custom Compact Layout | Updated | Added Customer_Status__c right after Engagement_Status__c and removed LeadSource. |
| 14 | CompactLayout | Opportunity | New_Awesome_Companct_Layout | New Awesome Compact Layout | Updated | Added Customer_Status__c right after Engagement_Status__c. |
| 15 | CompactLayout | Opportunity | Opportunity_Companct_Layout | Opportunity Compact Layout | Updated | Added Customer_Status__c right after Engagement_Status__c. |
| 16 | PermissionSet | N/A | Beacon_Consulting_Object_Tab_FLS | Beacon Consulting - Object, Tab, FLS | Updated | Added read access to Customer_Status__c on Contact, Lead and Opportunity, and to Active_Beacon_Subscription__c on Contact. |
| 17 | PermissionSet | N/A | Beacon_Customer_Success_Object_Tab_FLS | Beacon Customer Success - Object, Tab, FLS | Updated | Added read access to Customer_Status__c on Contact, Lead and Opportunity, and to Active_Beacon_Subscription__c on Contact. |
| 18 | PermissionSet | N/A | Beacon_Executive_Object_Tab_FLS | Beacon Executive - Object, Tab, FLS | Updated | Added read access to Customer_Status__c on Contact, Lead and Opportunity, and to Active_Beacon_Subscription__c on Contact. |
| 19 | PermissionSet | N/A | Beacon_Finance_Object_Tab_FLS | Beacon Finance - Object, Tab, FLS | Updated | Added read access to Customer_Status__c on Contact, Lead and Opportunity, and to Active_Beacon_Subscription__c on Contact. |
| 20 | PermissionSet | N/A | Beacon_Marketing_Object_Tab_FLS | Beacon Marketing - Object, Tab, FLS | Updated | Added read access to Customer_Status__c on Contact, Lead and Opportunity, and to Active_Beacon_Subscription__c on Contact. |
| 21 | PermissionSet | N/A | Beacon_Product_Object_Tab_FLS | Beacon Product - Object, Tab, FLS | Updated | Added read access to Customer_Status__c on Contact, Lead and Opportunity, and to Active_Beacon_Subscription__c on Contact. |
| 22 | PermissionSet | N/A | Beacon_ResOps_Object_Tab_FLS | Beacon ResOps - Object, Tab, FLS | Updated | Added read access to Customer_Status__c on Contact, Lead and Opportunity, and to Active_Beacon_Subscription__c on Contact. |
| 23 | PermissionSet | N/A | Beacon_Sales_Object_Tab_FLS | Beacon Sales - Object, Tab, FLS | Updated | Added read access to Customer_Status__c on Contact, Lead and Opportunity, and to Active_Beacon_Subscription__c on Contact. |
| 24 | PermissionSet | N/A | Beacon_Salesforce_Admin_Object_Tab_FLS | Beacon Salesforce Admin - Object, Tab, FLS | Updated | Added read access to Customer_Status__c on Contact, Lead and Opportunity, and to Active_Beacon_Subscription__c on Contact. |
| 25 | PermissionSet | N/A | Beacon_Tech_Object_Tab_FLS | Beacon Tech - Object, Tab, FLS | Updated | Added read access to Customer_Status__c on Contact, Lead and Opportunity, and to Active_Beacon_Subscription__c on Contact. |
