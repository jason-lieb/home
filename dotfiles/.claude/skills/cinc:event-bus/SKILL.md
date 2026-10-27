---
name: event-bus
description: "Publish and consume events on the CincPro (Witco) Kafka event bus from an app, with @cincpro/euphony and @prosody-events/prosody. Use whenever an app's package.json has @cincpro/euphony, @prosody-events/prosody, or @cincpro/prosody, or the user wants to publish an event, add or fix an event handler or consumer, build a worker-kafka component, handle an excision, send a proposal or use propose(), schedule timers or tasks, use keyed state or checkpoints, set PROSODY_* or EUPHONY_* variables, debug events that are dropped, duplicated, or retried forever, review an app's event-bus setup for known mistakes, or upgrade euphony 13 to 14 or prosody to 0.6. Not for adding or changing event schemas in the event-schemas repo (use event-schemas) or for writing deploy.yaml (use galactus)."
---

# Event bus: publish and consume with euphony and prosody

This skill is for **app code that uses** the event bus. It covers `@cincpro/euphony` (publish, typed handlers, entities, proposals, tasks) and `@prosody-events/prosody` (the Kafka client under euphony: config, ports, retries, keyed state). Python, Ruby, and C# apps use prosody bindings in their own language; this skill covers JS and TS.

## Step 1: check the versions first

The content here is verified against the versions in [sources.json](sources.json): euphony 14.5.0 and prosody 0.6.1.

1. Run the drift check from the project root, once per session. It reports the project's pins and whether an upstream release has moved past this skill, and it caches the upstream part for a day.

   ```bash
   node "<skill-dir>/scripts/check-drift.mjs" "<skill-dir>" --skill event-bus --project .
   ```

   Replace `<skill-dir>` with this skill's base directory. If Node is not available, read the pinned versions of `@cincpro/euphony` and `@prosody-events/prosody` from `package.json` and the lockfile yourself.
