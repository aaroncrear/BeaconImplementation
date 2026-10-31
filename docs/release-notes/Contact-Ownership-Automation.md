# "Contact-Ownership-Automation" – Release Notes

## Requirements

The Contact Owner should always match the Owner of the Contact's Account. The business need was:

- When the Owner of an Account changes, set the Owner of every related Contact to the new Account Owner. This should be added to the existing `Account - On Update - After Save` flow.
- When a Contact is created with an Account, set the Contact Owner to the Account Owner.
- When the Account on a Contact is changed, set the Contact Owner to the new Account's Owner.
- Use before-save flows where possible, otherwise after-save flows.

## Release Notes

Three existing record-triggered flows were updated. No new flows or fields were added.

### Account - On Update - After Save (`Account_On_Update_After_Save`)

This flow has to stay **after-save** because it updates other records (the related Contacts). Before-save flows can only change the record being saved.

- **Entry criteria:** `Account Owner (OwnerId) Is Changed` was added as a fifth condition, so the flow now runs when any compliance field **or** the Owner changes (`1 OR 2 OR 3 OR 4 OR 5`).
- **Contact loop:** a new decision, `Owner Changed?`, runs for each Contact. When the Account Owner changed, a new assignment, `Assign Contact Owner`, sets the Contact's `OwnerId` to the Account's new `OwnerId`. The Contact then goes through the existing `Assign Contact Values` assignment and is added to the same bulk `Update Contacts` element. The Owner is only set when the Account Owner changed, so a compliance-only change does not reset Contact Owners that were set by hand.
- **New decision `Compliance Fields Changed?`:** placed after the Contacts are updated (or after no Contacts were found). Leads and open Opportunities only receive the compliance fields, so when only the Owner changed the flow ends here and skips the Lead and Opportunity queries and updates. When any compliance field changed, the flow continues to the Leads and Opportunities as before.
- When only the Owner changes, the Contacts' compliance fields are still set to the Account's current values in the same update. These are the values the flow already keeps in sync, so no data changes unless a Contact had drifted from its Account.
- Contact updates still route faults to the `Fault Path Subflow`.

Salesforce's standard Change Owner action on Account only moves Contacts owned by the previous Account Owner. This flow moves **all** related Contacts, including ones owned by other users.

### Contact - On Create - Before Save (`Contact_On_Create_Before_Save`)

**Before-save** was used because the flow only changes the Contact being saved, which needs no extra DML.

- **Entry criteria:** changed from `Title Is Null = false` to a formula, `OR(NOT(ISBLANK(Title)), NOT(ISBLANK(AccountId)))`, so the flow now also runs for Contacts created with an Account and no Title.
- **New decision `Title Populated?`:** keeps the existing Seniority Level logic for Contacts with a Title. Contacts without a Title skip it.
- **New decision `Account Populated?`** and assignment **`Assign Contact Owner`:** when the Contact has an Account, sets `OwnerId` to `Account.OwnerId`. The Account Owner is read through the `$Record.Account.OwnerId` relationship, which before-save flows support without a Get Records element.
- Contacts created without an Account keep the Owner they were created with.
- This also applies to Contacts created by Lead conversion, which will be owned by the Account Owner rather than the user who converted the Lead.

### Contact - On Update - Before Save (`Contact_On_Update_Before_Save`)

**Before-save** was used for the same reason.

- **Entry criteria formula:** a third condition was added, `AND(ISCHANGED(AccountId), NOT(ISBLANK(AccountId)))`, so the flow now also runs when the Contact moves to a different Account.
- **New decision `Account Changed?`** and assignment **`Assign Contact Owner`:** placed after the existing Do Not Engage and Title checks. When the Account changed to a non-blank value, sets `OwnerId` to the new Account's Owner.
- Removing the Account from a Contact (clearing `AccountId`) leaves the Owner unchanged.
- Changing only the Contact Owner does not start this logic, so a Contact Owner can still be changed by hand. It will be set again the next time the Contact's Account, or the Account's Owner, changes.
- When the Account flow updates Contact Owners, the Contacts' `AccountId` does not change, so this flow does not run the owner logic again.

### On/Off Switch

These three flows did not check the On/Off Switch (`{!$Setup.On_Off_Switch__c.Run_Flows__c}`) before this change, and it was not added. Adding it would also turn off their existing compliance, Seniority Level and Do Not Engage logic when the switch is off, which is outside the scope of this build.

