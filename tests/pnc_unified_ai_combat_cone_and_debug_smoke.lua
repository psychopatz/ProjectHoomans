local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "common_lua" },
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "client" },
    { "PsychopatzCore", "common" },
})

local now = 10000
Events = {
    OnGameBoot = { Add = function() end },
    OnInitGlobalModData = { Add = function() end },
    EveryTenMinutes = { Add = function() end },
    OnTick = { Add = function() end },
    OnWorldSound = { Add = function() end },
}
isServer = function() return true end
isClient = function() return false end
getText = function(key) return key end

require "PsychopatzCore/Composition/PC_SharedComposition"
PsychopatzCore.RuntimeRole = PsychopatzCore.RuntimeRole or {}
PsychopatzCore.RuntimeRole.AllowsServerCode = function() return true end

local okBus, ShockBus = PsychopatzCore.Require("core.shocking_events", "unified_ai_cone_smoke")
T.truthy(okBus and ShockBus and type(ShockBus.Emit) == "function",
    "ShockingEventBus must resolve for debug smoke")
ShockBus.Reset()

local losCalls = {}
local worldZombies = {}
local records = {}
local liveZombies = {}
local players = {}

local function distSq(x1, y1, x2, y2)
    local dx = (x2 or 0) - (x1 or 0)
    local dy = (y2 or 0) - (y1 or 0)
    return dx * dx + dy * dy
