# "Beacon-Custom-PM-App" – Release Notes

## Requirements

- Build a custom Project Management data model for Beacon to replace the removed Milestones PM build, using the PM_App specification:
  - **Project:** auto-numbered project code, project name, client account and contact, owner and sales owner, client and logo status, project status, methodology, type, module subscription, kickoff and deadline with an auto-calculated duration in weeks, and budget (professional fees, directs, auto-calculated total, bundle hours).
  - **Time:** auto-numbered time entries tied to a Project (master-detail) and a team member (user), with date and hours.
- Point the existing Project Team Member object's master-detail at the new Project object instead of `Milestone1_Project__c`.
- Add descriptions to every object and field, and create page layouts and Lightning record pages for each object.
- **Beacon Consulting - Object, Tab, FLS:** Read, Create and Edit on the objects and fields.
- **Beacon Salesforce Admin - Object, Tab, FLS:** full CRUD, View All and Modify All.

## Release Notes

- **Project (`Project__c`).**
  - The record name is the auto-numbered **Project Code** (`Proj - 00001`). The descriptive name is in a separate Project Name field.
  - Owner uses the standard record Owner. Sales Owner is a separate user lookup.
  - Sharing is Public Read/Write so the consulting team can collaborate on any project. The Consulting permission set has no View All, so a Private model would hide other people's projects.
  - **Project Status:** "None" from the spec is the standard blank (--None--) value, not a stored value.
  - **Project Type:** "Lauch" is corrected to "Launch". "Other" is anchored at the bottom of the list. A **Project Type - Other** text field plus a validation rule capture what "Other" means, per the "[specify]" note.
  - **Module Subscription:** a multi-select picklist on the existing **Primary Module** global value set, the same one used by Campaign and Opportunity. Adding a module there makes it available in all of them. The spec's None, All and Autoimmune values aren't in that value set, so they aren't available; leaving the field blank means no modules.
  - **Duration (Weeks):** a formula, (Deadline – Kickoff) / 7, shown to one decimal. It stays blank until both dates are set.
  - **Budget - Total:** a currency formula, Professional Fees + Directs, with blanks treated as zero.
  - A validation rule stops Deadline from being set before Kickoff.
  - History tracking is on for Project Status, Kickoff and Deadline.
- **Project Time (`Project_Time__c`).**
  - Detail of Project through a master-detail, auto-numbered `PT - 000001`, with Date and Hours (two decimals).
  - Salesforce doesn't allow a master-detail to User, so **Project Team Member** is a lookup to User. It is required on the page layout.
  - A validation rule requires Hours to be greater than zero.
- **Project Team Member (`Project_Team_Member__c`).**
  - The existing object is kept and updated. Salesforce can't change the parent object (`referenceTo`) of an existing master-detail, so a new master-detail field, **`Beacon_Project__c`** (label "Project"), points at the new `Project__c`. The page layout, list view and the Project page's related list use the new field. Team Member (User) and Role are unchanged apart from added descriptions.
  - The old `Project__c` master-detail (to `Milestone1_Project__c`) is deleted by the `manifest/destructive/project-management/` manifest. That manifest no longer deletes the Project Team Member object itself.
- **Page layouts and Lightning pages.** Each object has a sectioned page layout and a Beacon Lightning record page (header, Details and Related tabs, activity sidebar).
  - The Lightning pages are activated as the org default desktop record page through each object's View action override.
  - The Project layout includes the Project Team Members, Project Time, activity and field history related lists.
- **Tabs and permissions.** Tabs were added for Projects and Project Time. Both permission sets grant the object, field and tab access listed below.
  - Master-detail fields are left out of field-level security because Salesforce always grants access to them.
  - Formula fields are read-only.

## Acceptance Criteria

1. Assign the **Beacon Consulting - Object, Tab, FLS** permission set to a test user and log in as that user.
2. Open the **Projects** tab and click **New**. Confirm the Beacon Project Record Page loads and the Project Code is auto-numbered on save (e.g. `Proj - 00001`).
3. Fill in Project Name, Account, Contact, Sales Owner, Client Status, Logo Status, Project Status, Methodology and Project Type, then save. Confirm the record saves.
4. Set Project Type to **Other** and leave Project Type - Other blank. Confirm the error "Please specify the project type in Project Type - Other." Fill it in and confirm the record saves.
5. In Module Subscription, confirm the available values match the Primary Module global value set. Select **ADC** and **Oncology** and confirm the record saves with both values.
6. Set Kickoff to 01/01/2027 and Deadline to 29/01/2027. Confirm Duration (Weeks) shows 4.0. Set Deadline before Kickoff and confirm the error.
7. Enter Budget - Professional Fees = 10,000 and Budget - Directs = 2,500. Confirm Budget - Total = 12,500.00. Clear Directs and confirm the total is 10,000.00.
8. From the Project's Related tab, create a **Project Team Member** with a Team Member and Role. Confirm it appears in the related list.
9. From the Project's Related tab, create a **Project Time** record with Project Team Member, Date and Hours = 1.5. Confirm it saves as `PT - 000001`. Enter Hours = 0 and confirm the error.
10. As the Consulting user, confirm Projects can be created and edited but not deleted, and that Projects owned by other users are visible and editable.
11. Assign **Beacon Salesforce Admin - Object, Tab, FLS** to a test user. Confirm the user can delete Projects, Project Time and Project Team Members, and has View All / Modify All.

