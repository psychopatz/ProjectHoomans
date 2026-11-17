# Architecture — Semantic Test Authority

**Status:** COMPLETE (A6R26 closed).

## One behavioral authority

    semantic.harness-test.v1
    → provider resolver
    → typed operations/session controls
    → compiler/production Lua
    → comparator
    → CLI/GUI/batch

Fixtures own semantic scenario/outcome acceptance.

Imperative tests own implementation mechanisms: compiler/parser/schema, registry/ranking algorithms, protocol and worker lifecycle, GUI mechanics, save/native/network boundaries, performance, observatory/sweep/quality algorithms and static architecture.

A test is not low-level merely because it calls the production worker.

## Method-level ownership

Every direct-worker test method must state its own responsibility.

For retained imperative methods, classification must contain a concrete mechanism reason. Mixed methods should be split so behavioral assertions can move to fixtures without deleting legitimate mechanism coverage.

## Resource ownership

Every test owns and closes the Lua/Tk/process/thread resources it creates. Broad suites must finish within the acceptance bound and return to the pre-suite worker-resource baseline.

## Test-support ownership

Reusable helpers belong in descriptive support modules, never another test_*.py. Direct test-to-test imports are forbidden.

## Identity

Current filenames, classes, methods, CLI/UI help, canonical machine IDs, current module/API/error descriptions and fixture-authored synthetic IDs are descriptive. Historical phase names belong in Git/history-only commentary.

## Reproducible workspace

Acceptance is multi-repository whenever tests consume multiple repositories. Tests that read actual repo content must use the reconstructed workspace roots, not silently read a live external checkout. Read-only dependencies still receive an exact commit fingerprint in the final handoff.
