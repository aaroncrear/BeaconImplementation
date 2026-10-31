# "Account-Domain-Automation" – Release Notes

## Requirements

The `Domain` field on Account (`Domain__c`) is matched against the `Email Domain` field on Lead to relate Leads to Accounts (see `Lead - On Create - After Save`). It was a manual field, so it was often blank and Leads did not match. The business need was:

- When an Account is created, set `Domain` from the `Website` field: everything after `www.`.
- When the `Website` on an existing Account changes, set `Domain` again the same way.
- Keep `Domain` as an editable text field set by automation, not a formula, so users can overwrite it manually.
- Update the description of the `Domain` field to explain that it is set by automation.

## Release Notes

Two record-triggered **before-save** flows were added on Account. Before-save was used because the flows only update a field on the record being saved, which needs no extra DML and runs faster than an after-save update.

### Account - On Create - Before Save (`Account_On_Create_Before_Save`)

- **Runs when:** an Account is created, the On/Off Switch `Run Flows` setting is on, `Website` is not blank and `Domain` is blank.
- **Does:** one assignment, `Assign Domain from Website`, sets `Domain__c` to the `formDomain` formula.
- A `Domain` typed in by the user when creating the Account is kept, not overwritten.

### Account - On Update - Before Save (`Account_On_Update_Before_Save`)

- **Runs when:** an Account is updated, the On/Off Switch `Run Flows` setting is on, `Website` changed on this save, and the new `Website` is not blank.
- **Does:** the same `Assign Domain from Website` assignment.
- Editing `Domain` alone does not start the flow, so manual overwrites stick until the `Website` changes again.
- If `Website` is cleared, `Domain` is left as it was rather than blanked.

### How the domain is worked out

Both flows use the same three formulas, which build on each other:

1. `formWebsiteNoProtocol` trims spaces and removes any protocol, such as `https://` or `http://`.
2. `formWebsiteNoWww` removes a leading `www.` (any case). A website with no `www.` is used as it is, so `acme.com` still gives `acme.com`.
3. `formDomain` removes anything from the first `/`, `?`, `#` or `:` (page path, query string, anchor or port) and makes the result lower case.

This goes slightly further than "everything after `www.`": a website such as `https://www.acme.com/about` gives `acme.com`, which matches a Lead email of `jane@acme.com`, instead of `acme.com/about`, which would never match.

| Website | Domain |
|---------|--------|
| `www.acme.com` | `acme.com` |
| `https://www.Acme.com/about-us` | `acme.com` |
| `http://acme.co.uk` | `acme.co.uk` |
| `acme.com` | `acme.com` |
| `www.acme.com:8080/home?x=1` | `acme.com` |

Both flows check the On/Off Switch (`{!$Setup.On_Off_Switch__c.Run_Flows__c}`) in their entry formula, as all new flows should.

### Domain field description

The description of `Account.Domain__c` was changed to:

> Used in automation to match Leads to Accounts based on this field and the Email Domain field on Leads. This field gets set via automation based on the value from the website. It is automated and not a formula to allow manual overwrites.

No change was made to the field's type, length, page layout placement or field-level security.

## Acceptance Criteria

1. **Create with `www.`:** Create an Account with Website `www.acme-test.com` and Domain blank. Save. Confirm Domain is `acme-test.com`.
2. **Create with protocol and path:** Create an Account with Website `https://www.Acme-Test2.com/about`. Save. Confirm Domain is `acme-test2.com`.
3. **Create without `www.`:** Create an Account with Website `acme-test3.com`. Save. Confirm Domain is `acme-test3.com`.
4. **Create with a manual Domain:** Create an Account with Website `www.acme-test4.com` and Domain `manual.com`. Save. Confirm Domain stays `manual.com`.
5. **Create without a Website:** Create an Account with no Website. Save. Confirm Domain is blank.
6. **Website changed:** On the Account from test 1, change Website to `www.new-acme.com`. Save. Confirm Domain is `new-acme.com`.
7. **Manual overwrite:** On the same Account, change only Domain to `override.com`. Save. Confirm Domain stays `override.com`.
8. **Other edits:** On the same Account, change a field other than Website (such as Phone). Save. Confirm Domain stays `override.com`.
9. **Website cleared:** On the same Account, clear Website. Save. Confirm Domain is unchanged.
10. **On/Off Switch:** Set `Run Flows` to unchecked on an On/Off Switch record for your user. Create an Account with Website `www.switch-test.com`. Confirm Domain is blank. Check `Run Flows` again afterwards.
11. **Lead match:** Create an Account with Website `https://www.lead-match-test.com`. Confirm Domain is `lead-match-test.com`. Create a Lead with Email `jane@lead-match-test.com`. Confirm the Lead's Account field is set to that Account.

## Post Deployment Items

- **Optional backfill of existing Accounts:** the flows only run on create or when Website changes, so existing Accounts with a Website and a blank Domain are not filled in. To fill them in, export Accounts where `Website` is not blank and `Domain__c` is blank, and run an update that sets `Website` to a changed value, or populate `Domain__c` directly in the data load. Confirm with the business before overwriting any Domain values that already exist.

## Component Manifest

Github Branch: [Account-Domain-Automation](https://github.com/aaroncrear/BeaconImplementation/tree/Account-Domain-Automation)

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Flow | Account | Account_On_Create_Before_Save | Account - On Create - Before Save | Created | Before-save flow that sets Domain from the Website when an Account is created with a Website and no Domain. |
| 2 | Flow | Account | Account_On_Update_Before_Save | Account - On Update - Before Save | Created | Before-save flow that sets Domain from the Website when the Website changes to a non-blank value. |
| 3 | Custom Field | Account | Domain__c | Domain | Updated | Description updated to explain that the field is set by automation from the Website and can be overwritten manually. |
