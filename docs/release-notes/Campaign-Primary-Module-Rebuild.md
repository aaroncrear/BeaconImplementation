# "Campaign-Primary-Module-Rebuild" – Release Notes

## Requirements

- The Campaign **Primary Module** picklist (`Campaign.Primary_Module__c`) must use the shared **Primary Module** global value set (`Primary_Module`), the same one used by `Opportunity.Primary_Module__c` and `Campaign.Related_Modules__c`. Module values should be managed in one place.
- The existing field has its own local list of values and can't be changed in place to point at a global value set. A replacement field is needed.
- The replacement field must have the same field-level security as the existing field.
- The replacement field must sit in the same spot on the **Beacon Parent Campaign Record Page** and **Beacon Sub Campaign Record Page** Lightning pages.
- The **Campaign - On Create - Before Save** flow must copy the new field from the Parent Campaign to the Sub Campaign, not the old one.
- Add a new module value, **AI**, to the Primary Module global value set. Make it available on every record type, and keep the value set in alphabetical order.

## Release Notes

- **New field `Campaign.Beacon_Primary_Module__c` (label "Primary Module").** A restricted picklist that uses the `Primary_Module` global value set, matching `Opportunity.Primary_Module__c`. Salesforce doesn't let a local picklist be switched to a global value set, and the API name `Primary_Module__c` is still in use on Campaign, so the new field follows the `Beacon_` prefix already used by `Beacon_Module_Family__c`. The label is still "Primary Module" so users see the same name.
- **Record types.** The Parent Campaign and Sub Campaign record types now make all 25 active global value set values available on the new field. This includes **Allogeneic**, which is in the global value set but was never on the old field's local list, and the new **AI** value.
- **Lightning pages.** On both Beacon Campaign record pages, the Dynamic Forms field was swapped in place, so the new field sits exactly where the old one was. It keeps the same UI behavior: editable on the Parent Campaign page, read-only on the Sub Campaign page (its value comes from the parent via the flow).
- **Page layout.** `Campaign Layout` also had `Primary_Module__c` in the same slot, and it swaps to the new field there too. The layout drives the New/Edit Campaign modal, so without this change users couldn't set the new field when creating a Parent Campaign.
- **Flow.** The `Update Sub Campaign Primary Module` assignment in **Campaign - On Create - Before Save** now reads `Get_Parent_Campaign.Beacon_Primary_Module__c` and writes `$Record.Beacon_Primary_Module__c`. Nothing else in the flow changed.
- **Field-level security.** Copied from the org's current FLS on `Campaign.Primary_Module__c`:
  - **Read/Edit:** Beacon Marketing and Beacon Salesforce Admin Object/Tab/FLS permission sets.
  - **Read only:** Beacon Consulting, Customer Success, Executive, Product, ResOps, Sales and Tech Object/Tab/FLS permission sets.
  - The Salesforce-managed `sfdc_slack` and `sfdc_a360_sfcrm_data_extract` permission sets also grant read on the old field. They are system managed and are left out of this build.
- **New "AI" value.** Added **AI** (API name `AI`) to the `Primary_Module` global value set. The set is sorted manually (`sorted` = false), so it was reordered alphabetically, ignoring case: AI now sits between ADC and Allogeneic. This also fixed one existing out-of-order pair, so **Gene Therapy** now comes before **General**. AI is enabled on every record type for every field that uses the set:
  - Campaign Parent Campaign and Sub Campaign record types: `Beacon_Primary_Module__c` and `Related_Modules__c`.
  - Opportunity Consulting, Subscription New and Subscription Renewal record types: `Primary_Module__c`.
- **The old field is not deleted** in this build. That leaves time to migrate existing data (see Post Deployment Items) before it is removed.

## Acceptance Criteria

1. **Field setup:** In Setup > Object Manager > Campaign > Fields & Relationships, open **Primary Module** (`Beacon_Primary_Module__c`). Confirm the Values section says it uses the **Primary Module** global value set.
2. **Value set order:** In Setup > Picklist Value Sets, open **Primary Module**. Confirm **AI** is listed and every value is in alphabetical order (ADC, AI, Allogeneic, … Gene Therapy, General, … Targeted Radiopharmaceuticals, TPD).
3. **Record type values:** Open the Parent Campaign and Sub Campaign record types. Confirm **Primary Module** (`Beacon_Primary_Module__c`) lists all 25 active values from the global value set, including Allogeneic and AI. Confirm **Related Modules** also includes AI.
4. **Parent Campaign page:** As a Marketing user, open a Parent Campaign. Confirm **Primary Module** shows in the same position as before and can be edited. Set it to a value and save.
5. **New Campaign modal:** As a Marketing user, click New on Campaigns and choose Parent Campaign. Confirm **Primary Module** is in the form and shows the global value set values. Save with a value picked.
6. **Sub Campaign flow:** Create a Sub Campaign whose Parent Campaign is the record from step 4 or 5. Confirm the Sub Campaign's **Primary Module** matches the parent's value after save.
7. **Sub Campaign page:** On the Sub Campaign from step 6, confirm **Primary Module** shows in the same position as before and is read-only.
8. **No parent:** Create a Sub Campaign with no Parent Campaign. Confirm the save succeeds and **Primary Module** stays blank.
9. **FLS, read only:** As a Sales (or Consulting, Customer Success, Executive, Product, ResOps or Tech) user, open a Parent Campaign. Confirm **Primary Module** is visible but can't be edited.
10. **FLS, edit:** As a Salesforce Admin user, confirm **Primary Module** can be viewed and edited.
11. **Opportunity AI value:** Open or create an Opportunity for each record type (Consulting, Subscription New, Subscription Renewal). Confirm **AI** can be picked in **Primary Module**.

