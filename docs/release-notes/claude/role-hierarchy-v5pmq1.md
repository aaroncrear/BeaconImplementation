# "claude/role-hierarchy-v5pmq1" – Release Notes

## Requirements

The business requested a full Role Hierarchy be built out in the org so that record access,
sharing, and roll-up reporting follow the company's actual org chart, rather than every user
sitting at the same level. The hierarchy needed to reflect the company's functional teams —
Sales (New Business and Accounts, each with SDR/AM/Manager tiers), Marketing, Consulting,
Product, ResOps, and Tech — all rolling up to an `Executive` role, with a top-level
`SF Admin` role above Executive and a separate `RevOps/Tech Admin` role for system administration.

## Release Notes

24 Roles were deployed directly to the org to build out the hierarchy below. Role access was set
per function: most roles have `Read` opportunity access (so managers/reps can see but not edit
opportunities outside their own), while `SF Admin`, `RevOps/Tech Admin`, `Director of Sales`, and
the two `Manager` roles in the sales tree (`Manager - Accounts`, `Manager - New Business`) were
given `Edit` opportunity access to reflect their operational ownership of the sales pipeline.
Case and Contact access is `Edit` for every role, and `mayForecastManagerShare` is off (`false`)
across the board, matching Salesforce's default role settings.

Hierarchy:

```
SF Admin
├── Executive
│   ├── Consulting Manager
│   │   └── Consulting Rep
│   ├── Director of Marketing
│   │   └── Senior Marketing Manager
│   │       └── Marketing Manager
│   │           └── Marketing Rep
│   ├── Director of Sales
│   │   ├── Head of Accounts
│   │   │   └── Manager - Accounts
│   │   │       ├── AM - Accounts
│   │   │       └── SDR - Accounts
│   │   └── Head of New Business
│   │       └── Manager - New Business
│   │           ├── AM - New Business
│   │           └── SDR - New Business
│   ├── Product Manager
│   │   └── Product Rep
│   ├── ResOps Manager
│   │   └── ResOps Rep
│   └── Tech Manager
│       └── Tech Rep
└── RevOps/Tech Admin
```

The roles were deployed to the org directly, then retrieved and added to this repo as
source-tracked metadata under `unpackaged/main/default/roles/`, following the standard Salesforce
Role metadata convention: the `<name>` and `<description>` elements hold the role's own label, and
the `<parentRole>` element holds the developer name of the role it reports to (root role, `SF
Admin`, has no `<parentRole>`).

An earlier, temporary two-role hierarchy (`Executive` reporting to nothing, with a `Contractor`
role beneath it) was created first to validate the approach, then replaced by the full 24-role
structure above — `Executive` was reparented under the new `SF Admin` root role, and the
`Contractor` role was removed as it was only a placeholder for the initial test.

## Acceptance Criteria

1. In Setup > Roles (Role Hierarchy), confirm the tree above matches exactly: `SF Admin` at the
   top, with `Executive` and `RevOps/Tech Admin` reporting to it, and the Sales/Marketing/
   Consulting/Product/ResOps/Tech branches reporting to `Executive` as shown.
2. Open `Director of Sales`, `Manager - Accounts`, `Manager - New Business`, `RevOps/Tech Admin`,
   and `SF Admin`, and confirm Opportunity Access is `Read/Write`.
3. Open every other role and confirm Opportunity Access is `Read Only`.
4. Open any role and confirm Case Access and Contact Access are both `Read/Write`, and "This
   role's users may share their forecast..." is unchecked.
5. Assign a test user to a leaf role (e.g. `SDR - Accounts`) and confirm record visibility rolls
   up correctly through `Manager - Accounts` → `Head of Accounts` → `Director of Sales` →
   `Executive` → `SF Admin`.
6. Confirm no `Contractor` role remains in the hierarchy.

## Post Deployment Items

None.

## Component Manifest

Github Branch: https://github.com/aaroncrear/BeaconImplementation/tree/claude/role-hierarchy-v5pmq1

| # | Component Type | Object | API Name | Label | Created/Updated/Deleted | Description |
|---|----------------|--------|----------|-------|-------------------------|--------------|
| 1 | Role | UserRole | SF_Admin | SF Admin | Created | Top-level role, no parent. |
| 2 | Role | UserRole | Executive | Executive | Updated | Reparented under SF_Admin (previously top-level). |
| 3 | Role | UserRole | RevOps_Tech_Admin | RevOps/Tech Admin | Created | Reports to SF_Admin. |
| 4 | Role | UserRole | Consulting_Manager | Consulting Manager | Created | Reports to Executive. |
| 5 | Role | UserRole | Consulting_Rep | Consulting Rep | Created | Reports to Consulting Manager. |
| 6 | Role | UserRole | Director_of_Marketing | Director of Marketing | Created | Reports to Executive. |
| 7 | Role | UserRole | Senior_Marketing_Manager | Senior Marketing Manager | Created | Reports to Director of Marketing. |
| 8 | Role | UserRole | Marketing_Manager | Marketing Manager | Created | Reports to Senior Marketing Manager. |
| 9 | Role | UserRole | Marketing_Rep | Marketing Rep | Created | Reports to Marketing Manager. |
| 10 | Role | UserRole | Director_of_Sales | Director of Sales | Created | Reports to Executive. |
| 11 | Role | UserRole | Head_of_Accounts | Head of Accounts | Created | Reports to Director of Sales. |
| 12 | Role | UserRole | Manager_Accounts | Manager - Accounts | Created | Reports to Head of Accounts. |
| 13 | Role | UserRole | AM_Accounts | AM - Accounts | Created | Reports to Manager - Accounts. |
| 14 | Role | UserRole | SDR_Accounts | SDR - Accounts | Created | Reports to Manager - Accounts. |
| 15 | Role | UserRole | Head_of_New_Business | Head of New Business | Created | Reports to Director of Sales. |
| 16 | Role | UserRole | Manager_New_Business | Manager - New Business | Created | Reports to Head of New Business. |
| 17 | Role | UserRole | AM_New_Business | AM - New Business | Created | Reports to Manager - New Business. |
| 18 | Role | UserRole | SDR_New_Business | SDR - New Business | Created | Reports to Manager - New Business. |
| 19 | Role | UserRole | Product_Manager | Product Manager | Created | Reports to Executive. |
| 20 | Role | UserRole | Product_Rep | Product Rep | Created | Reports to Product Manager. |
| 21 | Role | UserRole | ResOps_Manager | ResOps Manager | Created | Reports to Executive. |
| 22 | Role | UserRole | ResOps_Rep | ResOps Rep | Created | Reports to ResOps Manager. |
| 23 | Role | UserRole | Tech_Manager | Tech Manager | Created | Reports to Executive. |
| 24 | Role | UserRole | Tech_Rep | Tech Rep | Created | Reports to Tech Manager. |
