# Semantic trader and guard conversation audit and plan

Date: 2026-11-10  
Scope: PsychopatzCore, Project Hoomans, DTCommon, DTHoomans, standalone
DTAbstract, and the semantic harness CodeBuilder.

## Decision

Move the conversation mechanism to PsychopatzCore and make DTCommon the single
owner of Dynamic Trading conversation content, landing configuration, and
trade-specific effects. DTHoomans and DTAbstract will consume the same DTCommon
conversation entry point.

The physical/abstract distinction remains a provider presence detail:

- DTHoomans materializes the canonical actor when the player is close enough.
- DTAbstract keeps the same actor and conversation contract without a live body.
- Neither provider owns a semantic parser, response policy, landing page, or
  duplicated dialogue tree.

Guards and traders are roles/capabilities in one actor conversation contract,
not separate conversation engines. The landing page is one Core presentation
surface with role-gated choices and dialogue blocks.

## Audit result

The migration is not complete. It is a partial migration with three layers
already working and two remaining split points.

### Already on the shared path

1. PsychopatzCore owns the reusable semantic machinery:
   - semantic parser, IR, router, dialogue state, and actor conversation service;
   - capability-gated action collection;
   - relationship/capability-gated dialogue-block selection;
   - the Core conversation window and actor-conversation input part.
2. DTCommon already registers a Dynamic Trading pack into the Core semantic
   registry and already uses `PsychopatzActorConversationService` and
   `PsychopatzActorConversationInput`.
3. DTHoomans and DTAbstract both reach DTCommon for the conversation content.
   Their remaining provider-specific work is authorization, transport, and
   presence/projection acquisition.

### Remaining split points

#### 1. DTCommon has a second, handwritten landing system

`DTCommon_TraderConversation.lua` contains a large manual policy and a manual
`nodes.root` choice list. It recreates trade, identity, roster rotation,
destination, origin, news, and goodbye choices instead of collecting the
registered Core semantic actions and selecting registered Core dialogue blocks.

The file is 837 code lines and `Conversation.BuildSpec` is 271 lines in the
static architecture audit. This is the principal Dynamic Trading refactor
hotspot.

The same file also has a narrower semantic-result dispatcher than the pack it
registers. The pack declares trade, referral, and rumors actions, but the
result handler only performs the trade effect. This can make a guard/referral
choice or a semantic trader request appear to do nothing even though the
action is registered.

#### 2. The semantic harness is still Project-Hoomans-specific

The current CodeBuilder is not yet a package-neutral generator:

- ownership normalizes every non-Core owner to `ProjectHoomans`;
- routing only has Core and Hoomans package descriptors;
- generated registry code is hardcoded to `PNC.Semantics.ConversationRegistry`;
- runtime and translation output paths are hardcoded to the Project Hoomans
  package;
- the manifest schema and generated module prefix are PNC-specific;
- the builder generates conversation datasets, but not a DTCommon semantic-pack
  registration artifact or a provider-neutral landing definition.

Changing a DT shard's `source.owner` to `DTCommon` today would silently route
it to Project Hoomans. That is a hard migration blocker, not a cosmetic
tooling issue.

#### 3. Provider bridges still contain conversation-opening policy

The provider bridges should remain as access adapters, but they must converge on
one shared DTCommon post-authorization open coordinator. The previous audit
also found the pending Core actor-projection race. The new landing migration
must not reproduce that race: an accepted request with a pending projection
must resume when Core publishes the canonical actor, rather than failing the
conversation open once.

## Evidence inspected

### Core

- `PsychopatzSemanticPackRegistry` already exposes `CollectActions` and
  `SelectDialogueBlock`, with capability and relationship gate evaluation.
- `PsychopatzActorConversationService` already owns normalized actor context,
  parsing, routing, response planning, state, snapshots, and bounded turns.
- Core conversation UI accepts a standard `start`/`nodes` definition and an
  actor-conversation input extension.

### Project Hoomans

- `PNC_ConversationDefinition_Builder.BuildDefinition` is the current landing
  page pattern used by companion, colonist, and hostile conversation flows.
- `PNC_ConversationComposer_Menu_Root` and the semantic presentation bridge show
  how a stable authored root can be projected into Core's choice surface.
- That builder is Hoomans-specific because it depends on Hoomans relationship,
  hostile-routing, portrait, lifecycle, and authored content services. DTCommon
  must use the pattern, not import this builder or depend on PNC.

### Dynamic Trading

- `DTCommon_SemanticPack.lua` registers the Dynamic Trading concepts, patterns,
  action providers, and relationship-aware blocks in Core.
- `DTCommon_TraderConversation.lua` still owns the duplicated manual landing,
  policy, text, and action dispatch.
- `DTHoomans_Client.lua` and `DTAbstract_CoreConversation.lua` are provider
  entrypoints. They can share the new DTCommon landing without sharing the
  physical/abstract presence implementation.
- Existing conversation tests assert manual `root` array ordering. Those tests
  will need to assert stable semantic IDs, role gates, and provider parity
  instead.

### Static architecture triage

The current scans are evidence for scope, not a reason to perform a broad
refactor:

