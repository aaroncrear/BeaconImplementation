# "Campaign-Primary-Module-Rebuild" – Release Notes

## Requirements

- The Campaign **Primary Module** picklist (`Campaign.Primary_Module__c`) must use the shared **Primary Module** global value set (`Primary_Module`), the same one used by `Opportunity.Primary_Module__c` and `Campaign.Related_Modules__c`. Module values should be managed in one place.
- The rebuilt field keeps the name **Primary Module**, both the label and the API name `Primary_Module__c`.
- It keeps the same field-level security as the existing field.
- It stays in the same spot on the **Beacon Parent Campaign Record Page** and **Beacon Sub Campaign Record Page** Lightning pages.
- The **Campaign - On Create - Before Save** flow must copy the rebuilt field from the Parent Campaign to the Sub Campaign.
- Add a new module value, **AI**, to the Primary Module global value set. Make it available on every record type, and keep the value set in alphabetical order.

## Release Notes

- **Why the old field is renamed.** Salesforce can't switch an existing picklist from a local list of values to a global value set, and two fields can't share an API name. So before deployment, the existing field is renamed in Setup to `Primary_Module_Legacy__c` (label "Primary Module (Legacy)"). That frees up `Primary_Module__c` for the rebuilt field. Renaming, rather than deleting, keeps the existing data and field-level security on the legacy field so the data can be migrated.
- **Rebuilt field `Campaign.Primary_Module__c` (label "Primary Module").** A restricted picklist that uses the `Primary_Module` global value set, matching `Opportunity.Primary_Module__c`.
- **Legacy field `Campaign.Primary_Module_Legacy__c` (label "Primary Module (Legacy)").** This is the old field after the rename, with its original local values. It's in source only so the repo matches the org, and it's kept only until data migration is done.
- **Record types.** On the Parent Campaign and Sub Campaign record types, `Primary_Module__c` now offers all 25 active global value set values. That includes **Allogeneic**, which was never on the old field's local list, and the new **AI** value. The old field's values are now listed under `Primary_Module_Legacy__c`.
- **Lightning pages, page layout and flow.** These already reference `Primary_Module__c`, so their source is unchanged. They still have to be deployed with this build. When the old field is renamed in Setup, Salesforce moves the page and layout references with it to `Primary_Module_Legacy__c`. Redeploying these components points them back to the rebuilt field in the same position, with the same behavior:
  - editable on the Parent Campaign page;
  - read-only on the Sub Campaign page (the value comes from the parent via the flow);
  - in the same slot on `Campaign Layout`, which drives the New/Edit modal.
  - The flow's `Update Sub Campaign Primary Module` assignment copies `Primary_Module__c` from the Parent Campaign again.
- **Field-level security.** Copied from the org's current FLS on the old field:
  - **Read/Edit:** Beacon Marketing and Beacon Salesforce Admin Object/Tab/FLS permission sets.
  - **Read only:** Beacon Consulting, Customer Success, Executive, Product, ResOps, Sales and Tech Object/Tab/FLS permission sets.
  - The legacy field keeps its existing FLS through the rename.
- **New "AI" value.** Added **AI** (API name `AI`) to the `Primary_Module` global value set. The set is sorted manually (`sorted` = false), so it was reordered alphabetically, ignoring case: AI now sits between ADC and Allogeneic. This also fixed one existing out-of-order pair, so **Gene Therapy** now comes before **General**. AI is enabled on every record type for every field that uses the set:
  - Campaign Parent Campaign and Sub Campaign record types: `Primary_Module__c` and `Related_Modules__c`.
  - Opportunity Consulting, Subscription New and Subscription Renewal record types: `Primary_Module__c`.

### Deployment Steps

1. **Pre-deployment (manual, in the target org):**
   1. Go to Setup > Object Manager > Campaign > Fields & Relationships and edit **Primary Module** (`Primary_Module__c`).
   2. Change **Field Label** to `Primary Module (Legacy)` and **Field Name** to `Primary_Module_Legacy`, then save.
   3. If Salesforce blocks the rename because the field is in use, first deactivate the **Campaign - On Create - Before Save** flow, do the rename, and let the deployment reactivate the flow.
2. **Deploy this branch.** Include every component in the manifest below.

## Acceptance Criteria

1. **Field setup:** In Setup > Object Manager > Campaign > Fields & Relationships, open **Primary Module** (`Primary_Module__c`). Confirm the Values section says it uses the **Primary Module** global value set. Confirm **Primary Module (Legacy)** (`Primary_Module_Legacy__c`) also exists.
2. **Value set order:** In Setup > Picklist Value Sets, open **Primary Module**. Confirm **AI** is listed and every value is in alphabetical order (ADC, AI, Allogeneic, … Gene Therapy, General, … Targeted Radiopharmaceuticals, TPD).
3. **Record type values:** Open the Parent Campaign and Sub Campaign record types. Confirm **Primary Module** lists all 25 active values from the global value set, including Allogeneic and AI. Confirm **Related Modules** also includes AI.
4. **Parent Campaign page:** As a Marketing user, open a Parent Campaign. Confirm **Primary Module** (not the Legacy field) shows in the same position as before and can be edited. Set it to a value and save.
5. **New Campaign modal:** As a Marketing user, click New on Campaigns and choose Parent Campaign. Confirm **Primary Module** is in the form and shows the global value set values. Save with a value picked.
6. **Sub Campaign flow:** Confirm **Campaign - On Create - Before Save** is active. Create a Sub Campaign whose Parent Campaign is the record from step 4 or 5. Confirm the Sub Campaign's **Primary Module** matches the parent's value after save.
7. **Sub Campaign page:** On the Sub Campaign from step 6, confirm **Primary Module** shows in the same position as before and is read-only.
8. **No parent:** Create a Sub Campaign with no Parent Campaign. Confirm the save succeeds and **Primary Module** stays blank.
9. **FLS, read only:** As a Sales (or Consulting, Customer Success, Executive, Product, ResOps or Tech) user, open a Parent Campaign. Confirm **Primary Module** is visible but can't be edited.
10. **FLS, edit:** As a Salesforce Admin user, confirm **Primary Module** can be viewed and edited.
11. **Opportunity AI value:** Open or create an Opportunity for each record type (Consulting, Subscription New, Subscription Renewal). Confirm **AI** can be picked in **Primary Module**.

