# "ResOps-Request" – Release Notes

## Requirements

The ResOps team needs a way for users to raise requests against an Opportunity and track them through to completion. The business asked for:

1. A new **ResOps Request** record type on Case that uses a new **ResOps Request** support process.
2. A new **Opportunity** lookup field on Case.
3. A **ResOps Request** action on Opportunity that defaults the Case's Opportunity to the record it's launched from and the Account to that Opportunity's Account.
4. The action added to the **Beacon Subscription Renewal Opportunity Layout** and the **Opportunity Layout**.
5. **Beacon - Baseline - Standard Field Access** updated to give Read, Create and Edit on Case, plus Read and Edit on the standard Case fields, set field by field (no View All Fields).
6. Case **Status** values **In Progress**, **Cancelled** and **Completed** added, with Cancelled and Completed as closed statuses, and the picklist ordered New, On Hold, Escalated, Closed, Cancelled, Completed.
7. A new **ResOps Request** support process with New, In Progress, Cancelled and Completed.
8. Case **Type** values **Company Pipeline QC**, **Targeted QC-Provide Further Information**, **Use Case - Provide Further Information** and **Contract Cleanup** added, and made the only Type values available on the ResOps Request record type.
9. A new **Due Date Required** date field on Case, readable by every persona "Object, Tab, FLS" permission set.
10. A new **ResOps Request Case Layout**: two columns with Owner, Status and Type on the left and Account, Opportunity, Date/Time Opened, Date/Time Closed and Due Date Required on the right, and Subject and Description in a one-column section below.

## Release Notes

**Case Status values.** The `CaseStatus` standard value set now holds New, In Progress, On Hold, Escalated, Closed, Cancelled and Completed. Closed, Cancelled and Completed are closed statuses, and New stays the default. The requirement listed the order without In Progress, so it sits directly after New to follow the natural workflow (New → In Progress → done).

**ResOps Request support process.** The new `ResOps Request` business process offers only New (default), In Progress, Cancelled and Completed. It gives ResOps cases two closed outcomes (Cancelled, Completed) without the generic Closed status.

**Case Type values.** Company Pipeline QC, Targeted QC-Provide Further Information, Use Case - Provide Further Information and Contract Cleanup were added to the `CaseType` standard value set. The existing values (Problem, Feature Request, Question) are unchanged. The new values are also available on the master record type because standard value sets are shared.

**ResOps Request record type.** `Case.ResOps_Request` uses the ResOps Request support process and restricts Type to the four new values only. It's the first Case record type in the org, so existing Cases remain on the master record type.

**New Case fields.** **Opportunity** (`Opportunity__c`) is a lookup to Opportunity. It clears itself if the Opportunity is deleted (Set Null) and shows as a "Cases" related list option on Opportunity. **Due Date Required** (`Due_Date_Required__c`) is a Date field.

**ResOps Request quick action.** `Opportunity.ResOps_Request` is a Create action that builds a Case on the ResOps Request record type. Its `targetParentField` is `Opportunity__c`, so the Opportunity is filled in automatically with the record the action is launched from. A predefined value (`Opportunity.AccountId`) defaults the Case Account to the Opportunity's Account. The action form shows Type (required), Subject and Description on the left and Opportunity, Account and Due Date Required on the right.

**Opportunity layouts.** The action was added to the Lightning action bar and the Quick Actions list on both the **Opportunity Layout** and the **Beacon Subscription Renewal Opportunity Layout**. `Beacon_Opportunity_Record_Page` uses the standard highlights panel without dynamic actions, so the layout's action list drives the buttons users see.

**ResOps Request Case Layout.** The new layout has a two-column **Case Information** section with Owner, Status and Type (Status and Type required) on the left, and Account, Opportunity, Date/Time Opened (`CreatedDate`, read only), Date/Time Closed (`ClosedDate`, read only) and Due Date Required on the right. A one-column **Request Details** section below holds Subject and Description. The related lists and actions are carried over from the standard Case Layout, minus Solutions. Every profile that already assigns the Beacon Opportunity layouts now assigns this layout to the ResOps Request record type.

