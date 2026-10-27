# What to ask for each request

Each section gives the dropdown values and what the description must contain. Ask only for what you cannot find in the repo or the conversation. Every request also needs a target date and a stakeholder.

## Contents

- [A new namespace or stack](#a-new-namespace-or-stack)
- [A PostgreSQL database](#a-postgresql-database)
- [Valkey or Memcached](#valkey-or-memcached)
- [An S3 bucket](#an-s3-bucket)
- [Elasticsearch](#elasticsearch)
- [AI model access](#ai-model-access)
- [Terminus client secrets](#terminus-client-secrets)
- [Read access to another team's database](#read-access-to-another-teams-database)
- [Remove or rename an app](#remove-or-rename-an-app)
- [A change to a platform service or tool](#a-change-to-a-platform-service-or-tool)
- [A bug report](#a-bug-report)

## A new namespace or stack

`Request Type`: `New service or capability`. `Platform Area`: `Deploying a Namespace or Application`.

Ask for:

- The namespace, as `{subsystem}-{tenant}`. Check the name against the [naming rules](https://github.com/cincpro/seldon-idp/blob/main/README.md#namespaces): no hyphen inside a subsystem or a tenant, and no abbreviations. When the subsystem is not clear, suggest the owner's name.
- The levels: `sbx` for non-engineers, `dev` for engineers, `prd` for engineers only. `dev` and `sbx` never get production data or client data.
- The owner team. A namespace has one owner.
- What the apps in the namespace do, and the first app's repo.
- Which teams need access to the namespace.

## A PostgreSQL database

`Request Type`: `New service or capability`. `Platform Area`: `Datastores (PostgreSQL)`.

Ask for:

- The namespace, the app, and the levels.
- The tier, 1 to 4. Show the [tier table](https://github.com/cincpro/seldon-idp/blob/main/README.md#tiers) if the user does not know it.
- The expected size and load, if known.
- The roles the app needs: `ro`, `rw`, `migrate`. Tell the user that galactus syncs them through `database_users` in `deploy.yaml`.
- Whether data moves from an existing database.

## Valkey or Memcached

`Request Type`: `New service or capability`. `Platform Area`: `Other / Not sure`.

Ask for:

- Valkey or Memcached, and why. Redis is deprecated: use Valkey.
- The namespace, the app, the levels, and the tier.
- The expected memory and load, if known.

Tell the user that `valkey: true` or `memcached: true` in `deploy.yaml` syncs the credentials.

## An S3 bucket

`Request Type`: `New service or capability`. `Platform Area`: `Other / Not sure`.

Ask for:

- The namespace, the app, and the levels.
- Private app data, or a CloudFront origin. For an origin, which distribution reads it.
- Whether anything must be public. Warn that a public distribution serves every object to anyone with the URL.
- How long the data must stay, if it matters.

## Elasticsearch

`Request Type`: `Access request` for an existing cluster, else `New service or capability`. `Platform Area`: `Other / Not sure`.

Ask for the namespace, the app, the levels, and what the app reads or writes. Access is not automated, so the description must say exactly what is needed.

## AI model access

`Request Type`: `Access request`. `Platform Area`: `AI Model Serving`.

Ask for:

- The namespace (for example `sites-witco`), and the levels.
- The provider and the models.
- A short description of the use case.

The platform team delivers the key or Bedrock access through Vault. The platform guidance is to start with the best frontier model, and to optimize cost only after the feature works.

## Terminus client secrets

`Request Type`: `New service or capability`. `Platform Area`: `Identity & Authentication`.

One request covers all the levels. The [Terminus integration guide](https://github.com/cincpro/terminus/blob/main/docs/integrating.md#how-do-i-get-started) lists what it needs. Ask for:

- A name for the client.
- The client type: `web`, `mobile`, or `native`.
- The login host: `login.witco.net` for Witco employees (Microsoft Entra), or `login.realgeeks.com` for Real Geeks users (Locutus).
- Each environment that needs a client, such as dev and production. Dev and production hold separate client records.
- Every redirect URI (the app's login callback URL), for each environment. Terminus matches them exactly, including the scheme and the trailing slash.
- Whether the app does not want PKCE. PKCE is on unless the request says otherwise.
- Whether the app does not want the consent screen. It shows unless the request says otherwise.
- The Vault path where the app expects the secrets, if it uses `secrets_from`.

The platform team puts the client secret in Vault. Never put a secret value in the issue. Secrets go only through Vault.

## Read access to another team's database

`Request Type`: `Access request`. `Platform Area`: `Datastores (PostgreSQL)`.

Ask for:

- The database, and the team that owns it.
- A link to that team's approval. Do not file the request without it.
- The app that needs access, its namespace, and the levels.
- Why the app needs the data.

Only read-only access is possible. `rw` and `migrate` never go outside the owning app. To change another team's data, the app must use the event bus. Apps never share credentials.

## Remove or rename an app

`Request Type`: `Change to existing service`. `Platform Area`: `Deploying a Namespace or Application`.

Ask for:

- The stack and the app, for example `dev-marketing-cinc` and `old-landing`.
- For a rename, the new name.
- For a removed target or cluster, which one.
- Whether the old resources can be deleted, and whether any data must be kept.

Tell the user to change `deploy.yaml` in the same way, so that the next deploy does not bring the app back.

## A change to a platform service or tool

`Request Type`: `Change to existing service`. `Platform Area`: the closest match, such as `Tooling` for galactus or the deploy workflows, `Kubernetes Compute`, or `Telemetry & Observability`.

Ask for:

- The current behavior and the desired behavior.
- Why the change matters, and who it affects.
- Links: the repo, the workflow run, the galactus version, or the issue in the tool's own repo.

For a new `witco.*` telemetry attribute, use `Telemetry & Observability`. Only the platform team defines those attributes.

## A bug report

`Request Type`: `Bug or incident report`. `Platform Area`: the closest match.

Ask for:

- The current behavior, and the exact error.
- The steps to reproduce it.
- The desired behavior.
- Links: the failed workflow run, the Argo CD app, or a Grafana link.

If the platform is down now and users are affected, stop and send the user to the [incident response process](https://github.com/cincpro/incident-response).