- Project Hoomans: production health 80.2/100; Semantics pressure 100 and
  Conversation pressure 87.6.
- DynamicTrading: production health 96.9/100; `TraderConversation` is the
  clearest local hotspot, with a large `BuildSpec` and manual responsibility
  density.
- PsychopatzCore: production health 71.2/100; the generic Semantics subsystem
  is comparatively healthy, but Core has unrelated UI/composition cycles.

The implementation should therefore add the smallest generic Core landing
contract and migrate the DTCommon boundary, without pulling unrelated Hoomans
subsystems into Core.

## Target ownership

### PsychopatzCore owns the mechanism

Core should own:

- the semantic IR/parser/router/state lifecycle;
- generic actor conversation service and input widget;
- a provider-neutral landing builder/presenter;
- action collection and dialogue-block selection from registered packs;
- stable choice/session contracts and bounded refresh/async completion seams;
- canonical actor projection readiness notifications used by pending opens.

Core must not own trader text, caravan policy, market data, referral behavior,
or Project Hoomans relationship/hostile rules.

### DTCommon owns the Dynamic Trading domain

DTCommon should own:

- the generated Dynamic Trading semantic pack and dialogue content;
- the shared guard/trader landing configuration;
- role and capability policy (`trader`, `guard`, later any actor with a trade
  capability);
- trade, referral, rumors, identity, route, and roster actions/effects;
- the provider-neutral conversation context adapter;
- the shared post-authorization/pending-projection open coordinator.

The generated artifact may be backed by a small DTCommon runtime adapter for
effects that must call live trade services. That adapter is not a second
conversation engine and must not duplicate generated phrases or choice policy.

### DTHoomans owns presence only

DTHoomans remains responsible for:

- physical actor materialization and proximity rules;
- native body lookup and physical access authorization;
- publishing the canonical actor projection and provider lease;
- calling the shared DTCommon open coordinator after authorization.

It must not provide a second landing, response policy, or semantic pack.

### DTAbstract owns abstract presence only

DTAbstract remains responsible for:

- abstract-world access authorization and transport;
- abstract actor projection and provider state;
- calling the same DTCommon open coordinator.

It must not call Core's conversation UI through a private builder. Its bridge
may remain as a transport file, but its successful result must terminate in the
same DTCommon `BuildSpec`/open path as DTHoomans.

### Project Hoomans remains optional

Project Hoomans may register its native Hoomans opener and physical actor
projection when enabled. DTCommon must not require it. With Hoomans disabled,
DTCommon plus DTAbstract must still open the same Core landing. With Dynamic
Trading disabled, Hoomans' companion/colonist/hostile conversations must still
use Core without DT content being present.

## Planned implementation

## Current implementation status (2026-11-10)

Phase 0 is partially complete: the actor/context, capability, role, presence,
one-landing contract, and resumable pending-projection state are now exercised
by Core and DT conversation tests. Phase 2 has its first vertical slice: Core
provides `ActorLanding`, and DTCommon consumes it for both guards and traders.
Phase 1 remains the next migration because the semantic harness is still
PNC-specific.

The active slice deliberately keeps DTCommon's domain callbacks (trade,
referral, rumors, roster, identity, and route responses) outside Core. Core
only composes registered semantic actions and dialogue blocks into its native
conversation contract.

### Phase 0 — Freeze contracts and baseline the current failure

1. Define the shared actor conversation projection:
   `canonicalActorID`, source ID, role, capabilities, provider, provider
   state, presence mode, actor presentation, roster, knowledge, and context.
2. Define the Core landing contract independently of PNC:
   actor/context input, stable landing ID, greeting block category, collected
   action rows, optional roster rows, extension parts, and effect callbacks.
3. Define pending-open states explicitly:
   `access_pending`, `projection_pending`, `ready`, `opened`, `denied`, and
   `expired`. An accepted request must be resumable while projection is pending.
4. Capture the existing DTCommon behavior and current conversation tests before
   replacing the manual root.

### Phase 1 — Make the semantic harness package-neutral

Extend the existing builder rather than creating a DT-specific generator.

1. Replace the two-owner hardcoding with data-driven package descriptors for at
   least `PsychopatzCore`, `ProjectHoomans`, and `DTCommon`.
2. Parameterize repository resolution, generated module prefix, Lua registry
   namespace, runtime path, and translation path.
3. Add an explicit owner-repository mapping/CLI option for the sibling
   DynamicTrading checkout. Do not infer an absolute path from a developer's
   home directory.
4. Keep Hoomans' combined composition registry as Hoomans composition only;
   write a separate DTCommon registry/manifest under DTCommon. Core-owned
   artifacts must continue to be written to Core, never copied into another
   mod's generated tree.
5. Move the generic compiler schema/naming away from PNC-only names while
   retaining one canonical source format. Do not add a legacy second loader.
6. Add a generated-pack data format for concepts, speech acts, patterns,
   dialogue blocks, landing rows, and effect identifiers. Generated data must
   contain no live provider calls; DTCommon binds effect identifiers to its
   runtime callbacks.
7. Generate DTCommon translations from the same source records. Remove the
   duplicate DTHoomans caravan-referral conversation bundle once the shared
   source is active.

