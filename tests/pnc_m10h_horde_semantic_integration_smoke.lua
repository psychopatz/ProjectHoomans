local T = require "tests/support/test"
T.addPackagePaths()

local now = 1000
local sceneSpec
local ambientResult
local ambientContext
local reserveCount = 0
local heading = { x = 0, y = -1 }

local player = {
    getX = function() return 100 end,
    getY = function() return 100 end,
    getZ = function() return 0 end,
}

local body = {
    getX = function() return 100 end,
    getY = function() return 100 end,
    getZ = function() return 0 end,
    getForwardDirection = function()
        return {
            getX = function() return heading.x end,
            getY = function() return heading.y end,
        }
    end,
}

local angle240 = math.rad(240)
local centroidX = 100 + math.sin(angle240) * 10
local centroidY = 100 - math.cos(angle240) * 10

PNC = {
    SocialEventHooks = {
        ResolvePlayerKey = function() return "player-one" end,
    },
    SocialEventHooksInternal = {
        WorldAgeHours = function() return 1 end,
    },
    Core = {
        Now = function() return now end,
        ForEachPlayer = function(fn) fn(player) end,
        DistanceSq = function(x1, y1, x2, y2)
            local dx, dy = x2 - x1, y2 - y1
            return dx * dx + dy * dy
        end,
    },
    Const = {
        ZOMBIE_TARGET_RADIUS = 12,
        PRESENCE_LIVE = "LIVE",
    },
    Registry = {
        GetLiveZombie = function(id)
            if tostring(id) == "npc-horde" then return body end
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
            ambientResult = result
            ambientContext = result and result.ambientFlavor
                and result.ambientFlavor.context or nil
            return true
        end,
    },
    Relationships = {
        AddMemory = function() return true end,
    },
    CombatTactics = {
        Internal = {
            BuildZombieThreatCentroid = function()
                return centroidX, centroidY, 8
            end,
        },
    },
    Semantics = {
        CombatEncounterIntent = {
            SetNotifier = function() end,
            OnHordeTransition = function() return true end,
            IsPromptSpeaker = function() return false end,
            MatchesOwner = function() return true end,
            Snapshot = function() return { intent = "undecided" } end,
        },
        CombatReactionProfile = {
            Build = function()
                return {
                    combatReactionStyle = "brave",
                    combatReactionMood = "steady",
                    traits = { pnc_veteran = true },
                }
            end,
        },
        CombatMoment = {
            Build = function(spec)
                return {
                    priority = 80,
                    kind = spec.kind,
                    presentationClass = spec.presentationClass,
                }
            end,
            Snapshot = function(value) return value end,
        },
        CombatBanterArbiter = {
            Reserve = function()
                reserveCount = reserveCount + 1
                return true
            end,
            RecordPresentation = function() end,
        },
        SocialReactions = {
            Resolve = function(spec)
                return {
                    fallback = "Horde nearby. Keep your eyes up.",
                    realizationID = "semantic.test.horde",
                    responsePlanID = "semantic.combat.horde",
                    realizationFamily = "semantic.combat.horde",
                    semanticAct = "REACT",
                    topic = "combat",
                    groundedFactRefs = spec.context.factRefs,
                    offerIDs = {},
                }
            end,
        },
        SocialContext = {
            ResolveNPCType = function() return "companion" end,
        },
        InteractionSceneAdopters = {
            OnHordeTransition = function(_record, spec)
                sceneSpec = spec
                return true
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
    "server",
    "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_CombatAdapter_Awareness.lua"
)

local record = {
    id = "npc-horde",
    alive = true,
    x = 100,
    y = 100,
    z = 0,
    presenceState = "LIVE",
    affiliation = { role = "guard" },
    runtime = {
        zombieObservation = {
            band = "horde",
            nearbyCount = 8,
            hordeCount = 8,
        },
    },
    social = {
        relationships = {
            ["player-one"] = {
                state = "friend",
                approval = 20,
                familiarity = 10,
                memories = {},
            },
        },
    },
}

local emitted, eventID, phase = PNC.SocialEventHooks.ObserveZombieHorde(
    record, 8, 4, now, "zombie_observation"
)
T.truthy(emitted, "production horde observation emits")
T.equal(phase, "started", "production horde transition starts episode")
T.truthy(eventID, "production horde event has stable ID")
T.truthy(sceneSpec, "existing Scene adopter receives authoritative transition")
T.truthy(sceneSpec.spatial, "Scene transition receives tactical spatial snapshot")
T.equal(sceneSpec.spatial.clockToken, "CLOCK_08",
    "Scene transition receives rear-left clock token")
T.equal(sceneSpec.spatial.relativeSector8, "REAR_LEFT",
    "Scene transition receives coarse relative sector")
T.equal(sceneSpec.spatial.presentationMode, "clock",
    "guard/veteran policy selects tactical clock mode")
T.truthy(ambientResult, "existing ambient semantic path still delivers")
T.truthy(ambientContext and ambientContext.tacticalSpatial,
    "ambient semantic context receives tactical spatial snapshot")
T.equal(ambientContext.tacticalSpatial.clockToken,
    sceneSpec.spatial.clockToken,
    "Scene and ambient semantic surfaces share the same canonical clock fact")
T.equal(ambientContext.tacticalSpatial.relativeSector8,
    sceneSpec.spatial.relativeSector8,
    "Scene and ambient semantic surfaces share coarse relation")
T.contains(ambientResult.ambientFlavor.text, "Zombies, 8 o'clock!",
    "ambient semantic realization consumes same clock fact")
T.truthy(reserveCount >= 1,
    "existing banter arbiter remains the presentation admission authority")

local stable, stableReason = PNC.SocialEventHooks.ObserveZombieHorde(
    record, 8, 4, now + 20000, "zombie_observation"
)
T.falsy(stable, "stable horde does not create per-tick tactical chatter")
T.equal(stableReason, "horde_episode_stable",
    "existing episode anti-spam remains authoritative")

T.finish("pnc_m10h_horde_semantic_integration_smoke")
