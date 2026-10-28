# Audit — Current Conversation-Coherence Gap

This file records only the evidence that justifies the active C0–C10 roadmap. Completed R0–R9 recovery history is available in Git and is not repeated here.

## Current production findings

Fresh Semantic Harness worker checks on the current ProjectHoomans checkout show:

| Input | Current semantic result | Current visible outcome |
| --- | --- | --- |
| `fuckyou` | `INSULT`, ~0.91 | hostile response |
| `fuck u` | `INSULT`, ~0.99 | hostile response |
| `fuck youuuu` | `HOSTILE_REMARK`, ~0.87 | hostile response |
| `i hate you` | `HOSTILE_REMARK`, ~0.99 | hostile response |
| `i hope you die` | `HOSTILE_REMARK`, ~0.83 | generic clarification |
| `shutthefuckup` | no match | clarification |
| `youidiot` | no match | clarification |
| `illkillyou` | no match | clarification |
| `youreuseless` | no match | clarification |

The exact values are baselines, not permanent contracts.

## Root cause 1 — whitespace/token boundaries

PsychopatzCore `PsychopatzSemanticNormalizer.lua` lowercases, cleans punctuation and tokenizes on whitespace. Joined words therefore remain one token unless fuzzy matching happens to rescue a particular case.

The correct owner for generic no-space/elongation recovery is PsychopatzCore, not a ProjectHoomans phrase patch.

## Root cause 2 — candidate interpretation is richer than final policy

ProjectHoomans already consumes Core candidate parsing, but `PNC_SemanticDialoguePolicy_Flow.lua` applies a broad high-confidence gate after unresolved-reference handling.

A recognized social act below the high threshold can therefore become `ASK_CLARIFICATION` even when it is entity-independent and conversation-safe.

This policy should become risk-aware rather than globally lowered.

## Root cause 3 — discourse context is underused

The accepted pragmatic resolver knows flows, topic and recent semantic state, but candidate selection/admission still happens before a dedicated conversation-context interpretation layer can use adjacency, pending questions and related discourse evidence.

The missing layer belongs between Core candidates and the existing pragmatic resolver.

## Root cause 4 — suggestions and replies are still more authored than semantic

The existing PNC_SemanticDialogueSuggestions pipeline already has the correct execution authority: it gathers authored/root/flow/response-plan/provider candidates, ranks and deduplicates them, and clicks typed semantic_click_frame values through the existing conversation path.

However, most visible candidate wording is still supplied by authored labelKey / utteranceKey / fallback records. The system does not yet derive a balanced set of positive, negative and contextual semantic continuations directly from the current DiscourseFrame.

Likewise, PNC_SpeechRealization.lua already owns style-aware phrase-family selection and anti-repeat, but it mainly selects complete authored phrases. It does not yet compose a bounded runtime utterance from a semantic strategy plus canonical lexical slots.

Therefore the next architecture should extend these existing authorities, not create a second button generator or response engine.

## Root cause 5 — social persistence can masquerade as semantic failure

Conduct evidence is bounded at 64 entries. `PNC_ConductService_EvidenceInternals.lua` inserts new evidence and calls `PruneEvidence`; when the new item itself is removed, the operation returns `evidence_pruned_by_limit`.

That persistence outcome can surface as a rejected social action even though NLU and interaction selection succeeded.

Language understanding, immediate reaction, relationship change and durable evidence retention must be reported separately.

## Architectural conclusion

Do not fix this by:

- adding every malformed spelling as a new social alias;
- adding a ProjectHoomans tokenizer;
- introducing a standalone sentiment classifier;
- globally lowering confidence thresholds;
- expanding conduct evidence without bounds.

Proceed through the C0–C10 roadmap using existing Core NLU, ParseCandidates, discourse state, pragmatic resolver, Interaction Director and Semantic Lab.
