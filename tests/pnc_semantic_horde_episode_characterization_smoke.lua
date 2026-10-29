local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
})

PNC = {
    SocialEventHooks = {},
    SocialEventHooksInternal = {
        WorldAgeHours = function() return 1 end,
    },
    Core = {
        Now = function() return 0 end,
        ForEachPlayer = function() end,
        DistanceSq = function(x1, y1, x2, y2)
            local dx, dy = x2 - x1, y2 - y1
            return dx * dx + dy * dy
        end,
    },
    Const = {
        ZOMBIE_TARGET_RADIUS = 12,
    },
    Semantics = {
        SocialReactions = {
            Resolve = function() return nil end,
        },
        SocialContext = {
            ResolveNPCType = function() return "companion" end,
        },
    },
}
PNC.Network = {}
PNC.Registry = {}
PNC.Perception = {}

T.load(
    "ProjectHoomans",
    "server",
    "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_CombatAdapter_Awareness.lua"
)

local Hooks = PNC.SocialEventHooks
local record = {
    id = "npc-b1-horde",
    alive = true,
    x = 10,
    y = 20,
    z = 0,
    runtime = {},
}

local first, firstID, firstPhase = Hooks.ObserveZombieHorde(
    record, 4, 4, 1000, "zombie_observation"
)
T.truthy(first, "first above-threshold observation starts an episode")
T.equal(firstPhase, "started", "first transition is explicitly started")
T.contains(firstID, "social:zombie_horde_encounter:",
    "episode uses the production horde event type")
T.truthy(record.runtime.zombieHordeAwareness.active,
    "episode state is active after start")

local stable, stableReason = Hooks.ObserveZombieHorde(
    record, 4, 4, 9000, "zombie_observation"
)
T.falsy(stable,
    "same stable horde stays silent even long after presentation cooldowns")
T.equal(stableReason, "horde_episode_stable",
    "stable episode is explicitly classified")

local escalated, escalatedID, escalatedPhase = Hooks.ObserveZombieHorde(
    record, 8, 4, 10000, "zombie_observation"
)
T.truthy(escalated, "material pressure-band increase emits a transition")
T.equal(escalatedPhase, "escalated", "increase is explicitly escalated")
T.truthy(escalatedID ~= firstID,
    "escalation has its own event identity")
T.equal(record.runtime.zombieHordeAwareness.episodeID, firstID,
    "escalation remains inside the same encounter episode")

local deescalated, _, deescalatedPhase = Hooks.ObserveZombieHorde(
    record, 5, 4, 11000, "zombie_observation"
)
T.truthy(deescalated, "material pressure-band decrease can emit a transition")
T.equal(deescalatedPhase, "deescalated",
    "decrease is explicitly deescalated")

local cleared, clearReason = Hooks.ObserveZombieHorde(
    record, 0, 4, 12000, "zombie_observation"
)
T.falsy(cleared, "clear transition does not create another speech event")
T.equal(clearReason, "horde_episode_cleared",
    "below-threshold observation explicitly closes the episode")
T.falsy(record.runtime.zombieHordeAwareness.active,
    "episode state becomes inactive on clear")
T.equal(record.runtime.zombieHordeAwareness.episodeID, nil,
    "active episode identity is released on clear")

local later, laterID, laterPhase = Hooks.ObserveZombieHorde(
    record, 4, 4, 20000, "zombie_observation"
)
T.truthy(later, "a later horde after a real clear starts a new episode")
T.equal(laterPhase, "started", "later horde is a new start")
T.truthy(laterID ~= firstID, "new episode receives a new event identity")

local observationSource = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Perception/PNC_ZombieObservation.lua"
)
local followSource = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowHazards.lua"
)
local combatSource = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Combat/CombatTactics/PNC_CombatTactics_ThreatAssessment.lua"
)
T.contains(observationSource, "hooks.ObserveZombieHorde(",
    "canonical zombie observation owns semantic horde transitions")
T.falsy(string.find(followSource, "ObserveZombieHorde", 1, true),
    "follow behavior no longer independently emits semantic horde events")
T.falsy(string.find(combatSource, "ObserveZombieHorde", 1, true),
    "combat threat assessment no longer independently emits semantic horde events")
T.falsy(string.find(observationSource, "getZombieList", 1, true),
    "canonical horde transition owner adds no global zombie scan")

T.finish("pnc_semantic_horde_episode_characterization_smoke")
