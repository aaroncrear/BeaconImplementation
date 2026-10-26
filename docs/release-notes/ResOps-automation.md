# "ResOps-automation" – Release Notes

## Requirements

1. Create a new **ResOps Manager** field on Campaign.
2. Give ResOps Manager the same access as **ResOps Primary** in every persona "Object, Tab, FLS" permission set.
3. Put ResOps Manager only on the **Beacon Parent Campaign Record Page**, directly above ResOps Primary.
4. Create an **Opportunity - On Update - After Save** Flow that runs only when:
   - the Opportunity is updated and its Stage is changed to **Contract**,
   - the Opportunity uses the **Subscription New** record type, and
   - **Run Flows** is checked on the On/Off Switch custom setting.
5. The Flow uses a Decision on the Opportunity's Stage, with an outcome for **Contract**.
6. On the Contract outcome, the Flow creates a Case on the **ResOps Request** record type. A Decision checks that the record type was found before the Case is created.
7. The Case is created with:
   - **Subject** = New Customer - Contract ResOps Cleanup
   - **Type** = Contract Cleanup
   - **Owner** = the **ResOps Primary** of the Campaign whose **Primary Module** matches the triggering Opportunity's Primary Module. Only Campaigns on the **Parent Campaign** record type are considered.
   - **Contact** = the Contact on the Opportunity's **primary Contact Role**.

## Release Notes

### ResOps Manager field

**ResOps Manager** (`Campaign.ResOps_Manager__c`) is a Lookup to User, built the same way as ResOps Primary and ResOps Secondary. If the user is deleted, the field is cleared (Set Null).

**Access.** The field was added to all ten persona "Object, Tab, FLS" permission sets with the same access each set gives ResOps Primary:

- **Read/Edit:** Beacon Marketing and Beacon Salesforce Admin.
- **Read only:** Consulting, Customer Success, Executive, Finance, Product, ResOps, Sales and Tech.

**Page placement.** The field was added to the **Beacon Parent Campaign Record Page** in the same section as ResOps Primary, directly above it, between Product Secondary and ResOps Primary. It isn't on any other page or page layout.

### Opportunity - On Update - After Save Flow

A new record-triggered Flow, **Opportunity - On Update - After Save** (`Opportunity_On_Update_After_Save`), creates a Contract Cleanup ResOps Request Case when a new-customer Opportunity reaches Contract.

**Entry conditions** (Formula Evaluates to True):

```
AND(
    {!$Setup.On_Off_Switch__c.Run_Flows__c},
    {!$Record.RecordType.DeveloperName} = "Subscription_New",
    ISCHANGED({!$Record.StageName}),
    ISPICKVAL({!$Record.StageName}, "Contract")
)
```

- **`ISCHANGED`** makes the Flow run only when the Stage changes to Contract. Saving an Opportunity that's already at Contract doesn't create another Case.
- The record type is matched by developer name, the same way as in Opportunity - On Create - After Save, so no Id is hardcoded.
- The Flow honors the **On/Off Switch**, like the other Beacon Flows.

**Flow steps:**

1. **Opportunity Stage** (Decision). Has a **Contract** outcome. Its default outcome, **Other Stage**, ends the Flow. Stage outcomes for future automation can be added here. The entry conditions would also need to allow those stages.
2. **Get ResOps Request Record Type** (Get Records). Finds the Case record type with developer name `ResOps_Request`.
3. **ResOps Request Record Type Found?** (Decision). If the record type isn't found, the Flow ends without creating a Case.
4. **Assign Contract Cleanup Case** (Assignment). Sets the record type, Subject (`New Customer - Contract ResOps Cleanup`) and Type (`Contract Cleanup`). It also sets the Case's **Opportunity** to the triggering Opportunity and **Account** to its Account. These two weren't in the request, but they link the Case to the deal. They make the Case appear in the Opportunity's Cases related list, and they let the Case's Primary Module formula work.
5. **Get Primary Contact Role** (Get Records). Finds the Opportunity Contact Role on the triggering Opportunity where **Primary** is checked.
6. **Primary Contact Role Found?** (Decision). If one is found, **Assign Case Contact** sets the Case **Contact** to that Contact Role's Contact. If the Opportunity has no primary Contact Role, the Case is created without a Contact.
7. **Get Parent Campaign Record Type** (Get Records). Finds the Campaign record type with developer name `Parent_Campaign`.
8. **Can Look Up Parent Campaign?** (Decision). Continues only if the Opportunity has a Primary Module and the Parent Campaign record type was found. Without this check, a blank value in the next lookup could match the wrong Campaign. If the Parent Campaign record type isn't found, no Campaign is used at all.
9. **Get Parent Campaign** (Get Records). Filters on **Record Type = Parent Campaign** (by the Id found in step 7), so Sub Campaigns are never matched. It finds the Campaign whose Primary Module equals the Opportunity's Primary Module and whose ResOps Primary isn't blank. Both Primary Module fields use the shared Primary Module global value set, so the values match exactly. If more than one Campaign matches, the oldest one (by Created Date) is used.
10. **Parent Campaign Found?** (Decision). If a Campaign is found, **Assign Case Owner** sets the Case Owner to its ResOps Primary.
11. **Create Contract Cleanup Case** (Create Records). Creates the Case. Status defaults to New from the ResOps Request support process.

