# Contextual Dialogue & Quest Framework — Current Progress

**Updated:** 2026-10-21
**Parent goal:** IN PROGRESS — complete V1–V5 on the existing `main` branch
**Documentation baseline:** `556bdd7a57a7`
**Repository rule:** no branch was created; native Project Zomboid SP/MP, live servers, installation, and Workshop publishing remain user-owned.

## Preserved foundation

B0–B6, H0–H4, and F1–F4 remain the preserved implementation baseline. The work continues through the existing Semantic Lab, `semantic.interaction_spec.v1`, CodeBuilder, Core-backed translation path, server-authoritative Knowledge/Dossier services, Lua worker, and Conversation Inspector. The historical F1–F4 ledger is evidence, not a replacement for the V1–V5 requirements.

## V1 — reusable visual CodeBlocks graph

**Status:** implemented and developer-verified. Commit: `c1913c9c`.

The existing Studio workflow now supports typed graph add/remove/configure/connect/disconnect operations for both backstory and registered capability interactions. It retains legacy `semantic.codeblocks.v1` action-flow compatibility, validates ports/cycles/orphans, keeps preview effect-free, requires explicit generation approval, and attaches deterministic graph metadata to the existing compiler output.

Evidence:

- Focused Python suite: 33 tests passed.
- Real Core+Hoomans Lua worker proof: the same visual service generated distinct backstory and registered `FOLLOW` assets; the worker returned `I worked as farmer before all this.` and `Okay, I will follow you for V1.`.
- GUI construction under Xvfb: exit 0; graph edit smoke: exit 0, 4 blocks and 3 connections.
- Generated EN/TL assets were deterministic and written only to the established mod asset directories.

## V2 — Core-backed localization

**Status:** existing implementation verified; final authored EN/TL acceptance evidence remains part of V5.

The existing `PsychopatzCustomTranslationManager`, `PNC.Translation`, registered catalogs/manifests, and legacy TextLoader compatibility remain the only localization path. Existing worker tests cover complete EN/TL sentences, dynamic `farmer` → `magsasaka` substitution, fallback diagnostics, language switching, and player-scoped privacy.

## V3 — personality-aware Knowledge disclosure

**Status:** implemented and developer-verified. Commit: `8adfe968`.

The existing Knowledge owner now evaluates topic alignment and private/personal disclosure willingness using the registered NPC personality/social style plus existing familiarity and approval. Familiarity remains eligibility only; guarded styles do not reveal facts without the stronger relationship context. Discovery, backstory preview/disclosure, and the semantic backstory fact provider pass the same topic context. No duplicate Knowledge service or per-NPC ModData was introduced.

Evidence:

- Real worker H3 suite: 5 tests passed. At familiarity 40, friendly disclosure produces the canonical English sentence and player dossier; withdrawn disclosure produces the refusal and no dossier.
- Lua smoke: `pnc_backstory_knowledge_disclosure_smoke`, 1/1 passed for friendly, guarded, and topic-mismatch cases.
- PZ Kahlua verification: 0 errors across the changed Knowledge directory and backstory fact-source file.

## V4 — persistence and Conversation Inspector

**Status:** implemented and developer-verified in the existing worker/inspector path; commit pending this progress update.

The existing `KNOWLEDGE_METRICS` worker command now serializes the complete canonical NPC record, backstory metadata, player-scoped Knowledge registry, and combined actor/Knowledge payload with the production Core deep-copy behavior. It preserves the legacy Knowledge byte field and reports the persisted ModData snapshot separately. The existing Conversation Inspector now projects a bounded readable acceptance chain: utterance, selected CodeBlock/graph fingerprint and edges, Core meaning, fact provider, Knowledge permission, translation lookups, actual NPC response, gameplay effects, and dossier delta. Generated semantic patterns now retain the existing graph metadata through the production catalog and worker observation.

Evidence:

- H4 worker suite: 3 tests passed, including legitimate 0/1/10 discovery comparisons and synthetic 100/1,000 NPC populations.
- Measured canonical worker records: 0 discoveries `actor=1002`, `backstory=0`, `knowledge=0`, `combined=1010` bytes; 1 discovery `actor=1608`, `backstory=593`, `knowledge=751`, `combined=2386`; 10 discoveries `actor=1623`, `backstory=593`, `knowledge=4887`, `combined=6537`; synthetic 1000/1 `knowledge=467754`, `combined=468783`, `npcCount=1000`.
- Conversation Inspector and V1 worker graph-provenance tests passed; graph metadata remains bounded and raw JSON remains an advanced diagnostic rather than the primary chain.
- Production-copy behavior was aligned with the native Core deep-copy implementation so the worker's diagnostic response bound cannot truncate persistence measurements.

## Remaining mandatory chunk

- V5: run the complete Studio approval → generated assets → worker restart → conversation → Knowledge/Dossier/multiplayer privacy → regeneration behavior-change acceptance, then run focused/full developer checks and record exact SHAs, commands, exit codes, generated paths, responses, effects, and persistence measurements.

`GOAL_PROMPT.md` was not created or modified.
