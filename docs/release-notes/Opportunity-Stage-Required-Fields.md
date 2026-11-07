# Opportunity-Stage-Required-Fields – Release Notes

## Requirements

Subscription Opportunities (Subscription New and Subscription Renewal) need certain fields completed before they can move on from a stage:

| Leaving stage | Required fields |
|---|---|
| Demo Booked | Date Demo Scheduled (new date field), Primary Module, Primary Campaign Source, Lead Source, Lead Type |
| Demo Completed | Date Demo Booked |
| Proposal | Invoice Terms |

The existing rule that requires fields when an Opportunity enters Demo Booked should apply to Subscription New only.

## Release Notes

### New field

**Date Demo Scheduled** (`Date_Demo_Scheduled__c`, Date) holds the date the demo will take place. It sits below **Date Demo Booked** (the day the demo was booked) on the Opportunity layouts, and has the same access as Date Demo Booked in every permission set.

### New validation rules

Each rule fires only when the Stage **changes from** the listed stage **to a later stage**, so reps can work the stage freely and fill the fields in before moving on:

| Rule | Fires when the Stage moves from | to | Requires |
|---|---|---|---|
| Required_Fields_Leaving_Demo_Booked | Demo Booked | Demo Completed, Proposal, Contract or Closed Won | Date Demo Scheduled, Primary Module, Primary Campaign Source, Lead Source, Lead Type |
| Required_Fields_Leaving_Demo_Completed | Demo Completed | Proposal, Contract or Closed Won | Date Demo Booked |
| Required_Fields_Leaving_Proposal | Proposal | Contract or Closed Won | Invoice Terms |

- They check the stage the Opportunity is leaving (`PRIORVALUE(StageName)`), so moving back a stage or to **Closed Lost** is never blocked, and existing Opportunities aren't affected until their Stage is changed.
- They apply to both Subscription record types (`Subscription_New`, `Subscription_Renewal`). Only Subscription New uses the Demo stages; the Proposal rule applies to renewals too.
- Like the other Beacon rules, they're skipped when **Run Validation Rules** is unchecked on the On/Off Switch.

### Existing rule

**Required_Fields_Demo_Booked** (Primary Campaign Source, Type, Primary Module, Lead Source and Lead Type required on entering Demo Booked) now applies to **Subscription New** only.

### Interaction with the quote automation

**Quote - On Update - After Save** moves the Opportunity from Proposal to **Contract** when its syncing quote reaches the final status. If Invoice Terms is blank, the new Proposal rule stops that update: the quote still saves, but the Opportunity stays at Proposal and the flow's fault email is sent. Reps should complete Invoice Terms before the quote is finalised. If Beacon wants the rep to see the message on the quote instead, a quote validation rule can be added later.

## Acceptance Criteria

Use a Subscription New Opportunity unless stated.