**When no Owner can be found** (the Opportunity has no Primary Module, or no Parent Campaign with that module has a ResOps Primary), the Case is still created. It's owned by the user who moved the Opportunity to Contract. This way the request isn't lost, and the Case can be reassigned.

**Errors.** If any Get Records or the Create Records step fails, the Flow calls the existing **Fault Path Subflow** to send the error notification. For example, it fails if the ResOps Primary user is inactive.

**Works with Quote - On Update - After Save.** When a synced Quote is Accepted, that Flow moves the Opportunity to Contract. That update also triggers this Flow, so a Subscription New Opportunity moved to Contract by an accepted Quote also gets a Contract Cleanup Case.

## Acceptance Criteria

**Setup data:** make sure the test Opportunity has a **primary Contact Role**. Make sure an active **Parent Campaign** has a **Primary Module** (e.g. *Module A*) and a **ResOps Primary** user. Pick a ResOps Primary user who isn't you, so you can see the Owner was set.

1. **ResOps Manager field.** In Setup → Object Manager → Campaign → Fields & Relationships, confirm **ResOps Manager** exists as a Lookup(User) with a description.
2. **Field access.** Open each persona "Object, Tab, FLS" permission set → Object Settings → Campaigns. Confirm ResOps Manager has the same access as ResOps Primary: Read/Edit in Beacon Marketing and Beacon Salesforce Admin, and Read only in the other eight.
3. **Page placement.** Open a Parent Campaign. Confirm **ResOps Manager** shows directly above **ResOps Primary**. Open a Sub Campaign and confirm ResOps Manager doesn't appear.
4. **Flow is active.** In Setup → Flows, confirm **Opportunity - On Update - After Save** is **Active**.
5. **Case created on Contract:**
   1. Open a **Subscription New** Opportunity at a stage before Contract, with Primary Module = *Module A*.
   2. Change the Stage to **Contract** and save.
   3. In the Opportunity's **Cases** related list, open the new Case.
   4. Confirm: Record Type = **ResOps Request**, Subject = **New Customer - Contract ResOps Cleanup**, Type = **Contract Cleanup**, Status = **New**, Opportunity and Account are filled in, **Contact** = the Contact on the Opportunity's primary Contact Role, and **Owner** = the Parent Campaign's ResOps Primary.
6. **No duplicate on a re-save.** Edit another field on the same Opportunity (still at Contract) and save. Confirm no second Case is created.
7. **No primary Contact Role.** On a Subscription New Opportunity with no primary Contact Role (no Contact Roles, or none marked Primary), move the Stage to Contract. Confirm the Case is created with Contact blank.
8. **Sub Campaigns are ignored.** Create a **Sub Campaign** with a Primary Module (e.g. *Module B*) and a ResOps Primary, and make sure no Parent Campaign has *Module B* with a ResOps Primary. Move a Subscription New Opportunity with Primary Module *Module B* to Contract. Confirm the Case is owned by you, not the Sub Campaign's ResOps Primary.
9. **No Matching Campaign.** On a Subscription New Opportunity whose Primary Module isn't on any Parent Campaign with a ResOps Primary, or that has no Primary Module, move the Stage to Contract. Confirm the Case is created and owned by you.
10. **Other record types are skipped.** Move a **Subscription Renewal** Opportunity and a **Consulting** Opportunity to Contract. Confirm no Case is created.
11. **Other stages are skipped.** Move a Subscription New Opportunity to a stage other than Contract. Confirm no Case is created.
12. **Accepted Quote.** On a Subscription New Opportunity at Proposal, set its synced Quote's Status to **Accepted**. Confirm the Opportunity moves to Contract and a Contract Cleanup Case is created.
13. **On/Off Switch:**
    1. Add a **User** level On/Off Switch record for your user with **Run Flows** unchecked.
    2. Move a Subscription New Opportunity to Contract. Confirm no Case is created.
    3. Delete the User level record afterwards.