**Baseline standard field access.** `Beacon_Baseline_Standard_Field_Access` now grants Case Read, Create and Edit (no Delete, View All, Modify All or View All Fields). Field-level security is listed field by field for every standard Case field that accepts FLS in the org: Read/Edit on Account, Contact, Description, Escalated, Case Origin, Parent Case, Priority, Case Reason, Subject, and the four Web fields (Company, Email, Name, Phone). Closed Date gets Read only because it's a system-calculated field. It also makes the ResOps Request record type visible, so users who hold the baseline set can run the action and create ResOps Requests.

**Persona permission sets.** All nine persona "Object, Tab, FLS" permission sets got **Read** on Due Date Required, as requested. They also got **Read/Edit** on the new Opportunity field. That field is custom, so the standard-field baseline set can't cover it, and without edit access the action couldn't stamp the Opportunity onto the Case.

## Acceptance Criteria

1. **Case Status values.** In Setup → Object Manager → Case → Fields & Relationships → Status, confirm the values appear in this order: New, In Progress, On Hold, Escalated, Closed, Cancelled, Completed. Confirm Closed, Cancelled and Completed are marked as closed, and New is the default.
2. **Case Type values.** In Case → Type, confirm Company Pipeline QC, Targeted QC-Provide Further Information, Use Case - Provide Further Information and Contract Cleanup exist alongside Problem, Feature Request and Question.
3. **Support process.** In Setup → Support Processes, open **ResOps Request** and confirm it contains only New (default), In Progress, Cancelled and Completed.
4. **Record type.** In Case → Record Types, open **ResOps Request**. Confirm it's active, uses the ResOps Request support process, and Type shows only the four new values.
5. **Fields.** Confirm Case has **Opportunity** (Lookup to Opportunity) and **Due Date Required** (Date).
6. **Layout and assignment.** In Case → Page Layouts, open **ResOps Request Case Layout** and confirm the sections and field placement described in the Release Notes. In Page Layout Assignment, confirm the ResOps Request record type uses this layout for the profiles in the Component Manifest.
7. **Permissions.** Open **Beacon - Baseline - Standard Field Access**. Confirm Case has Read, Create and Edit (View All Fields unchecked), the standard Case fields listed above have Read/Edit (Closed Date Read only), and the ResOps Request record type is assigned. Open each persona "Object, Tab, FLS" permission set and confirm Due Date Required is Read and Opportunity is Read/Edit.
8. **Action on Opportunity Layout.** Log in as (or impersonate) a user with the Baseline and a persona permission set. Open an Opportunity using the **Opportunity Layout** (e.g. Subscription New) and confirm a **ResOps Request** button appears in the action bar.
9. **Action on Subscription Renewal layout.** Open a Subscription Renewal Opportunity and confirm the **ResOps Request** button appears.
10. **Create a ResOps Request.** Click **ResOps Request**. Confirm Opportunity is pre-filled with the current Opportunity and Account with its Account. Confirm Type offers only the four ResOps values. Fill in Type, Subject and Description, then save. Confirm the success message "ResOps Request Successfully Created" appears.
11. **Verify the Case.** Open the new Case. Confirm the record type is ResOps Request, Status is New, Opportunity and Account are populated, and the page uses the ResOps Request Case Layout. Confirm the Status picklist offers only New, In Progress, Cancelled and Completed.
12. **Close the Case.** Set Status to **Completed** and save. Confirm the Case is closed (Date/Time Closed is populated). Repeat on another Case with **Cancelled**.
13. **Regression.** Confirm existing Cases (master record type) still show the Case Layout and their existing Status values.

## Post Deployment Items

1. Make sure ResOps users and anyone who should raise requests are assigned **Beacon - Baseline - Standard Field Access** (Case access and record type visibility) and their persona "Object, Tab, FLS" permission set.
2. Optional: add the Cases (Opportunity) related list to the Opportunity layouts so requests can be seen from the Opportunity. This wasn't in scope for this build.

## Component Manifest

