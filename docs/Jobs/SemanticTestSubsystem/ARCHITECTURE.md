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

Fixtures own semantic scenario/outcome behavior (including contextual hub/suggestion availability, trust/ownership gating, click routes, and action-surface refresh).

Imperative tests own implementation contracts such as compiler/parser/generation determinism, worker protocol and payload validation, GUI mechanics, save/native/network boundaries, performance/resource budgets, observatory/sweep/quality algorithms, candidate registry/ranking/privacy mechanics, stale-frame/cache replay protocol, event-window worker RPCs, and static architecture/naming guards.

Calling `LuaSemanticWorker` does not make a test low-level.

## Naming

Active paths, suites, case IDs, test filenames, class names, canonical UI/CLI/API identities, and human-facing descriptions across both repositories describe current semantic/implementation responsibility. Historical phase provenance belongs in Git.
