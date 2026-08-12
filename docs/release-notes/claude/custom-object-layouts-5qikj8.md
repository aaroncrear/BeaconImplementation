# "claude/custom-object-layouts-5qikj8" – Release Notes

## Requirements

A prior Gearset commit on this branch deployed 9 brand-new custom objects (the Milestone1
project-management data model plus `Project_Snapshot__c` and `Project_Team_Member__c`) along with
all of their fields, list views, validation rules, and tabs — but each object's page layout was
left at Salesforce's bare default (just the Name field, an Owner field where applicable, and the
standard System Information section). None of the newly deployed custom fields were visible to
users on any record page. The business needed those layouts built out so every custom field is
accessible, organized into logically grouped sections with headers rather than dumped into a
single flat list.

## Release Notes

Eight of the nine newly deployed objects are standard custom objects and got rebuilt layouts; the
ninth, `Milestone1_Settings__c`, is a Hierarchy **Custom Setting** and has no page layout to build,
so it was left as-is.

For each object, every custom field was placed into a `TwoColumnsTopToBottom` section with a
descriptive header (long text/HTML fields were pulled into their own trailing `OneColumn`
section so they render full-width instead of being squeezed into a narrow column). Field behavior
was derived from each field's own metadata rather than guessed: formula fields, roll-up summary
(`Summary`) fields, and `AutoNumber` fields were all set to `Readonly` since Salesforce doesn't
allow user input on them; `MasterDetail` relationship fields were set to `Required`, matching
Salesforce's enforcement that a detail record must always have a parent; every other field was set
to editable (`Edit`). The pre-existing "System Information" and "Custom Links" sections, and any
`miniLayout`/`relatedLists` blocks, were left untouched at the end of each layout.

- **`Milestone1_Expense__c`** ("Expense Layout"): "Expense Information" (Project Task, Amount,
  Incurred By, Name, Date Incurred) and "Description".
- **`Milestone1_Log__c`** ("Log Layout"): "Log Information" (Project, Subject, Type, Name),
  "Related Records" (the 4 optional lookups back to Task/Milestone/Expense/Time), and "Detail"
  (the HTML body field).
- **`Milestone1_Milestone__c`** ("Milestone Layout"): "Milestone Information", "Schedule &
  Predecessors", "Budget & Estimates", "Actuals & Balances", "Task Rollups" (49 fields total,
  its largest layout by far), and "Description".
- **`Milestone1_Project__c`** ("Project Layout"): "Project Information", "Schedule", "Budget &
  Estimates", "Milestone & Task Rollups", "Status Indicators (Deprecated)" (the 7
  `Status_*`/`Status_Img*` chart/summary text fields whose labels are themselves marked
  "- Deprecated" in the field metadata), and "Description & Links".
- **`Milestone1_Task__c`** ("Project Task Layout"): "Task Information", "Schedule & Status",
  "Effort & Expense", "Relationships & Hierarchy", "System & Import Data", and "Description".
- **`Milestone1_Time__c`** ("Time Layout"): "Time Entry Information" and "Description".
- **`Project_Snapshot__c`** ("Project Snapshot Layout"): "Snapshot Information", "Budget &
  Expense", and "Task & Milestone Counts".
- **`Project_Team_Member__c`** ("Project Team Member Layout"): "Team Member Information" (all 3
  fields plus Name).

## Acceptance Criteria

1. Confirm all 9 objects from the prior Gearset commit are present in Object Manager:
   `Milestone1_Expense__c`, `Milestone1_Log__c`, `Milestone1_Milestone__c`,
   `Milestone1_Project__c`, `Milestone1_Settings__c`, `Milestone1_Task__c`, `Milestone1_Time__c`,
   `Project_Snapshot__c`, `Project_Team_Member__c`.
2. Open a record (or the New record page) for each of the 8 non-Custom-Setting objects above and
   confirm every custom field on that object appears somewhere on the layout — cross-check against
   the field list in Object Manager for that object.
