# Upgrade from 12.x to 14.x: renames and breaking changes

From 12.83.0 to 14.22.0 the registry grew from 209 to 328 event types. The two major versions changed little on the wire. Most wire-breaking changes shipped as **minor or patch** releases, so do not trust semver: read this list for every app that moves from 12 to 14.

Legend: **[minor]** and **[patch]** mark wire-breaking changes that shipped in a minor or patch release.

## Upgrade steps for an app

1. Point the `@cincpro` scope at CodeArtifact. GitHub Packages stops at 14.19.0, and 14.20.0 and later are only on CodeArtifact. Do not print a registry token into the transcript; use a wrapper that keeps it in a file.
2. Bump `@cincpro/event-schemas` straight to the latest 14.x. Skip 14.0.0 to 14.12.x: those versions changed the enum exports twice (see [Code changes](#code-changes)).
3. Bump euphony in the same change. euphony re-exports event-schemas, and euphony 14.5 depends on `@cincpro/event-schemas ^14.9.1`.
4. Replace every `website` name in the app: topics, event types, entity types, class names, and `data.subsystem` checks. See [The `website` → `sites` rename](#the-website--sites-rename).
5. Check the app against the other renames below.
6. Add excision handling for every entity the app stores. In euphony that is `createEntityExcisedHandler` (see the `event-bus` skill and [empire-excision.md](empire-excision.md)).
7. Make sure that `switch` statements on `category` or `type` do not fail on the new `excision` category.

## The `website` → `sites` rename

**[minor] 12.86.0 (#702).** The subsystem `website` became `sites`. This changed:

- `data.subsystem`, from `"website"` to `"sites"`;
- the prefix of all 44 event types (`website.<entity>.asserted` → `sites.<entity>.asserted`) and of the 22 entity types;
- the TypeSpec namespace and the generated class names (`Website*` → `Sites*`). 13.2.0 also added a `Sites` prefix to models that had none: `Site` → `SitesSite`, `Consumer` → `SitesConsumer`, `SiteReference` → `SitesSiteReference`.

Topics:

| Old topic | New topic |
| --- | --- |
| `witco.website.admin-events` | `witco.sites.admin-events` |
| `witco.website.client-events` | `witco.sites.client-events` |
| `witco.website.consumer-events` | `witco.sites.consumer-events` |
| `witco.website.site-events` | `witco.sites.site-events` |
| `witco.website.email-generation-priority-events` | `witco.sites.email-generation-priority-events` |
| `witco.website.email-generation-regular-events` | `witco.sites.email-generation-regular-events` |
| `witco.website.email-send-priority-events` | `witco.sites.email-send-priority-events` |
| `witco.website.email-send-regular-events` | `witco.sites.email-send-regular-events` |

A consumer of the old topic gets nothing after the producer upgrades. Producers and consumers must move together, or consume both topics during the move.

## Other topic changes

| Change | Version |
| --- | --- |
| `comms.phoneDnc.*` moved from `witco.solaris.internal-events` to `internal.witco.solaris.phone-events` | **[patch]** 13.2.1 |
| `nurtureEngine.refreshSummary.*` moved from `squire.lead-events` to `witco.lead-events` | **[patch]** 13.3.1 |

Only apps pinned between 12.84 and 14.x need these:

- `witco.propertydata.standardfield-events` → `witco.propertydata.standard-field-events` (12.86.1).
- `witco.solaris.voice-internal-events` → `internal.witco.solaris.voice-events` (13.3.2).

## Event and entity type changes

| Change | Version |
| --- | --- |
| `comms.phoneConsent.asserted` and `.retracted` removed (never used; not in the changelog) | **[minor]** 13.9.0 |
| `crm.fromLeadEmail.asserted`: entity type `crm.email` → `crm.fromLeadEmail` | **[patch]** 14.9.2 |
| `crm.toLeadEmail.asserted`: entity type `crm.email` → `crm.toLeadEmail` | **[patch]** 14.9.2 |
| `comms.phoneDnc.*`: entity type `comms.phone` → `comms.phoneDnc` | **[patch]** 14.9.2 |
| `mls.listing.*` got the entity type `mls.listing` | 14.9.0 |

The two email entities each also got a `.retracted` event in 14.9.2.

Only apps pinned between 13.2 and 14.9 need these:

- `comms.callRecording.*` and `comms.callTranscription.*` became `comms.call.*` **[minor]** 14.10.0.
- `crm.email.retracted` existed in 14.9.0 only.
- The 80 `<sub>.<entity>.excised` types existed in 14.9.0 only.

## Field and key changes

| Change | Version |
| --- | --- |
| `comms.createAccount.*`: the subject and sub-tenant now come from `content.proposalId`, so the Kafka key changed | **[minor]** 12.84.0 |
| `comms.submitPhoneConsent.*`: `phoneNumber` is a plain string, and the subject path is `phoneNumber` (was `phoneNumber.number`) | **[minor]** 12.84.0 |
| `CRM.owner` is `AgentReference \| null` (TypeScript type only) | 14.5.2 |
| `propertyData.materializedListingAccountField`: `searchFilterConfiguration` replaced by `searchFilterConfigurationUuid`; `displayName`, `filterType`, and others removed | **[minor]** 14.15.0 |

No other field on a model that existed at 12.83.0 was renamed or removed.

## Code changes

These change generated code, not the wire:

- **13.0.0 (C# only):** datetimes serialize with a `Z` suffix instead of `+00:00`.
- **14.0.0 (TypeScript):** the root export changed to native `enum`s, so plain strings no longer fit enum-typed fields. **14.13.0 reverted this**: the root exports string-literal unions again, as in 12.x. Enum values moved to subpaths: `@cincpro/event-schemas/enumObjects` (`as const` objects; use this one) and `@cincpro/event-schemas/enums` (native enums). An app on 14.0 to 14.12 that imports enum values from the root must switch to a subpath. From 12.x straight to 14.13 or later, nothing changes for the root import.
- **Renamed classes:** `PhoneNumber` → `PhoneConsent` and `InternalPhone` → `PhoneDNC` (13.9.0); `CRMEmailEntity` → `CRMFromLeadEmailEntity` and `CRMToLeadEmailEntity` (14.9.2); the `CommsPhoneNumber` scalar removed (12.84.0).
- **Python, Ruby, and C#** left Gemfury and GitHub Packages for CodeArtifact at 14.20.0.

## Recheck this list

The list comes from a diff of the event types, topics, and entity types between the tags. To check a newer range, parse `events/**/*.tsp` at both tags for each model's `type:` literal, `@canonicalTopic`, and `@entityType`, then compare the two sets. The event-schemas `CHANGELOG.md` names each change, but it does not mark which ones break the wire.
