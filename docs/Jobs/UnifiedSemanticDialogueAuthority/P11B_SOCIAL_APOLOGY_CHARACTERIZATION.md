# P11B Social Apology Characterization

## Scope

The fixed Social Apology wording domain is the four realization families
selected by the existing `semantic.apology` response catalog:

- `semantic.social.apology.default`
- `semantic.social.apology.friendly`
- `semantic.social.apology.stressed`
- `semantic.social.apology.withdrawn`

Each family has one authored phrase for each of the four presentation styles
(`neutral`, `warm`, `terse`, and `guarded`) in English and Tagalog. The
manifest-backed `content/social_apology.json` shard owns these 16 phrase
variants. Its `apology` domain generates bounded `Apology.lua`, `Apology.json`
and Tagalog `Apology.json` artifacts.

The broad `content/social.json` shard remains the owner of its unrelated
commands/emotes and tool-reply content. The new shard is a semantic domain
boundary, not a byte-range split.

## Runtime authority preserved

`PNC_SemanticDialogueResponseCatalog_Social_Core.lua` remains the response
selection authority. Stress/panic precedence, friendly selection, withdrawn
selection, default fallback, relationship projection, and the existing
`SOCIAL_ACKNOWLEDGED` response branch are unchanged. Apology turns remain
deterministic and presentation-only: they do not mutate relationship state,
dispatch tools, call the LLM, or authorize gameplay effects.

The `semantic.apology.trusted` catalog variant remains a compatibility
boundary. It has a response fallback and external relationship eligibility but
no legacy fixed realization family or style bundle, so it is deliberately not
invented or migrated in this slice. Its static response key remains available
until that response-pool boundary is characterized separately.

## Retired wording owners

The four migrated static response-map entries, four fixed `Responses.json`
keys, and sixteen fixed `Realizations.json` keys are retired in both EN and TL.
The four handwritten `SpeechRealization/Families/Social.lua` families are also
retired. The generated Conversation registry now resolves the migrated IDs to
generated phrase keys while preserving their semantic IDs and response-pool
selection.

## Acceptance evidence

- focused Social Apology/compiler/runtime/compatibility regressions: `6/6 PASS`;
- full Python acceptance: `164/164 PASS`, `0` failures, `0` skips;
- native Lua regression: `897/897 PASS`;
- two consecutive CodeBuilder generations: `125` artifacts,
  `1,554,720` bytes, identical SHA-256
  `d5b864b8de13d3889d2d06dafed012840e90f9fbb256339aa3b19de2b1066de7`;
- `pz_verify --kahlua`: `3,391` files scanned, `0` errors, `0` warnings;
- installed Project Zomboid Kahlua compiler: `123` files passed, `0` source
  writes, no game launch.
