# `expose:` — HTTP exposure in galactus 0.24

galactus 0.24 replaced `ingress:` with `expose:`. **`ingress:` is now a parse error**, at the root, on a target, and on a component. By default an `api` or `web` component now gets a Gateway API **HTTPRoute** on the shared Envoy gateway, not a Traefik Ingress.

Upstream: [docs/advanced/expose.md](https://github.com/cincpro/galactus/blob/main/docs/advanced/expose.md) and [docs/upgrading/0.23-to-0.24.md](https://github.com/cincpro/galactus/blob/main/docs/upgrading/0.23-to-0.24.md) on `main` (the `main` version of the upgrade guide is newer than the 0.24.0 tag and gives the safer default path).

## Syntax

```yaml
expose:                      # {enabled: false} turns off all exposure
  external:                  # ON by default: HTTPRoute on Gateway witco-external
    manage_dns: true         # default; false leaves DNS to someone else
    hostname:                # pick one form
      base: files            #   default: api -> {app}-{component}, web -> {app}
      root_domain: witco.net #   witco.net (default), cincapi.com, cinccrm.com (Witco only)
      # fqdn: files.cincapi.com   # prd form; galactus inserts .{sl} below prd
    http_route: {...}        # raw HTTPRoute, deep-merged last
  traefik:                   # OFF by default: the 0.23 Traefik Ingress, unchanged
    enabled: true
    manage_dns: true         # default
    ingress: {...}           # raw Ingress, deep-merged last (old ingress: content goes here)
  internal: {...}            # not implemented; enabling it is an error
```

- `expose` applies to `api` and `web` only. At the root or on a target it fans out, and other component types ignore it. Set directly on another component type, it is an error.
- The HTTPRoute is `{app}-{component}`, one rule `PathPrefix /` to the Service's `http` port. TLS is handled at the gateway.
- **Route hostname:** `{base}.witco.net` on prd and `{base}.{sl}.witco.net` elsewhere. There is no cluster suffix, so every cluster at one service level gets the same name. The base must be one DNS label of at most 63 characters; a long `{app}-{component}` is an error.
- **Ingress hostname (Traefik, as in 0.23):** the same, plus `-{loc}-{cluster}` off the default cluster.
- Every `expose` block is a feature: write `{enabled: false}`, never a bare `false`.

## Common settings

```yaml
# In-cluster only, no public hostname (replaces ingress: {enabled: false})
expose: { enabled: false }

# Keep exactly the 0.23 Traefik Ingress (both keys are required)
expose:
  traefik: { enabled: true }
  external: { enabled: false }

# Gateway route on a custom domain
expose:
  external:
    hostname: { fqdn: files.cincapi.com }
```

`traefik: {enabled: true}` alone fails with `dns_claimed_twice`, because `external` is on by default and both claim DNS for the same hostname. The 0.24 error message and the upgrade guide's summary row both give this incomplete fix; always add `external: {enabled: false}`.

## What a version bump to 0.24 does

For each `api` and `web` component, with no `expose:` key:

| Setup | Result |
| --- | --- |
| Witco, target on the default cluster | The Ingress is deleted and an HTTPRoute with the same hostname is created. **DNS moves to Envoy in one deploy.** |
| Two targets at one service level (for example am16 and am17), two `web` components, or an mgt app also on am3 | Validation fails with `hostname_collision`. |
| Realgeeks or HelloCondo | Validation fails with `gateway_unavailable`: these orgs have no gateway. |
| Any `ingress:` key left | Parse error. |

So an app that never set `ingress:` changes too.

## Safe migration

Do the version bump with Traefik kept, then move to the gateway in later releases. One stage per deploy:

1. `traefik: {enabled: true}` and `external: {enabled: false}` — same manifests as 0.23. Ship this with the bump.
2. `traefik: {enabled: true}` and `external: {manage_dns: false}` — the route exists, DNS still points at Traefik. Test the route.
3. `traefik: {enabled: true, manage_dns: false}` and default `external` — DNS moves to Envoy; Traefik still answers during the DNS change.
4. Remove the `traefik` block.

With both enabled, galactus warns (`host_not_routed`) about Ingress hosts that the route does not serve, for example custom hosts from an old `ingress.spec`. Port them to `hostname.fqdn` (or `http_route`) before stage 3.

Skip to the default only for an app that is not live, or when a short DNS change is acceptable.

## Several targets or clusters

- Traefik exists only on the default clusters: am16 (prd), am71 (dev), am4 and am3 (mgt), am90 (sbx), and the Realgeeks and HelloCondo clusters. **am17 and am72 have no Traefik**, so a root-level keep-Traefik block fails there (`traefik_unavailable`).
- The route hostname is the same on every cluster at a service level. Only one target may manage its DNS. On the other targets set `external: {manage_dns: false}`.
- For a target on am17 or am72 while the default-cluster target keeps Traefik, override on that target (from the rules; not tested):

  ```yaml
  targets:
    - service_level: prd
      loc_code: am17
      cluster_name: kube0
      expose:
        traefik: { enabled: false }
        external: { enabled: true, manage_dns: false }
  ```

## Other errors `galactus validate` reports

`dns_claimed_twice` (two blocks or targets manage one hostname), `route_name_collision`, `nothing_enabled` (every block off; use `expose: {enabled: false}`), an unknown `root_domain`, a bad `fqdn` or `base`, and `internal` enabled.

Not checked: a hostname that another app already uses, and whether the gateway has a listener for a custom `fqdn`. Confirm both with the platform team before you ship a new domain: use the `seldon-request` skill to draft the request.
