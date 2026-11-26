# Emergent Social Dialogue & Actor-Agnostic Choices

## Purpose

Project Hoomans' dialogue system is designed to breed **organic friendships, rivalries, and social conflicts** from everyday conversations—such as world gossip, broadcasts, camp breaks, and tactical disagreements—without hardcoding linear questlines.

The architecture unifies three proven emergent-narrative patterns directly onto Project Hoomans' existing social and relationship foundations:

1. **Actor-Agnostic Shared Choices (Versu model):** Every `choice` block in a `.convo` `story` or `blueprint` is shared by both **players** (rendered as interactive dialogue choices) and **autonomous NPCs** (scored and selected by `OfferRealizer.PickAutonomous`). Zero duplicate authoring is required for Player↔NPC vs NPC↔NPC dialogue.
2. **Weighted Personality Selection (Crusader Kings 3 `ai_chance` model):** Players read the room and carefully pick choices to earn `approval`, `respect`, and `familiarity`. Autonomous NPCs score the exact same choices using their 7 numeric `SocialProfiles` axes (`compassion`, `sociability`, `forgiveness`, `bravery`, `materialism`, `aggression`, `loyalty`), categorical styles, mood, and existing relationship toward the speaker, then roll deterministically (seeded weighted pick) so choices feel authentic and varied.
3. **Asymmetric Personality Reactions & Conflict Loops (RimWorld model):** Each `reply [when]:` block inside a `choice` owns its own spoken lines, bounded `approval` / `respect` / `familiarity` / `morale` / action `do` effects, and optional nested follow-up `choice` blocks (bonding vs de-escalation vs escalation). The **same line** can delight one personality, earn cold respect from another, or spark an argument with a stressed/aggressive survivor.

---

## Integration With Existing Authorities

This system **does not** create a parallel relationship or trait store. It feeds directly into Project Hoomans' existing systems:

| Authority | Document | Role |
|---|---|---|
| Directed Personal Relationships | [Relationships.md](Relationships.md) | Owns persistent `approval` (`-100..100`), `respect` (`-100..100`), `familiarity` (`0..100`), `morale` (`-100..100`), decaying memories, cooldown/saturation bounds, and `friend` / `rival` / `enemy` hysteresis. |
| Social Profiles & Personality | [SocialProfiles.md](SocialProfiles.md) | Owns `record.social.personality` (`socialStyle` + 7 `[0..1]` numeric axes: `compassion`, `sociability`, `forgiveness`, `bravery`, `materialism`, `aggression`, `loyalty`). |
| NPC Trait Registry | [NPCTraits.md](NPCTraits.md) | Composes dynamic and authored NPC traits into personality axes and category biases. |
| Runtime ConvoDSL & Story Compiler | [ConvoBlocks README](../../Contents/mods/ProjectHoomans/common/media/translation/EN/ConvoBlocks/README.md) | Streams `.convo` files at runtime, compiles `story` graphs into `FlowRegistry` + `ResponseCatalog`, and resolves personality reactions via `ConvoDSL.ResolveReaction`. |

### Why `approval` vs `respect` Breeds Real Drama

Because `Relationships.md` separates **liking (`approval`)** from **regard (`respect`)**:
- **Organic Friendships (`friend`: `approval >= 35` & `respect >= 15`)** grow when compatible personalities agree, share memories, or watch each other's backs.
- **Organic Rivalries (`rival`: `approval <= -25` & `respect >= 25`)** emerge naturally when blunt/tactical and warm/compassionate survivors clash over values (`approval -`) while still acknowledging each other's grit (`respect +`).
- **Organic Enemies (`enemy`: `approval <= -60` & `respect < 10`)** develop when repeated friction escalates unchecked (`double_down` / insults while stressed), eventually feeding faction grievances where authorized.

---

## Actor-Agnostic Choice Scoring (`OfferRealizer.PickAutonomous`)

When an NPC chooses from a story node's `branchOffers` (or blueprint offers):

