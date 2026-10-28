# Semantic Harness CodeBuilder

CodeBuilder has one canonical Conversation authoring tree:

```text
sources/conversation/
├─ manifest.json
├─ content/
├─ patterns/
├─ flows/
└─ ui/
```

`wordnet_concepts.json` remains the canonical reviewed lexicon mapping.

There are no aggregate Conversation source files and no standalone
semantic/dialogue/content generation modes. Patterns, response pools, semantic
flows, phrase content, and static UI definitions are compiled together through
`conversation/manifest.json`.

## Generate Conversation artifacts

```bash
python3 tools/semantic_harness/codebuilder/build.py \
  --conversation-manifest \
  tools/semantic_harness/codebuilder/sources/conversation/manifest.json \
  --conversation-output-root .
```

This deterministically generates:

- bounded Lua modules under `Generated/Conversation/`;
- the small Conversation registry/manifest hubs;
- Conversation-domain translation bundles;
- the generated translation manifest;
- per-artifact deterministic hashes/diffs from the canonical shard model.

Generated Lua/JSON is never an authoring source.

## Authoring service

Semantic Lab and agent workflows use logical dataset IDs backed directly by
canonical shards:

- `semantic_flows`
- `common_dialogue`
- `grounded_personal`
- `wordnet_concepts`

Dialogue logical datasets combine their pattern and response shards in memory
for validation and split writes back to those real shards. No compatibility
aggregate is created.

## Locales

EN is the required fallback. Other locales are data-driven through generic
`translations` maps and generated translation discovery. Adding another locale
must not require a CodeBuilder language whitelist.

## WordNet

WordNet generation remains independent:

```bash
python3 tools/semantic_harness/codebuilder/build.py \
  --wordnet-home /path/to/WordNet-3.0
```
