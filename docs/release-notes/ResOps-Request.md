# "ResOps-Request" – Release Notes

## Requirements

The ResOps team needs a way for users to raise requests against an Opportunity and track them through to completion. The business asked for:

1. A new **ResOps Request** record type on Case that uses a new **ResOps Request** support process.
2. A new **Opportunity** lookup field on Case.
3. A **ResOps Request** action on Opportunity that defaults the Case's Opportunity to the record it's launched from and the Account to that Opportunity's Account.
4. The action added to the **Beacon Subscription Renewal Opportunity Layout** and the **Opportunity Layout**.
5. **Beacon - Baseline - Standard Field Access** updated to give Read, Create and Edit on Case, plus Read and Edit on the standard Case fields, set field by field (no View All Fields).
6. Case **Status** values **In Progress**, **Cancelled** and **Completed** added, with Cancelled and Completed as closed statuses, and the picklist ordered New, In Progress, On Hold, Escalated, Closed, Cancelled, Completed.
7. A new **ResOps Request** support process with New, In Progress, Cancelled and Completed.
8. Case **Type** values **Company Pipeline QC**, **Targeted QC-Provide Further Information**, **Use Case - Provide Further Information** and **Contract Cleanup** added, and made the only Type values available on the ResOps Request record type.
9. A new **Due Date Required** date field on Case, readable and editable by every persona "Object, Tab, FLS" permission set.
10. A new **ResOps Request Case Layout**: two columns with Owner, Status and Type on the left and Account, Opportunity, Date/Time Opened, Date/Time Closed and Due Date Required on the right, and Subject and Description in a one-column section below. Contact was later added under Account, Priority under Type, and Case Origin under Priority. Assign it only to the **Beacon Standard User** and **System Administrator** profiles.
11. Access to the ResOps Request record type granted through the persona "Object, Tab, FLS" permission sets, not the Baseline permission set.
12. A **Cases** related list on both the Opportunity Layout and the Beacon Subscription Renewal Opportunity Layout.
13. A text formula field on Case showing the **Primary Module** of the related Opportunity. Place it under Opportunity on the ResOps Request Case Layout, and make it readable by the persona "Object, Tab, FLS" permission sets.
14. Descriptions filled in on every field and piece of metadata created for this branch.

## Release Notes

**Case Status values.** The `CaseStatus` standard value set now holds New, In Progress, On Hold, Escalated, Closed, Cancelled and Completed. Closed, Cancelled and Completed are closed statuses, and New stays the default. In Progress sits directly after New, as confirmed with the business, to follow the natural workflow (New → In Progress → done).

**ResOps Request support process.** The new `ResOps Request` business process offers only New (default), In Progress, Cancelled and Completed. It gives ResOps cases two closed outcomes (Cancelled, Completed) without the generic Closed status.

**Descriptions.** Every field, the support process, the record type, the quick action and each new Status and Type picklist value has a description. Page layouts and profiles have no description setting in Salesforce.

**Case Type values.** Company Pipeline QC, Targeted QC-Provide Further Information, Use Case - Provide Further Information and Contract Cleanup were added to the `CaseType` standard value set. The existing values (Problem, Feature Request, Question) are unchanged. The new values are also available on the master record type because standard value sets are shared.

**ResOps Request record type.** `Case.ResOps_Request` uses the ResOps Request support process and restricts Type to the four new values only. It's the first Case record type in the org, so existing Cases remain on the master record type.

**New Case fields.** **Opportunity** (`Opportunity__c`) is a lookup to Opportunity. It clears itself if the Opportunity is deleted (Set Null) and shows as a "Cases" related list option on Opportunity. **Due Date Required** (`Due_Date_Required__c`) is a Date field. **Primary Module** (`Opportunity_Primary_Module__c`) is a Text formula, `TEXT(Opportunity__r.Primary_Module__c)`, that shows the related Opportunity's Primary Module picklist value as text. It's blank when the case has no Opportunity or the Opportunity has no Primary Module.

