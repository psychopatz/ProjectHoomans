# Semantic dialogue decoupling — implemented architecture and target

## Current production path (verified in source)
Input -> Core parser/candidates -> Hoomans contextual eligibility -> legacy `resolveIntentBranch` response decision **plus** separate flow preview -> `LocalResponse.Resolve(branch)` -> `ResponsePlan.Attach(alreadyChosenResponse)` -> existing text/translation/presentation and server-authoritative effects -> flow commit. The bounded flow kernel exists, but does **not yet** fully select displayed replies.

## Target
Input -> compatible Core NLU/typed candidates -> safety + eligibility -> **registered flow controls conversational reaction/response pool and next node** -> existing conditioned response catalog -> typed multi-act EN/TL realization where needed -> actual existing NPC UI/speech queue. Unmigrated legacy action paths remain behind strict server authority. Only accepted player turns advance bounded flow sessions once.

## Ownership
- PsychopatzCore owns generic parser/candidate/router contracts and translation manifest reader. Its GitHub main now has the APIs; check local files before edits.
- Hoomans owns flow policy/registry/kernel, NPC situation, response selection, presentation, localization shard registrations and domain request preparation.
- MarketSense owns item classification; PBrainZ remains optional and must never decide server-authoritative effects.
- Existing authored conversation bundles and native PZ Translate files remain separate; current 12 EN/TL Conversation shards are retained.

## Acceptance rules
- No new custom parser/Jess system, competing response pools, repeated JSON-only fixtures or giant one-file dialogue monolith.
- Flow response selections must **actually** override/furnish the displayed production reply through the existing supported route, not merely decorate diagnostics. One chosen response, no duplicate flow+legacy messages.
- User identity/wellbeing collision fix remains intact; unrelated statements cannot incur name-evasion penalties.
- Fuzzy commands, identity, inventory, trust, multiplayer and tasks remain validated by existing authoritative game services.
- Preview is pure, submit commits once, sessions bounded per speaker/addressee and interruption/resumption safe.
- Localized multi-act responses use grammar-safe authored EN/TL template keys, not concatenated random phrases.
- Semantic Lab GUI and worker use the SAME production registry and decision trace. A graph/editor must edit/validate the actual flow definition contract; never create a parallel JSON-only interpreter.
- Harness-guided implementation comes first; the user performs the final live-game test after handoff.
