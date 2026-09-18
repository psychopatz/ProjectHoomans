local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "client" },
})

local clock = 1000
local sent = {}
local handlers = {}
local queue = { queue = {}, current = nil }
local player
local previewCalls = {}
local previewBody = {
    modData = {},
}
function previewBody:getModData() return self.modData end
local previewDebugger = {
    active = nil,
}
function previewDebugger.PlayXML(_, _, body, _, options)
    previewCalls[#previewCalls + 1] = options
    previewDebugger.active = {
        npcId = "npc-preview",
        body = body,
    }
    return true, "xml_pipeline_started"
end
function previewDebugger.Stop()
    previewDebugger.active = nil
    return true
end
local currentRuntime = {
    active = false,
    owner = nil,
    result = nil,
}

package.preload["TimedActions/WalkToTimedAction"] = function()
    ISWalkToTimedAction = {
        new = function(_, body, square)
            local action = {
                character = body,
                location = square,
            }
            function action:setOnComplete(callback, context)
                self.onComplete = callback
                self.onCompleteContext = context
            end
            function action:forceStop()
                for index, queued in ipairs(queue.queue) do
                    if queued == self then
                        table.remove(queue.queue, index)
                        break
                    end
                end
                if queue.current == self then queue.current = nil end
            end
            return action
        end,
    }
end

package.preload["TimedActions/ISTimedActionQueue"] = function()
    ISTimedActionQueue = {
        getTimedActionQueue = function()
            return queue
        end,
        add = function(action)
            queue.queue[#queue.queue + 1] = action
            if not queue.current then queue.current = action end
        end,
    }
end

PNC = {
    Core = {
        Now = function() return clock end,
        IsClientOnly = function() return true end,
    },
    Const = {
        MODULE = "ProjectHoomans",
        CMD_PUPPET_OPERA_REQUEST = "PuppetOperaRequest",
        CMD_PUPPET_OPERA_STATE = "PuppetOperaState",
        CMD_PUPPET_OPERA_TRACE = "PuppetOperaTrace",
        PRESENCE_LIVE = "live",
    },
    Client = {
        Internal = {
            RegisterServerCommand = function(command, handler)
                handlers[command] = handler
                return true
            end,
        },
    },
    AnimationDebugPlayer = previewDebugger,
}

package.preload["PNC/Debug/PNC_AnimationDebugPlayer"] = function()
    return previewDebugger
end

PsychopatzCore = {
    Animation = {
        Player = {
            ResolveLocalPlayer = function() return player end,
            Validate = function(body)
                return body ~= nil, body and nil or "player_missing"
            end,
            Play = function(_, entry, options)
                currentRuntime.active = true
                currentRuntime.owner = options.owner
                currentRuntime.result = nil
                currentRuntime.entry = entry
                return true, "player_action_started", {
                    owner = options.owner,
                }
            end,
            Runtime = function()
                return currentRuntime
            end,
            Stop = function()
                currentRuntime.active = false
                currentRuntime.result = {
                    ok = false,
                    reason = "stopped",
                    at = clock,
                }
                return true, "stopped"
            end,
        },
    },
}

Events = {
    OnTick = { Add = function(callback) Events.tick = callback end },
    OnResetLua = { Add = function(callback) Events.reset = callback end },
}

function sendClientCommand(target, module, command, payload)
    sent[#sent + 1] = {
        target = target,
        module = module,
        command = command,
        payload = payload,
    }
end

local square = {
    getX = function() return 99 end,
    getY = function() return 199 end,
    getZ = function() return 0 end,
}

function getCell()
    return {
        getGridSquare = function(_, x, y, z)
            return {
                getX = function() return x end,
                getY = function() return y end,
                getZ = function() return z end,
            }
        end,
    }
end

player = {
    x = 100.5,
    y = 200.5,
    z = 0,
    forwardX = 0,
    forwardY = 1,
}
function player:getX() return self.x end
function player:getY() return self.y end
function player:getZ() return self.z end
function player:getForwardDirectionX() return self.forwardX end
function player:getForwardDirectionY() return self.forwardY end
function player:getVehicle() return nil end
function player:isSeatedInVehicle() return false end
function player:isDead() return false end
function player:isLocalPlayer() return true end
function player:faceLocation(x, y)
    local dx = x - self.x
    local dy = y - self.y
    if math.abs(dx) >= math.abs(dy) then
        self.forwardX = dx >= 0 and 1 or -1
        self.forwardY = 0
    else
        self.forwardX = 0
        self.forwardY = dy >= 0 and 1 or -1
    end
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
T.load(
    "ProjectHoomans",
    "client",
    "PNC/PuppetOpera/PNC_PuppetOpera_Client.lua"
)

local Opera = PNC.PuppetOpera
local Client = Opera.Client
local blueprint = Opera.GetBlueprint("social.kiss_test")
local plan = Opera.Anchors.BuildPlan(blueprint, player)
T.truthy(plan, "transport test could not build anchor plan")

local nearbyRegistryBody = {
    x = 101.5,
    y = 200.5,
    modData = {},
}
function nearbyRegistryBody:getX() return self.x end
function nearbyRegistryBody:getY() return self.y end
function nearbyRegistryBody:getModData() return self.modData end

PNC.Registry = {
    ForEachLive = function(callback)
        callback({ id = "npc-reg", displayName = "Registry NPC" },
            nearbyRegistryBody)
        callback({ displayName = "missing-body" }, nil)
    end,
}
PNC.Network = {
    ClientState = {
        snapshots = {
            duplicate = {
                id = "npc-reg",
                displayName = "Duplicate NPC",
                x = 101.5,
                y = 200.5,
                presenceState = "live",
                alive = true,
            },
            network = {
                id = "npc-net",
                displayName = "Network NPC",
                x = 102.5,
                y = 200.5,
                presenceState = "live",
                alive = true,
            },
            alpha = {
                id = "npc-alpha",
                displayName = "Alpha NPC",
                x = 103.5,
                y = 200.5,
                presenceState = "live",
                alive = true,
            },
            zeta = {
                id = "npc-zeta",
                displayName = "Zeta NPC",
                x = 103.5,
                y = 200.5,
                presenceState = "live",
                alive = true,
            },
            dead = {
                id = "npc-dead",
                displayName = "Dead NPC",
                x = 101.5,
                y = 200.5,
                presenceState = "live",
                alive = false,
            },
            stale = {
                id = "npc-stale",
                displayName = "Stale NPC",
                x = 101.5,
                y = 200.5,
                presenceState = "stale",
                alive = true,
            },
            far = {
                id = "npc-far",
                displayName = "Far NPC",
                x = 104.5,
                y = 200.5,
                presenceState = "live",
                alive = true,
            },
            malformed = {
                id = "npc-malformed",
                displayName = "Malformed NPC",
                presenceState = "live",
                alive = true,
            },
        },
    },
}
PNC.ClientPresenceSync = {
    BodyByID = {
        ["npc-net"] = false,
    },
}

local nearby = Client.GetNearbyNPCs(3)
T.equal(#nearby, 4,
    "nearby discovery did not filter live targets by radius and validity")
T.equal(nearby[1].id, "npc-reg",
    "nearby discovery did not prefer the live registry body")
T.equal(nearby[1].name, "Registry NPC",
    "network duplicate replaced the registry target")
T.equal(nearby[2].id, "npc-net",
    "nearby discovery did not include a valid network snapshot")
T.equal(nearby[3].name, "Alpha NPC",
    "nearby discovery did not use deterministic name ordering for ties")
T.equal(nearby[4].name, "Zeta NPC",
    "nearby discovery tie ordering changed")
local nearbyIDs = {}
for _, entry in ipairs(nearby) do nearbyIDs[entry.id] = true end
T.falsy(nearbyIDs["npc-dead"],
    "nearby discovery included a dead snapshot")
T.falsy(nearbyIDs["npc-stale"],
    "nearby discovery included a non-live snapshot")
T.falsy(nearbyIDs["npc-far"],
    "nearby discovery included an out-of-radius snapshot")
T.falsy(nearbyIDs["npc-malformed"],
    "nearby discovery included a malformed snapshot")

local invalidPlayerPreview, invalidPlayerReason = Client.PreviewPlayer(nil)
T.falsy(invalidPlayerPreview,
    "Puppet player preview accepted a missing entry")
T.equal(invalidPlayerReason, "player_preview_entry_missing",
    "Puppet player preview returned the wrong missing-entry reason")

local playerPreviewAccepted, playerPreviewReason = Client.PreviewPlayer({
    state = "Idle",
    anim = "Bob_Idle",
    playable = true,
})
T.truthy(playerPreviewAccepted,
    "Puppet player preview did not start")
T.equal(playerPreviewReason, "player_action_started",
    "Puppet player preview returned the wrong start reason")
T.equal(currentRuntime.owner, "ProjectHoomans.PuppetOperaPreview",
    "Puppet player preview did not claim its animation lease")
T.truthy(Client.StopPreview(),
    "Puppet player preview could not be stopped")
T.falsy(currentRuntime.active,
    "Puppet player preview remained active after stop")
currentRuntime.active = true
currentRuntime.owner = "other.preview"
local blockedPlayerPreview, blockedPlayerReason = Client.PreviewPlayer({
    state = "Idle",
    anim = "Bob_Idle",
    playable = true,
})
T.falsy(blockedPlayerPreview,
    "Puppet player preview replaced an animation owned by another system")
T.equal(blockedPlayerReason, "player_animation_owned_by_other",
    "Puppet player preview returned the wrong ownership reason")
currentRuntime.active = false
currentRuntime.owner = nil
currentRuntime.entry = nil

local invalidNPCPreview, invalidNPCReason = Client.PreviewNPC(nil,
    "npc-preview", previewBody, { id = "npc-preview" })
T.falsy(invalidNPCPreview,
    "Puppet NPC preview accepted a missing entry")
T.equal(invalidNPCReason, "npc_preview_entry_missing",
    "Puppet NPC preview returned the wrong missing-entry reason")

previewDebugger.active = {
    npcId = "other-preview",
    body = previewBody,
}
local blockedNPCPreview, blockedNPCReason = Client.PreviewNPC({
    state = "bumped",
    node = "PNC_Shove",
    anim = "Bob_Shove",
    playable = true,
}, "npc-preview", previewBody, { id = "npc-preview" })
T.falsy(blockedNPCPreview,
    "Puppet NPC preview replaced an NPC preview owned by another system")
T.equal(blockedNPCReason, "npc_preview_owned_by_other",
    "Puppet NPC preview returned the wrong ownership reason")
previewDebugger.active = nil

local previewAccepted, previewReason = Client.PreviewNPC(
    {
        state = "bumped",
        node = "PNC_Shove",
        anim = "Bob_Shove",
        conditions = {
            { name = "BumpType", kind = "STRING", value = "PNC_Shove" },
        },
        playable = true,
    },
    "npc-preview",
    previewBody,
    { id = "npc-preview" }
)
T.truthy(previewAccepted, "Puppet NPC preview did not start")
T.truthy(previewCalls[1] and previewCalls[1].nonCombat == true,
    "Puppet NPC preview did not use the non-combat bump lease")
T.equal(previewCalls[1].sceneId, "ProjectHoomans.PuppetOperaPreview:npc-preview",
    "Puppet NPC preview did not identify its owner")
T.truthy(Client.StopPreview(),
    "Puppet NPC preview could not be stopped")
T.falsy(previewBody.modData.PNC_PuppetOperaPreviewOwner,
    "Puppet NPC preview left its ownership marker behind")

local maintainCalls = 0
local replayCalls = 0
function previewDebugger.Maintain()
    maintainCalls = maintainCalls + 1
end
function previewDebugger.Replay()
    replayCalls = replayCalls + 1
    return true, "preview_replayed"
end
clock = 2000
T.truthy(Client.SetPreviewLoopEnabled(true),
    "Puppet preview loop did not enable")
previewAccepted = Client.PreviewNPC({
    state = "bumped",
    node = "PNC_Shove",
    anim = "Bob_Shove",
    playable = true,
}, "npc-preview", previewBody, { id = "npc-preview" })
T.truthy(previewAccepted, "Puppet NPC preview could not restart for looping")
clock = 3000
Client.Pump()
T.equal(maintainCalls, 1,
    "Puppet preview loop did not maintain its owned NPC")
T.equal(replayCalls, 1,
    "Puppet preview loop did not replay after its bounded delay")
T.truthy(previewCalls[2] and previewCalls[2].loop == true,
    "Puppet NPC preview did not pass loop ownership to the adapter")
T.falsy(Client.SetPreviewLoopEnabled(false),
    "Puppet preview loop did not disable")
T.falsy(Client.GetPreviewLoopEnabled(),
    "Puppet preview loop getter reported stale state")
T.truthy(Client.StopPreview(),
    "Puppet loop preview could not be stopped")

clock = 4000
previewAccepted = Client.PreviewNPC({
    state = "bumped",
    node = "PNC_Shove",
    anim = "Bob_Shove",
    playable = true,
}, "npc-preview", previewBody, { id = "npc-preview" })
T.truthy(previewAccepted, "Puppet preview could not start before Lua reset")
T.truthy(Client.SetPreviewLoopEnabled(true),
    "Puppet preview loop could not enable before Lua reset")
Events.reset()
T.falsy(previewDebugger.active,
    "Lua reset left the Puppet NPC preview active")
T.falsy(previewBody.modData.PNC_PuppetOperaPreviewOwner,
    "Lua reset left the Puppet NPC ownership marker behind")
T.falsy(Client.GetPreviewLoopEnabled(),
    "Lua reset left the Puppet preview loop enabled")

previewAccepted = Client.StartPlacementPreview(
    "social.kiss_test",
    nil,
    {
        actor_1 = "__local_player__",
        actor_2 = "npc-client",
    },
    "social.kiss_test:preview_pending"
)
T.truthy(previewAccepted, "client did not send the placement preview request")
T.equal(sent[#sent].payload.action, "preview_start",
    "placement preview did not use the preview_start request action")
T.equal(sent[#sent].payload.actors.actor_2, "npc-client",
    "placement preview did not carry the actor-slot binding map")
T.falsy(sent[#sent].payload.x,
    "placement preview must not send an arbitrary world coordinate")
local pendingStopAccepted = Client.StopPlacementPreview()
T.truthy(pendingStopAccepted,
    "pending placement preview could not be cancelled")
T.equal(sent[#sent].payload.action, "preview_stop",
    "pending placement preview cancellation did not use preview_stop")

previewAccepted = Client.StartPlacementPreview(
    "social.kiss_test",
    nil,
    {
        actor_1 = "__local_player__",
        actor_2 = "npc-client",
    },
    "social.kiss_test:preview"
)
T.truthy(previewAccepted, "client could not restart the placement preview")

local previewSnapshot = {
    sessionId = "puppet:preview:1",
    blueprintId = "social.kiss_test",
    revision = 1,
    phase = Opera.Phases.MOVING,
    preview = true,
    actors = {
        actor_1 = {
            kind = "local_player",
            target = plan.actors.actor_1,
        },
        actor_2 = {
            kind = "nearby_live_npc",
            target = plan.actors.actor_2,
        },
    },
}
Client.ReceiveState(previewSnapshot)
T.equal(queue.current and queue.current.puppetOperaSessionId,
    previewSnapshot.sessionId,
    "placement preview did not create the owned native walk action")
local previewStopAccepted = Client.StopPlacementPreview()
T.truthy(previewStopAccepted,
    "client did not send the placement preview stop request")
T.equal(sent[#sent].payload.action, "preview_stop",
    "placement preview stop used the wrong request action")
previewSnapshot.revision = 2
previewSnapshot.phase = Opera.Phases.RESTORED
previewSnapshot.restored = true
Client.ReceiveState(previewSnapshot)
T.falsy(queue.current,
    "placement preview stop left the native walk action owned")

local accepted = Client.Start("social.kiss_test", "npc-client", false, nil, {
    actor_1 = "__local_player__",
    actor_2 = "npc-client",
})
T.truthy(accepted, "client did not send the start request")
T.equal(sent[#sent].command, PNC.Const.CMD_PUPPET_OPERA_REQUEST,
    "start did not use the Puppet Opera request command")
T.equal(sent[#sent].payload.action, "start",
    "start request action changed")
T.equal(sent[#sent].payload.npcID, "npc-client",
    "start request NPC identity changed")
T.equal(sent[#sent].payload.actors.actor_2, "npc-client",
    "start request did not carry the actor-slot binding map")
T.falsy(sent[#sent].payload.x,
    "client request must not send an arbitrary world coordinate")

local sessionID = "puppet:client:1"
local snapshot = {
    sessionId = sessionID,
    blueprintId = "social.kiss_test",
    revision = 1,
    phase = Opera.Phases.MOVING,
    actors = {
        actor_1 = {
            kind = "local_player",
            target = plan.actors.actor_1,
        },
        actor_2 = {
            kind = "nearby_live_npc",
            target = plan.actors.actor_2,
        },
    },
}
T.truthy(handlers[PNC.Const.CMD_PUPPET_OPERA_STATE],
    "client state command was not registered")
T.truthy(handlers[PNC.Const.CMD_PUPPET_OPERA_TRACE],
    "client trace command was not registered")
T.equal(Events.tick, Client.Pump,
    "client runtime pump was not registered as the tick entry point")
Client.ReceiveState(snapshot)
T.equal(queue.current and queue.current.puppetOperaSessionId, sessionID,
    "moving state did not create the owned native walk action")
T.equal(sent[#sent].payload.action, "player_moving",
    "moving state did not acknowledge the server revision")

T.falsy(Client.ReceiveState({
    sessionId = sessionID,
    revision = 0,
    phase = Opera.Phases.MOVING,
}), "stale server snapshot was accepted")
T.equal(Client.GetSnapshot().revision, 1,
    "stale server snapshot replaced the current revision")

player.x = plan.actors.actor_1.worldX
player.y = plan.actors.actor_1.worldY
Client.Pump()
T.equal(sent[#sent].payload.action, "player_arrived",
    "client did not acknowledge verified local arrival")

snapshot.revision = 2
snapshot.phase = Opera.Phases.FACING
Client.ReceiveState(snapshot)
Client.Pump()
T.equal(sent[#sent].payload.action, "player_facing",
    "client did not acknowledge verified local facing")

clock = 1200
snapshot.revision = 3
snapshot.phase = Opera.Phases.PLAYING
snapshot.beatIndex = 1
snapshot.beatStartAt = 1500
Client.ReceiveState(snapshot)
Client.Pump()
T.falsy(currentRuntime.entry,
    "player beat started before the synchronized beat timestamp")

clock = 1500
Client.Pump()
T.truthy(currentRuntime.entry,
    "player beat did not start at the synchronized timestamp")
T.equal(sent[#sent].payload.action, "player_beat_started",
    "client did not acknowledge player beat start")

clock = 1501
currentRuntime.active = false
currentRuntime.result = {
    ok = true,
    reason = "player_action_finished",
    at = clock,
}
Client.Pump()
T.equal(sent[#sent].payload.action, "player_beat_finished",
    "client did not acknowledge the completed player beat")

return T.finish("pnc_puppet_opera_transport_smoke")
