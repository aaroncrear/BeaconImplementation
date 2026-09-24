# "Seniority-Scoring" – Release Notes

## Requirements

Leads and Contacts need a numeric seniority score based on the person's Title. Leads also need a seniority level that matches the standard Contact field.

- Add a picklist field, **Seniority Level**, to Leads with the same values as the standard **Seniority Level** field on the Contact. The standard Contact field's values can't be changed, so the Lead field copies it. Automation will fill it in from the Title and Seniority Score.
- Add a formula field, **Seniority Score**, to Leads and Contacts. It is a number with no decimals, based on the Title. The logic comes from the *Seniority Score and Segment Logic* spreadsheet (Seniority Ranking tab). Going in the order of the spreadsheet: if the Title contains the value in column B (Title), the Seniority Score is the value in column C (Seniority Level Score).
- Give read access to the new fields in the nine **Beacon … - Object, Tab, FLS** permission sets.
- On the Lead page layout, put Seniority Level under Department, then Seniority Score under Seniority Level.
- On the Contact page layout, put Seniority Score under Seniority Level.
- Set **Seniority Level** automatically from the Title on Leads (the new field) and Contacts (the standard field), using the spreadsheet's score-to-level mapping (column D):
  - Update the **Lead - On Update - Before Save** and **Contact - On Update - Before Save** flows to also run when the Title changes, and set Seniority Level with a flow formula named `formSeniorityLevel`.
  - Give each updated flow a new description, and give every flow element a description.
  - Create **Lead - On Create - Before Save** and **Contact - On Create - Before Save** flows that set Seniority Level the same way when a record is created with a Title.

## Release Notes

### Seniority Level (Lead)

A restricted picklist field, **Seniority Level** (`Seniority_Level__c`), was added to **Lead**. Its description is "Populated via automation based on Title and Seniority Score. This replicates the standard field on the Contact, which can not have its values updated."

The values were copied from the standard Contact field **Seniority Level** (API name `TitleType`). Both the labels and the API names match, so automation and Lead conversion mapping can copy values between the two fields without translating them:

| Label | API Name |
|-------|----------|
| CEO | `ceo` |
| Executive | `executive` |
| VP | `vp` |
| Director or Manager | `directorOrManager` |
| Individual Contributor | `individualContributor` |

The picklist is restricted, so it can only hold these five values, just like the Contact field. The flows below fill it in from the Title.

### Seniority Score (Lead and Contact)

A Number formula field, **Seniority Score** (`Seniority_Score__c`), was added to **Lead** and **Contact**. It has no decimal places (scale 0). Its description is "Populated based on the Title." The formula is the same on both objects.

The formula checks the Title against the 87 keywords on the Seniority Ranking tab, in the order the spreadsheet lists them (top to bottom). **The first keyword the Title contains sets the score.** Consecutive keywords with the same score are grouped into one `OR()`. This keeps the formula under Salesforce's 3,900-character limit without changing which keyword wins. If the Title contains none of the keywords, or is blank, the score is blank.

Things to know about how the formula matches:

- **Matching is case-sensitive.** `CONTAINS()` is case-sensitive, so "Director" matches "Direct" but "director" doesn't.
- **Keywords match anywhere in the Title, including inside other words.** For example, "Intern" matches "International", "Temp" matches "Template", and "Lead" matches "Leader" and "Leadership". "PM", "MD" and "CEO" match anywhere they appear in capital letters.
- **Earlier rows win over later, more specific rows.** Because the spreadsheet runs from the lowest score to the highest, a general keyword near the top can match before a more specific one further down. Some examples:

| Title | Score | Matching keyword |
|-------|-------|------------------|
| CEO | 9 | CEO |
| President | 10 | Preside |
| Vice President of Sales | 7 | Vice P |
| Head of Product | 6 | Head |
| Chief Executive Officer | 5 | Officer (spreadsheet row 44, before "Chief Exec") |
| Chief Financial Officer | 5 | Officer (spreadsheet row 44, before "Chief") |
| Managing Director | 5 | Manag (spreadsheet row 48, before "Managing Director") |
| Senior Vice President | 5 | Senior (spreadsheet row 49, before "Vice P") |
| Director of Engineering | 3 | Engineer (spreadsheet row 17, before "Direct") |
| Principal Engineer | 3 | Engineer (spreadsheet row 17, before "Principal Eng") |
| Senior Analyst | 3 | Analys (spreadsheet row 18, before "Senior Analys") |