## Post Deployment Items

- **Deployment order:**
  1. **Before deploying:** delete any existing Project Team Member records. They belong to the old Milestones projects, and Salesforce won't add a new master-detail field to an object that already has records.
  2. **Deploy this branch.** This adds `Beacon_Project__c` next to the old `Project__c` master-detail.
  3. **Then deploy the `manifest/destructive/project-management/` destructive change set.** It deletes the old Project Team Member `Project__c` field, the Milestones PM objects and tabs, and the old Project Task and Milestone Lightning pages. `Beacon_Project_Record_Page` was taken out of that manifest because this build reuses the name for the new Project page.
     `sf project deploy start --manifest manifest/destructive/project-management/package.xml --pre-destructive-changes manifest/destructive/project-management/destructiveChangesPre.xml --post-destructive-changes manifest/destructive/project-management/destructiveChanges.xml --target-org <alias>`
     In sandboxes, add `--purge-on-delete` so the deleted objects are erased right away.
- **Assign permission sets:** assign the Beacon Consulting and Beacon Salesforce Admin permission sets to the relevant users, if they aren't already assigned.
- **Phone and tablet pages:** the Lightning pages are activated as the desktop org default. Activate them for phone in Lightning App Builder if mobile access is needed.

## Component Manifest

Github Branch: [Beacon-Custom-PM-App](https://github.com/aaroncrear/BeaconImplementation/tree/Beacon-Custom-PM-App)

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Custom Object | Project__c | Project__c | Project | Created | Beacon client project. Holds the client, owners, scope (methodology, type, modules), schedule and budget for a piece of consulting work. Parent of Project Team Members and Project Time. |
| 2 | Custom Field (Lookup) | Project__c | Account__c | Account | Created | Client account the project is delivered for. |
| 3 | Custom Field (Number) | Project__c | Budget_Bundle_Hours__c | Budget - Bundle Hours | Created | Budgeted bundle hours for the project. |
| 4 | Custom Field (Currency) | Project__c | Budget_Directs__c | Budget - Directs | Created | Budgeted direct costs for the project. |
| 5 | Custom Field (Currency) | Project__c | Budget_Professional_Fees__c | Budget - Professional Fees | Created | Budgeted professional fees for the project. |
| 6 | Custom Field (Currency) | Project__c | Budget_Total__c | Budget - Total | Created | Auto-calculated total budget: Budget - Professional Fees plus Budget - Directs. |
| 7 | Custom Field (Picklist) | Project__c | Client_Status__c | Client Status | Created | Whether the client is new to Beacon or a repeat client. |
| 8 | Custom Field (Lookup) | Project__c | Contact__c | Contact | Created | Primary client contact for the project. |
| 9 | Custom Field (Date) | Project__c | Deadline__c | Deadline | Created | Project deadline (end) date. |
| 10 | Custom Field (Number) | Project__c | Duration_Weeks__c | Duration (Weeks) | Created | Auto-calculated number of weeks between Kickoff and Deadline. Blank until both dates are set. |
| 11 | Custom Field (Date) | Project__c | Kickoff__c | Kickoff | Created | Project kickoff (start) date. |
| 12 | Custom Field (Picklist) | Project__c | Logo_Status__c | Logo Status | Created | Whether the client logo is new to Beacon or a repeat logo. |
| 13 | Custom Field (MultiselectPicklist) | Project__c | Module_Subscription__c | Module Subscription | Created | Beacon modules the client subscribes to for this project. Uses the Primary Module global value set. |
| 14 | Custom Field (Picklist) | Project__c | Project_Methodology__c | Project Methodology | Created | Research methodology used to deliver the project. |
| 15 | Custom Field (Text) | Project__c | Project_Name__c | Project Name | Created | Descriptive name of the project. The record name is the auto-numbered Project Code. |
| 16 | Custom Field (Picklist) | Project__c | Project_Status__c | Project Status | Created | Current delivery status of the project. Blank means no status set yet (None). |
| 17 | Custom Field (Text) | Project__c | Project_Type_Other__c | Project Type - Other | Created | Free-text project type, required when Project Type is Other. |
| 18 | Custom Field (Picklist) | Project__c | Project_Type__c | Project Type | Created | Type of project delivered. When Other is selected, Project Type - Other must be filled in. |
| 19 | Custom Field (Lookup) | Project__c | Sales_Owner__c | Sales Owner | Created | User who sold the project. The project Owner is the user delivering it. |
| 20 | Validation Rule | Project__c | Deadline_After_Kickoff | Deadline After Kickoff | Created | Deadline cannot be before Kickoff. |
| 21 | Validation Rule | Project__c | Project_Type_Other_Required | Project Type Other Required | Created | Project Type - Other must be completed when Project Type is Other. |
| 22 | Compact Layout | Project__c | Beacon_Project_Compact_Layout | Beacon Project Compact Layout | Created | Highlights panel fields: Project Code, Project Name, Account, Project Status, Deadline, Owner. |
| 23 | List View | Project__c | Project__c.All | All | Created | List view showing all records. |
| 24 | Custom Object | Project_Time__c | Project_Time__c | Project Time | Created | Hours logged by a team member against a Project on a given date. Detail of Project. |
| 25 | Custom Field (Date) | Project_Time__c | Date__c | Date | Created | Date the work was done. |
| 26 | Custom Field (Number) | Project_Time__c | Hours__c | Hours | Created | Number of hours worked. |
| 27 | Custom Field (Lookup) | Project_Time__c | Project_Team_Member__c | Project Team Member | Created | User who did the work. Lookup to User because master-detail relationships cannot point at User. |
| 28 | Custom Field (MasterDetail) | Project_Time__c | Project__c | Project | Created | Project the time is logged against. |
| 29 | Validation Rule | Project_Time__c | Hours_Must_Be_Positive | Hours Must Be Positive | Created | Hours must be greater than zero. |
| 30 | List View | Project_Time__c | Project_Time__c.All | All | Created | List view showing all records. |
| 31 | Custom Object | Project_Team_Member__c | Project_Team_Member__c | Project Team Member | Updated | Member of a project team, with their role. Detail of Project. Master-detail moved to the new Project object through the new Beacon_Project__c field. |
| 32 | Custom Field (MasterDetail) | Project_Team_Member__c | Beacon_Project__c | Project | Created | Master-detail to the new Project (Project__c) object. Replaces the old Project__c field, whose parent can't be changed. |
| 33 | Custom Field (MasterDetail) | Project_Team_Member__c | Project__c | Project | Deleted | Old master-detail to Milestone1_Project__c. Deleted by manifest/destructive/project-management/destructiveChanges.xml. |
| 34 | Custom Field (Picklist) | Project_Team_Member__c | Role__c | Role | Updated | Role of the team member on the project. |
| 35 | Custom Field (Lookup) | Project_Team_Member__c | Team_Member__c | Team Member | Updated | User on the project team. |
| 36 | List View | Project_Team_Member__c | Project_Team_Member__c.All | All | Created | List view showing all records. |
| 37 | Page Layout | Project__c | Project__c-Project Layout | Project Layout | Created | Page layout with every field grouped into sections. Includes Project Team Members and Project Time related lists. |
| 38 | Page Layout | Project_Time__c | Project_Time__c-Project Time Layout | Project Time Layout | Created | Page layout with every field grouped into sections. |
| 39 | Page Layout | Project_Team_Member__c | Project_Team_Member__c-Project Team Member Layout | Project Team Member Layout | Updated | Page layout with every field grouped into sections. |
| 40 | Lightning Record Page | Project__c | Beacon_Project_Record_Page | Beacon Project Record Page | Created | Header and Details/Related tabs, with the activity panel in the sidebar. Set as the org default desktop record page through the object's View override. |
| 41 | Lightning Record Page | Project_Time__c | Beacon_Project_Time_Record_Page | Beacon Project Time Record Page | Created | Header and Details/Related tabs, with the activity panel in the sidebar. Set as the org default desktop record page through the object's View override. |
| 42 | Lightning Record Page | Project_Team_Member__c | Beacon_Project_Team_Member_Record_Page | Beacon Project Team Member Record Page | Created | Header and Details/Related tabs, with the activity panel in the sidebar. Set as the org default desktop record page through the object's View override. |
| 43 | Custom Tab | Project__c | Project__c | Projects | Created | Object tab for Project. |
| 44 | Custom Tab | Project_Time__c | Project_Time__c | Project Time | Created | Object tab for Project Time. |
| 45 | Permission Set | N/A | Beacon_Consulting_Object_Tab_FLS | Beacon Consulting - Object, Tab, FLS | Updated | Read, Create and Edit on Project, Project Time and Project Team Member. Read/Edit on all fields (read-only on formulas). Tabs visible. |
| 46 | Permission Set | N/A | Beacon_Salesforce_Admin_Object_Tab_FLS | Beacon Salesforce Admin - Object, Tab, FLS | Updated | Full CRUD, View All and Modify All on Project, Project Time and Project Team Member. Read/Edit on all fields (read-only on formulas). Tabs visible. |
| 47 | Destructive Manifest | N/A | manifest/destructive/project-management/destructiveChanges.xml | destructiveChanges.xml | Updated | No longer deletes the Project_Team_Member__c object. Now deletes only its old Project__c master-detail field, plus the Milestones PM objects. |
| 48 | Destructive Manifest | N/A | manifest/destructive/project-management/destructiveChangesPre.xml | destructiveChangesPre.xml | Updated | Removed Beacon_Project_Record_Page, which is now the new Project record page. |
