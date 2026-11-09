# Knowledge-gated hover and semantic conversation audit

## Contract
Known non-colonist actors may show hover cards. Unknown actors never show cards, including in debug mode. PsychopatzCore owns shared hover/presentation; Hoomans supplies player-specific learned identity; DTAbstract uses the same Core presentation with its discovery adapter. Debug route/geography visibility must not grant identity knowledge. Preserve the existing bounded map caches and journey projection.

## Findings and plan
1. Remove the previous debug hover bypass (the previous SharedActorMapParity interpretation was incorrect). Resolve player knowledge before stale actor projection flags; fail closed when knowledge is unavailable. Keep the 250 ms knowledge cache.
2. Preserve canonical/generated identity claim modes through the client transport. The canonical choice deliberately omits a literal name, but the old client dropped its mode; server admission then rejected it as identity_claim_missing. Add a client-to-server regression for SP and MP and retain server lease validation.
3. Propagate synchronous SP admission failures. The old common dispatch helper treated a false server return as a successful dispatch, leaving the dialogue pending.
4. Preserve the currently dispatched native choice as bounded presentation evidence. Core clears session.choices before running its action; Hoomans subsequently rejected category/topic frames as suggestion_not_presented. Keep stale, duplicate and disabled checks.
5. Fix cold-load suggestion ownership: PNC_Identity publishes PNC.Identity without returning a module table; Suggestions_Core must read the namespace after requiring it. The fuller local-route test reproduced a boolean-index failure in BuildBackFrame before this fix. Check name questions and What's up through deterministic routing and native click seams; verify rejection recovery, not just parser output. Do not change truthful-name requirements or grant knowledge on the client.
6. Run focused regressions, the complete Hoomans suite, affected Core/DT map tests, and Kahlua verification. Record results below.

## Evidence limits
Graph discovery used the Nov 5 indexes; current source was read for changed/stale paths. Latest available console capture is Nov 7 03:55 and contains startup diagnostics, not a trace of the reported conversation click. It reports a conversation translation manifest registration diagnostic; this alone does not identify the failed dialogue request. Native SP/MP behavior remains a user-run confirmation gate.

## Implementation and regression evidence
- Shared hover now reads player knowledge before marker flags, fails closed without knowledge, and never checks debug permission to grant a card. Learned facts take priority over stale pending presentation state. Canonical actorID is used when resolving Hoomans names/factions.
- Core no longer treats an absent discovery entry for a group/community actor as learned identity; unavailable registered knowledge adapters cannot fall back to raw actor names. Debug help text matches this policy in EN/TL.
- Client identity requests retain claimMode/responseStyle; SP false returns propagate and clear the pending request. Canonical names still resolve from the authenticated player on the server, and invalid conversation leases still fail.
- Native row dispatch supplies exact-frame presentation evidence only during its synchronous callback. Disabled rows cannot enter that scope; stale/duplicate checks remain in force.
- Suggestions require the identity module for its namespace side effect, then read PNC.Identity. The actual local parser, suggestion shortcut and response queue now cover name questions and What's up with no LLM.

The canonical client-to-server regression failed before the fix (no new disclosure). The actual Core Session.selectChoice regression failed before the fix (no routed topic click). Expanded local routing exposed the cold-load boolean-index exception. All now pass. A real server-result/client-knowledge receiver test also checks learned non-colonist map hover, stale flags, canonical actor ID and unknown rejection in debug.

## Verification
- Hoomans full Lua suite: **1009/1009 passed**.
- Core related map/world/portrait/projection tests: **22/22 passed**, including bounded repeated-frame cache assertions and journey parity.
- Kahlua verifier: **9 changed runtime files passed**.
- DynamicTrading map/host/presentation regressions: **5/5 passed**.
- No native game session was driven; no save or discovery grants were applied. Existing unrelated working-tree edits were preserved.

## Native confirmation checklist
1. Restart with the updated local Core and Hoomans scripts. In SP, click What's up and ask an unknown non-colonist's name; complete the truthful introduction. Verify one reply per turn and that the name fact enables its map card without reopening the map.
2. With debug inspection both off and on, verify another unknown actor cannot show a card. Known travelling Hoomans and DTAbstract actors should retain movement and route display; compare smoothness with the earlier cache fix.
3. Repeat introductions in MP with two players: one player's knowledge must not reveal identity to the other. An expired conversation lease must reject cleanly without stuck input.
4. If a live click still fails, capture that click's semantic request/rejection event. The available startup-only console cannot prove which reported UI action failed; the translation-manifest diagnostic is separate and is not treated as proof of a dialogue-request failure.
