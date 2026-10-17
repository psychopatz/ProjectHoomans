# Flow registry and behavioral ownership contract

**Already built:** registry/kernel, bounded active/suspended sessions, preview/commit, identity and wellbeing modules. **Incomplete:** flow authority over response selection and third-module end-to-end extensibility.

## Required behavior
1. Core candidates + Hoomans eligibility choose a valid semantic frame. Mutating or ambiguous fuzzy input is clarified/blocked before response/gameplay action.
2. Flow `Preview` selects a safe registered flow/node/transition with `responsePool`/typed response plan metadata. Its response choice must **drive** production response catalog selection when eligible; no normal reply chosen first by legacy `resolveIntentBranch`.
3. Existing intent policy remains a safe adapter for unhandled/non-migrated interactions and gameplay service requests. Do not inject new global special cases for each future flow. Exactly one response and one authoritative action path per accepted utterance.
4. `Commit` advances state once for a real accepted turn. Two previews are side-effect-free. A flow must not send transport, change trust or auto-schedule tasks.
5. Speakers/addressees have bounded isolated sessions, explicit suspend/resume and scoped refusal. Identity can be interrupted by wellbeing and later resumed; `im fine thanks` must never be treated as a false name.
6. Prove extensibility by adding one harmless third Lua flow, using the existing catalog and (where new prose is needed) existing EN/TL shards. **Do not modify the central intent branch or central resolver just to support that flow.**
7. Existing Semantic Lab GUI must expose the real candidate, flow ID, node transition, selected response pool/template, pending obligation, and outcome; its visual editor must save/register through validated production definitions and allow a new flow to be tested.
8. Response plans may combine typed dialogue acts later, respecting EN/TL grammar, short bounded outputs and actual NPC speech sequencing.

## Engineering sequence
Repair the harness presentation/worker seam first; capture one meaningful existing full-turn identity/wellbeing trace. Wire existing flow metadata into selection behind safety checks; preserve legacy parity and authoritative result adapters. Add third flow and prove its response through Semantic Lab. Then implement real flow inspector/editing and multi-act content. Do not make normal UI testing contingent on user starting Project Zomboid.
