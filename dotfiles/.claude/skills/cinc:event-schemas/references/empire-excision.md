# Excision, and the `empire` and `identity` subsystems

## Excision

An excision is a **hard delete** of one entity, for example for a regulatory request. Every consumer removes all the data it holds for that entity. A retraction is different: it is a soft delete, and its content is optional context.

Excision came in 13.9.0 (`events/subsystems/excision.tsp`). An excision has `category: "excision"`, `data.entity.type` and `data.entity.id`, an optional `data.subsystem` that names the owner, and the usual tenant, sub-tenant, and subject. It has no content.

### One generic schema

The registry has a single excision schema: `empire.entity.excised` (`EmpireEntityExcisedEvent`, in `events/subsystems/empire/empire.entity.excised.tsp`). It has no `@canonicalTopic`; the owner publishes it on the topic of the excised entity.

- 14.9.0 added a `<sub>.<entity>.excised` schema for each of 80 entities. 14.9.1 (#783) removed all of them again.
- `documentation/GENERAL_GUIDANCE.md` says: use `empire.entity.excised` for all excisions, and do not define an excision event for one entity.
- When you add an entity, do **not** add an excision file. The build requires only the assertion and the retraction.

### Trap: the `type` on the wire

The registry and euphony disagree about the `type` of an excision:

| Source | `type` it uses |
| --- | --- |
| event-schemas 14.22.0 docs and schema | `empire.entity.excised`, with the entity in `data.entity.type` |
| euphony 14.5 (`exciseEntity`, `createEntityExcisedHandler`) | `<entityType>.excised`, for example `crm.lead.excised`, validated by euphony's own schema |

euphony reads `empire.entity.excised` as an excision of the entity type `empire.entity`, so it does not call a `createEntityExcisedHandler` for `crm.lead`. A producer that follows the registry docs (for example a Python or Ruby service) sends excisions that euphony apps do not act on.

Until the two agree:

- A Node app publishes with euphony's `exciseEntity`. It sends `<entityType>.excised`.
- A producer in another language sends `<entityType>.excised` too, with the same shape, if euphony apps consume the topic. Say that this differs from the registry docs.
- A consumer that is not euphony handles both forms.
- On a `compacted.<topic>` topic, an excision arrives as a Kafka tombstone (a null value). euphony's `createEntityHandler` handles that in `onExcise`.

The `event-bus` skill covers excision handlers in apps.

## The `empire` subsystem

Empire is the name of Witco's platform architecture: the event schemas, the platform APIs, the event data plane, and the platform stack (Kafka, prosody, euphony). The `empire` subsystem holds platform-wide contracts, not business entities. It owns three things:

- **The excision contract:** `empire.entity.excised`, above.
- **Links** (14.5.0), for the Composition Service. An `empire.link` is a directed link from one entity to another, for example from a Witco `sites.site` to a Real Geeks CRM. Its ID is `<source endpoint>|<target endpoint>`, where an endpoint is `tenant/subTenant/entityType/entityId`. The envelope and the key come from the target endpoint. Events: `empire.link.asserted` and `.retracted`, and the proposals `empire.createLink.*` and `empire.removeLink.*`, all on `witco.empire.link-events`. A link has an optional `role` (14.17.0).
- **Hydrator internals:** `EmpireHydration*` events on `internal.witco.empire.entity-events`, and the `EmpireCompacted*` shape on `compacted.<topic>`. A compacted record keeps the original `type` (for example `crm.lead.asserted`) and adds the full `content`, `previousContent`, `createdAt`, and `source`. Apps read these topics through euphony's `createEntityHandler`; they do not publish them.

## The `identity` subsystem

`identity` (14.14.0 and later) holds people and API keys that Terminus backs. It has assertions and retractions only, no proposals yet.

| Entity | Topic | Content |
| --- | --- | --- |
| `identity.person` | `witco.identity.person-events` | `id` (the Terminus user ID), `subTenantId` (the Terminus deployment), `email` |
| `identity.apiKey` | `witco.identity.api-key-events` | `id`, `subTenantId`, `hash`, `prefix`, `lastFour`, `creatorIpAddress`, `expiresAt`, `permissions` (14.20.0), and `owner` (a person or an organization) |

- The subject of an API key event is its `hash` (sha256, base64url). The key itself is never in an event.
- A retracted API key carries a `reason`: `revoked` or `expired`.
- `identity` is the best small example of a current subsystem. Copy it when you add an entity.