The formula is:

```
IF( CONTAINS( Title, "Other" ),
    0,
IF( OR(
    CONTAINS( Title, "Graduat" ),
    CONTAINS( Title, "Intern" ),
    CONTAINS( Title, "Postdoc" ),
    CONTAINS( Title, "Student" ),
    CONTAINS( Title, "Temp" ),
    CONTAINS( Title, "Train" )
),
    1,
IF( OR(
    CONTAINS( Title, "Administra" ),
    CONTAINS( Title, " Assistant" ),
    CONTAINS( Title, "Assistant" ),
    CONTAINS( Title, "Fellow" ),
    CONTAINS( Title, "Profess" ),
    CONTAINS( Title, "Research" ),
    CONTAINS( Title, "Scien" )
),
    2,
IF( OR(
    CONTAINS( Title, "Coordinat" ),
    CONTAINS( Title, "Engineer" ),
    CONTAINS( Title, "Analys" ),
    CONTAINS( Title, "Lecturer" ),
    CONTAINS( Title, "Supervis" )
),
    3,
IF( OR(
    CONTAINS( Title, "Principal " ),
    CONTAINS( Title, "Specialist" ),
    CONTAINS( Title, "Associate Prin" ),
    CONTAINS( Title, "Principal Analys" ),
    CONTAINS( Title, "Principa Profes" ),
    CONTAINS( Title, "Principal Research" ),
    CONTAINS( Title, "Principal Scien" ),
    CONTAINS( Title, "Principal Specia" ),
    CONTAINS( Title, "Principal Eng" ),
    CONTAINS( Title, "Consultant" ),
    CONTAINS( Title, "Investigator" ),
    CONTAINS( Title, "Marketing" ),
    CONTAINS( Title, "PM" ),
    CONTAINS( Title, "Recruiter" ),
    CONTAINS( Title, "Sales Representative" ),
    CONTAINS( Title, "Senior Analys" ),
    CONTAINS( Title, "Senior Professor" ),
    CONTAINS( Title, "Senior Research" ),
    CONTAINS( Title, "Senior Scien" ),
    CONTAINS( Title, "Senior Special" ),
    CONTAINS( Title, "Superintendent" ),
    CONTAINS( Title, "Microb" ),
    CONTAINS( Title, "Advisor" )
),
    4,
IF( OR(
    CONTAINS( Title, "Officer" ),
    CONTAINS( Title, "Associat" ),
    CONTAINS( Title, "General Super" ),
    CONTAINS( Title, "Lead" ),
    CONTAINS( Title, "Manag" ),
    CONTAINS( Title, "Senior" ),
    CONTAINS( Title, "Senior PM" ),
    CONTAINS( Title, "Senior Project" ),
    CONTAINS( Title, "SeniorSuper" )
),
    5,
IF( OR(
    CONTAINS( Title, "Direct" ),
    CONTAINS( Title, "Human Resource Bus" ),
    CONTAINS( Title, "AVP" ),
    CONTAINS( Title, "Executive" ),
    CONTAINS( Title, "Head" ),
    CONTAINS( Title, "Leader" ),
    CONTAINS( Title, "Regional" ),
    CONTAINS( Title, "Senior Associat" )
),
    6,
IF( OR(
    CONTAINS( Title, "Vice P" ),
    CONTAINS( Title, "EVP" ),
    CONTAINS( Title, "Global Head" ),
    CONTAINS( Title, "Managing Director" ),
    CONTAINS( Title, "Partner" ),
    CONTAINS( Title, "Principal" ),
    CONTAINS( Title, "SVP" ),
    CONTAINS( Title, "VP" )
),
    7,
IF( OR(
    CONTAINS( Title, "Chief" ),
    CONTAINS( Title, "CFO" ),
    CONTAINS( Title, "CHRO" ),
    CONTAINS( Title, "CIO" ),
    CONTAINS( Title, "CMO" ),
    CONTAINS( Title, "COO" ),
    CONTAINS( Title, "CPO" ),
    CONTAINS( Title, "CSO" ),
    CONTAINS( Title, "CRO" )
),
    8,
IF( OR(
    CONTAINS( Title, "Chief Exec" ),
    CONTAINS( Title, "CEO" ),
    CONTAINS( Title, "General Counsel" ),
    CONTAINS( Title, "MD" )
),
    9,
IF( OR(
    CONTAINS( Title, "Founder" ),
    CONTAINS( Title, "Founding" ),
    CONTAINS( Title, "Board Direct" ),
    CONTAINS( Title, "Board Memb" ),
    CONTAINS( Title, "Chair" ),
    CONTAINS( Title, "Preside" ),
    CONTAINS( Title, "Owner" )
),
    10,
NULL
)))))))))))
```

