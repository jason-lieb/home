# Docs to distrust in the galactus repo (0.24.0)

Authority order: what `galactus validate` and the generated manifests show > this skill > the galactus `docs/` > `README.md` > `CLAUDE.md` > `PRD.md`. When a galactus doc below disagrees with this skill, trust this skill.

| Upstream doc | Says | Actually |
| --- | --- | --- |
| `docs/advanced/autoscaling.md` | Autoscaling defaults to off for `api`, `web`, `worker` | CPU at 85 %, min 2, max 10 |
| `docs/advanced/autoscaling.md` | min and max replicas are not configurable | `min_replicas` and `max_replicas` work on every type except `off` |
| `docs/advanced/autoscaling.md` | Kafka: min 1, max 10, scales to zero | min 2, max 16, no scale to zero |
| `docs/components/workers.md` | Workers default to no autoscaling; OTLP over gRPC | `cpu` (`worker`, celery, sidekiq), `resque` (resque); OTLP `http/protobuf` |
| `docs/components/cronjob.md` | History limits 3 succeeded / 1 failed | 1 succeeded / 3 failed |
| `docs/configuration/environment.md` | Platform variables cannot be overridden; OTLP gRPC; one Vault secret each for rw, ro, migrate | They can be overridden (pod `env` ones only through `env:`); `http/protobuf`; default users are `[rw]` |
| `docs/upgrading/0.23-to-0.24.md` (summary row) and the `ingress:` parse error | `ingress: {enabled: true}` → `expose: {traefik: {enabled: true}}` | Also needs `external: {enabled: false}`, or it fails with `dns_claimed_twice` |
| `docs/upgrading/*` | (nothing about Realgeeks `prd`) | `am14-kube1` was removed in 0.24; Realgeeks `prd` targets fail |
| `docs/upgrading/0.22-to-0.23.md` | Only `ro` leaves the default users | `migrate` leaves the main container too |
| 0.23.0 CHANGELOG | Argo name changes only for non-default clusters | Every Application is renamed |
| `README.md` | Argo name `[APP]--[NS]--[SL]`; quick start pins `^0.20` | `{sl}-{ns}--{app}--{loc}-{cluster}`; pin `~0.24.0` |
| `CLAUDE.md` | `init: false`; unquoted `API_PORT: 8080`; a `bambam` component type; `migrate` needs a command override | `init: {enabled: false}`; quote every value; no such type; pass `migration_command` as a parameter |
| `templates/migrate.rs` doc comment | Override the command with `args:` | `args:` replaces the credential script; use the parameter |
| `PRD.md` | A 2025 draft | Not current; ignore it |
| The old guidance that "api and web have no default probes" | — | They probe `/healthz/live` and `/healthz/ready` on the `http` port |
| `kafkaesque-deploy.yaml` (repo root) | An example | No longer parses |

## Tools that mislead

- **`galactus init`** writes a `deploy.yaml` that does not work: no `version:` (so it runs 0.15.1), no `repo_slug` (a parse error), and the org `hellocondo` instead of `hello_condo`. It also overwrites an existing file and needs a terminal. Write the file by hand.
- **`galactus generate`** (the default command) empties its output folder before it writes. Point it only at a scratch folder.
- **`--no-version-check`** runs whatever binary is installed, which may be older than the pin and reject newer keys such as `expose`.
