-- Dynamic end-to-end lifecycle test for EVERY registered Puppet Opera blueprint.
--
-- Automatically discovers all blueprints from `PNC.PuppetOpera.Blueprints.List()`
-- and runs each one through:
--   1. Preflight (verifies no crashes and ready == true)
--   2. Start -> MOVING -> tick-1 activeSafety/puppetMovementIsSafe
--   3. Arrival -> FACING -> READY -> PLAYING (beat 1 + beat 2 transition)
--   4. AnimVarAdapter verification on anim_vars tracks + locomotive sustained check
--   5. Mid-session preflight snapshot + Client.Stop() cleanup verification

local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "client" },
})

local clock = 10000
local npcRecords = {}
local npcBodies = {}
local playerBody

local function makeActor(x, y, fx, fy)
    local a = {
        x = x,
        y = y,
        z = 0,
        forwardX = fx or 0,
        forwardY = fy or 1,
        modData = {},
        vars = {},
        actionState = "idle",
        collidable = true,
        solid = true,
        useless = false,
        moving = false,
        bumpFinished = false,
    }
    function a:getX() return self.x end
    function a:getY() return self.y end
    function a:getZ() return self.z end
    function a:setX(v) self.x = v end
    function a:setY(v) self.y = v end
    function a:setZ(v) self.z = v end
    function a:setLx(v) self.x = v end
    function a:setLy(v) self.y = v end
    function a:setLz(v) self.z = v end
    function a:getForwardDirectionX() return self.forwardX end
    function a:getForwardDirectionY() return self.forwardY end
    function a:getModData() return self.modData end
    function a:getActionStateName() return self.actionState or "idle" end
    function a:getCurrentActionContextStateName() return self.actionState or "idle" end
    function a:setVariable(name, val) self.vars[tostring(name)] = val end
    function a:clearVariable(name) self.vars[tostring(name)] = nil end
    function a:getVariableBoolean(name)
        if name == "BumpAnimFinished" then return self.bumpFinished == true end
        return self.vars[tostring(name)] == true
    end
    function a:getVariableString(name)
        return tostring(self.vars[tostring(name)] or "")
    end
    function a:isDead() return false end
    function a:getVehicle() return nil end
    function a:isSeatedInVehicle() return false end
    function a:setCollidable(v) self.collidable = v == true end
    function a:isCollidable() return self.collidable == true end
    function a:setSolid(v) self.solid = v == true end
    function a:isSolid() return self.solid == true end
    function a:setUseless(v) self.useless = v == true end
    function a:isUseless() return self.useless == true end
    function a:setMoving(v) self.moving = v == true end
    function a:isMoving() return self.moving == true end
    function a:isPlayerMoving() return self.moving == true end
    function a:setPath2() end
    function a:getPath2() return nil end
    function a:setTarget() end
    function a:setBlockMovement(v) self.blockMovement = v == true end
    function a:isBlockMovement() return self.blockMovement == true end
    function a:setIgnoreAutoVault(v) self.ignoreVault = v == true end
    function a:isIgnoreAutoVault() return self.ignoreVault == true end
    function a:getCurrentSquare()
        return {
            getX = function() return math.floor(a.x) end,
            getY = function() return math.floor(a.y) end,
            getZ = function() return math.floor(a.z) end,
            isFree = function() return true end,
            isSolid = function() return false end,
            isSolidTrans = function() return false end,
            isInARoom = function() return false end,
        }
    end
    function a:faceLocation(tx, ty)
        local dx = tx - self.x
        local dy = ty - self.y
        if math.abs(dx) >= math.abs(dy) then
            self.forwardX = dx >= 0 and 1 or -1
            self.forwardY = 0
        else
            self.forwardX = 0
            self.forwardY = dy >= 0 and 1 or -1
        end
    end
    return a
end

playerBody = makeActor(100.5, 200.5, 0, 1)
function playerBody:getUsername() return "E2ETester" end
function playerBody:getOnlineID() return 7 end

for i = 1, 4 do
    local id = "npc_" .. tostring(i)
    npcBodies[id] = makeActor(100.5 + i * 1.5, 200.5, 0, -1)
    npcRecords[id] = { id = id, name = "NPC " .. tostring(i), x = 100.5 + i * 1.5, y = 200.5, z = 0, runtime = {} }
end