### Seniority Level automation (update flows)

The existing **Lead - On Update - Before Save** and **Contact - On Update - Before Save** flows were updated to set Seniority Level when the Title changes. On Lead they set the new `Seniority_Level__c` field. On Contact they set the standard `TitleType` field.

**New description:** "Sets the Status to Do Not Engage if the record is Blacklisted or DNC and Email Opt Out. Sets the Seniority Level based on the Title when the Title changes."

**Entry criteria.** The flows keep the original field conditions and add a fourth one, **Title Is Changed = True**. The condition logic is `1 OR (2 AND 3) OR 4`:

1. Blacklisted = True
2. Do Not Call = True
3. Email Opt Out = True
4. Title Is Changed = True

"When to run the flow for updated records" changed from **Only when a record is updated to meet the condition requirements** to **Every time a record is updated and meets the condition requirements**. With the old setting, a record that already met the Blacklisted or Do Not Call conditions would never start the flow, because the conditions are joined with OR. A Title change on that record would not update its Seniority Level. With the new setting, every Title change starts the flow.

To keep the original Status behavior, the "only when updated to meet the criteria" check moved into the **Do Not Engage Criteria Met?** decision. That decision compares the record to its values before the update (`$Record__Prior`) and only sets the Status when the record newly meets the criteria:

| # | Field | Value |
|---|-------|-------|
| 1 | `$Record.Blacklisted__c` | True |
| 2 | `$Record.DoNotCall` | True |
| 3 | `$Record.HasOptedOutOfEmail` | True |
| 4 | `$Record__Prior.Blacklisted__c` | False |
| 5 | `$Record__Prior.DoNotCall` | False |
| 6 | `$Record__Prior.HasOptedOutOfEmail` | False |

Condition logic: `(1 OR (2 AND 3)) AND 4 AND (5 OR 6)`. That means the record meets the criteria now, it wasn't Blacklisted before, and it wasn't both Do Not Call and Email Opt Out before.

**Elements.** A Title change now also starts the flow, so the flow checks each part separately. This keeps a Title-only change from setting the Status. Both changes are made with Assignment elements on `$Record`, so the record is only saved once, even when both the Status and the Seniority Level change:

| Element | Type | Description |
|---------|------|-------------|
| Do Not Engage Criteria Met? | Decision | Checks whether the record was just updated to be Blacklisted, or Do Not Call and Email Opt Out, and did not meet those criteria before this update. Only then is the Status set to Do Not Engage, so a Title change or an edit to a record that already met the criteria does not reset the Status. |
| Assign Status to Do Not Engage | Assignment | Sets the Status (Lead) or Contact Status (Contact) to Do Not Engage. Replaces the old Update Status to Do Not Engage (Update Records) element. |
| Title Changed? | Decision | Checks whether the Title changed on this update, so the Seniority Level is only recalculated when the Title changes. |
| Assign Seniority Level | Assignment | Sets the Seniority Level field to the value returned by the formSeniorityLevel formula. |
| formSeniorityLevel | Formula (Text) | Returns the Seniority Level picklist API name based on the Title. |

Both decisions run in the same save, so one update can set both the Status and the Seniority Level.

**The formSeniorityLevel formula** checks the Title against the same 87 keywords as the Seniority Score, in the same spreadsheet order. The first match wins, so the level always matches the score's level from column D:

| Score | Seniority Level | Formula returns |
|-------|-----------------|-----------------|
| 0–1, or no match | Blank | `""` (clears the field) |
| 2–4 | Individual Contributor | `individualContributor` |
| 5–6 | Director or Manager | `directorOrManager` |
| 7 | VP | `vp` |
| 8 | Executive | `executive` |
| 9–10 | CEO | `ceo` |

