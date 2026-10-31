# "Account-Domain-Automation" – Release Notes

## Requirements

The `Domain` field on Account (`Domain__c`) is matched against the `Email Domain` field on Lead to relate Leads to Accounts (see `Lead - On Create - After Save`). It was a manual field, so it was often blank and Leads did not match. The business need was:

- When an Account is created, set `Domain` from the `Website` field: everything after `www.`.
- When the `Website` on an existing Account changes, set `Domain` again the same way.
- Keep `Domain` as an editable text field set by automation, not a formula, so users can overwrite it manually.
- Update the description of the `Domain` field to explain that it is set by automation.
- When the `Country` on a Lead changes, try again to relate the Lead to an Account by matching its `Email Domain` and `Country`, as `Lead - On Create - After Save` does when a Lead is created.
- Fix the domain-only fallback in `Lead - On Create - After Save`, which never related the Lead.

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

### Lead - On Update - After Save (`Lead_On_Update_After_Save`)

A Lead's `Country` is often blank or wrong when the Lead is created and corrected later, so the create flow's Domain + Country match may not have been possible at the time. This new after-save flow re-runs the match when `Country` changes. It is after-save, like the create flow, because it queries Accounts and updates the Lead's `Account__c` lookup.

- **Runs when:** a Lead is updated, the On/Off Switch `Run Flows` setting is on, `Country` changed on this save, `Email Domain` is not blank and the Lead is not converted.
- **Pass 1 – Domain + Country:** `Get Matching Account by Domain and Country` finds the first Account whose `Domain__c` equals the Lead's `Email_Domain__c` and whose `BillingCountry` equals the Lead's new `Country`. If one is found and it is not already the Lead's Account, `Update Lead Account` sets `Account__c` to it. This **replaces** an existing Account, because a Domain + Country match is the strongest match available and the Country has just changed.
- **Pass 2 – Domain only:** if pass 1 finds no new match, `Lead Account Blank?` checks whether the Lead has an Account. Only if `Account__c` is blank, `Get Matching Account by Domain Only` finds the first Account with a matching `Domain__c`, ignoring Country, and `Relate Lead to Account` sets `Account__c` to it. A weaker domain-only match never replaces an Account that is already set, whether automation or a user set it.
- If neither pass finds a match, `Account__c` is left as it is. The flow never clears it.
- Both update elements route their fault path to the existing `Fault Path Subflow`, which emails the fault message.
- The flow's own update to `Account__c` does not change `Country`, so it does not re-trigger itself.

The element names, lookups and descriptions mirror `Lead - On Create - After Save`. The only difference is the `Lead Account Blank?` check before the domain-only fallback.

### Lead - On Create - After Save fix (`Lead_On_Create_After_Save`)

In the existing create flow, the `Matching Domain Account Found?` decision checked `Get_Matching_Account_by_Domain_and_Country.Id` instead of `Get_Matching_Account_by_Domain_Only.Id`. The flow only reaches that decision when the Domain + Country lookup found nothing, so the check was always false and the domain-only fallback never related the Lead. The decision now checks `Get_Matching_Account_by_Domain_Only.Id`, and its description names that lookup. Nothing else in the flow changed.

After this fix, a new Lead whose Email Domain matches an Account but whose Country does not (or is blank) is related to the first Account with that Domain, as the flow was originally meant to do.

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
11. **Lead match on create:** Create an Account with Website `https://www.lead-match-test.com`. Confirm Domain is `lead-match-test.com`. Create a Lead with Email `jane@lead-match-test.com`. Confirm the Lead's Account field is set to that Account.
12. **Domain-only match on create:** Create an Account with Website `www.fallback-test.com` and Billing Country `United Kingdom`. Create a Lead with Email `chris@fallback-test.com` and Country `Spain`. Confirm the Lead's Account is set to that Account.

**Lead - On Update - After Save**

Set up two Accounts first: Account A with Website `www.country-test.com` and Billing Country `United Kingdom`, and Account B with Website `www.country-test.com` and Billing Country `United States`. Confirm both have Domain `country-test.com`.

13. **Country change matches Domain + Country:** Create a Lead with Email `sam@country-test.com` and Country `France`. Open the Lead and change Country to `United Kingdom`. Save. Confirm the Lead's Account is Account A.
14. **Country change replaces the Account:** On the same Lead, change Country to `United States`. Save. Confirm the Lead's Account is now Account B.
15. **No Domain + Country match keeps an existing Account:** On the same Lead, change Country to `Germany`. Save. Confirm the Lead's Account is still Account B.
16. **Domain-only fallback:** Create a Lead with Email `alex@country-test.com` and no Country, then clear its Account field if it was set. Change Country to `Germany`. Save. Confirm the Lead's Account is set to Account A or Account B (the first domain match found).
17. **Other edits:** On a Lead with an Account, change a field other than Country (such as Phone). Save. Confirm the Account does not change.
18. **No match:** Create a Lead with Email `pat@no-account-domain.com`. Change its Country. Save. Confirm the Account stays blank and no error appears.
19. **On/Off Switch:** Uncheck `Run Flows` on an On/Off Switch record for your user. Repeat test 13 with a new Lead. Confirm the Account is not set. Check `Run Flows` again afterwards.

## Post Deployment Items

- **Optional backfill of existing Accounts:** the flows only run on create or when Website changes, so existing Accounts with a Website and a blank Domain are not filled in. To fill them in, export Accounts where `Website` is not blank and `Domain__c` is blank, and run an update that sets `Website` to a changed value, or populate `Domain__c` directly in the data load. Confirm with the business before overwriting any Domain values that already exist.

## Component Manifest

Github Branch: [Account-Domain-Automation](https://github.com/aaroncrear/BeaconImplementation/tree/Account-Domain-Automation)

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Flow | Account | Account_On_Create_Before_Save | Account - On Create - Before Save | Created | Before-save flow that sets Domain from the Website when an Account is created with a Website and no Domain. |
| 2 | Flow | Account | Account_On_Update_Before_Save | Account - On Update - Before Save | Created | Before-save flow that sets Domain from the Website when the Website changes to a non-blank value. |
| 3 | Flow | Lead | Lead_On_Update_After_Save | Lead - On Update - After Save | Created | After-save flow that re-matches a Lead to an Account by Email Domain and Country when the Lead's Country changes, with a domain-only fallback when the Lead has no Account. |
| 4 | Flow | Lead | Lead_On_Create_After_Save | Lead - On Create - After Save | Updated | Fixed the Matching Domain Account Found? decision to check the Domain-only lookup, so the domain-only fallback relates the Lead. |
| 5 | Custom Field | Account | Domain__c | Domain | Updated | Description updated to explain that the field is set by automation from the Website and can be overwritten manually. |