local function makeSquare(x, y, z)
    return {
        x = x, y = y, z = z,
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return z end,
        isFree = function() return true end,
        isSolid = function() return false end,
        isSolidTrans = function() return false end,
        isInARoom = function() return false end,
        isBlockedTo = function() return false end,
    }
end

function getCell()
    return {
        getGridSquare = function(_, x, y, z) return makeSquare(x, y, z) end,
    }
end

function getSpecificPlayer() return playerBody end

ISTimedActionQueue = {
    _queues = {},
    getTimedActionQueue = function(body)
        ISTimedActionQueue._queues[body] = ISTimedActionQueue._queues[body] or { queue = {} }
        return ISTimedActionQueue._queues[body]
    end,
    add = function(action)
        local q = ISTimedActionQueue.getTimedActionQueue(action.character)
        q.current = action
        q.queue[#q.queue + 1] = action
    end,
}

ISWalkToTimedAction = {}
function ISWalkToTimedAction:new(character, square)
    local act = {
        character = character,
        square = square,
        stopped = false,
    }
    function act:setOnComplete(fn, ctx) self.onComplete = fn; self.ctx = ctx end
    function act:forceStop()
        self.stopped = true
        local q = ISTimedActionQueue.getTimedActionQueue(self.character)
        q.current = nil
        q.queue = {}
    end
    return act
end

PsychopatzCore = {
    Animation = {
        Player = {
            _runtime = { active = false },
            ResolveLocalPlayer = function() return playerBody end,
            Validate = function() return true end,
            Play = function(_, entry, opts)
                if not (entry.playerAction or entry.action or entry.emote or entry.anim) then
                    return false, "selected_entry_has_no_player_action"
                end
                PsychopatzCore.Animation.Player._runtime = {
                    active = true,
                    owner = opts and opts.owner or "",
                }
                return true, "started", { owner = opts and opts.owner or "" }
            end,
            Stop = function()
                PsychopatzCore.Animation.Player._runtime = {
                    active = false,
                    result = { ok = true, at = clock },
                }
                return true
            end,
            Runtime = function() return PsychopatzCore.Animation.Player._runtime end,
        },
    },
}

Events = {
    OnTick = { Add = function() end },
}

PNC = {
    Core = {
        Now = function() return clock end,
        IsClientOnly = function() return false end,
    },
    Const = {
        MODULE = "ProjectHoomans",
        CMD_PUPPET_OPERA_REQUEST = "PuppetOperaRequest",
        CMD_PUPPET_OPERA_STATE = "PuppetOperaState",
        CMD_PUPPET_OPERA_TRACE = "PuppetOperaTrace",
    },
    Registry = {
        Get = function(id) return npcRecords[id] end,
        GetLiveZombie = function(id) return npcBodies[id] end,
    },
    ServerCommandRouter = {
        CanUseDebug = function() return true end,
        Register = function() return true end,
    },
    Client = {
        RegisterServerCommand = function() end,
    },
    BehaviorMoveIntent = {
        RequestMove = function(targetRecord, x, y, z, _, _, reason)
            targetRecord.runtime = targetRecord.runtime or {}
            targetRecord.runtime.moveIntent = {
                kind = "move",
                x = x, y = y, z = z,
                reason = reason,
            }
            return true
        end,
        Hold = function(targetRecord, reason)
            targetRecord.runtime = targetRecord.runtime or {}
            targetRecord.runtime.moveIntent = { kind = "hold", reason = reason }
            return true
        end,
    },
    Animation = {
        PlayBump = function(targetBody, _, bumpType)
            local md = targetBody:getModData()
            md.PNC_BumpRequestedType = bumpType
            md.PNC_BumpActionLease = true
            targetBody.bumpFinished = true
            return true, "started"
        end,
        ResolveBumpType = function(v) return v end,
        IsBumpActionActive = function() return false end,
        MaintainBump = function() return true, "maintained" end,
        FinishBump = function() return true end,
    },
}

-- Load PuppetOpera stack (shared + server + client)
local Opera = T.load("ProjectHoomans", "shared", "PNC/Core/PuppetOpera/PNC_PuppetOpera.lua")
local Blueprints = T.load("ProjectHoomans", "shared", "PNC/Core/PuppetOpera/PNC_PuppetOpera_Blueprints.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/PuppetOpera/PNC_PuppetOpera_Anchors.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/PuppetOpera/PNC_PuppetOpera_AnimVarAdapter.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/PuppetOpera/PNC_PuppetOpera_Tether.lua")
local Telemetry = T.load("ProjectHoomans", "shared", "PNC/Core/PuppetOpera/PNC_PuppetOpera_Telemetry.lua")
Telemetry.Enabled = false

T.load("ProjectHoomans", "server", "PNC/PuppetOpera/PNC_PuppetOpera_NPCMovementAdapter.lua")
T.load("ProjectHoomans", "server", "PNC/PuppetOpera/PNC_PuppetOpera_NPCAnimationAdapter.lua")
local Authority = T.load("ProjectHoomans", "server", "PNC/PuppetOpera/PNC_PuppetOpera_Authority.lua")

-- Stub TimedActions require before loading Client adapters
package.loaded["TimedActions/WalkToTimedAction"] = true
package.loaded["TimedActions/ISTimedActionQueue"] = true
package.loaded["PNC/Debug/PNC_AnimationDebugPlayer"] = true
package.loaded["PsychopatzCore/Animation/PsychopatzPlayerAnimationController"] = true

local Client = T.load("ProjectHoomans", "client", "PNC/PuppetOpera/PNC_PuppetOpera_Client.lua")

function sendServerCommand(_, _, command, payload)
    if command == PNC.Const.CMD_PUPPET_OPERA_STATE then
        Client.ReceiveState(payload)
    end
end

local allBlueprints = Blueprints.List()
T.truthy(#allBlueprints >= 12, "Expected at least 12 registered blueprints, got " .. tostring(#allBlueprints))

local tested = 0
for _, bp in ipairs(allBlueprints) do
    -- Reset world positions and queues cleanly before each blueprint
    playerBody.x, playerBody.y, playerBody.z = 100.5, 200.5, 0
    playerBody.forwardX, playerBody.forwardY = 0, 1
    playerBody.vars = {}
    playerBody.moving = false
    ISTimedActionQueue._queues = {}
    for i = 1, 4 do
        local id = "npc_" .. tostring(i)
        npcBodies[id].x = 100.5 + i * 1.5
        npcBodies[id].y = 200.5
        npcBodies[id].z = 0
        npcBodies[id].forwardX, npcBodies[id].forwardY = 0, -1
        npcBodies[id].vars = {}
        npcBodies[id].modData = {}
        npcBodies[id].actionState = "idle"
        npcRecords[id].runtime = {}
    end

    -- Build dynamic actor bindings matching this blueprint's actor kinds
    local bindings = {}
    local npcIdx = 1
    local hasPlayer = false
    local actorIDs = {}
    for actorID in pairs(bp.actors or {}) do actorIDs[#actorIDs + 1] = actorID end
    table.sort(actorIDs)
    for _, actorID in ipairs(actorIDs) do
        local def = bp.actors[actorID]
        if def.kind == "local_player" then
            bindings[actorID] = "__local_player__"
            hasPlayer = true
        else
            bindings[actorID] = "npc_" .. tostring(npcIdx)
            npcIdx = npcIdx + 1
        end
    end

    -- 1. Preflight must succeed without error
    local preOk, preRes = Authority.HandleRequest(playerBody, {
        action = "preflight",
        blueprintId = bp.id,
        actors = bindings,
    })
    T.equal(preOk, true, bp.id .. " preflight request accepted")
    T.equal(preRes.preflight and preRes.preflight.ready, true,
        bp.id .. " preflight ready (got reason=" .. tostring(preRes.preflight and preRes.preflight.reason) .. ")")

    -- 2. Start session -> MOVING
    local startOk, startRes = Client.Start(bp.id, nil, false, nil, bindings)
    T.equal(startOk, true, bp.id .. " start accepted: " .. tostring(startRes))
    local session = Authority.GetSessionForOwner(playerBody)
    T.truthy(session, bp.id .. " active session created")
    T.equal(session.phase, Opera.Phases.MOVING, bp.id .. " starts in MOVING")

    -- 3. Tick-1 PumpSession during MOVING (must NOT abort with npc_movement_ownership_lost!)
    clock = clock + 50
    local pumpOk1 = Authority.PumpSession(session, clock)
    T.equal(pumpOk1, true, bp.id .. " survives tick-1 MOVING safety (err=" .. tostring(session.lastError) .. ")")
    Client.Pump()

    -- 4. Move all non-stationary actors to their target anchors
    for _, actor in pairs(session.actors) do
        local pt = Opera.Anchors.WorldPoint(actor.target)
        if pt and actor.body then
            actor.body.x = pt.x
            actor.body.y = pt.y
        end
    end
    -- 5. Advance through MOVING -> FACING -> READY -> PLAYING
    for _ = 1, 15 do
        if session.phase == Opera.Phases.PLAYING then break end
        clock = clock + 100
        local okPump = Authority.PumpSession(session, clock)
        T.equal(okPump, true, bp.id .. " pump toward PLAYING (phase=" .. tostring(session.phase) .. " err=" .. tostring(session.lastError) .. ")")
        Client.Pump()
    end
    T.equal(session.phase, Opera.Phases.PLAYING, bp.id .. " reached PLAYING (got " .. tostring(session.phase) .. ")")

    -- Advance past beatStartAt so beat 1 actually starts
    clock = tonumber(session.beatStartAt or clock) + 20
    Client.Pump()
    T.equal(Authority.PumpSession(session, clock), true, bp.id .. " beat 1 started cleanly (err=" .. tostring(session.lastError) .. ")")
    Client.Pump()

    -- Verify anim_vars applied on beat 1 if beat 1 uses anim_vars
    local beat1 = bp.beats[1]
    for actorID, actor in pairs(session.actors) do
        local track = Blueprints.GetTrack(beat1, actorID, actor.kind)
        if type(track) == "table" and track.route == "anim_vars" then
            T.equal(actor.body.vars.PNC_AnimActive, true,
                bp.id .. " beat 1 sets PNC_AnimActive on " .. actorID)
            T.equal(actor.body.vars.PNC_AnimStyle, track.style,
                bp.id .. " beat 1 sets PNC_AnimStyle on " .. actorID)
        end
    end

    -- If multi-beat with beat 2 locomotive/sustained, advance beat 1 -> beat 2!
    if #bp.beats >= 2 and (beat1.mode == "timed" or not beat1.mode) then
        clock = clock + (tonumber(beat1.durationMs) or 900) + 50
        Client.Pump()
        T.equal(Authority.PumpSession(session, clock), true, bp.id .. " beat 1 completes cleanly")
        -- Advance through READY -> PLAYING for beat 2
        clock = tonumber(session.beatStartAt or clock) + 50
        T.equal(Authority.PumpSession(session, clock), true, bp.id .. " beat 2 READY -> PLAYING")
        clock = tonumber(session.beatStartAt or clock) + 50
        Client.Pump()
        T.equal(Authority.PumpSession(session, clock), true, bp.id .. " beat 2 starts cleanly")
        T.equal(session.beatIndex, 2, bp.id .. " transitioned to beat 2")

        local beat2 = bp.beats[2]
        if beat2.mode == "locomotive" or beat2.mode == "sustained" then
            -- Verify beat 2 stays alive well past durationMs
            clock = clock + (tonumber(beat2.durationMs) or 3000) + 5000
            Client.Pump()
            T.equal(Authority.PumpSession(session, clock), true, bp.id .. " sustained/locomotive beat 2 stays alive past durationMs")
            T.equal(session.phase, Opera.Phases.PLAYING, bp.id .. " stays in PLAYING during locomotive beat 2")
        end
    end

    -- 6. If still active (e.g. locomotive/sustained/loop), inject a sessionless
    -- preflight snapshot mid-session and verify Stop / Restore STILL exits cleanly!
    if not session.closed then
        Client.ReceiveState({
            preflight = { ready = false, reason = "npc_owned_by_other_puppet_override" },
        })
        local stopOk, stopReason = Client.Stop()
        T.equal(stopOk, true, bp.id .. " Client.Stop() succeeds even after preflight snapshot: " .. tostring(stopReason))
    end
    T.equal(Authority.GetSessionForOwner(playerBody), nil, bp.id .. " server session closed")
    for actorID, actor in pairs(session.actors) do
        T.equal(actor.body.vars.PNC_AnimActive, nil,
            bp.id .. " PNC_AnimActive cleared on " .. actorID .. " after Stop/Complete")
    end

    tested = tested + 1
end

print("PASS pnc_puppet_opera_all_blueprints_e2e_smoke (" .. tostring(tested) .. " blueprints verified end-to-end)")
