# Contextual Semantic Intelligence — stable architecture proposal

Status: proposed; any detailed API examples are design contracts to validate against the existing source, not claims of implemented modules.

## Intended transformation

Player text -> PsychopatzCore parser -> validated IR -> existing reference/context resolver -> Project Hoomans situation snapshot -> existing dialogue policy plus *minimal needed* reaction arbitration -> existing response catalog/presentation -> optional PBrainZ verbalization OR deterministic response -> existing server-authoritative game action service.

The goal is to separate **semantic recognition**, **behavioral reaction selection** and **surface wording**. Do not create a new arbiter solely to select synonyms already supported by the current response catalog.

## Responsibilities

| Owner | Retained responsibilities | Allowed extension |
| --- | --- | --- |
| PsychopatzCore | Normalize, concepts, grammar, exact/fuzzy matching, confidence, IR version 1, generic dialogue state | Only a demonstrably reusable generic primitive; no PNC-specific needs/relationships |
| Project Hoomans Semantics | Situation projection, dialogue policy, contextual reference resolution, catalog response, bounded conversation obligations | Minimal reaction-selection logic or existing catalog conditions for verified gaps |
| Project Hoomans domains | NPC health/needs, relationship, task, knowledge, inventory, authority | Copied bounded read-only context; changes through public command services |
| MarketSense | Item meaning, classification/capabilities | Never bypassed by lexical expansion |
| PBrainZ | Optional dialogue/text generation, memory retrieval, provider tool normalization | May receive selected reaction read-only; never authoritatively change gameplay |

## Reaction selection rule

Input: validated IR, bounded copied context, existing pending dialogue state. Output: a pure reaction descriptor including existing branch and optional reaction ID, subject/topic, evidence reason, response pool identifier, next follow-up opportunity, and diagnostics. No gameplay effect or persistence in Select/Preview.

Suggested priority classes (only after checking existing policy and preserving its hard gates):

1. Existing safety, permissions, unresolved reference and confidence behavior (never overridden).
2. Already-active conversational obligation with matching speaker/recipient.
3. Immediate danger/urgent actionable NPC state, only with authoritative facts.
4. Question-specific factual disclosure (health, need, activity).
5. Social relationship/personality influence over *tone*, not gameplay facts.
6. Generic response fallback.

Unknown facts are unknown: never infer healthy state, wound cause, familiarity or promised task from missing context. Ties and uncertainty resolve predictably or clarify. Reactions must not route a previously harmless input into a command.

## State / lifecycle

- Reuse `PNC_SemanticDialogueContextState`, Core DialogueState, existing context projections and `PNC_SemanticDialogueReferenceResolver` first.
- Preview is side-effect-free and may be repeated without consuming a pending turn. Accepted turns are recorded once; an actual gameplay outcome must be correlated through the already authorized server response.
- Any newly necessary dialogue obligation uses bounded, session-scoped fields with speaker, addressee, topic, kind and expiry/retirement. Avoid copying the whole transcript or new ModData per NPC.
- Group conversations must use explicit speaker/recipient IDs; one NPC's disclosure cannot become every NPC's memory or obligation.
- Keep an active need/wellbeing disclosure as dialogue state only; it is *not* an automatically scheduled gameplay job.

## Candidate pilot behavior

Player asks "Are you okay?" -> parse QUESTION/WELLBEING -> read source NPC state -> select HEALTHY_ACKNOWLEDGEMENT, NEED_DISCLOSURE, INJURY_DISCLOSURE or UNCERTAIN_CLARIFICATION depending on verified available facts -> existing text pool emits grounded variant. If the NPC disclosed thirst, a follow-up "What's wrong?" refers to that disclosure, not a random previously mentioned entity. "Can I help?" may offer dialogue, but must not enqueue a task unless an existing authorized explicit command exists.

Use the *existing* wellbeing response pool when possible; introduce new reaction IDs/fields only when a behavior transition cannot be represented by existing topic/follow-up/response APIs.

## Compatibility and rollout

- Preserve exported public functions, IR and response payload fields, translation fallbacks, network request/result schemas, authority checks and save compatibility.
- Use existing version-agnostic common content for authored response/translations; runtime Lua belongs in current 42.20 media layer.
- Optional provider must never become a runtime dependency for offline decisions.
- No heavyweight per-frame NPC work. Context assembly is triggered by dialogue/dirty state; benchmark before adding caching.
- Retain small reversible chunks with compatibility adapters only when needed; do not refactor neighboring domains for style.
