local Nameplates = PNC.Nameplates
local State = Nameplates.State
local Internal = Nameplates.Internal
local Settings = Nameplates.Settings

local function initForPlayer(playerIndex)
    local player = getSpecificPlayer(playerIndex)
    if not player or State.managers[playerIndex] then return end
    local manager = ISPNCNameplateManager:new(playerIndex, player)
    manager:initialise()
    State.managers[playerIndex] = manager
end

local function onCreatePlayer(playerIndex)
    initForPlayer(playerIndex)
end

local function onGameStart()
    Internal.NormalizeDebugSetting()
    PNC.Runtime = PNC.Runtime or {}
    PNC.Runtime.nameplateDebugEnabled = Settings.showNameplateDebug == true
    for i = 0, getNumActivePlayers() - 1 do initForPlayer(i) end
end

local function onPreUIDraw()
    if isIngameState and not isIngameState() then return end
    for _, manager in pairs(State.managers) do
        if manager and manager.active then
            manager:update()
            manager:prerender()
            manager:render()
        end
    end
end

local function onResetLua()
    State.managers = {}
end

Events.OnCreatePlayer.Add(onCreatePlayer)
if Events and Events.OnGameBoot then
    Events.OnGameBoot.Add(Internal.NormalizeDebugSetting)
end
Events.OnGameStart.Add(onGameStart)
if Events and Events.OnPreUIDraw then
    Events.OnPreUIDraw.Add(onPreUIDraw)
end
if Events and Events.OnResetLua then Events.OnResetLua.Add(onResetLua) end
