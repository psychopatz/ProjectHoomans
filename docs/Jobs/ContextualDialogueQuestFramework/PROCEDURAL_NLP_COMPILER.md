# Procedural Semantic NLP Compiler — specification and rollout

**Status:** PLANNED. `tools/semantic_compiler` already compiles reviewed WordNet 3.0 aliases/verb forms and `common_interactions.json` into generated Lua lexicon/dialogue shards. Extend that compiler rather than replacing it or making the Tk UI parse natural language independently.

## Product contract

Canonical **authoring specification** records: version/namespace/owner, concepts and aliases, utterance examples + negative examples, semantic frame/slots/capture constraints, contextual gates, named capability binding references, dialogue nodes and response pools, EN/TL keys/fallbacks, diagnostics and explicit module ownership. Graph coordinates, UI selection and layout stay separate editor metadata.

Pipeline:
1. Import/read existing registry/catalog capabilities and semantic definitions, retaining IDs, translation keys and source ownership; reject collisions or unsupported handwritten Lua.
2. Author/edit a typed intermediate representation (IR for definitions; **not** replacing the existing runtime Core semantic IR).
3. Normalize + validate graph reachability, typed conditions, slots and action parameter compatibility, unknown facts, response pools, translations, per-flow bounds and dependency capabilities.
4. Expand only **reviewed safe** aliases, grammatical forms and sample paraphrase templates using existing Core grammar/concept contracts; do not generate semantics by free-form synonym explosion.
5. Compile deterministic sorted sharded output into the existing production catalog/flow APIs, translation shards and explicit require/manifest entries. No dynamic runtime `eval`, wildcard folder scans, direct `loadstring` or separate JSON runtime.
6. Preview a precise source diff; place only approved generated artifacts in their correct mod asset paths; check in generated files and their authoring sources together.
7. Load fresh Lua worker from compiled source and run semantic/behavior acceptance. Re-compile same sources and assert byte-identical output/no stale diffs.

## Proposed definition sketch (format indicative, not implemented)

```yaml
schema: pnc.semantic_authoring.v1
id: pnc.dialogue.follow
owner: ProjectHoomans
utterances:
  positives: ["follow me", "come with me", "could you follow me"]
  negatives: ["don't follow me", "are you following me?", "I followed you"]
emit: {intent: REQUEST, speechAct: REQUEST, action: FOLLOW}
capability: pnc:companion.follow
context: {requires: ["resolved_recipient", "authorized_or_clarify"]}
dialogue:
  result: {admitted: "ack_follow", rejected: "ack_denied", pending: "ack_pending"}
responses:
  ack_follow: "semantic.follow.accepted"
  ack_denied: "semantic.follow.denied"
```

The compiler must resolve strings to **existing registered capability IDs** or fail; it must not invent a Lua function by naming convention. Generating a *supported definition* is not generating a new game implementation. New effects require a domain-owned registered handler and explicit tests.

## Output conventions and load order

Read root `AGENTS.md`, the actual `tools/semantic_compiler/build.py` / existing generated files, `PNC_SemanticCatalog.lua`, `PNC_SemanticDialogueFlowCatalog.lua`, and Build 42.20 translation/bootstrap conventions before deciding exact target paths.

Choose a stable modular layout compatible with current common/media source and 42.20 `media/lua/shared/PNC/Semantics/` sharded generated entries. Keep one responsibility per file/group (lexicon, patterns, flow definitions, response pools, translations, manifests); don't grow a giant hardcoded policy switch. Preserve existing manually written flows and source modules. Generated Lua must be Kahlua-safe. Generated translations are maintained through the project's existing EN/TL shard conventions and proper relative paths, not arbitrary new JSON in a tests folder.

## Error prevention and coverage

Fail or warn deterministically for:
- duplicate/overlapping normalized utterances, identical or conflicting Core frame matches, conflicting priorities, unsafe fuzzy executable recognition;
- new command without registered capability, wrong action ID, mismatched target/arguments, missing permission gate;
- dangling/unreachable/cyclic invalid graph and impossible or unknown gate type;
- missing response pool/translation keys and untranslated language fallback;
- collisions with current registered English and Tagalog phrases; inter-NPC pronoun/reference ambiguity;
- generated files outside canonical asset path, unmanaged manifests or excessive node/flow/diagnostic budgets.

A conservative precision-first approach to **executable commands** is mandatory. Reject imperative negation/questions/past-tense statement collisions. Automatic coverage reports should show exact positive/negative samples, selected candidate, false positives/negatives, route, relevant confidence and whether action was actually allowed. An unhandled utterance may honestly clarify; it must not become a guessed action.

## Validation and definition lifecycle

Use a supported editable code view with syntax validation and a synchronized graph, but editing handwritten complex arbitrary Lua cannot be round-tripped automatically. Preserve those files unchanged and mark read-only/unsupported until an explicit migration exists.

A generated artifact earns acceptance only when both:
- structural: compiler + source load + manifest + Kahlua/translation contracts pass, and deterministic rerun is clean;
- behavioral: fresh production Lua worker uses the compiled files and shows real IR/flow/selected NPC text/capability outcome for positive/negative and contextual cases.

The harness should produce a concise human-readable compilation report: authored definitions, generated modules with exact mod paths, skipped/unsupported source, content revisions, collisions, test cases, pass/fail and reproducible command lines. JSON may be a protocol/intermediate test format; **JSON-only artifacts/tests are not the deliverable**.

## Phasing

First prove a named existing FOLLOW binding in `CAPABILITY_ACTION_BINDINGS.md`. Then implement **one complete source generation and reload loop** for that definition using the existing compiler. Only after that broaden templates/grammar, output sharding, editing UX and quest integration. Avoid generating dozens of files in speculative feature campaigns.