end

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        ZOMBIE_TARGET_RADIUS = 16,
        ROAM_TARGET_RADIUS = 16,
        COMBAT_HORDE_RADIUS = 5.5,
        PERCEPTION_FRAME_MS = 200,
        PERCEPTION_FRAME_MOVE_TOLERANCE = 0.5,
        PERCEPTION_LOS_MAX_CANDIDATES = 4,
        COMBAT_DEBUG_CONE_RADIUS = 14,
        COMBAT_DEBUG_CONE_ANGLE_DEGREES = 110,
        COMBAT_DEBUG_CONE_HALF_ANGLE_DEGREES = 55,
        DEBUG_OVERLAY_RADIUS = 16,
        BODY_TAG_VERSION = 1,
        BODY_SHELL_VERSION = 1,
        BODY_SHELL_OUTFIT = "PNC_Carrier",
        BODY_SHELL_CARRIER_VERSION = 1,
    },
    Core = {
        Now = function() return now end,
        IsAuthority = function() return true end,
        IsServerOnly = function() return false end,
        IsClientOnly = function() return false end,
        DistanceSq = distSq,
        IsManagedNPCBody = function() return false end,
        IsFriendlyPlayer = function() return false end,
        CanTargetNPC = function(att, target) return att and target and att.id ~= target.id end,
        GetAttackDirection = function() return 1, 0 end,
        LogInfo = function() end,
        LogWarn = function() end,
        DeepCopy = function(v)
            if type(v) ~= "table" then return v end
            local out = {}
            for k, val in pairs(v) do
                if type(val) == "table" then
                    local sub = {}
                    for sk, sv in pairs(val) do sub[sk] = sv end
                    out[k] = sub
                else
                    out[k] = val
                end
            end
            return out
        end,
    },
    Registry = {
        Data = records,
        Get = function(id) return records[tostring(id or "")] end,
        GetLiveZombie = function(id) return liveZombies[tostring(id or "")] end,
        IsLiveRecord = function(rec)
            return type(rec) == "table" and rec.alive ~= false
        end,
        ForEachLive = function(fn)
            for _, rec in pairs(records) do
                if rec and rec.alive ~= false then fn(rec) end
            end
        end,
    },
    Relationships = {
        AreNPCsEnemies = function(a, b)
            return type(a) == "table" and type(b) == "table"
                and a.id ~= b.id
                and a.faction ~= b.faction
        end,
    },
    SpatialIndex = {
        QueryZombies = function() return worldZombies end,
        QueryPlayers = function() return players end,
        QueryNPCs = function()
            local out = {}
            for _, rec in pairs(records) do out[#out + 1] = rec end
            return out
        end,
    },
    Perception = {
        Internal = {},
        GetZombieCandidatesAt = function() return worldZombies end,
        CanAttackTarget = function(_, target) return target ~= nil end,
        HasTargetLOS = function(_, target)
            losCalls[#losCalls + 1] = target and target.id or "?"
            return true
        end,
        HasLOSBetween = function() return true end,
        GetAllPlayers = function() return players end,
    },
    BehaviorCommon = { HaltMovement = function() end },
    Tasking = {
        Claims = { GetDiagnostics = function() return { activeCount = 1 } end },
        Queries = {
            BuildBrain = function(id)
                return {
                    activeTaskKind = "Guard",
                    activeBand = "Security",
                    activeSourceDomain = "Combat",
                    claims = { { kind = "position" } },
                    scenarioId = "scenario.guard_gate",
                    autonomyAdId = "ad.watch_perimeter",
                }
            end,
        },
        Commands = {
            Reevaluate = function(id, reason)
                return true, { kind = "Reeval:" .. tostring(reason) }
            end,
        },
    },
    WorkService = {
        ReconcileHandlers = {
            farming = function() end,
            corpse_haul = function() end,
        },
    },
    Network = {
        Internal = { SnapshotParts = {} },
        ClientState = {},
    },
    NetworkSnapshots = {},
}

T.load("ProjectHoomans", "common_lua", "PNC/ReactionPolicy/Registry.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Perception/PNC_PerceptionService.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Perception/PNC_Perception_Frame.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Perception/PNC_Perception/Visibility.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Perception/PNC_Perception/ThreatHistory.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Perception/PNC_Perception/ActorSearch.lua")

-- Override CanSeeWorldObject AFTER Visibility.lua loads so we observe mock LOS calls
PNC.Perception.CanSeeWorldObject = function(_, obj)
    losCalls[#losCalls + 1] = obj and obj.id or "?"
    return true, "clear"
end

-- 1. Combat view-cone pre-filtering, 2.5m peripheral ring, recentThreat bypass, LOS budget
local function mockZombie(id, x, y)
    local md = { PNC_ZombieID = id }
    return {
        id = id,
        isDead = function() return false end,
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return 0 end,
        getModData = function() return md end,
    }
end

local npc1 = {
    id = "npc_1",
    name = "Alice",
    x = 0,
    y = 0,
    z = 0,
    alive = true,
    presenceState = "live",
    perceptionProfileId = "profile.colonist_default",
    runtime = {
        facingDirX = 1,
        facingDirY = 0,
    },
}
records["npc_1"] = npc1

-- Populate 6 behind zombies outside peripheral (>2.5m) plus 2 front zombies + 1 close behind + 1 recentThreat
worldZombies = {}
for i = 1, 6 do
    worldZombies[#worldZombies + 1] = mockZombie("behind_" .. i, -(3 + i), 0)
end
local peripheralZ = mockZombie("periph_back", -2.0, 0)
local recentThreatZ = mockZombie("recent_back", -9.0, 0)
local frontZ1 = mockZombie("front_1", 6.0, 0.5)
local frontZ2 = mockZombie("front_2", 10.0, -0.5)
worldZombies[#worldZombies + 1] = peripheralZ
worldZombies[#worldZombies + 1] = recentThreatZ
worldZombies[#worldZombies + 1] = frontZ1
worldZombies[#worldZombies + 1] = frontZ2
npc1.runtime.recentThreat = { kind = "zombie", id = "recent_back" }

losCalls = {}
local visible = PNC.Perception.GetVisibleZombieEntries(npc1, 16)
T.equal(#visible, 4,
    "expected periph_back, recent_back, front_1, front_2 to pass vision cone despite 6 behind zombies ahead in array")
T.equal(#losCalls, 4,
    "LOS budget must only be charged for cone-passing candidates (no LOS wasted on behind zombies)")
T.truthy((npc1.runtime.perceptionFrame.coneRejectedCount or 0) >= 6,
    "coneRejectedCount must record behind zombies skipped before LOS")

-- Enemy actor search cone check (facing east, behind hostile skipped, front hostile selected)
npc1.isHostile = true
npc1.faction = "raiders"
local behindHostile = {
    id = "npc_behind_hostile",
    alive = true,
    x = -6, y = 0, z = 0,
    isHostile = true, faction = "guards",
}
local frontHostile = {
    id = "npc_front_hostile",
    alive = true,
    x = 8, y = 0, z = 0,
    isHostile = true, faction = "guards",
}
records["npc_behind_hostile"] = behindHostile
records["npc_front_hostile"] = frontHostile
liveZombies["npc_behind_hostile"] = mockZombie("npc_behind_hostile", -6, 0)
liveZombies["npc_front_hostile"] = mockZombie("npc_front_hostile", 8, 0)

local foundNpcEnemy = PNC.Perception.FindNearestEnemyNPC(npc1, 16, nil)
T.equal(foundNpcEnemy and foundNpcEnemy.id, "npc_front_hostile",
    "FindNearestEnemyNPC must prefer in-cone front hostile over behind hostile")

local function mockPlayer(name, oid, x, y)
    return {
        isAlive = function() return true end,
        isDead = function() return false end,
        getOnlineID = function() return oid end,
        getUsername = function() return name end,
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return 0 end,
    }
end

players = {
    mockPlayer("player_behind", 1, -5, 0),
    mockPlayer("player_front", 2, 9, 0),
}
local foundPlayer = PNC.Perception.FindNearestEnemyPlayer(npc1, 16)
T.truthy(foundPlayer and foundPlayer.username == "player_front",
    "FindNearestEnemyPlayer must skip behind player outside cone and select in-cone player")

-- 2. Subsystem pumps in FinishTick (only calls PumpLOSQueue when HasPendingLOS() == true)
PNC.Server = {
    Internal = {
        TimingNow = function() return now end,
    },
}
T.load("ProjectHoomans", "server", "PNC/Server/Server/PNC_Server_SubsystemPumps.lua")
local queuePumps, sweepTimeouts, sweepLeases = 0, 0, 0
local pendingLos = false
local realPerceptionSvc = PNC.PerceptionService
local realHasPending = realPerceptionSvc.HasPendingLOS
realPerceptionSvc.HasPendingLOS = function() return pendingLos end
realPerceptionSvc.PumpLOSQueue = function() queuePumps = queuePumps + 1 end
PNC.DialogueMicroBeatDirector = {
    SweepTimeouts = function() sweepTimeouts = sweepTimeouts + 1 end,
}
PNC.JointSceneLease = {
    SweepExpired = function() sweepLeases = sweepLeases + 1 end,
}
PNC.Server.Internal.FinishTick(now)
T.equal(queuePumps, 0, "FinishTick must skip PumpLOSQueue when HasPendingLOS is false")
T.equal(sweepTimeouts, 1, "FinishTick must sweep dialogue timeouts")
T.equal(sweepLeases, 1, "FinishTick must sweep expired joint scene leases")
pendingLos = true
PNC.Server.Internal.FinishTick(now + 10)
T.equal(queuePumps, 1, "FinishTick must pump LOS queue when HasPendingLOS is true")
realPerceptionSvc.HasPendingLOS = realHasPending
PNC.DialogueMicroBeatDirector = nil
PNC.JointSceneLease = nil

-- 3. Live combat debug cone payload + DebugText overlay lines
T.load("ProjectHoomans", "server", "PNC/Agitation/PNC_AgitationService.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Visuals/PNC_SecondaryChannel.lua")
PNC.PerceptionService.RecordClue(npc1, { kind = "sound", x = 4, y = 2, z = 0, confidence = 0.8 }, now)
local okAg = PNC.AgitationService.ApplyTrigger(npc1, "weapon_draw", "debug_player", now)
T.truthy(okAg, "ApplyTrigger weapon_draw must update NPC agitation")
PNC.SecondaryChannel.SetAlertLevel(npc1, "alert")

T.load("ProjectHoomans", "shared", "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_CombatDebugState_AttackPayload.lua")
local dbgPayload = PNC.Network.Internal.SnapshotParts.BuildCombatDebugAttackPayload({
    record = npc1,
    runtime = npc1.runtime,
    now = now,
    aim = {},
    tactical = {},
    fireLane = {},
    retreat = {},
    defense = {},
    combat = {},
    firearmState = {},
})
T.truthy(type(dbgPayload) == "table", "BuildCombatDebugAttackPayload must return table")
T.equal(dbgPayload.perceptionProfileId, "profile.colonist_default")
T.truthy((tonumber(dbgPayload.coneRadius) or 0) > 0, "live coneRadius must populate from compiled profile")
T.truthy((tonumber(dbgPayload.coneHalfAngleDegrees) or 0) > 0, "live coneHalfAngleDegrees must populate from compiled profile")
T.truthy((tonumber(dbgPayload.peripheralRadius) or 0) >= 2.0, "peripheralRadius must populate")
T.truthy((tonumber(dbgPayload.coneRejectedCount) or 0) >= 6, "coneRejectedCount must project to attack payload")
T.truthy((tonumber(dbgPayload.clueCount) or 0) >= 1, "clueCount must project to client debug overlay")
T.equal(dbgPayload.agitationStage, "wary")
T.equal(dbgPayload.secondaryAlertLevel, "alert")

PNC.NameplateDebug = PNC.NameplateDebug or {}
PNC.NameplateRenderer = {
    Internal = {
        Rounded = function(v)
            if v == nil then return "-" end
            return tostring(math.floor(tonumber(v) * 10 + 0.5) / 10)
        end,
    },
}
T.load("ProjectHoomans", "client", "PNC/UI/Nameplates/NameplateRenderer/PNC_NameplateRenderer_DebugText.lua")
local visionLines = PNC.NameplateRenderer.BuildVisionDebugLines(dbgPayload)
T.equal(#visionLines, 2, "BuildVisionDebugLines must emit VISION and REACT lines")
T.contains(visionLines[1], "VISION profile.colonist_default")
T.contains(visionLines[2], "REACT ag=wary(28)")
local combatLines = PNC.NameplateRenderer.BuildCombatDebugLines(dbgPayload)
local joinedCombat = table.concat(combatLines, "\n")
T.contains(joinedCombat, "VISION profile.colonist_default")
T.contains(joinedCombat, "REACT ag=wary(28)")

-- 4. Unified AI Debug Lab server service actions, snapshot, & Singleplayer local dispatch
T.load("ProjectHoomans", "server", "PNC/ConvoEngine/Social/PNC_JointSceneLeaseService.lua")
T.load("ProjectHoomans", "server", "PNC/ConvoEngine/Social/PNC_DialogueMicroBeatDirector.lua")
T.load("ProjectHoomans", "server", "PNC/Tasking/PNC_UnifiedAIDebugService.lua")

local snap = PNC.UnifiedAIDebugService.BuildSnapshot("npc_1")
T.truthy(snap and snap.selected and snap.selected.id == "npc_1", "BuildSnapshot must return selected NPC detail")
T.equal(snap.selected.perceptionProfileId, "profile.colonist_default")
T.truthy((snap.selected.coneRejectedCount or 0) >= 6, "BuildSnapshot must surface coneRejectedCount")
T.contains(snap.globals.workReconcilers, "farming")

local snapAfterExplosion, stExp = PNC.UnifiedAIDebugService.PerformAction(nil, {
    debugAction = "emit_explosion",
    npcId = "npc_1",
})
T.contains(stExp, "explosion:")
T.truthy((snapAfterExplosion.globals.shockBusStats.emitted or 0) >= 1, "ShockBus emission counter must increment")

local _, stSound = PNC.UnifiedAIDebugService.PerformAction(nil, {
    debugAction = "emit_suspicious_sound",
    npcId = "npc_1",
})
T.contains(stSound, "world_sound:")

local _, stScene = PNC.UnifiedAIDebugService.PerformAction(nil, {
    debugAction = "trigger_copresence",
    npcId = "npc_1",
})
T.contains(stScene, "scene:")

local snapAfterMixin, stMixin = PNC.UnifiedAIDebugService.PerformAction(nil, {
    debugAction = "inject_mixin",
    npcId = "npc_1",
})
T.contains(stMixin, "mixin:")
T.truthy(snapAfterMixin.selected.dialogueSceneId ~= nil, "dialogueSceneId must remain active after low mixin")

-- Verify Singleplayer local dispatch handler in PNC_ClientActions_Debug_State.lua
local receivedUiSnap = nil
PNC.UnifiedAIDebugUI = {
    ReceiveSnapshot = function(s) receivedUiSnap = s end,
}
local debugHandlers = T.load("ProjectHoomans", "client",
    "PNC/Networking/ClientActions/PNC_ClientActions_Debug_State.lua")
T.truthy(type(debugHandlers.unified_ai_debug_action) == "function",
    "PNC_ClientActions_Debug_State must export unified_ai_debug_action")
local okDispatch, reasonDispatch = debugHandlers.unified_ai_debug_action(nil, {
    debugAction = "emit_gunfire",
    npcId = "npc_1",
})
T.truthy(okDispatch, "Singleplayer local dispatch unified_ai_debug_action must succeed")
T.contains(reasonDispatch, "gunfire:")
T.truthy(PNC.Network.ClientState.unifiedAIDebugAuthorized == true,
    "unifiedAIDebugAuthorized must be true after SP dispatch")
T.truthy(PNC.Network.ClientState.unifiedAIDebug ~= nil,
    "ClientState.unifiedAIDebug must be updated after SP dispatch")
T.equal(PNC.Network.ClientState.lastUnifiedAIDebugReceiveAt, now)
T.truthy(receivedUiSnap ~= nil,
    "UnifiedAIDebugUI.ReceiveSnapshot must be invoked on SP dispatch")

local snapCleared, stClear = PNC.UnifiedAIDebugService.PerformAction(nil, {
    debugAction = "clear_npc_ai",
    npcId = "npc_1",
})
T.equal(stClear, "cleared:npc_1")
T.equal(snapCleared.selected.agitationStage, "calm")
T.equal(snapCleared.selected.clueCount, 0)
T.equal(snapCleared.selected.dialogueSceneId, nil)

do
    -- Verify overlay detail mode cycling, thick stroke cones, warning links, and Lab test_warn_allies.
    local thickCalls = 0
    isoToScreenX = function(_, x, y) return (x - y) * 32 end
    isoToScreenY = function(_, x, y, z) return (x + y) * 16 - (z or 0) * 96 end
    getTextManager = function()
        return {
            getFontHeight = function() return 12 end,
            MeasureStringX = function(_, _, text) return #tostring(text or "") * 6 end,
        }
    end
    T.stubClientUI()
    PsychopatzCore = PsychopatzCore or {}
    PsychopatzCore.Settings = {
        Open = function(_, spec)
            local values = {}
            for k, v in pairs((spec and spec.defaults) or {}) do values[k] = v end
            return {
                values = values,
                Get = function(_, k, fb) return values[k] == nil and fb or values[k] end,
                Set = function(_, k, v) values[k] = v end,
            }
        end,
    }
    PNC.Nameplates = PNC.Nameplates or {}
    PNC.Translation = PNC.Translation or { GetKey = function(_, fb) return fb end }
    local drawnText = {}
    PNC.NameplatePresentation = PNC.NameplatePresentation or {}
    PNC.NameplatePresentation.Fonts = PNC.NameplatePresentation.Fonts or { debug = "Small" }
    PNC.NameplatePresentation.DrawOutlinedText = function(_, text)
        drawnText[#drawnText + 1] = tostring(text)
    end
    PNC.NameplateRenderer = PNC.NameplateRenderer or { Internal = {} }
    T.load("ProjectHoomans", "client", "PNC/UI/PNC_Nameplates_Settings.lua")
    T.load("ProjectHoomans", "client", "PNC/UI/PNC_Nameplates_OverlayToggles.lua")
    T.load("ProjectHoomans", "client", "PNC/UI/Nameplates/NameplateRenderer/PNC_NameplateRenderer_WorldPrimitives.lua")
    T.load("ProjectHoomans", "client", "PNC/UI/Nameplates/NameplateRenderer/PNC_NameplateRenderer_DebugText.lua")
    T.load("ProjectHoomans", "client", "PNC/UI/Nameplates/NameplateRenderer/PNC_NameplateRenderer_CombatDebug.lua")
    T.load("ProjectHoomans", "client", "PNC/UI/Nameplates/NameplateRenderer/PNC_NameplateRenderer_CombatDebug_Render.lua")

    local np = PNC.Nameplates
    T.equal(np.GetCombatDebugDetailMode(), "cones", "default combat debug detail mode must be cones")
    T.equal(np.CycleCombatDebugDetailMode(), "compact", "cycle 1 -> compact")
    T.equal(np.CycleCombatDebugDetailMode(), "full", "cycle 2 -> full")
    T.equal(np.CycleCombatDebugDetailMode(), "cones", "cycle 3 -> cones")

    local renderer = PNC.NameplateRenderer
    local origThick = renderer.Internal and renderer.Internal.DrawWorldThickLine
    T.truthy(type(origThick) == "function", "DrawWorldThickLine must be installed")
    renderer.Internal.DrawWorldThickLine = function(...)
        thickCalls = thickCalls + 1
        return origThick(...)
    end

    local textSpyCalls = {}
    local origBuildVision = renderer.BuildVisionDebugLines
    renderer.BuildVisionDebugLines = function(...)
        local out = origBuildVision(...)
        textSpyCalls[#textSpyCalls + 1] = out
        return out
    end

    local lineCalls, shadowLineCalls = 0, 0
    local rectCalls = 0
    local manager = {
        playerIndex = 0, x = 0, y = 0,
        drawLine2 = function(_, _, _, _, _, _, r, g, b)
            lineCalls = lineCalls + 1
            if r == 0 and g == 0 and b == 0 then
                shadowLineCalls = shadowLineCalls + 1
            end
        end,
        drawRect = function() rectCalls = rectCalls + 1 end,
    }
    local function mkZombie(x, y)
        return {
            isDead = function() return false end,
            getX = function() return x end,
            getY = function() return y end,
            getZ = function() return 0 end,
            getForwardDirection = function() return { getX = function() return 1 end, getY = function() return 0 end } end,
        }
    end
    local entryA = {
        uuid = "dbg-a",
        zombie = mkZombie(10, 10),
        snapshot = {
            id = "dbg-a",
            attackMode = true,
            combatDebugState = {
                coneRadius = 12,
                coneHalfAngleDegrees = 55,
                agitationStage = "alerted",
                secondaryAlertLevel = "tense",
                warnedBy = "dbg-b",
                warningLink = {
                    kind = "zombie", role = "recipient", actorId = "dbg-b",
                    x = 14, y = 10, z = 0, at = 1000, expiresAt = 3500,
                },
                target = { kind = "zombie", id = "z1", x = 15, y = 10, z = 0, visible = true },
            },
        },
    }
    local entryB = {
        uuid = "dbg-b",
        zombie = mkZombie(12, 10),
        snapshot = {
            id = "dbg-b",
            combatDebugState = {
                coneRadius = 10,
                coneHalfAngleDegrees = 55,
            },
        },
    }

    -- In "cones" mode with dbg-a selected, only dbg-a gets vision debug text.
    np.SetCombatDebugDetailMode("cones")
    PNC.Network = PNC.Network or {}
    PNC.Network.ClientState = { unifiedAIDebug = { selectedId = "dbg-a" } }
    local settings = { combatDebugDetailMode = np.GetCombatDebugDetailMode() }
    local renderState = { usedLabelRects = {} }
    lineCalls, shadowLineCalls, textSpyCalls, drawnText = 0, 0, {}, {}
    renderer.RenderCombatDebug(manager, entryA, settings, renderState)
    renderer.RenderCombatDebug(manager, entryB, settings, renderState)
    T.truthy(shadowLineCalls > 0 and lineCalls > 40,
        "combat overlay should draw thick dark-backed strokes for cones, rings, and warning link")
    T.equal(#textSpyCalls, 1, "cones mode must render detailed text only for focused NPC")
    T.truthy(rectCalls > 0, "combat text backdrop drawRect must be rendered")

    np.SetCombatDebugDetailMode("full")
    settings.combatDebugDetailMode = "full"
    textSpyCalls = {}
    renderer.RenderCombatDebug(manager, entryA, settings, { usedLabelRects = {} })
    renderer.RenderCombatDebug(manager, entryB, settings, { usedLabelRects = {} })
    T.equal(#textSpyCalls, 2, "full mode draws full debug/vision text for both NPCs")
    np.SetCombatDebugDetailMode("cones")

    -- Verify UnifiedAIDebugService test_warn_allies action triggers warning and telemetry.
    if PNC.Perception and PNC.Perception.PublishAllyThreatWarning then
        local npcA = { id = "dbg-a", name = "Alpha", x = 10, y = 10, z = 0, alive = true, factionID = "survivors", runtime = { facingDirX = 1, facingDirY = 0 } }
        local npcB = { id = "dbg-b", name = "Bravo", x = 12, y = 10, z = 0, alive = true, factionID = "survivors", runtime = {} }
        PNC.Registry = PNC.Registry or { Data = {} }
        PNC.Registry.Data = { ["dbg-a"] = npcA, ["dbg-b"] = npcB }
        PNC.Registry.Get = function(id) return PNC.Registry.Data[tostring(id)] end
        PNC.Registry.ForEachLive = function(cb)
            for _, rec in pairs(PNC.Registry.Data) do cb(rec) end
        end
        PNC.UnifiedAIDebugService = PNC.UnifiedAIDebugService
            or T.load("ProjectHoomans", "server", "PNC/Tasking/PNC_UnifiedAIDebugService.lua")
        local snap, status = PNC.UnifiedAIDebugService.PerformAction(nil, {
            debugAction = "test_warn_allies",
            npcId = "dbg-a",
        })
        T.contains(status, "warn_allies:", "UnifiedAI test_warn_allies must report warned count")
        T.truthy(snap and snap.globals and snap.globals.allyWarningStats,
            "UnifiedAI snapshot must expose allyWarningStats")
    end
end

T.finish("pnc_unified_ai_combat_cone_and_debug_smoke")
