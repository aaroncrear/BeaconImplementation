# Delta deploys to the HTCDEV sandbox

Every push to the `dev-sandbox` branch that changes Salesforce metadata (`unpackaged/**`, `sfdx-project.json` or `.forceignore`) deploys **only the changed components** to the Beacon HTCDEV sandbox.

Workflow: `.github/workflows/deploy-htcdev.yml` · Delta script: `scripts/ci/build-delta.sh`

## How it works

1. The workflow checks out full history and installs the Salesforce CLI and the [sfdx-git-delta](https://github.com/scolladon/sfdx-git-delta) plugin.
2. It diffs from the **last successful deploy** to the pushed commit. That point is recorded by the git tag `htcdev-last-deploy`, which the workflow moves forward after every successful deploy. Because of this, a failed deploy's changes are retried on the next push instead of being skipped. On the first run, before the tag exists, it diffs from where `dev-sandbox` branched off `master`.
3. sfdx-git-delta writes a `package.xml` (added or changed components) and a `destructiveChanges.xml` (deleted components).
4. It runs `sf project deploy start --manifest package.xml` against HTCDEV. If nothing deployable changed, it skips the deploy.
5. The job summary shows the delta manifest. The delta files are also saved as a run artifact.

## One-time setup

### 1. Create the auth secret

The workflow logs in with an SFDX auth URL stored as a GitHub secret. Run these on your machine:

```bash
sf org login web --alias htcdev --instance-url https://test.salesforce.com
sf org display --target-org htcdev --verbose --json | jq -r .result.sfdxAuthUrl
```

Use HTCDEV's My Domain login URL instead of test.salesforce.com if you prefer. Copy the `force://...` value it prints.

Then go to GitHub → **Settings → Environments → New environment** and name it `htcdev`. Add an environment secret:

| Secret | Value |
| --- | --- |
| `HTCDEV_SFDX_AUTH_URL` | the `force://...` value |

The auth URL carries a refresh token for the user who logged in. Ideally, log in as a dedicated deployment/integration user in HTCDEV. Logging out of that CLI session (`sf org logout`) revokes the token.

### 2. Optional settings (repo or environment variables)

| Variable | Default | Purpose |
| --- | --- | --- |
| `HTCDEV_TEST_LEVEL` | `NoTestRun` | e.g. `RunLocalTests` once Apex is in the project |
| `HTCDEV_DEPLOY_DELETES` | `false` | `true` also deletes components from HTCDEV when their files are deleted in git |

With deletes off, deleted components are listed in the job summary but left in the org. The baseline tag still moves forward, so remove those components by hand or with the files in `manifest/destructive/`.

## Manual runs

**Actions → Deploy delta to HTCDEV → Run workflow** (on `dev-sandbox`):

- **from_ref**: diff from a specific commit, tag or branch. For example, `master` redeploys everything that differs from master.
- **validate_only**: check-only deploy. Nothing is saved, and the baseline tag does not move.

## Gotchas

- **Profiles** deploy as the whole profile file whenever that file changes.
- **Clicks-not-code changes made directly in HTCDEV** are not in git. A deploy can overwrite them if the same component is changed in the branch. Retrieve them into the branch first.
- **Pushes queue, they don't cancel.** Only one deploy runs at a time.
