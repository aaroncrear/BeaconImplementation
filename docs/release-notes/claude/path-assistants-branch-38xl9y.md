# "claude/path-assistants-branch-38xl9y" – Release Notes

## Requirements

- Give Sales, Customer Success, and Consulting users guided, in-context instructions as they move Contact, Lead, and Opportunity records through their respective status/stage picklists.
- Build out the Contact Status path (Active Opp, New, Nurturing, Working) so reps know what to check and what fields to complete at each stage, mirroring the guidance already defined on the Lead Status path.
- Provide stage-specific Opportunity paths for the Consulting, Subscription New, and Subscription Renewal record types so each sales motion sees requirements relevant to how that type of deal actually closes (e.g. DocuSign/payment details before Contract, Revenue Cloud proposal details before Proposal, Loss Reason before Closed Lost).
- Add a Default Opportunity path (master record type) covering the standard Needs Analysis → Proposal → Closed Won/Lost stages for record types that don't have a dedicated path, and require key fields (Amount, Close Date, Discovery Completed, ROI Analysis Completed, Loss Reason) at the appropriate stages.

## Release Notes

- Populated the previously empty `Contact_Status` Path Assistant (Contact, `Contact_Status__c`, Master record type) with guidance for all four picklist values: **Active Opp** (check with the Opportunity Owner before engaging), **New** (check Lead conversion source, set to Working to engage), **Nurturing** (marketing-driven, Lead Score threshold notifies the owner), and **Working** (booking a demo auto-creates an Opportunity and flips status to Active Opp; inactivity reverts to Nurturing). This mirrors the equivalent guidance already live on the Lead Status path so Contact and Lead follow the same qualification story post-conversion.
- Added `Default_Opportunity` (Opportunity, `StageName`, Master record type, inactive) as a baseline path for record types without a dedicated Opportunity path. It requires `Discovery_Completed__c` at Needs Analysis, `ROI_Analysis_Completed__c` at Proposal, `Amount`/`CloseDate` from Needs Analysis onward, and `Loss_Reason__c` at Closed Lost. It is deployed inactive by design since every current Opportunity record type (Consulting, Subscription New, Subscription Renewal) already has its own dedicated, active path below — it exists only as a fallback for future record types.
- Added three record-type-specific Opportunity paths, each active and scoped via `recordTypeName` so users only see the guidance relevant to their deal type:
  - **Opportunity_Stage_Consulting** (`Consulting` record type): Contract stage requires the contract to be sent via DocuSign and payment details completed; Closed Won requires the contract to be completed by the customer; Closed Lost requires a Loss Reason.
  - **Opportunity_Stage_Subscription_New** (`Subscription_New` record type): same Contract/Closed Won/Closed Lost guidance as Consulting, plus a Proposal step requiring Revenue Cloud details (user counts, products, pricing) to be completed.
  - **Opportunity_Stage_Subscription_Renewal** (`Subscription_Renewal` record type): identical stage guidance to Subscription New, scoped to renewal opportunities.
- These three record-type paths intentionally do not use `fieldNames` field requirements (unlike `Default_Opportunity`) — the guidance text calls out the fields/actions to complete (DocuSign, payment, Revenue Cloud proposal details, Loss Reason) without hard-gating stage progression, since those steps span systems (DocuSign, Revenue Cloud) that aren't always reflected back onto the Opportunity record itself.

## Acceptance Criteria

1. **Contact Status path**
   - Navigate to a Contact record and open the Path component above the record detail.
   - Confirm all four stages (Active Opp, New, Nurturing, Working) show guidance text instead of being blank.
   - Confirm the New and Nurturing steps display the LeadSource field as a suggested field to complete.
2. **Default Opportunity path**
   - Confirm the `Default_Opportunity` Path Assistant is deployed but inactive (Setup → Path Settings), so it does not appear on any Opportunity record today.
   - Reviewing the metadata, confirm Needs Analysis requires Discovery Completed, Proposal requires ROI Analysis Completed, and Closed Lost requires Loss Reason.
3. **Consulting Opportunity path**
   - Create/open an Opportunity with the Consulting record type and confirm the Path shows: Closed Lost → Loss Reason must be populated; Closed Won → contract must be completed by customer; Contract → DocuSign sent and payment details completed.
4. **Subscription New Opportunity path**
   - Create/open an Opportunity with the Subscription New record type and confirm the Path shows the same Contract/Closed Won/Closed Lost guidance as Consulting, plus a Proposal step calling out Revenue Cloud details (users, products, pricing).
5. **Subscription Renewal Opportunity path**
   - Create/open an Opportunity with the Subscription Renewal record type and confirm the Path shows the same four stages/guidance as Subscription New.
6. Confirm no other existing Path Assistants (e.g. Lead Status, base `Default` Opportunity path if pre-existing) were altered by this deployment.

## Post Deployment Items

None.

## Component Manifest

Github Branch: https://github.com/aaroncrear/BeaconImplementation/tree/claude/path-assistants-branch-38xl9y

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Path Assistant | Contact | Contact_Status | Contact Status | Updated | Added guidance steps for all four Contact Status values (Active Opp, New, Nurturing, Working); path was previously deployed with no steps. |
| 2 | Path Assistant | Lead | Default | Default | Created | Guidance path for Lead Status (New, Nurturing, Qualified, Unqualified, Working) on the Master record type. |
| 3 | Path Assistant | Opportunity | Default_Opportunity | Default | Created | Baseline (inactive) path for the Master Opportunity record type covering Needs Analysis, Proposal, Closed Won, and Closed Lost with required fields. |
| 4 | Path Assistant | Opportunity | Opportunity_Stage_Consulting | Opportunity Stage - Consulting | Created | Active path scoped to the Consulting record type covering Contract, Closed Won, and Closed Lost. |
| 5 | Path Assistant | Opportunity | Opportunity_Stage_Subscription_New | Opportunity Stage - Subscription New | Created | Active path scoped to the Subscription New record type covering Proposal, Contract, Closed Won, and Closed Lost. |
| 6 | Path Assistant | Opportunity | Opportunity_Stage_Subscription_Renewal | Opportunity Stage - Subscription Renewal | Created | Active path scoped to the Subscription Renewal record type covering Proposal, Contract, Closed Won, and Closed Lost. |
