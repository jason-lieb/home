# Migrate euphony 13 → 14 (and prosody 0.4 → 0.6)

Use this file when an app pins `@cincpro/euphony` 13.x, or an early 14.x, and is moving to 14.5. euphony 14 needs prosody `^0.6.0`, so the prosody steps come with it.

**Breaking changes shipped in minor releases.** The euphony CHANGELOG marks only 14.0.0 as breaking, but 14.2.0, 14.3.0, and 14.4.0 also break apps. Find the app's current version in the table and do every step from that row down.

| From | Steps that still apply |
| --- | --- |
| 13.x | 1–11 |
| 14.0.x – 14.1.x | 3–11 |
| 14.2.0 – 14.2.2 | 4, 7–11 |
| 14.2.3 – 14.2.x | 7–11 |
| 14.3.x | 7 (if prosody is still 0.5), 10, 11 |
| 14.4.x | 11 |

## Before you start

- Node 24 or later in every image, CI job, and dev machine. See [prosody.md](prosody.md#platform-and-docker) for base images and the AVX2 rule.
- Cassandra (`PROSODY_CASSANDRA_NODES`) for **every** non-mock process, including API servers that only publish. Under prosody 0.4 only consumers needed it.
- Point the `@cincpro` scope at CodeArtifact in `.npmrc`. GitHub Packages has euphony only up to 14.3.1.
- Regenerate the lockfile and check that it resolves the new versions. A stale lockfile with `--frozen-lockfile` builds the old ones.
- Upgrade `@cincpro/event-schemas` to `^14.9.1` or later in the same change; euphony 14.3 requires it. The event-schemas 12 → 14 renames (for example `website` → `sites` topics) are covered by the `event-schemas` skill.

## Steps

### 1. Remove `taskOptions` (14.0.0)

euphony stores tasks in prosody keyed state now.

```typescript
// before
await subscribe(handlers, { taskOptions: { readTaskState, upsertTaskState } });
// after
await subscribe(handlers);
```

- Delete the read/upsert functions and, after the cut-over, the app's task table.
- **Existing schedules are not migrated.** Tasks pending in the old table are lost; at the first wake for each key only `defaultTaskName` runs, if set. Before the deploy, list pending tasks and plan to schedule them again (for example from a one-off command, or by letting the next event for each key schedule them).
- A leftover `taskOptions` fails type-checking but is ignored at runtime.

### 2. Plan for checkpoints (14.1.0, optional)

Nothing breaks. Long handlers that restart from scratch on retry can now save progress; see [euphony.md](euphony.md#checkpoints).

### 3. Make `client()` and `bundle()` awaited; set `PROSODY_SUBSYSTEM` (14.2.0)

```typescript
// before
client().send(topic, key, payload);
const packet = bundle(request);
// after
(await client()).send(topic, key, payload);
const packet = await bundle(request);
```

- Search the app and its tests for `client()` and `bundle(` (not `ctx.bundle`, which stays synchronous).
- Set `PROSODY_SUBSYSTEM` everywhere the app runs: `deploy.yaml` (galactus does not add it), docker compose, CI, test setup, `.env.example`. Use the subsystem name as event-schemas spells it.

### 4. Expect new event IDs from handlers (14.2.3)

Events published with `ctx.publish` get different IDs than on 13.x, for the same input. A message that is retried across the deploy can publish a second copy that downstream dedup does not catch. Downstream consumers must already be idempotent; check the ones that are not. Renaming `PROSODY_GROUP_ID` or `PROSODY_SUBSYSTEM` later also changes these IDs.

### 5. Create the prosody client with `create()` (prosody 0.5)

Only for code that uses prosody directly:

```typescript
// before
const client = new ProsodyClient(config);
// after
const client = await ProsodyClient.create(config);
```

### 6. Give direct prosody handlers all three callbacks (prosody 0.5)

Direct `client.subscribe` needs `onMessage`, `onExcise`, and `onTimer`, and `onMessage`/`onExcise` must return a JSON value (`return null;`).

### 7. Rename prosody options (prosody 0.5 and 0.6)

Old names are ignored with no error.

| Old | New |
| --- | --- |
| `stateCacheSizeBytes` (number), `PROSODY_STATE_CACHE_SIZE_BYTES` | `stateOwnedCacheSize` (string, `"64 MiB"`), `PROSODY_STATE_OWNED_CACHE_SIZE` |
| `deferCacheSize`, `deferSeekTimeoutMs`, `deferDiscardThreshold` | `loaderCacheSize`, `loaderSeekTimeoutMs`, `loaderDiscardThreshold` |
| `idempotenceTtlS` | `idempotenceTtlSeconds` |
| `stateRecoveryDelaySeconds`, `PROSODY_STATE_RECOVERY_DELAY` | removed |

Also from prosody 0.5: payloads go out through `JSON.stringify` (a `Date` becomes a string; a `BigInt` throws), an inbound message is a native object (spreading it loses the fields), and every non-mock client binds port 9099. See [prosody.md](prosody.md).

### 8. Add an excision handler for every assertion handler (14.3.0)

`subscribe()` throws until each entity type with an assertion handler also has an excision handler on the same topic.

```typescript
// before
await subscribe([createEventHandler(CRMLeadAssertedEvent, onLead)]);
// after
await subscribe([
  createEventHandler(CRMLeadAssertedEvent, onLead),
  createEntityExcisedHandler(Lead, async (ctx, entity, signal) => {
    await deleteEverythingFor(entity.id, signal); // rows, caches, keyed state, tasks
  }),
]);
```

The excision handler must hard-delete everything the app holds for the entity. See [euphony.md](euphony.md#excision).

### 9. Pass the `createEventHandler` options as an object (14.3.0)

```typescript
// before
createEventHandler(EventClass, handler, mySchema);
// after
createEventHandler(EventClass, handler, { validationSchema: mySchema });
```

In JavaScript, or behind `any`, the old form is ignored with no error and the default schema runs instead.

### 10. Replace `createEntityChangedHandler` (14.4.0)

It is removed, with its option types. Choose a replacement:

- **The entity has a compacted topic** (`compacted.<topic>`): use `createEntityHandler`. Each message carries the full entity and what changed, so drop `readEntity`/`upsertEntity` diffing. See [euphony.md](euphony.md#entities-on-compacted-topics).
- **It does not:** use `createEventHandler` for the assertion event plus `createEntityExcisedHandler`, and diff with `new Entity(current)` if you still need change tracking.

```typescript
// before
createEntityChangedHandler(Lead, { readEntity, upsertEntity, watchedKeys: ["emails"] },
  async (ctx, entity) => { if (entity.hasChanges()) await sync(entity.getPatch()); });
// after, compacted topic
createEntityHandler(Lead, {
  onUpsert: async (ctx, lead) => { if (lead.changedAny("emails")) await sync(lead.content); },
  onExcise: async (ctx, lead) => deleteEverythingFor(lead.id),
});
```

The excision event also moved from `empire.entity.excised` (14.3.x) to `<entityType>.excised`. A 14.3.x producer and a 14.4+ consumer do not match; upgrade both.

### 11. Check tenant config (14.5.0)

An invalid `EUPHONY_TENANT` used to retry each message; now it is permanent and the consumer drops every message. Confirm the value is one of `unassigned`, `cinc`, `realgeeks`, `witco` in every environment before the deploy.

## After the upgrade

- Run the test suite with `PROSODY_MOCK=true` and `PROSODY_SUBSYSTEM` set. Tests that expected `bundle()` to throw on bad content must now expect `publish()` to throw (validation moved to send in 14.1.3).
- Remove `EUPHONY_CONSUMER` and `PROSODY_ALLOWED_EVENTS` from deploy and compose config. Keep `PROSODY_SUBSCRIBED_TOPICS` on galactus `worker-kafka` components, because KEDA reads it.
- Add a test that calls the real `subscribe(handlers)` with `PROSODY_MOCK=true`. Tests that mock euphony do not catch a missing excision handler. See [conventions-testing.md](conventions-testing.md#test-the-real-handler-set).
- Deploy the worker image on hardware with AVX2 (linux x64), or use arm64.
