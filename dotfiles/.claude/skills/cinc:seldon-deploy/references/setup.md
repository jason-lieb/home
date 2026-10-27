# Set up Seldon deploys for an app

Do these steps in order. Each step names who does it. The app developer does most of them in the app repo. The platform team does the steps outside it.

## Contents

1. [Check that the stack exists](#1-check-that-the-stack-exists)
2. [Write deploy.yaml](#2-write-deployyaml)
3. [Build the image](#3-build-the-image)
4. [Keep the galactus workflow](#4-keep-the-galactus-workflow)
5. [Add the deploy caller](#5-add-the-deploy-caller)
6. [Secrets](#6-secrets)
7. [Production](#7-production)
8. [Do the first deploy](#8-do-the-first-deploy)
9. [Optional extras](#9-optional-extras)

## 1. Check that the stack exists

A stack is `<level>-<namespace>`, for example `dev-marketing-cinc`. The namespace is `{subsystem}-{tenant}` (see the [platform concepts](https://github.com/cincpro/seldon-idp/blob/main/README.md#platform-concepts)). Argo CD deploys an app only into a stack that has an `AppProject`. The platform team makes that `AppProject`, the Kubernetes namespace, and the Vault auth for each stack.

Check for the `AppProject` (it prints `exists` or an HTTP 404):

```bash
gh api "repos/cincpro/seldon-gitops/contents/mgt-witco/witco-namespaces/am4-kube0/\
argoproj.io-v1alpha1_AppProject_infra_<level>-<namespace>.yaml?ref=infra" --silent \
  && echo exists
```

If it does not exist, draft a platform request (use the `seldon-request` skill) for the namespace and the levels. How an app developer gets a new stack is not documented yet, so do not try to make one.

Check each level that you deploy to. The ApplicationSet for each level sends an app to these clusters:

| Level | Default cluster | Other clusters (`loc_code` in `deploy.yaml`) |
|---|---|---|
| `dev` | `am71-kube0` | `am72-kube0` |
| `prd` | `am16-kube0` | `am17-kube0` |
| `sbx` | `am90-kube0` | none |

## 2. Write deploy.yaml

Use the `galactus` skill. The pipeline needs these fields:

- `name` and `namespace`. The stack is `<level>-<namespace>`, and the gitops folder is `<stack>/<name>/`.
- A `targets` entry for each level that you deploy to.
- A `version:` pin. The workflow installs the galactus release that matches it. Without a pin, galactus 0.15.1 runs.

## 3. Build the image

Add `.github/workflows/image-build.yml`. Keep `name: Image Build`, because the deploy caller can name this workflow in a `workflow_run` trigger.

```yaml
name: Image Build
on: push
permissions:
  contents: read
  id-token: write
  statuses: write
jobs:
  build:
    uses: cincpro/actions/.github/workflows/image-build.yml@image-build-v2
    secrets: inherit
```

- The build pushes to `558529356944.dkr.ecr.us-east-1.amazonaws.com/<image-name>` with the tags `<sha8>`, `<image-name>-<sha8>`, and `trunk-<sha8>` or `branch-<sha8>`. It makes the ECR repo on the first push.
- `image-name` defaults to the GitHub repo name. galactus builds the image name from `name:` in `deploy.yaml`. If the two names are different, set `with: image-name: <deploy.yaml name>`, or no deploy will ever find its image.
- The build sets the commit status `Image Built & Pushed`. The deploy-a-ref interface requires it.
- For a base image, use the [Seldon base images](https://github.com/cincpro/seldon-images) (`FROM 558529356944.dkr.ecr.us-east-1.amazonaws.com/node:22-slim` and others). They add a tuned allocator and the corporate CA.
- To install private packages in the build, read "Token in Docker builds" in the [`cincpro/actions` README](https://github.com/cincpro/actions#token-in-docker-builds). The build gets a CodeArtifact token as a BuildKit secret automatically.

## 4. Keep the galactus workflow

A Seldon repo still needs `.github/workflows/galactus.yml`. It does not need to run on every deploy, for example when nothing changed. Use the workflow from "Onboard a new app" in the `galactus` skill's `deploy-yaml.md`. Do not do the `geekbot register` and `geekbot kdeploy` steps from that list: they are for the geekstack path.

## 5. Add the deploy caller

Add `.github/workflows/seldon-deploy.yml`. There is no agreed standard yet. Copy the resolve-and-deploy caller from [workflows.md](workflows.md#resolve-and-deploy), because `cinc-marketing-library` uses it and it is the closest to a standard. Tell the user that the interface can change when `cincpro/actions` cuts a release.

For a non-engineer, set `service-level: sbx` and add no `dev` or `prd` path. Engineers deploy to `dev`. See [Production](#7-production).

## 6. Secrets

- **Workflow secrets:** `WITCO_RELEASE_BOT_PRIVATE_KEY` and `ARGOCD_AUTH_TOKEN` are organization secrets, and the `WITCO_RELEASE_BOT_APP_ID` variable is an organization variable. Do not add them to the repo.
- **ReleaseBot:** the GitHub App must be installed on `galactus`, `witco-cli`, and `seldon-gitops`. This is done once for the organization. If a run fails to make a ReleaseBot token, ask the platform team.
- **App secrets in Vault:** galactus syncs the app's own Vault path, and `secrets_from` adds other paths (see the `galactus` skill). Who writes a secret depends on the secret:
  - **Most secrets:** the app developers edit or add the entries themselves in the Vault UI at [vault.rg-infra.com](https://vault.rg-infra.com). If the user cannot write to the path, draft a platform request (use the `seldon-request` skill).
  - **Terminus (OIDC) client secrets:** the platform team enters them after a platform request (use the `seldon-request` skill). One request covers all the levels. Dev and production hold separate client records, so list each one.
- Send a secret only through Vault. Never paste a secret value into an issue, Slack, or email.
- Never put a secret in `deploy.yaml`, in the workflow, or in `seldon-gitops`.

## 7. Production

Only engineers can deploy to `prd`. Only the most senior engineers and DevOps have access to `prd`. Product people and other non-engineers who build apps must not promote to production without an engineer.

Code review is the main gate. CI/CD can target `prd`, but only with code that a reviewer approved first.

When an engineer adds production:

1. Add the `prd` target to `deploy.yaml`.
2. Make sure that branch protection on the default branch requires a review. A `prd` deploy runs only from the default branch, so it ships only reviewed code.
3. Start `prd` deploys by hand from **Run workflow**. The resolve-and-deploy interface refuses a `prd` deploy that a push started, unless `auto-deploy-prd: true` is set and `prd` is the only target.
4. Optional: make a GitHub environment named `prd` with required reviewers. The resolve-and-deploy interface runs its deploy job in that environment, so each `prd` deploy then waits for an approval too.

The deploy-a-ref interface has no environment gate, and its `ref` input can name an unreviewed branch. If a repo uses it, anyone who can run the workflow can deploy each level in its `level` options. Leave `prd` out of those options until an engineer owns the production setup.

## 8. Do the first deploy

1. Push the workflows and `deploy.yaml` to a branch, and merge them when the checks pass.
2. Run **Actions → Seldon Deploy → Run workflow** with `dry-run` set. Read the manifest diff in the run summary. On a first deploy, every file is new.
3. Run it again without `dry-run`, or let the merge deploy dev.
4. Open the Argo CD link in the run summary. The ApplicationSet makes the app `<stack>--<name>` (for example `dev-marketing-cinc--cinc-marketing-library`) within a few minutes of the gitops commit. You do not register it.
5. Check that the pods are ready and that the app answers at its host.

## 9. Optional extras

- **Make targets** (from `seldon-demo`): `deploy-prd` starts the workflow with `gh workflow run` and follows it, and `deploy-diff` renders the checkout and diffs it against `seldon-gitops` with `witctl gitops --diff`. `witctl` needs your own access.
- **`sdeploy`:** `sdeploy <app>[/<ref>] to <level>` in Slack starts the deploy-a-ref caller. It is not known whether geekbot needs a registration first.
- **Manifest check on pull requests:** `manifest-check.yml` (PR #87, branch `manifest-check`) runs galactus on each pull request that changes `deploy.yaml`. It is not released either.
- **Dependabot gate:** block a deploy while a critical Dependabot alert is open. See [workflows.md](workflows.md#dependabot-gate).
