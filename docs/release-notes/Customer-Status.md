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

## Post Deployment Items

- In each target org, run a report or query to find Accounts whose Type is Analyst, Integrator, Investor or Press, and decide whether to update them to an active value. None exist in the dev org (Beacon HTC DEV). Deactivated values stay on existing records until someone changes them.
- Deploy the `Contactable` static resource together with, or before, the four Engagement Status fields. Otherwise the formulas point to an image that doesn't exist yet.

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