It returns the picklist API names, which are the same on the Lead and Contact fields. It works from the Title rather than the Seniority Score formula field, because a before-save flow might not see the recalculated score when the Title changes in the same save. It has the same ordering and case-sensitivity behavior as the Seniority Score (see above). It is 3,574 characters, under Flow's 3,900-character formula limit.

```
IF(OR(
CONTAINS({!$Record.Title},"Other"),
CONTAINS({!$Record.Title},"Graduat"),
CONTAINS({!$Record.Title},"Intern"),
CONTAINS({!$Record.Title},"Postdoc"),
CONTAINS({!$Record.Title},"Student"),
CONTAINS({!$Record.Title},"Temp"),
CONTAINS({!$Record.Title},"Train")
),
"",
IF(OR(
CONTAINS({!$Record.Title},"Administra"),
CONTAINS({!$Record.Title}," Assistant"),
CONTAINS({!$Record.Title},"Assistant"),
CONTAINS({!$Record.Title},"Fellow"),
CONTAINS({!$Record.Title},"Profess"),
CONTAINS({!$Record.Title},"Research"),
CONTAINS({!$Record.Title},"Scien"),
CONTAINS({!$Record.Title},"Coordinat"),
CONTAINS({!$Record.Title},"Engineer"),
CONTAINS({!$Record.Title},"Analys"),
CONTAINS({!$Record.Title},"Lecturer"),
CONTAINS({!$Record.Title},"Supervis"),
CONTAINS({!$Record.Title},"Principal "),
CONTAINS({!$Record.Title},"Specialist"),
CONTAINS({!$Record.Title},"Associate Prin"),
CONTAINS({!$Record.Title},"Principal Analys"),
CONTAINS({!$Record.Title},"Principa Profes"),
CONTAINS({!$Record.Title},"Principal Research"),
CONTAINS({!$Record.Title},"Principal Scien"),
CONTAINS({!$Record.Title},"Principal Specia"),
CONTAINS({!$Record.Title},"Principal Eng"),
CONTAINS({!$Record.Title},"Consultant"),
CONTAINS({!$Record.Title},"Investigator"),
CONTAINS({!$Record.Title},"Marketing"),
CONTAINS({!$Record.Title},"PM"),
CONTAINS({!$Record.Title},"Recruiter"),
CONTAINS({!$Record.Title},"Sales Representative"),
CONTAINS({!$Record.Title},"Senior Analys"),
CONTAINS({!$Record.Title},"Senior Professor"),
CONTAINS({!$Record.Title},"Senior Research"),
CONTAINS({!$Record.Title},"Senior Scien"),
CONTAINS({!$Record.Title},"Senior Special"),
CONTAINS({!$Record.Title},"Superintendent"),
CONTAINS({!$Record.Title},"Microb"),
CONTAINS({!$Record.Title},"Advisor")
),
"individualContributor",
IF(OR(
CONTAINS({!$Record.Title},"Officer"),
CONTAINS({!$Record.Title},"Associat"),
CONTAINS({!$Record.Title},"General Super"),
CONTAINS({!$Record.Title},"Lead"),
CONTAINS({!$Record.Title},"Manag"),
CONTAINS({!$Record.Title},"Senior"),
CONTAINS({!$Record.Title},"Senior PM"),
CONTAINS({!$Record.Title},"Senior Project"),
CONTAINS({!$Record.Title},"SeniorSuper"),
CONTAINS({!$Record.Title},"Direct"),
CONTAINS({!$Record.Title},"Human Resource Bus"),
CONTAINS({!$Record.Title},"AVP"),
CONTAINS({!$Record.Title},"Executive"),
CONTAINS({!$Record.Title},"Head"),
CONTAINS({!$Record.Title},"Leader"),
CONTAINS({!$Record.Title},"Regional"),
CONTAINS({!$Record.Title},"Senior Associat")
),
"directorOrManager",
IF(OR(
CONTAINS({!$Record.Title},"Vice P"),
CONTAINS({!$Record.Title},"EVP"),
CONTAINS({!$Record.Title},"Global Head"),
CONTAINS({!$Record.Title},"Managing Director"),
CONTAINS({!$Record.Title},"Partner"),
CONTAINS({!$Record.Title},"Principal"),
CONTAINS({!$Record.Title},"SVP"),
CONTAINS({!$Record.Title},"VP")
),
"vp",
IF(OR(
CONTAINS({!$Record.Title},"Chief"),
CONTAINS({!$Record.Title},"CFO"),
CONTAINS({!$Record.Title},"CHRO"),
CONTAINS({!$Record.Title},"CIO"),
CONTAINS({!$Record.Title},"CMO"),
CONTAINS({!$Record.Title},"COO"),
CONTAINS({!$Record.Title},"CPO"),
CONTAINS({!$Record.Title},"CSO"),
CONTAINS({!$Record.Title},"CRO")
),
"executive",
IF(OR(
CONTAINS({!$Record.Title},"Chief Exec"),
CONTAINS({!$Record.Title},"CEO"),
CONTAINS({!$Record.Title},"General Counsel"),
CONTAINS({!$Record.Title},"MD"),
CONTAINS({!$Record.Title},"Founder"),
CONTAINS({!$Record.Title},"Founding"),
CONTAINS({!$Record.Title},"Board Direct"),
CONTAINS({!$Record.Title},"Board Memb"),
CONTAINS({!$Record.Title},"Chair"),
CONTAINS({!$Record.Title},"Preside"),
CONTAINS({!$Record.Title},"Owner")
),
"ceo",
""))))))
```

