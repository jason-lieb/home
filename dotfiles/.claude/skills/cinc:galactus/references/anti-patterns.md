# Known `deploy.yaml` anti-patterns

Mistakes found in the `deploy.yaml` files of CincPro apps (survey of October 2026). Use this list to review a `deploy.yaml`, to debug a deploy, or to check one before and after an upgrade. Each entry gives what goes wrong, how to find it, and the fix.

## Contents

- [Version pins](#version-pins)
- [Settings that do nothing](#settings-that-do-nothing)
- [Probes and exposure](#probes-and-exposure)
- [Event-bus workers](#event-bus-workers)
- [Secrets and environment](#secrets-and-environment)
- [Structure](#structure)
- [CI](#ci)

## Version pins

### No `version:`, or a floating one

- **Effect:** No pin runs galactus 0.15.1, an old dialect. A floating pin (`"0"` or `"*"`) moves to each new minor by itself, and on 0.x every minor can break. A floating app moved to 0.24 and to the Envoy gateway with no change in its repo.
- **Find:** `grep -n '^version' deploy.yaml`.
- **Fix:** Pin a minor with a tilde, quoted: `version: "~0.24.0"`. Upgrade on purpose.

### Unquoted version

- **Effect:** galactus reads `version: 0.20` as a string, but other YAML tools read it as the number `0.2`.
- **Fix:** Quote it.

### Stuck on 0.21 because of legacy secrets

- **Effect:** Most apps pin 0.21 because 0.22 rejects their `secrets:` lists and bare-bool features. They miss every fix since.
- **Find:** `grep -nE '^\s*secrets:|:\s*(true|false)\s*$' deploy.yaml`.
- **Fix:** Do the 0.21 → 0.22 step in [upgrade-to-0.24.md](upgrade-to-0.24.md). Move the app's values to the canonical Vault path first.

## Settings that do nothing

galactus ignores these with no error. Each one makes a reader believe something that is not true.

| Setting | Why it does nothing | Instead |
| --- | --- | --- |
| `memory_limit` on `api`, `web`, or a worker | The limit is always 2× `memory` | Raise `memory`; `memory_limit` works only on `command` |
| `cpu`, `memory`, `memory_limit` on a `cronjob` | Cronjobs get no requests or limits | A raw `cronjob: {spec: ...}` override, if you need them |
| `scaled_object`, `vertical_pod_autoscaler`, `service_monitor` content not under `spec_overlay:` | Only `spec_overlay` is read | Nest it under `spec_overlay:` |
| `scaled_object.spec_overlay.minReplicaCount` / `maxReplicaCount` | Works, but hides the bounds from readers and from the merge | `autoscaling: {min_replicas, max_replicas}` |
| Unknown root keys (for example `sentry_project_id`) | Root typos are ignored | Delete them; check root keys by eye |
| `min_replicas` / `max_replicas` with `autoscaling: {type: off}` | `off` is always one replica | `deployment: {spec: {replicas: N}}` |
| `pod_disruption_budget: {maxUnavailable: 1}` (flat) | Before 0.22 ignored; from 0.22 an error | `pdb: {max_unavailable: 1}` |
| `loc_code: am16` on a prd target, `image_name` equal to the default | Already the default | Delete them |

## Probes and exposure

### Default probes that the app does not serve

- **Effect:** `api` and `web` get liveness `/healthz/live` and readiness `/healthz/ready` on the `http` port by default. An app with no such routes is restarted and never ready. Many apps set no probes and depend on these defaults without knowing it.
- **Find:** An `api` or `web` component with no `liveness_probe` and `readiness_probe`; then check the app's routes.
- **Fix:** Serve both paths, or set the probes to paths the app serves. Use `httpGet` probes; an `exec` probe merges with the default `httpGet` and Kubernetes rejects it.

### Custom hosts on a domain the gateway does not accept

- **Effect:** `expose.external` accepts only `witco.net`, `cincapi.com`, and `cinccrm.com`. An app with hosts on other domains (in an old `ingress.spec`) cannot move to the gateway.
- **Fix:** Keep the Traefik block for those hosts, and ask the platform team about the domain with a platform request (use the `seldon-request` skill).

### `ingress: false`, or `ingress:` after the bump to 0.24

- **Fix:** See [expose.md](expose.md). `expose: {enabled: false}` replaces `ingress: {enabled: false}`.

## Event-bus workers

### KEDA watches the wrong consumer group

- **Effect:** A `worker-kafka` with no `autoscaling` block scales on the group named by the top-level `name:`. When `PROSODY_GROUP_ID` differs (for example `<app>-worker`), the worker never scales on lag.
- **Find:** Compare each `worker-kafka`'s `PROSODY_GROUP_ID` (in `deploy.yaml` or in code) with `autoscaling.consumer_group`, or with `name:` when that is not set.
- **Fix:** `autoscaling: {type: kafka, consumer_group: <PROSODY_GROUP_ID>, topics: [...]}`.

### Kafka worker scaled on CPU

- **Effect:** `autoscaling: {type: cpu}` on a Kafka consumer does not react to lag; a backlog grows while CPU stays low.
- **Fix:** `type: kafka` or `type: kafka_consumer_group`.

### Missing event-bus variables on components that are not `worker-kafka`

- **Effect:** galactus sets the Kafka and Cassandra variables only on `worker-kafka`. An `api` or `cronjob` that publishes fails at client creation. Separately, `PROSODY_SUBSYSTEM` is never set by galactus, and euphony 14.2 and later need it.
- **Fix:** See [event-bus.md](event-bus.md).

### Dead or redundant event-bus config

- `EUPHONY_CONSUMER`: dead; delete.
- `PROSODY_BOOTSTRAP_SERVERS` and `PROSODY_CASSANDRA_NODES` on a `worker-kafka` with the platform values: redundant (galactus sets them). Keep them on other component types.
- `PROSODY_SUBSCRIBED_TOPICS`: not dead on `worker-kafka`; the default KEDA trigger reads it.

## Secrets and environment

### Secret values in `environment:`

- **Effect:** `deploy.yaml` is in git, and its `environment:` becomes a ConfigMap. Client secrets, passwords, and API keys written there are exposed to everyone with repo or cluster read access.
- **Find:** `environment:` keys named `*SECRET*`, `*PASSWORD*`, `*TOKEN*`, `*KEY*` with literal values.
- **Fix:** Move the value to the app's Vault path (`{sl}/{namespace}/{app}/app`) under the same name, remove it from `deploy.yaml`, and rotate it, because it is in git history.

### A root `secrets_from` with one service level's path

- **Effect:** `secrets_from: [{path: prd/shared/x}]` at the root gives dev pods prd secrets, or breaks when a dev target is added.
- **Fix:** Put `secrets_from` on each target, with that target's service level in the path.

### Defaults written out by hand

- `OTEL_SERVICE_NAME` equal to the app name, and `OTEL_ENABLED: "true"`: already the defaults.
- `SENTRY_DSN` in `environment:` and a hand-written `SENTRY_ENVIRONMENT`: use the top-level `sentry_dsn:` field, which sets both.
- `NODE_ENV: development` (or similar) on a prd target.

## Structure

### The same values repeated in every target

- **Effect:** A change must be made in each target, and the targets drift apart.
- **Find:** Keys with the same value in every `targets[]` entry or every `targets[].components[]` entry.
- **Fix:** Move them to the component in `components:`, or to the root.

### Target component entries that match nothing

- **Effect:** An entry in `targets[].components[]` whose `name` is not in `components:` deploys a new workload.
- **Fix:** Match the name exactly, or add the component to `components:` on purpose.

### A never-firing schedule to turn a cronjob off

- **Effect:** `schedule: "0 0 31 2 *"` hides intent and still deploys the CronJob.
- **Fix:** `cronjob: {spec: {suspend: true}}`, or remove the component.

### Hard-coded image tags in raw sidecars and init containers

- **Effect:** Containers added through `deployment.spec.template.spec` with `<image>:latest` do not follow the build tag.
- **Fix:** Use galactus's own `init` block where possible, and keep raw containers to what galactus cannot express.

## CI

- **The galactus workflow with no `deploy.yaml`:** the job reports success and does nothing. Remove the workflow or add the file.
- **Old workflow refs** (`galactus.yml@galactus-v1`) and reusable workflows pinned to branches: pin to the published tag (`@galactus-v2`). The Seldon deploy workflows are the exception: they have no tag yet, so a caller pins a commit or a branch (see the `seldon-deploy` skill).
- **Pipelines that install the latest galactus:** with an exact or older pin, galactus must download the pinned build, which can fail when the CI role cannot read the release bucket. When a deploy job fails with a 403 after a galactus release, check the pin against the installed version.
