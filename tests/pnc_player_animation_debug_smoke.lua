local T = require "tests/support/test"

local PLAYER_FILE =
    T.path("ProjectHoomans", "client", "PNC/Debug/")
        .. "PNC_PlayerAnimationDebug.lua"

local now = 1000
local seated = false
local dead = false
local localPlayer = true
local state = {
    variables = {},
    reportedEvent = nil,
    actionName = nil,
    emote = nil,
    emotePlaying = false,
    cancelPressed = false,
    cleared = {},
}

local queue = { queue = {}, current = nil }
local player

local function newClass(parent)
    local class = {}
    setmetatable(class, { __index = parent })
    class.__index = class
    function class:derive()
        return newClass(self)
    end
    return class
end

ISBaseTimedAction = newClass({})

function ISBaseTimedAction.new(self, character)
    local action = setmetatable({ character = character, maxTime = -1 }, self)
    return action
end

function ISBaseTimedAction:forceStop()
    self.action.forceStop = true
end

function ISBaseTimedAction:setActionAnim(name)
    self.action:setActionAnim(name)
end

function ISBaseTimedAction:setAnimVariable(name, value)
    self.action:setAnimVariable(name, value)
end

function ISBaseTimedAction:setOverrideHandModels(primary, secondary)
    self.action:setOverrideHandModels(primary, secondary)
end

function ISBaseTimedAction:getDuration()
    return self.maxTime
end

function ISBaseTimedAction:beginAddingActions()
    self._isAddingActions = true
    self._numAddedActions = 0
end

function ISBaseTimedAction:endAddingActions()
    self._isAddingActions = nil
    self._numAddedActions = nil
end