**ResOps Request quick action.** `Opportunity.ResOps_Request` is a Create action that builds a Case on the ResOps Request record type. Its `targetParentField` is `Opportunity__c`, so the Opportunity is filled in automatically with the record the action is launched from. A predefined value (`Opportunity.AccountId`) defaults the Case Account to the Opportunity's Account. The action form shows Type (required), Subject and Description on the left and Opportunity, Account and Due Date Required on the right.

**Opportunity layouts.** The action was added to the Lightning action bar and the Quick Actions list on both the **Opportunity Layout** and the **Beacon Subscription Renewal Opportunity Layout**. Both layouts also got a **Cases** related list (driven by the new Opportunity lookup) showing Case Number, Subject, Type, Status, Due Date Required and Date/Time Opened, so requests raised from an Opportunity can be seen on it. `Beacon_Opportunity_Record_Page` uses the standard highlights panel without dynamic actions, so the layout's action list drives the buttons users see.

**ResOps Request Case Layout.** The new layout has a two-column **Case Information** section with Owner, Status, Type (Status and Type required), Priority and Case Origin on the left, and Account, Contact, Opportunity, Primary Module (read only), Date/Time Opened (`CreatedDate`, read only), Date/Time Closed (`ClosedDate`, read only) and Due Date Required on the right. A one-column **Request Details** section below holds Subject and Description. The related lists and actions are carried over from the standard Case Layout, minus Solutions. The layout is assigned to the ResOps Request record type only on the **System Administrator** (`Admin`) and **Beacon Standard User** profiles. Beacon Standard User is a custom profile that wasn't tracked in the repo before. Its new profile file contains only this layout assignment, so deploying it updates just that assignment and leaves the rest of the profile as it is in the org.

**Baseline standard field access.** `Beacon_Baseline_Standard_Field_Access` now grants Case Read, Create and Edit (no Delete, View All, Modify All or View All Fields). Field-level security is listed field by field for every standard Case field that accepts FLS in the org: Read/Edit on Account, Contact, Description, Escalated, Case Origin, Parent Case, Priority, Case Reason, Subject, and the four Web fields (Company, Email, Name, Phone). Closed Date gets Read only because it's a system-calculated field.

**Persona permission sets.** All nine persona "Object, Tab, FLS" permission sets got **Read/Edit** on Due Date Required, **Read** on Primary Module, and visibility of the **ResOps Request** record type. Users need both a persona set and the Baseline set to raise a request: the Baseline set grants Case access, and the persona set grants the record type. They also got **Read/Edit** on the new Opportunity field. That field is custom, so the standard-field baseline set can't cover it, and without edit access the action couldn't stamp the Opportunity onto the Case.

## Acceptance Criteria

