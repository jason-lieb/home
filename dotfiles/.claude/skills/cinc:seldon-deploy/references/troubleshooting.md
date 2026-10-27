# Troubleshoot a Seldon deploy

Read the run summary first. Both interfaces write the image tag, the stack, and an Argo CD link there. Then find the symptom below.

## Contents

- [How the parts fit](#how-the-parts-fit)
- [The deploy did not start](#the-deploy-did-not-start)
- [The deploy failed](#the-deploy-failed)
- [The deploy passed, but the app is wrong](#the-deploy-passed-but-the-app-is-wrong)

## How the parts fit

- **`cincpro/seldon-gitops`, branch `seldon`:** one folder for each app, `<level>-<namespace>/<app>/`, with raw manifests named `<api>-<version>_<kind>_<namespace>_<name>.yaml`. A target on a cluster that is not the default for its level gets a sibling folder, `<app>--<loc>-<cluster>`. `deployed_version` holds the 12-char sha of the last deploy from `main`. Nothing goes on `main` of this repo.
- **`cincpro/seldon-gitops`, branch `infra`:** the platform layer: namespaces, Vault auth, and the Argo CD `AppProject` and `ApplicationSet` objects. App developers do not change it.
- **ApplicationSets:** `<level>-seldon-gitops` turns each `<level>-*/*` folder into the app `<stack>--<app>` on the default cluster. `<level>-seldon-gitops-per-cluster` does the same for the `--<loc>-<cluster>` folders. Both sync automatically, prune, and self-heal.
- **Argo CD:** `https://argocd.witco.net/applications?search=<stack>--<app>`.

## The deploy did not start

| Symptom | Cause | Fix |
|---|---|---|
| A merge did not deploy, and no run exists | The `workflow_run` trigger names the wrong workflow. A typo fails with no error. | Make `workflows:` match the `name:` of the image build workflow exactly. Set `branches:` to the default branch. |
| The run was skipped after a merge | The image build did not succeed. Deploy-a-ref skips a `workflow_run` whose build failed. | Fix the build, then push or run the deploy by hand. |
| Every run fails at once with a workflow not found error | The caller pins `seldon-deploy.yml@feat/seldon-deploy`. That file is gone. | Repin. See [workflows.md](workflows.md#which-interface-to-use). |
| `sdeploy` does nothing | Not known. The caller may lack the dispatch inputs that geekbot sends (`ref`, `level`, `requested-by`), or geekbot may need a registration. | Check the inputs, then ask in [Discussions](https://github.com/cincpro/seldon-idp/discussions). |

## The deploy failed

| Symptom | Cause | Fix |
|---|---|---|
| It waits about 10 minutes, then `<repo>:<tag> never appeared in ECR` | No image has that tag. The build failed or was cancelled, or the image name is wrong. | Check the image build for that commit. A cancelled build writes no tag: push again, or run the deploy with an older `image-tag` or `ref` that has an image. Make sure that `image-name` in the build matches `name:` in `deploy.yaml`. |
| `Image Built & Pushed` failure or pending (deploy-a-ref) | The build failed, or it finished with the status still pending. A failed build can leave the status pending with a green run. | Read the build log for that commit, not the status. Fix the build. |
| `deploy.yaml has no target with service_level: <level>` | The level is not a target. | Add the target (an engineer, for `prd`), or pick another level. |
| `prd deploys only from main` or `a push cannot deploy prd` | The resolve-and-deploy production rules. | Start the `prd` deploy from **Run workflow** on the default branch. |
| `no single <image> image is running in <level>-<namespace>` | A `prd` promotion found no image, or more than one, in the lower level. | Deploy the lower level first, or pass `image-tag`. |
| `... is not an ancestor of ...` | The target level runs a commit that is newer than, or beside, what you deploy. witctl refuses so that an old checkout cannot overwrite a newer deploy. | Deploy a commit that contains the running one. To roll back on purpose, pass `image-tag` or `ref`, which skips the check. |
| The ownership check fails (deploy-a-ref) | The gitops folder holds the image of another repo with the same app `name`. | Rename the app in `deploy.yaml`, or ask the platform team. |
| The ReleaseBot token step fails | ReleaseBot is not installed on `galactus`, `witco-cli`, or `seldon-gitops`, or the organization secret is not visible. | Ask the platform team. Do not add a repo secret. |
| galactus fails with a 403 (resolve-and-deploy) | That interface installs the newest galactus, which then downloads the pinned version. | Read the CI notes in the `galactus` skill's `anti-patterns.md`. |
| `the Argo CD wait needs the ARGOCD_AUTH_TOKEN secret` | The caller does not pass the secret. | Add `ARGOCD_AUTH_TOKEN: ${{ secrets.ARGOCD_AUTH_TOKEN }}` under `secrets:`. |
| The Argo CD wait times out | The app did not become Synced and Healthy in 600 seconds. Pods do not start, probes fail, or an image is missing. | Open the Argo CD app and read the events of the failing resource. Raise `argocd-timeout` only for a slow but healthy rollout. |
| The run is red because of a Dependabot alert | The `alert-gate` job found an open critical alert. | Fix or dismiss the alert, or run by hand with `ignore-alerts`. |

## The deploy passed, but the app is wrong

| Symptom | Cause | Fix |
|---|---|---|
| A second component is in `ImagePullBackOff` | The deploy waits for the app image only. A second image, such as `<app>-static`, was not pushed for this commit. | Make the build push every image for every commit. The old pods keep serving until it arrives. |
| No Argo CD app appears | The stack has no `AppProject`, or the folder name does not match `<level>-*/*`. | Check the stack (see [setup.md](setup.md#1-check-that-the-stack-exists)). |
| An app runs on a cluster that you removed from `deploy.yaml` | witctl syncs only what galactus rendered. The old `--<loc>-<cluster>` folder stays. | Draft a platform request (use the `seldon-request` skill) to remove the folder from `seldon-gitops` and clean up the cluster. |
| A hand edit in `seldon-gitops` is gone | The next deploy replaced the folder, or Argo CD reverted a change in the cluster. | Make every change in `deploy.yaml`. |
| The deploy shipped with failing tests | Tests do not gate the deploy. | Read the Actions run after each push. Make the test workflow required on pull requests. |
| `make deploy-dev` fails with an access error | It runs as you, with your AWS session and push access to `seldon-gitops`. | Use the workflow, which uses ReleaseBot. |
