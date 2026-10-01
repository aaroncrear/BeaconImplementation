# "claude/trusting-pasteur-37mn40" – Release Notes

## Requirements

Automate lead routing as set out in the **Lead Flow – SF Process – V2** deck (Flow A Marketing Intake &
Conversion, Flow B Lead / Opp Assignment, Flow C Sales Intake & Conversion) and the assignment rules signed
off with Curtis:

- **New Lead Status: Ready to Convert.** When a Demo Request or Active Enquiry comes in, set the Lead to
  this status so the rep knows it is a hot Lead to convert, with an Opportunity, as soon as they start work.
- **New Opportunity Stage: Request for Information.** The first stage before Demo Booked, for genuine
  interest where no demo is booked yet.
- **APAC reps per campaign.** Add an APAC SDR and an APAC AM user lookup to the Parent Campaign. Routing
  pulls in the relevant one.
- **Existing customers (Accounts team).** The AM and SDR are both on the Account Team, and the AM is the
  Account Owner. Every Contact on the Account is owned by the AM. Marketing leads go to the SDR and stay as
  Leads until qualified. Once converted, the Contact owner is the AM. AMs can create Contacts directly. SDRs
  can only create Leads, never Contacts.
- **New business, assigned Accounts.** Same as above. In addition, the SDR creates the Opportunity on the
  Account and adds themselves to the Opportunity Team, and the AM needs visibility and alerting.
- **New business, unassigned Accounts.** If the Account is new or not assigned to a rep, check whether the
  individual is from Asia (APAC, excluding India per the deck). If so, assign the Lead to the Asia
  specialist. Otherwise, use the existing letter split (for example `M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z`). A
  non-letter goes to rep 1.
- **Re-routing.** A Lead stays with its first owner across engagements. If the Lead has not been converted
  within 21 days and the prospect engages with another module after that, route it again.

## Release Notes

### How routing starts

HubSpot (or Marketing) adds a Lead or Contact to a Campaign as a **Campaign Member**. The new record-triggered
flow **CampaignMember – On Create – After Save** is the entry point (Flow A). It reads:

- the member's Campaign for the **Campaign Type** and **Primary Module**, falling back to the Parent
  Campaign when blank;
- the **Parent Campaign** for the rep fields. A Campaign with no parent is used as-is.

Demo Request, Active Enquiry and In Platform Demo Request are treated as **hand-raisers**.

> The deck branches on "Campaign Record Type", but the Campaign record types are Parent/Sub. These values
> are **Campaign Type** values, so **Active Enquiry** and **In Platform Demo Request** were added to the
> Campaign Type picklist (Demo Request already existed).

### Leads

1. **Skipped:** converted Leads, Blacklisted Leads and Leads with Status Do Not Engage.
2. **Routed** when either is true:
   - **New:** the Lead has never been routed (*Last Routed Date* is blank) and is **not already owned by a
     sales rep**. A sales rep is an active user in an AM, SDR or sales-management role (`AM_*`, `SDR_*`,
     `Manager_Accounts`, `Manager_New_Business`, `Head_of_Accounts`, `Head_of_New_Business`,
     `Director_of_Sales`). Leads created by HubSpot or Marketing are routed. A Lead an SDR created
     manually stays with that SDR.
   - **21-day re-route:** at least 21 days have passed since the Lead was last routed (or created, if it
     was never routed), and the Campaign's Primary Module is **different** from the module that last
     routed it.
3. **Hand-raisers** set the Status to **Ready to Convert**, unless the Lead is already Ready to Convert,
   Qualified or Unqualified.
4. The owner gets a **Lead Routing Alert** (bell and mobile notification) for one of three cases:
   - **New Lead assigned**, with the routing reason;
   - **Hot Lead – Ready to Convert**;
   - **Lead engagement**, for an existing owner, matching the deck's "Contact Owner is Notified".

Routing writes three new read-only fields to the Lead, in a new **Lead Routing** section of the Lead layout:

- **Routing Reason**, e.g. *Letter split (M) – SDR 2*, *Account Team – SDR*, *APAC specialist SDR on
  Parent Campaign*, or *Not routed: …*;