1. **Eligibility Filter:** Any choice with a `when` predicate (e.g. `[actor.style=tactical]`, `[actor.role=trader]`, `[actor.social_style=protective|friendly]`) is filtered against the choosing NPC's live context.
2. **Base Utility + `ai_bias` Scoring (`OfferRealizer.ScoreOffer`):**
   - Base score uses `utility` (`compassion`, `openness`, `caution`, `assertive`, `deception`, `materialism`, `loyalty`, `forgiveness`).
   - `ai_bias` tags (e.g., `ai_bias=aggression+|bravery+|compassion-|stressed+|rival+`) add signed modifiers for:
     - All 7 personality axes (`compassion`, `sociability`, `forgiveness`, `bravery`, `materialism`, `aggression`, `loyalty`) with `+` or `-`.
     - Live mood (`stressed`, `tired`, `cheerful`, `unhappy`, `in_pain`).
     - Existing relationship toward the speaker (`friend`, `rival`, plus general `relationshipApproval` nudge).
     - Role/style markers (`tactical`, `trader`, `protective`, `guarded`, `warm`).
3. **Selection Mode:**
   - **Seeded Weighted Roll (CK3-style, default when `opts.seed` is supplied):** Cube-sharpens choice scores (`score^3`) and selects deterministically from the seed so NPCs strongly favor personality-aligned choices with natural variance.
   - **Strict Top Pick:** Pass `opts.deterministic = true` (or omit `seed`) to always pick the highest-scoring choice.

---

## Asymmetric Reactions & Nested Conflict/Bonding Branches

Inside a `.convo` `story`, each `reply [when]:` block defines a distinct reaction branch evaluated against the **listening** actor's context via `ConvoDSL.ResolveReaction(storyID, nodeID, listenerContext, opts)`:

```convo
choice negative (intent=DISAGREE, subject=MEDIA_GOSSIP, utility=assertive, ai_bias=aggression+|bravery+|compassion-|stressed+|rival+):
  label: "Push back — waste of power and risky"
  say: "Feels like a waste of power watching old tapes while the world burns."

  reply [actor.style=tactical|cold]:
    "Finally someone thinking straight. Power's too precious for reruns."
    do relationship.respect +3
    do relationship.approval +1
    do guard_perimeter
    end

  reply [actor.style=aggressive|hostile, mood.stressed]:
    "Nobody asked for a lecture, {term.address}. Mind your own watch."
    do relationship.approval -4
    do relationship.respect -1
    do morale -2

    choice deescalate (intent=APOLOGIZE, subject=SOCIAL, utility=forgiveness, ai_bias=forgiveness+|compassion+):
      label: "Back off — keep the peace"
      say: "Alright, fair enough. Didn't mean to jump down your throat."
      reply [default]:
        "Yeah. Well—just let me breathe for five minutes."
        do relationship.approval +2
        do relationship.respect +1
        end

    choice double_down (intent=INSULT, subject=CONFLICT, utility=assertive, ai_bias=aggression+|bravery+|forgiveness-|rival+):
      label: "Stand your ground"
      say: "If a loud tape gets us overrun, it is my business."
      reply [default]:
        "Unbelievable. Stay out of my way, {term.address}."
        do relationship.approval -5
        do relationship.respect +1
        do morale -3
        end
```

### Runtime Flow (Identical for Player↔NPC and NPC↔NPC)

1. **Opening:** Speaker A delivers a personality-colored opening line from the story's `start` node.
2. **Choice:**
   - If Responder B is a **Player**, the UI displays eligible `branchOffers` from `start`.
   - If Responder B is an **NPC**, `OfferRealizer.PickAutonomous` scores and selects from the exact same `branchOffers`.
3. **Reaction:** `ConvoDSL.ResolveReaction(storyID, targetNodeID, speakerAContext)` resolves Speaker A's personality-matched reply, bounded `do` effects (`memoryBound = true` for relationship/morale mutations so server authority applies decaying memories + cooldowns/saturation), and any reaction-specific `followUpOffers`.
4. **Follow-up (Optional):** If the reaction opened a bonding or conflict sub-branch (e.g., `deescalate` vs `double_down`), Responder B chooses again—continuing organically until a terminal reaction ends the scene or recommends a follow-up story.

---

## Reference Stories

The initial proof-of-concept stories implementing this full loop live in `Contents/mods/ProjectHoomans/common/media/translation/EN/ConvoBlocks/branches/`:
- `story_gossip_media.convo` — TV, skill shows, home VHS, and music broadcasts.
- `story_gossip_radio.convo` — AEBS alerts, military/pastor/cannibal/looter radio (including Trader & Tactical branches).
- `story_gossip_world.convo` — Choppers, alarms, nearby gunfire, and rumors (including Protective watch & conflict escalation branches).

---

## Reactive Beats & Actor-Agnostic State-Remediation Watchers

