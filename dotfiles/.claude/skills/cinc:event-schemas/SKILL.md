---
name: event-schemas
description: "Add and change events in the CincPro (Witco) event-schemas registry (cincpro/event-schemas, TypeSpec), and use the @cincpro/event-schemas package. Use whenever the user works in the event-schemas repo or its .tsp files under models/subsystems or events/subsystems, or a tspconfig.yaml emits @cincpro/motif-devkit, or the user wants to add a field to an event or entity, create a new entity, event type, assertion, retraction, or proposal with succeeded and failed events, decide between a new field and a new entity, check whether a schema change is backward compatible, find which topic or subsystem carries an event, list the subsystems and topics, understand excision or the empire and identity subsystems, upgrade @cincpro/event-schemas from 12 to 14 (website to sites renames), or author events with motif. Not for app code that publishes or consumes events (use event-bus) or for deploy.yaml (use galactus)."
---

# event-schemas: add and change events in the registry

This skill is for **app developers who add the events their app needs** to `cincpro/event-schemas`. It covers where to edit, the rules the build enforces, the rules that only review enforces, and how a change reaches apps. The domain model (categories, tenancy, key format, shallow-upsert merge) is in the `event-bus` skill; this skill does not repeat it.

## Step 1: check the versions first

The content here is verified against the versions in [sources.json](sources.json): event-schemas 14.22.0 and motif 0.22.0.

1. Run the drift check from the project root, once per session. It reports the project's pins and whether an upstream release has moved past this skill, and it caches the upstream part for a day.

   ```bash
   node "<skill-dir>/scripts/check-drift.mjs" "<skill-dir>" --skill event-schemas --project .
   ```

   Replace `<skill-dir>` with this skill's base directory. If Node is not available, read the pinned `@cincpro/event-schemas` from `package.json` and the lockfile yourself.
2. Use the pin table (`STATUS`):
   - **`older`:** say so. Topics, event types, and fields were renamed; use [references/renames-12-to-14.md](references/renames-12-to-14.md). Never give 14.x advice to a 12.x or 13.x app without saying which version it is for.
   - **`newer`:** say that this skill may be out of date. Read the event-schemas `CHANGELOG.md` for the gap before you rely on the skill, and recommend an update issue.
   - **`same`:** go on.
3. Use the upstream table (`ACTION`):
   - **`none: ...`** (no `gh`, offline): go on, and say nothing about it.
   - **`mention only`:** say in one sentence that a newer release exists.
   - **`recommend an update issue`:** follow the update issue steps below.

**Update issue.** Look for an open issue first with `gh issue list -R cincpro/claude-plugins --label skill-drift --search event-schemas`, and point to it if one exists. Else run the drift check again with `--issue-draft event-schemas`, and show its title and body as a ready-to-run `gh issue create -R cincpro/claude-plugins --label skill-drift` command. If it prints no draft, use the title `docs(event-schemas): update for <package> <version>`. Run the command only after the user approves it.

In the `event-schemas` repo itself, the package is not a dependency, so the pin table is empty. The version there is `version` in `node/package.json`. If `tspconfig.yaml` emits `@cincpro/motif-devkit`, also read [references/motif.md](references/motif.md); the drift check covers motif too.

