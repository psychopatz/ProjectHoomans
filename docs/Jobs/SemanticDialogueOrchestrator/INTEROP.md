# Cross-job integration contract: dialogue × modular translation

This is the **canonical** contract shared by `SemanticDialogueOrchestrator` and `TranslationCatalogModularization`. The translation agent reads this file **read-only** and records compatibility notes in its own PROGRESS; the dialogue agent owns changes to this contract only with coordinated review.

## Stable integration surface
- Dialogue produces **stable response-pool IDs, translation keys and typed placeholder arguments**; translation owns how that key resolves to localized prose.
- Preserve `PNC.Translation.GetKey`, `TrFormat`, `Get` and related established call sites unless both jobs explicitly agree on a migration.
- No flow module hardcodes shard locations, JSON loading or English text alternatives as gameplay routing logic. It may declare semantic response IDs and translation bundle ownership metadata, validated at registration.
- Bundles must be language-agnostic in their manifest paths; English and Tagalog share the same relative paths/keys and compatible placeholder semantics.
- New flows must be executable with old single-file catalogs until the optional multi-file Core reader and corresponding Project Hoomans migration are accepted.
- The translation migration must **not** alter response IDs, selected variant priority, semantic candidate meaning, dialogue network messages or NPC state.
- Neither job may use the other's test result as a substitute for its own production Lua gate. Both use isolated Semantic Lab workers/output directories.
- For shared bootstrap, response catalog, translation manager or core parser edits, agree on which agent owns the current change window and stage cross-repo commits behind reviewed integration branches; never overwrite another agent's live modifications.

## Merge/rollout protocol
1. Land documentation/intent and the small collision containment safely.
2. Translation job lands a backwards-compatible **optional** Core reader feature with dedicated Core tests.
3. Translation job migrates one Hoomans subsystem and demonstrates identical real-worker EN/TL output.
4. Dialogue job registers identity and wellbeing flows against stable lookup APIs (may proceed with old catalogs).
5. Integrate feature branches and rerun cross-job real-worker identity/wellbeing + translation key parity and native SP/MP acceptance separately.

## Contract failure examples
- Two bundles claim the same key; fail registration/load, do not use nondeterministic merge order.
- A chosen response key is missing for TL; explicitly log English fallback, not a silently different semantic reaction.
- A flow preview triggers translation rendering; allowed read-only. It must not mutate flow state or gameplay.
- An identity candidate is rejected but still emits `SemanticIdentityRequest`; fail the dialog gate even if the displayed response appears correct.
