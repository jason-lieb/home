---
name: galactus
description: "Write, change, review, and upgrade galactus deploy.yaml files that deploy CincPro (Witco) apps to Kubernetes. Use whenever a repo has a deploy.yaml with version, namespace, components, and targets keys, or a .github/workflows/galactus.yml, or the user wants to add or change a component (api, web, worker, worker-kafka, cronjob, command), expose an app or change its hostname, use expose or replace ingress, set autoscaling or KEDA, add secrets, Vault paths, database users, valkey or memcached, set probes or resources, pick a cluster or target, fix a galactus validation error, review a deploy.yaml for known mistakes, onboard an app to geekstack, or upgrade galactus to 0.24. Not for the Seldon deploy pipeline (seldon-deploy.yml, seldon-gitops, Argo CD sync, rollbacks; use seldon-deploy), for app code that publishes or consumes events (use event-bus), or for event schemas (use event-schemas)."
---

# galactus: deploy an app with `deploy.yaml`

galactus reads `deploy.yaml` at the app repo root and writes Kubernetes manifests into a gitops repo, which Argo CD applies. There are two paths: the `galactus.yml` workflow writes to geekstack, and a Seldon deploy (`seldon-deploy.yml`) runs `galactus --flat` and writes to `cincpro/seldon-gitops`. This skill covers writing and upgrading `deploy.yaml`, not working on galactus itself. For the Seldon pipeline, its setup, and its failures, use the `seldon-deploy` skill.

## Step 1: check the version first

The content here is verified against galactus 0.24.0 ([sources.json](sources.json)).

1. Run the drift check from the project root, once per session. It reports the project's pins and whether an upstream release has moved past this skill, and it caches the upstream part for a day.

   ```bash
   node "<skill-dir>/scripts/check-drift.mjs" "<skill-dir>" --skill galactus --project .
   ```

   Replace `<skill-dir>` with this skill's base directory. If Node is not available, read `version:` in `deploy.yaml` yourself.
2. Use the pin table (`STATUS`):
   - **`older`:** say so (most apps pin 0.21, many 0.23). Keys differ by version: `secrets:` exists only before 0.22, `secrets_from:` and `{enabled: ...}` features only from 0.22, `ingress:` only before 0.24, and `expose:` only from 0.24. Answer for the pinned version, and use [references/upgrade-to-0.24.md](references/upgrade-to-0.24.md) for upgrades. Never give 0.24 advice to a 0.23 app without saying which version it is for.
   - **`newer`:** say that this skill may be out of date for the app. Read the galactus CHANGELOG and `docs/upgrading/` for the gap before you rely on the skill, and recommend an update issue.
   - **`same`:** go on.
3. Use the upstream table (`ACTION`):
   - **`none: ...`** (no `gh`, offline): go on, and say nothing about it.
   - **`mention only`:** say in one sentence that a newer release exists.
   - **`recommend an update issue`:** follow the update issue steps below.

**Update issue.** Look for an open issue first with `gh issue list -R cincpro/claude-plugins --label skill-drift --search galactus`, and point to it if one exists. Else run the drift check again with `--issue-draft galactus`, and show its title and body as a ready-to-run `gh issue create -R cincpro/claude-plugins --label skill-drift` command. If it prints no draft, use the title `docs(galactus): update for <package> <version>`. Run the command only after the user approves it.

**`no version`** in the pin table means that `deploy.yaml` has no `version:`. That runs galactus 0.15.1, an old dialect; say so and plan a rewrite.

Authority order: `galactus validate` and the generated manifests > this skill > the galactus `docs/` > `README.md` > `CLAUDE.md` > `PRD.md`. Several galactus docs state the wrong defaults; [references/docs-to-distrust.md](references/docs-to-distrust.md) lists them.

## A modern `deploy.yaml`

```yaml
version: "~0.24.0"
org: witco
namespace: domain-witco
name: myapp
team_name: platform
repo_slug: cincpro/myapp
sentry_dsn: https://...

environment:                          # applies to every component
  LOG_LEVEL: info                     # values are quoted strings
expose:                               # keep the 0.23 Traefik Ingress for now
  traefik: { enabled: true }
  external: { enabled: false }

components:
  - type: api
    port: 3000
    database_users: [rw, migrate]
  - type: worker-kafka
    name: worker
    command: ["node"]
    args: ["dist/main.js", "worker"]
    environment:
      PROSODY_GROUP_ID: myapp-worker
    autoscaling: { type: kafka, consumer_group: myapp-worker, topics: [witco.lead-events] }
  - type: command
    name: bash
    template: bash
  - type: command
    name: migrate
    template: migrate
    parameters: [{ name: migration_command, value: "node dist/main.js migrate" }]

targets:
  - service_level: dev
  - service_level: prd
```

