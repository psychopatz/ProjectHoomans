-- Bounded, refresh-local caches for the Puppet Opera debug model.
--
-- The cache is only active while the debug window is rebuilding its views.
-- It is never a time-based gameplay cache, and it is discarded at the end of
-- the refresh so live discovery remains authoritative between UI refreshes.

PNC = PNC or {}
PNC.PuppetOperaDebugModel = PNC.PuppetOperaDebugModel or {}

local Model = PNC.PuppetOperaDebugModel
local Internal = Model.Internal or {}
local State = Internal.State or Model.State
local active = false
local cache

local function newCache()
    cache = {
        changeSerial = State.changeSerial,
    }
end

local function invalidate()
    if active then newCache() end
end

local function getCache()
    if not active then return nil end
    if not cache or cache.changeSerial ~= State.changeSerial then
        newCache()
    end
    return cache
end

Internal.getRefreshCache = getCache
Internal.invalidateRefreshCache = invalidate

function Model.BeginRefresh()
    active = true
    newCache()
end

function Model.InvalidateRefreshCache()
    invalidate()
end

function Model.EndRefresh()
    active = false
    cache = nil
end

return Model
