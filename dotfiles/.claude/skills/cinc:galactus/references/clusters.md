# Orgs, service levels, and clusters (galactus 0.24)

A target's `service_level` picks the org's default cluster for that level. `loc_code` and `cluster_name` pick another registered cluster. A pair that is not registered is an error that lists the valid ones.

| Org | Service level | Default cluster | Other clusters | Traefik | Gateway (`expose.external`) |
| --- | --- | --- | --- | --- | --- |
| witco | `mgt` | am4-kube0 | am3-kube0 | both | both |
| witco | `prd` | am16-kube0 | am17-kube0 | am16 only | both |
| witco | `dev` | am71-kube0 | am72-kube0 | am71 only | both |
| witco | `sbx` | am90-kube0 | — | yes | yes |
| realgeeks | `stg` | am30-kube0 | — | yes | **no** |
| hello_condo | `prd`, `stg`, `qa`, `dev` | am15, am34, am51, am70 (all kube0) | — | yes | **no** |

- **Realgeeks `prd` has no cluster.** `am14-kube1` was removed in 0.24 (destroyed 2026-09-30). A Realgeeks `prd` target fails with `unknown_cluster`, though `galactus init` still offers it.
- Any other org and service-level pair fails.
- IRSA works only on Witco `prd`, `dev`, and `sbx`.
- HelloCondo has no default Kafka brokers or Cassandra; a `worker-kafka` there must set `PROSODY_BOOTSTRAP_SERVERS` itself.

## Several targets

Several targets may share a service level when each resolves to a different cluster; two targets on one cluster are an error (`cluster_collision`), even across service levels.

```yaml
targets:
  - service_level: prd                 # am16-kube0
  - service_level: prd
    loc_code: am17
    cluster_name: kube0
    expose: { external: { manage_dns: false } }   # am16's route owns the hostname
```

With `expose:`, the route hostname has no cluster suffix, so only one target per service level may manage its DNS. See [expose.md](expose.md#several-targets-or-clusters).

## Names that come from the cluster

- Argo Application: `{sl}-{namespace}--{app}--{loc}-{cluster}`, for example `prd-domain-witco--sigil--am16-kube0`.
- geekstack path: `kube-config/{namespace}/{app}/targets/{sl}/{loc}/{cluster}/`.
- Cassandra for `worker-kafka`: `cirrus-{loc}-{cluster}-service…` on prd and `stratus-{loc}-{cluster}-service…` elsewhere, so an am17 target gets am17's Cassandra.
- Ingress hosts (Traefik) off the default cluster get `-{loc}-{cluster}`; HTTPRoute hosts do not.