1. **Case Status values.** In Setup → Object Manager → Case → Fields & Relationships → Status, confirm the values appear in this order: New, In Progress, On Hold, Escalated, Closed, Cancelled, Completed. Confirm Closed, Cancelled and Completed are marked as closed, and New is the default.
2. **Case Type values.** In Case → Type, confirm Company Pipeline QC, Targeted QC-Provide Further Information, Use Case - Provide Further Information and Contract Cleanup exist alongside Problem, Feature Request and Question.
3. **Support process.** In Setup → Support Processes, open **ResOps Request** and confirm it contains only New (default), In Progress, Cancelled and Completed.
4. **Record type.** In Case → Record Types, open **ResOps Request**. Confirm it's active, uses the ResOps Request support process, and Type shows only the four new values.
5. **Fields.** Confirm Case has **Opportunity** (Lookup to Opportunity), **Due Date Required** (Date) and **Primary Module** (Formula (Text)), and that each has a description. Confirm the new Status and Type values also have descriptions.
6. **Layout and assignment.** In Case → Page Layouts, open **ResOps Request Case Layout** and confirm the sections and field placement described in the Release Notes. In Page Layout Assignment, confirm the ResOps Request record type uses this layout for the **System Administrator** and **Beacon Standard User** profiles.
7. **Permissions.** Open **Beacon - Baseline - Standard Field Access**. Confirm Case has Read, Create and Edit (View All Fields unchecked), the standard Case fields listed above have Read/Edit (Closed Date Read only), and no Case record type is assigned. Open each persona "Object, Tab, FLS" permission set. Confirm the ResOps Request record type is assigned, Due Date Required and Opportunity are both Read/Edit, and Primary Module is Read.
8. **Action on Opportunity Layout.** Log in as (or impersonate) a Beacon Standard User with the Baseline and a persona permission set. Open an Opportunity using the **Opportunity Layout** (e.g. Subscription New) and confirm a **ResOps Request** button appears in the action bar.
9. **Action on Subscription Renewal layout.** Open a Subscription Renewal Opportunity and confirm the **ResOps Request** button appears.
10. **Create a ResOps Request.** Click **ResOps Request**. Confirm Opportunity is pre-filled with the current Opportunity and Account with its Account. Confirm Type offers only the four ResOps values. Fill in Type, Subject, Description and Due Date Required, then save. Confirm the success message "ResOps Request Successfully Created" appears.
11. **Verify the Case.** Open the new Case. Confirm the record type is ResOps Request, Status is New, Opportunity and Account are populated, Primary Module shows the Opportunity's Primary Module value, and the page uses the ResOps Request Case Layout. Confirm the Status picklist offers only New, In Progress, Cancelled and Completed.
12. **Close the Case.** Set Status to **Completed** and save. Confirm the Case is closed (Date/Time Closed is populated). Repeat on another Case with **Cancelled**.
13. **Cases related list.** Go back to the Opportunity and confirm the new Case appears in the **Cases** related list on both the Opportunity Layout and the Subscription Renewal layout.
14. **Regression.** Confirm existing Cases (master record type) still show the Case Layout and their existing Status values.

## Post Deployment Items

1. Make sure ResOps users and anyone who should raise requests are on the **Beacon Standard User** profile and are assigned **Beacon - Baseline - Standard Field Access** (Case access) and their persona "Object, Tab, FLS" permission set (record type visibility).

## Component Manifest

