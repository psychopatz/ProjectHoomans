# Project Hoomans NPC Voice Trigger Audit and Integration Plan

**Status:** Research/design plan with the first client trigger slice implemented
**Scope:** Client-side NPC voice playback, with optional client-local world-sound emission
**Date:** 2026-08-28

## Decision summary

The voice system should be an observer of replicated NPC state, not a dependency of the NPC behavior, health, stamina, or incapacitation systems.

The first implementation should have four small layers:

```text
replicated NPC snapshot
        |
        v
client trigger observer  ->  catalog/policy  ->  NPC voice playback
        |
        +-- local-only emitter
        +-- world-sound emitter
```

The existing shared/server code continues to decide that an NPC was hurt, exhausted, incapacitated, or dead. The client observes those state changes and decides whether a sound should be played. This keeps audio side effects out of `PNC_BehaviorSystem`, `PNC_Health`, and `PNC_Stamina`, preventing the behavior graph from becoming coupled to presentation.

The proposed first slice is:

1. Hurt/injury: one voice event per new damage observation, with a conservative fallback when the exact damage cause is not replicated.
2. Effort/movement: an occasional effort voice when the NPC crosses into exhausted stamina while moving, protected by a cooldown.
3. Animation-aware respiratory cues: a 20% identity-seeded chance on a sneeze/cough animation edge, with a cooldown to avoid obnoxious repetition.
4. Incapacitation/fall: one `DeathAlone` vocal when the client observes an NPC become or already be incapacitated, emitted through the world-sound path.
5. Terminal death: a separate one-shot path, because dead records are filtered out of the normal live-presence loop and may be retired quickly.

Conversation and future emotes should call semantic events such as `social.come_on`, not raw `VoiceFemale...` or `VoiceMale...` aliases. The catalog remains the single place that maps semantic intent to a voice suffix and playback policy.

## What is already exposed

### Existing Project Hoomans code

- `PNC_NPCVoice.lua` already preserves the `NotAZombie` descriptor prefix, derives a stable voice profile from identity seed and gender, resolves gendered voice aliases, applies voice type/pitch parameters, and exposes separate local and world playback methods.
- The voice profile is bound from the client presentation path after appearance/equipment application. The audio feature should keep using that binding and must not take ownership of `NotAZombie` suppression.
- `PNC_NetworkSnapshots_DetailedPayloads.lua` already carries identity seed, gender, health state, alive state, recent-damage timing, body health, stamina values/state/ratio, and visual state.
- `PNC_NetworkSnapshots_VisualState.lua` already exposes movement, movement mode, running/crawling state, animation, profile key, and incapacitated visual state.
- `PNC_Stamina.lua` already derives `fresh`, `working`, `winded`, and `exhausted`; the exhausted threshold is a ratio of `0.15` or lower.
- `PNC_Health_Incapacitation.lua` and `PNC_Animation_Downed.lua` already define the semantic and visual downed boundary.
- `PNC_ClientPresenceTick.lua` is the clean client integration seam. After a snapshot has been applied to its body, a trigger observer can inspect the same snapshot without changing the health, behavior, or animation modules.

Relevant source:

- [PNC_NPCVoice.lua](../../Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Audio/PNC_NPCVoice.lua)
- [PNC_ClientPresenceTick.lua](../../Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/PresenceSync/PNC_ClientPresenceTick.lua)
- [PNC_NetworkSnapshots_DetailedPayloads.lua](../../Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_DetailedPayloads.lua)
- [PNC_NetworkSnapshots_VisualState.lua](../../Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_VisualState.lua)
- [PNC_Stamina.lua](../../Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Stamina/PNC_Stamina.lua)
- [PNC_Health_Incapacitation.lua](../../Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Health/PNC_Health/PNC_Health_Incapacitation.lua)
- [PNC_Animation_Downed.lua](../../Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Visuals/PNC_Animation/PNC_Animation_Downed.lua)

### Base Java/Lua audio surface

The Java baseline confirms that the relevant pieces are available to Lua:

- `IsoGameCharacter:playSoundLocal(alias)` plays through the character emitter without directly creating a `WorldSoundManager` event.
- `IsoGameCharacter:addWorldSoundUnlessInvisible(...)` explicitly creates a world sound when the character is not invisible.
- `IsoPlayer:playerVoiceSound(suffix)` is the player convenience wrapper. It resolves the player descriptor voice prefix and calls the vocal emitter, but it is not the generic NPC API we should depend on.
- `CharacterSoundEmitter:playVocals(alias)` exists in Java. The current NPC helper intentionally uses `playSoundLocal(alias)` because it can then apply `CharacterVoiceType` and `CharacterVoicePitch` through the Lua-visible emitter path. A runtime probe should confirm whether direct Lua `playVocals` is needed for any missing vocal behavior; it is not required for the first trigger plan.
- `IsoZombie:playHurtSound()` does not provide a useful human vocal path; it updates zombie hit audio state instead. NPC hurt voices therefore need to be explicit client presentation behavior.
- Base player emotes use a local sound event and track looped sounds in `PlayerEmoteState`. This is useful precedent for future NPC emotes, but the initial injury/effort/downed events should remain one-shot triggers.

