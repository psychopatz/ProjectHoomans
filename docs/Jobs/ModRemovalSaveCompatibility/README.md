# Mod Removal & Save Compatibility — Project Hoomans

**Status:** PLANNED. Documentation and read-only reference-save audit only; runtime defect is not yet diagnosed.
**Primary repository:** ProjectHoomans.
**Participants, conditional on evidence:** psychopatzCore and DynamicTrading (including enabled DTCommon, MarketSense and DTHoomans integrations); verify actual ownership before editing them.
**Reference:** Apocalypse save 2026-11-20_07-12-33, world version 251, under ~/Zomboid/Saves/Apocalypse/. Never check save binaries into Git.

## Parent objective

A character who has used Project Hoomans must remain playable after the mod is disabled, with vanilla carrying capacity, stats, traits, physical inventory and equipment behaving correctly. In particular, diagnose the user's reported maximum carry capacity of 8 in the reference save, establish the real cause, fix any verified mod-owned defect at the proper owner, and prevent regressions on enable/save/disable/reload/re-enable in SP and relevant MP flows.

A surviving ModData namespace by itself is not a defect. The critical criterion is whether it still affects vanilla runtime or creates invalid ownership after the mod is absent. Diagnose before implementing, and do not blindly reset character capacity to a guessed value.

## Documents

- AUDIT.md: verified baseline, hypotheses and limitations.
- ROADMAP.md: complete objective, phases and acceptance gates.
- PROGRESS.md: active truth and single immediate Next Chunk.
- AGENT_RUNBOOK.md: safe save/repository procedure.
- HANDOFF.md: current reproducible checkpoint.

The conversational /goal is not stored in Git. Keep root AGENTS.md untouched unless a genuinely durable repository-wide rule changes.

## Non-goals

No automatic global ModData purge, destructive save edits, forced default strength/carry value, compatibility shim duplication, or broad redesign of the existing NPC inventory authority. No claim that the mod caused the symptom without a reproduced causal trace.