Authority order when sources disagree: `make compile` and the generated code > this skill > `documentation/*.md` in the repo > `README.md`. Several repo docs are out of date; [Where the repo docs are wrong](#where-the-repo-docs-are-wrong) lists them.

## Field, entity, or proposal

Decide first (`documentation/ARCHITECTURE.md`, "Event Modeling Guidelines"):

| The change | Do this |
| --- | --- |
| A property of an entity your subsystem owns (a flag, status, counter, timestamp) | Add an **optional field** to its content model. No event files change. |
| A thing with its own lifecycle or owner, a many-to-many relationship, or a field that would need a deep merge | Add a **new entity** with an assertion and a retraction. |
| A request that another subsystem create, change, or delete an entity **it** owns | Add a **proposal** with paired `.succeeded` and `.failed` events. Never assert another subsystem's entity. |

One subsystem writes each top-level field. Two subsystems can assert the same entity type, but never the same field.

## Add a field (the common case)

1. Edit the content model in `models/subsystems/<sub>/<model>.tsp`. Add the field as optional (`name?: Type`).
2. Format and compile (see [Validate before the PR](#validate-before-the-pr)).
3. Open a PR with a Conventional Commit title (`feat(crm): add lead nickname`). `feat` makes a minor release and `fix` a patch.
4. Ask for review from an engineer whose app consumes the event, and post the PR in `#dev-event-schemas`.
5. After merge, the release bot opens a release PR. When it merges, Node, Python, Ruby, and C# packages ship with one shared version. Apps then bump `@cincpro/event-schemas`.

If the topic is in `data_warehouse/topics.yaml`, the new field also becomes a ClickHouse column. Renames or exclusions for the warehouse go in `data_warehouse/subsystems/<sub>.yaml`.

## Add an entity

Copy the `identity` subsystem; it is small and current. For entity `<entity>` in subsystem `<sub>`:

| File | Content |
| --- | --- |
| `models/subsystems/<sub>/entities/<sub><Entity>Entity.tsp` | `const <SUB>_<ENTITY>_ENTITY_TYPE = "<sub>.<entity>";` and `model <Sub><Entity>Entity extends Entity { type: "<sub>.<entity>"; }` |
| `models/subsystems/<sub>/entities/main.tsp` | Import the entity file. |
| `models/subsystems/<sub>/<entity>.tsp` | The content model (`data.content`). |
| `models/subsystems/<sub>/main.tsp` | Import the content model. The repo docs leave this step out. |
| `events/subsystems/<sub>/<sub>.<entity>.asserted.tsp` | The assertion. |
| `events/subsystems/<sub>/<sub>.<entity>.retracted.tsp` | The retraction. |
| `events/subsystems/<sub>/main.tsp` | Import both event files. |

A new subsystem also needs `import "./<sub>";` and `using <Sub>;` in `events/subsystems/main.tsp` and `models/subsystems/main.tsp`. An id-only `<entity>Reference.tsp` model is optional.

Do **not** add an excision file. Excision uses one generic schema; see [references/empire-excision.md](references/empire-excision.md).

Each assertion and retraction needs these lines. This is `events/subsystems/identity/identity.person.asserted.tsp`:

```tsp
model PersonAssertedContent extends AssertionContent { person?: Person; }
model PersonAssertedAppData extends AssertionAppData {
  entity?: IdentityPersonEntity; content?: PersonAssertedContent; subsystem: "identity"; }
@extension("@canonicalTopic", "witco.identity.person-events")
@extension("@entityType", IDENTITY_PERSON_ENTITY_TYPE)
@extension("@contentEntityIdPath", "person.id")
@extension("@contentSubTenantIdPath", "person.subTenantId")
@extension("@contentSubjectIdPath", "person.id")
model PersonAssertedEvent extends Events.Subsystems.Assertion {
  type: "identity.person.asserted"; data: PersonAssertedAppData; }
```

Prefix every model name with the subsystem (`CRMLeadPhone`, not `LeadPhone`). The build does not enforce this, but two models with one name break code generation.

## Add a proposal

Add `<sub>.<action>.proposed.tsp`, `.succeeded.tsp`, and `.failed.tsp` in `events/subsystems/<sub>/`, and import all three in its `main.tsp`. They extend `Events.Subsystems.Proposal`, `Success`, and `Failure`. Each needs `@canonicalTopic`, `@contentSubTenantIdPath`, and `@contentSubjectIdPath`, and no `@entityType`. Use `events/subsystems/sms/sms.sendSMS.*.tsp` as the template; its `.failed` event adds `error?: string` and a `failureCode` enum. The build does not check that the three exist together, so check it yourself. The answer events refer to the proposal through `data.proposals`.

## What the build checks, and what it does not

`make compile` fails on these:

- An assertion or retraction without `@entityType`, `@contentEntityIdPath`, `@contentSubTenantIdPath`, or `@contentSubjectIdPath`.
- A proposal, success, or failure without `@contentSubTenantIdPath` or `@contentSubjectIdPath`.
- A `type` that is not `<entityType>.asserted` or `<entityType>.retracted`, or a `type` that another event already uses.
- An entity type without exactly one assertion and one retraction.
- Any TypeSpec warning (`warn-as-error: true`).

These pass the build and still break consumers:

1. **No `@canonicalTopic`:** the event class has no `TOPIC`, so apps cannot publish it.
2. **No `subsystem: "<sub>"` literal** on the AppData: the class has no `SUBSYSTEM`.
3. **A model name that does not end in `Event`, or a `type` that is not a string literal:** the event drops out of the unions, the validators, and the docs.
4. **A content path that does not exist.** The build checks only that the path is not empty. Paths are relative to that event's own content model, so a retraction with a different content shape needs its own paths.
5. **A missing pair:** forget to import both the assertion and the retraction, and nothing fails; the entity is just absent.
6. **Unformatted files:** `make check` formats only 20 of the 637 `.tsp` files, because the shell expands its glob. Run `npx tsp format "**/*.tsp"` (with the quotes).
7. **`RETRACTION_TYPE` is `undefined` at runtime** for most entity definitions in the Node package. It type-checks, but the generator writes it before the retraction class it points to, so the value is not set yet when the module loads. The exact count depends on the file order of the build machine. Do not rely on it: in apps, use the retraction event class. You cannot fix it with a schema change.

## Payload rules

- Make every top-level field optional. Absent means "no change". Use `X | null` when consumers must tell "cleared" from "unchanged".
- No arrays at the top level of content: they break the shallow merge. Model the items as child entities.
- Wrap IDs in objects (`agent: { id }`, not `agentId`), so related fields can be added later.
- Reference large or variable data by URL.
- A child entity never changes its parent. Retract it and assert a new one.

## Compatibility

No CI check compares a change with the last release. Review is the only gate.

| Safe | Breaking |
| --- | --- |
| A new optional field | A type change, or making a field required |
| A new event or entity type | A rename, removal, or restructure of a field |
| A new enum value, **for TypeScript consumers only** | A change of an event's topic or entity type |
| | A new top-level array, or a child moved to a new parent |

A new enum value can break Python, Ruby, and C# consumers: their generated enums are closed. TypeScript is tolerant because the consumer validator (`ZOD`) uses loose objects and relaxes enums to plain strings. The publisher validator (`PUBLISHER_ZOD`) is strict: exact enums and no unknown keys. Wire-breaking renames have shipped as minor releases (see [references/renames-12-to-14.md](references/renames-12-to-14.md)), so do not trust semver alone. A version bump also does not mean that your language changed, because all four packages share one version.

## Validate before the PR

1. Install with the `@cincpro` scope pointed at CodeArtifact, and `AWS_CODEARTIFACT_TOKEN` set by a wrapper that keeps the token in a file. Do not run a command that prints a registry token (`witctl credentials get`, `aws codeartifact get-authorization-token`) into the transcript.
2. Run `npm install`, then `make compile`. This runs every build check above.
3. Run `npx tsp format "**/*.tsp"`.
4. Optional: `make generate-docs` builds the docs in Docker. It also needs the CodeArtifact token, although the README says "just Docker".

## Packages and registry

| Language | Package |
| --- | --- |
| Node | `@cincpro/event-schemas` (subpaths `/enums`, `/enumObjects`) |
| Python | `event-schemas` (import `event_schemas`) |
| Ruby | `event_schemas` |
| C# | `Witco.EventSchemas` |

Since 14.20.0 all four publish to AWS CodeArtifact only (domain `witco`). An app whose `.npmrc` points `@cincpro` at GitHub Packages gets nothing newer than 14.19.0. `cincpro/event-schemas#821` (motif adoption) keeps CodeArtifact, although its description says GitHub Packages.

## Where the repo docs are wrong

- `CONTRIBUTE_SIMPLIFIED.md` says "ping Mitchell to release" and that the PR title needs `feat:`. The release bot is automatic, and any Conventional Commit type passes.
- `CREATE_UPDATE_IN_DEPTH.md` says the release PR is under a person's account and that packages build before it merges. A bot opens it, and packages build after it merges.
- The docs say the `{Subsystem}{Entity}AssertedEvent` name is required for code generation. Only the `Event` suffix and a literal `type` matter; prefix anyway to prevent collisions.
- `ARCHITECTURE.md` says CI rejects changes that relax requirements. No such check exists.
- `GENERAL_GUIDANCE.md` says to use `empire.entity.excised` for excisions. euphony 14.5 publishes and handles `<entityType>.excised` instead; see [references/empire-excision.md](references/empire-excision.md).
- `ruby/README.md` lists the categories without excision.
- Older guides say retraction content is a required tombstone. It is now optional context.

## References

- [references/catalog.md](references/catalog.md) — subsystems and topics, which topic carries which events, and the commands that recount them.
- [references/empire-excision.md](references/empire-excision.md) — the excision category, the generic excision schema and the euphony mismatch, and the `empire` and `identity` subsystems.
- [references/renames-12-to-14.md](references/renames-12-to-14.md) — topic, event, and field renames from 12 to 14, and the upgrade steps for an app.
- [references/motif.md](references/motif.md) — **experimental**: the TypeSpec toolkit that will replace the per-event files and generators.