2. Use the pin table (`STATUS`):
   - **`older`:** say so. For euphony before 14 (or early 14.x), or prosody before 0.6, use [references/migrate-13-to-14.md](references/migrate-13-to-14.md). Several APIs in this skill do not exist in 13.x, and some 13.x APIs are gone. Never give 14.x advice to a 13.x app without saying which version it is for.
   - **`newer`:** say that this skill may be out of date for this app. Read the upstream CHANGELOG for the gap (and the installed package's `.d.ts` files) before you rely on the skill, and recommend an update issue.
   - **`same`:** go on.
3. Use the upstream table (`ACTION`):
   - **`none: ...`** (no `gh`, offline): go on, and say nothing about it.
   - **`mention only`:** say in one sentence that a newer release exists.
   - **`recommend an update issue`:** follow the update issue steps below.

**Update issue.** Look for an open issue first with `gh issue list -R cincpro/claude-plugins --label skill-drift --search event-bus`, and point to it if one exists. Else run the drift check again with `--issue-draft event-bus`, and show its title and body as a ready-to-run `gh issue create -R cincpro/claude-plugins --label skill-drift` command. If it prints no draft, use the title `docs(event-bus): update for <package> <version>`. Run the command only after the user approves it.

Authority order when sources disagree: the installed package (`node_modules/.../dist/*.d.ts` and code) > this skill > the upstream README. The euphony README has known errors; [references/euphony.md](references/euphony.md#where-the-upstream-docs-are-wrong) lists them.

## The domain model

Other skills (`event-schemas`, `galactus`) rely on this section.

```
your app        publishes with euphony, consumes with euphony handlers
event-schemas   TypeSpec registry → event classes, Zod validators, topics
prosody         Kafka client (Rust, JS bindings): ordering, retries, timers, dedup, state
Kafka           witco.* topics (and compacted.witco.* mirrors)
```

The company appears as **Witco** in topics and docs and as **cincpro** in GitHub and npm. Same system.

**Event categories:**

| Category | Meaning | Event name |
| --- | --- | --- |
| assertion | The current state of an entity that the publishing subsystem owns | `<subsystem>.<entity>.asserted` |
| retraction | A soft delete: the entity no longer exists | `<subsystem>.<entity>.retracted` |
| excision | A regulatory hard delete: every consumer removes all data for the entity | `<subsystem>.<entity>.excised` |
| proposal | A request that another subsystem act on an entity it owns | `<subsystem>.<action>.proposed` |
| success / failure | The answer to a proposal; references the proposal IDs | `<subsystem>.<action>.succeeded` / `.failed` |

**Identity:** tenant (brand: `cinc`, `realgeeks`, `witco`, or `unassigned`) → sub-tenant (a partition in the tenant, such as a CRM ID or site ID) → subject (the resource the event is about, such as a lead ID) → entity (`data.entity.{type,id}`, where the type is the event-name prefix, such as `crm.lead`).

**Key:** the Kafka key is `tenantId:subTenantId:subjectId`. Order is per key. On compacted topics the subject is `<entityType>:<entityId>`.

**Merge rule:** a consumer applies an assertion as a **shallow, top-level upsert**. Each top-level field replaces the stored one as a whole; never deep-merge. A missing field means "no change"; `null` means "cleared".

**Topics:** the topic of an event always comes from its class (`EventClass.TOPIC`). Topics are not one per subsystem. Never hard-code a topic string. The `event-schemas` skill covers the catalog of subsystems and topics.

## Which API to use

| Job | Use |
| --- | --- |
| Publish from a route, script, or job | `publish({ eventType, ..., idempotencyKey })` |
| Publish from inside a handler | `ctx.publish(...)` |
| Publish by entity definition | `assertEntity` / `retractEntity` / `exciseEntity` (or `ctx.` forms) |
| Handle an assertion, retraction, proposal, success, or failure | `createEventHandler(EventClass, fn)` |
| Handle an excision | `createEntityExcisedHandler(EntityDefinition, fn)` — **required** next to every assertion handler |
| Mirror an entity into your DB, with "what changed" | `createEntityHandler(Entity, { onUpsert, onExcise })` on its compacted topic |
| Ask another subsystem to act, and wait for the answer | `ctx.propose(...)` / `propose(...)` |
| Ask, and handle the answer later | `publish` the proposal; handle its `.succeeded`/`.failed` with `ctx.hasProposal(id)` |
| Answer a proposal | `ctx.publish` the paired success or failure event, with `proposals: [id]` |
| Run work later for a key | Tasks (`createTaskHandler` + `ctx.scheduleTask`) or timers (`createTimerHandler` + `ctx.clearAndSchedule`), not both |
| Resume a long handler after a retry | `checkpoint(...)` + `ctx.state(def)` |
| Keep per-key working state | prosody keyed state (`value`, `map`, `set`, `deque`) via `stateCollections` |
| Send or receive a payload that is not a standard event | `(await client()).send(...)` / `createCustomEventHandler` |

Details: [references/euphony.md](references/euphony.md) and [references/prosody.md](references/prosody.md).

## Required setup

- Node 24 or later. Debian bookworm-based images (`node:24-slim`); no Alpine. linux x64 hosts need AVX2.
- Env for every non-mock process: `PROSODY_BOOTSTRAP_SERVERS`, `PROSODY_CASSANDRA_NODES` (also for API servers that only publish), `PROSODY_SUBSYSTEM`, `EUPHONY_TENANT`. Consumers add `PROSODY_GROUP_ID`. Set `PROSODY_SOURCE_SYSTEM` to a value that differs from the group ID if the app consumes its own events.
- Local and tests: `PROSODY_MOCK=true` (in-memory, no Kafka or Cassandra), still with `PROSODY_SUBSYSTEM`.
- With galactus: galactus adds the brokers, `PROSODY_CASSANDRA_NODES`, and `PROSODY_STATE_CACHE_DIR` to `worker-kafka` components only; an `api` or other component that publishes sets them itself. galactus never adds `PROSODY_SUBSYSTEM`. Set `autoscaling.consumer_group` equal to `PROSODY_GROUP_ID` (it defaults to the app `name:`), and list the topics in `PROSODY_SUBSCRIBED_TOPICS` for KEDA, even though euphony ignores that variable. Default worker probes use prosody's port 8000.
- euphony 14.4 and later are published only to CodeArtifact. An app whose `.npmrc` points `@cincpro` at GitHub Packages cannot install them.

## Traps that cause most bugs

1. **Subscribe before anything creates the client.** `publish`, `bundle`, `propose`, the entity operations, `client()`, and `unsubscribe` create it; after that, `subscribe()` throws.
2. **Every assertion handler needs an excision handler** for the same entity type and topic, or `subscribe()` throws.
3. **`idempotencyKey` must be unique per operation.** Content is not part of the event ID; a reused or `undefined` key makes different events share one ID, and dedup drops them with no error.
4. **Unclassified errors retry forever** in the default Pipeline mode. Throw `PermanentError` only for input that can never succeed; that drops the message. A raw `ZodError` is transient.
5. **Validate content in the handler.** Inbound validation is loose (every field optional). Parse with your own schema and turn failures into `PermanentError`.
6. **Answer proposals; do not throw.** Bad proposal input gets the paired `.failed` event via `ctx.publish`; a thrown `PermanentError` leaves the proposer with no answer.
7. **`sourceSystem` equal to the group ID** (the default) makes a consumer skip its own events.
8. **An invalid `EUPHONY_TENANT` drops every message** (14.5). A missing one publishes as `unassigned`, which tenant-pinned consumers ignore.
9. **Ports:** every non-mock client binds 9099 at start; consumers also bind 8000. Two processes on one host collide.
10. **Pass the `signal`** to all I/O, and never swallow a cancellation error.
11. **Handlers must be idempotent.** Delivery is at-least-once.
12. **`RETRACTION_TYPE` is `undefined` at runtime** for most entity definitions: pass `retractionType` to `createEntityHandler` with `onRetract`, and publish retractions with the event class.

To review or debug an existing app, check it against [references/anti-patterns.md](references/anti-patterns.md).

## References

- [references/euphony.md](references/euphony.md) — publish, consume, excision, entities, proposals, timers and tasks, checkpoints, errors, upstream doc errors.
- [references/prosody.md](references/prosody.md) — config and env, ports, Docker and platform, retry modes, cancellation, dedup, keyed state, direct client use.
- [references/conventions-testing.md](references/conventions-testing.md) — how CincPro apps lay out workers and handlers, and how they test them.
- [references/migrate-13-to-14.md](references/migrate-13-to-14.md) — upgrade steps for euphony 13 → 14.5 and prosody 0.4 → 0.6.
- [references/anti-patterns.md](references/anti-patterns.md) — mistakes found in real apps, each with how to find and fix it. Read it when you review, debug, or upgrade an app.
