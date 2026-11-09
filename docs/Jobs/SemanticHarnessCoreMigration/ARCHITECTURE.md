# Architecture — Semantic Harness Core Migration

## Ownership target

```text
PsychopatzCore
  protocol / JSON / process / worker session
  scenario and bounded projections
  provider registry and capability contracts
  generic conversation, traversal, identity, and interaction seams
  provider-neutral tests

ProjectHoomans     DTCommon / DTAbstract / DTHoomans
  provider adapters, policy, data, and acceptance tests
  physical materialization where supported
  abstract simulation where supported
```

The target is one execution model with capability differences, not separate
Hoomans and DynamicTrading harness engines. Provider modules must communicate
through Core contracts and degrade cleanly when an optional adopter is absent.

## Non-goals

- Moving merchant stock, budgets, or trade authority into Core actor inventory.
- Making DTAbstract materialize NPCs.
- Making Hoomans provider policy part of Core.
- Deleting tests solely to reduce file count without a replacement contract.
- Claiming native runtime acceptance from Python/Lua harness results alone.
