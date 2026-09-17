local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
})

local clock = 1000
local sent = {}
local player
local npcA
local npcB
local recordA
local recordB

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
        RequestMove = function(targetRecord, x, y, z, _, _, reason)
            targetRecord.runtime = targetRecord.runtime or {}
            targetRecord.runtime.moveIntent = {
                kind = "move",
                x = x,
                y = y,
                z = z,
                reason = reason,
            }
            return true, "requested"
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
            targetBody.bumpFinished = true
            return true, "started"
        end,
        ResolveBumpType = function(value) return value end,
        IsBumpActionActive = function() return false end,
        MaintainBump = function() return true, "maintained" end,
        FinishBump = function() return true end,
    },
    PuppetOpera = {},
}

Events = {
    OnTick = { Add = function(callback) Events.tick = callback end },
}

function isServer() return true end

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
function player:getOnlineID() return 99 end

npcA = actor(100.5, 200.5, 0, 1)
npcB = actor(100.5, 200.5, 0, 1)
recordA = { id = "npc-a", runtime = {} }
recordB = { id = "npc-b", runtime = {} }

PNC.Registry.Get = function(id)
    id = tostring(id)
    if id == "npc-a" then return recordA end
    if id == "npc-b" then return recordB end
    return nil
end
PNC.Registry.GetLiveZombie = function(id)
    id = tostring(id)
    if id == "npc-a" then return npcA end
    if id == "npc-b" then return npcB end
    return nil
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
local registered, blueprint = Opera.Blueprints.Register("rumors.dual_npc", {
    id = "rumors.dual_npc",
    version = 1,
    actors = {
        npc_a = { kind = "nearby_live_npc", anchor = "left" },
        npc_b = { kind = "nearby_live_npc", anchor = "right" },
    },
    anchorFrame = {
        tolerance = 0.75,
        anchors = {
            left = {
                right = -1,
                forward = 0,
                z = 0,
                faceTarget = "npc_b",
            },
            right = {
                right = 1,
                forward = 0,
                z = 0,
                faceTarget = "npc_a",
            },
        },
    },
    beats = {
        {
            id = "exchange",
            durationMs = 900,
            tracks = {
                npc_a = { bump = "PNC_Shove", animation = "Bob_Shove" },
                npc_b = { bump = "PNC_Shove", animation = "Bob_Shove" },
            },
        },
    },
    playback = { defaultMode = "once", allowLoop = true, gapMs = 0 },
})
T.truthy(registered, "two-NPC blueprint could not be registered")
T.truthy(blueprint, "two-NPC blueprint normalization returned no value")
T.equal(blueprint.beats[1].tracks.npc_a.bump, "PNC_Shove",
    "first NPC track was not normalized")
T.equal(blueprint.beats[1].tracks.npc_b.bump, "PNC_Shove",
    "second NPC track was not normalized")
T.truthy(Opera.Blueprints.ValidateRuntime(blueprint),
    "two-NPC blueprint failed the runtime policy")

T.load(
    "ProjectHoomans",
    "server",
    "PNC/PuppetOpera/PNC_PuppetOpera_NPCMovementAdapter.lua"
)
T.load(
    "ProjectHoomans",
    "server",
    "PNC/PuppetOpera/PNC_PuppetOpera_NPCAnimationAdapter.lua"
)
T.load(
    "ProjectHoomans",
    "server",
    "PNC/PuppetOpera/PNC_PuppetOpera_Authority.lua"
)

local Authority = Opera.Authority
local accepted, session = Authority.HandleRequest(player, {
    action = "start",
    blueprintId = "rumors.dual_npc",
    actors = {
        npc_a = "npc-a",
        npc_b = "npc-b",
    },
    loop = false,
})
T.truthy(accepted, "authority rejected a valid two-NPC scene")
T.truthy(session.actors.npc_a and session.actors.npc_b,
    "authority did not create both NPC actor slots")
T.truthy(recordA.runtime.puppetOperaLease,
    "first NPC did not receive a session lease")
T.truthy(recordB.runtime.puppetOperaLease,
    "second NPC did not receive a session lease")
T.equal(Authority.ByActor["npc-a"], session,
    "first NPC was not indexed as session-owned")
T.equal(Authority.ByActor["npc-b"], session,
    "second NPC was not indexed as session-owned")

npcA.x = session.actors.npc_a.target.worldX
npcA.y = session.actors.npc_a.target.worldY
npcB.x = session.actors.npc_b.target.worldX
npcB.y = session.actors.npc_b.target.worldY
Authority.PumpSession(session, clock)
T.equal(session.phase, Opera.Phases.FACING,
    "two-NPC arrival barrier did not advance to facing")

Authority.PumpSession(session, clock)
T.equal(session.phase, Opera.Phases.READY,
    "two-NPC facing barrier did not schedule the beat")

clock = session.beatStartAt + 1
Authority.PumpSession(session, clock)
T.equal(session.phase, Opera.Phases.PLAYING,
    "two-NPC beat did not enter playing")
clock = session.beatStartAt + 1
Authority.PumpSession(session, clock)
T.truthy(session.closed, "two-NPC one-shot scene did not close")
T.equal(Authority.LastSnapshots[session.ownerId].phase,
    Opera.Phases.COMPLETED,
    "two-NPC completed snapshot was not retained")
T.falsy(recordA.runtime.puppetOperaLease,
    "first NPC lease was not released")
T.falsy(recordB.runtime.puppetOperaLease,
    "second NPC lease was not released")
T.falsy(Authority.ByActor["npc-a"],
    "first NPC session index was not released")
T.falsy(Authority.ByActor["npc-b"],
    "second NPC session index was not released")
T.truthy(#sent > 0, "two-NPC transport emitted no state")

return T.finish("pnc_puppet_opera_multi_actor_smoke")
