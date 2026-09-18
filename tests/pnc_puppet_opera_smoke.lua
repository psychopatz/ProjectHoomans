local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
})

local clock = 1000
local sent = {}
local player
local npc
local record

PNC = {
    Core = {
        Now = function() return clock end,
    },
    Const = {
        MODULE = "ProjectHoomans",
        CMD_PUPPET_OPERA_REQUEST = "PuppetOperaRequest",
        CMD_PUPPET_OPERA_STATE = "PuppetOperaState",
        CMD_PUPPET_OPERA_TRACE = "PuppetOperaTrace",
    },
    Registry = {},
    ServerCommandRouter = {
        CanUseDebug = function() return true end,
        Register = function() return true end,
    },
    BehaviorMoveIntent = {
        RequestMove = function(targetRecord, x, y, z, mode, stopDistance, reason)
            targetRecord.runtime = targetRecord.runtime or {}
            targetRecord.runtime.moveIntent = {
                kind = "move",
                x = x,
                y = y,
                z = z,
                reason = reason,
            }
            return true
        end,
        Hold = function(targetRecord, reason)
            targetRecord.runtime.moveIntent = {
                kind = "hold",
                reason = reason,
            }
            return true
        end,
    },
    Animation = {
        PlayBump = function(targetBody, _, bumpType)
            local modData = targetBody:getModData()
            modData.PNC_BumpRequestedType = bumpType
            modData.PNC_BumpActionLease = true
            targetBody.bumpFinished = true
            return true, "started"
        end,
        ResolveBumpType = function(value) return value end,
        IsBumpActionActive = function() return false end,
        MaintainBump = function() return true, "maintained" end,
        FinishBump = function() return true end,
    },
}

Events = {
    OnTick = { Add = function(callback) Events.tick = callback end },
}

function sendServerCommand(target, module, command, payload)
    sent[#sent + 1] = {
        target = target,
        module = module,
        command = command,
        payload = payload,
    }
end

local function actor(x, y, forwardX, forwardY)
    local value = {
        x = x,
        y = y,
        z = 0,
        forwardX = forwardX,
        forwardY = forwardY,
        modData = {},
        bumpFinished = false,
    }
    function value:getX() return self.x end
    function value:getY() return self.y end
    function value:getZ() return self.z end
    function value:getForwardDirectionX() return self.forwardX end
    function value:getForwardDirectionY() return self.forwardY end
    function value:getModData() return self.modData end
    function value:getVariableBoolean(name)
        return name == "BumpAnimFinished" and self.bumpFinished == true
    end
    function value:isDead() return false end
    function value:getVehicle() return nil end
    function value:isSeatedInVehicle() return false end
    function value:faceLocation(targetX, targetY)
        local dx = targetX - self.x
        local dy = targetY - self.y
        if math.abs(dx) >= math.abs(dy) then
            self.forwardX = dx >= 0 and 1 or -1
            self.forwardY = 0
        else
            self.forwardX = 0
            self.forwardY = dy >= 0 and 1 or -1
        end
    end
    return value
end

player = actor(100.5, 200.5, 0, 1)
function player:getUsername() return "PuppetTester" end
function player:getOnlineID() return 42 end

npc = actor(100.5, 200.5, 0, -1)
function npc:getActionStateName() return self.actionState or "" end
record = { id = "npc1", runtime = {} }
PNC.Registry.Get = function(id)
    return tostring(id) == "npc1" and record or nil
end
PNC.Registry.GetLiveZombie = function(id)
    return tostring(id) == "npc1" and npc or nil
end

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/PuppetOpera/PNC_PuppetOpera_Blueprints.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/PuppetOpera/PNC_PuppetOpera_Anchors.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/PuppetOpera/PNC_PuppetOpera_Trace.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/PuppetOpera/PNC_PuppetOpera.lua"
)

local Opera = PNC.PuppetOpera
local playerNPCKiss = Opera.GetBlueprint("social.kiss_player_npc")
T.truthy(playerNPCKiss, "dedicated player/NPC kiss blueprint missing")
T.equal(playerNPCKiss.actors.actor_1.kind, "local_player",
    "player/NPC scene did not fix actor 1 to the player route")
T.equal(playerNPCKiss.actors.actor_2.kind, "nearby_live_npc",
    "player/NPC scene did not fix actor 2 to the NPC route")
