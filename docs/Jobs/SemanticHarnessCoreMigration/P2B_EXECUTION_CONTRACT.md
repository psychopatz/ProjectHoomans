# P2-B typed semantic execution contract

## Core contract

Core owns `worker/SemanticExecution.lua` with schema
`semantic.harness_execution.v1`. A provider registers:

- `providerID`;
- `materializationMode`: `none`, `abstract`, or `physical`;
- capability labels;
- callbacks for context, text submission, preview, semantic-frame
  submission, and snapshots;
- an optional interaction callback.

The contract reports callback availability and fails closed for an unregistered
operation. It does not inspect provider records or decide whether materialized
NPCs should exist.

## Hoomans adapter

Hoomans wires the contract to its existing PNC-backed `Conversation` and
`ScenarioSession` services. `INPUT`, `PREVIEW`, and semantic-frame submission
now enter through the contract; Hoomans still owns PNC dialogue policy,
translations, authority pumping, and output projection. Its advertised
materialization mode is `physical`.

## Next provider gates

DTCommon/DTAbstract must register the same callback surface with
`materializationMode = abstract`; DTHoomans may register `physical`. The next
chunk must add those provider descriptors/adapters and contract tests before
moving any mixed Hoomans conversation module.
