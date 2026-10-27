# Conventions and testing in CincPro apps

From a survey of the JS and TS apps in the `cincpro` org (October 2026). Most of them are on euphony 14.3.x; none was on 14.5 yet. sigil and squire are the best current examples; squire is the model for excision.

## Contents

- [App layout](#app-layout)
- [Worker lifecycle](#worker-lifecycle)
- [Handlers](#handlers)
- [Publishing](#publishing)
- [Config in deploy and compose](#config-in-deploy-and-compose)
- [Testing](#testing)
- [Anti-patterns](#anti-patterns)

## App layout

- One image, several entry points. `src/main.ts` calls `@cincpro/radiant`'s `execute({ api, worker, ... })`, which picks the entry point from argv. Each key matches a galactus component, whose `args` select it. Keep the key, the component `name:`, and the `args` in step.
- galactus `worker-kafka` runs `pnpm run worker` by default. Apps that ship compiled code override `command` and `args`, for example `command: [node, --enable-source-maps, --import, ./dist/instrumentation.js, dist/events/main.js]`.
- Handler layouts in use (pick one per app):
  - one file per event type, named for it, default export: `src/<app>-worker/handlers/crm.lead.asserted.ts`, `crm.lead.excised.ts`; tasks in `tasks/` (squire, herald);
  - kebab-case `*.handler.ts` and `*.task.ts`, named exports, and `handlers/index.ts` exporting the array (sigil);
  - grouped by source subsystem: `eventHandlers/<subsystem>/<entity>{Asserted,Retracted,Excised}.ts` (firebird).
- The worker imports one array of handlers and makes **one** `subscribe()` call.

## Worker lifecycle

```typescript
import { subscribe, unsubscribe } from "@cincpro/euphony";
import { onShutdown } from "@cincpro/radiant";

export async function worker() {
  await subscribe(handlers, { stateCollections, defaultTaskName });
  onShutdown(async () => {
    await unsubscribe(); // stop consuming first
    await db.close();    // then close what handlers use
  });
  await new Promise(() => {}); // park the process
}
```

- **radiant's `onShutdown` keeps only the first callback** and ignores later ones with a warning. Put all teardown in one callback.
- `unsubscribe()` throws in a process that never subscribed. If an API process and a worker share a shutdown module, wrap it in `try`/`catch` (sigil's `src/shutdown.ts`).
- radiant's `GRACEFUL_SHUTDOWN_TIMEOUT_SECONDS` (forced exit) and prosody's `PROSODY_SHUTDOWN_TIMEOUT` (drain) are separate. Keep the radiant one longer.
- euphony has no group ID option. A consumer that needs its own group per pod (a broadcast feed) sets `process.env.PROSODY_GROUP_ID` before `subscribe()` (certd-envoy-sds).

## Handlers

- Parse the content with the app's own Zod schema and throw `PermanentError` on failure (sigil). A raw `ZodError` is transient and retries forever.
- Validate `ctx.key` (for example `z.uuid().parse(ctx.key.subTenantId)`) instead of using `!`.
- A cross-CRM guard is common: check that the content's CRM ID equals `ctx.key.subTenantId`, and throw `PermanentError` if not.
- For proposals, publish in this order: the assertion, then the DB write, then the `.succeeded` event. A crash then gives a duplicate assertion (harmless), not a lost one (sigil).
- **Excision handlers delete for real.** squire's `crm.lead.excised.ts` deletes the DB rows, calls `ctx.clearScheduled()`, and clears each keyed state collection with `ctx.state(def).clear()`. A no-op is right only when the app stores nothing about the entity; say so in a comment.

## Publishing

- Inside handlers, always `ctx.publish`. Bare `publish` only in routes, jobs, and scripts, always with an explicit `idempotencyKey` that names the operation and the record: `{ context: "createWebsiteClient", clientUuid }`.
- Put publish helpers in one module per subsystem or entity (firebird `dataAccess/eventBus/<subsystem>/`, delorean `CrmEventPublisher.ts`).
- A backfill or re-sync job folds a run ID into the key, so a retry of the same run dedups but a new run publishes again.
- Publish after the DB transaction commits, not inside it.
- For "publish exactly when the row commits", use a transactional outbox: write outbox rows in the transaction and drain them in a worker (transaction-connect). Keep the drain module separate and load euphony with `await import("@cincpro/euphony")` so Next.js never bundles the native module.
- Because publish-side validation errors are transient, delorean's publisher validates the packet from `await bundle(...)` itself and returns an error result before it calls `publish`. Use this when bad input must not retry.
- Next.js apps list `@prosody-events/prosody` in `serverExternalPackages`.

## Config in deploy and compose

| Variable | Where | Value |
| --- | --- | --- |
| `EUPHONY_TENANT` | top-level `environment:` | the tenant |
| `PROSODY_SUBSYSTEM` | top-level | the subsystem the app owns (`domain`, `comms`, `crm`, `sites`, `identity`, `nurtureEngine`, ...) |
| `PROSODY_SOURCE_SYSTEM` | top-level, or per component | the app name; per component when a worker must see events its own API publishes (sigil sets `sigil-api` on the API) |
| `PROSODY_GROUP_ID` | each worker component | `<app>-<component>` |
| `PROSODY_LOG` | optional | `info` or `error` |

- galactus adds `PROSODY_BOOTSTRAP_SERVERS` (when not set), `PROSODY_CASSANDRA_NODES`, and `PROSODY_STATE_CACHE_DIR` to **`worker-kafka` components only**. An `api`, `web`, `worker`, `command`, or `cronjob` component that publishes must set the brokers and Cassandra itself.
- galactus scales `worker-kafka` with KEDA on consumer lag. KEDA watches `autoscaling.consumer_group`, which **defaults to the top-level `name:`**, not `PROSODY_GROUP_ID`, and the topics in the component's `PROSODY_SUBSCRIBED_TOPICS`. Set `autoscaling.consumer_group` to the same value as `PROSODY_GROUP_ID`, and list the topics, or the autoscaler watches nothing. (euphony itself ignores `PROSODY_SUBSCRIBED_TOPICS`.) The `galactus` skill has the details.
- Tuning seen in production: `PROSODY_MAX_CONCURRENCY`, `PROSODY_TIMEOUT`, `PROSODY_STALL_THRESHOLD`, `PROSODY_SHUTDOWN_TIMEOUT`; `PROSODY_SLAB_SIZE: 1m` after a Cassandra tombstone incident (solaris).
- Local Kafka, Cassandra, and Redpanda Console come from a `docker-compose.events.yaml`; tests and CI set `PROSODY_MOCK=true`.

## Testing

### Unit-test a handler

Mock only the factories so they return the handler function, keep the rest of euphony real, and call the handler with a fake context:

```typescript
vi.mock("@cincpro/euphony", async (importActual) => ({
  ...(await importActual<typeof import("@cincpro/euphony")>()),
  createEventHandler: (_type: unknown, handler: unknown) => handler,
  createEntityExcisedHandler: (_type: unknown, handler: unknown) => handler,
}));

const ctx = {
  key: { tenantId: "witco", subTenantId, subjectId },
  publish: vi.fn(async () => ({ topic: "t", key: "k", payload: { id: "evt" } })),
};
await (leadAsserted as unknown as Handler)(
  ctx,
  { payload: { type: "crm.lead.asserted", id: "1", data: { category: "assertion", content } } },
  new AbortController().signal,
);
expect(ctx.publish).toHaveBeenCalledWith(expect.objectContaining({ eventType: X }));
```

- The partial mock (squire) keeps `PermanentError` and the event classes real. Older apps alias `@cincpro/euphony` to a hand-written mock in `vitest.config.ts`; those mocks drift between repos, so check that the local one passes the handler through.
- For excision handlers, give the fake context `clearScheduled` and `state(def).clear` mocks, and assert that every store is cleared (squire `tests/exciseTestUtils.ts`).

### Test the real handler set

Mocked factories hide `subscribe()` errors, such as a missing excision handler. Add one test that subscribes the real handler array in mock mode (sigil):

```typescript
test("subscribe accepts the worker's handler set", async () => {
  vi.stubEnv("PROSODY_MOCK", "true");
  vi.stubEnv("PROSODY_SUBSYSTEM", "crm");
  await expect(subscribe(handlers)).resolves.toBeUndefined();
});
afterAll(async () => { await unsubscribe(); });
```

### Other patterns

- Test `main.ts` by mocking `subscribe`, `unsubscribe`, and radiant's `onShutdown`, then assert on the handler list and that shutdown is registered.
- Put publishing behind an interface and inject a fake in tests (delorean `FakeCrmEventPublisher`), or inject the publish function (transaction-connect).
- To check a packet without sending, `await bundle(...)` and assert on `topic`, `key`, `payload.id`, and content. `bundle` creates the client, so set `PROSODY_MOCK=true` and `PROSODY_SUBSYSTEM`, and do not call `subscribe()` later in the same process.
- euphony registration is global to the module. Run event tests serially (vitest `fileParallelism: false`), and remember that `unsubscribe()` clears only `createEventHandler` registrations.
- Handler tests that need a database use a real Postgres from docker compose; no app uses testcontainers.

## Anti-patterns

The mistakes found in the survey, with how to find and fix each one, are in [anti-patterns.md](anti-patterns.md).