Github Branch: https://github.com/aaroncrear/BeaconImplementation/tree/ResOps-Request

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | RecordType | Case | ResOps_Request | ResOps Request | Created | New Case record type for ResOps requests; uses the ResOps Request support process and limits Type to the four ResOps values. |
| 2 | BusinessProcess (Support Process) | Case | ResOps Request | ResOps Request | Created | Support process with statuses New (default), In Progress, Cancelled and Completed. |
| 3 | CustomField | Case | Opportunity__c | Opportunity | Created | Lookup to Opportunity (Set Null on delete); child relationship "Cases". |
| 4 | CustomField | Case | Due_Date_Required__c | Due Date Required | Created | Date the requester needs the case completed by. |
| 5 | StandardValueSet | Case | CaseStatus | Case Status | Updated | Added In Progress, Cancelled (closed) and Completed (closed); reordered to New, In Progress, On Hold, Escalated, Closed, Cancelled, Completed. |
| 6 | StandardValueSet | Case | CaseType | Case Type | Updated | Added Company Pipeline QC, Targeted QC-Provide Further Information, Use Case - Provide Further Information and Contract Cleanup. |
| 7 | Layout | Case | Case-ResOps Request Case Layout | ResOps Request Case Layout | Created | Two-column Case Information section (Owner, Status, Type / Account, Opportunity, Date/Time Opened, Date/Time Closed, Due Date Required) and one-column Request Details section (Subject, Description). |
| 8 | QuickAction | Opportunity | Opportunity.ResOps_Request | ResOps Request | Created | Create action for a ResOps Request Case; Opportunity defaults to the source record and Account defaults to the Opportunity's Account. |
| 9 | Layout | Opportunity | Opportunity-Opportunity Layout | Opportunity Layout | Updated | Added the ResOps Request action to the Salesforce Mobile and Lightning Experience actions and to the Quick Actions list. |
| 10 | Layout | Opportunity | Opportunity-Beacon Subscription Renewal Opportunity Layout | Beacon Subscription Renewal Opportunity Layout | Updated | Added the ResOps Request action to the Salesforce Mobile and Lightning Experience actions and to the Quick Actions list. |
| 11 | PermissionSet | Case | Beacon_Baseline_Standard_Field_Access | Beacon - Baseline - Standard Field Access | Updated | Granted Case Read/Create/Edit, field-by-field Read/Edit on 14 standard Case fields (Read on Closed Date), and visibility of the ResOps Request record type. View All Fields not granted. |
| 12 | PermissionSet | Case | Beacon_Consulting_Object_Tab_FLS | Beacon Consulting - Object, Tab, FLS | Updated | Added Read on Due Date Required and Read/Edit on Opportunity. |
| 13 | PermissionSet | Case | Beacon_Customer_Success_Object_Tab_FLS | Beacon Customer Success - Object, Tab, FLS | Updated | Added Read on Due Date Required and Read/Edit on Opportunity. |
| 14 | PermissionSet | Case | Beacon_Executive_Object_Tab_FLS | Beacon Executive - Object, Tab, FLS | Updated | Added Read on Due Date Required and Read/Edit on Opportunity. |
| 15 | PermissionSet | Case | Beacon_Marketing_Object_Tab_FLS | Beacon Marketing - Object, Tab, FLS | Updated | Added Read on Due Date Required and Read/Edit on Opportunity. |
| 16 | PermissionSet | Case | Beacon_Product_Object_Tab_FLS | Beacon Product - Object, Tab, FLS | Updated | Added Read on Due Date Required and Read/Edit on Opportunity. |
| 17 | PermissionSet | Case | Beacon_ResOps_Object_Tab_FLS | Beacon ResOps - Object, Tab, FLS | Updated | Added Read on Due Date Required and Read/Edit on Opportunity. |
| 18 | PermissionSet | Case | Beacon_Sales_Object_Tab_FLS | Beacon Sales - Object, Tab, FLS | Updated | Added Read on Due Date Required and Read/Edit on Opportunity. |
| 19 | PermissionSet | Case | Beacon_Salesforce_Admin_Object_Tab_FLS | Beacon Salesforce Admin - Object, Tab, FLS | Updated | Added Read on Due Date Required and Read/Edit on Opportunity. |
| 20 | PermissionSet | Case | Beacon_Tech_Object_Tab_FLS | Beacon Tech - Object, Tab, FLS | Updated | Added Read on Due Date Required and Read/Edit on Opportunity. |
| 21 | Profile | Case | Admin | Admin | Updated | Assigned the ResOps Request Case Layout to the ResOps Request record type. |
| 22 | Profile | Case | Analytics Cloud Integration User | Analytics Cloud Integration User | Updated | Assigned the ResOps Request Case Layout to the ResOps Request record type. |
| 23 | Profile | Case | Analytics Cloud Security User | Analytics Cloud Security User | Updated | Assigned the ResOps Request Case Layout to the ResOps Request record type. |
| 24 | Profile | Case | CPQ Integration User | CPQ Integration User | Updated | Assigned the ResOps Request Case Layout to the ResOps Request record type. |
| 25 | Profile | Case | Chatter External User | Chatter External User | Updated | Assigned the ResOps Request Case Layout to the ResOps Request record type. |
| 26 | Profile | Case | Chatter Free User | Chatter Free User | Updated | Assigned the ResOps Request Case Layout to the ResOps Request record type. |
| 27 | Profile | Case | Chatter Moderator User | Chatter Moderator User | Updated | Assigned the ResOps Request Case Layout to the ResOps Request record type. |
| 28 | Profile | Case | ContractManager | ContractManager | Updated | Assigned the ResOps Request Case Layout to the ResOps Request record type. |
| 29 | Profile | Case | Einstein Agent User | Einstein Agent User | Updated | Assigned the ResOps Request Case Layout to the ResOps Request record type. |
| 30 | Profile | Case | End User | End User | Updated | Assigned the ResOps Request Case Layout to the ResOps Request record type. |
| 31 | Profile | Case | Executive Sponsor | Executive Sponsor | Updated | Assigned the ResOps Request Case Layout to the ResOps Request record type. |
| 32 | Profile | Case | External Apps Login User | External Apps Login User | Updated | Assigned the ResOps Request Case Layout to the ResOps Request record type. |
| 33 | Profile | Case | External Einstein Agent User | External Einstein Agent User | Updated | Assigned the ResOps Request Case Layout to the ResOps Request record type. |
| 34 | Profile | Case | Identity User | Identity User | Updated | Assigned the ResOps Request Case Layout to the ResOps Request record type. |
| 35 | Profile | Case | MarketingProfile | MarketingProfile | Updated | Assigned the ResOps Request Case Layout to the ResOps Request record type. |
| 36 | Profile | Case | Minimum Access - API Only Integrations | Minimum Access - API Only Integrations | Updated | Assigned the ResOps Request Case Layout to the ResOps Request record type. |
| 37 | Profile | Case | Minimum Access - Salesforce | Minimum Access - Salesforce | Updated | Assigned the ResOps Request Case Layout to the ResOps Request record type. |
| 38 | Profile | Case | Read Only | Read Only | Updated | Assigned the ResOps Request Case Layout to the ResOps Request record type. |
| 39 | Profile | Case | Sales Insights Integration User | Sales Insights Integration User | Updated | Assigned the ResOps Request Case Layout to the ResOps Request record type. |
| 40 | Profile | Case | Salesforce API Only System Integrations | Salesforce API Only System Integrations | Updated | Assigned the ResOps Request Case Layout to the ResOps Request record type. |
| 41 | Profile | Case | SalesforceIQ Integration User | SalesforceIQ Integration User | Updated | Assigned the ResOps Request Case Layout to the ResOps Request record type. |
| 42 | Profile | Case | SolutionManager | SolutionManager | Updated | Assigned the ResOps Request Case Layout to the ResOps Request record type. |
| 43 | Profile | Case | Standard | Standard | Updated | Assigned the ResOps Request Case Layout to the ResOps Request record type. |
