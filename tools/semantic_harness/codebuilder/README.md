# Semantic Lab CodeBuilder

This package is the single offline implementation of the Project Hoomans
semantic compiler and deterministic artifact writer. The shared
`SemanticLabAuthoringService` binds repository/runtime configuration for
Semantic Lab's GUI, headless authoring commands, and Codex-facing Python API.

The reviewed canonical JSON inputs remain in `tools/semantic_compiler/`:

- `semantic_definitions.json`
- `common_interactions.json`
- `wordnet_concepts.json`

The `tools/semantic_compiler` Python modules are compatibility wrappers only;
they re-export this package and preserve direct-script and `python -m` entry
points. Generated Lua, EN/TL translations, and manifests retain their existing
Project Zomboid paths and byte-stable rendering.

Headless Semantic Lab authoring uses the same service as the Tk editor:

```sh
tools/semantic_harness/run_harness.sh --no-gui --jsonl \
  --compile-source tools/semantic_compiler/semantic_definitions.json
tools/semantic_harness/run_harness.sh --no-gui --jsonl \
  --review-dataset tools/semantic_compiler/common_interactions.json
```

`--generate-source` and `--generate-dataset` are explicit write operations;
preview operations remain effect-free.

The same service exposes `SemanticBlockRegistry`, a bounded catalog of
reusable language, condition, world-fact, context, memory, response, action,
and quest blocks. Live Semantic Lab passes the existing Lua FlowEditor catalog
into it; the registry only describes and validates references. Gate evaluation,
NLU interpretation, gameplay dispatch, and quest authority remain in their
existing production owners.

The Flow editor also uses `semantic.codeblocks.v1` for a deterministic
graph/codeblock round trip. Node definitions are retained, ordinary and
result edges carry explicit types, and nested-flow references are bounded
editor metadata validated against known flow IDs. Applying codeblocks changes
only the current draft; production `Registry.Validate` remains the final
registration authority.

Reviewed external dataset adapters are also part of CodeBuilder. The MASSIVE
and SGD adapters accept only bounded build-time sources plus a provenance
manifest, verify the source hash, and emit effect-free review candidates. A
candidate can become a canonical dialogue pattern only after an explicit
review decision and a manifest with approved derived-text redistribution.
Adapters never write raw corpora to `Contents/mods/**/media`, package raw
records for Lua, or replace the existing dialogue compiler.

```sh
tools/semantic_harness/run_harness.sh --no-gui --jsonl \
  --adapt-dataset massive \
  --dataset-source /path/to/massive.jsonl \
  --dataset-manifest /path/to/massive.manifest.json
```
