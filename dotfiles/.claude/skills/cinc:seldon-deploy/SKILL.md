---
name: seldon-deploy
description: "Set up, run, fix, and explain Seldon deploys of CincPro (Witco) apps to Kubernetes: the caller for the shared seldon-deploy workflow, galactus --flat, witctl gitops, cincpro/seldon-gitops, and Argo CD. Use whenever a repo has .github/workflows/seldon-deploy.yml or seldon-promote.yml; the user sets up deploys for a new app, deploys to dev, sbx, or prd, rolls back, runs a dry run, or uses sdeploy, make deploy-*, or witctl gitops; a deploy waits for an image, never starts, fails on Image Built & Pushed, or times out in Argo CD; or the user asks how Seldon works: what a stack, namespace, service level, or tier is, who can deploy to production, how Argo CD finds an app, where to see logs and metrics after a deploy, how to get a database, cache, secret, or AI model key, or how to remove or rename an app. Not for the contents of deploy.yaml (use galactus), app code on the event bus (use event-bus), or drafting a seldon-idp platform request (use seldon-request)."
---

# seldon-deploy: ship an app through Seldon

A Seldon deploy takes an app from a commit to running pods in five steps:

```text
push → Image Build (ECR, tag = 8-char sha)
     → caller .github/workflows/seldon-deploy.yml
     → shared cincpro/actions seldon-deploy.yml: galactus --flat renders deploy.yaml
     → witctl gitops pushes to cincpro/seldon-gitops, branch seldon, <level>-<namespace>/<app>/
     → Argo CD ApplicationSet syncs <level>-<namespace>--<app>
```

This skill covers the pipeline (the setup, the caller workflow, a deploy, a rollback, and the failures) and answers questions about Seldon. The `galactus` skill covers what goes in `deploy.yaml`.

**For a question about Seldon** (what a stack or a service level is, where the logs are, how to get a database or a secret, how to remove an app), answer from [references/concepts.md](references/concepts.md). Run Step 1 only when the answer depends on the app's caller workflow.

## Step 1: check the version and the interface

The shared workflow is not released yet. It lives on the branches of open pull requests in `cincpro/actions`, and the input names differ between them. Find out which one the app uses before you give advice.

1. Run the drift check from the project root, once per session. It reports when `cincpro/actions` publishes a `seldon-deploy-vX.Y.Z` tag. This skill has `verified: 0.0.0` because no release exists, so any release is newer than this skill.

   ```bash
   node "<skill-dir>/scripts/check-drift.mjs" "<skill-dir>" --skill seldon-deploy --project .
   ```

   Replace `<skill-dir>` with this skill's base directory. `ACTION` `none: no tag matches ...` means there is still no release; go on and say nothing. For `recommend an update issue`, follow the update issue steps in the `galactus` skill, with `seldon-deploy` as the skill name.
