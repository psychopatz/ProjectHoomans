# Runbook — Modular Semantic Harness and Mod Manager

## Repositories

- Primary: `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`
- Core: `/home/psychopatz/Zomboid/Workshop/psychopatzCore`
- Dynamic Trading: `/home/psychopatz/Zomboid/Workshop/DynamicTrading`

Always inspect all three Git states before editing. Preserve unrelated dirty
files. Never create branches, publish Workshop content, launch native Project
Zomboid, or use destructive Git operations.

## Implementation sequence

1. Baseline the current Core harness and provider tests.
2. Add Core-owned manifest/selection/activation contracts and unit tests.
3. Migrate provider manifests and adapters without changing domain behavior.
4. Add selection CLI and compatibility aliases.
5. Wire activation routes into Python and Lua workers.
6. Fix installed/wheel launch and recursive package data.
7. Audit generic/provider ownership and remove only proven duplicate harness
   mechanics.
8. Run focused, cross-repository, packaging, and static gates.

## Commands

Run from Core unless a test explicitly belongs to an adopter:

```bash
PYTHONPATH=. python3 -m unittest discover -s tools/semantic_harness/tests -p 'test_*.py'
PYTHONPATH=. python3 -m tools.semantic_harness --help
bash tools/semantic_harness/run_harness.sh --doctor --doctor-json
```

The final runbook will document the completed manager commands and selection
matrix after implementation.
