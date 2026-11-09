# P3-D — projection facades and worker handshake boundary

## Result

The remaining Hoomans activity and source/working-world state files were
compatibility-only re-exports. Their callers now import Core directly and the
duplicate files were deleted:

- `tools/semantic_harness/runtime/activity.py`
- `tools/semantic_harness/runtime/state.py`

Hoomans scenario defaults, normalization, validation, and repository/runtime
configuration remain local because they carry adopter policy and production
fixtures. The Hoomans live-profiler/source adapters now import Core state
contracts directly.

Core also owns `lua/worker/LaunchMetadata.lua`, a single parser for
`SEMANTIC_HARNESS_PROFILE`, `SEMANTIC_HARNESS_PROVIDER_IDS`, and
`SEMANTIC_HARNESS_MATERIALIZATION_MODE`. Core and Hoomans workers use it, and
both expose the resulting profile/provider/materialization metadata in their
handshake. This keeps abstract and physical providers on one observable
transport contract.

## Gates

- Core semantic-harness suite: 36 passing.
- Hoomans projection/state/runtime/codebuilder boundary slice: 36 passing,
  one expected skip.
- DynamicTrading provider-adapter Python tests: 3 passing.
- DynamicTrading Lua Core-adapter smoke: passing.
- No Hoomans imports remain for deleted process/protocol/session/activity/state
  facades; `runtime.scenario` remains intentionally Hoomans-owned.

The broader Hoomans harness still has the previously recorded three unrelated
translation/identity catalog failures. Native Project Zomboid SP/MP behavior
remains a user-owned acceptance gate.
