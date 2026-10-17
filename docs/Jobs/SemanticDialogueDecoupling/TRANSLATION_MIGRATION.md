# Conversation translation shards — implemented; deployment acceptance outstanding

## Current inventory
Project Hoomans `d345e5c3ba41ba752517b405320e6d61e847a3f8` contains explicit `common/media/translation/manifests/Conversation.json`, with **12 EN and 12 TL** subsystem files under `EN/Conversation/` and `TL/Conversation/`. Former single `Conversation/Conversation.json` files have been removed. The previous implementation ledger reports exactly 521 unique keys for each language with value/placeholder parity to baseline monoliths; audit that parity from the installed deployed files before calling native migration complete.

Published PsychopatzCore `0212491d2af3597cceaa7353e62f01ef54adca44` **does not support a manifest argument** for `scope.registerSystem`. The Hoomans bootstrap calls `Scope.registerSystem(systemName, basePath, MANIFESTS[systemName])`; on that published Core the third parameter is ignored and legacy one-file loading is attempted. This can result in English/default fallback or an unloaded custom Conversation catalog. It must not be silently accepted as success.

## Required corrected contract
- Reconcile and safely publish/install compatible Core manifest loader **without discarding unrelated local Core edits**. Validate Hoomans/Core pair in the actual game.
- Keep `PNC.Translation.GetKey`, `Get`, `TrFormat`, Core legacy `registerSystem`, per-key English fallback, diagnostics and language switching stable; fail visibly if a required API is missing rather than silently hiding missing shards.
- Explicit manifest paths and finite bounded file reads; reject duplicates, path traversal, invalid files and missing English ownership. No directory recursion, repeated IO per turn, or parallel editable monolith.
- Verify actual EN/TL identity/wellbeing/tool replies, shared UI, language restart, missing-TL fallback and original key/value/placeholder parity in the installed B42 mod pair.
- The old `common/media/conversation/` authored dialogue system and `common/media/lua/shared/Translate/` native PZ catalogs are not targets.
- Legacy `Trading/Trading.json` has 20 keys per language but is not one of the 15 bootstrap systems; earlier real lookup fell back. Fix only after tracing its consumers/ownership; keep it a bounded integration issue.
- Do not create another goal, move shards back into one giant file, or claim passing JSON audit implies native localized display.

## Corrective acceptance
Before any more sharding changes: Core deployed handshake confirms manifest API, actual `getModFileReader` opens a declared shard path, EN and TL real in-game dialogue renders distinct values, and fallback/lookup provenance can be inspected. Former manifest smoke result and parity hashes are useful regression references, not full proof of installed behavior.