The important distinction is:

```text
PlayLocal(alias)  = audible to the local client; no intentional zombie-hearing event
PlayWorld(alias)  = local voice playback + explicit WorldSoundManager event
```

Because this feature is intentionally client-sided, `PlayWorld` affects the local client's world-sound simulation. It will not make a remote multiplayer client hear the vocal or make a server-authoritative zombie react on every client. That would require a later networked sound event and is outside this plan.

## Voice alias reference

The stock generated voice definitions use this shape:

```text
VoiceFemale<suffix>
VoiceMale<suffix>
```

The existing NPC voice profile resolves the gendered prefix and applies its deterministic voice type and pitch. The trigger system should store the suffix only.

### Injury and pain

| Semantic event | Suffix | Initial use |
|---|---|---|
| `injury.bite` | `PainFromBite` | Hurt trigger when bite cause is known |
| `injury.glass_cut` | `PainFromGlassCut` | Glass/window injury |
| `injury.fall_low` | `PainFromFallLow` | Low fall impact |
| `injury.fall_high` | `PainFromFallHigh` | High fall or hard downed impact |
| `injury.blunt` | `PainFromHitBlunt` | Generic hit fallback |
| `injury.wall` | `PainFromRunIntoWall` | Collision/run-into-wall event |
| `injury.scratch` | `PainFromScratch` | Scratch cause when known |
| `injury.lacerate` | `PainFromLacerate` | Laceration cause when known |
| `injury.moodle` | `PainMoodle` | Conservative generic pain fallback |

The current snapshot has damage timing and body-health data, but the exact damage cause is not yet guaranteed to be present as a dedicated field. The first implementation should not guess a bite/scratch/laceration from incomplete data. Use a generic pain suffix until a small `lastDamageKind`-style snapshot field is deliberately added later.

### Social, callout, and future conversation events

| Semantic event | Suffix | Initial use |
|---|---|---|
| `social.come_on` | `LureCmon` | Future NPC dialogue/emote response |
| `social.tsk` | `LureTsk` | Future lure/emote response |
| `social.shout_hey` | `ShoutHey` | Future audible callout |
| `social.whisper_hey` | `WhisperHey` | Future quiet callout |
| `social.whisper_psst` | `WhisperPsst` | Future quiet attention call |
| `social.megaphone_hey` | `ShoutMegaphoneHey` | Future megaphone callout |
| `social.megaphone_whisper_hey` | `WhisperMegaphoneHey` | Future megaphone whisper |
| `social.megaphone_whisper_psst` | `WhisperMegaphonePsst` | Future megaphone whisper |

`LureCmon` is recorded now because it is the intended “come on” example, but it should not be wired into the initial hurt/effort/downed slice.

### Effort and movement

| Semantic event | Suffix | Initial use |
|---|---|---|
| `effort.exhausted` | `Exercise` | Occasional low-stamina effort vocal while moving |
| `effort.jump_low` | `JumpLow` | Future jump animation event |
| `effort.jump_high` | `JumpHigh` | Future high jump animation event |
| `effort.climb_window` | `ClimbWindow` | Future climb animation event |
| `effort.corpse_low` | `CorpseLowEffort` | Only when dragging a corpse |
| `effort.corpse_high` | `CorpseHighEffort` | Only for high-effort corpse dragging |

`CorpseLowEffort` and `CorpseHighEffort` should not be used as generic tired-NPC voices; their names indicate a specific corpse-dragging context. `Exercise` is the safer initial stock alias for a generic exhaustion vocal.

### Death, respiratory, and action sounds

| Semantic event | Suffix | Initial use |
|---|---|---|
| `death.alone` | `DeathAlone` | Future terminal death fallback |
| `death.eaten` | `DeathEaten` | Future death-by-eating context |
| `death.fall` | `DeathFall` | Reserve for a true fatal fall/death animation |
| `respiratory.cough` | `Cough` | 20% animation-edge cough cue |
| `respiratory.sneeze_light` | `SneezeLight` | 20% animation-edge sneeze cue |
| `respiratory.sneeze_heavy` | `SneezeHeavy` | Future heavy sneeze trigger |
| `respiratory.muffled_cough` | `MuffledCough` | Future muffled cough trigger |
| `action.bandage` | `ApplyBandage` | 80% NPC treatment vocal when bandaging starts |
| `action.vomit` | `Vomit` | Future illness/action trigger |
| `action.sleep` | `Sleep` | Vocal once when a sleep animation begins |
| `action.sigh` | `Sigh` | Future mood/conversation trigger |

