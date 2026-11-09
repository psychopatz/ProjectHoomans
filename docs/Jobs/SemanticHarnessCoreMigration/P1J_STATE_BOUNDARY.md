# P1-J Python state boundary

## Audit result

Hoomans `runtime/state.py` contained only provider-neutral state mechanics:
provenance labels, immutable source snapshots, working-world baselines, bounded
patch diffs, reset counters, and transport projections. Hoomans `runtime/worker.py`
and save-backed tests consumed those types. Core had no equivalent Python
module.

Hoomans `runtime/scenario.py` remains mixed: Core already owns generic merge,
name/identifier, and JSON document mechanics through aliases, while Hoomans
retains its default scenario, health normalization, and Hoomans-specific
validation policy.

## Change

The state engine now lives in Core `semantic_harness.state`. Hoomans
`runtime/state.py` is a compatibility re-export, so existing callers and save
providers keep their import paths without retaining a second implementation.

## Deliberately retained in Hoomans

- `DEFAULT_SCENARIO` and Hoomans fixture shape;
- health normalization and NPC validation;
- production save import and provider rehydration;
- Hoomans worker façade and conversation policy.

## Gate

Core state tests cover immutable source data, mutation patches, provenance, and
reset behavior. Hoomans save-backed, production rehydration, envelope, and
worker smoke tests pass through the compatibility import path.
