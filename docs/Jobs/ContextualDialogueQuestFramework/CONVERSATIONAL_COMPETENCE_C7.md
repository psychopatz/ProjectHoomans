# C7 — Conversational Competence and Conversation-First Semantic Lab

**Approved product expansion: PLANNED / NOT IMPLEMENTED.** 2026-10-19 remote source checkpoint `93cbb77498d8d35ded43d3594f59147d71a666e9`. New C7 is not an assertion that current agent tests failed; it is a distinct user-observed product gap. Prior R0A–R5B developer acceptance and its SHA/test ledger are preserved verbatim in `HISTORY_R0_R5B_20261019.md`. The old READY FOR USER LIVE TEST applied to those narrowly exercised flows. This expanded goal is OPEN.

## Observed conversation and real code findings

User's Semantic Lab Simulation screenshot (not an independently rerun worker trace):
- `do you have any news` -> `I haven't heard any news lately.`: recognized GOSSIP and produced a cautious no-news response, but offers no continuation. Do NOT fabricate news.
- `wait here` -> `Okay, I'll stay.` and accepted STAY: existing command pipeline works and must not regress.
- `where do you live exactly` -> `I'm not sure what you mean.`: no verified general NPC residence/settlement fact-question path in inspected current parser; an NPC may have no validated home, so output must express that uncertainty, not invent an address.
- `have you been bitten` -> same generic fallback: Core `BITTEN` concept exists, but inspected `PNC_SemanticCatalog_ConversationPatterns.lua` bite pattern is GOSSIP about a third-party event, not a direct second-person health-status question. Do not infer bitten/unbitten merely from absent field.
- `i like your dress` -> same generic fallback: `PNC_SemanticSocialCatalog_Register.lua` includes `COMPLIMENT_FEATURE` eyes/hair/outfit/smile/voice, not dress; response catalog already has socially appropriate compliment responses. Avoid one-off literal additions as the sole solution.
- Simulation trace defaults to raw JSON with agenda/engineFacts and the "Flow graph" visualizes quest `authorize → request → admitted/rejected/failed` execution, not conversational intent/knowledge/initiative. Preserve this view for command authority, but don't confuse it with an editable dialogue-understanding graph.

Source files/owners to inspect first: `PNC_SemanticCatalog_ConversationPatterns.lua`, `PNC_SemanticCatalog_Concepts.lua`, `PNC_SemanticSocialCatalog_Register.lua`, `PNC_SemanticSocialCatalog_Definitions.lua`, `PNC_SemanticDialogueLocalResponse_Questions.lua`, `PNC_SemanticDialogueLocalResponse_Resolve.lua`, `PNC_SemanticDialogueResponsePlan.lua`, `PNC_SemanticDialogueContextState.lua`, `PNC_SemanticDialogueInput_ContextProjection.lua`, `tools/semantic_harness/gui.py` and the relevant real-worker tests.

## Product contract

An NPC is a **grounded conversational participant** rather than a response-table/command API. It can interpret a family of related conversational expressions, answer from its OWN facts, make socially appropriate acknowledgements, ask relevant follow-up questions sometimes, remember pending questions and topic, and clarify honest unknowns without treating every sentence as an executable command.

Reuse existing Core NLU/IR and Hoomans ContextState/FlowKernel/ResponsePlan/response catalogs. Add reusable *typed* conceptual structures and attribute resolution only where source-backed gaps exist:
`DialogueAct {ASK|INFORM|COMPLIMENT|ACKNOWLEDGE|CLARIFY|OFFER|REFUSE|FOLLOW_UP|TOPIC_SWITCH}`;
`QuestionFrame {speaker,target,subject,requestedAttribute,reference,timeScope}`;
`FactResult {status:known|unknown|ambiguous|unavailable, owner, factRef, value, freshness, provenance}`;
`ResponsePlan {act, groundedFactRefs, uncertainty, audience, responsePool, followUpOpportunity?}`.
These are **design concepts**, not existing runtime APIs. Map into existing Lua types and registration contracts before implementing. Do not implement a second parser, LLM or gameplay dispatcher.

Unknown fact is NOT the same as unrecognized meaning. Parser understands "Were you bitten?" even if real medical owner cannot answer: choose a direct uncertainty-aware medical response, not "I'm not sure what you mean." Do not invent an injury history, residence, inventory, rumor, feeling, item amount or quest state.

Social meaning/response independence: compliments can reference a **semantic category of apparel/accessories/appearance** with conservative lexical aliases grounded in existing clothing definitions; not thousands of hardcoded `I like your dress` patterns. Same for health status and bite-related properties, with explicit subject and question direction. NLU negation, questions vs commands, third-party gossip and quoted/ambiguous statements must stay safe.

Dialogue initiative: where relevant, NPC can acknowledge, respond, and optionally ask a follow-up based on conversational agenda, personality, relationship/trust, needs/danger/interruptions and cooldown; one acknowledgment/request may be generated without a game mutation. Never append automatic follow-up after every response, repeatedly press the player, or initiate commands on behalf of the player. Preserve per-NPC/per-player isolation, bounded turns and allocations. Chat can be multi-turn with PBrainZ entirely off; optional PBrainZ realizes the SAME factual plan and authority.

