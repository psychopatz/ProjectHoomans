# C0A baseline evidence

These reports characterize the current Project Hoomans production path. The
semantic, multi-turn, suggestion, and realization reports are captured through
`LuaSemanticWorker`; Python only sends inputs and projects returned Lua fields.
The storage report reads the existing compiler model and generated tree. The
conduct report is backed by a disposable Lua smoke registry.

The `expectedSemantic` labels live only in the fixture files. They are not
asserted as current behavior and are not used by the worker or by any Python
semantic evaluator.

Capture commands:

```text
python3 -m tools.semantic_harness.c0a_baseline semantic
python3 -m tools.semantic_harness.c0a_baseline multi_turn
python3 -m tools.semantic_harness.c0a_baseline suggestions
python3 -m tools.semantic_harness.c0a_baseline reply_realization
python3 -m tools.semantic_harness.c0a_baseline storage
```

The checked-in JSON is a C0A snapshot. Later semantic changes should update or
replace the relevant current report intentionally rather than turning a
characterized failure into an expected result.