## Post Deployment Items

1. **Migrate existing data.** Copy values from `Primary_Module__c` to `Beacon_Primary_Module__c` on existing Campaign records, for example with Data Loader or a one-time flow. The values' API names match the global value set. The exception is **Adoptive Cell**, which is inactive on the old field and isn't in the global value set. Decide how to map any records that still hold it.
2. **Reports and list views.** Update any reports, report types, list views or dashboards that reference the old `Campaign.Primary_Module__c` so they point to the new field.
3. **Retire the old field.** After the data is migrated and confirmed, delete `Campaign.Primary_Module__c` (or relabel it, e.g. "Primary Module (Legacy)", until it's deleted). Until then both fields are labeled "Primary Module".

## Component Manifest

Github Branch: https://github.com/aaroncrear/BeaconImplementation/tree/Campaign-Primary-Module-Rebuild

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | CustomField | Campaign | Beacon_Primary_Module__c | Primary Module | Created | Restricted picklist using the `Primary_Module` global value set. Replaces `Primary_Module__c`. |
| 2 | RecordType | Campaign | Parent_Campaign | Parent Campaign | Updated | Added all active global value set values for `Beacon_Primary_Module__c`; added AI to `Related_Modules__c`. |
| 3 | RecordType | Campaign | Sub_Campaign | Sub Campaign | Updated | Added all active global value set values for `Beacon_Primary_Module__c`; added AI to `Related_Modules__c`. |
| 4 | FlexiPage | Campaign | Beacon_Parent_Campaign_Record_Page | Beacon Parent Campaign Record Page | Updated | Swapped `Primary_Module__c` for `Beacon_Primary_Module__c` in the same position (editable). |
| 5 | FlexiPage | Campaign | Beacon_Sub_Campaign_Record_Page | Beacon Sub Campaign Record Page | Updated | Swapped `Primary_Module__c` for `Beacon_Primary_Module__c` in the same position (read-only). |
| 6 | Layout | Campaign | Campaign-Campaign Layout | Campaign Layout | Updated | Swapped `Primary_Module__c` for `Beacon_Primary_Module__c` in the same position so the New/Edit modal uses the new field. |
| 7 | Flow | Campaign | Campaign_On_Create_Before_Save | Campaign - On Create - Before Save | Updated | The assignment now copies `Beacon_Primary_Module__c` from the Parent Campaign to the Sub Campaign. |
| 8 | PermissionSet | Campaign | Beacon_Marketing_Object_Tab_FLS | Beacon Marketing Object/Tab/FLS | Updated | Read/Edit on `Campaign.Beacon_Primary_Module__c`. |
| 9 | PermissionSet | Campaign | Beacon_Salesforce_Admin_Object_Tab_FLS | Beacon Salesforce Admin Object/Tab/FLS | Updated | Read/Edit on `Campaign.Beacon_Primary_Module__c`. |
| 10 | PermissionSet | Campaign | Beacon_Consulting_Object_Tab_FLS | Beacon Consulting Object/Tab/FLS | Updated | Read on `Campaign.Beacon_Primary_Module__c`. |
| 11 | PermissionSet | Campaign | Beacon_Customer_Success_Object_Tab_FLS | Beacon Customer Success Object/Tab/FLS | Updated | Read on `Campaign.Beacon_Primary_Module__c`. |
| 12 | PermissionSet | Campaign | Beacon_Executive_Object_Tab_FLS | Beacon Executive Object/Tab/FLS | Updated | Read on `Campaign.Beacon_Primary_Module__c`. |
| 13 | PermissionSet | Campaign | Beacon_Product_Object_Tab_FLS | Beacon Product Object/Tab/FLS | Updated | Read on `Campaign.Beacon_Primary_Module__c`. |
| 14 | PermissionSet | Campaign | Beacon_ResOps_Object_Tab_FLS | Beacon ResOps Object/Tab/FLS | Updated | Read on `Campaign.Beacon_Primary_Module__c`. |
| 15 | PermissionSet | Campaign | Beacon_Sales_Object_Tab_FLS | Beacon Sales Object/Tab/FLS | Updated | Read on `Campaign.Beacon_Primary_Module__c`. |
| 16 | PermissionSet | Campaign | Beacon_Tech_Object_Tab_FLS | Beacon Tech Object/Tab/FLS | Updated | Read on `Campaign.Beacon_Primary_Module__c`. |
| 17 | GlobalValueSet | N/A | Primary_Module | Primary Module | Updated | Added the AI value and reordered the values alphabetically (Gene Therapy now before General). |
| 18 | RecordType | Opportunity | Consulting | Consulting | Updated | Added AI to `Primary_Module__c`. |
| 19 | RecordType | Opportunity | Subscription_New | Subscription New | Updated | Added AI to `Primary_Module__c`. |
| 20 | RecordType | Opportunity | Subscription_Renewal | Subscription Renewal | Updated | Added AI to `Primary_Module__c`. |