### Phase 2 — Add the generic Core landing builder

Implement a small Core service that produces the normal Core conversation
definition from a domain pack and actor context.

The builder should:

- select a gated greeting block through the Core semantic registry;
- collect capability-gated action rows through `CollectActions`;
- render stable semantic choice IDs, labels, response references, and effects;
- preserve the Core `start`/`nodes`/extension contract;
- support deterministic refresh when knowledge, roster, or projection changes;
- expose a completion callback for projection-pending opens;
- stay usable with no Project Hoomans or Dynamic Trading loaded.

The builder must not call PNC's `BuildDefinition`, PNC relationship services, or
Hoomans hostile routing.

### Phase 3 — Build the DTCommon guard/trader landing

Replace the manual `DTCommon_TraderConversation.BuildSpec` root and duplicated
policy with the Core landing builder and DTCommon generated data.

Use one landing contract with role/capability differences:

| Context | Landing behavior |
| --- | --- |
| trader role | trade, identity, route/origin, rumors/story, roster, goodbye |
| guard role | identity, referral to the trader, route/rumors when available, roster, goodbye |
| any actor with trade capability | trade action is available regardless of provider or body type |
| no trade capability | no trade action; conversation remains usable |

The roster switch is a shared actor utility, not a separate provider landing.
Each member uses the same spec shape with its own canonical actor, role,
portrait/presentation, knowledge, and capabilities.

All typed and button choices must enter the same Core actor-conversation
service. Action dispatch must cover every registered DT action, including
referral and rumors, and return a visible response or explicit unavailable
state rather than silently doing nothing.

### Phase 4 — Collapse provider entrypoints onto DTCommon

1. Keep DTHoomans and DTAbstract access requests and provider-specific server
   checks.
2. Normalize their accepted results into the shared projection contract.
3. Route both through one DTCommon pending-open coordinator.
4. Resume after Core actor projection publication when the projection is not yet
   ready.
5. Remove private provider conversation builders and duplicate semantic text.
6. Preserve the physical/abstract distinction only in provider state and
   materialization behavior.

### Phase 5 — Remove the split implementation

After parity tests pass:

- remove the handwritten DTCommon root choice list;
- remove duplicated DTCommon response branches that are replaced by generated
  dialogue/policy data;
- remove DTHoomans-only shared conversation content;
- reduce `DTCommon_SemanticPack.lua` to generated-pack bootstrap plus live effect
  bindings, or replace it with the generated registration module;
- leave only provider access/presence bridges in DTHoomans and DTAbstract;
- update the tests and documentation so no test treats array order or a private
  provider builder as the contract.

## Validation gates

### Core and harness

- Core-only actor conversation opens with a minimal pack.
- Hoomans-only conversations still load the existing generated content.
- DTCommon-owned source routes to DTCommon, not PNC.
- Core-owned shards route to Core and are not duplicated under DTCommon or PNC.
- Generated registries, manifests, translations, source ownership, and hashes
  are deterministic.
- Kahlua compatibility and generated context-health checks pass.

### DTCommon behavior

- trader and guard landings use the same Core namespace and node contract;
- capability gating hides trade for guards without trade capability;
- referral, rumors, trade, identity, route, roster, and goodbye all have
  observable outcomes;
- a colonist or other future actor can become tradable by capability without a
  new conversation engine or provider-specific landing;
- absent MarketSense data degrades to bounded fallback text rather than
  invalidating the conversation.

### Provider parity

- DTHoomans physical actor and DTAbstract abstract actor produce equivalent
  landing choice IDs for equivalent role/capability context;
- DTHoomans materializes only inside its configured nearby radius;
- DTAbstract never requires a live zombie body;
- both providers use the same canonical actor identity and roster member IDs;
- accepted access followed by delayed projection opens exactly once;
- denied, expired, stale, and duplicate responses do not open a session.

### Toggle matrix

| Project Hoomans | Dynamic Trading | Expected result |
| --- | --- | --- |
| on | on | Hoomans and DTCommon use Core; both DT providers share one landing |
| off | on | DTCommon + DTAbstract still open the same Core landing |
| on | off | Hoomans conversations still work; no DT pack/actions are loaded |
| off | off | Core remains loadable; no optional adopter call fails the base shell |

## Explicit non-goals

- Do not move trader-domain text or market logic into PsychopatzCore.
- Do not make DTCommon depend on Project Hoomans.
- Do not retain a second “legacy” semantic or landing implementation for
  fallback once the migration is validated.
- Do not merge physical materialization into abstract simulation.
- Do not broaden this change into the unrelated Core UI/composition cycles
  reported by the static architecture scan.
- Do not launch Project Zomboid or publish Workshop content as part of the
  developer-side migration; live in-game validation remains a later handoff
  gate.

## Current status

Audit complete; no gameplay code was changed in this audit slice. The next
implementation chunk is Phase 0, followed by the package-neutral CodeBuilder
ownership change. The pending Core projection/open race from
`CONVERSATION_ACCESS_AUDIT_2026-11-10.md` is a required input to Phase 0 rather
than a separate provider-specific fix.
