# "Beacon-Feedback" – Release Notes

## Requirements

- Add a new **Beacon Feedback** custom object to store Beacon feedback and surveys in Salesforce. It replaces the old Beacon_Feeback process, which stored surveys in Jotform.
- Give the object one record type and page layout for each survey type: Customer Call, Intelligence, Onboarding Call 1 - Kick Off, Onboarding Call 2 - Becoming an Expert, Sales Demo, Sales Prospecting and Your Input.
- Remove `NOT($User.ByPassVR__c)` from every Validation Rule that uses it.
- Delete the **ByPassVR** (`ByPassVR__c`) checkbox field on the User object.
- Every custom field and Validation Rule on the object must have a description.

## Release Notes

### Beacon Feedback object

The **Beacon Feedback** object (`BeaconFeedback__c`) was built in the org and pulled into this branch with Gearset. It includes:

- **91 custom fields** that hold the survey questions and answers, plus supporting fields:
  - **Opportunity** (`Opportunity__c`) links each survey to an Opportunity.
  - **Beacon Feedback Name** (`Beacon_Feedback_Name__c`) is a formula: Opportunity Name - Survey Type.
  - **Due Date** (`Due_Date__c`) sets when the survey is due. **Survey Notification Date** (`Survey_Notification_Date__c`) is a formula set to 7 days before it, and **Survey Notification Today** (`Survey_Notification_Today__c`) is checked on that date.
  - **Survey Completed** (`Survey_Completed__c`) marks the survey as done.
  - The 1-5 rating fields are Number fields, limited to 1-5 by Validation Rules.
- **7 record types** and **8 page layouts**: one per survey type, plus the default Beacon Feedback Layout.
- **10 Validation Rules**: 7 keep the rating fields within range, and 2 make a field required when a Sales Prospecting or Sales Demo survey is marked complete.

### Validation Rule bypass removed

`NOT($User.ByPassVR__c)` was used by only one Validation Rule, **Any_Further_Feedback_Mandatory**. It was removed from that rule's formula, and the rest of the formula is unchanged. No other Validation Rule, flow, layout, profile or permission set in the repository references the field.

### ByPassVR field deleted (User)

Once nothing referenced it, the `ByPassVR__c` checkbox on User was deleted from the branch. The org-wide way to switch off Validation Rules is the **On/Off Switch** custom setting (`On_Off_Switch__c`, **Run Validation Rules**), added in the On-Off-Switch branch.

### Descriptions

90 of the 91 fields had no description; only **Any Further Feedback Posted To Teams** did. A description was added to each of the 90 fields and to all 10 Validation Rules. Each description says what the field holds and, where it applies, which survey layouts show it and which Validation Rule checks it.

### Things to know

- **Any_Further_Feedback_Mandatory** and **Next_Steps_Date_Mandatory** check `TEXT(Survey_Completed__c) = "YES"`, but the picklist value is `Yes`. Text comparisons in formulas are case-sensitive, so these two rules may never fire. This build leaves the formulas as they were built; test them as described below.
- 26 fields are not on any page layout: Agree Curating Module Specific Data?, Agree With Search Filters In The Spec?, Agree With The Scope Of The Module(s)?, Any Further Feedback Posted To Teams, Comment On The Layout/Appearance, Data Comprehensiveness (1-5), Did Client Understand How To Run Search, Did They Recommend Any Platform Changes, Disease Areas Are They Interested In?, Functionality They Least/Most Interested In?, If Disease Area Is Other, If Growth Factor Is Other, If Interest In New Module, If Risk Factor Is Other, If They Found Data From Other Source, If They Would Like More Info, Overall Demo Rank (1-5), Prospect's Thoughts On The Pricing?, Quality Of Data (1-5), Satisfied With The Accuracy Of Our Data?, Show Interest In Any Other Modules?, Sourcing Data Prior To Beacon?, Speed Of Platform (1-5), Usability Of Platform (1-5) and Would They Like More Information?.
- The branch doesn't include a tab, permission sets or profile changes for the object.

## Acceptance Criteria