T.equal(playerNPCKiss.beats[1].tracks.actor_1.mode, "emote",
    "social player beat did not use the native emote route")
T.equal(playerNPCKiss.beats[1].tracks.actor_1.emote, "wavehi",
    "social player beat did not use the existing wavehi emote")
T.equal(playerNPCKiss.beats[1].tracks.actor_2.bump, "PNC_WaveHi",
    "social NPC beat did not use the non-combat PNC_WaveHi bridge")
T.truthy(Opera.Blueprints.ValidateRuntime(playerNPCKiss),
    "dedicated player/NPC kiss blueprint failed runtime policy")
local npcNPCKiss = Opera.GetBlueprint("social.kiss_npc_npc")
T.truthy(npcNPCKiss, "dedicated NPC/NPC kiss blueprint missing")
T.equal(npcNPCKiss.actors.actor_1.kind, "nearby_live_npc",
    "NPC/NPC scene did not fix actor 1 to NPC")
T.equal(npcNPCKiss.actors.actor_2.kind, "nearby_live_npc",
    "NPC/NPC scene did not fix actor 2 to NPC")
T.truthy(Opera.Blueprints.ValidateRuntime(npcNPCKiss),
    "dedicated NPC/NPC kiss blueprint failed runtime policy")
local blueprint = Opera.GetBlueprint("social.kiss_test")
T.truthy(blueprint, "kiss blueprint missing")
T.falsy(blueprint.actors.actor_1.kind,
    "actor 1 should remain kind-neutral")
T.falsy(blueprint.actors.actor_2.kind,
    "actor 2 should remain kind-neutral")
T.equal(blueprint.beats[1].tracks.actor_1.byKind.local_player.action,
    "RemoveBush",
    "player route is not the safe native action")
T.equal(blueprint.beats[1].tracks.actor_1.byKind.local_player.anim, "Bob_Shove",
    "player clip is not Bob_Shove")
T.equal(blueprint.beats[1].tracks.actor_1.byKind.local_player.debugDuration, 54,
    "player beat duration was not converted to native action ticks")
T.equal(blueprint.beats[1].tracks.actor_2.byKind.nearby_live_npc.bump,
    "PNC_WaveHi",
    "npc beat did not reuse the proven non-combat Hoomans WaveHi route")
local shoveApproved, shoveReason = Opera.AnimationCapabilities.IsSceneApproved(
    "nearby_live_npc",
    { bump = "PNC_Shove", nonCombat = true }
)
T.falsy(shoveApproved,
    "combat-classified PNC_Shove was incorrectly approved for a live scene")
T.contains(shoveReason, "not_scene_approved",
    "PNC_Shove rejection did not expose its preview-only policy")
local runtimeOK, runtimeReason = Opera.Blueprints.ValidateRuntime(blueprint)
T.truthy(runtimeOK, "default blueprint failed runtime policy: "
    .. tostring(runtimeReason))

local plan = Opera.Anchors.BuildPlan(blueprint, player)
T.truthy(plan, "relative anchor plan failed")
T.truthy(plan.actors.actor_1.x ~= plan.actors.actor_2.x
    or plan.actors.actor_1.y ~= plan.actors.actor_2.y,
    "relative anchors overlap")
T.truthy(plan.actors.actor_1.x ~= math.floor(player.x)
    or plan.actors.actor_1.y ~= math.floor(player.y),
    "player anchor did not move relative to origin")
T.truthy(#Opera.Anchors.GetGridPreview(blueprint) == 2,
    "anchor preview did not expose both anchors")

