# P4-F — engine projection ownership audit

## Result

The following provider-neutral Project Zomboid/semantic-harness infrastructure
now lives in PsychopatzCore:

- offline engine fixture projection;
- health normalization and validation;
- installed item-script catalog parsing;
- bounded read-only Core-profiler projection; and
- native Build 42 player-state decoding.

The two places where source data is adopter-shaped remain explicit thin
Hoomans adapters: profiler namespace aliases (`ProjectHoomans.*`) and native
player identity matching (`PNC_CharacterUUID` plus related metadata). Core's
generic modules accept those as configuration and contain no Hoomans or
Dynamic Trading imports or identifiers.

## Remaining Hoomans runtime ownership

The remaining `tools/semantic_harness/runtime` package is limited to Hoomans
policy and source integration: repository/profile configuration, Hoomans
scenario defaults, PNC save catalog/import/browser/state providers, NPC
profiles, physical worker command operations, and Hoomans authoring and
knowledge projections. Those are not duplicate Core engines and should not be
deleted merely because they live under a `runtime` directory.

## Validation

- PsychopatzCore semantic-harness suite: 43 tests passed.
- Project Hoomans engine-projection/worker integration slice: 23 tests passed,
  with only environment-dependent skips.
- Old Hoomans imports for the five moved generic modules are absent.
- Core generic projection modules have no adopter-name references.
- Native Project Zomboid SP/MP behavior was not launched or claimed.

## Next

Run the cross-repository import/load matrix for Core-only, Hoomans,
DTAbstract, and DTHoomans; then complete the user-owned native acceptance
matrix. Any further deletion must be driven by caller/test proof, not by the
directory name alone.