Github Branch: https://github.com/aaroncrear/BeaconImplementation/tree/ResOps-Request

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | RecordType | Case | ResOps_Request | ResOps Request | Created | New Case record type for ResOps requests; uses the ResOps Request support process and limits Type to the four ResOps values. |
| 2 | BusinessProcess (Support Process) | Case | ResOps Request | ResOps Request | Created | Support process with statuses New (default), In Progress, Cancelled and Completed. |
| 3 | CustomField | Case | Opportunity__c | Opportunity | Created | Lookup to Opportunity (Set Null on delete); child relationship "Cases". |
| 4 | CustomField | Case | Due_Date_Required__c | Due Date Required | Created | Date the requester needs the case completed by. |
| 5 | CustomField | Case | Opportunity_Primary_Module__c | Primary Module | Created | Text formula showing the related Opportunity's Primary Module: TEXT(Opportunity__r.Primary_Module__c). |
| 6 | StandardValueSet | Case | CaseStatus | Case Status | Updated | Added In Progress, Cancelled (closed) and Completed (closed), each with a description; reordered to New, In Progress, On Hold, Escalated, Closed, Cancelled, Completed. |
| 7 | StandardValueSet | Case | CaseType | Case Type | Updated | Added Company Pipeline QC, Targeted QC-Provide Further Information, Use Case - Provide Further Information and Contract Cleanup, each with a description. |
| 8 | Layout | Case | Case-ResOps Request Case Layout | ResOps Request Case Layout | Created | Two-column Case Information section (Owner, Status, Type, Priority, Case Origin / Account, Contact, Opportunity, Primary Module, Date/Time Opened, Date/Time Closed, Due Date Required) and one-column Request Details section (Subject, Description). |
| 9 | QuickAction | Opportunity | Opportunity.ResOps_Request | ResOps Request | Created | Create action for a ResOps Request Case; Opportunity defaults to the source record and Account defaults to the Opportunity's Account. |
| 10 | Layout | Opportunity | Opportunity-Opportunity Layout | Opportunity Layout | Updated | Added the ResOps Request action to the Salesforce Mobile and Lightning Experience actions and Quick Actions list, and added the Cases related list. |
| 11 | Layout | Opportunity | Opportunity-Beacon Subscription Renewal Opportunity Layout | Beacon Subscription Renewal Opportunity Layout | Updated | Added the ResOps Request action to the Salesforce Mobile and Lightning Experience actions and Quick Actions list, and added the Cases related list. |
| 12 | PermissionSet | Case | Beacon_Baseline_Standard_Field_Access | Beacon - Baseline - Standard Field Access | Updated | Granted Case Read/Create/Edit and field-by-field Read/Edit on 14 standard Case fields (Read on Closed Date). View All Fields not granted. |
| 13 | PermissionSet | Case | Beacon_Consulting_Object_Tab_FLS | Beacon Consulting - Object, Tab, FLS | Updated | Added Read/Edit on Due Date Required and Opportunity, Read on Primary Module, and visibility of the ResOps Request record type. |
| 14 | PermissionSet | Case | Beacon_Customer_Success_Object_Tab_FLS | Beacon Customer Success - Object, Tab, FLS | Updated | Added Read/Edit on Due Date Required and Opportunity, Read on Primary Module, and visibility of the ResOps Request record type. |
| 15 | PermissionSet | Case | Beacon_Executive_Object_Tab_FLS | Beacon Executive - Object, Tab, FLS | Updated | Added Read/Edit on Due Date Required and Opportunity, Read on Primary Module, and visibility of the ResOps Request record type. |
| 16 | PermissionSet | Case | Beacon_Marketing_Object_Tab_FLS | Beacon Marketing - Object, Tab, FLS | Updated | Added Read/Edit on Due Date Required and Opportunity, Read on Primary Module, and visibility of the ResOps Request record type. |
| 17 | PermissionSet | Case | Beacon_Product_Object_Tab_FLS | Beacon Product - Object, Tab, FLS | Updated | Added Read/Edit on Due Date Required and Opportunity, Read on Primary Module, and visibility of the ResOps Request record type. |
| 18 | PermissionSet | Case | Beacon_ResOps_Object_Tab_FLS | Beacon ResOps - Object, Tab, FLS | Updated | Added Read/Edit on Due Date Required and Opportunity, Read on Primary Module, and visibility of the ResOps Request record type. |
| 19 | PermissionSet | Case | Beacon_Sales_Object_Tab_FLS | Beacon Sales - Object, Tab, FLS | Updated | Added Read/Edit on Due Date Required and Opportunity, Read on Primary Module, and visibility of the ResOps Request record type. |
| 20 | PermissionSet | Case | Beacon_Salesforce_Admin_Object_Tab_FLS | Beacon Salesforce Admin - Object, Tab, FLS | Updated | Added Read/Edit on Due Date Required and Opportunity, Read on Primary Module, and visibility of the ResOps Request record type. |
| 21 | PermissionSet | Case | Beacon_Tech_Object_Tab_FLS | Beacon Tech - Object, Tab, FLS | Updated | Added Read/Edit on Due Date Required and Opportunity, Read on Primary Module, and visibility of the ResOps Request record type. |
| 22 | Profile | Case | Admin | System Administrator | Updated | Assigned the ResOps Request Case Layout to the ResOps Request record type. |
| 23 | Profile | Case | Beacon Standard User | Beacon Standard User | Updated | Assigned the ResOps Request Case Layout to the ResOps Request record type (profile newly tracked in the repo; file contains only this assignment). |