## Post Deployment Items

1. **Migrate existing data.** Copy values from `Primary_Module_Legacy__c` to `Primary_Module__c` on existing Campaign records, for example with Data Loader or a one-time flow. The values' API names match the global value set. The exception is **Adoptive Cell**, which is inactive on the old field and isn't in the global value set. Decide how to map any records that still hold it.
2. **Reports and list views.** Reports, list views and dashboards that used the old field follow it to `Primary_Module_Legacy__c` after the rename. Repoint them to `Primary_Module__c`.
3. **Retire the legacy field.** After the data is migrated and confirmed, delete `Campaign.Primary_Module_Legacy__c` in the org and remove it and its record type entries from source.

## Component Manifest

Github Branch: https://github.com/aaroncrear/BeaconImplementation/tree/Campaign-Primary-Module-Rebuild

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | CustomField | Campaign | Primary_Module_Legacy__c | Primary Module (Legacy) | Updated | Old local-value-set field, renamed from `Primary_Module__c` in Setup before deployment. Kept for data migration. |
| 2 | CustomField | Campaign | Primary_Module__c | Primary Module | Created | Rebuilt restricted picklist using the `Primary_Module` global value set. |
| 3 | GlobalValueSet | N/A | Primary_Module | Primary Module | Updated | Added the AI value and reordered the values alphabetically (Gene Therapy now before General). |
| 4 | RecordType | Campaign | Parent_Campaign | Parent Campaign | Updated | `Primary_Module__c` gets all active global value set values; old values moved to `Primary_Module_Legacy__c`; AI added to `Related_Modules__c`. |
| 5 | RecordType | Campaign | Sub_Campaign | Sub Campaign | Updated | `Primary_Module__c` gets all active global value set values; old values moved to `Primary_Module_Legacy__c`; AI added to `Related_Modules__c`. |
| 6 | RecordType | Opportunity | Consulting | Consulting | Updated | Added AI to `Primary_Module__c`. |
| 7 | RecordType | Opportunity | Subscription_New | Subscription New | Updated | Added AI to `Primary_Module__c`. |
| 8 | RecordType | Opportunity | Subscription_Renewal | Subscription Renewal | Updated | Added AI to `Primary_Module__c`. |
| 9 | FlexiPage | Campaign | Beacon_Parent_Campaign_Record_Page | Beacon Parent Campaign Record Page | Updated | No source change. Redeploy to point the field back to the rebuilt `Primary_Module__c` after the rename (editable). |
| 10 | FlexiPage | Campaign | Beacon_Sub_Campaign_Record_Page | Beacon Sub Campaign Record Page | Updated | No source change. Redeploy to point the field back to the rebuilt `Primary_Module__c` after the rename (read-only). |
| 11 | Layout | Campaign | Campaign-Campaign Layout | Campaign Layout | Updated | No source change. Redeploy to point the field back to the rebuilt `Primary_Module__c` after the rename. |
| 12 | Flow | Campaign | Campaign_On_Create_Before_Save | Campaign - On Create - Before Save | Updated | No source change. Redeploy so the parent-to-sub copy uses the rebuilt `Primary_Module__c` and the flow is active. |
| 13 | PermissionSet | Campaign | Beacon_Marketing_Object_Tab_FLS | Beacon Marketing Object/Tab/FLS | Updated | Read/Edit on `Campaign.Primary_Module__c`. |
| 14 | PermissionSet | Campaign | Beacon_Salesforce_Admin_Object_Tab_FLS | Beacon Salesforce Admin Object/Tab/FLS | Updated | Read/Edit on `Campaign.Primary_Module__c`. |
| 15 | PermissionSet | Campaign | Beacon_Consulting_Object_Tab_FLS | Beacon Consulting Object/Tab/FLS | Updated | Read on `Campaign.Primary_Module__c`. |
| 16 | PermissionSet | Campaign | Beacon_Customer_Success_Object_Tab_FLS | Beacon Customer Success Object/Tab/FLS | Updated | Read on `Campaign.Primary_Module__c`. |
| 17 | PermissionSet | Campaign | Beacon_Executive_Object_Tab_FLS | Beacon Executive Object/Tab/FLS | Updated | Read on `Campaign.Primary_Module__c`. |
| 18 | PermissionSet | Campaign | Beacon_Product_Object_Tab_FLS | Beacon Product Object/Tab/FLS | Updated | Read on `Campaign.Primary_Module__c`. |
| 19 | PermissionSet | Campaign | Beacon_ResOps_Object_Tab_FLS | Beacon ResOps Object/Tab/FLS | Updated | Read on `Campaign.Primary_Module__c`. |
| 20 | PermissionSet | Campaign | Beacon_Sales_Object_Tab_FLS | Beacon Sales Object/Tab/FLS | Updated | Read on `Campaign.Primary_Module__c`. |
| 21 | PermissionSet | Campaign | Beacon_Tech_Object_Tab_FLS | Beacon Tech Object/Tab/FLS | Updated | Read on `Campaign.Primary_Module__c`. |
