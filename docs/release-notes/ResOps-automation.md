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
8. Create a **Case - On Create - After Save** Flow that runs when a **ResOps Request** Case is created and **Run Flows** is checked on the On/Off Switch.
9. The Flow calls the **Email Subflow** in a step named **ResOps Case Created Notification**, passing `varObject` = Case, `varRecordID` = the triggering Case's Id, and `varTrigger` = ResOps Case Created.
10. In the Email Subflow's **ResOps Case Created** path, add a Send Email action:
    - **Subject** = ResOps Case {Case Number} - {Case Type}
    - **Body** = ResOps Case {Case Number} has been created. Please review. "Case {Case Number}" links to the Case, using the `formRecordLink` formula.
    - **Sender** = the **Beacon Salesforce Automations** org-wide email address.
    - **Recipients** = the **ResOps Manager**, **ResOps Primary** and **ResOps Secondary** of the Campaign (Parent Campaign record type) whose **Primary Module** matches the Primary Module of the Case's Opportunity.
11. Create a **Case - On Create - Before Save** Flow for **ResOps Request** Cases that sets the Case Owner to the **ResOps Primary** from the Campaign, using the same Campaign matching as Opportunity - On Update - After Save.

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
7. **Get Parent Campaign Record Type** (Get Records). Finds the active Campaign record type with developer name `Parent_Campaign`.
8. **Can Look Up Parent Campaign?** (Decision). Continues only if the Opportunity has a Primary Module and the Parent Campaign record type was found. Without this check, a blank value in the next lookup could match the wrong Campaign. If either is missing, the Flow ends and no Case is created.
9. **Get Parent Campaign** (Get Records). Filters on **Record Type = Parent Campaign** (by the Id found in step 7), so Sub Campaigns are never matched. It finds the **active** Campaign whose Primary Module equals the Opportunity's Primary Module and whose ResOps Primary isn't blank. Inactive Campaigns are ignored. Both Primary Module fields use the shared Primary Module global value set, so the values match exactly. If more than one Campaign matches, the oldest one (by Created Date) is used.
10. **Parent Campaign Found?** (Decision). If a Campaign is found, **Assign Case Owner** sets the Case Owner to its ResOps Primary. If not, the Flow ends and no Case is created.
11. **Create Contract Cleanup Case** (Create Records). Creates the Case. Status defaults to New from the ResOps Request support process.

**When no Owner can be found** (the Opportunity has no Primary Module, or no active Parent Campaign with that module has a ResOps Primary), **no Case is created**. A Contract Cleanup Case is only created when it can go straight to the right ResOps Primary. Keeping Parent Campaigns filled in is therefore required for this automation to work. See Post Deployment Items.

**Errors.** If the Create Records step fails, the Flow calls the existing **Fault Path Subflow** to send the error notification. For example, it fails if the ResOps Primary user is inactive.

**Works with Quote - On Update - After Save.** When a synced Quote is Accepted, that Flow moves the Opportunity to Contract. That update also triggers this Flow, so a Subscription New Opportunity moved to Contract by an accepted Quote also gets a Contract Cleanup Case.

### Case - On Create - After Save Flow

A new record-triggered Flow, **Case - On Create - After Save** (`Case_On_Create_After_Save`), emails the ResOps team when a ResOps Request Case is created.

**Entry conditions** (Formula Evaluates to True):

```
AND(
    {!$Setup.On_Off_Switch__c.Run_Flows__c},
    {!$Record.RecordType.DeveloperName} = "ResOps_Request"
)
```

It has a single step, **ResOps Case Created Notification**, which calls the **Email Subflow** with `varObject` = `Case`, `varRecordID` = the Case Id and `varTrigger` = `ResOps Case Created`. The Flow runs for every new ResOps Request Case, whether it's created from the **ResOps Request** action on an Opportunity or by **Opportunity - On Update - After Save**.

### Case - On Create - Before Save Flow

A new record-triggered Flow, **Case - On Create - Before Save** (`Case_On_Create_Before_Save`), sets the Owner of every new ResOps Request Case to the ResOps Primary of the matching Parent Campaign.

**Entry conditions** (Formula Evaluates to True):

```
AND(
    {!$Setup.On_Off_Switch__c.Run_Flows__c},
    {!$Record.RecordType.DeveloperName} = "ResOps_Request"
)
```

**Flow steps** (the same Campaign matching as steps 7–10 of Opportunity - On Update - After Save):

1. **Get Parent Campaign Record Type** (Get Records). Finds the active Campaign record type with developer name `Parent_Campaign`.
2. **Can Look Up Parent Campaign?** (Decision). Continues only if the Case's Opportunity has a Primary Module (`$Record.Opportunity__r.Primary_Module__c`) and the Parent Campaign record type was found.
3. **Get Parent Campaign** (Get Records). Finds the active Campaign on the Parent Campaign record type with the same Primary Module and a ResOps Primary. If more than one matches, the oldest one is used.
4. **Parent Campaign Found?** (Decision). If a Campaign is found, **Assign Case Owner** sets the Case Owner (`$Record.OwnerId`) to its ResOps Primary.

