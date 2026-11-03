# Roadmap — Core Semantic & Relationship Foundation

**Status:** READY FOR USER LIVE TEST — developer-owned P0-P20 complete.

The roadmap is closed for implementation. No P21 is planned. Reopen only if native acceptance or a concrete regression demonstrates a developer-side defect.

## Completed phase map

### P0-P7 — Foundation and first convergence pass

Established the cross-repository ownership model and initial implementation:

- convergence audit and public contracts;
- Core canonical shared relationship authority;
- generic Core semantic/conversation foundation;
- standalone Dynamic Trading semantic/story pack;
- Project Hoomans additive adoption;
- cross-adopter capability/boundary isolation;
- initial hot-plug/save migration acceptance.

Independent audits found gaps in the first closeout; those gaps were repaired by later phases rather than by creating competing authorities.

### P8-P12 — Shared identity, relationship integrity, and real adopter integration

Completed:

- one canonical Core player social target-key contract;
- non-destructive Core-first relationship mutation/merge;
- foreign adopter extension and memory preservation;
- complete semantic-pack ownership/unregister behavior;
- repaired Hoomans Core semantic schema and production adoption;
- fuller standalone DT identity/whereabouts/story coverage;
- production cross-adopter hot-plug matrix replacing synthetic-only serialization claims.

### P13-P17 — Production-boundary hardening

Completed:

- real DT-first -> Hoomans identity adoption;
- production `ActorConversationService` capability isolation;
- complete required DT utterance coverage;
- evidence-grounded route/news behavior;
- Core authoritative player-identity issuance/adoption state;
- canonical DT home/current/origin/destination policy;
- TalkService consumption of canonical factual state;
- bounded uncertainty when factual evidence is unavailable.

### P18-P20 — Final authority, travel, presentation, and persistence closure

Completed and independently reverified:

- unknown `PNC_CharacterUUID` mirrors cannot bootstrap Core identity authority;
- legitimate Hoomans-first identity registration originates from validated Hoomans identity authority;
- resident excursion lifecycle projects PREPARING/OUTBOUND/VISITING/RETURNING_HOME/AT_HOME into canonical DT travel state;
- canonical settlement/community IDs resolve to human-facing names without leaking machine IDs;
- FAILED excursion semantics use numeric timestamp meaning, including `departedAt > 0, completedAt = 0`;
- failure before departure, after departure, while visiting, while returning, and retry behavior are regression-tested;
- reconstructed persistence deep-copies the persisted storage representation into a fresh backing table;
- reloaded trader records are distinct Lua objects while preserving canonical state;
- WorldKnowledge `Save/Load` restores fact/evidence data;
- completed and failed travel states remain coherent after reconstructed reload.

## Final developer completion gates

All mandatory developer gates are accepted:

- canonical actor/player identity and shared relationship truth;
- non-destructive cross-adopter social mutation;
- residue-free semantic-pack lifecycle;
- production capability isolation;
- standalone Dynamic Trading semantics without Hoomans dependency;
- working Hoomans additive adoption;
- production hot-plug/remove/re-add behavior;
- factual DT travel/settlement/news grounding and presentation;
- failure-state correctness;
- reconstructed persistence evidence;
- bounded runtime work;
- focused/full regression baselines and static checks.

## Native user-owned handoff

Developer completion does **not** claim native Project Zomboid acceptance.

User-owned live validation should cover representative:

- SP Core + DT;
- MP Core + DT;
- combined DT + Hoomans;
- DT-first -> add/remove/re-add Hoomans;
- Hoomans-first -> add/remove/re-add DT;
- excursion departure/visit/return/failure/retry;
- human-readable settlement/location dialogue;
- persistence across real Project Zomboid restarts;
- UI/dialogue quality and real multiplayer lifecycle behavior.

If native testing finds a concrete developer defect, reopen this roadmap from that evidence. Otherwise the job remains implementation-complete.
