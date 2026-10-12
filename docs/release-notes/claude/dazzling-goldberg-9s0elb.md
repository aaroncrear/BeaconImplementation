# "claude/dazzling-goldberg-9s0elb" – Release Notes

## Requirements

The Production validation deployment failed with four component errors. The deployment must validate cleanly:

1. `sfdcInternalInt__sfdc_tua_dqa_service` (Permission Set): "Cannot create a new component with the namespace: sfdcInternalInt."
2. `Beacon_Parent_Campaign_Record_Page` (FlexiPage): "We couldn't validate Quick Action Campaign.Sub_Campaign."
3. `Beacon Standard User` (Profile): "You can't edit tab settings for VideoCallParticipant, as it's not a valid tab."
4. `Campaign.Sub_Campaign` (Quick Action): "You can't change this field because Campaign has a master-detail relationship with Campaign."

## Release Notes

- **Campaign.Sub_Campaign quick action.** The action sets the parent through `targetParentField` = `Parent`, so Salesforce fills in `ParentId` from the record the action runs on. Salesforce rejects an action layout that also lets the user edit that same parent field. `ParentId` was removed from the action layout. The parent is still set automatically.
- **Beacon_Parent_Campaign_Record_Page.** No change. The page failed only because it references the `Campaign.Sub_Campaign` action, which failed. It validates once the action deploys.
- **VideoCallParticipant tab.** The `standard-VideoCallParticipant` tab exists in the source org but not in Production. It was removed from the tab settings of every profile in the repo, so these profiles won't hit the same error. The `Beacon Standard User` profile is not stored in this repo. Exclude that tab setting in the deployment tool (see Post Deployment Items).
- **sfdcInternalInt namespaced permission sets.** These are Salesforce-managed, internal permission sets. No org can create them through the Metadata API. Leave them out of any deployment.

## Acceptance Criteria

1. Run a validation deployment to Production that includes `Campaign.Sub_Campaign`, `Beacon_Parent_Campaign_Record_Page`, and `Beacon Standard User`, and leaves out `sfdcInternalInt__sfdc_tua_dqa_service`. Confirm that all components validate.
2. After deployment, open a Parent Campaign record in Production. Confirm that the **Sub Campaign** button appears in the highlights panel.
3. Click **Sub Campaign**. Confirm that the Parent Campaign field is not shown on the form. Fill in the Name and click Save.
4. Open the new campaign. Confirm that its record type is Sub Campaign and its Parent Campaign is the record from step 2.
5. Log in as (or view as) a Beacon Standard User. Confirm that the user's tabs and apps look as expected.

## Post Deployment Items

- In Gearset (or your deployment tool), **deselect `sfdcInternalInt__sfdc_tua_dqa_service`** and any other `sfdcInternalInt__*` permission sets. They are managed by Salesforce and can't be deployed.
- For the **Beacon Standard User** profile, exclude the `standard-VideoCallParticipant` tab visibility from the comparison, or remove that tab setting in the source org's profile before deploying.

## Component Manifest

Github Branch: [claude/dazzling-goldberg-9s0elb](https://github.com/aaroncrear/BeaconImplementation/tree/claude/dazzling-goldberg-9s0elb)

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Quick Action | Campaign | Campaign.Sub_Campaign | Sub Campaign | Updated | Removed ParentId from the action layout. The parent is still set through targetParentField. |
| 2 | Profile | N/A | Admin | System Administrator | Updated | Removed the standard-VideoCallParticipant tab setting. |
| 3 | Profile | N/A | CPQ Integration User | CPQ Integration User | Updated | Removed the standard-VideoCallParticipant tab setting. |
| 4 | Profile | N/A | ContractManager | Contract Manager | Updated | Removed the standard-VideoCallParticipant tab setting. |
| 5 | Profile | N/A | Identity User | Identity User | Updated | Removed the standard-VideoCallParticipant tab setting. |
| 6 | Profile | N/A | MarketingProfile | Marketing User | Updated | Removed the standard-VideoCallParticipant tab setting. |
| 7 | Profile | N/A | Minimum Access - API Only Integrations | Minimum Access - API Only Integrations | Updated | Removed the standard-VideoCallParticipant tab setting. |
| 8 | Profile | N/A | Minimum Access - Salesforce | Minimum Access - Salesforce | Updated | Removed the standard-VideoCallParticipant tab setting. |
| 9 | Profile | N/A | SolutionManager | Solution Manager | Updated | Removed the standard-VideoCallParticipant tab setting. |
| 10 | Profile | N/A | Standard | Standard User | Updated | Removed the standard-VideoCallParticipant tab setting. |