## The model in brief

- **Layers**, lowest first: root fields (the "global component") → `components[]` → fields on a target (apply to **all** components in it) → `targets[].components[]`. Maps merge, most blocks deep-merge, lists and scalars replace. Details: [references/deploy-yaml.md](references/deploy-yaml.md#merge-model).
- **Component types:** `api` and `web` (Service, HTTPRoute, probes), `worker`, `worker-kafka` (euphony and prosody), `worker-celery`, `worker-sidekiq`, `worker-resque`, `cronjob`, `command` (one-off Argo workflow).
- **Defaults that surprise:** autoscaling is **on** (CPU at 85 %, min 2 replicas); an init container runs `./scripts/init.sh` from the image; memory limit = 2× request, no CPU limit; `database_users` is `[rw]`; `api` and `web` get public hostnames and probe `/healthz/live` and `/healthz/ready`, so the app must serve those paths or set its own probes.
- **Secrets:** the app's own Vault path and its database users are synced automatically; `secrets_from` adds other paths, whole. `valkey: true` and `memcached: true` add cache credentials.
- **Exposure (0.24):** `expose:` replaced `ingress:`. By default `api` and `web` get a Gateway API HTTPRoute on Envoy. See [references/expose.md](references/expose.md).
- **Clusters:** `service_level` picks the default cluster; `loc_code` and `cluster_name` pick another. See [references/clusters.md](references/clusters.md).

## Before you hand back a change

1. Run `galactus validate` from the repo root. It lists every error at once and writes nothing. It needs AWS credentials to download the pinned version.
2. Run `galactus diff` to compare the result with geekstack `master`. For an app on the Seldon path, run the deploy workflow with `dry-run` instead; it diffs against `cincpro/seldon-gitops`.
3. Never run `galactus generate` (the default command) with an output folder that holds anything you need: it empties the folder first.

If you cannot run galactus, say so; the pull request's Galactus check runs the same validation.

## Traps that cause most bugs

1. **No `version:`** runs 0.15.1. Always pin, as `"~0.24.0"`.
2. **A version bump to 0.24 moves DNS to Envoy** for every `api` and `web`, even with no `ingress:` key. Ship the bump with the keep-Traefik block above.
3. **`ingress:` is a parse error in 0.24.** `expose: {traefik: {enabled: true}}` alone fails too; it also needs `external: {enabled: false}`.
4. **Typos at the root are ignored** with no error; typos in a component are errors.
5. **A `targets[].components[]` entry that matches no component** creates an extra workload.
6. **An autoscaling override must repeat `type`** and its required fields, or it replaces the block.
7. **Feature fields take objects:** `init: {enabled: false}`, not `init: false`. `environment` values must be quoted.
8. **An image without `./scripts/init.sh`** never starts. Add the script or set `init: {enabled: false}`.
9. **`worker-kafka` KEDA watches the app `name:`** by default. Set `autoscaling.consumer_group` to `PROSODY_GROUP_ID`.
10. **galactus never sets `PROSODY_SUBSYSTEM`**, and sets Kafka and Cassandra variables on `worker-kafka` only. See [references/event-bus.md](references/event-bus.md).
11. **A Vault field with the same name as an `environment:` key wins** at runtime.
12. **Do not use `galactus init`.** It writes a file that does not parse.

To review or debug an existing `deploy.yaml`, check it against [references/anti-patterns.md](references/anti-patterns.md).

## References

- [references/deploy-yaml.md](references/deploy-yaml.md) — top-level keys, `version:`, merge model, components, probes, resources, autoscaling, secrets, env, init, RBAC and IRSA, commands, validation, onboarding.
- [references/expose.md](references/expose.md) — `expose:` syntax, what the 0.24 bump does, safe migration to the gateway, several clusters.
- [references/upgrade-to-0.24.md](references/upgrade-to-0.24.md) — upgrade steps from 0.21 to 0.24, with what the upstream guides leave out.
- [references/clusters.md](references/clusters.md) — orgs, service levels, clusters, Traefik and gateway availability.
- [references/event-bus.md](references/event-bus.md) — `worker-kafka`, prosody variables, KEDA, images for event-bus apps.
- [references/docs-to-distrust.md](references/docs-to-distrust.md) — galactus docs that are wrong at 0.24.0.
- [references/anti-patterns.md](references/anti-patterns.md) — mistakes found in real `deploy.yaml` files, each with how to find and fix it. Read it when you review, debug, or upgrade.