- **Last Routed Date**;
- **Last Routed Module**.

When no active rep is found, the Lead keeps its current owner. The reason is still recorded, and the routing
date is not stamped, so the next engagement tries again.

### Routing engine (Flow B)

The **Lead Routing Engine** is an autolaunched subflow. It works out the owner and returns it with a
routing reason. It doesn't update any records, so it can be reused and tested on its own.

The **Account** used is the Lead's *Account* lookup, which the existing Lead – On Create – After Save flow
sets by email domain, or the Contact's Account.

"The Account's AM" means the oldest **Account Team** member with role **Account Manager**. "The Account's
SDR" means the one with role **Sales Development Representative**. An Account with either one is
**assigned**, which covers both existing customers and assigned new-business Accounts. That avoids needing
a separate "customer" definition: Curtis's rules route both cases the same way for Leads.

Rules, in order:

1. **Account Team**
   - An **In Platform Demo Request** goes to the **AM** (from the V2 deck).
   - Otherwise, a Lead goes to the **SDR** and an Opportunity goes to the **AM**.
   - If the Account Team has only the other role, that person is used.
2. **APAC (excluding India):** goes to the Parent Campaign's **APAC SDR** (Leads) or **APAC AM**
   (Opportunities). Someone counts as APAC when Region is Asia or Oceania, or Country is an APAC country
   name or ISO code. India / IN is excluded.
3. **Letter split:**
   - The first letter of the Account name, or the Lead's Company when no Account is linked, is compared
     against the comma-separated **SDR Split 1–6** lists (Leads) or **AM Split 1–3** lists (Opportunities).
   - Spaces and letter case are ignored.
   - No match, a non-letter or a blank name goes to **SDR 1** / **AM 1**.
   - If an APAC person has no APAC rep set on the Campaign, they also fall through to the letter split.
4. The chosen user must be **active**. If not, no owner is returned and the reason says so.

The split fields were 20 characters long, too short for `M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z` (27 characters). They
are now **255 characters**, with help text explaining the format.

### Contacts (existing individuals)

A hand-raiser from a Contact with an Account creates an **Opportunity**, as in the deck's "Create
Opportunity with Relevant Details":

- **Record type:** Subscription New.
- **Stage:** Request for Information.
- **Name:** *Account – Campaign Type – date*.
- **Close Date:** 30 days out, as a placeholder.
- **Primary Campaign Source:** the Campaign.
- **Primary Module:** the Campaign's module.
- **Primary contact:** the Contact.
- **Owner:** the engine's **AM**. If no rep is found, the Contact owner.

Exceptions and notifications:

- If the Contact is already primary contact on an open Opportunity, no new one is created.
- The Opportunity owner is notified.
- The Contact owner is always notified of the engagement.

### Contact ownership: every Contact on the Account is owned by its AM

**Contact – On Create – Before Save** (updated):

- When a Contact is created on an Account with an active **Account Manager** on its Account Team, that AM
  becomes the owner. This covers Contacts AMs create and Contacts created by **Lead conversion** ("once the
  Lead is converted, the Contact Owner will be the AM").
- When the Account has no AM on its team, the owner is left alone.
- The existing Seniority Level logic is unchanged. The Title check moved from the start conditions into a
  decision, so the flow runs for every new Contact.

**Contact – On Create – After Save** (new) sends the owner a Lead Routing Alert when someone else created
the Contact. This gives the AM the requested visibility and alerting on conversions.

### SDRs can't create Contacts

New validation rule **SDRs Cannot Create Contacts** on Contact:

- It blocks creating a Contact when the user's role API name starts with `SDR_` (SDR Accounts and SDR New
  Business).
- It respects the On/Off Switch (*Run Validation Rules*).

A validation rule was used rather than removing Contact Create from SDR permissions, because Lead conversion
needs Contact Create. Validation rules don't run during Lead conversion unless the org setting *Require
Validation for Converted Leads* is on (see Post Deployment Items).

### SDR-created Opportunities

**Opportunity – On Create – Before Save** (new):

- When an SDR creates an Opportunity on an Account with an active AM on the Account Team, the owner becomes
  the AM.