1. In **Setup → Object Manager → Beacon Feedback**, confirm the object exists with the record name format **BFB-{0000}**.
2. Open **Fields & Relationships** and confirm all 91 custom fields exist. Open several of them and confirm each has a **Description**.
3. Open **Record Types** and confirm the 7 record types exist and are active: Customer Call, Intelligence, Onboarding Call 1 - Kick Off, Onboarding Call 2 - Becoming an Expert, Sales Demo, Sales Prospecting and Your Input.
4. Open **Validation Rules** and confirm the 10 rules exist, are active and each has a **Description**.
5. Open **Any_Further_Feedback_Mandatory** and confirm the formula no longer contains `$User.ByPassVR__c`.
6. Create a Beacon Feedback record of any record type with an Opportunity and a Survey Type. Confirm **Beacon Feedback Name** shows `<Opportunity Name>-<Survey Type>`.
7. Set **Due Date** to 7 days from today and save. Confirm **Survey Notification Date** is today and **Survey Notification Today** is checked.
8. On a **Your Input** record, enter 6 in **Rate Beacon User Friendliness (1-5)** and save. Confirm the error "Select a number between 1 and 5". Enter 0 and confirm the same error. Enter 3 and confirm it saves. Repeat for **Rate Monthly Digest's Usefulness (1-5)**.
9. On a **Customer Call** record, enter 201 in **Number Of Customers On Call** and confirm the error "Select a number between 1 and 200". Enter 10 and confirm it saves.
10. On a **Sales Prospecting** record, leave **Any Further Feedback** blank and change **Survey Completed** to **Yes**. Note whether the error "Please complete the Any Further Feedback field" appears. It is expected not to fire because of the `"YES"` comparison described above.
11. On a **Sales Demo** record, leave **Next Steps Date** blank and change **Survey Completed** to **Yes**. Note whether the Next Steps Date error appears. As in step 10, it is expected not to fire.
12. In **Object Manager → User → Fields & Relationships**, confirm **ByPassVR** no longer exists. Also check **Deleted Fields** and erase it there if it is listed.

## Post Deployment Items

- Delete the **ByPassVR** (`ByPassVR__c`) field on User in each target org where it exists. Deploy the updated **Any_Further_Feedback_Mandatory** Validation Rule first, then delete the field. In Gearset, include the deleted field in the comparison. Otherwise, delete it in **Object Manager → User → Fields & Relationships**. Any values stored in the field are lost.
- Grant users access to the Beacon Feedback object, its fields and its record types (for example through the Beacon permission sets), and add a tab if needed. None of these are in this branch.

## Component Manifest

