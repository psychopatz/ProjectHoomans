# P11B — Wellbeing wording shard characterization

## Bounded slice

This slice migrates ten fixed, no-argument semantic response families as one
cohesive Wellbeing domain shard. The default and injured families retain four
style variants; the remaining eight catalog routes retain their existing
neutral-only behavior:

| Semantic template | Selection contract | EN neutral | TL neutral |
| --- | --- | --- | --- |
| `semantic.question.wellbeing.default` | predicate-free fallback after stronger wellbeing facts | `I'm okay. How about you?` | `Okay naman ako. Ikaw, kumusta?` |
| `semantic.question.wellbeing.injured` | `healthState` is `injured`, `wounded`, or `critical` at priority 2 | `A little banged up, but I'll manage.` | `Medyo may tama ako, pero kakayanin ko.` |

The additional neutral families are `panic`, `stress`, `thirst`,
`thirst_alt`, `hunger`, `hunger_alt`, `fatigue`, and `fatigue_alt` under the
same `semantic.question.wellbeing.*` namespace, preserving the exact EN/TL
values from their former `Responses.json` records.

All ten routes are selected by the existing wellbeing observation/catalog
path. They have no arguments, effects, transport, tool calls, or gameplay
eligibility changes. Grounded wellbeing and follow-up routes remain outside
this slice. `semantic.question.wellbeing.unknown` also remains outside because
the existing `semantic.question.wellbeing.unknown` response pool is a global
ID owner; the compiler correctly rejects giving that ID to a second content
record until that response-pool boundary is migrated coherently.

## Former wording owners

Before migration, the two templates were represented by:

- the static question-wellbeing translation-key map and neutral
  `Responses.json` records for the ten migrated IDs; and
- the four-style `Status.lua`/`Realizations.json` records for the default and
  injured families.

The neutral injured TL value intentionally follows the live `Responses.json`
map (`Medyo may tama ako, pero kakayanin ko.`), not the superseded neutral
`Realizations.json` value. Warm, terse, and guarded text preserves the former
style wording exactly.

## New ownership and proof

`sources/conversation/content/wellbeing.json` is the sole authored source for
all sixteen EN/TL style phrases. CodeBuilder emits the bounded Wellbeing runtime
shard and `Conversation/{EN,TL}/Wellbeing.json`; `Status.lua` retains only an
empty registry-membership shell. The old map and legacy translation records
are removed, with no alias table.

Acceptance must prove:

1. the merged compiler model has both canonical IDs exactly once and reports
   `content/wellbeing.json` as their owner;
2. EN and TL preserve semantic identity and resolve the generated Content
   translation keys for normal and injured routes;
3. all four style phrases match the characterized values;
4. transport/tool/effect outputs and route precedence remain unchanged;
5. legacy map/`Responses.json`/`Realizations.json` ownership is absent for all
   migrated IDs, with the compiler-reported unknown-pool collision explicit;
6. generation remains deterministic and the full native Lua regression stays
   green.
