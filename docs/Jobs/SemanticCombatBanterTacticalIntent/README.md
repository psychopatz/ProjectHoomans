# Semantic Combat Banter & Tactical Intent

This job turns the accepted combat-awareness foundation into active co-op gameplay banter.

## Product target

NPC combat dialogue should feel like characters acting inside the fight:

- followers can notice a dangerous horde and ask whether the team should engage, avoid, or hold;
- the player can answer by semantic choice, typed equivalent, or simply acting;
- NPCs react to the team decision while continuing gameplay;
- combat barks are autonomous and usually non-interactive;
- kill commentary can use the actual weapon family, combat skill, body-part/outcome and current pressure when grounded;
- zombie and hostile-human kills have distinct semantic treatment;
- personality, traits, relationship, panic/stress and confidence affect tone/profanity without deterministic stereotypes;
- silence is a normal outcome so combat does not become chatter spam.

## Architecture rule

Do not add a chatbot beside combat.

Reuse the existing Perception/ZombieObservation, companion behavior, CombatResolution/AttackExecution, Equipment/Skills, semantic lifecycle, suggestion/click frames, SpeechRealization and CodeBuilder authorities.

Combat presentation is explicitly classified as:
- `BARK` — autonomous, non-blocking, no response required;
- `TACTICAL_PROMPT` — a real short-lived team decision with semantic offers;
- intentional terminal response.

See:
- `AUDIT.md` — current live/product failures;
- `ARCHITECTURE.md` — ownership and invariants;
- `ROADMAP.md` — mandatory B0–B9 implementation sequence;
- `HARNESS_ACCEPTANCE.md` — acceptance matrices;
- `AGENT_RUNBOOK.md` — execution rules;
- `PROGRESS.md` — current truth and immediate Next Chunk.

## Current state

Planning base is ProjectHoomans `8632bc30` on existing `main`.

Implementation has not started. Begin with B0A in `PROGRESS.md`: establish production-grounded regression contracts before modifying horde, banter, weapon commentary, or UI behavior.

Native SP/MP feel validation remains user-owned unless explicitly reassigned.
