# Architecture — Semantic Test Estate

**Status:** COMPLETE (A6R19–A6R22 accepted).

## Behavioral authority

    semantic.harness-test.v1
    → provider resolver
    → typed operations
    → compiler/production Lua
    → comparator
    → CLI/GUI/batch

Fixtures own semantic scenario/outcome behavior. Imperative tests own mechanisms: compiler/parser, registry/ranking, protocol/payload validation, GUI mechanics, save/native/network, performance, observatory/sweep/quality algorithms, and static architecture.

## Test-support ownership

Reusable test setup/helpers belong in dedicated support modules, never another `test_*.py`. Tests importing tests create rename-order coupling and are forbidden.

## Hermeticity

Every worker/Tk test owns and closes its resources. Full-suite execution must terminate with zero test-owned worker descendants and without unraisable GUI cleanup errors.

## Identity

Descriptive identity applies to filenames, test classes/methods, current CLI/UI text, canonical machine IDs, and fixture-authored synthetic IDs. Historical phase labels belong in Git/history documents; compatibility aliases must be explicit, deprecated, and tested.

## Classification

Mixed direct-worker suites require method-level responsibility. A worker call does not make behavior a low-level contract.