- This applies to Opportunities created directly or by converting a Lead, matching the deck's "Opportunity
  assigned to Account Owner".

**Opportunity – On Create – After Save** (new):

- It adds the SDR to the **Opportunity Team** (role Sales Development Representative, Edit access), which
  automates "add themselves into the Opportunity Team".
- It sends the AM a Lead Routing Alert.

### Other components

- **Lead Status – Ready to Convert:** added between Working and Qualified. It is not a converted status.
- **Opportunity Stage – Request for Information:** already exists in the org, as the first stage of the
  Subscription New sales process with probability 0 and forecast category Omitted. No change was made.
- **Campaign – APAC SDR / APAC AM:** user lookups, added to the *Splits* section of the Campaign layout
  under SDR 6.
- **Custom Notification Type – Lead Routing Alert:** desktop and mobile.
- **Field-level security:** set in the Beacon *Object, Tab, FLS* permission sets.
  - The Campaign APAC fields follow the existing SDR 1 access: Marketing and Admin can edit, everyone else
    can read.
  - The Lead routing fields are read-only for everyone except Salesforce Admin. The flows run in system
    context and set them automatically.
- **On/Off Switch:** every new flow, and the new Contact owner logic, checks `Run_Flows__c`.
- **Fault handling:** every DML and notification element uses `Fault_Path_Subflow`.

### Not in this build

- **Not built (Flow C):**
  - Moving Leads or Contacts to Nurturing after 30 days with no activity, and adding them to a marketing
    campaign;
  - the lead-score threshold notification;
  - blocking duplicate Leads/Contacts on email for manual creation (Duplicate Rules).

  The first two need a nurture-campaign decision and a HubSpot lead score field in Salesforce. The
  duplicate rules need a decision on how HubSpot API inserts should be treated. All three can follow in a
  later build.
- **Out of scope:** the red items on the deck (HubSpot lead scoring, Ascentrik notes) and the buddy system
  for Account and Opportunity Teams, which is to be discussed separately.

## Acceptance Criteria

**Setup (once)**

1. Deploy, then confirm in **Setup → Account Teams** and **Opportunity Team Settings** that both are
   enabled. They are already enabled in HTC Dev.
2. Pick test users:
   - **SDR-A**, role *SDR New Business*;
   - **SDR-B**, role *SDR New Business*;
   - **AM-A**, role *AM Accounts*;
   - **APAC-SDR** and **APAC-AM**, any active users.
3. Create a **Parent Campaign** and fill in:
   - SDR 1 = SDR-A, SDR Split 1 = `A,B,C,D,E,F,G,H,I,J,K,L`;
   - SDR 2 = SDR-B, SDR Split 2 = `M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z`;
   - AM 1 = AM-A, AM Split 1 = `A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z`;
   - APAC SDR = APAC-SDR, APAC AM = APAC-AM;
   - Primary Module = *Oncology*.
4. Create three **Sub Campaigns** under it:
   - one with Type **Demo Request**;
   - one with Type **Webinar**;
   - one with Type **Content Download** and Primary Module **Cell Therapy**.
5. Create Account **Acme Pharma**, Domain `acme.com`. Add **AM-A** (Account Manager) and **SDR-A** (Sales
   Development Representative) to its Account Team, and make AM-A the Account Owner.

**Test 1 – Assigned Account goes to the Account Team SDR**

1. As an admin (not an AM or SDR), create Lead *Jane Test*, Company *Acme Pharma*, Email `jane@acme.com`.
   Confirm the Lead's Account field = Acme Pharma.
2. Add the Lead to the **Webinar** Sub Campaign.
3. Expected:
   - Owner = SDR-A;
   - Routing Reason = *Account Team - SDR*;
   - Last Routed Date = now, Last Routed Module = Oncology;
   - Status unchanged;
   - SDR-A gets a "New Lead assigned" bell notification.

**Test 2 – Hand-raiser sets Ready to Convert**

1. Add the same Lead to the **Demo Request** Sub Campaign.
2. Expected:
   - Status = **Ready to Convert**;
   - owner unchanged, because it's within 21 days;
   - SDR-A gets a "Hot Lead – Ready to Convert" notification.