## Acceptance Criteria

Use two active test users, **User A** and **User B**, who both have access to Accounts and Contacts.

1. **Account Owner change:** Create an Account owned by User A with three Contacts. Set one Contact's Owner to User B by hand. Change the Account Owner to User B. On the Change Owner screen, untick any options to transfer related records. Save. Confirm all three Contacts are now owned by User B.
2. **Account Owner change back:** Change the same Account's Owner back to User A. Confirm all three Contacts are owned by User A.
3. **Owner-only change skips Leads and Opportunities:** On an Account with a related Lead (Account lookup) and an open Opportunity, change only the Account Owner. Confirm the Contacts' Owners change and the Lead and Opportunity `Last Modified Date` do not change.
4. **Compliance still syncs:** On the Account from test 1, check `Do Not Call`. Confirm the related Contacts, Leads and open Opportunities get `Do Not Call` as before, and the Contact Owners do not change.
5. **Compliance change doesn't reset manual Owners:** Set one Contact on the Account to User B by hand. Then uncheck `Do Not Call` on the Account. Confirm that Contact is still owned by User B.
6. **Compliance and Owner together:** Change the Account Owner and check `Email Opt Out` in the same save (for example with inline edit or Data Loader). Confirm the Contacts get both the new Owner and `Email Opt Out`, and the Leads and Opportunities get `Email Opt Out`.
7. **Contact created with an Account:** Logged in as User B (or with the Owner set to User B), create a Contact on an Account owned by User A. Confirm the Contact Owner is User A.
8. **Contact created with an Account and a Title:** Create a Contact with Title `Vice President` on an Account owned by User A. Confirm the Owner is User A and Seniority Level is `VP`.
9. **Contact created without an Account:** Create a Contact with no Account, owned by User B. Confirm the Owner stays User B.
10. **Contact created without a Title:** Create a Contact with an Account and no Title. Confirm the Owner is the Account Owner and Seniority Level is blank.
11. **Contact Account changed:** Move a Contact from an Account owned by User A to an Account owned by User B. Confirm the Contact Owner is User B.
12. **Contact Account cleared:** Clear the Account on a Contact owned by User B. Confirm the Owner stays User B.
13. **Manual Contact Owner change:** On a Contact whose Account is owned by User A, change only the Contact Owner to User B. Confirm the Owner stays User B.
14. **Existing Contact logic:** Change a Contact's Title to `CFO`. Confirm Seniority Level is `Executive` and the Owner does not change. Check `Blacklisted` on a Contact and confirm Status is `Do Not Engage`.
15. **Lead conversion:** Convert a Lead into an existing Account owned by User A while logged in as User B. Confirm the new Contact is owned by User A.
16. **Bulk:** With Data Loader, change the Owner of 200 Accounts that have Contacts. Confirm all of their Contacts get the new Owners and no fault emails are sent.

## Post Deployment Items

- **Optional backfill of existing Contacts:** the flows only run on Contact create, when a Contact's Account changes, or when an Account's Owner changes. Existing Contacts whose Owner does not match their Account Owner are not fixed. To fix them, export Contacts with `Id`, `OwnerId` and `Account.OwnerId` where `AccountId` is not blank, filter to rows where the two Owners differ, set `OwnerId` to `Account.OwnerId` and update them with Data Loader. Confirm with the business before overwriting Contact Owners that were set on purpose.

## Component Manifest

Github Branch: [Contact-Ownership-Automation](https://github.com/aaroncrear/BeaconImplementation/tree/Contact-Ownership-Automation)

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Flow | Account | Account_On_Update_After_Save | Account - On Update - After Save | Updated | Now also runs when the Account Owner changes and sets the Owner of all related Contacts to the new Account Owner. Skips the Lead and Opportunity updates when no compliance field changed. |
| 2 | Flow | Contact | Contact_On_Create_Before_Save | Contact - On Create - Before Save | Updated | Now also runs for Contacts created with an Account and sets the Contact Owner to the Account Owner. Seniority Level logic unchanged. |
| 3 | Flow | Contact | Contact_On_Update_Before_Save | Contact - On Update - Before Save | Updated | Now also runs when the Contact's Account changes to a non-blank value and sets the Contact Owner to the new Account's Owner. |
