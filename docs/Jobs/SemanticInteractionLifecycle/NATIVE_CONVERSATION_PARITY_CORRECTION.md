# P10 — Native Conversation Parity Correction

**Opened:** 2026-10-25  
**Status:** ACTIVE — developer acceptance reopened by user-supplied native/harness evidence.  
**Source baseline audited:** ProjectHoomans main at \`7833214e0eb0f52467caa8749b6bc8c5333d1f64\`.  
**Preserve:** accepted P0–P9 semantic lifecycle implementation unless a P10 regression proves a production defect.  
**Native Project Zomboid:** user remains owner of final live acceptance; the supplied native screenshot is valid evidence for the mismatch that reopened developer work.

## Why P10 exists

The P0–P9 implementation passed its recorded automated gates, but the first user-facing harness/native comparison exposed a product-level parity failure that those gates did not prove.

The Semantic Lab currently presents a materially different conversation surface from native Project Zomboid:

- native conversation opens through the production Talk/Conversation definition and staged greeting lifecycle;
- native Core owns one player-facing Response Channel;
- Project Hoomans \`PresentSemanticChoices\` selects the current semantic group and adapts only those rows into Core's presented choices;
- the Semantic Lab currently can render the broader/global semantic candidate projection instead;
- the harness can therefore show many safe/internal candidates that native play does not currently present;
- the harness may show rows that are not actually interactive because its clickability rule is based on worker response type rather than the production presented-choice/session contract;
- the harness Simulation layout can restore old splitter state after ordinary worker operations and can leave a large empty bottom pane after controls are hidden;
- the saved-world browser's useful player-relative role classification can be obscured behind a persisted lens/view selection.

P10 is not a request to rewrite the semantic lifecycle. It corrects the harness so it is trustworthy evidence for the lifecycle already implemented.

## User-supplied native parity fixture

The native screenshot supplied on 2026-10-25 shows a real in-game conversation with Pete Patz.

Observed player-facing state:

~~~text
NPC opening:
Hey. Need a hand before we wrap up?

Response Channel:
1. Tell them to leave the group
2. That's all. Stay safe.
3. What's up?

TYPE TO TALK:
available

CURRENT RELATION:
native relationship quadrant visible
~~~

The corresponding Semantic Lab evidence showed a much broader choice surface, including weather, wellbeing, generic topic, work/order and other candidates simultaneously.

The exact labels above are a state-specific fixture, not a global hard-coded menu. The invariant is that the harness must render whatever production Core would present for the same state, not that every conversation must show those three labels.

## Verified production boundary

Current production source already defines the correct authority seam:

~~~text
Conversation.BuildDefinition
  -> choicePresentation
  -> DialogueInput.Internal.PresentSemanticChoices
  -> buildCoreChoices
  -> Session:setPresentedChoices
  -> native Core Response Channel
~~~

\`buildCoreChoices\` resolves \`projection.currentGroupID\`, finds the selected group, and presents that group's navigation/candidates/capabilities plus the intentional owned-action root additions.

The Semantic Lab must consume this production presentation result. It must not independently flatten the full candidate projection into the main conversation surface.

## P10 architecture rule

> **The Semantic Lab primary Conversation surface is a behavioral mirror of the native production Conversation session. Diagnostics may expose more data, but they must never be confused with player-presented choices.**

For the same source state, conversation revision and production session:

~~~text
Native Core presented choices
             ==
Semantic Lab presented choices
~~~

Equality means the same semantic row identity/frame, group/revision, enabled/disabled state and ordering semantics. Local widget styling does not need to copy the game's green theme.

## Required headless production projection

Add or expose one production-Lua conversation presentation projection suitable for the Semantic Lab.

Conceptually:

~~~lua
{
    schema = "semantic.native_conversation_view.v1",

    talkStart = {...},
    lifecycle = {
        state = "...",
        busy = false,
        closing = false,
    },

    opening = {
        messages = {...},
    },

    relationPresentation = {...},

    responseChannel = {
        revision = 0,
        groupID = "...",
        rows = {
            {
                id = "...",
                text = "...",
                enabled = true,
                semanticFrame = {...},
                source = {...},
            },
        },
    },

    semanticInput = {
        available = true,
    },
}
~~~

This is a presentation projection, not a new gameplay authority.

Python/Tk may render this structure. Python must not recreate \`buildCoreChoices\`, category policy, lifecycle validity or semantic click authority.

## Primary surface versus diagnostics

### Primary Conversation mirror

Must show only production-visible state:

- staged/opening NPC messages;
- current conversation log projection;
- exact current Response Channel rows;
- enabled/disabled state;
- typed semantic input availability;
- current relation presentation summary;
- lifecycle/busy state when needed for truthful interaction.

### Debug/authoring sidecar

May show:

- full safe semantic candidate projection;
- hidden/eligible reasons where privacy permits;
- provider/source diagnostics;
- all semantic groups;
- response plans;
- thread/beat/memory state;
- authority traces;
- persistence/scaling metrics.

A diagnostic candidate must never appear as a player-facing response merely because it exists in the broader projection.

## World Browser correction

The World Browser remains a debug/navigation surface, not a native UI mirror.

However, its useful role classifications must be first-class and discoverable.

Required navigation should make these concepts explicit without requiring the user to remember a persisted combobox lens:

- Relationship / Role:
  - player faction / companions;
  - settlers / communities;
  - hostile / looters;
  - traders / providers;
  - neutral / unaffiliated;
  - other/unknown as needed;
- saved affiliations/factions;
- communities;
- overlays/provider views.

These are alternate projections of authoritative save-backed truth, not duplicated stores.

## Simulation layout correction

The conversation is the primary purpose of the Simulation surface.

Target desktop topology:

~~~text
+--------------------------------------+--------------------+
| conversation / transcript            | context + tools    |
|                                      | NPC                |
|                                      | Player             |
|                                      | Relationship       |
| response channel                     | World              |
|                                      | Faction            |
| type-to-talk                         | Lifecycle / Memory |
+--------------------------------------+ Diagnostics         |
~~~

Requirements:

- conversation gets the dominant vertical area;
- debug/workbench controls move to a right-side dock/notebook or equivalent sidecar;
- hiding a pane releases its allocated space rather than leaving an empty PanedWindow child;
- ordinary worker/configuration operations do not restore an older splitter position over the user's current drag;
- persisted layout is restored at startup/true structural transitions, not after every operation;
- user layout changes are persisted safely/debounced;
- many diagnostic candidates use scroll/grouping rather than expanding the player-facing response channel.

## Suggestion/click parity

The harness must stop using worker response type as the authority for whether a displayed production choice can be clicked.

The production contract already owns:

- current conversation/session;
- current semantic revision;
- selected group;
- semantic frame validity;
- busy/pending state;
- stale detection;
- duplicate receipt detection;
- disabled eligibility;
- rejection and restoration behavior.

The harness should submit the exact production-presented frame through the same worker boundary and display the resulting state.

## P10 ordered chunks

### P10A — Reopen acceptance + freeze parity evidence

**Status:** COMPLETE in documentation/audit.

Required evidence captured:

- user native screenshot with three Response Channel rows and native opening;
- harness screenshot with broader mismatched choices;
- source audit of \`Conversation.BuildDefinition\`, \`PresentSemanticChoices\`, \`buildCoreChoices\`, Semantic Lab suggestion renderer, click gating and splitter restore behavior.

Gate: old READY FOR USER LIVE TEST status is superseded and P10 is active.

### P10B — Headless production Conversation presentation projection

Add the smallest production-owned projection that exposes the same current presentation state Core consumes.

Required:

- Talk/opening state;
- staged NPC opening/messages;
- exact \`buildCoreChoices\`/presented choice rows;
- group/revision;
- enabled state;
- relation presentation;
- semantic-input availability;
- lifecycle/busy state;
- no Python reconstruction.

Gate: worker can answer “what would native Conversation present now?” from production Lua state.

### P10C — Semantic Lab primary conversation uses native projection

Required:

- main response surface renders only production-presented rows;
- global/all-candidate projection moves to diagnostics;
- current group shown truthfully;
- initial save import does not masquerade a generic capability projection as an opened conversation;
- explicit Open/Start Conversation creates the production opening state.

Gate: for a fixed save-backed pair/state, harness main Conversation matches the production projection exactly.

### P10D — Click/session parity

Required:

- exact presented semantic frame is submitted;
- busy rows cannot be clicked;
- disabled rows are visibly disabled;
- stale/duplicate/rejected frames follow production semantics;
- rejected native-style click restores/reprojects the correct response surface;
- no \`response.type in {"turn","semantic_click"}\` shortcut determines semantic validity.

Gate: native and harness use the same production semantic choice/session authority.

### P10E — Opening, close, suspend and resume parity

Required:

- distinguish Load NPC from Open Conversation;
- exercise production Talk start and staged greeting/opening;
- closing/suspending uses the semantic interaction lifecycle;
- resume projects the correct current response channel;
- typed input, emote and semantic choice all resolve against the same active beat/thread.

Gate: lifecycle transitions visible in the harness correspond to production conversation lifecycle rather than scenario refreshes.

### P10F — Simulation desktop UX redesign

Required:

- conversation-first layout;
- right-side context/debug dock;
- no empty lower pane after controls hide;
- no splitter snap-back after settings/worker operations;
- persist real user layout safely;
- response channel remains readable with variable row counts;
- transcript retains useful vertical space at supported desktop sizes.

Gate: repeated real workflow operations do not move the user's layout and the conversation remains the dominant surface.

### P10G — World Browser navigation repair

Required:

- relationship/role classification is explicit and discoverable;
- affiliations, communities and overlays remain available without replacing the role view;
- search works across appropriate projections;
- persisted UI state cannot make core classification appear deleted;
- read-only source-save and P14 rehydration guarantees remain unchanged.

Gate: user can immediately find companions/settlers/hostiles/traders and still inspect saved factions/communities.

### P10H — Native-versus-harness parity acceptance

For the same saved Player/NPC pair and production state, compare:

- Talk route/start;
- opening NPC message semantic/provenance and resolved text where deterministic;
- current Response Channel IDs/text/enabled state/group/revision;
- relationship presentation;
- typed input availability;
- click result and next presented rows;
- close/suspend/resume lifecycle state.

Use production Lua/headless evidence plus user-provided native evidence where native runtime is required.

Gate: Semantic Lab is trustworthy as a headless/debug representation of the conversation the player actually sees.

## Acceptance status rule

P0–P9 remain accepted implementation foundation.

The overall Semantic Interaction Lifecycle goal is **not** READY FOR USER LIVE TEST while P10 is incomplete.

P10 may be extended with additional user-approved subphases before a final goal prompt is generated. Do not treat this document as frozen scope until the user says the planning pass is complete.