**Test 3 – Letter split on an unassigned Account**

1. As an admin, create Lead *Max Test*, Company *Mercury Bio*, Email `max@mercurybio.com`, Country *United
   Kingdom*, with no matching Account.
2. Add the Lead to the **Webinar** Sub Campaign.
3. Expected: Owner = **SDR-B**, Routing Reason = *Letter split (M) - SDR 2*.
4. Repeat with Company *Beta Labs*. Expected: SDR-A, *Letter split (B) - SDR 1*.
5. Repeat with Company *3D Bio*. Expected: SDR-A, *Letter split (3) - SDR 1 (default)*.

**Test 4 – APAC specialist**

1. Create Lead *Ken Test*, Company *Zeta Tokyo*, Country *Japan*, with no matching Account.
2. Add it to the Webinar Sub Campaign.
3. Expected: Owner = **APAC-SDR**, reason *APAC specialist SDR on Parent Campaign*.
4. Repeat with Country *India*. Expected: letter split (Z → SDR-B), not APAC-SDR.

**Test 5 – Existing rep-owned Lead is not re-routed**

1. As **SDR-A**, create Lead *Sam Test*, Company *Zebra Co*.
2. Add it to the Webinar Sub Campaign.
3. Expected: owner stays SDR-A, Routing Reason blank, and SDR-A gets a "Lead engagement" notification.

**Test 6 – 21-day re-route on a new module**

1. On the Lead from Test 3 (*Mercury Bio*), as admin set **Last Routed Date** to 22 days ago and change the
   owner to SDR-A.
2. Add it to the **Content Download (Cell Therapy)** Sub Campaign.
3. Expected: Owner = SDR-B again, Last Routed Module = Cell Therapy, Last Routed Date = now.
4. Repeat with a Campaign whose module matches Last Routed Module. Expected: no re-route.

**Test 7 – SDRs cannot create Contacts**

1. Log in as SDR-A and try to create a Contact. Expected: error *SDRs can't create Contacts…*.
2. As SDR-A, convert the Lead from Test 1 to Acme Pharma, with an Opportunity.
3. Expected:
   - the conversion succeeds;
   - the new **Contact owner = AM-A**, and AM-A gets "New Contact on your Account";
   - the **Opportunity owner = AM-A**;
   - **SDR-A is on the Opportunity Team** (Sales Development Representative, Read/Write);
   - AM-A gets "New Opportunity from your SDR".

**Test 8 – AM creates a Contact**

1. As AM-A, create a Contact on Acme Pharma.
2. Expected: owner = AM-A, and no notification, because AM-A created it.
3. As an admin, create a Contact on Acme Pharma.
4. Expected: owner = AM-A, and AM-A is notified.

**Test 9 – Contact hand-raiser creates an Opportunity**

1. Add the Contact from Test 8 to the **Demo Request** Sub Campaign.
2. Expected:
   - a new Opportunity *Acme Pharma - Demo Request - <date>*;
   - record type Subscription New, Stage **Request for Information**, Close Date +30 days;
   - Primary Campaign Source = the Sub Campaign, Primary Module = Oncology;
   - the Contact is the primary contact role, and Owner = AM-A;
   - AM-A gets the Opportunity and Contact notifications.
3. Add the Contact to the Demo Request Campaign again (remove and re-add). Expected: no second Opportunity,
   and the notification says an open Opportunity already exists.

**Test 10 – On/Off Switch**

1. Create an On/Off Switch record for your user with *Run Flows* unchecked.
2. Repeat Test 3. Expected: no routing.
3. With *Run Validation Rules* unchecked for SDR-A, SDR-A can create a Contact.
4. Delete the record afterwards.

## Post Deployment Items

1. **Populate Parent Campaign rep fields:**
   - SDR 1–6 and SDR Split 1–6, as comma-separated letters;
   - AM 1–3 and AM Split 1–3;
   - APAC SDR and APAC AM.

   Campaigns with no SDRs set can't letter-split, and Leads keep their current owner with a *Not routed*
   reason.
2. **Populate Account Teams** (manual upload):
   - For every customer and assigned new-business Account, add the AM (role *Account Manager*) and the SDR
     (role *Sales Development Representative*), and make the AM the Account Owner.
   - Routing treats an Account with no team members as unassigned.
