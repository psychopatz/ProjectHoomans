# P1-H worker router boundary

## Audit result

The Hoomans `CommandRouter` had two responsibilities mixed in one file:

1. provider-neutral ordered handler dispatch and unknown-command failure;
2. the Hoomans handler list and transport-evidence policy.

The session, conversation, authoring, knowledge, simulation, talk, and
observatory handlers are not generic: they depend on PNC and Hoomans provider
capabilities and remain adopter-owned.

## Change

Core now owns `worker/Router.lua`. It accepts an adopter-supplied ordered
handler list and optional transport-evidence annotator, preserves handler
return/control values, and returns the canonical unknown-command failure.
Hoomans supplies its existing handler list and evidence module through this
seam. The Hoomans router remains the provider composition point, but no longer
duplicates the dispatch loop.

## Deliberately retained in Hoomans

- `CommandRouter_Session.lua` and all command capability policy;
- Hoomans/PNC conversation, authoring, knowledge, simulation, and talk
  handlers;
- provider-specific hello/catalog projections;
- transport evidence configuration and fact-command selection.

## Gate

Core router smoke coverage verifies ordered dispatch, control-result
preservation, transport annotation, and unknown-command behavior. Hoomans
worker-module and dialogue smoke tests verify the adopter composition still
boots through the Core-first module path.
