# Catalog: subsystems and topics

The topic of an event always comes from its `@canonicalTopic` (`EventClass.TOPIC` in Node). Topics are not one per subsystem: `witco.lead-events` carries events from `crm` and from `nurtureEngine`. Never hard-code a topic string in an app.

The counts below go stale with each release. Recount them before you quote a number.

## Recount

Run this from the root of the `event-schemas` repo (bash or zsh, macOS or Linux):

```sh
echo "event types: $(grep -rhoE '^ {0,4}type: "[^"]+"' events --include='*.tsp' | sort -u | wc -l)"
echo "topics:      $(grep -rhozE '"@canonicalTopic",\s*"[^"]+"' events --include='*.tsp' \
  | tr '\0' '\n' | grep -oE '"[^"]+"$' | sort -u | wc -l)"
echo "subsystems:  $(grep -rhoE 'subsystem: "[^"]+"' events/subsystems --include='*.tsp' \
  | cut -d'"' -f2 | sort -u | paste -sd' ' -)"
```

The topic count needs `grep -z`, because some `@canonicalTopic` decorators wrap onto a second line. A plain line grep misses them.

At 14.22.0 the output is 328 event types, 40 topics, and 12 subsystems:

```
comms corporateCRM crm domain doNotCall empire identity mls nurtureEngine propertyData sites sms
```

The 328 include 19 legacy `realgeeks.accounts.*` events (no topic) and 9 `prosody` telemetry events. Neither group is part of the 12 subsystems.

To find the topic of one event, open its file, `events/subsystems/<sub>/<event type>.tsp`, and read `@canonicalTopic`. Or search for it:

```sh
grep -rl 'type: "crm.lead.asserted"' events | xargs grep -A1 '@canonicalTopic'
```

## Topics at 14.22.0

| Topic | Subsystems (event types) |
| --- | --- |
| `witco.lead-events` | crm (35), nurtureEngine (35) |
| `witco.crm-events` | crm (2) |
| `witco.agent-events` | crm (2) |
| `realgeeks.lead-manager.crm-events` | crm (4) |
| `squire.lead-events` | nurtureEngine (15) |
| `squire.agent-events` | nurtureEngine (3) |
| `squire.crm-events` | nurtureEngine (3) |
| `witco.comms.account-events` | comms (2) |
| `witco.comms.phone-events` | comms (5) |
| `witco.comms.management` | comms (3) |
| `internal.witco.solaris.phone-events` | comms (2) |
| `internal.witco.solaris.voice-events` | comms (2) |
| `witco.corporate-crm.call-events` | corporateCRM (2) |
| `witco.domain.account-events` | domain (26) |
| `witco.donotcall-events` | doNotCall (2) |
| `witco.donotcall-synthesized-events` | doNotCall (2) |
| `witco.empire.link-events` | empire (8) |
| `internal.witco.empire.entity-events` | empire (hydrator internals) |
| `witco.identity.person-events` | identity (2) |
| `witco.identity.api-key-events` | identity (2) |
| `witco.listing-events` | mls (2) |
| `witco.propertydata.field-events` | propertyData (41) |
| `witco.propertydata.field-group-events` | propertyData (11) |
| `witco.propertydata.listing-account-events` | propertyData (13) |
| `witco.propertydata.materialized-field-events` | propertyData (2) |
| `witco.propertydata.mls-events` | propertyData (2) |
| `witco.propertydata.profile-events` | propertyData (8) |
| `witco.propertydata.search-filter-configuration-events` | propertyData (11) |
| `witco.propertydata.standard-field-events` | propertyData (2) |
| `witco.sites.admin-events` | sites (2) |
| `witco.sites.client-events` | sites (2) |
| `witco.sites.consumer-events` | sites (20) |
| `witco.sites.site-events` | sites (6) |
| `witco.sites.management` | sites (3) |
| `witco.sites.email-generation-priority-events` | sites (4) |
| `witco.sites.email-generation-regular-events` | sites (4) |
| `witco.sites.email-send-priority-events` | sites (2) |
| `witco.sites.email-send-regular-events` | sites (2) |
| `witco.sms-events` | sms (5) |
| `prosody.telemetry-events` | prosody telemetry (9) |

`empire.entity.excised` has no topic. The owner publishes it on the topic of the excised entity (see [empire-excision.md](empire-excision.md)).

## Compacted topics

The hydrator mirrors 15 value-delta topics to `compacted.<topic>` (for example `compacted.witco.lead-events`). There the key subject is `<entityType>:<entityId>`, and each record holds the current state of one entity. The list is in `data_warehouse/topics.yaml`. euphony's `createEntityHandler` reads these topics; check that the compacted topic exists before an app relies on it.

## Browse

The rendered docs for every event are at https://event-schemas.witco.net/.