### Seniority Level automation (create flows)

Two new before-save flows, **Lead - On Create - Before Save** and **Contact - On Create - Before Save**, set Seniority Level when a record is created with a Title.

- **Description:** "Sets the Seniority Level based on the Title when a Lead is created with a Title." The Contact flow says "Contact" instead of "Lead".
- **Entry criteria:** Title Is Null = False. Records created without a Title don't start the flow.

| Element | Type | Description |
|---------|------|-------------|
| Update Seniority Level | Update Records ($Record) | Sets the Seniority Level field to the value returned by the formSeniorityLevel formula. On Lead this is `Seniority_Level__c`; on Contact it is `TitleType`. |
| formSeniorityLevel | Formula (Text) | The same formula as the update flows. Returns the Seniority Level picklist API name based on the Title. |

Before-save flows update the record in the same save, without a second DML operation, so no Update Records call on another record is needed.

### Page layouts

- **Lead Layout:** **Seniority Level** was added under **Department** (`Department__c`), and **Seniority Score** under Seniority Level. Both are read-only. Seniority Score is a formula, and Seniority Level is filled in by automation.
- **Contact Layout:** **Seniority Score** was added, read-only, under the standard **Seniority Level** (`TitleType`) field.

### Field access

Read-only access to **Lead: Seniority Level**, **Lead: Seniority Score** and **Contact: Seniority Score** was added to these permission sets:

- Beacon Consulting - Object, Tab, FLS
- Beacon Customer Success - Object, Tab, FLS
- Beacon Executive - Object, Tab, FLS
- Beacon Marketing - Object, Tab, FLS
- Beacon Product - Object, Tab, FLS
- Beacon ResOps - Object, Tab, FLS
- Beacon Sales - Object, Tab, FLS
- Beacon Salesforce Admin - Object, Tab, FLS
- Beacon Tech - Object, Tab, FLS

## Acceptance Criteria

1. In **Setup → Object Manager → Lead → Fields & Relationships**, open **Seniority Level** and confirm:
   1. It is a picklist with the API name `Seniority_Level__c`.
   2. **Restrict picklist to the values defined in the value set** is checked.
   3. The values are CEO, Executive, VP, Director or Manager and Individual Contributor, with the API names shown in the Release Notes.
   4. The description matches the Release Notes.
2. Open **Object Manager → Contact → Fields & Relationships → Seniority Level** (the standard field) and confirm its values and API names match the Lead field.
3. On both **Lead** and **Contact**, open **Seniority Score** and confirm it is a Number formula with 0 decimal places, the API name `Seniority_Score__c`, and the description "Populated based on the Title."
4. Log in as, or assign the permission sets to, a user with one of the nine Beacon … - Object, Tab, FLS permission sets. Confirm the user can see all three fields and can't edit them.
5. Open a Lead. Confirm **Seniority Level** appears under **Department** and **Seniority Score** under Seniority Level.
6. Open a Contact. Confirm **Seniority Score** appears under **Seniority Level**.
7. Test the score on a Lead and on a Contact. Set the Title to each value below, save, and confirm the Seniority Score:

| Title | Expected Seniority Score |
|-------|--------------------------|
| Sales Intern | 1 |
| Research Scientist | 2 |
| Data Analyst | 3 |
| Marketing Manager | 4 |
| Project Manager | 5 |
| Head of Product | 6 |
| Vice President of Sales | 7 |
| CFO | 8 |
| CEO | 9 |
| Founder | 10 |
| Other | 0 |
| Accountant | Blank |
| *(blank Title)* | Blank |

8. Change a record's Title from "Sales Intern" to "Founder". Confirm the score changes from 1 to 10.
9. Set a Title to "sales intern" (lowercase). Confirm the score is blank, because matching is case-sensitive.
10. On an existing Lead and an existing Contact, change the Title to each value below, save, and confirm the **Seniority Level**:

| Title | Expected Seniority Level |
|-------|--------------------------|
| Sales Intern | Blank |
| Data Analyst | Individual Contributor |
| Project Manager | Director or Manager |
| Head of Product | Director or Manager |
| Vice President of Sales | VP |
| CFO | Executive |
| Founder | CEO |
| Accountant | Blank |

11. Change the Title of a record with a Seniority Level to blank. Confirm the Seniority Level is cleared.
12. On a Lead or Contact that isn't Blacklisted, Do Not Call or Email Opt Out, change only the Title. Confirm the Status (Lead) or Contact Status (Contact) doesn't change to Do Not Engage.
13. Check **Blacklisted** on a Lead and a Contact and save. Confirm the Status (Lead) or Contact Status (Contact) changes to Do Not Engage.
14. On the same records, change the Status back to another value and save without changing Blacklisted. Confirm it isn't set back to Do Not Engage, because the criteria were already met before this update.
15. On the same Blacklisted records, change the Title. Confirm the Seniority Level updates and the Status is **not** set back to Do Not Engage.
16. Check **Do Not Call** and **Email Opt Out** together on a record that is neither, and change the Title in the same save. Confirm the Status changes to Do Not Engage and the Seniority Level is set.
17. Create a new Lead and a new Contact with the Title "Vice President of Sales". Confirm the Seniority Level is VP.
18. Create a new Lead and a new Contact with no Title. Confirm the Seniority Level is blank.
19. In **Setup → Flows**, confirm **Lead - On Create - Before Save** and **Contact - On Create - Before Save** are active, and that every element in all four flows has a description.

## Post Deployment Items

- **Fill in existing records.** The flows only run when a record is saved. Existing Leads and Contacts with a Title need a one-time data update to set their Seniority Level.
- **Map Seniority Level on Lead conversion.** In **Object Manager → Lead → Fields & Relationships → Map Lead Fields**, map Lead **Seniority Level** to Contact **Seniority Level**. The API names match, so the value copies over as-is.
- **Review the keyword order.** The formula follows the spreadsheet order exactly, so some senior titles score low (see the examples in the Release Notes, such as "Chief Executive Officer" = 5). If that isn't intended, reorder the spreadsheet, and the formula can be regenerated from it.

## Component Manifest

