# Upgrade galactus to 0.24 (from 0.21 and later)

Upgrade one minor at a time: change `version:`, run `galactus validate`, deploy, then go on. On 0.x every minor can break.

Upstream guides: [docs/upgrading/](https://github.com/cincpro/galactus/tree/main/docs/upgrading). Use the copies on `main`; they are newer than the 0.24.0 tag. This file adds what those guides leave out.

## Before you start

- Find the pin: `grep -n '^version' deploy.yaml`. No `version:` line means the app runs 0.15.1; treat that as a rewrite, not an upgrade. A pin older than 0.21 needs the upstream guides for each earlier step.
- Quote the pin: `version: "~0.24.0"`. An unquoted `0.20` reads as the number `0.2` in other YAML tools.

## 0.21 → 0.22

0.21 is the most common pin in CincPro apps, mostly because 0.22 rejects the legacy secrets format. This is the largest step. The upstream [0.21-to-0.22.md](https://github.com/cincpro/galactus/blob/main/docs/upgrading/0.21-to-0.22.md) has the details; these are the changes that fail validation or break an app:

1. **`secrets:` is replaced by `secrets_from:`**, at every level. Items are path-only (`{path, version?}`); bare `- NAME` items and `key:` fields are errors.

   ```yaml
   # before
   secrets:
     - DATABASE_PASSWORD                        # app secret: now automatic
     - key: STRIPE_KEY
       path: secret/data/prd/shared/stripe:api_key
   # after
   secrets_from:
     - path: prd/shared/stripe                  # the whole path is synced
   ```

   The app secret now comes from one fixed path, `{sl}/{namespace}/{app}/app`, and **every field there becomes an env var of exactly that name**. Before you deploy: create that Vault path, move the app's values into it, and rename each field to the env var the app reads (case matters). If the path does not exist, pods do not start. Database credentials come from `database_users` (see the 0.23 step for the default).

2. **Bare-bool features are errors.** `ingress: false` → `ingress: {enabled: false}`, `rbac: true` → `rbac: {enabled: true}`; also `pod_disruption_budget`, `service_account`, `irsa`, and the `iam_*` blocks.
3. **Flat PDB fields move to `pdb:`.** `pod_disruption_budget: {maxUnavailable: 1}` (which never did anything) → `pdb: {max_unavailable: 1}`.
4. **Init containers are on by default.** Every image needs an executable `./scripts/init.sh`, or set `init: {enabled: false}` at the root.
5. **Minimum replicas is 2 everywhere, and a PDB is generated above 1 replica.** Set `min_replicas: 1` on targets that must stay single.
6. **`datastores:` is removed.** Delete the key.
7. Expect a one-time diff in the rendered output (ordering, labels, namespace casing, cronjob image tags).

## 0.22 → 0.23

1. **Default database users are narrower.** `database_users` is now `[rw]` (was `[rw, ro, migrate]`), and `init.database_users` is `[rw, migrate]`. The upstream guide mentions only `ro`, but the main container also loses `migrate`.

   ```yaml
   # main process runs migrations, or reads with ro:
   database_users: [rw, migrate]      # or [rw, ro]
   ```

2. **`targets[].is_default` is an error.** Delete it.
3. **`loc_code` and `cluster_name` must name a registered cluster.** Fix or remove bad overrides; the error lists the valid ones. See [clusters.md](clusters.md).
4. **Database env var names for multi-word app names** lose their separators: `DATABASE_PG_MY_GREAT_APP_RW_*` becomes `DATABASE_PG_MYGREATAPP_RW_*`. The names come from the Vault fields; rename the fields and the app's reads together.
5. **The Argo Application is renamed** to `{sl}-{namespace}--{app}--{loc}-{cluster}`. Not in the upstream guide. Update dashboards, links, and scripts that use the old `{app}--{namespace}` name.

0.23.1 adds `valkey: true` and `memcached: true` (no action). 0.23.2 changes only the `--flat` output layout.

## 0.23 → 0.24

The main change is `expose:`. Read [expose.md](expose.md) first.

1. **Change the pin and add the keep-Traefik block in the same commit.** 0.23 does not know `expose:`, so you cannot add it early.

   ```yaml
   version: "~0.24.0"
   expose:
     traefik: { enabled: true }
     external: { enabled: false }
   ```

   This gives the same manifests as 0.23. Without it, the bump moves DNS to Envoy in one deploy, **even if the app never set `ingress:`**.

2. **Replace every `ingress:` key** (it is a parse error now):

   | 0.23 | 0.24 |
   | --- | --- |
   | `ingress: {enabled: false}` | `expose: {enabled: false}` |
   | `ingress: {enabled: true}` | `expose: {traefik: {enabled: true}, external: {enabled: false}}` |
   | `ingress: {spec: {...}}` | `expose: {traefik: {enabled: true, ingress: {spec: {...}}}, external: {enabled: false}}` |
   | a custom host under `witco.net`, `cincapi.com`, or `cinccrm.com` | later, `expose: {external: {hostname: {fqdn: <host>}}}` |

   The error message and the upstream summary row say `ingress: {enabled: true}` → `expose: {traefik: {enabled: true}}`. That alone fails with `dns_claimed_twice`; add `external: {enabled: false}`.

3. **Targets on am17 or am72** cannot use Traefik. Give them a target-level override; see [expose.md](expose.md#several-targets-or-clusters).
4. **Realgeeks and HelloCondo** have no gateway: the keep-Traefik block is required for good.
5. **Realgeeks `prd` (`am14-kube1`) is gone.** A Realgeeks `prd` target now fails with `unknown_cluster`. Remove it. The upstream guides do not mention this.
6. Run `galactus validate`, then `galactus diff`. With the keep-Traefik block, the diff shows only the version header.

After the bump is live, move to the gateway in separate releases ([expose.md](expose.md#safe-migration)).

## Check after each step

- `galactus validate` from the repo root (so the pin applies) reports no errors.
- `galactus diff` shows only the changes you expect.
- After deploy, the app's hostname still resolves and serves, and the Argo app is healthy.