3. **Check the Lead Convert setting.** In Setup → Lead Settings, confirm **Require Validation for Converted
   Leads** is **off**. If it's on, the *SDRs Cannot Create Contacts* rule blocks SDRs from converting Leads.
4. **Set the HubSpot campaign type.** Confirm HubSpot sets the Campaign Type to **Active Enquiry** or **In
   Platform Demo Request** on the relevant Campaigns, using those exact names.
5. **Check user roles.** Confirm SDRs are in the *SDR Accounts* / *SDR New Business* roles, and AMs and
   sales managers are in the AM, Manager, Head-of or Director of Sales roles. Routing and the SDR rules
   depend on them.
6. **Mobile notifications:** add *Lead Routing Alert* to the Salesforce mobile app's notification settings
   if mobile push notifications are wanted.

## Component Manifest

Github Branch: https://github.com/aaroncrear/BeaconImplementation/tree/claude/trusting-pasteur-37mn40

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Flow | N/A | Lead_Routing_Engine | Lead Routing Engine | Created | Autolaunched subflow (Flow B). Returns the owner and routing reason: Account Team (In Platform Demo Request goes to the AM; otherwise SDR for Leads and AM for Opportunities, with fallback to the other role), then the APAC (excl. India) SDR/AM on the Parent Campaign, then the letter split on SDR/AM Split fields, with no match going to rep 1. Only returns active users. |
| 2 | Flow | CampaignMember | CampaignMember_On_Create_After_Save | CampaignMember - On Create - After Save | Created | Routing entry point (Flow A). Routes new Leads not owned by a sales rep, and re-routes Leads after 21 days on a different module. Sets Ready to Convert for hand-raisers. Creates a Request for Information Opportunity for hand-raiser Contacts. Sends Lead Routing Alerts. |
| 3 | Flow | Contact | Contact_On_Create_Before_Save | Contact - On Create - Before Save | Updated | Added: Contact owner = the Account Team Account Manager (active) on create, including Lead conversion. The Title start condition moved into a decision so the flow runs on every create. Seniority logic unchanged. |
| 4 | Flow | Contact | Contact_On_Create_After_Save | Contact - On Create - After Save | Created | Alerts the Contact owner (AM) when someone else creates a Contact on their Account, including by conversion. |
| 5 | Flow | Opportunity | Opportunity_On_Create_Before_Save | Opportunity - On Create - Before Save | Created | When an SDR creates an Opportunity, sets the owner to the Account Team Account Manager (active). |
| 6 | Flow | Opportunity | Opportunity_On_Create_After_Save | Opportunity - On Create - After Save | Created | Adds the creating SDR to the Opportunity Team (Sales Development Representative, Edit) when someone else owns the Opportunity, and alerts the owner. |
| 7 | Custom Notification Type | N/A | Lead_Routing_Alert | Lead Routing Alert | Created | Desktop and mobile notification used by the routing flows. |
| 8 | Validation Rule | Contact | SDRs_Cannot_Create_Contacts | SDRs Cannot Create Contacts | Created | Blocks Contact creation by users in an SDR_ role. Respects the On/Off Switch. |
| 9 | Standard Value Set | Lead | LeadStatus | Lead Status | Updated | Added Ready to Convert (not converted) between Working and Qualified. |
| 10 | Standard Value Set | Campaign | CampaignType | Campaign Type | Updated | Added Active Enquiry and In Platform Demo Request. |
| 11 | Record Type | Campaign | Parent_Campaign | Parent Campaign | Updated | Made Active Enquiry and In Platform Demo Request available for Type. |
| 12 | Record Type | Campaign | Sub_Campaign | Sub Campaign | Updated | Made Active Enquiry and In Platform Demo Request available for Type. |
| 13 | Field | Campaign | APAC_SDR__c | APAC SDR | Created | Lookup(User). APAC (excl. India) specialist SDR for Lead routing on unassigned Accounts. |
| 14 | Field | Campaign | APAC_AM__c | APAC AM | Created | Lookup(User). APAC (excl. India) specialist AM for auto-created Opportunities on unassigned Accounts. |
| 15 | Field | Campaign | SDR_Split_1__c | SDR Split 1 | Updated | Length 20 → 255. Help text added for the comma-separated letter format. |
| 16 | Field | Campaign | SDR_Split_2__c | SDR Split 2 | Updated | Length 20 → 255. Help text added. |
| 17 | Field | Campaign | SDR_Split_3__c | SDR Split 3 | Updated | Length 20 → 255. Help text added. |
| 18 | Field | Campaign | SDR_Split_4__c | SDR Split 4 | Updated | Length 20 → 255. Help text added. |
| 19 | Field | Campaign | SDR_Split_5__c | SDR Split 5 | Updated | Length 20 → 255. Help text added. |
| 20 | Field | Campaign | SDR_Split_6__c | SDR Split 6 | Updated | Length 20 → 255. Help text added. |
| 21 | Field | Campaign | AM_Split_1__c | AM Split 1 | Updated | Length 20 → 255. Help text added. |
| 22 | Field | Campaign | AM_Split_2__c | AM Split 2 | Updated | Length 20 → 255. Help text added. |
| 23 | Field | Campaign | AM_Split_3__c | AM Split 3 | Updated | Length 20 → 255. Help text added. |
| 24 | Field | Lead | Routing_Reason__c | Routing Reason | Created | Text(255). Why routing chose the current owner. Set by automation. |
| 25 | Field | Lead | Last_Routed_Date__c | Last Routed Date | Created | Date/Time of the last routing. Used for the 21-day re-route. |
| 26 | Field | Lead | Last_Routed_Module__c | Last Routed Module | Created | Text(255). Primary Module of the Campaign that last routed the Lead. Used for the re-route rule. |
| 27 | Layout | Campaign | Campaign-Campaign Layout | Campaign Layout | Updated | Added APAC SDR and APAC AM under SDR 6 in the Splits section. |
| 28 | Layout | Lead | Lead-Lead Layout | Lead Layout | Updated | Added a Lead Routing section with read-only Routing Reason, Last Routed Date and Last Routed Module. |
| 29 | Permission Set | N/A | Beacon_Consulting_Object_Tab_FLS | Beacon Consulting - Object, Tab, FLS | Updated | Read on Campaign APAC SDR/AM and the three Lead routing fields. |
| 30 | Permission Set | N/A | Beacon_Customer_Success_Object_Tab_FLS | Beacon Customer Success - Object, Tab, FLS | Updated | Read on Campaign APAC SDR/AM and the three Lead routing fields. |
| 31 | Permission Set | N/A | Beacon_Executive_Object_Tab_FLS | Beacon Executive - Object, Tab, FLS | Updated | Read on Campaign APAC SDR/AM and the three Lead routing fields. |
| 32 | Permission Set | N/A | Beacon_Marketing_Object_Tab_FLS | Beacon Marketing - Object, Tab, FLS | Updated | Edit on Campaign APAC SDR/AM; Read on the three Lead routing fields. |
| 33 | Permission Set | N/A | Beacon_Product_Object_Tab_FLS | Beacon Product - Object, Tab, FLS | Updated | Read on Campaign APAC SDR/AM and the three Lead routing fields. |
| 34 | Permission Set | N/A | Beacon_ResOps_Object_Tab_FLS | Beacon ResOps - Object, Tab, FLS | Updated | Read on Campaign APAC SDR/AM and the three Lead routing fields. |
| 35 | Permission Set | N/A | Beacon_Sales_Object_Tab_FLS | Beacon Sales - Object, Tab, FLS | Updated | Read on Campaign APAC SDR/AM and the three Lead routing fields. |
| 36 | Permission Set | N/A | Beacon_Salesforce_Admin_Object_Tab_FLS | Beacon Salesforce Admin - Object, Tab, FLS | Updated | Edit on Campaign APAC SDR/AM and the three Lead routing fields. |
| 37 | Permission Set | N/A | Beacon_Tech_Object_Tab_FLS | Beacon Tech - Object, Tab, FLS | Updated | Read on Campaign APAC SDR/AM and the three Lead routing fields. |
