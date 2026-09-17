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
local blueprint = Opera.GetBlueprint("social.kiss_test")
T.truthy(blueprint, "kiss blueprint missing")
T.equal(blueprint.actors.player.kind, "local_player",
    "player slot kind changed")
T.equal(blueprint.actors.npc.kind, "nearby_live_npc",
    "npc slot kind changed")
T.equal(blueprint.beats[1].player.action, "RemoveBush",
    "player route is not the safe native action")
T.equal(blueprint.beats[1].player.anim, "Bob_Shove",
    "player clip is not Bob_Shove")
T.equal(blueprint.beats[1].player.debugDuration, 54,
    "player beat duration was not converted to native action ticks")
T.equal(blueprint.beats[1].npc.bump, "PNC_Shove",
    "npc beat did not reuse the proven Hoomans Shove route")
local runtimeOK, runtimeReason = Opera.Blueprints.ValidateRuntime(blueprint)
T.truthy(runtimeOK, "default blueprint failed runtime policy: "
    .. tostring(runtimeReason))

local plan = Opera.Anchors.BuildPlan(blueprint, player)
T.truthy(plan, "relative anchor plan failed")
T.truthy(plan.actors.player.x ~= plan.actors.npc.x
    or plan.actors.player.y ~= plan.actors.npc.y,
    "relative anchors overlap")
T.truthy(plan.actors.player.x ~= math.floor(player.x)
    or plan.actors.player.y ~= math.floor(player.y),
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
    actors = { npc = "npc1" },
})
T.truthy(preflightAccepted, "authority rejected a valid preflight request")
T.truthy(preflightResult and preflightResult.preflight
    and preflightResult.preflight.ready,
    "valid preflight did not report the scene as ready")
T.equal(preflightResult.preflight.actors.npc.reasonDetail, "ready",
    "valid preflight did not report the NPC as ready")

npc.actionState = "climbwindow"
preflightAccepted, preflightResult = Authority.HandleRequest(player, {
    action = "preflight",
    blueprintId = "social.kiss_test",
    actors = { npc = "npc1" },
})
T.truthy(preflightAccepted, "busy-state preflight request was rejected")
T.falsy(preflightResult.preflight.ready,
    "busy NPC was incorrectly reported as ready")
T.equal(preflightResult.preflight.actors.npc.reason,
    "npc_action_state_busy",
    "busy NPC readiness reason changed")
T.truthy(string.find(
    preflightResult.preflight.actors.npc.reasonDetail,
    "state=climbwindow",
    1,
    true
), "busy preflight did not expose the engine action state")
local busyAccepted, busyReason = Authority.HandleRequest(player, {
    action = "start",
    blueprintId = "social.kiss_test",
    npcID = "npc1",
    loop = false,
})
T.falsy(busyAccepted, "busy NPC was incorrectly forced into a scene")
T.truthy(string.find(tostring(busyReason), "state=climbwindow", 1, true),
    "busy start rejection did not preserve the action-state detail")
npc.actionState = nil

local previewAccepted, previewSession = Authority.HandleRequest(player, {
    action = "preview_start",
    blueprintId = "social.kiss_test",
    actors = { npc = "npc1" },
})
T.truthy(previewAccepted, "placement preview was not accepted")
T.truthy(previewSession and previewSession.previewOnly,
    "placement preview was not marked as preview-only")
player.x = previewSession.actors.player.target.worldX
player.y = previewSession.actors.player.target.worldY
npc.x = previewSession.actors.npc.target.worldX
npc.y = previewSession.actors.npc.target.worldY
T.truthy(Authority.HandleRequest(player, {
    action = "player_arrived",
    sessionId = previewSession.sessionId,
    revision = previewSession.revision,
}), "preview player arrival was not verified")
Authority.PumpSession(previewSession, clock)
T.equal(previewSession.phase, Opera.Phases.FACING,
    "placement preview did not enter the facing barrier")
player:faceLocation(
    previewSession.actors.npc.target.x,
    previewSession.actors.npc.target.y
)
T.truthy(Authority.HandleRequest(player, {
    action = "player_facing",
    sessionId = previewSession.sessionId,
    revision = previewSession.revision,
}), "preview player facing was not verified")
Authority.PumpSession(previewSession, clock)
T.equal(previewSession.phase, Opera.Phases.READY,
    "placement preview did not remain ready after facing")
T.equal(previewSession.actors.player.state, "preview_ready",
    "placement preview did not expose its ready state")
T.truthy(Authority.HandleRequest(player, {
    action = "preview_stop",
    sessionId = previewSession.sessionId,
}), "placement preview could not be stopped")
T.falsy(record.runtime.puppetOperaLease,
    "placement preview did not release the NPC session lease")

local accepted, session = Authority.HandleRequest(player, {
    action = "start",
    blueprintId = "social.kiss_test",
    npcID = "npc1",
    loop = false,
})
T.truthy(accepted, "authority rejected valid Puppet Opera start")
T.equal(session.phase, Opera.Phases.MOVING, "session did not enter moving")
T.truthy(record.runtime.puppetOperaLease,
    "NPC session lease was not acquired")

player.x = session.actors.player.target.worldX
player.y = session.actors.player.target.worldY
npc.x = session.actors.npc.target.worldX
npc.y = session.actors.npc.target.worldY

accepted = Authority.HandleRequest(player, {
    action = "player_arrived",
    sessionId = session.sessionId,
    revision = session.revision,
})
T.truthy(accepted, "server did not verify player arrival")
Authority.PumpSession(session, clock)
T.equal(session.phase, Opera.Phases.FACING,
    "arrival barrier did not enter facing")

player:faceLocation(session.actors.npc.target.x, session.actors.npc.target.y)
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