The generated definitions are the source of truth for whether a suffix is available in the installed game version. The checked installation includes female and male definitions under:

- `projectzomboid/media/scripts/generated/sounds/player/sounds_player_voice_female.txt`
- `projectzomboid/media/scripts/generated/sounds/player/sounds_player_voice_male.txt`

## Proposed module boundaries

### 1. `PNC_NPCVoice.lua`: playback and identity

Keep this module focused on:

- preserving `NotAZombie` through the existing suppression path;
- deriving and caching a deterministic gendered profile from identity seed;
- resolving a suffix to the correct gendered alias;
- applying voice type/pitch parameters;
- `PlayLocal`, `PlayWorld`, and `Stop`.

It should not know what “hurt,” “exhausted,” or “incapacitated” means.

### 2. `PNC_NPCVoiceCatalog.lua`: data-only policy

Add a small data module containing semantic event IDs and policy fields:

```lua
{
    id = "effort.exhausted",
    suffix = "Exercise",
    mode = "local",
    cooldown = 3.0,
}
```

The catalog may later hold alternate suffixes, gender/style restrictions, volume, radius, and world-sound settings. It should not inspect bodies or snapshots.

State-trigger policies use the same catalog without embedding state names or
probabilities in the observer. Match fields can address any snapshot value
with dotted paths, so the same evaluator can later cover actions, moods,
movement, or animation scenes:

```lua
{
    id = "animation.sneeze",
    eventID = "respiratory.sneeze_light",
    match = {
        fields = {
            "visualState.anim",
            "visualState.sceneBump",
            "visualState.specialAnim",
        },
        values = { "sneeze" },
        mode = "contains",
    },
    chancePercent = 20,
    cooldown = 5.0,
}
```

`match.fields`, `match.values`, `match.mode`, `chancePercent`, and
`cooldown` are all replaceable per rule. A missing `chancePercent` means
always eligible, `0` disables that rule, and multiple rules are evaluated in
catalog order with the first matching rule owning the state edge. The current
catalog uses this same generic rule shape for the 80% bandage cue and the
sleep cue; the latter intentionally has no percentage, so it fires once per
sleep occurrence.

### 3. `PNC_NPCVoiceTriggers.lua`: client observer and deduplication

This module should:

- receive a snapshot, body, replica flag, and current time;
- maintain transient per-NPC/per-body edge state;
- detect transitions and meaningful changes;
- apply cooldowns and priority rules;
- call the catalog event through `PNC_NPCVoice`.

Suggested transient state:

```lua
{
    lastAlive = true,
    lastHealthState = "normal",
    lastRecentDamageUntil = nil,
    lastBodyHealthSignature = nil,
    lastStaminaState = "fresh",
    lastMoving = false,
    lastEffortAt = -math.huge,
    lastDamageAt = -math.huge,
    lastDownedAt = -math.huge,
    lastRespiratoryAt = -math.huge,
    lastRespiratoryKey = nil,
}
```

Key this state by stable NPC identity or snapshot ID, and clear it when the body is removed/replaced. Do not put cooldown timestamps in persistent NPC `ModData`; they are presentation state and would create unnecessary persistence/network coupling.

### 4. One client adapter call

Require the trigger module once from client composition, then call it from `PNC_ClientPresenceTick.OnTick()` immediately after `applySnapshotToBody(snapshot, body, remoteReplica)`.

That location is important: `applySnapshotToBody` can return early after action-motion presentation. Calling the observer after the whole function means audio is not accidentally skipped by an animation branch, while still using the same body that was just resolved and presented.

Do not call the trigger module from:

- `PNC_BehaviorSystem`;
- `PNC_Behavior_Incapacitated`;
- `PNC_Health_*`;
- `PNC_Stamina*`;
- `PNC_LiveBodyControl_Audio`.

Those modules own authoritative state, downed movement, stamina calculation, and zombie-sound suppression respectively. Making any of them play voice would introduce side effects in the wrong lifecycle and would make client-only behavior difficult to isolate.

## Trigger behavior for the first slice

### Hurt/injury

Observe a new `recentDamageUntil` value and/or a changed body-health signature. Fire once per damage observation, then suppress repeats while the same snapshot is being presented.

