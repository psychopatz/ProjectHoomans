# Factions contracts under review

Authoritative entry: `server/PNC/Factions/PNC_FactionService.lua`.
Factions owns its registry, affiliation/treaty schema, admission and symmetric
relation commit. Incident, tactical behavior and toll applications retain their
existing public entries. Communities/player-key helper access remains open work.

## Committed treaty facts

Public data-only entry: `shared/PNC/Core/Factions/PNC_FactionEvents.lua`.

`TREATY_CHANGED(firstID, secondID, incidentType, relationSnapshot, worldAgeHours)`
announces a successful treaty commit after relation/faction/registry revisions
and reconciliation. Failed, unauthorized and unchanged requests announce nothing.
The relation snapshot is detached from canonical mutable faction state.

WorldKnowledge subscribes through the existing Core event bus. It no longer
reads or replaces `Factions.Internal.mutateTreaty`. Publication retains the same
IDs, incident type, relation snapshot and supplied world-age value. Observer
errors remain isolated from the mutation result. The subscription is installed
once per adapter, under the existing server-role and installation guards.

This event is process-local and server-authoritative; it changes no wire command
or saved schema. Core owns the reusable bus, Factions owns the fact's meaning,
and Knowledge owns its publication/dissemination. No new event mechanism,
gameplay state store or per-frame work is introduced.

The public fact contract supports independent observer retrieval. The reviewed
Knowledge handoff set keeps two files while replacing the private treaty
implementation with the public fact declaration; exact bytes/lines and scope
are in `P7E_KNOWLEDGE_RETRIEVAL.json`. The fixed seven-probe aggregate remains
separate. `P7E_FACTION_FACTS_PROOF.json` records behavioral and source evidence.
