# Unified Semantic Catalog Progress

**Status:** IMPLEMENTED — pending phase commit

**Primary repository:** `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`

**Participants:** PsychopatzCore, DynamicTrading

**Current phase:** Self-contained CodeBuilder recipe migration

**Next chunk:** final diff/status review, then participant commits first and
primary handoff commit last.

## Verified baseline

- PsychopatzCore is the only semantic CodeBuilder authority.
- Project Hoomans and Dynamic Trading consume the Core compiler and do not
  carry a second semantic harness.
- The manifest mounts the DT external pack into the same Core graph.
- Generated runtime locale files remain under each owning mod's
  `common/media/translation/<LANG>` tree.
- Existing unrelated dirty work in all three repositories is preserved.

## Accepted self-contained source contract

- Core-owned conversation shards and the DT external pack use
  `psychopatz.semantic.shard.v3`.
- Phrase source records are locale maps (`EN`, `TL`, and future locales); they
  no longer contain `phraseID` or `translationKey`.
- The compiler derives phrase IDs and runtime translation keys deterministically
  from the semantic template, style, and append-only array index.
- Player choices carry inline `label` and `choice` locale maps.
- Response variants, semantic-flow responses, and UI suggestions carry their
  own wording beside their structural records.
- `conversation_bundles.json` uses inline `text` locale maps and schema v2.
- Core source `translations/EN.json` and `TL.json` are deleted.
- The old source catalog reader, generator, contract, and hydration test are
  deleted; no compatibility bridge remains.

## Authoring service behavior

- The editor still exposes `translations`, `labelTranslations`, and
  `choiceTranslations` as its locale-facing view, so the UI does not need to
  know the physical recipe shape.
- Writes update the owning source shard directly and then regenerate package
  runtime artifacts; no authoring catalog is written.
- Dataset editing resolves provenance from manifest `sourceProfiles` in memory
  and never materializes a repeated source envelope into a shard.
- Stale dataset routes were corrected from deleted `flows/common/*` paths to
  the canonical `responses/*` shards.

## Verification

- Core CodeBuilder tests: **80/80 passed**.
- Full PNC conversation suite: **48/48 passed**.
- DT smoke suite: **88/88 passed**.
- Real build: **297 generated files**, 505 phrase families, 56 patterns, 13 UI
  definitions.
- Runtime parity: canonical content text and all Project Hoomans bundle text
  match the pre-migration EN/TL wording.
- Harness pings pass for `pnc`, `pnc-with-dthoomans`, and `dtabstract`.
- Source audit: no legacy source identity fields, no authoring translation
  directory, and no repeated provenance envelopes; three expected preferred
  size advisories remain.

The existing unrelated Tkinter observatory teardown finding remains outside
this phase.
