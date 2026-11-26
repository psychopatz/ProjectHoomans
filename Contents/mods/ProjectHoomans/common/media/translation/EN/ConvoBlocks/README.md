# ConvoBlocks Scripting Guide (`.convo`)

ConvoBlocks is Project Hoomans' zero-Lua dialogue, lexicon, suggestion, and branching story scripting language. All `.convo` files are streamed and parsed directly at runtime by Project Zomboid (no offline compiler required).

---

## 1. Folder Structure & Creating Language / Mod Packs

Place `.convo` files under:

```text
<YourMod>/common/media/translation/<LANG>/ConvoBlocks/
  lexicons/    # Shared vocabulary & reusable clauses (loaded first)
  blueprints/  # Shared semantic reply choice packs (`suggest.*`, `offer.*`)
  needs/       # Per-subject companion needs (`sleep.convo`, `hunger.convo`, ...)
  combat/      # Combat warnings, assists, wounds, horde & kill reactions
  world/       # Ambient, weather, alarms, choppers, broadcasts, progression
  social/      # Greetings, banter, gossip, conflict, identity
  commands/    # Orders, acknowledgments, redundant command reactions
  questions/   # Q&A pools (location, time, whereabouts, wellbeing)
  themes/      # Theme packs & mod compatibility packs
  branches/    # Multi-step nested branching `story` scripts
```

- **Language packs:** Copy any `.convo` files you want to translate into `<LANG>/ConvoBlocks/...` (for example `TL/`, `ES/`, `FR/`). Anything you omit automatically falls back to `EN`.
- **Community expansion mods:** Drop `.convo` files into your own mod's `common/media/translation/<LANG>/ConvoBlocks/` (or even directly into `ConvoBlocks/` root). Any activated mod is discovered automatically — **zero Lua required**.
- **Single-file convenience:** You can put `lexicon`, `blueprint`, `extend`, and `story` blocks together in one file.

---

## 2. File Header

Every `.convo` file starts with:

```text
language EN
namespace hoomans
```

Optional headers for community/theme packs:
- `pack my_pack_id` — namespaces auto-generated variant IDs so your pack never collides with other mods.
- `theme winter_survival` — tags variants with a theme label.

---

## 3. Core Building Blocks

### `lexicon` (Reusable Words & Clauses)
```text
lexicon noun.zombie
  [actor.style=tactical]:   "hostile" | "infected" | "dead"
  [actor.style=aggressive]: "rotter" | "biter" | "walker"
  [default]:                "walker" | "dead" | "biter"
```
Use `{noun.zombie}` in any dialogue line. Modders can add words without overwriting via `extend lexicon noun.zombie`.

### `blueprint` (Reusable Semantic Choice Packs)
```text
blueprint suggest.weather_chat
  choice weather.find_shelter:
    when: [environment.raining]
    label: "Let's get indoors"
    say: "Let's duck inside until this rain lets up."
    intent: SUGGEST
    subject: SHELTER
```
Attach to any `dialogue` or `story` node with `use suggest.weather_chat`. Modders can append choices via `extend blueprint suggest.weather_chat`.

### `dialogue` / `extend` (Response Banks)
```text
dialogue command.follow.redundant
  use offer.redundant_follow_nudges
  say [npc.fed_up, player.rude]:
    "Stop barking at me to follow you—I haven't left your side!"
  say [npc.fed_up]:
    "I heard you the first three times! Look behind you, I'm literally right here!"
  say [default]:
    "I'm already right behind you{end} {?mood.tail}"
```
- **Multi-line variants:** List multiple quoted lines under one `say` header to add alternate wordings without repeating headers.
- **Multi-turn utterances:** Separate sequential turns with ` >> ` (e.g. `"Hey there. >> How are you holding up?"`).
- **Non-destructive mod extensions:** Use `extend <pool_id>` to append variants to an existing pool without overwriting it.

