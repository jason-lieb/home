# The `deploy.yaml` model (galactus 0.24)

Verified against galactus 0.24.0. For details beyond this file, read the [galactus docs](https://github.com/cincpro/galactus/tree/main/docs), but check them against [docs-to-distrust.md](docs-to-distrust.md) first; several pages state the wrong defaults.

## Contents

- [What galactus does](#what-galactus-does)
- [Top-level keys](#top-level-keys)
- [The `version:` field](#the-version-field)
- [Merge model](#merge-model)
- [Components](#components)
- [Probes and resources](#probes-and-resources)
- [Autoscaling](#autoscaling)
- [Secrets](#secrets)
- [Environment variables galactus sets](#environment-variables-galactus-sets)
- [Init containers](#init-containers)
- [PDB, RBAC, and IRSA](#pdb-rbac-and-irsa)
- [Commands: `bash` and `migrate`](#commands-bash-and-migrate)
- [Validate and preview](#validate-and-preview)
- [Onboard a new app](#onboard-a-new-app)

## What galactus does

galactus is a CLI that reads one file, `deploy.yaml` at the app repo root, and writes Kubernetes manifests into the **geekstack** gitops repo (`kube-config/<namespace>/<app>/targets/<service_level>/<loc>/<cluster>/`). A shared GitHub Action runs it on push, Argo CD applies the output, and geekbot (Slack) registers and deploys apps. It is not an operator; nothing runs in the cluster.

From a short `deploy.yaml` it makes: Deployments, Services, HTTPRoutes (or Traefik Ingresses), probes, Vault secret sync (VSO), KEDA autoscaling, VPA, PodDisruptionBudgets, ServiceMonitors, RBAC and IRSA, init containers, CronJobs, and Argo WorkflowTemplates for one-off commands.

## Top-level keys

```yaml
version: "~0.24.0"       # always set it; see below
org: witco               # witco (default) | realgeeks | hello_condo
namespace: domain-witco  # required
name: sigil              # required: resource names, Vault paths, default image, default KEDA group
team_name: platform      # required
repo_slug: cincpro/sigil # required, case-sensitive
sentry_dsn: https://...  # optional: adds SENTRY_DSN and SENTRY_ENVIRONMENT

environment:             # any component field is legal here and applies to every component
  LOG_LEVEL: info
expose: { enabled: false }

components: [...]        # required
targets: [...]           # no targets means nothing is generated
```

- **Typos at the root are ignored with no error.** Typos inside a component are errors. Check root keys by eye.
- `environment` values must be quoted strings: `PORT: "8080"`, not `PORT: 8080`.
- `image_name` (default `<mgt ECR>/{name}`) sets the image repository. Give it without a tag; galactus always appends the build tag.
- `default_branch` and a target's `domain` do nothing. A target's `is_default` and a root or target `secrets:` key are errors.

## The `version:` field

- npm/Cargo semver. On 0.x the minor is the breaking part: `~0.24.0`, `^0.24.0`, and `0.24` all mean "0.24.x". Use `"~0.24.0"`.
- **Omitting `version:` runs galactus 0.15.1**, an old, different dialect. Always pin.
- galactus downloads the highest release that matches and runs it. The download needs AWS credentials. The pin is read only from `./deploy.yaml` in the current directory, so run galactus from the repo root.
- Release candidates (`-rc`) never match a range.
- Upgrade one minor at a time. See [upgrade-to-0.24.md](upgrade-to-0.24.md).

## Merge model

Each component's final config merges these layers, lowest first:

1. command template defaults (`command` components);
2. the global component (fields at the root);
3. the entry in `components:`;
4. fields set directly on a target (they apply to **every** component in that target);
5. the entry in `targets[].components[]`.

| Field | How a higher layer merges |
| --- | --- |
| `environment` | Map merge; higher keys win. |
| `secrets_from` | List merge, deduped by path. |
| `command`, `args` | Replaced only when the higher layer is non-empty. |
| `parameters` | Merged by `name`. |
| `env` (raw Kubernetes list) | Replaced as a whole. |
| `port`, `image`, `schedule`, `database_users`, `valkey`, `memcached`, `memory_limit`, `template` | Replaced. |
| `cpu`, `memory`, probes, `service`, `deployment`, `rbac`, `init`, `pdb`, `expose`, raw CRD blocks | Deep merge. |
| `autoscaling` | Field merge only when `type` is the same; another `type` replaces the block. |

Traps:

- A `targets[].components[]` entry is matched by `name` (or by type when unnamed). **An entry that matches nothing creates a new workload**, with no error. A base `{type: api, name: public}` needs `name: public` in the target.
- An autoscaling override must repeat `type` and its required fields. `{type: cpu, max_replicas: 20}` also resets `utilization` to 0.85. A `kafka` override must repeat `consumer_group` and `topics`.
- Feature fields (`expose`, `rbac`, `pdb`, `init`, and their nested blocks) take `{enabled: bool, ...}`. A bare `true` or `false` is a parse error. A block without `enabled:` never turns a feature back on that a lower layer turned off.
- Raw Kubernetes blocks nest fully: `deployment: {spec: {replicas: 1}}`, not `deployment: {replicas: 1}`. CRD escape hatches (`scaled_object`, `vertical_pod_autoscaler`, `service_monitor`, `workflow_template`, `iam_*`) take their content under `spec_overlay:`. Anything else under them is dropped with no error.

## Components

`type` defaults to `web`; `name` defaults to the type. `- api` is short for `- {type: api}`.

| Type | Generates | Notes |
| --- | --- | --- |
| `api` | Deployment, Service, ServiceMonitor (`/metrics`), VPA, KEDA, PDB, HTTPRoute | Port 8000. Hostname base `{app}-{component}`. |
| `web` | Same as `api` | Hostname base is `{app}`, so two `web` components collide. |
| `worker` | Deployment, VPA, KEDA, PDB | No port, no probes. |
| `worker-kafka` | Deployment, VPA, KEDA, PDB | For euphony and prosody workers. See [event-bus.md](event-bus.md). |
| `worker-celery`, `worker-sidekiq`, `worker-resque` | Deployment, KEDA, PDB (VPA for celery) | Default commands for each framework. Resque scales on queue length from `REDIS_URL`. |
| `cronjob` | CronJob | `schedule:` is required in practice (the default is not valid cron). `cpu` and `memory` are ignored: no requests or limits. Defaults: `concurrencyPolicy: Forbid`, `backoffLimit: 0`, history 1 succeeded / 3 failed. Raw overrides under `cronjob: {spec: ...}`. |
| `command` | Argo WorkflowTemplate `{app}-command-{name}` | A one-off run. See [Commands](#commands-bash-and-migrate). |

Node apps usually ship one image whose `dist/main.js` picks the entry point from argv (radiant `execute({...})`). Keep the component `name:`, its `args`, and the execute key the same.

## Probes and resources

- `api`, `web`, and `worker-kafka` get default probes on the named port `http` (the component `port:`): liveness `/healthz/live` (initial delay 30 s, period 10 s), readiness `/healthz/ready` (5 s, 5 s). `worker-kafka` uses prosody's `/livez` and `/readyz` instead.
- Your `liveness_probe` or `readiness_probe` is **deep-merged onto the default**. Changing `httpGet.path` or `port` works. An `exec` or `tcpSocket` probe keeps the default `httpGet` too, and Kubernetes rejects a probe with two handlers. Use `httpGet` probes.
- Requests default to `100m` CPU and `128Mi` memory. **The memory limit is always 2× the memory request**, and no CPU limit is set. `memory_limit` works only on `command` components.

## Autoscaling

On by default. The galactus docs say "off"; they are wrong.

| Type | Default for | Settings |
| --- | --- | --- |
| `cpu` | `api`, `web`, `worker`, `worker-celery`, `worker-sidekiq` | `utilization` (0.85), `min_replicas` (2), `max_replicas` (10) |
| `kafka` | `worker-kafka` | `consumer_group` and `topics` (both required when you write the block); max 16 |
| `kafka_consumer_group` | — | `consumer_group` only (lag over all its topics); max 16 |
| `metric` | — | `expression` (PromQL on Mimir) |
| `resque` | `worker-resque` | `address`, `queues` |
| `off` | — | One replica, no KEDA, no PDB. `min_replicas`/`max_replicas` do nothing; use `deployment: {spec: {replicas: N}}`. |

- Minimum replicas is 2 everywhere. Use `min_replicas: 1` on purpose for singletons (that also removes the PDB).
- Kafka scaling adds one pod per 30 s. It also scales on prosody's overdue timers for the group.

## Secrets

Vault paths synced to every component automatically (never list them in `secrets_from`; that is an error):

| Secret | Vault path |
| --- | --- |
| App | `{sl}/{namespace}/{app}/app` |
| Platform | `{sl}/seldon/platform` (shared ConfigMap and Secret) |
| Postgres user | `{sl}/{namespace}/{app}/databases/pg-{appnodashes}-{user}` |
| Valkey (`valkey: true`) | `{sl}/{namespace}/{app}/databases/valkey-{appnodashes}` |
| Memcached (`memcached: true`) | `{sl}/{namespace}/{app}/databases/memcached-{appnodashes}` |

- `{appnodashes}` is the app name with non-alphanumerics removed (`my-app` → `myapp`).
- `database_users` defaults to `[rw]`; `init.database_users` defaults to `[rw, migrate]`. They are independent. Set `[]` to opt out of either. An app whose main process runs migrations needs `database_users: [rw, migrate]`.
- `valkey: true` and `memcached: true` (0.23.1 and later) are plain booleans, not feature blocks.
- `secrets_from: [{path: prd/shared/stripe, version: 3}]` adds other paths. VSO syncs the **whole path**: every field becomes an env var with exactly that name. There is no per-field selection.
- Load order, later wins: platform ConfigMap, platform Secret, your `environment:` (as a ConfigMap), then each secret. So **a Vault field with the same name as an `environment:` key wins** at runtime. Pod `env:` beats all of them.
- Do not put secret values in `environment:`. Put them in Vault.

## Environment variables galactus sets

- In the pod `env` (override only with `env:`): `KUBE_POD_IP`, `KUBE_NODE_IP`, `OTEL_EXPORTER_OTLP_ENDPOINT`.
- Defaults you can override in `environment:`: `OTEL_ENABLED=true`, `OTEL_SERVICE_NAME={app}` (the app, not the component), `OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf`, `OTEL_RESOURCE_ATTRIBUTES=service.namespace=…,team=…,component={type}`.
- With `sentry_dsn`: `SENTRY_DSN` and `SENTRY_ENVIRONMENT={app}-{component}--{sl}`.
- `worker-kafka` adds prosody variables; see [event-bus.md](event-bus.md).

## Init containers

On by default for every component. The `seldon-init` container runs `./scripts/init.sh` from the component's image, with the same env and secrets. **If the image has no executable `./scripts/init.sh`, pods never start.** Add the script or turn init off:

```yaml
init: { enabled: false }          # root: every component; or per component
```

Other fields: `image`, `command`, `args`, `database_users` (default `[rw, migrate]`), `shared_volume: {path: /shared}`. Running migrations in init keeps `migrate` credentials out of the long-running container:

```yaml
  - type: web
    database_users: [rw]
    init:
      database_users: [rw, migrate]
```

## PDB, RBAC, and IRSA

- A PDB (`maxUnavailable: 1`) is generated for `api`, `web`, and workers with more than one replica. Tune with `pdb: {min_available: N}` or `pdb: {max_unavailable: N}`, not both.
- RBAC is opt-in. `rbac: {enabled: true}` makes a ServiceAccount. `rbac: {irsa: {enabled: true}}` adds an AWS IAM role. **The default IAM policy grants nothing**; supply one:

  ```yaml
  rbac:
    irsa:
      enabled: true
      iam_policy:
        spec_overlay:
          forProvider:
            policy: '{"Version":"2012-10-17","Statement":[...]}'
  ```

- IRSA works only for Witco `prd`, `dev`, and `sbx`.

## Commands: `bash` and `migrate`

```yaml
  - type: command
    name: bash
    template: bash               # a shell that sleeps for `ttl` minutes (default 60)
  - type: command
    name: migrate
    template: migrate
    parameters:
      - name: migration_command
        value: "node dist/main.js migrate"
```

- `migrate` installs `jq` and `awscli` with `apt`, reads RDS credentials from Secrets Manager (instance `{loc_code}-{app}-db0`), and then runs `migration_command`. It needs a **Debian-based image that runs as root**; Alpine and distroless images fail.
- Pass your command as the `migration_command` parameter. Setting `command:` or `args:` replaces the credential script.
- Custom commands declare `parameters: [{name, value?}]` and read them as `{{inputs.parameters.<name>}}`, best through an `env:` entry.
- A command runs as an Argo Workflow from its WorkflowTemplate (started through Bambam).

## Validate and preview

| Command | Effect |
| --- | --- |
| `galactus validate` | Parses, merges, and runs every rule. Lists all errors at once with line pointers. Writes nothing. **Use this first.** |
| `galactus diff` | Renders and diffs against geekstack `master`. The best preview before a merge; needs GitHub access. |
| `galactus deploy.yaml <scratch-dir>` | Renders the manifests. **It empties `<scratch-dir>` first**; never point it at `.` or a real checkout. |

- Run from the repo root so the `version:` pin applies; the download needs AWS credentials. `--no-version-check` uses the installed binary, which may be older than the pin.
- There is no JSON schema for `deploy.yaml`.
- The Galactus check on the pull request shows the same errors.
- To see what the merge produced, read the generated ConfigMap in geekstack.

## Onboard a new app

These steps are for the geekstack path. For a Seldon deploy, keep steps 1 and 2, skip steps 4 to 6, and follow `setup.md` in the `seldon-deploy` skill.

1. Write `deploy.yaml` by hand from the example in `SKILL.md`. **Do not use `galactus init`**: it omits `version:` and `repo_slug`, writes a bad org name, overwrites the file, and needs a terminal.
2. Add `.github/workflows/galactus.yml`:

   ```yaml
   name: Galactus
   on: push
   permissions:
     contents: read
     statuses: write
     id-token: write
   jobs:
     galactus:
       uses: cincpro/actions/.github/workflows/galactus.yml@galactus-v2
       secrets: inherit
   ```

3. For a new namespace, ask the platform team first with a platform request (use the `seldon-request` skill).
4. Register once: `geekbot register <repo_slug> to <service_level>`.
5. Check Argo CD for `{sl}-{namespace}--{app}--{loc}-{cluster}`, for example `dev-domain-witco--sigil--am71-kube0`.
6. Deploy: `geekbot kdeploy <app> to <service_level>`.
