# Known anti-patterns

Mistakes found in real CincPro apps (survey of October 2026). Use this list to review an app's event-bus setup, to debug one, or to check an app before and after an upgrade. Each entry gives what goes wrong, how to find it, and the fix.

The search commands assume the app root as the working directory. Adjust paths for monorepos.

## Contents

- [Config and deploy](#config-and-deploy)
- [Dependencies and images](#dependencies-and-images)
- [Handlers](#handlers)
- [Publishing](#publishing)
- [Lifecycle](#lifecycle)
- [Tests](#tests)
- [Copied guidance](#copied-guidance)

## Config and deploy

### `PROSODY_SUBSYSTEM` missing after an upgrade

- **Effect:** On euphony 14.2 or later, the first `publish`, `subscribe`, or `client()` throws `ConfigurationError`. An outbox drain or a worker fails at once; a route that publishes fails on each request.
- **Find:** `grep -rn PROSODY_SUBSYSTEM deploy.yaml docker-compose*.y*ml .env.example src` finds nothing, while `package.json` pins euphony 14.2 or later.
- **Fix:** Set it in the top-level `environment:` of `deploy.yaml`, in compose, in CI, and in test setup. galactus does not add it.

### KEDA consumer group differs from the real group

- **Effect:** galactus scales `worker-kafka` on the lag of `autoscaling.consumer_group`, which defaults to the app's `name:`. When `PROSODY_GROUP_ID` is something else (for example `<app>-worker`), the autoscaler watches a group with no members and never scales on load.
- **Find:** In `deploy.yaml`, compare each `worker-kafka` component's `PROSODY_GROUP_ID` with its `autoscaling.consumer_group` (or the top-level `name:` when that is not set).
- **Fix:** Set `autoscaling.consumer_group` to the same value as `PROSODY_GROUP_ID`, and keep `PROSODY_SUBSCRIBED_TOPICS` on the component for KEDA.

### Publishing component without Kafka or Cassandra config

- **Effect:** galactus adds `PROSODY_BOOTSTRAP_SERVERS`, `PROSODY_CASSANDRA_NODES`, and `PROSODY_STATE_CACHE_DIR` to `worker-kafka` components only. An `api`, `web`, `cronjob`, or `command` component that publishes fails at client creation; on prosody 0.5 or later, even a publish-only client needs Cassandra.
- **Find:** Components other than `worker-kafka` whose code imports `publish` from euphony, with no `PROSODY_BOOTSTRAP_SERVERS` and `PROSODY_CASSANDRA_NODES` in their `environment:`.
- **Fix:** Set both on those components (per target if they differ).

### Missing or invalid `EUPHONY_TENANT`

- **Effect:** A missing value publishes as `unassigned`, which tenant-pinned consumers ignore. On euphony 14.5, an invalid value makes the consumer drop every message.
- **Find:** `grep -rn EUPHONY_TENANT deploy.yaml docker-compose*.y*ml`.
- **Fix:** Set one of `cinc`, `realgeeks`, `witco`, or `unassigned` in every environment.

### Worker skips its own events

- **Effect:** `PROSODY_SOURCE_SYSTEM` defaults to the group ID, and a consumer skips messages whose source system equals its group ID. Events that the worker (or a component with the same value) publishes never reach its own handlers.
- **Find:** The app consumes an event type that it also publishes, and `PROSODY_SOURCE_SYSTEM` is unset or equals `PROSODY_GROUP_ID` on the publishing component.
- **Fix:** Give the publishing component a different source system (for example `<app>-api`). Keep the default only when skipping is what you want.

### Dead and misleading config

- **Effect:** Readers think these settings do something, and debug the wrong thing.
- **Find:**
  - `EUPHONY_CONSUMER` anywhere: removed from euphony long ago.
  - `PROSODY_ALLOWED_EVENTS` in a euphony app: euphony sets allowed events from the handlers.
  - `PROSODY_GROUP_ID` on a component, or a whole app, that does not consume.
- **Fix:** Remove them. Keep `PROSODY_SUBSCRIBED_TOPICS` on `worker-kafka` components, because KEDA reads it.

## Dependencies and images

### Node older than 24 with prosody 0.5 or later

- **Effect:** prosody 0.5 and later declare Node 24. Nothing checks at runtime, so the app may start and then fail in ways that are hard to trace.
- **Find:** `grep -n '^FROM' Dockerfile*` shows `node:20` or `node:22` (or a `node-22` base image), while the lockfile resolves `@prosody-events/prosody` 0.5 or later. Check `.nvmrc` and CI `node-version` as well.
- **Fix:** Move to a Node 24 bookworm-based image (`node:24-slim`). On linux x64 hosts, also confirm AVX2.

### Lockfile out of step with `package.json`

- **Effect:** `package.json` asks for the new version, but `--frozen-lockfile` or `npm ci` installs what the lockfile says. The code uses an API that the installed version does not have, and the build or the first start fails.
- **Find:** Compare the declared range with the locked version: `grep -n '@cincpro/euphony' package.json` and the matching entry in `pnpm-lock.yaml` or `package-lock.json`. Two lockfiles in one repo (`package-lock.json` and `pnpm-lock.yaml`) that disagree are the same problem.
- **Fix:** Run the install again, commit the lockfile, and delete the lockfile of the package manager the app does not use.

### Registry that cannot serve the version

- **Effect:** euphony 14.4 and later are only on CodeArtifact. An app whose `.npmrc` points `@cincpro` at `npm.pkg.github.com` cannot install them.
- **Find:** `grep -n '@cincpro' .npmrc`.
- **Fix:** Point the scope at CodeArtifact. Do not paste commands that print a registry token into the transcript.

### Unused or mismatched event-bus dependencies

- **Effect:** Extra install weight, a native module in the build, and false hits in dependency surveys. Some apps pair euphony 11 or 12 with `@prosody-events/prosody` 0.1, which those euphony versions do not use (they need the legacy `@cincpro/prosody`).
- **Find:** euphony or prosody in `package.json` with no import in `src`: `grep -rln "@cincpro/euphony\|@prosody-events/prosody" src`.
- **Fix:** Remove the dependencies, or upgrade to a matched pair (euphony 14.3.1 or later with prosody `^0.6.0`).

## Handlers

### Excision handlers that do nothing in an app that stores data

- **Effect:** Since euphony 14.3, `subscribe()` throws unless every assertion handler has an excision handler. Apps add empty ones to get past the check. An excision is a regulatory hard delete, so data that must be erased stays in the app.
- **Find:** `createEntityExcisedHandler` calls whose function is empty or only logs, in an app that writes the entity (or state keyed by it) to a DB, cache, keyed state, or timers.
- **Fix:** Delete everything for the entity: rows, caches, files, keyed state (`ctx.state(def).clear()`), and schedules (`ctx.clearScheduled()` or the tasks). Keep a no-op only when the app stores nothing, with a comment that says so.

### Unvalidated content, or validation errors left transient

- **Effect:** Inbound validation is loose, so bad content reaches the handler. A raw `ZodError` or `TypeError` from it is transient, and the default Pipeline mode retries it forever.
- **Find:** Handlers that read `msg.payload.data.content` fields without a parse step, or that call `.parse()` without converting the failure.
- **Fix:** Parse with the app's own schema and throw `PermanentError` on failure. For proposals, publish the paired `.failed` event instead.

### Swallowed cancellation

- **Effect:** A handler that catches every error and returns treats a cancellation as success, and the message is lost.
- **Find:** `catch` blocks in handlers that do not rethrow, and I/O calls that do not take the handler's `signal`.
- **Fix:** Pass `signal` to I/O, and rethrow errors that you do not handle on purpose.

## Publishing

### Hand-built envelopes sent with `client().send`

- **Effect:** It skips euphony's validation, ID generation, and key rules. Hard-coded topic strings go stale when schemas move topics, and a wrong key makes every consumer drop the message. One app also overwrote `eventTime` with the publish time, which loses when the change really happened.
- **Find:** `grep -rn "client())\.send\|client()\.send" src`, and string literals that look like topics (`witco.`).
- **Fix:** Use `publish` (or `assertEntity`) with the event class. Keep `client().send` for payloads that are not standard events.

### Constant or reused `idempotencyKey`

- **Effect:** The event ID ignores content, so a key such as `"user.created"` shared by many calls with the same routing IDs makes events share one ID. Dedup drops all but the first, with no error.
- **Find:** `idempotencyKey:` values that are string literals, or objects with no record ID or operation ID in them.
- **Fix:** Include the operation and the record (and a run ID for backfills): `{ op: "userCreated", userId }`.

### Publish-side validation errors that retry forever

- **Effect:** euphony reports an invalid outgoing payload as a transient error. Inside a handler, one bad record retries forever.
- **Fix:** Catch the publish error and rethrow it as `PermanentError`, or check the packet from `await bundle(...)` before `publish` and return an error result.

## Lifecycle

### More than one radiant `onShutdown` callback

- **Effect:** radiant keeps only the first callback. Later ones log a warning and never run, so a connection or the consumer is not closed on shutdown.
- **Find:** `grep -rn onShutdown src` returns more than one call on the same path.
- **Fix:** Register one callback that runs all teardown in order: `unsubscribe()`, then publishers, then the DB.

### `unsubscribe()` in a process that never subscribed

- **Effect:** It throws, so a shutdown module that an API process and a worker share fails in the API.
- **Fix:** Wrap it in `try`/`catch`, or register it only in the worker.

## Tests

### Mocked euphony hides `subscribe()` errors

- **Effect:** Tests that mock `createEventHandler` or `subscribe` stay green when an excision handler is missing or a registration is invalid. The worker then crashes at start in production.
- **Find:** Every test that touches handlers mocks `@cincpro/euphony`, and no test calls the real `subscribe(handlers)`.
- **Fix:** Add one test that calls the real `subscribe` with `PROSODY_MOCK=true` and `PROSODY_SUBSYSTEM`. See [conventions-testing.md](conventions-testing.md#test-the-real-handler-set).

### Hand-written euphony mocks that drift

- **Effect:** Copied `__mocks__/@cincpro/euphony.ts` files fall behind the real API (for example, no `createEntityExcisedHandler`, fake event classes with wrong enum values).
- **Fix:** Use a partial mock that spreads the real module and overrides only the factories.

## Copied guidance

### Stale skills and templates in app repos

- **Effect:** Agent skills and templates copied into app repos (for example an `add-event-sourcing` skill from the `template-app-*` repos) describe euphony 13. They leave out `PROSODY_SUBSYSTEM` and excision handlers, add `EUPHONY_CONSUMER`, and their mocked tests pass anyway.
- **Find:** `.claude/skills/*/SKILL.md` and template docs in the app that mention euphony.
- **Fix:** Prefer this skill. Update or remove the copy, and check what it told an agent to write.
