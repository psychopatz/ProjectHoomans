local T = require "tests/support/test"
T.addPackagePaths()

local now = 1000
local sent = {}
local reserveCalls = 0
local heading = { x = 0, y = -1 }
local player = {
    getOnlineID = function() return 77 end,
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}
local body = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    getForwardDirection = function()
        return {
            getX = function() return heading.x end,
            getY = function() return heading.y end,
        }
    end,
}

PNC = {
    Core = {
        Now = function() return now end,
        ForEachPlayer = function(fn) fn(player) end,
    },
    Const = {
        ZOMBIE_TARGET_RADIUS = 12,
        PRESENCE_LIVE = "LIVE",
    },
    PathService = {},
    NavigationRouter = {},
    Equipment = {
        Describe = function()
            return { combatModeResolved = "melee", weaponStatus = "equipped" }
        end,
    },
    Combat = {},
    Registry = {
        GetLiveZombie = function(id)
            if id == "npc-guard" then return body end
            return nil
        end,
        Get = function() return nil end,
    },
    Perception = {
        CanSeeWorldObject = function() return true end,
    },
    Network = {
        SendConversationRelationshipForNPC = function(
            _player, _npcID, _eventType, result
        )
            sent[#sent + 1] = result
            return true
        end,
    },
    Semantics = {
        CombatReactionProfile = {
            Build = function()
                return {
                    traits = { pnc_disciplined_fighter = true },
                    combatReactionStyle = "practical",
                }
            end,
        },
        CombatBanterArbiter = {
            Reserve = function()
                reserveCalls = reserveCalls + 1
                return reserveCalls == 1
            end,
        },
    },
    Translation = {
        GetKey = function(_, fallback) return fallback end,
    },
}
PsychopatzCore = {}
require "PsychopatzCore/Spatial/PsychopatzSpatialRelation"
PNC.ActorFacing = require "PNC/Core/Spatial/PNC_ActorFacing"
PNC.TacticalSpatialProjection =
    require "PNC/Core/Spatial/PNC_TacticalSpatialProjection"
PNC.Semantics.TacticalSpatialLanguage =
    require "PNC/Semantics/PNC_SemanticTacticalSpatialLanguage"

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Behaviors/PNC_Behavior_Common.lua"
)
T.load(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/PNC_SemanticCombatTargetCallouts.lua"
)

local record = {
    id = "npc-guard",
    alive = true,
    x = 0,
    y = 0,
    z = 0,
    presenceState = "LIVE",
    affiliation = { role = "guard" },
    runtime = {},
}
local target = {
    kind = "npc",
    id = "hostile-1",
    x = 10,
    y = 0,
    z = 0,
}

T.truthy(PNC.BehaviorCommon.SetCombatTarget(record, target, "perception"),
    "authoritative target setter accepts hostile human")
T.equal(#sent, 1, "target acquisition emits one semantic callout")
T.contains(sent[1].ambientFlavor.text, "Hostiles at 3 o'clock!",
    "right-side hostile uses observer-relative clock language")
T.equal(
    sent[1].ambientFlavor.context.tacticalSpatial.clockToken,
    "CLOCK_03",
    "semantic callout retains canonical clock token"
)

T.truthy(PNC.BehaviorCommon.SetCombatTarget(record, target, "perception"),
    "stable target write remains valid combat operation")
T.equal(#sent, 1, "stable target write does not emit another transition")

local sourceChanged = PNC.BehaviorCommon.SetCombatTarget(
    record, target, "reassessment"
)
T.truthy(sourceChanged, "source reassessment remains valid")
T.equal(#sent, 1,
    "existing banter cooldown suppresses repeated same-target presentation")
T.truthy(reserveCalls >= 2,
    "semantic anti-spam routes through existing banter arbiter")

T.finish("pnc_m10h_hostile_target_callout_smoke")