In addition to interactive `story` graphs, Project Hoomans runs a consolidated, actor-agnostic **State-Mutation & Remediation Watcher** (`server/PNC/Semantics/Beats/PNC_SemanticBeats_StateWatcher.lua` + `PNC_SemanticBeats_DefaultWatchers.lua`) so NPCs react both when a problem starts **and** when it is resolved—equally for **player-led groups** and **autonomous AI-controlled NPC squads**.

### Lifecycle (`inactive → active → armed → remediated`)

1. **Zero per-tick polling:** `Beats.CheckStateWatchers(now)` runs on the existing `CheckEnvironment` cadence (~10s) and reuses TTL-cached `BeatContext.GetWorldWeather`, `BeatContext.GetGroupExposure`, and `BeatContext.ResolveActorStats`.
2. **Actor-agnostic scopes:**
   - `scope = "world"`: global world conditions (e.g. `exposure.weather_cleared`).
   - `scope = "group"`: evaluated per nearby calm group (`Beats.FindCalmGroupsNearPlayer`), covering both player-led squads (using live Build 42 `Moodles`/`CharacterStat`/`isOutside`) and AI-controlled squads (using member squares via `BeatContext.IsActorIndoors`, `conditionStats`, and live weather).
   - `scope = "actor"`: evaluated per live NPC member (e.g. `actor.wound_healed`, `actor.fed_hydrated`, `actor.rested`, `actor.panic_calmed`).
3. **Anti-flicker hysteresis (`minActiveMs`) & TTL (`remediateWindowMs`):**
   - A condition must stay active for at least `minActiveMs` (or emit an onset beat) before arming remediation, preventing doorway-flicker false positives.
   - When the condition clears within `remediateWindowMs`, the watcher emits the configured ConvoDSL relief beat and records a `StoryMoment` via `ConversationDirector.RecordStoryMoment` so later `group_banter` can organically reference it.
4. **Event-driven Thunder & Weather:**
   - `PNC_SemanticBeats_WeatherAndExposure.lua` hooks `Events.OnThunderEvent(x, y, doStrike, doLightning, doRumble)` with zero polling for startled thunderclap and distant rumble reactions, plus data-driven transitions across `blizzard`, `tropical_storm`, `thunderstorm`, `storm`, `rain`, `snow`, `fog`, `wind`, `cold`, and `heat`.

### Adding a New State Watcher

Register declaratively in `PNC_SemanticBeats_DefaultWatchers.lua` (or a feature beat module) instead of creating a bespoke timer/map:

```lua
Beats.RegisterStateWatcher("domain.my_condition", {
    scope = "group",                -- "world" | "group" | "actor"
    priority = 30,
    minActiveMs = 10000,            -- hysteresis before arming remediation
    remediateWindowMs = 600000,     -- max armed age for relief beat
    remediateCooldownMs = 120000,
    sample = function(ctx, now)
        -- Pure read from cached ctx.env / ctx.exposure / ctx.actor / ctx.stats
        local active = ...
        return active, "my_variant", active and "problem_active" or "problem_cleared"
    end,
    remediate = {
        poolID = "semantic.world.exposure.relief", -- or "semantic.needs.relief"
        rolePrefix = "my_relief_role",             -- resolves *_open / *_reply / *_chime
        act = "REACT",
        replyAct = "AGREE",
        storyKind = "my_story_moment",
        storyTopic = "weather_talk",
    },
})
```

### ConvoDSL Authoring & `beats_audit` Debugging

- **Authoring:** Put onset/suggestion lines in `ConvoBlocks/world/world_exposure_suggest.convo` (`semantic.world.exposure.suggest`) and relief lines in `ConvoBlocks/world/world_exposure_relief.convo` (`semantic.world.exposure.relief`) or `ConvoBlocks/needs/needs_relief.convo` (`semantic.needs.relief`) with `[role=<rolePrefix>_open]`, `[role=<rolePrefix>_reply]`, and `[role=<rolePrefix>_chime]`.
- **Debugging (`ProjectHoomans.BeatsAudit`):** Enable `BeatsAudit` to inspect `snapshot` (`convoPools`, `convoPending`, `convoErrors`, `thunderHooked`), `env_state`, `exposure_state`, `watcher_state` (`registered`, `activeCount`, `armed`), `watcher_transition` (`phase=onset|armed|remediated|expired|cleared_unarmed`), and `thunder_event` in `console.txt`.
