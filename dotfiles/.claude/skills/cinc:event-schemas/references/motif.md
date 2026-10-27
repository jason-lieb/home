# motif (experimental)

> **Experimental.** motif is pre-1.0 and releases several times a day. No app uses it yet. This page is verified against motif 0.22.0 and stays thin on purpose: read the upstream docs for detail. They are in a private repo, so the links work only for `cincpro` org members.

## Step 1: check the version first

1. Run the drift check from the project root. The `motif` rows show the pins of `@cincpro/motif-devkit` (in a schema repo) and `@cincpro/motif` (in a package or app), and the latest motif release:

   ```bash
   node "<skill-dir>/scripts/check-drift.mjs" "<skill-dir>" --skill event-schemas --project .
   ```

   Without Node, read the pins from `package.json`, or run `npm ls @cincpro/motif-devkit @cincpro/motif`, and compare them with the `motif` entry in [../sources.json](../sources.json).
2. **`older` pin:** say which version the advice is for, and read the motif [CHANGELOG](https://github.com/cincpro/motif/blob/main/CHANGELOG.md) for what differs.
3. **`newer` pin, or `recommend an update issue` for motif:** say that this page may be out of date. Read the motif CHANGELOG for the gap; minors before 1.0 often break. Recommend an update issue as Step 1 of [../SKILL.md](../SKILL.md) describes, titled `docs(event-schemas): update for motif <version>`. The drift check ignores motif patch releases (`"notify": "minor"`), because motif releases several times a day.
4. **Newer patch only, or the same version:** go on.

On 0.x, a caret range locks the minor: `^0.22.0` means `>=0.22.0 <0.23.0`. Each minor release needs a deliberate bump.

## What motif is

motif is a TypeSpec library, emitter, and CLI. You declare entities, topics, and proposals once. motif derives every message shape from them (assertion, retraction, excision, and proposed, succeeded, failed) and emits JSON Schema, TypeScript types with Zod, C#, Python, and Ruby.

It replaces the **code-generation half** of `event-schemas`: the hand-written per-event `.tsp` files and the generators. It does not replace the registry. `event-schemas` still holds the declarations and still owns review, governance, and releases. The upstream README places it between the two:

```
event-schemas   declares entities, topics, and proposals; owns governance and release
motif           derives every message shape from those declarations
prosody         the bus client, which consumes the generated interfaces
```

Adoption starts in the `event-schemas` repo with `cincpro/event-schemas#821` ("feat: motif"), which is open. Until it merges, author events the 14.x way in [../SKILL.md](../SKILL.md). Use this page only when the repo you work in has a `tspconfig.yaml` that emits `@cincpro/motif-devkit`.

## How to recognize a motif project

`tspconfig.yaml` emits the motif devkit, and each `.tsp` file starts with `import "@cincpro/motif-devkit"; using Motif;`:

```yaml
warn-as-error: true
emit:
  - "@cincpro/motif-devkit"
options:
  "@cincpro/motif-devkit":
    emitter-output-dir: "{project-root}/motif-output"
    emitters: [ir, json-schema, typescript, csharp, python, ruby]
```

## Packages

| Package | Who installs it |
| --- | --- |
| `@cincpro/motif-devkit` | Schema repos only. TypeSpec library, emitter, and the `motif` CLI. |
| `@cincpro/motif` | TypeScript packages and apps. Runtime; Zod 4 is an optional peer for `@cincpro/motif/zod`. |
| `cincpro-motif` | Python (>= 3.9) and Ruby (>= 3.0) runtimes. |
| `Cincpro.Motif` | .NET runtime. |

All five share one version. They publish to AWS CodeArtifact, not to GitHub Packages or public npm. Do not paste commands that print a registry token into the transcript; use a wrapper that keeps the token in a file. Never add the devkit to an app; apps depend on the runtime only.

## The concepts in brief

- `@subsystem("x")` on a namespace: the first segment of every derived event type.
- `@topic("witco.x.y")` on a model: the topic, with the key axes `@tenant`, `@subTenant`, and `@subject` (all three are required). The key is still `tenant:subTenant:subject`.
- `@entity("name")` with `@publishedOn(TopicModel)` on a content model: derives `subsystem.name` and its `.asserted`, `.retracted`, and `.excised` events. Every entity is excisable unless it has `@noExcision`.
- `@reference(EntityModel)` on an ID property: ties the ID to an entity, and the compiler checks it.
- `@proposal` on an `op`: derives `.proposed`, `.succeeded`, and `.failed`.
- `#deprecated "reason"` (0.22 and later) on a property, an enum member, or a declaration: motif carries it into every output. On an `@entity` or `@proposal`, it deprecates every event derived from it.

The compiler enforces rules that `event-schemas` 14.x enforces only by review: lowerCamelCase names, no array at the root of content, and every top-level content property optional **and** nullable.

## Workflow

1. Declare or change the model.
2. Run `motif explain` to see what the declaration expands into. Do this after each change.
3. Run `motif check`, then `motif generate`. Warnings fail the build (`warn-as-error: true`).
4. Do not commit `motif-output/`. The `#821` branch of `event-schemas` ignores it in git.

Needs Node 20 or later and TypeSpec compiler 1.x.

## Traps

- **Breaking minors:** 0.6 removed `@topicKey` and `@identity`. 0.9 made all three key axes required and made top-level content properties optional and nullable. 0.18 removed `@noChangelog`, but the changelog lists it as a feature. Read the changelog for every minor bump.
- **A reference to a deprecated declaration fails the build.** It gives a `deprecated` warning, and `warn-as-error: true` makes that an error. Add `#suppress "deprecated" "<why>"` where the reference is deliberate.
- **Keep the devkit and the runtimes on the same minor.** 0.22 raised the IR and runtime contract versions.
- **The subject is the key axis, not "what the message is about".** For example, `leadPhone` events are keyed by the lead.
- **Do not trust the description of `#821` about publishing.** It says that publishing moves to GitHub Packages, but the branch still publishes to CodeArtifact. Read the diff. The `documentation/MOTIF_MIGRATION.md` on that branch is also behind the branch (it cites devkit `^0.11.0`).

## Upstream docs

- [README.md](https://github.com/cincpro/motif/blob/main/README.md): overview, install, CLI, and what each target emits.
- [documentation/AUTHORING.md](https://github.com/cincpro/motif/blob/main/documentation/AUTHORING.md): the decorator reference, the workflow, "Errors you will see", and "Deciding what to declare". Read this before you author.
- [documentation/DESIGN.md](https://github.com/cincpro/motif/blob/main/documentation/DESIGN.md): why motif works as it does.
- [samples/comms/main.tsp](https://github.com/cincpro/motif/blob/main/samples/comms/main.tsp): the `event-schemas` `comms` subsystem in motif; 14 event files become 6 declarations.
- [runtime/typescript/README.md](https://github.com/cincpro/motif/blob/main/runtime/typescript/README.md): the TypeScript runtime.
- [CHANGELOG.md](https://github.com/cincpro/motif/blob/main/CHANGELOG.md).
