# Architecture — Semantic Test Authority

**Status:** COMPLETE.

## Invariant

Provider behavioral acceptance has one authority:

    semantic.harness-test.v1
    → resolver/loader
    → typed operations
    → compiler/production Lua
    → comparator
    → CLI/GUI/batch

GUI Regression actions are fixture presets, not parallel behavioral matrices.

## Ownership

Fixtures own semantic scenario/outcome behavior.

Imperative tests own implementation contracts such as compiler/parser/generation determinism, worker protocol and payload validation, GUI mechanics, save/native/network boundaries, performance/resource budgets, observatory/sweep/quality algorithms, event-window worker RPCs, and static architecture.

Calling `LuaSemanticWorker` does not make a test low-level.

## Naming

Active paths, suites, case IDs, test filenames, class names, and human-facing descriptions describe current semantic/implementation responsibility. Historical phase provenance belongs in Git.

## Migration rule

Split mixed suites at method responsibility. Migrate behavioral methods only after fixture parity; retain implementation methods with specific justifications.