1. Open an Opportunity. Confirm **Date Demo Scheduled** shows below Date Demo Booked and can be edited by a Sales user.
2. **Entering Demo Booked (existing rule).** With Type blank, move from Request for Information to Demo Booked. Confirm the existing error. (Renewal and Consulting Opportunities don't have a Demo Booked stage, so the rule can only fire on Subscription New.)
3. **Leaving Demo Booked.** At Demo Booked with Date Demo Scheduled blank, move to Demo Completed. Confirm the error lists Date Demo Scheduled, Primary Module, Primary Campaign Source, Lead Source and Lead Type. Fill Date Demo Scheduled and save the move. Confirm it succeeds.
4. Repeat step 3 clearing Primary Module, then Primary Campaign Source, Lead Source and Lead Type in turn. Confirm each blocks the move.
5. At Demo Booked with Date Demo Scheduled blank, move straight to Proposal. Confirm the same error (skipping a stage still counts as leaving Demo Booked).
6. At Demo Booked with Date Demo Scheduled blank, move back to Request for Information, then to Closed Lost. Confirm neither is blocked.
7. **Leaving Demo Completed.** At Demo Completed with Date Demo Booked blank, move to Proposal. Confirm the error. Fill Date Demo Booked and confirm the move succeeds.
8. **Leaving Proposal.** At Proposal with Invoice Terms blank, move to Contract. Confirm the error. Fill Invoice Terms and confirm the move succeeds.
9. On a **Subscription Renewal** Opportunity at Proposal with Invoice Terms blank, move to Contract. Confirm the error.
10. On a **Consulting** Opportunity at Proposal with Invoice Terms blank, move to Contract. Confirm it isn't blocked.
11. **Quote automation.** On a Subscription New Opportunity at Proposal with Invoice Terms blank, set the syncing quote to its final status. Confirm the Opportunity stays at Proposal and the fault email arrives. Fill Invoice Terms, set the quote back and forward again, and confirm the Opportunity moves to Contract.
12. With **Run Validation Rules** unchecked on your On/Off Switch, repeat step 8. Confirm the move isn't blocked.

## Post Deployment Items

1. **Lightning record pages.** If the Opportunity Lightning pages use Dynamic Forms rather than the page layout, add **Date Demo Scheduled** next to Date Demo Booked on them.
2. **Paths.** Optionally add the required fields to each stage's Key Fields in the Subscription New and Renewal Opportunity paths (Setup → Path Settings) so reps see them before moving on.
3. **Gearset.** Deploy only the Date Demo Scheduled field permission in each permission set, so other differences in those permission sets aren't deployed with it.

## Component Manifest

Github Branch: [Opportunity-Stage-Required-Fields](https://github.com/aaroncrear/BeaconImplementation/tree/Opportunity-Stage-Required-Fields)

Package manifest: `manifest/Opportunity-Stage-Required-Fields-package.xml`

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | CustomField | Opportunity | Date_Demo_Scheduled__c | Date Demo Scheduled | Created | Date the demo will take place. Required to move on from Demo Booked. |
| 2 | ValidationRule | Opportunity | Required_Fields_Demo_Booked | Required_Fields_Demo_Booked | Updated | Now applies to Subscription New only (was every record type). |
| 3 | ValidationRule | Opportunity | Required_Fields_Leaving_Demo_Booked | Required_Fields_Leaving_Demo_Booked | Created | Moving on from Demo Booked requires Date Demo Scheduled, Primary Module, Primary Campaign Source, Lead Source and Lead Type. |
| 4 | ValidationRule | Opportunity | Required_Fields_Leaving_Demo_Completed | Required_Fields_Leaving_Demo_Completed | Created | Moving on from Demo Completed requires Date Demo Booked. |
| 5 | ValidationRule | Opportunity | Required_Fields_Leaving_Proposal | Required_Fields_Leaving_Proposal | Created | Moving on from Proposal requires Invoice Terms. |
| 6 | Layout | Opportunity | Opportunity-Opportunity Layout | Opportunity Layout | Updated | Date Demo Scheduled added below Date Demo Booked. |
| 7 | Layout | Opportunity | Opportunity-Beacon Subscription Renewal Opportunity Layout | Beacon Subscription Renewal Opportunity Layout | Updated | Date Demo Scheduled added below Date Demo Booked. |
| 8 | PermissionSet | — | Beacon_Consulting | Beacon Consulting | Updated | Read and edit access to Date Demo Scheduled (same as Date Demo Booked). |
| 9 | PermissionSet | — | Beacon_Consulting_Object_Tab_FLS | Beacon Consulting - Object, Tab, FLS | Updated | Read and edit access to Date Demo Scheduled (same as Date Demo Booked). |
| 10 | PermissionSet | — | Beacon_Customer_Success | Beacon Customer Success | Updated | Read access to Date Demo Scheduled (same as Date Demo Booked). |
| 11 | PermissionSet | — | Beacon_Customer_Success_Object_Tab_FLS | Beacon Customer Success - Object, Tab, FLS | Updated | Read access to Date Demo Scheduled (same as Date Demo Booked). |
| 12 | PermissionSet | — | Beacon_Executive | Beacon Executive | Updated | Read access to Date Demo Scheduled (same as Date Demo Booked). |
| 13 | PermissionSet | — | Beacon_Executive_Object_Tab_FLS | Beacon Executive - Object, Tab, FLS | Updated | Read access to Date Demo Scheduled (same as Date Demo Booked). |
| 14 | PermissionSet | — | Beacon_Finance_Object_Tab_FLS | Beacon Finance - Object, Tab, FLS | Updated | Read and edit access to Date Demo Scheduled (same as Date Demo Booked). |
| 15 | PermissionSet | — | Beacon_Marketing | Beacon Marketing | Updated | Read and edit access to Date Demo Scheduled (same as Date Demo Booked). |
| 16 | PermissionSet | — | Beacon_Marketing_Object_Tab_FLS | Beacon Marketing - Object, Tab, FLS | Updated | Read and edit access to Date Demo Scheduled (same as Date Demo Booked). |
| 17 | PermissionSet | — | Beacon_Product | Beacon Product | Updated | Read access to Date Demo Scheduled (same as Date Demo Booked). |
| 18 | PermissionSet | — | Beacon_Product_Object_Tab_FLS | Beacon Product - Object, Tab, FLS | Updated | Read access to Date Demo Scheduled (same as Date Demo Booked). |
| 19 | PermissionSet | — | Beacon_ResOps | Beacon ResOps | Updated | Read access to Date Demo Scheduled (same as Date Demo Booked). |
| 20 | PermissionSet | — | Beacon_ResOps_Object_Tab_FLS | Beacon ResOps - Object, Tab, FLS | Updated | Read access to Date Demo Scheduled (same as Date Demo Booked). |
| 21 | PermissionSet | — | Beacon_Sales | Beacon Sales | Updated | Read and edit access to Date Demo Scheduled (same as Date Demo Booked). |
| 22 | PermissionSet | — | Beacon_Sales_Object_Tab_FLS | Beacon Sales - Object, Tab, FLS | Updated | Read and edit access to Date Demo Scheduled (same as Date Demo Booked). |
| 23 | PermissionSet | — | Beacon_Salesforce_Admin | Beacon Salesforce Admin | Updated | Read and edit access to Date Demo Scheduled (same as Date Demo Booked). |
| 24 | PermissionSet | — | Beacon_Salesforce_Admin_Object_Tab_FLS | Beacon Salesforce Admin - Object, Tab, FLS | Updated | Read and edit access to Date Demo Scheduled (same as Date Demo Booked). |
| 25 | PermissionSet | — | Beacon_Tech | Beacon Tech | Updated | Read access to Date Demo Scheduled (same as Date Demo Booked). |
| 26 | PermissionSet | — | Beacon_Tech_Object_Tab_FLS | Beacon Tech - Object, Tab, FLS | Updated | Read access to Date Demo Scheduled (same as Date Demo Booked). |