Github Branch: https://github.com/aaroncrear/BeaconImplementation/tree/Seniority-Scoring

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | CustomField | Lead | Seniority_Level__c | Seniority Level | Created | Restricted picklist with the same values and API names as the standard Contact Seniority Level (TitleType) field: CEO, Executive, VP, Director or Manager, Individual Contributor. Populated via automation (not included in this build). |
| 2 | CustomField | Lead | Seniority_Score__c | Seniority Score | Created | Number formula (0 decimals) that scores the Lead's Title using the Seniority Ranking keyword list. |
| 3 | CustomField | Contact | Seniority_Score__c | Seniority Score | Created | Number formula (0 decimals) that scores the Contact's Title using the Seniority Ranking keyword list. |
| 4 | Layout | Lead | Lead-Lead Layout | Lead Layout | Updated | Added Seniority_Level__c under Department__c, and Seniority_Score__c under Seniority_Level__c, both read-only. |
| 5 | Layout | Contact | Contact-Contact Layout | Contact Layout | Updated | Added Seniority_Score__c, read-only, under the standard Seniority Level (TitleType) field. |
| 6 | PermissionSet | N/A | Beacon_Consulting_Object_Tab_FLS | Beacon Consulting - Object, Tab, FLS | Updated | Added read access to Lead.Seniority_Level__c, Lead.Seniority_Score__c and Contact.Seniority_Score__c. |
| 7 | PermissionSet | N/A | Beacon_Customer_Success_Object_Tab_FLS | Beacon Customer Success - Object, Tab, FLS | Updated | Added read access to Lead.Seniority_Level__c, Lead.Seniority_Score__c and Contact.Seniority_Score__c. |
| 8 | PermissionSet | N/A | Beacon_Executive_Object_Tab_FLS | Beacon Executive - Object, Tab, FLS | Updated | Added read access to Lead.Seniority_Level__c, Lead.Seniority_Score__c and Contact.Seniority_Score__c. |
| 9 | PermissionSet | N/A | Beacon_Marketing_Object_Tab_FLS | Beacon Marketing - Object, Tab, FLS | Updated | Added read access to Lead.Seniority_Level__c, Lead.Seniority_Score__c and Contact.Seniority_Score__c. |
| 10 | PermissionSet | N/A | Beacon_Product_Object_Tab_FLS | Beacon Product - Object, Tab, FLS | Updated | Added read access to Lead.Seniority_Level__c, Lead.Seniority_Score__c and Contact.Seniority_Score__c. |
| 11 | PermissionSet | N/A | Beacon_ResOps_Object_Tab_FLS | Beacon ResOps - Object, Tab, FLS | Updated | Added read access to Lead.Seniority_Level__c, Lead.Seniority_Score__c and Contact.Seniority_Score__c. |
| 12 | PermissionSet | N/A | Beacon_Sales_Object_Tab_FLS | Beacon Sales - Object, Tab, FLS | Updated | Added read access to Lead.Seniority_Level__c, Lead.Seniority_Score__c and Contact.Seniority_Score__c. |
| 13 | PermissionSet | N/A | Beacon_Salesforce_Admin_Object_Tab_FLS | Beacon Salesforce Admin - Object, Tab, FLS | Updated | Added read access to Lead.Seniority_Level__c, Lead.Seniority_Score__c and Contact.Seniority_Score__c. |
| 14 | PermissionSet | N/A | Beacon_Tech_Object_Tab_FLS | Beacon Tech - Object, Tab, FLS | Updated | Added read access to Lead.Seniority_Level__c, Lead.Seniority_Score__c and Contact.Seniority_Score__c. |
| 15 | Flow | Lead | Lead_On_Update_Before_Save | Lead - On Update - Before Save | Updated | Added Title Is Changed to the entry criteria (1 OR (2 AND 3) OR 4) and changed the flow to run every time a record is updated and meets the criteria. Added a Do Not Engage Criteria Met? decision that uses prior values to keep the original only-when-newly-met Status behavior, a Title Changed? decision, the formSeniorityLevel formula, and an Assign Seniority Level assignment that sets Seniority_Level__c. Replaced the Update Status to Do Not Engage record update with an Assign Status to Do Not Engage assignment. Updated the flow description. |
| 16 | Flow | Contact | Contact_On_Update_Before_Save | Contact - On Update - Before Save | Updated | Added Title Is Changed to the entry criteria (1 OR (2 AND 3) OR 4) and changed the flow to run every time a record is updated and meets the criteria. Added a Do Not Engage Criteria Met? decision that uses prior values to keep the original only-when-newly-met Status behavior, a Title Changed? decision, the formSeniorityLevel formula, and an Assign Seniority Level assignment that sets TitleType. Replaced the Update Status to Do Not Engage record update with an Assign Status to Do Not Engage assignment. Updated the flow description. |
| 17 | Flow | Lead | Lead_On_Create_Before_Save | Lead - On Create - Before Save | Created | Before-save flow that runs when a Lead is created with a Title and sets Seniority_Level__c using the formSeniorityLevel formula. |
| 18 | Flow | Contact | Contact_On_Create_Before_Save | Contact - On Create - Before Save | Created | Before-save flow that runs when a Contact is created with a Title and sets TitleType using the formSeniorityLevel formula. |
