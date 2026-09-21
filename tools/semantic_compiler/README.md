# Semantic compiler

This offline Python tool compiles a reviewed subset of Princeton WordNet 3.0
into aliases for concept IDs already registered by Project Hoomans. It does not
load WordNet or any other linguistic package at runtime.

The allowlist maps selected verb synsets to existing `FETCH` and `FOLLOW`
concepts. For `FETCH`, it adds the reviewed base lemmas `retrieve`, `take hold
of`, and `pick up` alongside `bring`, `fetch`, `get`, and `grab`. For `FOLLOW`,
it selects only the travel-behind sense and the base lemma `follow`; no other
WordNet synonyms are imported. Inflected forms are compiled into a separate
lemma-and-form index rather than concept aliases. The Lua Registry indexes
those forms, and grammar rules must opt into a specific form before it can
match. This supports narrow cases such as `stop following me` while keeping
past-tense and progressive statements out of imperative command rules. The
`got` and `gotten` forms are excluded because the authored catalog assigns
`got` to `HAVE`. Broad WordNet relations, unreviewed synset members, and
noun/entity aliases are not imported.

The selected WordNet 3.0 verb senses are `01433294` (bring/get/fetch),
`01433991` (retrieve), `01439190` (grab/take hold of), `02305586` (pick up),
and `01998432` (follow, travel behind). The allowlist names each accepted
lemma; other members of those synsets remain excluded. For example, the
compiler does not import `catch`, `convey`, or `collect` into FETCH.

## Build

Download and extract the WordNet 3.0 package from Princeton, then run:

```sh
python3 tools/semantic_compiler/build.py \
  --wordnet-home /path/to/WordNet-3.0
```

The source directory must contain `LICENSE` and `dict/index.verb`,
`dict/data.verb`, and `dict/verb.exc`. The output defaults to
`Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Semantics/PNC_SemanticGeneratedLexicon.lua`.
Use `--output` to build elsewhere. Raw WordNet files are not copied into the
repository or the Lua runtime.

Each mapping contains an exact WordNet verb offset and an explicit list of
permitted lemmas. The compiler rejects missing offsets, lemmas that are not
members of the selected synset, index mismatches, and generated alias
collisions across Hoomans concepts. It pins the hashes of the WordNet 3.0
verb index, verb data, exception list, and license so a different release or
modified source cannot be mislabeled as 3.0. It uses the selected lemmas,
WordNet's verb exception list, and a small offline regular-inflection routine.
Phrase verbs inflect only their first token. Inflections are tagged as past,
progressive, or third-person forms and point to their selected lemma. Forms and
aliases are sorted and deduplicated for stable output. Source version, file
checksums, license metadata, and the WordNet license notice are kept with the
generated artifact.

## Runtime integration

`PNC_SemanticCatalog.lua` merges generated aliases with authored aliases before
calling the existing Core `Registry.RegisterConcept`. Authored aliases are
kept first; normalized duplicates are removed. It registers generated forms
through the Core Registry's separate O(1) verb-form index. The concept matcher
returns form metadata, and command patterns reject those symbols by default;
only a rule with an explicit `verbForms` allowlist can consume one. Unused
generated concept IDs fail catalog registration so stale build data cannot
silently go unused.

The compiler does not add entity classes, relation semantics, task adapters,
or runtime execution handlers. The existing `FETCH` action reuses the
`GIVE_ITEM` task flow: it selects an item already carried by the NPC, moves to
the speaking player, and uses the authoritative inventory transfer. Requests
naming a `from` source or a destination other than the speaking player are
rejected. Runtime execution does not use WordNet relationships to search world
or container inventories.

## Tests

```sh
python3 -m unittest discover -s tools/semantic_compiler/tests -v
python3 tests/run_tests.py pnc_semantic_generated_lexicon_smoke
```

The license notice is also included at
`Contents/mods/ProjectHoomans/42.20/third_party_licenses/WordNet-3.0-LICENSE.txt`.
Review the upstream terms for the intended distribution. Princeton's official
WordNet package and license are documented at:

- https://wordnet.princeton.edu/documentation/wnpkgs7wn
- https://wordnet.princeton.edu/license-and-commercial-use

## Common dialogue interactions

`common_interactions.json` is the reviewed Project Hoomans seed for everyday
greetings, identity questions, wellbeing/activity questions, and state-aware
response variety. Its utterance patterns are exact full-phrase matches that
emit only existing `GREET` or `QUESTION` semantics. Question subjects use
existing `IDENTITY`, `WELLBEING`, and `ACTIVITY` response paths. Identity
responses retain the existing name-disclosure trust gate, while supplemental
lines vary by the NPC's identity-trust state.

DailyDialog and EmpatheticDialogues are recorded as coverage references for
dialogue-act and emotion-aware interaction categories. This seed contains
Hoomans-authored examples; it does not copy corpus turns. Corpus text should be
reviewed for its own license and manually mapped before any phrase is added to
the runtime seed.

Compile the reviewed interaction data with:

```sh
python3 tools/semantic_compiler/build.py \
  --dialogue-source tools/semantic_compiler/common_interactions.json
```

The compact result is
`Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Semantics/PNC_SemanticGeneratedDialogue.lua`.
The existing semantic catalog registers the exact patterns with the Core
Registry, and the existing response catalog appends the bounded variants to
their current pools. The compiler rejects unsupported intents, fuzzy patterns,
unknown response conditions, duplicate IDs/utterances, and oversized pools.
No external corpus or linguistic package is loaded by Lua at runtime.
