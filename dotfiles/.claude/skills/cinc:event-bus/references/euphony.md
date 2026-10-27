# euphony 14 for app developers

Verified against `@cincpro/euphony` 14.5.0. For a 13.x app, read [migrate-13-to-14.md](migrate-13-to-14.md) first; much of this file does not apply to 13.x.

Upstream docs, pinned to the verified version:

- [README](https://github.com/cincpro/euphony-js/blob/euphony-v14.5.0/README.md) — full API. Several examples in it are wrong; see [Where the upstream docs are wrong](#where-the-upstream-docs-are-wrong).
- [docs/entities.md](https://github.com/cincpro/euphony-js/blob/euphony-v14.5.0/docs/entities.md) — the compacted entity layer (`createEntityHandler`). Accurate except where noted below.

When a detail matters and this file does not cover it, read the installed package (`node_modules/@cincpro/euphony/dist/*.d.ts`) before the README.

## Contents

- [Setup](#setup)
- [Publish](#publish)
- [Consume](#consume)
- [Excision](#excision)
- [Entities on compacted topics](#entities-on-compacted-topics)
- [Proposals and `propose()`](#proposals-and-propose)
- [Timers and tasks](#timers-and-tasks)
- [Checkpoints](#checkpoints)
- [Errors and retries](#errors-and-retries)
- [Where the upstream docs are wrong](#where-the-upstream-docs-are-wrong)

## Setup

```bash
npm install @cincpro/euphony @cincpro/event-schemas @prosody-events/prosody zod
```

- euphony is ESM-only. `@cincpro/event-schemas`, `@prosody-events/prosody` (`^0.6.0`), and `zod` (`^4`) are peer dependencies; the app installs them.
- euphony re-exports all of `@cincpro/event-schemas`, so `import { CRMLeadAssertedEvent, Lead } from "@cincpro/euphony"` works. Most apps import event classes from euphony.
- prosody is a native module. Next.js apps list it in `serverExternalPackages`; tsup and esbuild configs mark it external.
- Node 24 or later. See [prosody.md](prosody.md#platform-and-docker) for the image rules.
- The `@cincpro` scope comes from a private registry; `@prosody-events/prosody` comes from public npm. euphony 14.4 and later are only on AWS CodeArtifact; GitHub Packages stops at 14.3.1. An app whose `.npmrc` points `@cincpro` at `npm.pkg.github.com` must move to CodeArtifact first. Do not paste commands that print a registry token into the transcript; use a wrapper that keeps the token in a file.

### Environment

euphony reads these itself. Everything else (`PROSODY_BOOTSTRAP_SERVERS`, `PROSODY_CASSANDRA_NODES`, `PROSODY_SOURCE_SYSTEM`, `PROSODY_MOCK`, ...) goes to prosody; see [prosody.md](prosody.md#configuration).

| Variable | Rule |
| --- | --- |
| `PROSODY_SUBSYSTEM` | **Required.** Unset or blank throws `ConfigurationError` when the client is created. Use the subsystem name exactly as event-schemas spells it (the `SUBSYSTEM` of your events, for example `crm`, `nurtureEngine`). `propose()` routes to it. |
| `EUPHONY_TENANT` | One of `unassigned`, `cinc`, `realgeeks`, `witco` (case-insensitive). Defaults to `unassigned`. A consumer with a concrete tenant ignores other tenants; an `unassigned` consumer takes all. Any other value throws `ConfigurationError`, which is permanent, so a consumer **drops every message**. Read once per process. |
| `PROSODY_GROUP_ID` | The consumer group. euphony folds it into `ctx.idempotencyId`, so renaming it changes the IDs of events published from handlers. |
| `EUPHONY_KEYPREFIX_BLACKLIST` / `_WHITELIST` | Optional consumer filter: prefix match on the full key. Blacklist first. |
| `EUPHONY_SUBTENANT_*`, `EUPHONY_SUBJECT_*` | Optional consumer filter: exact match. Not applied to custom handlers. |
| `OTEL_SERVICE_NAME` | Names the tracer. euphony always creates spans; a registered OpenTelemetry SDK decides whether they export. |

euphony sets prosody's subscribed topics and allowed events from the registered handlers, so `PROSODY_SUBSCRIBED_TOPICS` and `PROSODY_ALLOWED_EVENTS` do not change what the app consumes. They apply only with `subscribe(handlers, { useAutoSubscribedTopics: false })` or `{ useAutoAllowedEvents: false }`. **Keep `PROSODY_SUBSCRIBED_TOPICS` on galactus `worker-kafka` components anyway**: KEDA reads it to scale on lag. `PROSODY_ALLOWED_EVENTS` and `EUPHONY_CONSUMER` are dead config; remove them.

## Publish

```typescript
import { publish, CRMToLeadTextAssertedEvent } from "@cincpro/euphony";

const { payload } = await publish({
  eventType: CRMToLeadTextAssertedEvent, // the class, never a string
  subTenantId: crmId,
  subjectId: leadId,
  entityId: text.id,                     // assertions and retractions only
  content: text,                         // checked against PUBLISHER_ZOD when sent
  idempotencyKey: { op: "syncText", textId: text.id }, // required outside a handler
});
// payload.id is the event ID
```

- euphony builds the envelope, the topic (`EventClass.TOPIC`), and the key. Never hard-code a topic string.
- Success, failure, and proposal events take no `entityId`. Success and failure need `proposals: [proposalId, ...]`.
- Inside a handler, use `ctx.publish(...)`. It defaults tenant, sub-tenant, and subject from `ctx.key`, `idempotencyKey` is optional, and it chains the ID to the message being handled, so a retry does not make a new event.
- A resolved `publish()` means the broker acked, with one exception: prosody skips a send whose event ID it sent recently for the same topic and key, and still resolves.

### Event IDs and `idempotencyKey`

The event `id` is a deterministic UUID made from the routing IDs, `entityId`, the source system, and `idempotencyKey`. **`content` and `eventTime` are not inputs.**

- Two different operations with the same routing IDs and the same `idempotencyKey` get the same ID, and downstream dedup drops the second one with no error. Make the key unique to the operation: `{ op: "deleteText", textId }`, not a fixed string.
- `idempotencyKey: undefined` type-checks and gives every event the same ID. Always pass a real value.
- Objects are fine; key order does not matter. `ctx.publish` needs an object (it adds `contextId` to it; a field of that name is overwritten).

### ID inference from content

Event classes know where the entity, sub-tenant, and subject IDs live inside `content`. A value given only at the top level is written into content; a value only in content fills the top level; a value in both must match, or publish throws. The write is shallow: setting `crm.id` replaces the whole `crm` object in the copy that is sent.

### `bundle()` and `rekey()`

- `await bundle(request)` resolves the packet (`{ topic, key, payload }`) without sending. It is **async** and it **creates the prosody client**, so it cannot run before `subscribe()` in a consumer. It does not validate; `publish(packet)` validates when it sends.
- `rekey({ packet, topic?, tenantId?, subTenantId?, subjectId? })` changes the routing and keeps `payload.id`. A packet moved to a non-canonical topic is sent **without validation**.
- `ctx.bundle(...)` inside a handler is synchronous.

### Entity operations

`assertEntity`, `retractEntity`, and `exciseEntity` (and their `ctx.` forms) publish by entity definition instead of by event class:

```typescript
await assertEntity({ entityType: Lead, entity: lead, idempotencyKey: { op: "import", row } });
await retractEntity({ entityType: Lead, entity: { id }, idempotencyKey: { op: "delete", id } });
await exciseEntity({ entityType: Lead, entityId: id, idempotencyKey: { op: "gdpr", id } });
```

- `retractEntity` publishes `entity` as given; trim it to the IDs consumers need.
- `retractEntity` throws (transient, so it retries) when the definition's `RETRACTION_TYPE` is `undefined` at runtime, which is true for most definitions in event-schemas. Publish the retraction event class with `publish()` instead.
- `exciseEntity` publishes `<entityType>.excised` (for example `crm.lead.excised`) on the assertion's topic, with only the ID fields as content.

## Consume

```typescript
import {
  createEventHandler, createEntityExcisedHandler, subscribe, unsubscribe,
  CRMLeadAssertedEvent, Lead,
} from "@cincpro/euphony";

const leadAsserted = createEventHandler(CRMLeadAssertedEvent, async (ctx, msg, signal) => {
  const lead = msg.payload.data.content;
  await db.leads.upsert(lead, { signal });
});

const leadExcised = createEntityExcisedHandler(Lead, async (ctx, entity, signal) => {
  await db.leads.deleteAll(entity.id, { signal });
});

await subscribe([leadAsserted, leadExcised]); // before any publish, bundle, or client()
// on shutdown:
await unsubscribe();
```

- `create*Handler` returns a thunk; nothing registers until `subscribe()`.
- **Every assertion handler needs an excision handler for the same entity type on the same topic**, or `subscribe()` throws `HandlerRegistrationError`. See [Excision](#excision).
- `subscribe()` throws when: it runs twice; it gets no handlers; a handler registers after it; or the prosody client already exists. These calls create the client: `publish`, `bundle`, `propose`, `assertEntity`, `retractEntity`, `exciseEntity`, `client()`, `unsubscribe`. A worker that publishes during startup before it subscribes crashes.
- The third argument of `createEventHandler` is an options object: `{ validationSchema?, topic? }`. `topic` lets one event type have handlers on several topics (shadow, replay, compacted).
- Inbound events are checked against the tolerant `ZOD` (every field optional, unknown fields and enum values pass). Content reaches the handler effectively unvalidated. Parse it with your own schema and turn a failure into a `PermanentError`; a raw `ZodError` is transient and retries forever.
- The key is `tenantId:subTenantId:subjectId` and must match the envelope, or the message is dropped as permanent. euphony's `publish` always gets this right; a hand-built `client().send` may not.
- A message on a topic that has no matching handler is acknowledged and skipped with no log.
- `unsubscribe()` clears only `createEventHandler` registrations. Excision, custom, task, and timer registrations stay, so a second `subscribe()` in the same process (common in tests) throws on duplicates. It also throws in a process that never subscribed; guard a shutdown hook that producer-only entry points share.

### The handler context

`ctx` is prosody's context plus:

| Member | Use |
| --- | --- |
| `key` | `{ tenantId, subTenantId, subjectId }` from the message key. Fields are typed optional; validate them instead of using `!`. |
| `signal` | Pass it to every I/O call. See [prosody.md](prosody.md#cancellation). |
| `idempotencyId` | Stable for retries of this message, timer, or task. |
| `entity` | `{ type, id }` when the envelope has both. |
| `publish`, `bundle`, `propose`, `assertEntity`, `retractEntity`, `exciseEntity` | Routing defaults from `ctx.key`. |
| `hasProposal(id)` | Whether this event answers a proposal you sent. |
| `scheduleTask`, `cancelTask`, `getTasks` | Tasks; see [Timers and tasks](#timers-and-tasks). |
| `state(def)` | A checkpoint, or any prosody keyed-state collection. |
| `demand` | `{ kind: "normal" | "failure", retry }` from prosody: whether this run is a retry. |

## Excision

An excision is a regulatory hard delete. The handler must remove **everything** the app holds for that entity: rows, caches, files, keyed state, and scheduled timers or tasks. It is not a soft delete; that is a retraction.

- On ordinary topics, register `createEntityExcisedHandler(EntityDefinition, handler)` for every entity type that has an assertion handler. Pass the entity definition (`Lead`), not an event class. It handles the `<entityType>.excised` event.
- On a compacted topic, `createEntityHandler`'s required `onExcise` does this.
- If the app keeps nothing for an entity, the excision handler still has to exist. Make it a no-op and say why in a comment.

## Entities on compacted topics

`createEntityHandler` consumes `compacted.<canonical topic>` (for example `compacted.witco.lead-events`), a mirror where each message holds the full current entity plus the prior value of each changed field. It replaces 13.x's `createEntityChangedHandler`, and you do not diff against your own store.

```typescript
createEntityHandler(Lead, {
  onCreate: async (ctx, lead) => db.leads.insert({ id: lead.id, ...lead.content }),
  onUpdate: async (ctx, lead) => {
    if (lead.changedAny("emails", "phones")) await contactSync.enqueue(lead.id);
    await db.leads.update(lead.id, lead.content);
  },
  retractionType: CRMLeadRetractedEvent, // required with onRetract
  onRetract: async (ctx, lead) => db.leads.markDeleted(lead.id),
  onExcise: async (ctx, lead) => db.leads.deleteAll(lead.id), // required
});
```

- The compacted topic must exist for that entity's source topic. Check before you choose this API; if it does not exist, use `createEventHandler` plus `createEntityExcisedHandler`.
- Give `onUpsert`, or `onCreate` and `onUpdate`. With only `onUpdate`, creations are consumed and dropped with no error.
- `onRetract` needs `retractionType`: `RETRACTION_TYPE` is `undefined` at runtime for most entity definitions, and registration throws without it.
- To diff by hand on an ordinary topic, `new Entity(current)` is still exported.

## Proposals and `propose()`

A proposal asks the owning subsystem to act on an entity it owns. Cross-subsystem writes are always proposals, never assertions. Each proposal has paired `.succeeded` and `.failed` events.

Two ways to send one:

- **Fire and forget:** `publish(...)` the proposal, keep `payload.id`, and handle the paired success or failure event later with `ctx.hasProposal(id)`.
- **Wait for the answer:** `propose()` sends a prosody request to the owning subsystem and waits.

```typescript
const outcome = await ctx.propose(
  { eventType: SomeProposedEvent, content }, // any *.proposed event class
  { timeoutMs: 10_000 },
);
if (outcome.ok) {
  // outcome.value.status: 200 succeeded, 202 accepted, 204 ignored, 400 failed
} else {
  // outcome.error.kind: "timeout" | "handler" | "formatMismatch" | "malformedResponse"
}
```

- `propose()` takes only proposal events; anything else throws a permanent `ProposalError`. It cannot target your own `PROSODY_SUBSYSTEM` (that throws a transient error, so it retries forever).
- To answer a proposal, publish the paired success or failure event with **`ctx.publish`** inside the proposal handler, with `proposals: [proposal.id]`. That publish becomes the 200 or 400 response. A top-level `publish` is not captured, and a second outcome throws.
- Answer bad input with the paired failure event and a `failureCode`, and return normally. Throwing `PermanentError` drops the proposal and leaves the proposer with no answer.

## Timers and tasks

Use one or the other in an app, not both; registering both throws.

- **Timers** (`createTimerHandler` with `ctx.schedule`, `ctx.clearAndSchedule`, `ctx.unschedule`): one handler for the app. A timer carries only `{ key, time }`, no payload. Second precision; two timers for the same key in the same second become one.
- **Tasks** (`createTaskHandler(name, fn)` or `createTaskHandlerWithArgs<T>(name, fn)`, scheduled with `ctx.scheduleTask(name, when?, args?)`): named schedules per key. euphony stores them in prosody keyed state; no app table and no `taskOptions`. One due task runs per wake (tasks never run first, then the oldest). `subscribe(handlers, { defaultTaskName })` names a task to run when a wake finds none; it must name a registered task.
- With tasks on, the raw timer methods on `ctx` throw.
- A task scheduled for a name with no handler throws a transient error and retries forever.
- Both need Cassandra, or mock mode.

## Checkpoints

A checkpoint saves progress inside one attempt, so a retry of the same message resumes instead of starting over.

```typescript
const progress = checkpoint("import-progress", {
  schema: z.object({ page: z.number() }),
  ttlSeconds: 3600, // must be > 0
});
await subscribe(handlers, { stateCollections: [progress.stateDefinition] });

// in a handler:
const state = ctx.state(progress);
const start = (await state.hasCheckpoint()) ? (await state.restore()).page : 0;
// ...
await state.save({ page }); // commits now
```

- Register `progress.stateDefinition`, not `progress` (the README shows the latter).
- A checkpoint is scoped to `ctx.idempotencyId`: it is visible only to retries of the same message, timer, or task.
- `restore()` with nothing saved throws a transient `CheckpointNotFoundError`; check `hasCheckpoint()` first.
- For state that outlives one message, use prosody keyed state directly; see [prosody.md](prosody.md#keyed-state).

## Errors and retries

Every euphony error is a subclass of prosody's `TransientError` (retry) or `PermanentError` (drop). An unclassified error is transient. In Pipeline mode, the default, a transient error retries until it succeeds, so a deterministic bug stalls that key forever.

| Retried (transient) | Dropped (permanent) |
| --- | --- |
| Publish validation and identity errors, `MissingEventHelperError`, `RekeyError`, `SelfRequestError`, `ProposalAlreadyResolvedError`, `TaskSchedulingError`, `HandlerNotFoundError`, checkpoint errors, `EntityRetractionUnavailableError`, `UnsupportedExcisionTopicError` | `MessageValidationError`, `MalformedMessageError`, `InvalidKeyError`, `EnvelopeMismatchError`, `CompactedEventError`, `ProposalError`, `ConfigurationError`, `HandlerRegistrationError` |

- A publish inside a handler that fails validation is transient, so a broken outgoing payload retries forever. Catch it and rethrow as `PermanentError` when it cannot succeed.
- A permanent error means the message is gone. Use it for data that can never be processed, not for errors you can fix.

## Where the upstream docs are wrong

Trust the code over these README statements (14.5.0):

- "`subscribe()` is idempotent; later options are ignored." It throws on a second call and when the client already exists.
- The Usage example publishes before it subscribes, so it throws.
- Most consumer examples register an assertion handler with no excision handler, so `subscribe()` throws.
- `client().send(...)` and `const packet = bundle(...)` need `await`.
- "euphony does not implement `onExcise`." It does, on compacted topics.
- `stateCollections: [checkpointDef]` should be `[checkpointDef.stateDefinition]`.
- Spans are created only "when `OTEL_SERVICE_NAME` is set." They are always created.
- `docs/entities.md` says `createEntityHandler` is the default export. There is no default export.
- `event-production-howto.md` does not mention `PROSODY_SUBSYSTEM`, which is required.
