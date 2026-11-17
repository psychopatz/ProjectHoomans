# Architecture — Semantic Test Authority

**Status:** COMPLETE.

## Behavioral authority

    semantic.harness-test.v1
    → provider resolver
    → typed operations/session controls
    → compiler/production Lua
    → comparator
    → CLI/GUI/batch

Fixtures own semantic scenario/outcome acceptance.

Imperative tests own implementation mechanisms: parser/compiler/schema, provider/registry/ranking algorithms, transport and worker lifecycle, stale/replay protocol, GUI mechanics, persistence/native/network boundaries, performance, authoring/editing internals and observatory/sweep/quality algorithms.

A production-worker call alone never makes a test low-level.

## Method-level ownership

Each direct-worker method has a specific classification reason. Mixed tests are split so fixture-owned behavior is not duplicated by imperative acceptance.

## Resource ownership

Tests close the Lua/Tk/process/thread resources they create. Broad discovery must return to its pre-run worker baseline.

## Repository boundaries

Reusable helpers live in support modules rather than test-to-test imports. Acceptance uses explicit sibling repository roots. Read-only dependencies are pinned in HANDOFF even when unchanged.
