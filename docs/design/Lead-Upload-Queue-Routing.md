# Lead Uploader – Partner Queue Routing (Design Idea)

**Status:** Design only. Not built. Today, Leads created by the Lead Uploader are owned by the user who uploaded them (see `docs/release-notes/Experience-Cloud-Lead-Upload.md`).

## Goal

Assign uploaded Leads to a queue instead of the uploading partner user, so the right queue is chosen from **which partner** is uploading. Onboarding a new partner should be configuration only, with no code change.

## Proposed routing

Worked out on the server when an upload starts, from the running user (never from the browser, so a partner can't route Leads to another partner's queue):

1. If the user's partner Account has **Lead Upload Queue** (`Account.Lead_Upload_Queue__c`, a queue API name) set, use that queue.
2. Otherwise use **Default Queue** on a **Lead Upload Setting** custom metadata record (`Lead_Upload_Setting__mdt`, record `Default`), e.g. a new **Partner Leads** queue. This also covers internal uploaders.
3. If neither is set, the uploader keeps the Leads (today's behaviour).

Queue API names rather than Ids keep the configuration valid across sandboxes and production. If a configured queue doesn't exist or doesn't support Leads, block the upload before any Lead is created, with a "contact your administrator" message. Save the chosen queue on the Lead Upload record and reuse it for every batch, so a configuration change mid-upload can't split a list.

## Proposed components

| Component | Purpose |
|---|---|
| `Account.Lead_Upload_Queue__c` (Text 80) | Per-partner queue API name, in a "Partner Lead Routing" section on the Account Layout. Edit access for the Salesforce Admin persona only. |
| `Lead_Upload_Setting__mdt` with `Default_Queue__c`, `Share_With_Uploader__c` | Org-wide default queue, and whether partners keep read access after hand-off. |
| `Partner_Leads` queue (Lead) | Default destination. |
| `Lead.Partner_Account__c` and `Lead_Upload__c.Partner_Account__c` (lookups to Account) | Stamp each Lead and upload with the submitting partner, for reporting and future sharing rules. |
| `Lead_Upload__c.Assigned_Queue__c` (Text 80) | Records where the upload's Leads went. |
| `LeadUploadRouting` Apex class (`without sharing`) | Resolves and validates the route, and shares queue-owned Leads back to the uploader. |

## Implementation notes

- **Ownership:** partner users can't assign records to a queue. The controller would check the uploader's create access and field-level security on the file's values (`Security.stripInaccessible`), then insert in system mode with Owner and Partner Account set by the server.
- **Partner visibility:** partners can't see queue-owned Leads. One option is a manual Read share back to the uploader, switchable through `Share_With_Uploader__c`. Salesforce removes manual shares when a rep takes ownership. Long-term visibility would need a sharing rule per partner on Partner Account.
- **Testing:** HTCDEV has no Partner Community licences, so tests would need hooks that stand in for the partner Account and the user type.

## Alternative considered: Lead assignment rules

HTCDEV has no Lead assignment rules today. Salesforce allows only one active rule per object, and it also governs web-to-lead and manually created Leads. Routing by partner would need a rule entry for each partner. It's workable, but it couples this feature to org-wide Lead routing.

## Open questions

1. Which queue(s), and who should be members?
2. Should partners keep seeing their Leads after a rep takes ownership?
3. One queue per partner, or a shared queue with partner-based reporting?