function ISBaseTimedAction:begin()
    local owner = self
    self.action = {
        forceStop = false,
        getCurrentTime = function() return 0 end,
        setActionAnim = function(_, name)
            state.actionName = name
            state.variables.PerformingAction = name
            owner.animVariables = owner.animVariables or {}
            owner.animVariables[#owner.animVariables + 1] = "PerformingAction"
        end,
        setAnimVariable = function(_, name, value)
            state.variables[name] = value
            owner.animVariables = owner.animVariables or {}
            owner.animVariables[#owner.animVariables + 1] = name
        end,
        setOverrideHandModels = function() end,
        stop = function() owner:stop() end,
    }
    self:start()
end

function ISBaseTimedAction:stop()
    for _, name in ipairs(self.animVariables or {}) do
        state.variables[name] = nil
        state.cleared[name] = true
    end
    state.variables.IsPerformingAnAction = false
    queue.queue = {}
    queue.current = nil
end

function ISBaseTimedAction:perform()
    table.remove(queue.queue, 1)
    queue.current = queue.queue[1]
    if queue.current then queue.current:begin() end
end

ISTimedActionQueue = {
    getTimedActionQueue = function() return queue end,
    add = function(action)
        local current = queue.queue[1]
        if current and current._isAddingActions then
            table.insert(queue.queue, 2 + (current._numAddedActions or 0),
                action)
            current._numAddedActions = (current._numAddedActions or 0) + 1
        else
            queue.queue[#queue.queue + 1] = action
            if not queue.current then
                queue.current = action
                action:begin()
            end
        end
        return queue
    end,
}

function getSpecificPlayer(index)
    return index == 0 and player or nil
end

player = {
    isLocalPlayer = function() return localPlayer end,
    isDead = function() return dead end,
    isSeatedInVehicle = function() return seated end,
    getUsername = function() return "TestPlayer" end,
    reportEvent = function(_, event) state.reportedEvent = event end,
    playEmote = function(_, emote)
        state.emote = emote
        state.emotePlaying = true
    end,
    setVariable = function(_, name, value)
        state.variables[name] = value
        if name == "EmotePlaying" then state.emotePlaying = value end
    end,
    getVariableString = function(_, name)
        return name == "emote" and state.emote or ""
    end,
    getVariableBoolean = function(_, name)
        return name == "EmotePlaying" and state.emotePlaying or false
    end,
    pressedCancelAction = function() return state.cancelPressed end,
}

PNC = {
    Core = {
        Now = function() return now end,
    },
    PlayerAnimationDebugCatalog = {
        entries = {},
        stateCounts = {},
    },
}

Events = nil
function require() return true end
T.load(PLAYER_FILE)

local source = T.read(PLAYER_FILE)
T.falsy(string.find(source, "pcall", 1, true),
    "player debugger must not use pcall")
T.falsy(string.find(source, "AnimationPlayer", 1, true),
    "player debugger must not use raw AnimationPlayer access")

local playerDebug = PNC.PlayerAnimationDebug
local initialRuntime = playerDebug.Runtime()
T.truthy(initialRuntime.playerAvailable,
    "runtime incorrectly reported no local player before preview")
T.truthy(initialRuntime.playerReady,
    "runtime incorrectly reported local player as not ready before preview")
T.equal(initialRuntime.playerName, "TestPlayer",
    "runtime did not report the resolved local player before preview")

local entry = {
    state = "Loot",
    folder = "actions",
    file = "LootHigh.xml",
    node = "LootHigh",
    anim = "Bob_IdleLooting_High",
    action = "Loot",
    speed = 0.8,
    looped = false,
    playable = true,
    variables = {
        { name = "LootPosition", kind = "STRING", value = "High" },
    },
}

local ok, reason = playerDebug.Play(entry)
T.truthy(ok and reason == "player_action_started",
    "player action did not start")
T.equal(state.actionName, "Loot", "wrong PerformingAction was selected")
T.equal(state.variables.LootPosition, "High",
    "player action selector was not applied")
T.equal(state.reportedEvent, "EventLootItem",
    "Loot action event was not reported")
T.equal(playerDebug.Runtime().mode, "player_action_context",
    "player action context mode was not reported")
T.equal(playerDebug.Runtime().requestedClip, entry.anim,
    "selected player clip was not reported")

ok, reason = playerDebug.SetLoopEnabled(true)
T.truthy(ok and reason == "loop_enabled", "loop mode did not enable")
T.truthy(playerDebug.Runtime().loopRequested,
    "active player action did not receive loop mode")
T.truthy(playerDebug.active.action.loopRequested,
    "timed action did not receive loop mode")
local previousAction = playerDebug.active.action
previousAction:perform()
T.truthy(playerDebug.active and playerDebug.active.action ~= previousAction,
    "looped player action was not requeued")
T.equal(playerDebug.Runtime().loopCount, 1,
    "looped player action repeat was not counted")
playerDebug.SetLoopEnabled(false)
T.falsy(playerDebug.Runtime().loopRequested,
    "active player action loop mode did not disable")

ok, reason = playerDebug.Play(entry)
T.falsy(ok, "busy player action was replaced unexpectedly")
T.equal(reason, "player_action_busy", "wrong busy-player refusal")

playerDebug.Stop("test_stop")
T.falsy(playerDebug.active, "player action survived stop")
T.equal(state.variables.LootPosition, nil,
    "debug selector was not cleared by action cleanup")
T.equal(state.variables.PerformingAction, nil,
    "PerformingAction was not cleared by action cleanup")
T.truthy(state.cleared.LootPosition,
    "debug action did not register its selector for cleanup")

local emoteEntry = {
    state = "Emote",
    mode = "emote",
    folder = "emote",
    file = "clap.xml",
    node = "clap",
    emote = "clap",
    anim = "Bob_EmoteClap",
    speed = 1.0,
    looped = true,
    playable = true,
}

ok, reason = playerDebug.Play(emoteEntry)
T.truthy(ok and reason == "player_emote_started",
    "player emote did not start")
T.equal(state.emote, "clap", "wrong player emote was selected")
T.truthy(state.emotePlaying, "player emote was not marked as playing")
T.equal(playerDebug.Runtime().mode, "player_emote_state",
    "player emote state mode was not reported")
T.equal(playerDebug.Runtime().requestedEmote, "clap",
    "selected emote key was not reported")

playerDebug.SetLoopEnabled(true)
T.truthy(playerDebug.Runtime().loopRequested,
    "active player emote did not receive loop mode")
state.emotePlaying = false
playerDebug.Maintain()
T.truthy(state.emotePlaying, "looped player emote was not replayed")
T.equal(playerDebug.Runtime().loopCount, 1,
    "looped player emote repeat was not counted")

state.cancelPressed = true
state.emotePlaying = false
playerDebug.Maintain()
T.falsy(playerDebug.active,
    "player emote loop ignored the native cancel action")
T.equal(playerDebug.Runtime().result.reason, "player_emote_cancelled",
    "wrong player emote cancellation result")
state.cancelPressed = false

playerDebug.Stop("test_emote_stop")
T.falsy(state.emotePlaying, "player emote survived stop")
T.falsy(playerDebug.active, "player emote survived stop")
playerDebug.SetLoopEnabled(false)

ok, reason = playerDebug.Replay()
T.falsy(ok, "replay started without an active preview")
T.equal(reason, "nothing_playing", "wrong no-preview replay result")

seated = true
ok, reason = playerDebug.Play(entry)
T.falsy(ok, "seated player was allowed to start a preview")
T.equal(reason, "player_seated_in_vehicle", "wrong seated-player refusal")
seated = false

dead = true
ok, reason = playerDebug.Play(entry)
T.falsy(ok, "dead player was allowed to start a preview")
T.equal(reason, "player_is_dead", "wrong dead-player refusal")
dead = false

localPlayer = false
ok, reason = playerDebug.Play(entry)
T.falsy(ok, "non-local player was allowed to start a preview")
T.equal(reason, "player_is_not_local", "wrong non-local-player refusal")
localPlayer = true

T.finish("pnc_player_animation_debug_smoke")
