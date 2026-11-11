# Progress — Semantic Harness Core Migration

**Status:** developer-side implementation complete; native SP/MP acceptance remains user-owned.

**Primary repository:** ProjectHoomans (`main`)

**Participant repositories:** PsychopatzCore (`main`), DynamicTrading (`main`)

## Delivered contract

PsychopatzCore is infrastructure for every product composition. The harness
does not offer a Core-only preset. Core discovers provider manifests, resolves
dependencies/conflicts/routes, expands live runtime paths, and emits one
activation plan consumed by the Python and Lua workers.

The supported compositions are:

- `pnc`: Core + Project Hoomans.
- `dtabstract`: Core + DTCommon + DTAbstract.
- `pnc-with-dthoomans`: Core + Project Hoomans + DTCommon + DTHoomans.

Runtime bootstrap entrypoints are loaded from the live Core, Project Hoomans,
and Dynamic Trading repositories. No fixture copy or legacy provider shim is
used for activation.

## Repository changes

### PsychopatzCore

- Added the Core provider descriptor and live `runtimeBootstrap` manifest contract.
- Made `ActivationPlan` carry ordered live bootstrap entries.
- Added headless Lua bootstrap loading and activation-mod projection.
- Removed the old provider registry/profile-loader modules and their tests.
- Removed Core and standalone DTHoomans from the public preset catalog.
- Kept future expansion selection data-driven through manifests and custom provider IDs.

### Project Hoomans

- Removed the PNC adapter-registration shim.
- Uses the shared Core activation plan for PNC and DTHoomans loading.
- Dynamic Trading selection is derived from active providers, not scenario fixture flags.
- Preserved PNC production policy and its actual live runtime files.

### Dynamic Trading

- Declares DTCommon, DTAbstract, and DTHoomans through one provider manifest.
- Declares direct Core dependencies in the DTAbstract and DTHoomans mod metadata.
- Removed the standalone Dynamic Trading adapter-registration shim and tests.

## Developer-side evidence

- Core semantic harness suite: 55 tests passed.
- PNC runtime configuration slice: 4 tests passed.
- Live `run_harness.sh` smoke checks passed for `pnc`, `dtabstract`, and
  `pnc-with-dthoomans`, including real bootstrap entrypoints and provider IDs.
- `luac -p` passed for the changed Core and PNC worker modules.
- No Workshop publication or native Project Zomboid process was performed.

## Remaining user-owned gate

Run the native SP/MP matrix against real saves: composition toggles, restart
persistence, DTAbstract abstract interaction, DTHoomans physical materialization,
and shared conversation/trade behavior. This is outside the developer-side
filesystem/runtime harness gate.
