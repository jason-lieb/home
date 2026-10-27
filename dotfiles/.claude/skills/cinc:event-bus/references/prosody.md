# prosody 0.6 for app developers

Verified against `@prosody-events/prosody` 0.6.1. prosody is the Kafka client under euphony. A euphony app does not call it much, but its config, ports, platform rules, retry modes, and keyed state apply to every euphony app.

Upstream docs, pinned to the verified version:

- [README](https://github.com/prosody-events/prosody-js/blob/prosody-v0.6.1/README.md) — API, modes, keyed state, requests, excise.
- [CONFIGURATION.md](https://github.com/prosody-events/prosody-js/blob/prosody-v0.6.1/CONFIGURATION.md) — every option, its env var, and its default.

The legacy `@cincpro/prosody` 2.x package is the old internal home. Use `@prosody-events/prosody` for all new work.

## Contents

- [When to use prosody directly](#when-to-use-prosody-directly)
- [Configuration](#configuration)
- [Ports](#ports)
- [Platform and Docker](#platform-and-docker)
- [Failure modes and retries](#failure-modes-and-retries)
- [Cancellation](#cancellation)
- [Delivery and dedup](#delivery-and-dedup)
- [Keyed state](#keyed-state)
- [Using the client directly](#using-the-client-directly)
- [Traps](#traps)

## When to use prosody directly

A JS app uses euphony for all standard events. Use prosody itself only for:

- `setLogger(logger)` to route prosody's logs. Call it as a side effect of the app's logger module.
- `PermanentError` and `TransientError` (euphony re-exports both).
- Keyed state collections passed through `subscribe(handlers, { stateCollections })`.
- Payloads that are not standard events: send with `(await client()).send(topic, key, payload)` from euphony, and consume with euphony's `createCustomEventHandler`.
- `AdminClient` to create topics in tests: `import { AdminClient } from "@prosody-events/prosody"`.
- A process with no euphony at all, such as a script. Then see [Using the client directly](#using-the-client-directly).

## Configuration

An option passed in code beats its env var, which beats the default. Env vars take duration strings (`15s`, `5m`); options take numbers in the unit their name says (`timeoutMs`, `idempotenceTtlSeconds`). A negative, fractional, or non-finite number makes client creation fail. **An option with an old or wrong name is ignored with no error**; check names against CONFIGURATION.md.

| Env var | Need | Notes |
| --- | --- | --- |
| `PROSODY_BOOTSTRAP_SERVERS` | Every non-mock client | Kafka brokers, comma-separated. |
| `PROSODY_CASSANDRA_NODES` | **Every non-mock client**, including API servers that only publish | Client creation connects to Cassandra and fails without it. galactus sets it only on `worker-kafka` components. |
| `PROSODY_GROUP_ID` | Consumers | The consumer group. Convention: the app or component name. Must equal `autoscaling.consumer_group` in galactus `deploy.yaml`. |
| `PROSODY_SOURCE_SYSTEM` | Every client | Stamped on every message you send. Defaults to the group ID, and **a consumer skips messages whose source system equals its group ID**. Set it to a different value (for example `<app>-producer`) if the app consumes events it publishes. |
| `PROSODY_SUBSYSTEM` | euphony apps (euphony requires it) | Your subsystem name. Also required to answer requests and to own published keyed state. |
| `PROSODY_MOCK` | Local and tests | `true` uses in-memory Kafka: no brokers, no Cassandra, no peer port. |
| `PROSODY_PROBE_PORT` | Optional | Health probe port, default `8000`. `none` disables it. |
| `PROSODY_PEER_BIND_ADDRESS` | Optional | Peer gRPC address, default `<default interface IP>:9099`. Set it when two non-mock processes share a host. |
| `PROSODY_STATE_CACHE_DIR` | Production apps that use keyed state, tasks, or checkpoints | Local cache for keyed state. Defaults to a temp dir; point it at a mounted volume (for example a Kubernetes `emptyDir`). galactus sets it on `worker-kafka` components. |
| `PROSODY_LOG` | Optional | Log filter for prosody's own logs; default `info`. |

Defaults worth knowing: `maxConcurrency` 32 in-flight keys; handler `timeout` is 80% of `stallThreshold` (5 min); `shutdownTimeout` 30 s; `sendTimeout` 1 s; dedup TTL 7 days. There is no `PROSODY_MODE`; the mode is a code option only.

## Ports

A non-mock client opens two ports:

| Port | Opened | Purpose | Collision fix |
| --- | --- | --- | --- |
| 8000 (HTTP) | On `subscribe()` | `/readyz` (at least one partition assigned) and `/livez` (no stalled partition) | `PROSODY_PROBE_PORT=none`, or another port |
| 9099 (gRPC) | On client creation, for **every** non-mock client | Request responses (`propose()`) and peer delivery | `PROSODY_PEER_BIND_ADDRESS=<ip>:<port>` |

- Port 9099 binds the IP of the default network interface, not `0.0.0.0`. Passing `0.0.0.0` or `::` is rejected. A container with no default route fails at client creation.
- Two non-mock processes on one host or network namespace (an API and a worker on a laptop, or two containers in one pod) collide on both ports. Give the second one other ports.
- galactus points the default liveness and readiness probes of a `worker-kafka` component at `/livez` and `/readyz` on port 8000, so a worker needs no HTTP code of its own.

## Platform and Docker

- **Node 24 or later.** The package declares it, but nothing checks at runtime; an older Node only warns at install.
- **linux x64 needs AVX2 (x86-64-v3).** On a CPU without it, the process crashes with "Illegal instruction" at load, with no JavaScript error. Old Xeons, some VMs that hide CPU flags, and amd64 emulation under QEMU are the risks. On Apple Silicon, build and run `linux/arm64` images.
- Prebuilt binaries exist only for linux x64 and arm64 (glibc), macOS arm64, and Windows x64. No Alpine (musl), no armv7, no Intel macOS.
- glibc 2.34 or later: `node:24-slim` and `node:24-bookworm` work; bullseye, Amazon Linux 2, UBI 8, and Alpine do not.
- A missing binary fails at import with `Cannot find native binding`. Usually the lockfile was made on another platform with optional dependencies skipped; reinstall on the target platform.
- prosody uses mimalloc. Older internal docs that prescribe a jemalloc base image are stale.

## Failure modes and retries

| Mode | On a transient error |
| --- | --- |
| `Pipeline` (default) | Retries with backoff, then defers the message (it moves past it and retries later, up to 24 h apart) so one bad key does not block the partition. If most recent messages fail, deferral stops and the partition blocks. **Never drops a transient failure.** |
| `LowLatency` | Retries `maxRetries` (3) times, then writes to `failureTopic` (required). |
| `BestEffort` | No retry. Logs and moves on. For loss-tolerant work only. |

- A handler fails by throwing. Return means success and the offset commits.
- An error is permanent only if it is a `PermanentError` (or a method decorated with `@permanent(...)`). **Everything else is transient**, so in Pipeline mode a deterministic bug retries forever.
- A permanent error drops the message. Use it for input that can never succeed.

## Cancellation

prosody cancels a handler when it runs past the timeout, and during shutdown and rebalance.

- Pass the handler's `signal` to every call that takes one (fetch, DB clients, `ctx.publish`).
- Around work that cannot take a signal, check `ctx.shouldCancel` or `signal.aborted`.
- Do not catch and ignore cancellation errors. A handler that returns normally after cancellation counts as success, and the message is lost.
- `ctx.onCancel()` also resolves when the handler completes normally; check `shouldCancel` in its callback.

## Delivery and dedup

- Delivery is at-least-once. Offsets commit about every second, apart from handler completion. Handlers must be idempotent.
- The consumer dedups on the event `id` (plus group, topic, partition, and key) for 7 days. This is why euphony's deterministic event IDs matter: two events with one ID are one event.
- The producer also skips a send when it sent the same `id` to the same topic and key recently. The `send` resolves and nothing is sent; only an info log records it.
- Messages are ordered per key, and keys run concurrently on the single Node event loop. CPU-heavy handler work stalls every key.

## Keyed state

Keyed state is durable per-key memory for stream work: counters, pending work, per-key workflows. It is stored in Cassandra (not needed in mock mode). Keep business data in the app database; use keyed state for state that would otherwise need a DB read per message.

```typescript
import { value, map } from "@prosody-events/prosody";

const lastSeen = value<string>("last-seen", { ttlSeconds: 30 * 86_400 }); // T is compile-time only
await subscribe(handlers, { stateCollections: [lastSeen] }); // euphony's subscribe

// in a handler:
const seen = ctx.state(lastSeen);
const previous = await seen.get();
await seen.set(new Date().toISOString());
```

- Collections: `value`, `map`, `set`, `deque`, and the typed `messageValue`, `messageMap`, `messageDeque`. Build definitions only with these constructors; a hand-made object throws.
- Changes commit when the handler succeeds, so state follows retry semantics. Side effects such as emails do not, and can repeat on retry.
- Set a TTL longer than the longest workflow that uses the collection.
- Writing `null` is a permanent error; writing `undefined` is transient.
- A collection with `published: true` can be read by other subsystems with `client.state("<subsystem>", DEF)`. Reads can be up to about 5 seconds stale.
- An excision handler must clear the entity's keyed state too.

The README covers queries, paging, and published state in detail.

## Using the client directly

Only for code without euphony:

```typescript
import { ProsodyClient } from "@prosody-events/prosody";

const client = await ProsodyClient.create({ subscribedTopics: ["my.topic"] }); // not `new`
await client.subscribe({
  onMessage: async (ctx, message, signal) => { /* ... */ return null; },
  onExcise:  async (ctx, message, signal) => { /* delete data for message.key */ return null; },
  onTimer:   async (ctx, timer, signal) => { /* timer = { key, time } */ },
});
await client.send("my.topic", key, payload, signal);
// at exit:
await client.shutdown(); // or `await using client = await ProsodyClient.create(...)`
```

- `new ProsodyClient()` throws. Use `await ProsodyClient.create(config)`.
- All three handlers are required.
- `onMessage` and `onExcise` must return a JSON value (`null` is fine). A result that cannot become JSON, such as a `BigInt` from a database row, is a transient error that retries forever.
- `shutdown()` releases everything, including port 9099. `unsubscribe()` only stops consuming.
- Pass `subscribedTopics` as an array. In code, `"a,b"` is one topic named `a,b`; only the env var splits on commas.

## Traps

- Payloads go out through `JSON.stringify`: a `Date` becomes a string, a `Map` or `Set` becomes `{}`, and a `BigInt` throws. Inbound `message.timestamp` and `timer.time` are `Date`s.
- An inbound `message` is a native object with getters. `{ ...message }` and `JSON.stringify(message)` lose every field; read the properties you need.
- Handler methods are called unbound, so `this` is `undefined` in a class method. Use arrow functions.
- An aborted `send()` rejects, but the message may already be sent.
- If `SENTRY_DSN` is set and `@sentry/node` is installed, prosody reports handler errors to Sentry, and starts Sentry itself if the app has not.
- `await client.request(...)` from a handler to its own group, for the same key, waits until it times out.
