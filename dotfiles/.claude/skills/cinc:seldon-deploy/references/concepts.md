# Seldon concepts for app developers

Use this file to answer questions about Seldon: what it is, how its names work, what each service level means, and what an app gets after a deploy. The source of truth is the [`seldon-idp` README](https://github.com/cincpro/seldon-idp/blob/main/README.md) and its `docs/`. Link to those for detail.

## Contents

- [What Seldon is](#what-seldon-is)
- [Names: namespace, stack, service level](#names-namespace-stack-service-level)
- [Service levels and clusters](#service-levels-and-clusters)
- [Tiers](#tiers)
- [After the deploy: logs, metrics, and traces](#after-the-deploy-logs-metrics-and-traces)
- [Secrets](#secrets)
- [Databases, caches, and other resources](#databases-caches-and-other-resources)
- [Remove or rename an app](#remove-or-rename-an-app)
- [Where to get help](#where-to-get-help)

## What Seldon is

Seldon is the Witco internal developer platform. The platform team runs it as a product, and app developers are its customers. It is a set of layers, not one tool:

| Layer | What it gives an app | What the app team still owns |
|---|---|---|
| Hosting | Kubernetes, RDS PostgreSQL, Valkey, Memcached, Elasticsearch, ClickHouse | How the code uses memory, CPU, and queries |
| Observability | An OTEL pipeline to Grafana (Mimir, Loki, Tempo) | Instrumentation in the code, dashboards, and alert rules |
| Data plane | The Kafka event bus through prosody and euphony | Which events to publish and consume (see `event-bus`) |
| Developer experience | Templates, galactus, the Seldon deploy workflows, Terminus for OAuth and OIDC | `deploy.yaml` and the caller workflow |

Seldon replaces older choices. Do not start new work on Elastic Beanstalk, ECS, Lambda, MySQL, MS SQL Server, MongoDB, Redis (use Valkey), RabbitMQ, SQS, SNS, or Jenkins. The [service catalog](https://github.com/cincpro/seldon-idp/blob/main/docs/service-catalog.md) marks each one as deprecated.

For a new app, start from a template: [`template-app-nextjs`](https://github.com/cincpro/template-app-nextjs) or [`template-app-hono`](https://github.com/cincpro/template-app-hono). The Django and Rails templates are deprecated.

## Names: namespace, stack, service level

| Name | Pattern | Example | Meaning |
|---|---|---|---|
| Subsystem | a word | `crm`, `sites`, `ads` | A group of services that could be sold as one SaaS product, with one owner. Use the name from the event schemas when one exists. |
| Tenant | a word | `witco`, `cinc`, `realgeeks`, `hellocondo` | The business under the Witco umbrella. |
| Namespace | `{subsystem}-{tenant}` | `sites-witco`, `marketing-cinc` | A boundary with one clear owner. It is also the Kubernetes namespace. |
| Service level | `dev`, `sbx`, `prd` | `prd` | How important and how durable the resources are. |
| Stack | `{service level}-{namespace}` | `prd-sites-witco` | The main unit for infrastructure, keys, and credentials. It is also the folder in `seldon-gitops`. |
| App | `name:` in `deploy.yaml` | `firebird` | One deployable app in a stack. |

- Do not use a hyphen inside a subsystem or a tenant. The hyphen separates them.
- Do not abbreviate a subsystem or a tenant.
- When the subsystem is not clear, use the owner's name, such as `consumer`. It is easier to make a name more specific later than to split a broad one.
- An owner can own many namespaces, but a namespace has one owner.
- Some `seldon-idp` docs use `sites-firebird` as an example namespace. That is wrong by these rules: `firebird` is an app, and its namespace is `sites-witco`.

## Service levels and clusters

A service level is not the same as an environment. One service level can hold several environments, such as demo and test copies.

| Level | Meaning | Default cluster | Who can deploy |
|---|---|---|---|
| `sbx` | The lowest level: a sandbox. For vibe-coded apps and wireframes from product people and other non-engineers, and for test versions from engineers. The template's `bootstrap-app` skill sends external-facing apps here. | `am90-kube0` | Non-engineers, and engineers for test versions |
| `dev` | For development and UAT testing. No sensitive data (no customer or security data). Data need not be durable. No uptime promise. Support in business hours. | `am71-kube0` | Engineers |
| `prd` | Production. Sensitive, durable data. Recovery plans. Uptime under SLAs. Support 24x7 on call. | `am16-kube0` | Senior engineers and DevOps, after code review |

Each level is an AWS environment. `dev` and `sbx` must never have access to production data or client data. Do not connect an app on those levels to a `prd` resource.

A shared resource takes the highest service level of the things that depend on it.

## Tiers

A tier says how critical a service or a database is. It sets the backup retention and whether the database is multi-AZ.

| Tier | Meaning | Backup retention | Multi-AZ |
|---|---|---|---|
| 1, Critical | Must be up 24/7. Major features break without it. | 35 days, cross-region | Yes |
| 2, High | Can go down in a maintenance window without a large effect on customers. | 14 to 35 days | Yes |
| 3, Medium | Can change at any time without a direct effect on customers. | 7 to 14 days | Optional |
| 4, Low | Can change at any time, but other services depend on it, so do not leave it broken. | 3 to 7 days | No |

Give the tier when you ask for a database.

## After the deploy: logs, metrics, and traces

- **Where to look:** [Grafana](https://grafana.witco.net). Metrics are in Mimir, logs in Loki, and traces in Tempo.
- **How the data gets there:** the app sends OTEL data to the collector on its node. The templates turn this on with `@cincpro/radiant`, `OTEL_ENABLED: "true"`, and `OTEL_SERVICE_NAME`. galactus also sets `team_name` as the `team` resource attribute.
- **What the platform owns:** the collection pipeline, the storage, Grafana, Alertmanager, and the delivery of notifications.
- **What the app team owns:** the instrumentation in the code, and the alert rules that say when something is wrong. The platform does not tell you why a container runs out of memory or why a query is slow.
- **Conventions** (from the [telemetry guide](https://github.com/cincpro/seldon-idp/blob/main/docs/telemetry/README.md)):
  - Use the OTEL semantic conventions for attribute names.
  - Write one structured log line for each event, with a static message and the values in attributes.
  - Use span links for work that runs later, such as a queued job.
  - The `witco.*` attributes are reserved for the platform. Do not add your own.

## Secrets

- **Where they live:** Vault. galactus syncs the app's own path `{sl}/{namespace}/{app}/app` and its database credentials into the pods through VSO. `secrets_from` adds other paths (see the `galactus` skill).
- **Who writes them:**
  - App developers edit or add entries themselves in the Vault UI at [vault.rg-infra.com](https://vault.rg-infra.com).
  - The platform team enters some secrets after a platform request (use the `seldon-request` skill), for example Terminus (OIDC) client secrets.
- **How to send a secret:** only through Vault. Never send a secret value in an issue, Slack, or email.
- **Never** put a secret in `deploy.yaml`, a workflow, or `seldon-gitops`, not even an encrypted one.

## Databases, caches, and other resources

The platform team makes these today. Self-service is planned but not available. Draft a platform request (use the `seldon-request` skill) with the namespace, the service levels, and the tier.

| Resource | Notes |
|---|---|
| PostgreSQL (RDS) | Each logical database belongs to one app. That app gets three roles: `ro`, `rw`, and `migrate` (DDL). galactus syncs the credentials (`database_users` in `deploy.yaml`). |
| Valkey or Memcached (ElastiCache) | One shared auth token for each Valkey group. Apps get separate logical databases by index. Set `valkey: true` or `memcached: true` in `deploy.yaml`. |
| S3 | A private bucket, or a CloudFront origin bucket. |
| Elasticsearch | Access is not automated. Ask the platform team. |
| AI models | Give the namespace, the provider, the models, and the use case. The key or Bedrock access comes through Vault. Start with the best frontier model, and optimize cost only after the feature works. |

- Apps never share credentials, not even read-only ones.
- To read another team's database, get that team's approval first, then draft a platform request (use the `seldon-request` skill) for a read-only role.
- `rw` and `migrate` never go outside the owning app. To change another team's data, use the event bus (Empire), not its database.

## Remove or rename an app

App developers cannot change `seldon-gitops`. To remove an app, rename it, or remove a target or cluster from it, draft a platform request (use the `seldon-request` skill). The platform team deletes the old folder and cleans up the cluster.

- **Do not only change `name:` in `deploy.yaml`.** The next deploy makes a new folder and a new Argo CD app. The old app keeps running.
- **Do not only remove a target.** witctl syncs only what galactus renders, so the old folder stays deployed.
- The ApplicationSet sets no resource finalizer. When a folder is deleted, Argo CD can delete the app and leave its Kubernetes resources running. The platform team must clean them up.

## Where to get help

- **Requests:** a Platform Request issue in `cincpro/seldon-idp`. The `seldon-request` skill drafts it. Use it for a new namespace, a resource, a secret that you cannot write, access to another team's data, or a removal. Every issue must follow the Platform Request form.
- **Questions:** [Discussions](https://github.com/cincpro/seldon-idp/discussions) in `cincpro/seldon-idp`, not an issue.
- **Incidents:** [incident response](https://github.com/cincpro/incident-response).
- **Feedback:** the platform team treats rough edges and missing features as product feedback. Say what you need.
