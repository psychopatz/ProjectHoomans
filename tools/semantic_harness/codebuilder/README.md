# Semantic Lab CodeBuilder

This package is the single offline implementation of the Project Hoomans
semantic compiler and deterministic artifact writer. Semantic Lab's GUI,
headless authoring commands, and Codex-facing Python API use these modules.

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
