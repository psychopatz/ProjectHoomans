# NPC Trait System

NPC traits are authored through one registry and one effect resolver. A trait
may contribute to several channels at once:

- `personality`: numeric dimensions such as `forgiveness`, `sociability`, or
  `bravery`.
- `categoryBiases`: categorical personality choices such as `socialStyle`.
- `needs`: hunger, thirst, fatigue, and sleep-policy multipliers.
- `conditions`: stress, boredom, and panic rate multipliers.
- `behavior`: bounded decision modifiers such as `continueWorking` or
  `socialInteraction`.
- `combat.firearm`: cached ranged-combat modifiers such as fire cadence,
  aim settling, and hit chance. These are resolved by the authoritative NPC
  combat path; traits do not directly apply damage.
- `combat.melee`: cached normal-strike modifiers such as attack cadence,
  wind-up time, and hit chance. Ground finishers and shoves intentionally use
  their own action rules instead of inheriting ordinary strike accuracy.
- `presentation`: label, description, and icon metadata for knowledge/UI.

The registry intentionally does not consume player-only CharacterTraits such
as `hasfriend`, `hasdad`, or `ismarried`. Those traits describe player
starting-history systems and remain in their existing catalog. NPC traits and
the existing NPC dynamic-trait generator are resolved through the same NPC
effect composition path; no player-trait aliases are imported into it.

## Registering a trait

Register after the shared Project Hoomans composition has loaded:

```lua
local NPCTraits = PNC.API and PNC.API.NPCTraits
if NPCTraits then
    NPCTraits.Register({
        id = "my_mod:kindhearted",
        aliases = { "my_mod_kindhearted" },
        labelKey = "UI_MyMod_Trait_Kindhearted",
        descriptionKey = "UI_MyMod_Trait_Kindhearted_Description",
        iconPath = "media/ui/Traits/my_mod_kindhearted.png",
        source = "my_mod",
        priority = 10,
        excludes = { "pnc_withdrawn" },
        effects = {
            personality = {
                compassion = 0.10,
                forgiveness = 0.08,
            },
            categoryBiases = {
                socialStyle = { friendly = 1.0 },
            },
            needs = {
                fatigue = { awakeMultiplier = 0.90 },
            },
            conditions = {
                stress = {
                    positiveMultiplier = 0.80,
                    negativeMultiplier = 1.10,
                },
            },
            behavior = {
                socialInteraction = 0.15,
            },
            combat = {
                firearm = {
                    fireRateMultiplier = 1.10,
                    aimTimeMultiplier = 0.95,
                    hitChanceBias = 0.03,
                    pressureAccuracyBias = 0.02,
                },
                melee = {
                    attackRateMultiplier = 1.10,
                    windupTimeMultiplier = 0.95,
                    hitChanceBias = 0.03,
                    pressureAccuracyBias = 0.02,
                },
            },
        },
    })
end
```

Assign it to an NPC with `PNC.API.NPCTraits.Set(record, traits)` or include it
in an NPC definition as `npcTraits = { ["my_mod:kindhearted"] = true }`.
The registry normalizes aliases, resolves exclusions deterministically, and
stores an ordered fingerprint for persistence/profile invalidation.

The registry is also the definition source for generated NPC traits. Built-in
generated traits declare `generation = { group = "...", weight = ... }` beside
their effects, so the condition-stat generator does not maintain a second
trait-definition catalog.

Generation groups are registered data as well. The built-in NPC groups are
`nerves`, `tempo`, `constitution`, `fatigue`, `combat_style`, and
`combat_temperament`. The two combat groups intentionally roll independently,
so a generated NPC can combine a fighting style with a temperament and have
both effects compound through the normal resolver.

A mod that needs a new generation slot registers it before registering its
traits:

```lua
local traits = PNC.API.NPCTraits
traits.RegisterGenerationGroup({
    id = "my_mod:occupation_style",
    noneWeight = 80,
    priority = 100,
})
traits.Register({
    id = "my_mod:scavenger",
    labelKey = "UI_MyMod_Trait_Scavenger",
    descriptionKey = "UI_MyMod_Trait_Scavenger_Description",
    source = "my_mod",
    generation = { group = "my_mod:occupation_style", weight = 20 },
    effects = { behavior = { continueWorking = 0.10 } },
})
```

The generator sorts groups and candidates by stable IDs, uses each group's
total weight (including its `noneWeight`), and derives every roll from the
NPC identity seed. Adding a trait to an existing group therefore requires no
core-generator edit and remains deterministic. Invalid groups and weights are
rejected during registration. Authored `dynamicTraits` remain authoritative;
only generated records use the current generation version.

## Composition rules

Numeric personality values are additive and clamped to `[0, 1]`; this is what
allows `friendly + forgiving + brave` to compound without introducing a new
personality type for every combination. Categorical effects are accumulated as
biases and only select a category when the winning bias reaches the authored
threshold. Need and condition effects multiply, which keeps compatible traits
composable while bounded resolver clamps prevent runaway rates.

Sleep is resolved as one policy. The same policy is used for sleep
activation, criticality, wake completion, and fatigue recovery. A trait must
not patch only one of those values.

Firearm multipliers compound multiplicatively. Hit-chance and pressure
accuracy fields are additive percentage-point biases and are clamped by the
combat resolver. `fireRateMultiplier` values above `1.0` fire more frequently;
`aimTimeMultiplier` values below `1.0` settle aim sooner. The current ranged
resolver snapshots these modifiers when an attack starts and performs one
server-authoritative hit roll at the committed hit frame.

Melee rate and wind-up multipliers also compound multiplicatively. Melee hit
chance and pressure accuracy are additive percentage-point biases. Personality
is projected centrally into the cached melee result: aggression contributes a
small commitment accuracy bias, while bravery improves accuracy under pressure.
Only ordinary melee strikes use this accuracy roll; ground finishers and
shoves retain their dedicated action semantics.

## Registry inspector

Debug users can open `NPC TRAIT REGISTRY` from the PsychopatzCore debug hub.
The left panel lists the live registry, including third-party registrations.
Selecting an entry shows its canonical ID, metadata, generation settings,
exclusions, and every composed personality, need, condition, sleep, behavior,
firearm, and melee effect on the right.

## Current rollout

1. Registry/effect resolver and built-in NPC trait definitions.
2. Personality, condition, need, sleep, and fatigue-gate consumers.
3. Persistence/network/knowledge/UI metadata and hover descriptions.
4. Focused smoke tests and Kahlua compatibility checks.
5. NPC ranged firearm cadence, aim, and authoritative accuracy effects.
6. NPC normal-melee cadence, wind-up, and authoritative accuracy effects.
7. Registry-driven generation groups for newly spawned NPCs and mod traits.

Future melee expansion should add damage, stamina, stagger, and weapon-family
modifiers through this same channel. New behavior consumers (social task
scoring, night activity, and work/recreation choice) should continue using
named behavior keys rather than trait-specific branches.
