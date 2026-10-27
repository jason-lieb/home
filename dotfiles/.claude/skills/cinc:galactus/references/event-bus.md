# galactus for event-bus apps

What galactus does, and does not do, for apps that use `@cincpro/euphony` and `@prosody-events/prosody`. The `event-bus` skill covers the app code and the meaning of each variable.

## `worker-kafka` defaults

| Item | Default |
| --- | --- |
| Command | `pnpm run worker`. Override for compiled images: `command: ["node"]`, `args: ["dist/main.js", "<name>"]`. |
| Probes | prosody's `/livez` and `/readyz` on the named port `http` = `port:` (default 8000, prosody's default probe port). |
| Service, ServiceMonitor | None. Nothing scrapes a worker. |
| Autoscaling | `type: kafka`, `consumer_group` = top-level **`name:`** (the app, not the component), topics from `PROSODY_SUBSCRIBED_TOPICS`. Min 2, max 16, one pod per 30 s, plus a trigger on prosody's overdue timers. |

## Environment

| Variable | galactus sets it? |
| --- | --- |
| `PROSODY_BOOTSTRAP_SERVERS` | On `worker-kafka` when absent (platform brokers per service level; none for HelloCondo). |
| `PROSODY_CASSANDRA_NODES` | On `worker-kafka` when absent (`cirrus` on prd, `stratus` elsewhere, per cluster). |
| `PROSODY_STATE_CACHE_DIR` | On `worker-kafka`, always (`/var/lib/prosody/state-cache`, an emptyDir). |
| `PROSODY_SUBSYSTEM` | **Never.** euphony 14.2 and later need it; set it at the root. |
| `PROSODY_GROUP_ID` | Never. Set it per worker. |
| `PROSODY_SOURCE_SYSTEM` | Never. |
| `PROSODY_SUBSCRIBED_TOPICS` | Never. euphony ignores it, but the default KEDA trigger reads it. |
| `EUPHONY_TENANT` | Never. Set it at the root. |

**galactus sets the Kafka and Cassandra variables on `worker-kafka` only.** An `api`, `web`, `worker`, `cronjob`, or `command` component that publishes events needs `PROSODY_BOOTSTRAP_SERVERS` and `PROSODY_CASSANDRA_NODES` in its own `environment:` (per target when they differ). prosody 0.5 and later need Cassandra even to publish.

## A worker, written out

```yaml
environment:
  EUPHONY_TENANT: witco
  PROSODY_SUBSYSTEM: crm               # as event-schemas spells it

components:
  - type: worker-kafka
    name: worker-leads
    command: ["node"]
    args: ["dist/main.js", "worker-leads"]
    environment:
      PROSODY_GROUP_ID: myapp-worker-leads
    autoscaling:
      type: kafka
      consumer_group: myapp-worker-leads   # must equal PROSODY_GROUP_ID
      topics: [witco.lead-events]          # the topics the handlers consume
```

- **Set `autoscaling.consumer_group` to `PROSODY_GROUP_ID`.** The default is the app name, so a worker with `PROSODY_GROUP_ID: <app>-worker` and no `autoscaling` block scales on a group that has no members.
- List the topics, or use `type: kafka_consumer_group` (lag over all the group's topics, no list). With neither, and no `PROSODY_SUBSCRIBED_TOPICS`, the default trigger gets an empty topic.
- A target override of a `kafka` block must repeat `consumer_group` and `topics`.
- `bootstrap_servers` in the autoscaling block is not used; set `PROSODY_BOOTSTRAP_SERVERS` in `environment:` when you need a non-default broker.
- `OTEL_SERVICE_NAME` defaults to the app name for every component. Set it per worker if you want one service per worker in traces.

## Images

- prosody 0.5 and later need Node 24 and glibc (Debian bookworm or later), and AVX2 on linux x64. galactus does not check the image.
- The `migrate` command template needs a Debian-based image that runs as root.
- Every component runs `./scripts/init.sh` in an init container unless `init: {enabled: false}`.
