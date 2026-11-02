# "Lead-Type" – Release Notes

## Requirements

- Bring the **Lead Type** global value set into the repository. It gives more detailed reporting than Lead Source.
- Users should only be able to pick the original Lead Type values, from **Active Inquiry** through **Intelligence Referral**.
- The values listed after **Intelligence Referral** were added to the org today. Deactivate them so users can't choose them, but don't delete them.

## Release Notes

The `Lead_Type` global value set was pulled into the branch with Gearset. In this build, every value after **Intelligence Referral** is now inactive. That's 29 values:

| # | Value | Status |
|---|-------|--------|
| 1 | Account Upgrade | Deactivated |
| 2 | Active enquiry | Deactivated |
| 3 | Allocated List | Deactivated |
| 4 | Click through | Deactivated |
| 5 | Customer Success Referral | Deactivated |
| 6 | Delegate referral | Deactivated |
| 7 | Email Open | Deactivated |
| 8 | External referral | Deactivated |
| 9 | Infographic Download | Deactivated |
| 10 | LinkedIn Lead Gen | Deactivated |
| 11 | Mail Merge | Deactivated |
| 12 | Onsite Demo | Deactivated |
| 13 | Production referral | Deactivated |
| 14 | Renewal | Deactivated |
| 15 | Sales Navigator | Deactivated |
| 16 | Sales research | Deactivated |
| 17 | Social network contact | Deactivated |
| 18 | Spex referral | Deactivated |
| 19 | Top 100 | Deactivated |
| 20 | Webinar | Deactivated |
| 21 | On-Site Rebook | Deactivated |
| 22 | Analyst Referral | Deactivated |
| 23 | Digital Event | Deactivated |
| 24 | HW Delegate | Deactivated |
| 25 | Sales Trip | Deactivated |
| 26 | SCP | Deactivated |
| 27 | Target Sales research | Deactivated |
| 28 | Targeted Sales Outreach | Deactivated |
| 29 | Webinar Recording Download | Deactivated |

The 27 values from **Active Inquiry** through **Intelligence Referral** stay active, in their current order.

These values were deactivated, not deleted. Any records that already use them keep their value, and reports on them keep working, but users can't pick them for new records. The value set stays unsorted (`sorted` = false), so the order in the file is the order users see.

## Acceptance Criteria

1. Deploy the branch to the target org.
2. Go to **Setup → Picklist Value Sets → Lead Type**.
3. Under **Values**, confirm that the 27 values from **Active Inquiry** through **Intelligence Referral** are active, in the same order as before.
4. Under **Inactive Values**, confirm that all 29 values in the Release Notes table are listed.
5. Open or create a record with a field that uses the Lead Type value set. Confirm the picklist shows only the 27 active values.
6. If any record already had one of the deactivated values, open it and confirm the value is still shown.

## Post Deployment Items

None

## Component Manifest

Github Branch: [Lead-Type](https://github.com/aaroncrear/BeaconImplementation/tree/Lead-Type)

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | GlobalValueSet | N/A | Lead_Type | Lead Type | Updated | Deactivated the 29 values after Intelligence Referral (Account Upgrade through Webinar Recording Download). Active Inquiry through Intelligence Referral stay active. |
