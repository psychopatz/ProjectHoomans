-- Lightweight persisted death locations. Full NPC records are retired at
-- death; these markers exist only while the corresponding engine corpse can
-- still be found at the recorded square.

PNC = PNC or {}
PNC.Registry = PNC.Registry or {}

local Registry = PNC.Registry
local Core = PNC.Core
local Settings = PNC.Sandbox

Registry.DeathMarkers = Registry.DeathMarkers or {}
Registry.DeathMarkerRuntime = Registry.DeathMarkerRuntime or {}

local function normalizeString(value)
    if value == nil or value == "" then return nil end
    return tostring(value)
end

local function normalizeMarker(source, fallbackID)
    local marker
    if type(source) ~= "table" then return nil end
    marker = {
        id = normalizeString(source.id or fallbackID),
        name = normalizeString(source.name or source.displayName) or "Unknown NPC",
        x = tonumber(source.x) or 0,
        y = tonumber(source.y) or 0,
        z = tonumber(source.z) or 0,
        corpseToken = normalizeString(source.corpseToken or source.token),
        createdWorldHour = tonumber(source.createdWorldHour) or 0,
        infected = source.infected == true,
        colonist = source.colonist == true
            or source.recruited == true
            or tostring(source.faction or "") == "colonist",
        portrait = PNC.Identity
            and PNC.Identity.NormalizePortraitSummary
            and PNC.Identity.NormalizePortraitSummary(source.portrait)
            or nil,
        reanimationDelaySeconds = math.max(
            1,
            tonumber(source.reanimationDelaySeconds) or 3
        ),
    }
    return marker.id and marker or nil
end

local function runtimeFor(marker, fresh)
    local id = marker and tostring(marker.id) or nil
    local runtime
    if not id then return nil end
    runtime = Registry.DeathMarkerRuntime[id]
    if not runtime then
        runtime = {
            createdAt = Core.Now(),
            reanimateAt = marker.infected == true
                and (fresh == true
                    and Core.Now() + marker.reanimationDelaySeconds * 1000
                    or Core.Now())
                or 0,
            missingSinceAt = 0,
            corpseState = "unresolved",
            reanimationSpawned = false,
            reanimationSpawnInProgress = false,
            reanimationSpawnAttempts = 0,
            nextReanimationSpawnAt = 0,
        }
        Registry.DeathMarkerRuntime[id] = runtime
    end
    return runtime
end

function Registry.LoadDeathMarkers(directory)
    local source = type(directory and directory.deathMarkers) == "table"
        and directory.deathMarkers or {}
    local loaded = {}
    local id
    local marker
    Registry.DeathMarkerRuntime = {}
    for id, marker in pairs(source) do
        marker = normalizeMarker(marker, id)
        if marker then
            loaded[marker.id] = marker
            runtimeFor(marker, false)
        end
    end
    directory.deathMarkers = loaded
    Registry.DeathMarkers = loaded
    return loaded
end

function Registry.AddDeathMarker(record)
    local directory
    local infection = record and record.health and record.health.body
        and record.health.body.infection or nil
    local corpse = record and record.corpse or nil
    local marker
    if Core.IsAuthority and not Core.IsAuthority() then return nil end
    if not record or not record.id or not Registry.GetStorageDirectory then
        return nil
    end
    directory = Registry.GetStorageDirectory()
    marker = normalizeMarker({
        id = record.id,
        name = record.name or record.displayName,
        x = corpse and corpse.x or record.x,
        y = corpse and corpse.y or record.y,
        z = corpse and corpse.z or record.z,
        corpseToken = corpse and corpse.token,
        createdWorldHour = corpse and corpse.createdWorldHour,
        infected = infection and infection.fatal == true or false,
        colonist = record.recruited == true
            or tostring(record.faction or "") == "colonist",
        portrait = PNC.Identity
            and PNC.Identity.BuildPortraitSummary
            and PNC.Identity.BuildPortraitSummary(record)
            or nil,
        reanimationDelaySeconds = Settings and Settings.NPCReanimationSeconds
            and Settings.NPCReanimationSeconds() or 3,
    })
    if not marker then return nil end
    directory.deathMarkers[marker.id] = marker
    Registry.DeathMarkers[marker.id] = marker
    Registry.DeathMarkerRuntime[marker.id] = nil
    runtimeFor(marker, true)
    Registry.DirectoryDirty = true
    return marker
end

function Registry.GetDeathMarker(id)
    return id ~= nil and Registry.DeathMarkers[tostring(id)] or nil
end

function Registry.GetDeathMarkerRuntime(id)
    local marker = Registry.GetDeathMarker(id)
    return marker and runtimeFor(marker, false) or nil
end

function Registry.ForEachDeathMarker(callback)
    local id
    local marker
    if type(callback) ~= "function" then return end
    for id, marker in pairs(Registry.DeathMarkers) do
        callback(marker, id)
    end
end

function Registry.RemoveDeathMarker(id, reason)
    local directory
    if Core.IsAuthority and not Core.IsAuthority() then return false end
    if id == nil or not Registry.GetStorageDirectory then return false end
    id = tostring(id)
    directory = Registry.GetStorageDirectory()
    Registry.DeathMarkers[id] = nil
    Registry.DeathMarkerRuntime[id] = nil
    directory.deathMarkers[id] = nil
    Registry.DirectoryDirty = true
    if PNC.Network and PNC.Network.BroadcastDeathMarkerRemoval then
        PNC.Network.BroadcastDeathMarkerRemoval(
            id,
            reason or "corpse_removed"
        )
    elseif PNC.Network and PNC.Network.BroadcastRemoval then
        PNC.Network.BroadcastRemoval(id, reason or "corpse_removed")
    end
    return true
end

function Registry.MigrateDeadRecords()
    local dead = {}
    local id
    local record
    for id, record in pairs(Registry.Data) do
        if record.alive == false then dead[#dead + 1] = record end
    end
    for id = 1, #dead do
        record = dead[id]
        if not Registry.GetDeathMarker(record.id) then
            Registry.AddDeathMarker(record)
        end
        Registry.RemoveRecord(record.id)
    end
    return #dead
end

return Registry