Initial policy:

```text
new damage observation
    -> generic pain alias when cause is unknown
    -> PlayLocal
```

If a future snapshot field explicitly identifies the cause, the catalog can select `PainFromBite`, `PainFromScratch`, `PainFromLacerate`, `PainFromGlassCut`, or the fall variants without changing the observer structure.

The hurt event should normally be local-only. If a hit causes incapacitation, the separate downed-impact event handles the world-sound case so a single injury does not emit two competing world sounds.

### Low-stamina effort and movement

Observe the transition into `staminaState == "exhausted"` or a ratio crossing the exhausted threshold. Require meaningful movement from visual state (`moving`, running, crawling, or an active movement profile) before playing the effort event.

Initial policy:

```text
fresh/working/winded -> exhausted while moving
    -> Exercise
    -> PlayLocal
    -> cooldown of roughly 3 seconds
```

This is intentionally edge-triggered. It must not play once per stamina update or once per presence snapshot. A later configuration can make selected effort events world-audible, but the initial low-stamina vocal should be local to avoid creating excessive zombie-attracting noise.

### Animation-aware respiratory cues

`PNC_NetworkSnapshots_VisualState.BuildVisualState` publishes the active
animation scene as `visualState.anim` and `visualState.sceneBump`. The idle
sneeze scene therefore arrives as `Sneeze` in both fields while its step is
active. The observer checks those active fields instead of relying only on
the scene ID, because a scene can remain allocated during a short step gap.

```text
active Sneeze/Cough animation edge
    -> identity-seeded 20% roll per scene occurrence
    -> SneezeLight or Cough
    -> PlayLocal
    -> 5 second respiratory cooldown
```

The occurrence key includes scene revision, playback revision, step ID, and
step start time. This makes repeated snapshots of one animation silent while
allowing later animation occurrences to roll again. The seed and occurrence
are used together, so each NPC gets varied results without using a global
random stream or making the cue permanently on/off for that NPC. These cues
remain local-only and do not create zombie-hearing world events.

### Incapacitation and fall

Observe `healthState` changing from a live state to `incapacitated`. Fire one downed-impact event even if the incapacitated behavior continues to tick for a long time.

Recommended semantic separation:

```text
downed impact       -> DeathAlone; world mode
fatal fall/death    -> DeathFall; only when the terminal cause is known
ordinary death      -> DeathAlone; world mode only if desired
```

The current snapshot reliably exposes the incapacitated state, but it does not yet guarantee a dedicated incapacitation cause. The current requested policy maps that state to `DeathAlone`; keep `DeathFall` available for a future cause-specific fall event only after the cause is deliberately replicated.

Start with conservative world-sound values in the catalog, for example a small radius and volume suitable for a nearby impact. Keep these values data-driven so balancing does not touch the trigger logic. Use `stressHumans = false` unless the design later requires human stress propagation.

### Terminal death

Treat death as a separate lifecycle event. The normal presence loop skips `alive == false` records, and `Health.Kill` can release/retire the record, so a trigger that only runs after live presentation can miss the terminal transition.

Add a small client lifecycle adapter at the same presence/reconciliation layer that observes the dead/removal marker before the body is discarded. It should call the trigger observer’s terminal event once, then clean transient state. Do not add a callback from shared `Health.Kill` into client audio.

## Local versus world playback contract

The playback API should make the distinction impossible to overlook:

```lua
NPCVoice.PlayLocal(npc, "Exercise")
NPCVoice.PlayWorld(npc, "DeathAlone", {
    radius = 16,
    volume = 18,
    stressHumans = false,
})
```

The trigger policy chooses the mode; the low-level voice module performs it. A world event should be one explicit call that combines the local vocal and the client-local `WorldSoundManager` notification. The observer must never call `addWorldSoundUnlessInvisible` directly.

This preserves the `NotAZombie` behavior: stock zombie voice suppression remains in `PNC_LiveBodyControl_Audio.lua`, while NPC voice playback uses the existing humanized body voice lane. The new trigger modules should not alter descriptor prefixes or stock zombie sound suppression.

## Why this avoids spaghetti coupling

The dependency direction stays one-way:

```text
shared state/snapshots  ->  client observer  ->  catalog + playback
```

There is no dependency from health/stamina/behavior back into audio, no audio logic in movement control, and no conversation dependency on raw engine alias names. Adding a future event such as `social.come_on`, a cough, or a bandage grunt becomes a catalog entry plus one observer rule or explicit conversation call rather than another branch spread across NPC behavior files.