3. Confirm each layout is organized into the named sections listed in Release Notes (not a single
   flat "Information" section), each with a visible header.
4. Confirm read-only fields (formulas, roll-up summaries, auto-numbers — e.g.
   `Milestone1_Milestone__c.Duration__c`, `Milestone1_Task__c.Total_Hours__c`,
   `Project_Team_Member__c.Name`) render as read-only/greyed-out on the edit page and are not
   editable.
5. Confirm each object's `MasterDetail` field (e.g. `Milestone1_Expense__c.Project_Task__c`,
   `Milestone1_Task__c.Project_Milestone__c`, `Project_Team_Member__c.Project__c`) is marked
   required on the edit page.
6. Confirm `Milestone1_Settings__c` has no page layout in Object Manager (custom settings don't
   support them) and was not modified by this build.
7. Confirm the full build deploys cleanly to a sandbox with no metadata errors.

## Post Deployment Items

- Field-level security for the ~150 new fields across these 8 objects was not addressed by this
  build — layouts only control what a section shows, not whether a given profile/permission set
  can see or edit the field. Confirm FLS is granted on the relevant persona permission sets before
  end users rely on these layouts.
- Several fields on `Milestone1_Project__c` and `Milestone1_Milestone__c` are explicitly labeled
  "- Deprecated" in their field metadata (the `Status_*`/`Status_Img*`/`Open_vs_Complete_Tasks__c`/
  `Open_Late_Blocked_Tasks__c` fields) but were still added to the layout for completeness per this
  request's "all fields" scope — confirm with the business whether these deprecated fields should
  instead be hidden or removed from the layout (or from the object entirely) in a follow-up.
- No Lightning Record Pages, compact layouts, or layout assignments (record type/profile) were
  created or changed by this build — only the existing default page layouts were edited in place.

## Component Manifest

Github Branch: https://github.com/aaroncrear/beaconimplementation/tree/claude/custom-object-layouts-5qikj8

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Layout | Milestone1_Expense__c | Milestone1_Expense__c-Expense Layout | Expense Layout | Updated | Added all 5 custom fields across "Expense Information" and "Description" sections. |
| 2 | Layout | Milestone1_Log__c | Milestone1_Log__c-Log Layout | Log Layout | Updated | Added all 8 custom fields across "Log Information", "Related Records", and "Detail" sections. |
| 3 | Layout | Milestone1_Milestone__c | Milestone1_Milestone__c-Milestone Layout | Milestone Layout | Updated | Added all 49 custom fields across "Milestone Information", "Schedule & Predecessors", "Budget & Estimates", "Actuals & Balances", "Task Rollups", and "Description" sections. |
| 4 | Layout | Milestone1_Project__c | Milestone1_Project__c-Project Layout | Project Layout | Updated | Added all 34 custom fields across "Project Information", "Schedule", "Budget & Estimates", "Milestone & Task Rollups", "Status Indicators (Deprecated)", and "Description & Links" sections. |
| 5 | Layout | Milestone1_Task__c | Milestone1_Task__c-Project Task Layout | Project Task Layout | Updated | Added all 34 custom fields across "Task Information", "Schedule & Status", "Effort & Expense", "Relationships & Hierarchy", "System & Import Data", and "Description" sections. |
| 6 | Layout | Milestone1_Time__c | Milestone1_Time__c-Time Layout | Time Layout | Updated | Added all 6 custom fields across "Time Entry Information" and "Description" sections. |
| 7 | Layout | Project_Snapshot__c | Project_Snapshot__c-Project Snapshot Layout | Project Snapshot Layout | Updated | Added all 15 custom fields across "Snapshot Information", "Budget & Expense", and "Task & Milestone Counts" sections. |
| 8 | Layout | Project_Team_Member__c | Project_Team_Member__c-Project Team Member Layout | Project Team Member Layout | Updated | Added all 3 custom fields to the "Team Member Information" section. |
