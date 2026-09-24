# "Seniority-Scoring" – Release Notes

## Requirements

Leads and Contacts need a numeric seniority score based on the person's Title. Leads also need a seniority level that matches the standard Contact field.

- Add a picklist field, **Seniority Level**, to Leads with the same values as the standard **Seniority Level** field on the Contact. The standard Contact field's values can't be changed, so the Lead field copies it. Automation will fill it in from the Title and Seniority Score.
- Add a formula field, **Seniority Score**, to Leads and Contacts. It is a number with no decimals, based on the Title. The logic comes from the *Seniority Score and Segment Logic* spreadsheet (Seniority Ranking tab). Going in the order of the spreadsheet: if the Title contains the value in column B (Title), the Seniority Score is the value in column C (Seniority Level Score).
- Give read access to the new fields in the nine **Beacon … - Object, Tab, FLS** permission sets.
- On the Lead page layout, put Seniority Level under Department, then Seniority Score under Seniority Level.
- On the Contact page layout, put Seniority Score under Seniority Level.

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

The picklist is restricted, so it can only hold these five values, just like the Contact field. This build doesn't include the automation that fills in the field. See Post Deployment Items.

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

## Post Deployment Items

- **Build the Seniority Level automation.** This build creates the Lead **Seniority Level** field but not the automation that fills it in. The spreadsheet maps scores to levels (column D): 0–1 Blank, 2–4 Individual Contributor, 5–6 Director or Manager, 7 VP, 8 Executive, 9–10 CEO. This can be built as a record-triggered flow in a later branch.
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