local trace = Opera.Trace.New(16)
for index = 1, 20 do Opera.Trace.Add(trace, index, "event") end
T.equal(#trace.events, 16, "trace ring was not bounded")
T.equal(trace.events[#trace.events].sequence, 20,
    "trace ring lost its newest event")

T.load(
    "ProjectHoomans",
    "server",
    "PNC/PuppetOpera/PNC_PuppetOpera_Authority.lua"
)

local Authority = Opera.Authority
local preflightAccepted, preflightResult = Authority.HandleRequest(player, {
    action = "preflight",
    blueprintId = "social.kiss_test",
    actors = {
        actor_1 = "__local_player__",
        actor_2 = "npc1",
    },
})
T.truthy(preflightAccepted, "authority rejected a valid preflight request")
T.truthy(preflightResult and preflightResult.preflight
    and preflightResult.preflight.ready,
    "valid preflight did not report the scene as ready")
T.equal(preflightResult.preflight.actors.actor_2.reasonDetail, "ready",
    "valid preflight did not report the NPC as ready")

local customAccepted, customResult = Authority.HandleRequest(player, {
    action = "preflight",
    blueprintId = "social.kiss_test_custom",
    definition = Opera.Blueprints.Get("social.kiss_test"),
    actors = {
        actor_1 = "__local_player__",
        actor_2 = "npc1",
    },
})
T.truthy(customAccepted, "server should normalize an authorized scene-builder draft")
T.equal(customResult.preflight.blueprintId, "social.kiss_test_custom",
    "custom draft should retain its requested id")

npc.actionState = "climbwindow"
preflightAccepted, preflightResult = Authority.HandleRequest(player, {
    action = "preflight",
    blueprintId = "social.kiss_test",
    actors = {
        actor_1 = "__local_player__",
        actor_2 = "npc1",
    },
})
T.truthy(preflightAccepted, "busy-state preflight request was rejected")
T.falsy(preflightResult.preflight.ready,
    "busy NPC was incorrectly reported as ready")
T.equal(preflightResult.preflight.actors.actor_2.reason,
    "npc_action_state_busy",
    "busy NPC readiness reason changed")
T.truthy(string.find(
    preflightResult.preflight.actors.actor_2.reasonDetail,
    "state=climbwindow",
    1,
    true
), "busy preflight did not expose the engine action state")
local busyAccepted, busyReason = Authority.HandleRequest(player, {
    action = "start",
    blueprintId = "social.kiss_test",
    npcID = "npc1",
    actors = {
        actor_1 = "__local_player__",
        actor_2 = "npc1",
    },
    loop = false,
})
T.falsy(busyAccepted, "busy NPC was incorrectly forced into a scene")
T.truthy(string.find(tostring(busyReason), "state=climbwindow", 1, true),
    "busy start rejection did not preserve the action-state detail")
npc.actionState = nil

record.orderSpec = { kind = "camp" }
record.activeJob = "AtCamp"
record.activeBehavior = "AtCamp"
preflightAccepted, preflightResult = Authority.HandleRequest(player, {
    action = "preflight",
    blueprintId = "social.kiss_test",
    actors = {
        actor_1 = "__local_player__",
        actor_2 = "npc1",
    },
})
T.truthy(preflightAccepted, "passive-owner preflight request was rejected")
T.truthy(preflightResult.preflight.actors.actor_2.suspendable,
    "passive NPC was not marked suspendable")
T.equal(preflightResult.preflight.actors.actor_2.overrideOwnerKind, "camp",
    "passive owner kind was not reported")
T.equal(preflightResult.preflight.actors.actor_2.reasonDetail,
    "suspendable:camp",
    "passive preflight did not expose its resumable owner")

local previewAccepted, previewSession = Authority.HandleRequest(player, {
    action = "preview_start",
    blueprintId = "social.kiss_test",
    actors = {
        actor_1 = "__local_player__",
        actor_2 = "npc1",
    },
})
T.truthy(previewAccepted, "placement preview was not accepted")
T.truthy(previewSession and previewSession.previewOnly,
    "placement preview was not marked as preview-only")
player.x = previewSession.actors.actor_1.target.worldX
player.y = previewSession.actors.actor_1.target.worldY
npc.x = previewSession.actors.actor_2.target.worldX
npc.y = previewSession.actors.actor_2.target.worldY
T.truthy(Authority.HandleRequest(player, {
    action = "player_arrived",
    sessionId = previewSession.sessionId,
    revision = previewSession.revision,
}), "preview player arrival was not verified")
Authority.PumpSession(previewSession, clock)
T.equal(previewSession.phase, Opera.Phases.FACING,
    "placement preview did not enter the facing barrier")
player:faceLocation(
    previewSession.actors.actor_2.target.x,
    previewSession.actors.actor_2.target.y
)
T.truthy(Authority.HandleRequest(player, {
    action = "player_facing",
    sessionId = previewSession.sessionId,
    revision = previewSession.revision,
}), "preview player facing was not verified")
Authority.PumpSession(previewSession, clock)
T.equal(previewSession.phase, Opera.Phases.READY,
    "placement preview did not remain ready after facing")
T.equal(previewSession.actors.actor_1.state, "preview_ready",
    "placement preview did not expose its ready state")
T.truthy(Authority.HandleRequest(player, {
    action = "preview_stop",
    sessionId = previewSession.sessionId,
}), "placement preview could not be stopped")
T.falsy(record.runtime.puppetOperaLease,
    "placement preview did not release the NPC session lease")
T.falsy(record.runtime.puppetOperaOverride,
    "placement preview did not release the NPC override")
T.equal(record.activeJob, "AtCamp",
    "placement preview did not restore the passive NPC owner")

local accepted, session = Authority.HandleRequest(player, {
    action = "start",
    blueprintId = "social.kiss_test",
    npcID = "npc1",
    actors = {
        actor_1 = "__local_player__",
        actor_2 = "npc1",
    },
    loop = false,
})
T.truthy(accepted, "authority rejected valid Puppet Opera start")
T.equal(session.phase, Opera.Phases.MOVING, "session did not enter moving")
T.truthy(record.runtime.puppetOperaLease,
    "NPC session lease was not acquired")

player.x = session.actors.actor_1.target.worldX
player.y = session.actors.actor_1.target.worldY
npc.x = session.actors.actor_2.target.worldX
npc.y = session.actors.actor_2.target.worldY

accepted = Authority.HandleRequest(player, {
    action = "player_arrived",
    sessionId = session.sessionId,
    revision = session.revision,
})
T.truthy(accepted, "server did not verify player arrival")
Authority.PumpSession(session, clock)
T.equal(session.phase, Opera.Phases.FACING,
    "arrival barrier did not enter facing")

player:faceLocation(session.actors.actor_2.target.x,
    session.actors.actor_2.target.y)
accepted = Authority.HandleRequest(player, {
    action = "player_facing",
    sessionId = session.sessionId,
    revision = session.revision,
})
T.truthy(accepted, "server did not verify player facing")
Authority.PumpSession(session, clock)
T.equal(session.phase, Opera.Phases.READY,
    "facing barrier did not schedule beat")

clock = session.beatStartAt + 1
Authority.PumpSession(session, clock)
T.equal(session.phase, Opera.Phases.PLAYING,
    "beat scheduler did not enter playing")
clock = session.beatStartAt + 1
Authority.PumpSession(session, clock)

accepted = Authority.HandleRequest(player, {
    action = "player_beat_started",
    sessionId = session.sessionId,
    beatIndex = session.beatIndex,
    revision = session.beatRevision,
})
T.truthy(accepted, "server rejected player beat acknowledgement")
accepted = Authority.HandleRequest(player, {
    action = "player_beat_finished",
    sessionId = session.sessionId,
    beatIndex = session.beatIndex,
    revision = session.beatRevision,
})
T.truthy(accepted, "server rejected player beat completion")
Authority.PumpSession(session, clock)
T.truthy(session.closed, "one-shot session did not close")
T.equal(Authority.LastSnapshots[session.ownerId].phase,
    Opera.Phases.COMPLETED,
    "completed snapshot was not retained")
T.falsy(record.runtime.puppetOperaLease,
    "session lease was not released")
T.truthy(#sent > 0, "singleplayer transport emitted no state")

local sourceFiles = {
    { "shared", "PNC/Core/PuppetOpera/PNC_PuppetOpera_Blueprints.lua" },
    { "shared", "PNC/Core/PuppetOpera/PNC_PuppetOpera_Anchors.lua" },
    { "shared", "PNC/Core/PuppetOpera/PNC_PuppetOpera.lua" },
    { "shared", "PNC/Core/PuppetOpera/PNC_PuppetOpera_Trace.lua" },
    { "server", "PNC/PuppetOpera/PNC_PuppetOpera_Authority.lua" },
    { "server", "PNC/PuppetOpera/PNC_PuppetOpera_OverrideAdapter.lua" },
}
local forbiddenProtectedCall = "p" .. "call"
for _, specification in ipairs(sourceFiles) do
    T.falsy(string.find(
        T.read("ProjectHoomans", specification[1], specification[2]),
        forbiddenProtectedCall,
        1,
        true
    ), "new Puppet Opera code must not use protected calls: "
        .. specification[2])
end

return T.finish("pnc_puppet_opera_smoke")
