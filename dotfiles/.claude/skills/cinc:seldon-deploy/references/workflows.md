# The Seldon deploy workflows

The shared workflows live in `cincpro/actions`, and none of them is released. Each caller pins a branch or a commit. The three interfaces below have different inputs, so a caller written for one does not work with another.

## Contents

- [Which interface to use](#which-interface-to-use)
- [Resolve-and-deploy](#resolve-and-deploy)
- [Deploy-a-ref](#deploy-a-ref)
- [Promote](#promote)
- [Dependabot gate](#dependabot-gate)
- [Pinning](#pinning)

## Which interface to use

| Interface | Ref | Pull request | Used by |
|---|---|---|---|
| Resolve-and-deploy | `seldon-deploy.yml@c5b648ab6364ad0692f2c0c602d549a702f76cfe` | #77 (an earlier commit on its branch) | `cinc-marketing-library` |
| Deploy-a-ref | `seldon-deploy.yml@seldon-deploy` | #91 | `seldon-demo` |
| Promote | `seldon-promote.yml@feat/seldon-deploy` | #77 | `lead_router`, `lead_router_admin` |

No interface is the agreed standard. For a new app, use resolve-and-deploy, as `cinc-marketing-library` does. It is the newest real app, and it deploys `prd` only from the reviewed default branch. Use deploy-a-ref when the app needs `sdeploy` from Slack or the `workflow_run` trigger.

`seldon-deploy.yml@feat/seldon-deploy` is broken: the file is gone from that branch. `product-bi` and `lr-waiting-room-purge` still call it.

## Resolve-and-deploy

The workflow resolves the image tag, waits for the image in ECR, renders `deploy.yaml` with galactus, and pushes the manifests with `witctl gitops`. It does not wait for Argo CD.

| Input | Default | Meaning |
|---|---|---|
| `service-level` | (required) | The level to deploy. It must be a target in `deploy.yaml`. |
| `image-tag` | `''` | Deploy this commit (8-char sha, or any ref) instead of the pushed commit. Use it to roll back. It skips the `deployed_version` check. |
| `promote-from` | `''` | Deploy the image that this level runs now. A `prd` deploy uses the other target by default. |
| `dry-run` | `false` | Diff against `seldon-gitops`, push nothing. |
| `name`, `namespace` | from `deploy.yaml` | Override the gitops folder. Rarely needed. |
| `auto-deploy-prd` | `false` | Let a push deploy `prd`. It works only when `prd` is the only target. Engineers only. |

How it behaves:

- **Production:** a `prd` deploy must run from the default branch, so code review gates it. It must start from **Run workflow** unless `auto-deploy-prd` is set. The deploy job runs in the GitHub environment named `service-level`. Optional required reviewers on a `prd` environment add an approval step.
- **What `prd` ships:** with no `image-tag`, a `prd` deploy ships the image that the lower level runs now, not the tip of `main`. It refuses when `prd` already runs a commit that is not an ancestor of that image.
- **The image wait:** it checks ECR every 15 seconds for 10 minutes for `<image>:<sha8>`. The image is `image_name` in `deploy.yaml`, else `558529356944.dkr.ecr.us-east-1.amazonaws.com/<name>`.
- **galactus:** it installs the newest galactus release, and galactus then gets the version that `deploy.yaml` pins. The `galactus` skill describes the 403 failure that this can cause.
- **Secrets:** `secrets: inherit`. It reads `WITCO_RELEASE_BOT_PRIVATE_KEY` and the variable `WITCO_RELEASE_BOT_APP_ID`. Both are set for the organization.

A caller for dev, based on `cinc-marketing-library`:

```yaml
name: Seldon Deploy

on:
  push:
    branches: [main]
  workflow_dispatch: # a rollback, or a diff against seldon-gitops
    inputs:
      image-tag:
        description: Redeploy this 8-char commit sha instead of main's tip (rollback)
        required: false
      dry-run:
        description: Diff against seldon-gitops without pushing
        required: false
        type: boolean
        default: false

permissions:
  contents: read
  id-token: write

jobs:
  seldon-deploy:
    # an unreleased commit from cincpro/actions#77; repin on purpose when a tag ships
    uses: cincpro/actions/.github/workflows/seldon-deploy.yml@c5b648ab6364ad0692f2c0c602d549a702f76cfe
    with:
      service-level: dev
      image-tag: ${{ inputs.image-tag || '' }}
      dry-run: ${{ inputs.dry-run || false }}
    secrets: inherit
```

For `prd`, an engineer adds a `level` choice to the dispatch inputs, passes it as `service-level`, and checks that the default branch requires a review. See [setup.md](setup.md#7-production).

## Deploy-a-ref

The workflow resolves any ref to a commit, requires the `Image Built & Pushed` status on it, renders with the galactus release that `deploy.yaml` pins, pushes with `witctl gitops`, and waits for Argo CD to report the app Synced and Healthy. It reads its inputs from the caller's dispatch inputs, so the caller needs no `with:`.

| Input | Default | Meaning |
|---|---|---|
| `ref` | default branch | A branch, tag, or sha. An older one rolls back. |
| `level` | (required) | `dev`, `prd`, or `sbx`. It must be a target in `deploy.yaml`. |
| `dry-run` | `false` | Render and diff, push nothing, skip the Argo CD wait. |
| `requested-by` | the GitHub actor | Who asked. geekbot sets it for `sdeploy`. |
| `merge-level` | `dev` | `with:` only. The level that a `workflow_run` deploys. |
| `argocd-timeout` | `600` | `with:` only. Seconds to wait for each Argo CD app. |

How it behaves:

- **No production gate:** there is no environment, and `ref` can name an unreviewed branch. Anyone who can run the workflow can deploy any level in the `level` options.
- **One run for each level:** a newer request replaces a pending one for the same level and repo.
- **Pinned clusters:** a target with a `loc_code` off the default cluster is published as its own `<app>--<loc>-<cluster>` folder and waited on as its own Argo CD app.
- **Ownership check:** before it syncs, it checks that the gitops folder holds this repo's image. It refuses to overwrite another app's folder with the same name.
- **Outputs:** `sha`, `tag`, `stack`, and `gitops-commit`.

The caller from the `cincpro/actions` README, with the merge trigger:

```yaml
name: Seldon Deploy
run-name: >-
  ${{ inputs.dry-run && 'Diff' || 'Deploy' }}
  ${{ inputs.ref || github.event.workflow_run.head_sha || 'main' }} to ${{ inputs.level || 'dev' }}

on:
  workflow_dispatch: # Actions tab, or geekbot `sdeploy <app>[/<ref>] to <level>`
    inputs:
      ref: { description: "branch, tag or sha; empty means main", required: false }
      level: { description: service level, type: choice, options: [dev] }
      dry-run: { description: "render and diff only, push nothing", type: boolean, default: false }
      requested-by: { description: "who asked, when started on their behalf", required: false }
  workflow_run: # a merge to main deploys dev once its image is green
    workflows: ["Image Build"] # the exact name: of the image build workflow
    types: [completed]
    branches: [main]

jobs:
  deploy:
    # unreleased: cincpro/actions#91; repin to the tag when it ships
    uses: cincpro/actions/.github/workflows/seldon-deploy.yml@seldon-deploy
    permissions: # the called job reads commit statuses and run history with the repo token
      contents: read
      statuses: read
      actions: read
    secrets:
      WITCO_RELEASE_BOT_PRIVATE_KEY: ${{ secrets.WITCO_RELEASE_BOT_PRIVATE_KEY }}
      ARGOCD_AUTH_TOKEN: ${{ secrets.ARGOCD_AUTH_TOKEN }}
```

The `level` options hold `dev` only. An engineer adds `prd` when the app is ready for production.

## Promote

`seldon-promote.yml` (PR #77) deploys dev on each merge. A **Run workflow** ships the image that dev runs to `prd`, and an `image-tag` input rolls `prd` back. `seldon-demo` keeps a caller for it with no triggers, as a reference. Only one of `seldon-deploy.yml` and `seldon-promote.yml` may have the push and dispatch triggers.

## Dependabot gate

`cinc-marketing-library` blocks a deploy while a critical runtime Dependabot alert is open. Add a job before the deploy and make the deploy job `needs: alert-gate`:

```yaml
permissions:
  contents: read
  id-token: write
  vulnerability-alerts: read # the only key that lets GITHUB_TOKEN read Dependabot alerts

jobs:
  alert-gate:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - name: Check for open critical alerts
        if: ${{ !inputs.ignore-alerts }} # add a boolean ignore-alerts dispatch input
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          # poll: a push that fixes an alert races the Dependabot rescan that closes it
          deadline=$(( SECONDS + 600 ))
          q='state=open&severity=critical&scope=runtime&per_page=100'
          while alerts=$(gh api --paginate \
              "/repos/${GITHUB_REPOSITORY}/dependabot/alerts?$q" --jq '.[].number'); do
            [ -z "$alerts" ] && exit 0
            if [ "$SECONDS" -ge "$deadline" ]; then
              echo "::error::Open critical Dependabot alerts: $alerts"
              exit 1
            fi
            sleep 30
          done
          exit 1
```

The gate reads the alerts that are open now. A new alert also blocks a rollback of an older commit, so give the dispatch an `ignore-alerts` input.

## Pinning

A commit sha pin is necessary only for an action that the company does not control.

- Third-party actions: pin a commit sha with the version in a comment.
- Actions and workflows from the `cincpro` organization: use a version tag, such as the floating major tag (`@image-build-v2`, `@galactus-v2`). The company owns these repos, so a sha pin is not necessary.
- Seldon workflows: no tag exists yet, so use a commit sha or a branch. A sha does not move. A branch moves. A pinned sha keeps working after its branch moves on, unless someone deletes that version. The `cinc-marketing-library` pin `c5b648ab` is no longer on a branch, and it still works. Add a comment that names the pull request. When a tag ships, change to the tag. Do not guess a tag such as `@seldon-deploy-v1`.