2. Read the `uses:` line in `.github/workflows/seldon-deploy.yml` (or `seldon-promote.yml`) and find the interface:

   | `uses:` ref | Interface | Status |
   |---|---|---|
   | `@c5b648ab6364ad0692f2c0c602d549a702f76cfe` | Resolve-and-deploy: `service-level`, `image-tag`, `dry-run` | In use by `cinc-marketing-library`. The closest thing to a standard today. |
   | `@seldon-deploy` (branch, PR #91) | Deploy-a-ref: `ref`, `level`, `dry-run`, `requested-by` | In use by `seldon-demo`. The branch moves. |
   | `seldon-promote.yml@feat/seldon-deploy` (PR #77) | Promote: dev gets each merge, prd gets dev's image | In use by `lead_router` and `lead_router_admin`. |
   | `seldon-deploy.yml@feat/seldon-deploy` | None | **Broken.** That branch no longer has the file, so every run fails. Repin. |
   | `@seldon-deploy-vN` | Released | Newer than this skill. Read the `cincpro/actions` README first. |

   [references/workflows.md](references/workflows.md) has the inputs and a caller for each interface.
3. If the repo has no caller yet, set one up with [references/setup.md](references/setup.md).

There is no agreed standard yet. For a new app, copy the `cinc-marketing-library` caller (the first row), and say that the interface can change when `cincpro/actions` cuts a release.

## Two deploy paths

Many apps still deploy through geekstack. Find out which path an app uses before you give deploy steps.

| | geekstack path | Seldon path |
|---|---|---|
| Workflow | `galactus.yml@galactus-v2` only | `galactus.yml` and `seldon-deploy.yml` |
| Gitops repo | `cincpro/geekstack`, `kube-config/<namespace>/<app>/targets/...` | `cincpro/seldon-gitops`, branch `seldon`, `<level>-<namespace>/<app>/` |
| Register in Argo CD | `geekbot register <repo> to <level>` | Nothing. An ApplicationSet makes the app from the directory. |
| Deploy | `geekbot kdeploy <app> to <level>` | A merge to `main`, **Run workflow**, `sdeploy <app> to <level>`, or `make deploy-*` |
| Argo app name | `{sl}-{namespace}--{app}--{loc}-{cluster}` | `{sl}-{namespace}--{app}`, or `{sl}-{namespace}--{app}--{loc}-{cluster}` off the default cluster |

Keep `galactus.yml` in a Seldon repo. It is still required. It does not need to run on every deploy, for example when nothing changed.

## Production

**Only engineers deploy to `prd`.** Only the most senior engineers and DevOps have access to it. Product people and other non-engineers build apps with agentic tools, and they must not promote to production without an engineer.

- Non-engineers deploy to `sbx`. Engineers deploy to `dev`, and they can put test versions on `sbx`.
- When you help someone who is not an engineer, do not add a `prd` target to `deploy.yaml`, a `prd` option to the dispatch input, or `auto-deploy-prd`. Tell them that an engineer must do the production setup and the production deploy.
- When you do not know if the user is an engineer, ask before you add anything for `prd`.
- Code review is the main gate. CI/CD can target `prd` only with reviewed code. The resolve-and-deploy interface deploys `prd` only from the default branch, and it refuses a `prd` deploy that a push started, unless `auto-deploy-prd` is set. A GitHub environment named `prd` with required reviewers is an optional extra approval.
- The deploy-a-ref interface has no environment gate, and its `ref` can name an unreviewed branch. Anyone who can run the workflow can deploy any level in its `level` options.

## Deploy, diff, and roll back

- **Dev:** a merge to `main` deploys dev, when the caller has the push or `workflow_run` trigger.
- **Any level by hand:** **Actions → Seldon Deploy → Run workflow**. In Slack, `sdeploy <app>[/<ref>] to <level>` starts the same workflow (deploy-a-ref interface).
- **Dry run:** set `dry-run`. The run renders the manifests, puts the diff against `seldon-gitops` in the run summary, and pushes nothing.
- **Roll back:** run the workflow with an older commit: `image-tag` (an 8-char sha) on resolve-and-deploy, or `ref` on deploy-a-ref.
- **From a terminal:** `make deploy-dev` runs `galactus --flat` and `witctl gitops` as **you**. It needs your own AWS session and push access to `cincpro/seldon-gitops`. Most app developers have neither, so prefer the workflow.
- **What runs now:** read `<level>-<namespace>/<app>/deployed_version` on the `seldon` branch of `cincpro/seldon-gitops`. It holds the 12-char sha of the last deploy from `main`.

## Traps that cause most failures

1. **A cancelled image build leaves no image tag.** The deploy then waits about 10 minutes and fails. The shared `image-build.yml` cancels a running build when a new one starts for the same ref, and two calls in one workflow share one slot.
2. **The deploy waits for one image only:** the app image named by `name:` in `deploy.yaml`. A second image, such as an nginx `static` image, is not checked. If it is late, its pods stay in `ImagePullBackOff`, and the old pods keep serving.
3. **The `workflow_run` trigger must name the build workflow exactly** (`workflows: ["Image Build"]`). A typo fails with no error, and no merge ever deploys.
4. **Tests do not gate the deploy.** A red test run does not stop it. Read the Actions run after a push.
5. **The level must be a target in `deploy.yaml`.** Otherwise the run stops with `deploy.yaml has no target with service_level: <level>`.
6. **A target or an app name that you remove from `deploy.yaml` stays deployed.** witctl syncs only what galactus rendered, so the old folder in `seldon-gitops` stays, and Argo CD keeps the app. To remove or rename an app, draft a platform request with the `seldon-request` skill (see [references/concepts.md](references/concepts.md#remove-or-rename-an-app)).
7. **Do not edit `seldon-gitops` by hand.** The next deploy replaces the app directory, and Argo CD prunes what is not in git. Do not put secrets there.
8. **Do not pin `@seldon-deploy-v1` before it exists.** Every run fails. Watch `cincpro/actions` PR #91 and repin on purpose.

[references/troubleshooting.md](references/troubleshooting.md) lists each failure with its cause and fix.

## Open questions

These are not documented, and nobody has confirmed an answer. Say so.

- How an app developer gets a new namespace (stack) on Seldon. Until this is settled, draft a platform request for it with the `seldon-request` skill.
- Whether geekbot needs a repo to be registered before `sdeploy` works for it. Send this question to [Discussions](https://github.com/cincpro/seldon-idp/discussions).

## Platform requests

The platform team takes requests through the **Platform Request** issue form in `cincpro/seldon-idp`. When the user needs one, use the `seldon-request` skill. It interviews the user and drafts an issue that follows the form. Questions go to Discussions, not to an issue.

## References

- [references/concepts.md](references/concepts.md) — what Seldon is, names (namespace, stack, service level), tiers, logs and metrics after a deploy, secrets, how to get resources, removing or renaming an app, where to get help.
- [references/setup.md](references/setup.md) — set up Seldon deploys for an app, from the stack to the first green deploy.
- [references/workflows.md](references/workflows.md) — the three interfaces, their inputs, a caller for each, the Dependabot gate, pinning.
- [references/troubleshooting.md](references/troubleshooting.md) — failures with their causes and fixes, and how the gitops repo and Argo CD fit together.
