# Roadmap — Coherent Emergent Conversation

**Parent status:** IN PROGRESS.

The completed R0–R9 recovery is accepted foundation and is intentionally not repeated here. Git history contains that implementation record.

The remaining developer objective is C0–C8.

## C0 — failure corpus, ownership audit and baselines

Build a compact checked-in regression corpus around the actual production worker.

Cover at minimum:

- exact, typo, missing-space and elongated forms;
- profanity used toward NPC / self / world;
- insult vs hostile remark vs threat;
- negation and intensification;
- context-dependent short replies;
- ambiguous references;
- benign false-positive controls;
- mutating-action negative controls.

Required explicit cases include:

`fuckyou`, `fuckyouuuu`, `shutthefuckup`, `youidiot`, `youreuseless`, `illkillyou`, `i hope you die`, `i fucking hate this rain`, `i'm fucking starving`, `you're not bad`, `not really`, `yeah right`.

Audit current PsychopatzCore normalization/candidate APIs, ProjectHoomans candidate eligibility/policy thresholds, discourse/pragmatic state, and conduct-evidence saturation.

**Gate:** failures are reproducible in the real worker, ownership is explicit, and no implementation starts in the wrong repository.

## C1 — PsychopatzCore bounded surface recovery

Implement generic recovery in the Core NLU owner:

- registry-derived compact/no-space lookup;
- conservative repeated-character recovery;
- common contraction/apostrophe recovery where safe;
- bounded segmentation fallback for single unknown tokens;
- recovery provenance and confidence penalties;
- ambiguity preservation.

Exact parsing remains first and unchanged.

**Gate:** required compact/no-space cases recover automatically from registered vocabulary while benign false-positive controls and mutating-action safety remain green.

## C2 — semantic/social feature composition

Add generic compositional cues needed for discourse interpretation without creating a standalone sentiment engine.

Cover:

- directedness;
- target/self/world distinction;
- negation;
- intensification;
- hostility/affiliation/threat-like features;
- idiom/specific-pattern suppression of misleading lower-level cues.

ProjectHoomans social catalogs may add domain meanings, but Core remains the generic matcher.

**Gate:** profanity in self/world contexts does not become recipient hostility; threat, insult and hostile wish remain distinguishable; negation behaves correctly.

## C3 — Contextual Discourse Resolver

Add one ProjectHoomans layer between Core candidates and the existing pragmatic resolver.

It consumes candidates plus bounded conversation/interaction context and emits one explainable DiscourseFrame.

Required context:

- previous/recent semantic acts;
- pending questions/offers/requests;
- current/recent topic;
- reply-to / adjacency;
- active/suspended flow;
- references/targets;
- current beat/scene;
- actor/relationship/world/knowledge projections.

It must not reparse raw text.

**Gate:** context-sensitive short replies resolve from prior interaction state without phrase-specific hardcoded response branches.

## C4 — risk-aware candidate acceptance

Replace the global conversation confidence cliff with risk-aware policy.

- social/conversational acts may accept medium-confidence candidates when context strongly supports them;
- read-only questions remain permissive enough for natural conversation;
- unresolved/ambiguous meanings still clarify;
- mutating actions retain strict high/exact/confirmation requirements.

Fix the known class where a recognized `HOSTILE_REMARK` around 0.83 becomes generic clarification.

**Gate:** conversational understanding improves without increasing unsafe action execution.

## C5 — coherent discourse continuity

Make accepted conversation systems participate in one bounded discourse state.

Prove:

- question → answer/disagreement relevance;
- topic continuation and topic shift;
- apology after hostility;
- greeting/first-contact continuity;
- referent reuse;
- interruptions and resumption where valid;
- actor/world events influencing the same conversation without replacing semantic authority.

Do not persist transcripts.

**Gate:** multi-turn harness scenarios feel coherent because later turns derive meaning from earlier semantic state rather than independent sentence classification.

## C6 — social effect / conduct-memory decoupling

Fix the `evidence_pruned_by_limit` class of failure.

An understood/selected social interaction must not be reported as semantically rejected merely because durable conduct evidence cannot retain another record.

Implement bounded aggregation/coalescing where appropriate and expose distinct outcomes for:

- interaction understood;
- reaction selected;
- relationship effect;
- durable evidence persisted/coalesced/pruned.

**Gate:** a saturated conduct ledger still permits coherent social reaction while persistence remains bounded.

## C7 — Semantic Lab observability and fuzz/regression tools

Expose the complete understanding chain in bounded form:

- raw/normalized/recovered surface;
- candidate list;
- recovery provenance;
- contextual score/reason changes;
- DiscourseFrame;
- pragmatic/interaction decision;
- social-effect and conduct-memory outcome.

Add deterministic mutation/fuzz coverage for spacing, repeated letters, punctuation, capitalization and safe typo classes.

**Gate:** an agent can diagnose why a malformed or contextual utterance succeeded/failed without screenshots or monolithic JSON.

## C8 — integrated acceptance and live-test handoff

Run focused + broad real-worker regression across:

- EN and supported additional locales where semantics are locale-independent;
- surface recovery;
- contextual discourse;
- interaction behavior;
- action-safety controls;
- social-effect saturation;
- NPC-to-NPC regression;
- generation idempotence;
- performance/bounds;
- no save mutation;
- no transcript/ModData bloat.

Only after all developer gates pass return to **READY FOR USER LIVE TEST**.

## Continue / stop rule

Under an autonomous goal, implement C0 first, validate it, update `PROGRESS.md`, and continue through C8 automatically.

Stop early only for a genuine repository-ownership/safety blocker, an external dependency that prevents implementation, or completion of all developer-side gates.

Do not stop merely because one malformed phrase works.
