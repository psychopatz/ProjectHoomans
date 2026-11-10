# Core Semantic Harness Migration Roadmap

## Objective

Make PsychopatzCore the sole owner and distributor of the provider-neutral
Semantic Harness and its shared identity, semantic-suggestion, and
world-discovery/radio contracts. Project Hoomans/PNC and Dynamic Trading/DT
consume the Core package through explicit provider manifests. No adopter keeps
a `tools/semantic_harness` directory, package entrypoint, or compatibility
bridge.

## Ownership contract

- Core owns the worker lifecycle, protocol, runtime/session mechanics,
  CodeBuilder, inspection/UI/testing tools, generic Lua worker, identity
  knowledge/display projection, deterministic nickname derivation, static
  semantic suggestions, and radio/discovery contracts.
- PNC owns PNC gameplay policy, adapters, fixtures, authored conversation
  content, and the optional DTCommon materialization target used by its
  provider-aware generator.
- DT owns DTCommon/DTAbstract/DTHoomans adapters and DT conversation content.
  DTAbstract resolves with Core and DT alone; it does not load PNC.

## Acceptance phases

1. Baseline ownership and dirty-work preservation recorded.
2. Core harness package and `semantic-lab` entrypoint completed.
3. PNC and DT provider packages moved outside the adopter harness namespace.
4. Manifests, callers, generated Lua/translation artifacts, and tests cut over
   to Core; identity facets and optional DT content are source-owned correctly.
5. Old adopter trees and root harness packaging deleted; profile matrix and
   static ownership scans pass.

All five phases are satisfied in the current local workspace. Native
Project Zomboid validation and Workshop publication are outside this goal.
