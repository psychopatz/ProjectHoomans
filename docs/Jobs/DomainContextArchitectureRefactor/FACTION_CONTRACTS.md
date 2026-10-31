# Factions contracts under review

Authoritative entry: `server/PNC/Factions/PNC_FactionService.lua`.
Factions owns its registry, affiliation/treaty schema, admission and symmetric
relation commit. Incident, tactical behavior and toll applications retain their
existing public entries.

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

## Aggregate and shape cooperation

`Factions.Repository.GetRecord` loads and returns the canonical faction aggregate
for trusted authoritative child-domain writers. Communities owns excursion work;
`Repository.MarkChanged` retains the exact parent faction/registry revision and
dirty marking sequence. `Repository.IsAuthority` shares the existing predicate.
UI/read-only consumers retain the existing detached Get/List query contracts.

`Factions.FindPlayerKey` performs the existing non-creating identity lookup.
Colonist departure retains its primary identity lookup and external callback
error fence. FactionTypes publicly exposes its pure NormalizeTargetPoint and
NormalizeExcursion functions; schema implementation bodies are unchanged.
Foreign Factions.Internal and FactionTypes.Internal access is now guarded.

P7F retains one registry and existing unavailable-capability fallbacks. There is
no new persistence, authority, event or scheduling mechanism. See
`P7F_FACTION_REPOSITORY_PROOF.json` and `P7F_MCP_PROOF.json`, including the graph's
Travel alias false positives and indirect colonist-call limitation.