## Post Deployment Items

1. Fill in **ResOps Primary** (and **ResOps Manager**, if needed) on each active Parent Campaign so Contract Cleanup Cases get the right Owner.
2. Make sure each Primary Module is on only one active Parent Campaign that has a ResOps Primary. If more than one matches, the Flow uses the oldest Campaign.

## Component Manifest

Github Branch: https://github.com/aaroncrear/BeaconImplementation/tree/ResOps-automation

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Custom Field | Campaign | ResOps_Manager__c | ResOps Manager | Created | Lookup to User for the Campaign's ResOps Manager. Set Null on delete. |
| 2 | Flexipage | Campaign | Beacon_Parent_Campaign_Record_Page | Beacon Parent Campaign Record Page | Updated | Added ResOps Manager directly above ResOps Primary. |
| 3 | Permission Set | N/A | Beacon_Consulting_Object_Tab_FLS | Beacon Consulting - Object, Tab, FLS | Updated | Read on Campaign.ResOps_Manager__c, matching ResOps Primary. |
| 4 | Permission Set | N/A | Beacon_Customer_Success_Object_Tab_FLS | Beacon Customer Success - Object, Tab, FLS | Updated | Read on Campaign.ResOps_Manager__c, matching ResOps Primary. |
| 5 | Permission Set | N/A | Beacon_Executive_Object_Tab_FLS | Beacon Executive - Object, Tab, FLS | Updated | Read on Campaign.ResOps_Manager__c, matching ResOps Primary. |
| 6 | Permission Set | N/A | Beacon_Finance_Object_Tab_FLS | Beacon Finance - Object, Tab, FLS | Updated | Read on Campaign.ResOps_Manager__c, matching ResOps Primary. |
| 7 | Permission Set | N/A | Beacon_Marketing_Object_Tab_FLS | Beacon Marketing - Object, Tab, FLS | Updated | Read/Edit on Campaign.ResOps_Manager__c, matching ResOps Primary. |
| 8 | Permission Set | N/A | Beacon_Product_Object_Tab_FLS | Beacon Product - Object, Tab, FLS | Updated | Read on Campaign.ResOps_Manager__c, matching ResOps Primary. |
| 9 | Permission Set | N/A | Beacon_ResOps_Object_Tab_FLS | Beacon ResOps - Object, Tab, FLS | Updated | Read on Campaign.ResOps_Manager__c, matching ResOps Primary. |
| 10 | Permission Set | N/A | Beacon_Sales_Object_Tab_FLS | Beacon Sales - Object, Tab, FLS | Updated | Read on Campaign.ResOps_Manager__c, matching ResOps Primary. |
| 11 | Permission Set | N/A | Beacon_Salesforce_Admin_Object_Tab_FLS | Beacon Salesforce Admin - Object, Tab, FLS | Updated | Read/Edit on Campaign.ResOps_Manager__c, matching ResOps Primary. |
| 12 | Permission Set | N/A | Beacon_Tech_Object_Tab_FLS | Beacon Tech - Object, Tab, FLS | Updated | Read on Campaign.ResOps_Manager__c, matching ResOps Primary. |
| 13 | Flow | Opportunity | Opportunity_On_Update_After_Save | Opportunity - On Update - After Save | Created | Record-triggered After Save Flow. When a Subscription New Opportunity's Stage changes to Contract, creates a Contract Cleanup ResOps Request Case linked to the Opportunity's primary Contact Role Contact and owned by the ResOps Primary of the Parent Campaign (Parent Campaign record type only) with the matching Primary Module. Honors the On/Off Switch. |
