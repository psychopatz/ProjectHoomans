local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
})

local emitted = 0
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
            Resolve = function()
                emitted = emitted + 1
                return nil
            end,
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
    id = "npc-b0-horde",
    alive = true,
    x = 10,
    y = 20,
    z = 0,
    runtime = {},
}

local first, firstID = Hooks.ObserveZombieHorde(
    record, 6, 4, 1000, "ambient"
)
T.truthy(first, "first above-threshold observation starts an episode")
T.contains(firstID, "social:zombie_horde_encounter:",
    "episode uses the production horde event type")

local stillActive, activeReason = Hooks.ObserveZombieHorde(
    record, 6, 4, 2000, "combat"
)
T.falsy(stillActive, "nearby repeat is suppressed")
T.equal(activeReason, "horde_episode_active",
    "nearby repeat uses the short timing window")

local below, belowReason = Hooks.ObserveZombieHorde(
    record, 0, 4, 2500, "ambient"
)
T.falsy(below, "below-threshold observation does not emit")
T.equal(belowReason, "below_horde_threshold",
    "below-threshold observation returns before clearing episode state")
T.truthy(
    record.runtime.zombieHordeAwareness
        and record.runtime.zombieHordeAwareness.lastDetectedAt == 2000,
    "B0 regression: below-threshold observation does not close episode"
)

local repeated, repeatedID = Hooks.ObserveZombieHorde(
    record, 6, 4, 5501, "follow"
)
T.truthy(repeated,
    "B0 regression: same still-present horde reopens after timing gap")
T.truthy(repeatedID ~= firstID,
    "reopened stable horde receives a new event identity")

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
T.contains(observationSource, "if cached.tacticalHorde then",
    "ambient owner calls horde observer only for tactical horde")
T.contains(followSource,
    "if (tonumber(count) or 0) < (tonumber(threshold) or 3) then",
    "follow owner returns before calling horde observer below threshold")
T.contains(combatSource,
    "if (tonumber(count) or 0) < threshold then return end",
    "combat owner returns before calling horde observer below threshold")

T.finish("pnc_semantic_horde_episode_characterization_smoke")