The architecture audit identified the client composition and presentation areas as already high-fanout/cycle-sensitive. The safest change is therefore one client composition load and one presence-tick adapter call, with the actual policy and state machine isolated under `client/PNC/Audio/`.

## Implementation sequence

1. Add the data-only catalog and semantic event IDs.
2. Add the client trigger observer with edge detection and cooldowns.
3. Add the single post-presentation observer call in `PNC_ClientPresenceTick`.
4. Add the terminal-death observation at the client lifecycle/removal seam.
5. Run pure Lua tests against fake snapshots for repeated snapshots, state transitions, cooldowns, body replacement, and death cleanup.
6. Run an in-game emitter probe to verify the installed aliases, voice parameters, local playback, and the separate world-sound path.
7. Tune radius, volume, cooldown, and alias policy only after the event flow is stable.

The design was recorded before wiring; the implementation status is listed
below.

The first slice described above is now implemented in:

- `PNC_NPCVoiceCatalog.lua` for semantic event policy;
- `PNC_NPCVoiceTriggers.lua` for client-side transition detection, cooldowns, and local/world dispatch;
- `PNC_ClientPresenceTick.lua` for the post-presentation observer seam;
- `PNC_ClientRosterCommands.lua` for the terminal death command seam;
- `PNC_ClientComposition.lua` for deterministic client load order;
- `PNC_BandageAction.lua` for the player-to-NPC treatment vocal.

The observer also recognizes the replicated `treatmentState.phase == "bandaging"`
edge for NPC self-treatment. An NPC that is first observed already
incapacitated now receives the same `DeathAlone` world event, so an initial
snapshot cannot silently bypass the incapacitation trigger.

Animation-aware cues are also implemented through generic catalog rules. The
current entries map active `Sneeze`, `Cough`, bandage, and sleep states to
local aliases, but future sound triggers can be added by registering another
rule with its own matcher, chance, cooldown, and semantic event ID. Direct
semantic calls such as player-to-NPC bandaging use the same catalog chance
policy, so the 80% rule is consistent across both paths.

Conversation/emote callers remain intentionally unmodified. They can use
`PNC.NPCVoice.Triggers.Emit(body, "social.come_on", snapshot)` later.

## Verification notes and limitations

The structural audit used the Project Hoomans graph at generation `2026-08-27` and the deobfuscated Java baseline at generation `2026-08-22`. The relevant requested paths reported no recorded coverage gaps. `PNC_NPCVoice.lua`, `PNC_ClientComposition.lua`, and `PNC_ClientPresenceVisuals_BodyPresentation.lua` have newer filesystem metadata than the graph snapshot, so their checked-out source was treated as authoritative for those details. The Java baseline contains an unrelated parse-partial report in `zombie/core/CreditsName.java`, outside the audio paths used here.

The stock alias list was also checked against the installed generated sound-definition files. Alias availability can change with the installed Project Zomboid build; the runtime probe remains the final authority before wiring a new suffix.

## Source map

### Project Hoomans

- [PNC_BehaviorSystem.lua](../../Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Behaviors/PNC_BehaviorSystem.lua)
- [PNC_Behavior_Incapacitated.lua](../../Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Behaviors/PNC_Behavior_Incapacitated.lua)
- [PNC_Health_Incapacitation.lua](../../Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Health/PNC_Health/PNC_Health_Incapacitation.lua)
- [PNC_Health_Damage.lua](../../Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Health/PNC_Health/PNC_Health_Damage.lua)
- [PNC_Health_Death.lua](../../Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Health/PNC_Health/PNC_Health_Death.lua)
- [PNC_Stamina_Movement.lua](../../Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Stamina/PNC_Stamina_Movement.lua)
- [PNC_LiveBodyControl_Audio.lua](../../Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_Audio.lua)
- [PNC_LiveBodyControl_Maintenance.lua](../../Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_Maintenance.lua)

### Project Zomboid Java baseline

- [IsoPlayer.java](../../../../../../Desktop/Projects/ZomboidDecompiler/output/source/zombie/characters/IsoPlayer.java)
- [IsoGameCharacter.java](../../../../../../Desktop/Projects/ZomboidDecompiler/output/source/zombie/characters/IsoGameCharacter.java)
- [IsoZombie.java](../../../../../../Desktop/Projects/ZomboidDecompiler/output/source/zombie/characters/IsoZombie.java)
- [CharacterSoundEmitter.java](../../../../../../Desktop/Projects/ZomboidDecompiler/output/source/zombie/characters/CharacterSoundEmitter.java)
- [PlayerEmoteState.java](../../../../../../Desktop/Projects/ZomboidDecompiler/output/source/zombie/ai/states/PlayerEmoteState.java)