## First bounded chunk — C7A

1. Inspect local Hoomans/Core HEAD and dirty state; run baseline with exact five user-supplied utterances **in one properly configured real Lua-worker NPC scenario**. Record each selected Core IR/candidates, branch/flow/pattern, knowledge-provider availability, final NPC text and side effects. Also run 2–4 positive/negative paraphrases per failing target. Old unit-test counts are historical, not this baseline.
2. Implement the **smallest reusable recognition+response vertical slice** for two related conversational domains:
   - **Apparel/appearance compliment:** multiple expressions for `dress`, `jacket`/other clothing/appearance terms, a generic supported apparel feature abstraction (or justified equivalent) and already-existing social response pools. Use source-appropriate registered item/appearance facts when referencing actual worn items; a bare compliment can be acknowledged without claiming any clothing fact. Cover negative/quoted/third-person utterances so no false social event.
   - **Direct NPC bite-status medical question:** `Have you been bitten?`, `Did a zombie bite you?`, `Any bites?` etc using generalized target+attribute interpretation (or equivalent) rather than just literal exact matches. Source verified bite/wound status from actual production health/medical provider when available; else return truthful explicit uncertainty. Differentiate third-person `did you hear X got bitten?` gossip and imperatives, and never mutate health.
3. Protect existing `wait here` accepted action, NEWS truthful no-news response, INSULT/THREAT, FOLLOW/GIFT/QUEST, and no unsafe matching from ambiguous language. No fake news, no manufactured NPC home.
4. Worker trace needs parser cause vs missing fact vs response-renderer cause; log and link source of selected response in existing Simulation inspector if trace support missing. Do not rebuild five-pane GUI in C7A.
5. Test EN/TL where supported and do explicit support-gap reporting elsewhere. Use actual Core+Hoomans Lua worker, real final displayed reply, negative cases, no action dispatch and retained known authoritative effects. Run focused and relevant full Lua smoke, compiler/harness tests, `pz_verify`, source/translation syntax, and trace changed artifacts. Record real SHA/tests/failures. A recognized IR by itself is NOT acceptance.
6. If accepted, set exactly one Next Chunk `C7B`; otherwise keep `C7A` open. No native PZ launch or Workshop publication.

## Subsequent ordered phases

- **C7B General fact questions:** Parse subject/predicate/attribute and explicit speaker/addressee for residence/home/settlement, medical state, knowledge, inventory and relationship inquiries; query current registered authority, honor privacy/knowledge/unknown. Demonstrate cross-domain reused question handler, not one handwritten utterance per sentence.
- **C7C Conversation initiative:** Share a typed dialogue-act planner across social/news/needs/medical/quests. Choose when to ask an appropriate follow-up or topic switch based on personality, available facts, pending obligation, danger and cooldown. Prove NPC asks once, answers follow-up, stops at dismissal, no compulsive loops.
- **C7D Context continuity:** Existing bounded ContextState and episodic owner records preserve references, unanswered questions, topic interruptions, commitments, two NPCs/player identities; support "What happened?", "Why?", "And then?", "How many?" when grounded, clarify otherwise.
- **C7E Conversation-first visualization:** Simulation turn-first explanation UI: selected utterance → matching Core candidates/IR → context/typed dialogue act → NPC fact/evidence and uncertainty → reply plan/response text → optionally gameplay authority subflow. Action graph remains separate; click selects highlighted real route, graph/code tied to one canonical definition, no fake editable policy graphs, no sixth standalone app.
- **C7F Dataset-assisted precision:** Expand approved WordNet aliases, reviewed MASSIVE paraphrase/slots, SGD dialogue-state candidates through the embedded CodeBuilder with provenance, licenses, negatives and collision checks. Verify actual worker precision/recall on held-out diverse utterances rather than raw imported record counts; no external corpora/URLs used in PZ runtime.
- **C7G Developer acceptance:** Multi-topic five-plus-turn real Lua dialogues, EN/TL, personality variation, unknown truths, NPC initiative, quest/command isolation, measurable false dispatch (zero on protected set), performance and bounded memory; same tooling with/without optional PBrainZ. Final status READY FOR USER LIVE TEST only after those developer gates; native PZ SP/MP and Workshop user-owned.

## Acceptance evidence and product language

A test report MUST contain source SHA and actual Core revision, scenario/NPC/player ids, utterances and paraphrases, IR/candidate (including negation), fact source/status, chosen dialogue act and response plan, final rendered NPC text and translation, topic/agenda state changes and any authoritative side effects. Do not infer good conversational AI from 218 passing tests or 24 flows. Never promise unrestricted LLM-like spontaneous generative fluency from offline wordlists/intent datasets. Offline intent/grounding/initiative can improve meaningfully, while optional PBrainZ handles flexible free-form realization within shared boundaries.