**Why Before Save:** the Owner is set on the Case as it's saved, so no extra update is needed. It also runs before Case - On Create - After Save, so the new Case already has its Owner when the ResOps Case Created email is sent.

**When no Owner can be found** (the Case has no Opportunity, its Opportunity has no Primary Module, or no active Parent Campaign with that module has a ResOps Primary), the Owner is left as it is. That's normally the user who created the Case.

**Applies to every ResOps Request Case.** This covers Cases from the **ResOps Request** action on an Opportunity and the Contract Cleanup Cases created by Opportunity - On Update - After Save. That Flow already sets the same Owner, so for those Cases this Flow sets the same value again.

Before Save Flows can't call subflows, so this Flow has no Fault Path Subflow. If a Get Records step fails, the Case save fails and the user sees the error.

### Email Subflow – ResOps Case Created path

The **Case** outcome on **Which Object?** now runs **Get Case** (Get Records), which gets the Case that triggered the Subflow. Every Case trigger can then use the Case's fields. **Which Case Trigger?** follows, and its **Case Placeholder** outcome was replaced by a **ResOps Case Created** outcome (`varTrigger` = `ResOps Case Created`). The ResOps Case Created path:

1. **Get Parent Campaign Record Type** (Get Records). Finds the Campaign record type with developer name `Parent_Campaign`.
2. **Can Look Up Campaign?** (Decision). Continues only if the Case was found, its Opportunity has a Primary Module (`Get_Case.Opportunity__r.Primary_Module__c`), and the Parent Campaign record type was found. Otherwise no email is sent.
3. **Get Campaign** (Get Records). Finds the active Campaign on the Parent Campaign record type whose Primary Module matches the Case's Opportunity's Primary Module, and that has a ResOps Primary. If more than one matches, the oldest one is used. This uses the same rules as Opportunity - On Update - After Save, so the email goes to the team that owns the Case.
4. **Campaign Found?** (Decision). If no Campaign is found, no email is sent.
5. **Add ResOps Recipient Emails** (Assignment). Adds the email addresses of the Campaign's ResOps Manager, ResOps Primary and ResOps Secondary to `collResOpsCaseRecipients`, read straight from the Campaign's user lookups (for example `Get_Campaign.ResOps_Manager__r.Email`). ResOps Primary is always filled in, because Get Campaign requires it, so the list always has at least one address. There's no separate check for a blank ResOps Manager or ResOps Secondary. See the Acceptance Criteria test for blank recipients.
6. **Send ResOps Case Created Email** (Send Email action). Subject: `ResOps Case {Case Number} - {Type}`. Body (rich text): `ResOps Case {Case Number} has been created. Please review.`, where **Case {Case Number}** links to the Case through `formRecordLink`. It's sent from the **Beacon Salesforce Automations** org-wide email address (`digital.salesforce@beaconintel.com`). The address is the same in HTCDEV and UAT.

**Errors.** If any step on the path fails, the Email Subflow calls the **Fault Path Subflow**. A failed email sends the error notification instead of rolling back the new Case.

**Email Subflow is now Active.** It was deployed as a Draft framework in the Email-Subflow branch. Its release notes said to activate it in the first branch that adds a real email path, and this is that branch. The other Objects' Placeholder outcomes are unchanged and send nothing.

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
8. **Sub Campaigns are ignored.** Create a **Sub Campaign** with a Primary Module (e.g. *Module B*) and a ResOps Primary, and make sure no Parent Campaign has *Module B* with a ResOps Primary. Move a Subscription New Opportunity with Primary Module *Module B* to Contract. Confirm no Case is created. The Sub Campaign isn't used to set an Owner.
9. **No Matching Campaign.** On a Subscription New Opportunity whose Primary Module isn't on any Parent Campaign with a ResOps Primary, or that has no Primary Module, move the Stage to Contract. Confirm no Case is created.
10. **Other record types are skipped.** Move a **Subscription Renewal** Opportunity and a **Consulting** Opportunity to Contract. Confirm no Case is created.
11. **Other stages are skipped.** Move a Subscription New Opportunity to a stage other than Contract. Confirm no Case is created.
12. **Accepted Quote.** On a Subscription New Opportunity at Proposal, set its synced Quote's Status to **Accepted**. Confirm the Opportunity moves to Contract and a Contract Cleanup Case is created.
13. **On/Off Switch:**
    1. Add a **User** level On/Off Switch record for your user with **Run Flows** unchecked.
    2. Move a Subscription New Opportunity to Contract. Confirm no Case is created.
    3. Delete the User level record afterwards.
