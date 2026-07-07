# BeaconImplementation

Salesforce metadata project (sfdx). Package source lives under `unpackaged/`.

## Release Notes Requirement

For every Salesforce metadata build (new feature branch, org change, or set of
related changes), create a release notes file in the feature branch using the
format in `docs/templates/RELEASE_NOTES_TEMPLATE.md`. Copy the template, rename
it to match the branch (e.g. `docs/release-notes/<branch-name>.md`), and fill
it in — do not leave placeholder text in the delivered file.

Required sections, in order:

1. **`"Branch Name" – Release Notes`** — title, replace with the actual branch name.
2. **Requirements** — the business requirements driving the build.
3. **Release Notes** — what was built and why it was built the way it was.
4. **Acceptance Criteria** — step-by-step test cases to verify the build.
5. **Post Deployment Items** — any post-deployment work needed (list "None" if none).
6. **Component Manifest** — a link to the GitHub feature branch, followed by a
   table listing every metadata component touched, with columns:
   `#`, `Component Type`, `Object`, `API Name`, `Label`, `Created/Updated/Deleted`, `Description`.

Add one row per component changed — don't leave unused blank rows.
