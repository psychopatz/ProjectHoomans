# Semantic dialogue architecture — implemented vs target

## Current production pipeline (source verified, subject to installed Core revision)

    player utterance
      -> Core parser and optional local candidate hooks
      -> Hoomans candidate eligibility
      -> existing Policy.Decide safety/intent branch
           + flow Preview (separate diagnostic/transition path)
      -> existing branch-driven LocalResponse.Resolve
      -> ResponsePlan.Attach(after selecting reply)
      -> existing presentation/translation/command adapter
      -> optional flow Commit + server-side authoritative actions

Flow state and candidate data exist but have **not yet replaced central behavior selection**. The new target does not duplicate the parser, the state store or server action authorization.

## Corrected target pipeline

    real in-game utterance
      -> Core IR/candidate interpretation (compatible published dependency)
      -> eligibility and server-authority safety gates
      -> registered flow transition/response-plan **decision**
      -> existing conditioned catalog for selected pool/variant
      -> localized, bounded multi-act realization if requested
      -> existing real game speech queue / UI
      -> authorized gameplay request only through current authoritative domain

Non-flow or unmigrated game actions may continue through the legacy policy adapter; never silently route mutating commands from a flow solely by matching text. Require an explicit migration and shadow-trace parity before retiring legacy branches.

## Ownership and compatibility

- PsychopatzCore owns parser, IR v1, reusable bounded candidate/router hooks, and generic optional manifest loader. Synchronize **installed dependency and published dependency** with Hoomans; no accidental Hoomans-only copy of Core.
- Project Hoomans owns candidate eligibility, semantic flow registry/kernel, world/relationship context, response selection, actual NPC UI/presentation and server command adapters.
- Translation shards belong to Hoomans; loader is Core; other pre-existing legacy systems and native PZ Translate stay unchanged.
- MarketSense remains item classification authority. PBrainZ remains optional phrasing/retrieval; deterministic offline controls actual branch and effects.
- Preserve player/NPC IDs, flow isolation, IR/response/network/save compatibility, existing pending identity safety regression and server identity/task/inventory/MP replay checks.

## Key gate: behavioral flow ownership

A new flow declares triggers, frame eligibility, node transitions, conditioned response-pool references and optional typed dialogue acts. After safety checks, **selected flow result** controls which response is selected and which safe follow-up is awaited. The legacy intent branch is used only if there is no applicable flow, a flow fails safely, or an unmigrated authoritative action requires legacy handling. No per-flow `elseif` in the central branch/resolver.

Flow previews remain pure; committed state changes only once per accepted turn. No flow directly mutates trust, requests tasks or assumes an LLM. Bounded per speaker/addressee with defined interrupt, resume, expiry and cancel semantics.

## Native runtime observability

Expose opt-in low-volume in-game diagnostics: input/IR, selected candidate, flow ID/node/transition, selected pool/template, localized text key, action request, per-speaker state and server result. Redact or bound user content, keep disabled in production by default. The Semantic Lab may consume **identical production trace fields** but cannot manufacture behavior for tests.

Avoid tick-time scans, repeated translation IO or full WordNet runtime expansion.
