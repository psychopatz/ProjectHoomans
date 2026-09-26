-- Companion Dogs compatibility: late-load installation and coarse runtime pump.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
local Bridge = PNC.Compatibility.CompanionDogs or {}
local Internal = Bridge.Internal or {}
Bridge.Internal = Internal

local MAX_INSTALL_ATTEMPTS = Internal.MAX_INSTALL_ATTEMPTS or 120
local registeredInstall = false
local attempts = 0

local function removeCallback(event, callback)
    if event and event.Remove then event.Remove(callback) end
end

local function unregisterInstall()
    local callback = Bridge._installCallback
    if not registeredInstall or not callback then return end
    removeCallback(Events and Events.OnGameBoot, callback)
    removeCallback(Events and Events.OnGameStart, callback)
    removeCallback(Events and Events.OnTick, callback)
    registeredInstall = false
end

local function attemptInstall()
    if Bridge.TryInstall() then
        unregisterInstall()
        return true
    end
    attempts = attempts + 1
    if attempts >= MAX_INSTALL_ATTEMPTS then unregisterInstall() end
    return false
end

local function runtimeTick()
    local current
    current = Internal.Now()
    if current < (tonumber(Bridge._nextRuntimeProbeAt) or 0) then
        return
    end
    Bridge._nextRuntimeProbeAt = current + 1000
    if not Bridge._flavorsRegistered then Bridge.RegisterFlavors() end
    if type(CompanionDogs) ~= "table" then return end
    Bridge.Pump()
end

Bridge._installCallback = attemptInstall
if not Bridge.TryInstall() and Events then
    if Events.OnGameBoot and Events.OnGameBoot.Add then
        Events.OnGameBoot.Add(attemptInstall)
        registeredInstall = true
    end
    if Events.OnGameStart and Events.OnGameStart.Add then
        Events.OnGameStart.Add(attemptInstall)
        registeredInstall = true
    end
    if Events.OnTick and Events.OnTick.Add then
        Events.OnTick.Add(attemptInstall)
        registeredInstall = true
    end
end

if Events and Events.OnTick and Events.OnTick.Add
    and not Bridge._runtimeRegistered
then
    Events.OnTick.Add(runtimeTick)
    Bridge._runtimeRegistered = true
end

return Bridge