### `story` / `extend story` (Nested Branching Stories)
```text
story convo.camp_rest_break
  trigger intent=SUGGEST, subject=REST
  guard safe_to_talk

  say [mood.tired]:
    "I'm beat, {term.address}. Think we can set up camp here for a bit?"
    "Running on fumes, {term.address}—mind if we hold up here and rest?"

    choice 1 (intent=ACCEPT, subject=REST, tone=warm):
      label: "Sure, let's camp here"
      say: "Alright, take a breather—I'll watch the perimeter."
      reply:
        "Thanks, {term.address}. Setting up for a quick breather."
      do camp
      do relationship.trust +1

      choice 1a [any.injured] (intent=OFFER, subject=MEDICAL):
        label: "Let me check your wounds first"
        say: "Hold still—let me check that wound before you sit."
        reply:
          "Good call, {term.address}. It's been stinging since that last fight."
        do medical.check_wounds
        end

    choice 2 (intent=REFUSE, subject=REST, tone=firm):
      label: "No time, keep moving"
      say: "Can't stop right now. Keep moving."
      reply [default]:
        "Copy that, {term.address}. Staying right behind you."
      do relationship.trust -1
      end
```
- Nest `choice` blocks inside a `choice` **or inside a specific `reply [when]:` block** so follow-up branches (like de-escalation vs doubling down after an argument, or bonding follow-ups) only appear when that personality reaction triggers.
- Put `do`, `recommend`, `goto`, and `end` **indented inside a `reply [when]:` block** so the *exact same* choice produces different relationship/mood/action outcomes for different personalities!
- Add `ai_bias=...` on any `choice` (e.g. `ai_bias=compassion+|sociability+|warm+|friend+` or `ai_bias=aggression+|bravery+|stressed+|rival+`) so autonomous NPCs pick organically from the exact same choices players see.
- Use `gate [environment.raining] -> raining | clear | unknown` for world-state branches.
- Use `recommend <story_id>` on terminal branches to chain into follow-up stories.

#### Example: Actor-Agnostic Personality Reactions & Conflict Escalation
```text
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
    do morale -2

    choice deescalate (intent=APOLOGIZE, subject=SOCIAL, utility=forgiveness, ai_bias=forgiveness+|compassion+):
      label: "Back off — keep the peace"
      say: "Alright, fair enough. Didn't mean to jump down your throat."
      reply [default]:
        "Yeah. Well—just let me breathe for five minutes."
        do relationship.approval +2
        do relationship.respect +1
        end
```
See `docs/Systems/EmergentSocialDialogue.md` for the full Player↔NPC & NPC↔NPC scoring and relationship architecture.

---

## 4. Rule Ordering (No Priorities Needed)

You never need to write `(priority ...)` numbers:
- **Specificity wins first:** `[npc.fed_up, player.rude]` (2 checks) automatically beats `[npc.fed_up]` (1 check), which automatically beats `[default]` (0 checks).
- **Top-to-bottom order breaks ties:** When two different rules have the same number of conditions (like `[mood.panicked]` above `[mood.bored]`), the one written higher in the file wins automatically.
- **Random variety preserved:** Multiple quoted lines under one `say` block (or `|` words in one `lexicon` line) share the exact same score and rotate randomly with anti-repeat.

---

## 5. Variables, Tokens & Filters (`{...}`)

### Built-in Runtime Variables
| Token | Meaning |
| --- | --- |
| `{speaker.name}` | Speaking NPC's name |
| `{addressee.name}` | Listener's name (player or NPC) |
| `{term.address}` | Persona/bond-aware address (`love`, `kiddo`, `partner`, `pal`, or `{addressee.name}`) |
| `{scene.location}` / `{place.name}` | Current room, building, or settlement name |
| `{scene.clock}` | Formatted current in-game time |
| `{claimed.name}` | Name claimed during identity exchange |
| `{state.job}` | NPC's current job/activity |
| `{mention.items}` | Mentioned items list (use with `|list` or `|list_a`) |
| `{role}`, `{destination}`, `{direction}`, `{eta}`, `{content}` | Dynamic Q&A / whereabouts / fact payload values |
| `{end}` | Smart sentence-ending punctuation |

### Token Filters & Optional Tokens
- `{?clause.night_warning}` — Optional token: expands if matched, otherwise cleanly omitted.
- `{noun.zombie|s}` — Pluralize (`walker` → `walkers`).
- `{adj.fight|a}` — Add `a`/`an` (`ugly` → `an ugly`, `rough` → `a rough`).
- `{opener.relief|cap}` — Capitalize first letter.
- `{mention.items|list}` / `{mention.items|list_a}` — Format item lists (`a bandage and canned beans`).

---

## 6. Whitelisted `do` Actions & Effects

Stories can request safe, server-authoritative actions and bounded social effects with zero Lua:

| Directive | Effect |
| --- | --- |
| `do camp` | Ask NPC to set up / hold camp |
| `do follow` | Ask NPC to follow |
| `do stay` | Ask NPC to stay in position |
| `do wait` | Ask NPC to pause / wait |
| `do guard_perimeter` | Ask NPC to guard perimeter |
| `do trade` | Open/initiate trading flow |
| `do give_item` | Initiate item handoff |
| `do medical.check_wounds` | Trigger wound inspection |
| `do medical.bandage` | Trigger bandage application |
| `do relationship.approval +3` (or `-10` .. `+10`) | Bounded approval (liking/warmth) memory delta |
| `do relationship.respect +3` (or `-10` .. `+10`) | Bounded respect (competence/grit) memory delta |
| `do relationship.familiarity +2` (`0` .. `+10`) | Bounded familiarity gain |
| `do morale +3` (or `-10` .. `+10`) | Bounded morale shift |
| `do relationship.trust +1` / `do relationship.warmth +1` | Aliases for `relationship.respect` / `relationship.approval` (`-5` .. `+5`) |
| `do mood.calm` / `do mood.cheerful` / `do mood.stressed` / `do mood.unhappy` | Bounded mood shift |

---

## 7. Available `[condition]` Predicates

Combine multiple conditions with commas (`[mood.tired, environment.night_or_dusk]`), negate booleans with `!` (`[!environment.indoors]`), and match multiple values with `|` (`[actor.social_style=warm|friendly|protective]`).

- **Actor:** `actor.style` (`neutral|supportive|brave|aggressive|shaken|cold|exhausted|tactical|hostile`), `actor.social_style` (`friendly|protective|warm|neutral|guarded|withdrawn|hostile`), `actor.role` (`colonist|companion|trader|guard|looter|bandit|survivor`), `actor.age_band` (`youth|adult|elder`), `actor.injured`, `actor.health`, `actor.activity`, `actor.busy`
- **Personality Bands (`low | mid | high`):** `personality.compassion`, `personality.sociability`, `personality.forgiveness`, `personality.bravery`, `personality.materialism`, `personality.aggression`, `personality.loyalty`
- **Partner & Shared:** `partner.style`, `any.injured`, `any.exhausted`
- **Relationship:** `relationship.tier` (`hostile|wary|stranger|acquaintance|friendly|trusted|ally`), `relationship.state`, `relationship.bond` (`lover|spouse|parent|child|sibling|family|friend|rival|stranger`), `relationship.identity_trust` (`unknown|claimed|trusted|distrusted|untrustworthy`), `relationship.cross_group`
- **Environment & Place:** `environment.night_or_dusk`, `environment.time_band`, `environment.raining`, `environment.foggy`, `environment.snowing`, `environment.indoors`, `place.in_settlement`
- **Mood & Patience:** `mood.primary` (`calm|cheerful|bored|unhappy|hungry|tired|stressed|in_pain|panicked|annoyed|fed_up`), `mood.panicked`, `mood.in_pain`, `mood.stressed`, `mood.tired`, `mood.unhappy`, `mood.bored`, `mood.hungry`, `mood.cheerful`, `npc.annoyance` (`calm|mild|annoyed|fed_up`), `npc.annoyed`, `npc.fed_up`
- **Player Input:** `player.tone` (`neutral|polite|urgent|hostile|casual|skeptical`), `player.rude`, `player.shouting`, `player.polite`
- **State & Orders:** `state.posture` (`standing|sitting|sleeping|resting|crouching`), `state.job`, `state.order_kind` (`none|follow|stay|guard|camp|patrol`), `state.already_following`, `state.sitting`, `state.sleeping`, `state.working`, `command.redundant`, `command.id`, `command.reason`, `command.outcome`
- **Memory, World & Knowledge:** `memory.has_any`, `memory.saved_me`, `memory.fought_together`, `memory.treated_me`, `memory.betrayed`, `knowledge.has_gossip`, `world.power_off`, `world.water_off`, `world.has_event`, `world.food_crisis`, `world.raider_surge`, `world.event_type`
- **Conversation & Group:** `role`, `topic`, `intent`, `subject`, `action`, `conversation.repeat_count`, `conversation.pending_request`, `conversation.previous_topic`, `conversation.previous_action`, `conversation.last_intent`, `conversation.last_speech_act`, `group.size`, `group.broadcast`, `floor.speaker_is_npc`, `floor.interjection_kind`
- **Needs, Combat & Medical:** `need.type`, `need.urgency`, `emotion.type`, `emotion.urgency`, `combat.style`, `combat.mood`, `combat.pressure`, `combat.weapon_family`, `combat.hit_zone`, `combat.wound_type`, `medical.bandage_required`, `medical.bandage_status`, `medical.is_bitten`, `medical.open_wounds`, `medical.knox_exposure`
