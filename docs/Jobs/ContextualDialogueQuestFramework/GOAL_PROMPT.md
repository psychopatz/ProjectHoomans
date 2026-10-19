/goal
Repository: psychopatz/ProjectHoomans
CONTINUE EXISTING job: docs/Jobs/ContextualDialogueQuestFramework/ — do not create a duplicate job.
Remote design baseline: 263c132ea87678024cd81f8310bb85608dec28df on docs/contextual-dialogue-quest-framework-20261018, PR #4 open/unmerged at audit. FIRST verify actual local Hoomans and PsychopatzCore HEAD/branch/upstream/status, concurrent agent work and non-owned files; never force/reset/stash/ambiguous pull. New docs commit will be the newer planning baseline if present.

APPROVED GOAL — GROUNDED NPC PERSONAL DIALOGUE WITH MINIMAL MODDATA:
Use existing identitySeed + deterministic version-stable backstory definitions to reconstruct immutable personal history; store only sparse genuine exception/delta IDs. Reuse EXISTING server-authoritative PNC_NPCKnowledge descriptors/providers/evidence, familiarity/approval/privacy disclosure, player-character UUID scoping and discovered-only NPC Dossier. NPCs may answer from their own facts, but players learn them only through legitimate disclosure/evidence; familiarity makes a topic eligible, not automatically known. Avoid second biography/Knowledge root, profile paragraphs, every-NPC/full-matrix storage, per-frame backstory work. Optional PBrainZ must receive only disclosure-permitted outward facts and reuse offline dialogue authority.

READ root AGENTS.md, then job AGENT_RUNBOOK.md, README.md, ARCHITECTURE.md, GROUNDED_PERSONAL_DIALOGUE_B.md (current phase), CONVERSATIONAL_COMPETENCE_C7.md (history), ROADMAP.md, CONVERSATION_ACCEPTANCE.md, HARNESS_ACCEPTANCE.md; read Systems/NPCKnowledge.md, Persistence.md, Relationships.md, SocialProfiles.md and real source. PROGRESS.md LAST — exactly ONE current Next Chunk. The former C7A–C7G PROGRESS is preserved verbatim in HISTORY_C7_20261020.md; do not repeat accepted C7 code.

**CURRENT NEXT CHUNK B0 ONLY**:
- Real worker reproduce "nice dress" and "you got nice dress" (expected social compliment; ZERO inventory query), "you got a nice dress" vs "have you got a dress?" and "you got any bandages?" (real explicit inventory questions); include ambiguous "you got a dress", negation/quote/third-person and EN/TL. Trace competing parser candidates, evidence/question cues, selected IR/response pool, final NPC text and SemanticInventoryQuery/tool/side effect counts.
- Repair existing grammar/arbitration with reusable semantic evidence, NOT just exact-string regexes or unbounded synonym expansion. Keep authorized inventory, STAY, INSULT, GIFT, QUEST and Preview behavior unchanged, no false item query/command.
- IN SAME CHUNK make READ-ONLY feasibility proof that existing Memory.GetBackstoryProfile derives stable former_job/hometown from a real seeded NPC record and replays identically with unchanged registered catalog after worker restart. Audit potential weighted-definition/epoch reroll; propose where minimal B1 version/delta would live; do not write a competing backstory store or prematurely implement B1–B6.
- Real Core+Hoomans Lua worker final text/IR/transport, focused+relevant full Lua smoke, harness/compiler, doctor/Kahlua/pz_verify, and exact SHAs/test evidence. Update this job PROGRESS and commit only coherent verified files. Proceed to B1 ONLY when B0 accepted.

Then follow ROADMAP, ONE bounded real-worker chunk at a time:
B1 preserve biography over catalog evolution with epoch or stable definition-ID pinning and only genuine sparse overrides;
B2 reuse seeded backstories through authoritative read-only DialogueFacts/Knowledge provider, distinguish hometown from CURRENT residence/health;
B3 descriptor-based gradual familiarity/approval/privacy/disclosure and evidence with no threshold auto-unlock, no forced NPC secrets;
B4 show ONLY authorized discoveries in existing Dossier history category, suspected/confirmed and MP two-player isolation;
B5 multi-turn personal conversation, willingness/refusal/topic resume, personality, limited initiative, shared PBrainZ outbound disclosure filter;
B6 benchmark serialized ModData for 0/1/10 discoveries, lazy reconstruction/no all-NPC tick scans, generator revision/reload, EN/TL, MP privacy and full acceptance.

Use existing CodeBuilder/Semantic Lab and PsychopatzCore IR, Hoomans ContextState/ResponsePlan, server Quest/Knowledge/Relationship authorities and project persistence owner. Do not invent personal history, clone full profiles, send unrevealed facts to clients/LLM, create a new parser, bypass conversation leases or gameplay admission, or use full source corpora at PZ runtime. Native Project Zomboid SP/MP, server hosting, Steam Workshop install/publish/republication are USER-OWNED; never run or block development on them. Codex CLI native CUA apps=[] not a blocker: real Lua worker and X11/Tk if available. Keep one real Next Chunk and continue autonomously to developer READY FOR USER LIVE TEST or actual technical/authorization blocker.