14. **Flows are active.** In Setup → Flows, confirm **Case - On Create - Before Save**, **Case - On Create - After Save** and **Email Subflow** are **Active**.
15. **Email on a new ResOps Case:**
    1. On the Parent Campaign for *Module A*, fill in **ResOps Manager**, **ResOps Primary** and **ResOps Secondary** with three active users whose inboxes you can check.
    2. On an Opportunity with Primary Module *Module A*, click **ResOps Request** and create a Case.
    3. Confirm all three users receive an email from **Beacon Salesforce Automations** with the subject **ResOps Case {Case Number} - {Type}** and the body **ResOps Case {Case Number} has been created. Please review.**
    4. Click **Case {Case Number}** in the email and confirm it opens the new Case.
16. **Email from the Contract automation.** Move a Subscription New Opportunity with Primary Module *Module A* to Contract. Confirm the same three users get the email for the new Contract Cleanup Case.
17. **Blank recipients.** Clear **ResOps Manager** and **ResOps Secondary** on the Campaign and create another ResOps Request Case. Confirm the Case saves and the ResOps Primary still gets the email, with no Fault Path Subflow error email. If the email fails, report it: a check for blank fields needs to be added to the Email Subflow.
18. **No matching Campaign.** Create a ResOps Request Case from an Opportunity whose Primary Module isn't on any Parent Campaign with a ResOps Primary, or that has no Primary Module. Confirm the Case saves and no email is sent.
19. **Sub Campaigns are ignored.** Using the *Module B* Sub Campaign from step 8, create a ResOps Request Case on a *Module B* Opportunity. Confirm the Sub Campaign's users get no email.
20. **On/Off Switch.** With a **User** level On/Off Switch record for your user with **Run Flows** unchecked, create a ResOps Request Case. Confirm the Case is owned by you and no email is sent. Delete the record afterwards.

21. **Owner on a manually created ResOps Case.** On an Opportunity with Primary Module *Module A*, click **ResOps Request** and create a Case. Confirm the Case **Owner** is the *Module A* Parent Campaign's **ResOps Primary**, not you.
22. **Owner left alone when there's no match.** Create a ResOps Request Case from an Opportunity with no Primary Module, or whose Primary Module isn't on any active Parent Campaign with a ResOps Primary. Confirm the Case saves and is owned by you.
23. **Inactive Campaigns are ignored.** Uncheck **Active** on the *Module A* Parent Campaign. Create a ResOps Request Case on a *Module A* Opportunity. Confirm the Case is owned by you and no ResOps Case Created email is sent. Re-check **Active** afterwards.
24. **Other Case record types are skipped.** Create a Case on the master record type. Confirm its Owner is you.

## Post Deployment Items

1. Fill in **ResOps Primary** (and **ResOps Manager** and **ResOps Secondary**, if needed) on each active Parent Campaign. Without a ResOps Primary on an active Parent Campaign for a module, no Contract Cleanup Case is created for that module's Opportunities.
2. Make sure each Primary Module is on only one active Parent Campaign that has a ResOps Primary. Inactive Campaigns are ignored. If more than one active Campaign matches, the Flows use the oldest one.
3. Confirm the **Beacon Salesforce Automations** org-wide email address (`digital.salesforce@beaconintel.com`) exists and is verified in each target org. The email can't be sent from it otherwise. It's already set up in HTCDEV and UAT.
4. Confirm **Deliverability** (Setup → Deliverability) is set to **All email** in the org you're testing in. Sandboxes default to System email only, which blocks these emails.

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
| 13 | Flow | Opportunity | Opportunity_On_Update_After_Save | Opportunity - On Update - After Save | Created | Record-triggered After Save Flow. When a Subscription New Opportunity's Stage changes to Contract, creates a Contract Cleanup ResOps Request Case linked to the Opportunity's primary Contact Role Contact and owned by the ResOps Primary of the active Parent Campaign (Parent Campaign record type only) with the matching Primary Module. No Case is created when no such Campaign is found. Honors the On/Off Switch. |
| 14 | Flow | Case | Case_On_Create_After_Save | Case - On Create - After Save | Created | Record-triggered After Save Flow. When a ResOps Request Case is created, calls the Email Subflow (ResOps Case Created Notification) with varObject = Case, varRecordID = the Case Id and varTrigger = ResOps Case Created. Honors the On/Off Switch. |
| 15 | Flow | N/A | Email_Subflow | Email Subflow | Updated | The Case outcome now gets the triggering Case first. Replaced the Case Placeholder outcome with a ResOps Case Created path. It finds the Parent Campaign matching the Case's Opportunity Primary Module and emails its ResOps Manager, ResOps Primary and ResOps Secondary from the Beacon Salesforce Automations org-wide address, with a link to the Case. Added fault handling and activated the Flow. |
| 16 | Flow | Case | Case_On_Create_Before_Save | Case - On Create - Before Save | Created | Record-triggered Before Save Flow. When a ResOps Request Case is created, sets its Owner to the ResOps Primary of the active Parent Campaign matching its Opportunity's Primary Module, using the same matching as Opportunity - On Update - After Save. Honors the On/Off Switch. |