Github Branch: https://github.com/aaroncrear/BeaconImplementation/tree/Beacon-Feedback

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | CustomObject | BeaconFeedback__c | BeaconFeedback__c | Beacon Feedback | Created | Stores Beacon feedback/surveys. Replaces the Jotform-based Beacon_Feeback process. Auto-number name BFB-{0000}. |
| 2 | CustomField | BeaconFeedback__c | Account_Manager__c | Account Manager | Created | Lookup. The Account Manager (User) responsible for the prospect on a Sales Prospecting survey. |
| 3 | CustomField | BeaconFeedback__c | Agree_Curating_Module_Specific_Data__c | Agree Curating Module Specific Data? | Created | Picklist. Records how happy the client was with how module-specific data is being curated in the specification. |
| 4 | CustomField | BeaconFeedback__c | Agree_With_Search_Filters_In_The_Spec__c | Agree With Search Filters In The Spec? | Created | Picklist. Records how happy the client was with the search filters in the specification. |
| 5 | CustomField | BeaconFeedback__c | Agree_With_The_Scope_Of_The_Module_s__c | Agree With The Scope Of The Module(s)? | Created | Picklist. Records whether the client agreed with the scope of the module(s) discussed. |
| 6 | CustomField | BeaconFeedback__c | Any_Additional_Users_Interested__c | Any Additional Users Interested? | Created | Picklist. Records whether any additional users at the client are interested in Beacon. Used on Customer Call and Onboarding Call 1 - Kick Off surveys. |
| 7 | CustomField | BeaconFeedback__c | Any_Challenges_Faced__c | Any Challenges Faced | Created | Picklist. Records whether the client has faced any challenges using Beacon. Used on Customer Call surveys. |
| 8 | CustomField | BeaconFeedback__c | Any_Further_Feedback_Posted_To_Teams__c | Any Further Feedback Posted To Teams | Created | Checkbox. Used as a flag to check when the 'Any Further Feedback' field is filled in and the survey gets completed if the value has been sent to the MS Teams Channel. |
| 9 | CustomField | BeaconFeedback__c | Any_Further_Feedback__c | Any Further Feedback | Created | LongTextArea. Free-text field for any further feedback from the client. Required on Sales Prospecting surveys when Survey Completed is set to Yes (Any_Further_Feedback_Mandatory validation rule). |
| 10 | CustomField | BeaconFeedback__c | Any_Other_Projects_That_We_Can_Support__c | Any Other Projects That We Can Support | Created | LongTextArea. Free-text field for any other client projects the Beacon team could support. Used on Customer Call surveys. |
| 11 | CustomField | BeaconFeedback__c | Beacon_Feedback_Name__c | Beacon Feedback Name | Created | Text (Formula). Formula that builds a readable name for the survey from the related Opportunity name and the Survey Type (Opportunity Name - Survey Type). |
| 12 | CustomField | BeaconFeedback__c | Business_Context__c | Business Context | Created | LongTextArea. Free-text field describing the business context of the client's request. Used on Intelligence surveys. |
| 13 | CustomField | BeaconFeedback__c | Call_Type__c | Call Type | Created | Picklist. The type of customer call that took place (e.g. 121 Training, Webinar, QBR). Used on Customer Call surveys. |
| 14 | CustomField | BeaconFeedback__c | Client_Background__c | Client Background | Created | LongTextArea. Free-text field describing the client's background. Used on Intelligence surveys. |
| 15 | CustomField | BeaconFeedback__c | Comment_On_The_Layout_Appearance__c | Comment On The Layout/Appearance | Created | LongTextArea. Free-text field for any comments the client made about the layout or appearance of Beacon. |
| 16 | CustomField | BeaconFeedback__c | Confident_To_Get_Started_With_Beacon__c | Confident To Get Started With Beacon? | Created | Picklist. Records whether the client feels confident to get started with Beacon. Used on Onboarding Call 1 - Kick Off surveys. |
| 17 | CustomField | BeaconFeedback__c | Current_Solution__c | Current Solution | Created | Picklist. The solution the prospect currently uses for this data (e.g. Citeline, Clarivate, GlobalData, Manual). Used on Sales Prospecting surveys. |
| 18 | CustomField | BeaconFeedback__c | Data_Comprehensiveness__c | Data Comprehensiveness (1-5) | Created | Number. The client's rating of how comprehensive Beacon's data is, on a scale of 1 to 5. Limited to 1-5 by the Data_Comprehensiveness validation rule. |
| 19 | CustomField | BeaconFeedback__c | Did_Client_Understand_How_To_Run_Search__c | Did Client Understand How To Run Search | Created | Picklist. Records whether the client understood how to run a search in Beacon. |
| 20 | CustomField | BeaconFeedback__c | Did_They_Recommend_Any_Platform_Changes__c | Did They Recommend Any Platform Changes | Created | LongTextArea. Free-text field for any changes to the Beacon platform the client recommended. |
| 21 | CustomField | BeaconFeedback__c | Disease_Areas_Are_They_Interested_In__c | Disease Areas Are They Interested In? | Created | MultiselectPicklist. The disease areas the client is interested in. If Other is selected, list it in If Disease Area Is Other, List Here. |
| 22 | CustomField | BeaconFeedback__c | Drug_Trial_Pages_Easy_To_Navigate__c | Drug/Trial Pages Easy To Navigate | Created | Picklist. Records whether the client found the drug and trial pages easy to navigate and locate data on. Used on Your Input surveys. |
| 23 | CustomField | BeaconFeedback__c | Due_Date_Days__c | Due Date Days | Created | Number. The number of days used to work out when the survey is due. |
| 24 | CustomField | BeaconFeedback__c | Due_Date__c | Due Date | Created | Date. The date the survey is due to be completed. Survey Notification Date is calculated as 7 days before this date. |
| 25 | CustomField | BeaconFeedback__c | Expressed_Interest_In_Any_Other_Modules__c | Expressed Interest In Any Other Modules? | Created | Picklist. Records whether the client expressed interest in any other Beacon modules. Used on Customer Call and Onboarding Call 1 - Kick Off surveys. |
| 26 | CustomField | BeaconFeedback__c | Expressed_Interest_In_Other_Modules__c | Expressed Interest In Other Modules? | Created | MultiselectPicklist. The other Beacon modules the client has expressed interest in. Used on Onboarding Call 2 - Becoming an Expert surveys. |
| 27 | CustomField | BeaconFeedback__c | Functionality_They_Least_Interested_In__c | Functionality They Least Interested In? | Created | Picklist. The area of Beacon functionality the client is least interested in (Drugs, Trials, Analysis Tab, Deals, Companies). |
| 28 | CustomField | BeaconFeedback__c | Functionality_They_Most_Interested_In__c | Functionality They Most Interested In? | Created | Picklist. The area of Beacon functionality the client is most interested in (Drugs, Trials, Analysis Tab, Deals, Companies). |
| 29 | CustomField | BeaconFeedback__c | Growth_Factors_For_The_Account__c | Growth Factors For The Account? | Created | MultiselectPicklist. The growth factors identified for the account. More than one can be selected. If Other is selected, list it in If Growth Factor Is Other Please List. Used on Sales Demo surveys. |
| 30 | CustomField | BeaconFeedback__c | Has_Completed_The_Onboarding_Checklist__c | Has Completed The Onboarding Checklist? | Created | MultiselectPicklist. The onboarding checklist steps the client has completed (e.g. logged in, conducted a search, saved a search). Used on Onboarding Call 2 - Becoming an Expert surveys. |
| 31 | CustomField | BeaconFeedback__c | Have_Set_Up_Their_Own_Saved_Searches__c | Have Set Up Their Own Saved Searches? | Created | Picklist. Records whether the client has set up their own saved searches. Used on Onboarding Call 2 - Becoming an Expert surveys. |
| 32 | CustomField | BeaconFeedback__c | Have_They_Completed_The_Onboarding__c | Have They Completed The Onboarding? | Created | Picklist. Records whether the client has completed onboarding. Used on Onboarding Call 1 - Kick Off surveys. |
| 33 | CustomField | BeaconFeedback__c | Have_They_Used_The_Milestones_Tool__c | Have They Used The Milestones Tool? | Created | Picklist. Records whether the client has used the Milestones tool. Used on Onboarding Call 2 - Becoming an Expert surveys. |
| 34 | CustomField | BeaconFeedback__c | Have_Used_The_Download_Functionality__c | Have Used The Download Functionality? | Created | Picklist. Records whether the client has used the download functionality. Used on Onboarding Call 2 - Becoming an Expert surveys. |
| 35 | CustomField | BeaconFeedback__c | How_Beacon_Compares_To_Current_Process__c | How Beacon Compares To Current Process? | Created | LongTextArea. Free-text field describing how Beacon compares to the user's current process. Used on Your Input surveys. |
| 36 | CustomField | BeaconFeedback__c | How_Did_They_Find_Onboarding_Process__c | How Did They Find Onboarding Process? | Created | Picklist. The client's overall rating of their Beacon onboarding process, from Very Good to Very Poor. Used on Your Input surveys. |
| 37 | CustomField | BeaconFeedback__c | How_Often_Used_Download_Functionality__c | How Often Used Download Functionality? | Created | Picklist. How often the client has used the download functionality. Used on Onboarding Call 2 - Becoming an Expert surveys. |
| 38 | CustomField | BeaconFeedback__c | How_Often_Used_The_Milestones_Tool__c | How Often Used The Milestones Tool? | Created | Picklist. How often the client has used the Milestones tool. Used on Onboarding Call 2 - Becoming an Expert surveys. |
| 39 | CustomField | BeaconFeedback__c | How_Satisfied_Are_You_With_Support__c | How Satisfied Are You With Support? | Created | Picklist. The client's satisfaction with support from the Beacon Customer Success team, from Very Satisfied to Very Dissatisfied. Used on Your Input surveys. |
| 40 | CustomField | BeaconFeedback__c | How_Useful_Is_Monthly_Digest_Content__c | Rate Monthly Digest’s Usefulness (1-5) | Created | Number. The client's rating of how useful the Monthly Digest content is, on a scale of 1 (not useful) to 5 (extremely useful). Limited to 1-5 by the Monthly_Digest_Content validation rule. Used on Your Input surveys. |
| 41 | CustomField | BeaconFeedback__c | How_User_Friendly_Do_You_Find_Beacon__c | Rate Beacon User Friendliness (1-5) | Created | Number. The client's rating of how user-friendly Beacon is, on a scale of 1 (complex) to 5 (easy). Limited to 1-5 by the User_Friendly_Beacon validation rule. Used on Your Input surveys. |
| 42 | CustomField | BeaconFeedback__c | If_Disease_Area_Is_Other_List_Here__c | If Disease Area Is Other, List Here | Created | TextArea. Lists the disease area when Other is selected in Disease Areas Are They Interested In. |
| 43 | CustomField | BeaconFeedback__c | If_Growth_Factor_Is_Other_Please_List__c | If Growth Factor Is Other Please List | Created | TextArea. Lists the growth factor when Other is selected in Growth Factors For The Account. |
| 44 | CustomField | BeaconFeedback__c | If_Interest_In_New_Module_List_It_Here__c | If Interest In New Module, List It Here | Created | TextArea. Lists any new module the client is interested in. |
| 45 | CustomField | BeaconFeedback__c | If_Risk_Factor_Is_Other_Please_List_Here__c | If Risk Factor Is Other Please List Here | Created | TextArea. Lists the risk factor when Other is selected in What Are Risk Factors For The Account. |
| 46 | CustomField | BeaconFeedback__c | If_There_Was_Missing_Data_What_Was__c | If There Was Missing Data, What Was | Created | TextArea. Describes what data was missing when missing data is identified in Was Any Missing Data Identified. Used on Sales Demo and Your Input surveys. |
| 47 | CustomField | BeaconFeedback__c | If_They_Found_Data_From_Other_Source__c | If They Found Data From Other Source | Created | TextArea. Lists the other source the client found data from. |
| 48 | CustomField | BeaconFeedback__c | If_They_Would_Like_More_Info_List_Here__c | If They Would Like More Info, List Here | Created | TextArea. Lists the sector information the client would like when Would They Like More Information is Yes. |
| 49 | CustomField | BeaconFeedback__c | Is_This_A_Large_Onboarding__c | Is This A Large Onboarding? | Created | Picklist. Records whether this is a large onboarding. Used on Onboarding Call 1 - Kick Off surveys. |
| 50 | CustomField | BeaconFeedback__c | Job_Focus__c | Job Focus | Created | Picklist. The prospect's job focus (Clinical, Commercial, Preclinical, Translational). Used on Sales Prospecting surveys. |
| 51 | CustomField | BeaconFeedback__c | Key_Challenges__c | Key Challenges | Created | Picklist. The prospect's key challenge (e.g. timely, accurate data or benchmarking). Used on Sales Prospecting surveys. |
| 52 | CustomField | BeaconFeedback__c | Main_Functionalities_Most_Valuable__c | Main Functionalities Most Valuable? | Created | LongTextArea. Free-text field for the Beacon functionality the client finds most valuable, and why. Used on Onboarding Call 2 - Becoming an Expert surveys. |
| 53 | CustomField | BeaconFeedback__c | Matched_Use_Cases_Since_Onboarding__c | Matched Use Cases Since Onboarding? | Created | Picklist. Records whether the client's use of Beacon has matched the use cases set at onboarding. Used on Customer Call surveys. |
| 54 | CustomField | BeaconFeedback__c | Milestones__c | Milestones | Created | Picklist. The prospect's latest milestone (Funding, Partnerships, Progressing Asset). Used on Sales Prospecting surveys. |
| 55 | CustomField | BeaconFeedback__c | Modules_Interested_In_SDR_Prospecting__c | Modules Interested In (SDR Prospecting) | Created | Picklist. The Beacon module the prospect is interested in, as recorded by the SDR. Used on Sales Prospecting and Intelligence surveys. |
| 56 | CustomField | BeaconFeedback__c | Next_Steps_Date__c | Next Steps Date | Created | Date. The date of the agreed next steps. Required on Sales Demo surveys when Survey Completed is set to Yes (Next_Steps_Date_Mandatory validation rule). |
| 57 | CustomField | BeaconFeedback__c | Next_Steps__c | Next Steps | Created | LongTextArea. Free-text field for the agreed next steps. Used on Sales Demo surveys. |
| 58 | CustomField | BeaconFeedback__c | Number_Of_Customers_On_Call__c | Number Of Customers On Call | Created | Number. The number of customer attendees on the call. Limited to 1-200 by the Number_Of_Customers_On_Call validation rule. Used on Customer Call and Onboarding Call 1 - Kick Off surveys. |
| 59 | CustomField | BeaconFeedback__c | Opportunity__c | Opportunity | Created | Lookup. The Opportunity this survey is for. Also used to build the Beacon Feedback Name. |
| 60 | CustomField | BeaconFeedback__c | Other_comments__c | Other comments | Created | LongTextArea. Free-text field for any other comments. Used on Intelligence surveys. |
| 61 | CustomField | BeaconFeedback__c | Overall_Demo_Rank__c | Overall Demo Rank (1-5) | Created | Number. The client's overall rating of the demo, on a scale of 1 to 5. Limited to 1-5 by the Overall_Demo_Rank validation rule. |
| 62 | CustomField | BeaconFeedback__c | Overall_Sentiment__c | Overall Sentiment | Created | LongTextArea. Free-text field describing the client's overall sentiment. Used on Customer Call surveys. |
| 63 | CustomField | BeaconFeedback__c | Primary_Use_Cases_For_The_Account__c | Primary Use Cases For The Account? | Created | LongTextArea. Free-text field for the account's primary use cases for Beacon. Used on Intelligence surveys. |
| 64 | CustomField | BeaconFeedback__c | Product_Feedback__c | Product Feedback | Created | LongTextArea. Free-text field for feedback on the Beacon product. Used on Customer Call surveys. |
| 65 | CustomField | BeaconFeedback__c | Proposed_Solution__c | Proposed Solution | Created | LongTextArea. Free-text field describing the solution proposed to the client. Used on Intelligence surveys. |
| 66 | CustomField | BeaconFeedback__c | Prospect_s_Thoughts_On_The_Pricing__c | Prospect's Thoughts On The Pricing? | Created | Picklist. The prospect's view of the pricing (Reasonable, Expensive But Within Expectation, Overpriced, Not Explored). |
| 67 | CustomField | BeaconFeedback__c | Quality_Of_Data__c | Quality Of Data (1-5) | Created | Number. The client's rating of the quality of Beacon's data, on a scale of 1 to 5. Limited to 1-5 by the Quality_Of_Data validation rule. |
| 68 | CustomField | BeaconFeedback__c | ResOps_Feedback__c | ResOps Feedback | Created | LongTextArea. Free-text field for feedback for the Research Operations (ResOps) team. Used on Customer Call surveys. |
| 69 | CustomField | BeaconFeedback__c | Res_Ops_Support__c | Res Ops Support | Created | Text. Text field for the Research Operations (ResOps) support team to use. Used on Sales Demo surveys. |
| 70 | CustomField | BeaconFeedback__c | Research_Questions__c | Research Questions | Created | LongTextArea. Free-text field for the client's research questions. Used on Intelligence surveys. |
| 71 | CustomField | BeaconFeedback__c | SDR_Notes__c | SDR Notes | Created | LongTextArea. Free-text field for the Sales Development Rep's (SDR) notes. Used on Sales Prospecting surveys. |
| 72 | CustomField | BeaconFeedback__c | Satisfied_With_Initial_Kick_Off__c | Satisfied With Initial Kick-Off? | Created | Picklist. Records whether the client was satisfied with the initial kick-off onboarding session. Used on Onboarding Call 2 - Becoming an Expert surveys. |
| 73 | CustomField | BeaconFeedback__c | Satisfied_With_The_Accuracy_Of_Our_Data__c | Satisfied With The Accuracy Of Our Data? | Created | Picklist. Records whether the client was satisfied with the accuracy of Beacon's data. |
| 74 | CustomField | BeaconFeedback__c | Show_Interest_In_Any_Other_Modules__c | Show Interest In Any Other Modules? | Created | MultiselectPicklist. The other Beacon modules or therapy areas the client showed interest in. |
| 75 | CustomField | BeaconFeedback__c | Sourcing_Data_Prior_To_Beacon__c | Sourcing Data Prior To Beacon? | Created | MultiselectPicklist. Where the client sourced their data before Beacon (e.g. PubMed, Google, Clinicaltrials.gov). |
| 76 | CustomField | BeaconFeedback__c | Specific_requirements__c | Specific requirements | Created | LongTextArea. Free-text field for the client's specific requirements. Used on Intelligence surveys. |
| 77 | CustomField | BeaconFeedback__c | Speed_Of_Platform__c | Speed Of Platform (1-5) | Created | Number. The client's rating of the speed of the Beacon platform, on a scale of 1 to 5. Limited to 1-5 by the Speed_Of_Platform validation rule. |
| 78 | CustomField | BeaconFeedback__c | Survey_Completed__c | Survey Completed | Created | Picklist. Records whether the survey has been completed. Setting it to Yes triggers the Any_Further_Feedback_Mandatory (Sales Prospecting) and Next_Steps_Date_Mandatory (Sales Demo) validation rules. |
| 79 | CustomField | BeaconFeedback__c | Survey_Notification_Date__c | Survey Notification Date | Created | Date (Formula). Formula that sets the notification date to 7 days before the Due Date. |
| 80 | CustomField | BeaconFeedback__c | Survey_Notification_Today__c | Survey Notification Today | Created | Checkbox (Formula). Formula that is checked when today is the Survey Notification Date. |
| 81 | CustomField | BeaconFeedback__c | Survey_Type__c | Survey Type | Created | Picklist. The type of survey (e.g. Intelligence, Sales Demo, Customer Call). Also used to build the Beacon Feedback Name. |
| 82 | CustomField | BeaconFeedback__c | Timeliness_and_pricing__c | Timeliness and pricing | Created | LongTextArea. Free-text field for the client's timeline and pricing requirements. Used on Intelligence surveys. |
| 83 | CustomField | BeaconFeedback__c | Topic_Area_of_Interest__c | Topic Area of Interest | Created | LongTextArea. Free-text field for the client's topic area of interest. Used on Intelligence surveys. |
| 84 | CustomField | BeaconFeedback__c | Usability_Of_Platform__c | Usability Of Platform (1-5) | Created | Number. The client's rating of the usability of the Beacon platform, on a scale of 1 to 5. Limited to 1-5 by the Usability_Of_Platform validation rule. |
| 85 | CustomField | BeaconFeedback__c | Was_Any_Missing_Data_Identified__c | Was Any Missing Data Identified? | Created | MultiselectPicklist. The areas where the client identified missing data (Trial, Data with Trial, Drug, Data within Drug, None). Describe it in If There Was Missing Data, What Was. Used on Sales Demo and Your Input surveys. |
| 86 | CustomField | BeaconFeedback__c | What_Are_Risk_Factors_For_The_Account__c | What Are Risk Factors For The Account? | Created | Picklist. The risk factor identified for the account. If Other is selected, list it in If Risk Factor Is Other Please List Here. Used on Sales Demo surveys. |
| 87 | CustomField | BeaconFeedback__c | What_Are_The_User_Personas__c | What Are The User Personas? | Created | Picklist. The client's user persona (e.g. Research Scientist, Clinical, Business Development). Used on Customer Call surveys. |
| 88 | CustomField | BeaconFeedback__c | What_Are_Their_Main_Use_Cases__c | What Are Their Main Use Cases? | Created | LongTextArea. Free-text field for the client's main use cases. Used on Intelligence surveys. |
| 89 | CustomField | BeaconFeedback__c | What_Did_They_Like_Most_About_Beacon__c | What Did They Like Most About Beacon? | Created | LongTextArea. Free-text field for what the client liked most about Beacon. Used on Your Input surveys. |
| 90 | CustomField | BeaconFeedback__c | What_Was_The_Outcome_Of_The_Demo__c | What Was The Outcome Of The Demo? | Created | Picklist. The outcome of the demo, including interest in a paid subscription or founding partnership. Founding Partner question only. Used on Intelligence surveys. |
| 91 | CustomField | BeaconFeedback__c | What_is_AAA_Intelligence_need__c | What is AAA/Intelligence need? | Created | LongTextArea. Free-text field describing the client's AAA/Intelligence need. Used on Customer Call surveys. |
| 92 | CustomField | BeaconFeedback__c | Would_They_Like_More_Information__c | Would They Like More Information? | Created | Picklist. Records whether the client would like more information on the sector as a whole (company info, location data, trends etc.). |
| 93 | RecordType | BeaconFeedback__c | Customer_Call | Customer Call | Created | Record type for Customer Call surveys. |
| 94 | RecordType | BeaconFeedback__c | Intelligence | Intelligence | Created | Market research opportunities feedback |
| 95 | RecordType | BeaconFeedback__c | Onboarding_Call_1_Kick_Off | Onboarding Call 1 - Kick Off | Created | Record type for Onboarding Call 1 - Kick Off surveys. |
| 96 | RecordType | BeaconFeedback__c | Onboarding_Call_2_Becoming_an_Expert | Onboarding Call 2 - Becoming an Expert | Created | Record type for Onboarding Call 2 - Becoming an Expert surveys. |
| 97 | RecordType | BeaconFeedback__c | Sales_Demo | Sales Demo | Created | Record type for Sales Demo surveys. |
| 98 | RecordType | BeaconFeedback__c | Sales_Prospecting | Sales Prospecting | Created | Record type for Sales Prospecting surveys. |
| 99 | RecordType | BeaconFeedback__c | Your_Input | Your Input | Created | Record type for Your Input surveys. |
| 100 | ValidationRule | BeaconFeedback__c | Any_Further_Feedback_Mandatory | Any_Further_Feedback_Mandatory | Created | On Sales Prospecting surveys, requires Any Further Feedback to be filled in when Survey Completed is changed to Yes. Removed the NOT($User.ByPassVR__c) bypass. |
| 101 | ValidationRule | BeaconFeedback__c | Data_Comprehensiveness | Data_Comprehensiveness | Created | Makes sure Data Comprehensiveness is a number between 1 and 5. |
| 102 | ValidationRule | BeaconFeedback__c | Monthly_Digest_Content | Monthly_Digest_Content | Created | Makes sure the Monthly Digest usefulness rating is a number between 1 and 5. |
| 103 | ValidationRule | BeaconFeedback__c | Next_Steps_Date_Mandatory | Next_Steps_Date_Mandatory | Created | On Sales Demo surveys, requires Next Steps Date to be filled in when Survey Completed is changed to Yes. |
| 104 | ValidationRule | BeaconFeedback__c | Number_Of_Customers_On_Call | Number_Of_Customers_On_Call | Created | Makes sure Number Of Customers On Call is a number between 1 and 200. |
| 105 | ValidationRule | BeaconFeedback__c | Overall_Demo_Rank | Overall_Demo_Rank | Created | Makes sure Overall Demo Rank is a number between 1 and 5. |
| 106 | ValidationRule | BeaconFeedback__c | Quality_Of_Data | Quality_Of_Data | Created | Makes sure Quality Of Data is a number between 1 and 5. |
| 107 | ValidationRule | BeaconFeedback__c | Speed_Of_Platform | Speed_Of_Platform | Created | Makes sure Speed Of Platform is a number between 1 and 5. |
| 108 | ValidationRule | BeaconFeedback__c | Usability_Of_Platform | Usability_Of_Platform | Created | Makes sure Usability Of Platform is a number between 1 and 5. |
| 109 | ValidationRule | BeaconFeedback__c | User_Friendly_Beacon | User_Friendly_Beacon | Created | Makes sure the Beacon user-friendliness rating is a number between 1 and 5. |
| 110 | Layout | BeaconFeedback__c | BeaconFeedback__c-Beacon Feedback Layout | Beacon Feedback Layout | Created | Default layout for Beacon Feedback records. |
| 111 | Layout | BeaconFeedback__c | BeaconFeedback__c-Customer Call | Customer Call | Created | Page layout for the Customer Call survey. |
| 112 | Layout | BeaconFeedback__c | BeaconFeedback__c-Intelligence Feedback Layout | Intelligence Feedback Layout | Created | Page layout for the Intelligence survey. |
| 113 | Layout | BeaconFeedback__c | BeaconFeedback__c-Onboarding Call 1 - Kick Off | Onboarding Call 1 - Kick Off | Created | Page layout for the Onboarding Call 1 - Kick Off survey. |
| 114 | Layout | BeaconFeedback__c | BeaconFeedback__c-Onboarding Call 2 - Becoming an Expert | Onboarding Call 2 - Becoming an Expert | Created | Page layout for the Onboarding Call 2 - Becoming an Expert survey. |
| 115 | Layout | BeaconFeedback__c | BeaconFeedback__c-Sales Demo | Sales Demo | Created | Page layout for the Sales Demo survey. |
| 116 | Layout | BeaconFeedback__c | BeaconFeedback__c-Sales Prospecting | Sales Prospecting | Created | Page layout for the Sales Prospecting survey. |
| 117 | Layout | BeaconFeedback__c | BeaconFeedback__c-Your Input | Your Input | Created | Page layout for the Your Input survey. |
| 118 | CustomField | User | ByPassVR__c | ByPassVR | Deleted | Checkbox that let a user skip validation rules. Removed along with its only reference in Any_Further_Feedback_Mandatory. |
