if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

PNC = PNC or {}
PNC.CoreWorldDiscoveryAdapter =
    PNC.CoreWorldDiscoveryAdapter or {}

local Adapter = PNC.CoreWorldDiscoveryAdapter
local Discovery = PNC.WorldDiscovery
local Types = PNC.WorldDiscoveryTypes
local Reset = PNC.ModDataStore
    or require "PNC/Core/Persistence/PNC_ModDataStore"
local World = require
    "PsychopatzCore/SurvivorWorld/PsychopatzSurvivorWorld"

local function copy(value)
    if PNC.Core and PNC.Core.DeepCopy then
        return PNC.Core.DeepCopy(value)
    end
    if type(value) ~= "table" then return value end
    local output = {}
    for key, child in pairs(value) do
        output[copy(key)] = copy(child)
    end
    return output
end

local function pncKind(coreKind)
    if coreKind == "community" then return Types.KIND_SETTLEMENT end
    if coreKind == "group" then return Types.KIND_MOBILE_GROUP end
    return coreKind
end

local function coreKind(kind)
    if kind == Types.KIND_SETTLEMENT then return "community" end
    if kind == Types.KIND_MOBILE_GROUP then return "group" end
    return kind
end

local function coreEntry(kind, entityID, source)
    source = type(source) == "table" and source or {}
    return {
        entityID = tostring(entityID),
        kind = coreKind(kind),
        phase = math.max(
            0,
            math.min(3, math.floor(tonumber(source.phase) or 0))
        ),
        source = tostring(source.source or "legacy"),
        discoveredAt = math.max(0, tonumber(source.discoveredAt) or 0),
        updatedAt = math.max(0, tonumber(source.updatedAt) or 0),
        x = tonumber(source.x),
        y = tonumber(source.y),
        z = tonumber(source.z) or 0,
        arrivalState = tostring(source.arrivalState or "unchecked"),
        searchedAt = math.max(0, tonumber(source.searchedAt) or 0),
        contactedAt = math.max(0, tonumber(source.contactedAt) or 0),
        presenceStatus = tostring(source.presenceStatus or "unknown"),
        factionKnown = source.factionKnown == true,
        factionID = source.factionID,
        factionName = source.factionName,
    }
end

function Adapter.ToCore(raw)
    raw = type(raw) == "table" and raw or {}
    local output = {
        revision = math.max(0, math.floor(tonumber(raw.revision) or 0)),
        players = {},
    }
    for key, source in pairs(raw.players or {}) do
        local player = {
            revision = math.max(
                0,
                math.floor(tonumber(source.revision) or 0)
            ),
            lastRadioScanAt = math.max(
                0,
                tonumber(source.lastRadioScanAt) or 0
            ),
            radioScanCount = math.max(
                0,
                math.floor(tonumber(source.radioScanCount) or 0)
            ),
            entities = {
                community = {},
                group = {},
                signal = {},
            },
        }
        for kind, entries in pairs(source.entities or {}) do
            local targetKind = coreKind(kind)
            if player.entities[targetKind] then
                for entityID, entry in pairs(entries or {}) do
                    player.entities[targetKind][entityID] =
                        coreEntry(kind, entityID, entry)
                end
            end
        end
        output.players[tostring(key)] = player
    end
    return output
end

function Adapter.ToPNC(raw)
    raw = type(raw) == "table" and raw or {}
    local output = {
        schemaVersion = Types.SCHEMA_VERSION,
        revision = math.max(0, math.floor(tonumber(raw.revision) or 0)),
        players = {},
    }
    for key, source in pairs(raw.players or {}) do
        local player = {
            revision = math.max(
                0,
                math.floor(tonumber(source.revision) or 0)
            ),
            lastRadioScanAt = math.max(
                0,
                tonumber(source.lastRadioScanAt) or 0
            ),
            radioScanCount = math.max(
                0,
                math.floor(tonumber(source.radioScanCount) or 0)
            ),
            entities = {
                settlement = {},
                mobile_group = {},
            },
        }
        for kind, entries in pairs(source.entities or {}) do
            local targetKind = pncKind(kind)
            if player.entities[targetKind] then
                for entityID, entry in pairs(entries or {}) do
                    local item = copy(entry)
                    item.kind = targetKind
                    item.entityID = tostring(entityID)
                    player.entities[targetKind][entityID] = item
                end
            end
        end
        output.players[tostring(key)] = player
    end
    return output
end

local function mergeEntry(current, incoming)
    if not current then return copy(incoming), true end
    local changed = false
    if (tonumber(incoming.phase) or 0)
        > (tonumber(current.phase) or 0)
    then
        current.phase = incoming.phase
        changed = true
    end
    for _, field in ipairs({
        "source", "discoveredAt", "updatedAt",
        "x", "y", "z", "arrivalState",
        "searchedAt", "contactedAt",
        "presenceStatus", "factionKnown",
        "factionID", "factionName",
    }) do
        local incomingValue = incoming[field]
        if incomingValue ~= nil then
            if field == "searchedAt"
                or field == "contactedAt"
                or field == "updatedAt"
            then
                if (tonumber(incomingValue) or 0)
                    > (tonumber(current[field]) or 0)
                then
                    current[field] = copy(incomingValue)
                    changed = true
                end
            elseif current[field] == nil then
                current[field] = copy(incomingValue)
                changed = true
            elseif field == "factionKnown"
                and incomingValue == true
                and current[field] ~= true
            then
                current[field] = true
                changed = true
            end
        end
    end
    return current, changed
end

function Adapter.Merge(core, legacy)
    core = type(core) == "table" and copy(core)
        or { revision = 0, players = {} }
    legacy = Adapter.ToCore(legacy)
    core.players = core.players or {}
    local changed = false

    for key, incomingPlayer in pairs(legacy.players or {}) do
        local current = core.players[key]
        if not current then
            core.players[key] = copy(incomingPlayer)
            changed = true
        else
            current.entities = current.entities or {
                community = {}, group = {}, signal = {},
            }
            for _, kind in ipairs({
                "community", "group", "signal",
            }) do
                current.entities[kind] =
                    current.entities[kind] or {}
                for entityID, incoming in pairs(
                    incomingPlayer.entities[kind] or {}
                ) do
                    local merged, didChange = mergeEntry(
                        current.entities[kind][entityID],
                        incoming
                    )
                    current.entities[kind][entityID] = merged
                    changed = changed or didChange
                end
            end
            current.lastRadioScanAt = math.max(
                tonumber(current.lastRadioScanAt) or 0,
                tonumber(incomingPlayer.lastRadioScanAt) or 0
            )
            current.radioScanCount = math.max(
                tonumber(current.radioScanCount) or 0,
                tonumber(incomingPlayer.radioScanCount) or 0
            )
        end
    end
    return core, changed
end

local function registry()
    local authority = PNC.CoreSurvivorWorldAuthority
    local current = authority and authority.Registry
    if current then return current end
    return World.GetRuntimeRegistry()
end

function Adapter.SyncFromCore()
    local current = registry()
    if not current then
        return false, "core_survivor_world_unavailable"
    end
    Discovery.Registry =
        Adapter.ToPNC(current:GetDiscovery())
    Discovery.Loaded = true
    Discovery.Dirty = false
    return true
end

function Adapter.SyncToCore(reason)
    local current = registry()
    if not current then
        return false, "core_survivor_world_unavailable"
    end

    -- PNC's compatibility schema knows settlements and mobile groups but not
    -- Core-only discovery kinds such as signals. Replace only the kinds PNC
    -- owns for players present in the compatibility view; preserve all other
    -- canonical discovery data.
    local canonical = current:GetDiscovery()
    local incoming = Adapter.ToCore(Discovery.Registry)
    canonical.players = canonical.players or {}
    for key, source in pairs(incoming.players or {}) do
        local target = canonical.players[key] or {
            revision = 0,
            lastRadioScanAt = 0,
            radioScanCount = 0,
            entities = {
                community = {},
                group = {},
                signal = {},
            },
        }
        target.entities = target.entities or {}
        target.entities.community = copy(
            source.entities and source.entities.community or {}
        )
        target.entities.group = copy(
            source.entities and source.entities.group or {}
        )
        target.entities.signal =
            target.entities.signal or {}
        target.revision = math.max(
            tonumber(target.revision) or 0,
            tonumber(source.revision) or 0
        )
        target.lastRadioScanAt = math.max(
            tonumber(target.lastRadioScanAt) or 0,
            tonumber(source.lastRadioScanAt) or 0
        )
        target.radioScanCount = math.max(
            tonumber(target.radioScanCount) or 0,
            tonumber(source.radioScanCount) or 0
        )
        canonical.players[key] = target
    end

    current:SetDiscovery(canonical)
    local dirty, dirtyReason =
        World.RuntimeStore.MarkDirty(
            reason or "pnc_world_discovery"
        )
    if dirty == false then return false, dirtyReason end
    Discovery.Dirty = false
    return true
end

function Adapter.Save(reason)
    local ok, failure =
        Adapter.SyncToCore(reason)
    if not ok then return false, failure end
    local saved, saveReason =
        World.RuntimeStore.Save()
    if saved == false and saveReason ~= "not_dirty" then
        return false, saveReason
    end
    return true, "saved"
end

function Adapter.ActivateCutover()
    local current = registry()
    if not current then
        return false, "core_survivor_world_unavailable"
    end
    if Discovery.Loaded ~= true
        and Discovery.Load
    then
        Discovery.Load()
    end

    local legacy = copy(Discovery.Registry or {})
    local merged, changed = Adapter.Merge(
        current:GetDiscovery(),
        legacy
    )
    if changed then
        current:SetDiscovery(merged)
        World.RuntimeStore.MarkDirty(
            "pnc_world_discovery_legacy_import"
        )
        local saved, reason =
            World.RuntimeStore.Save()
        if saved == false and reason ~= "not_dirty" then
            return false, reason
        end
    end

    Adapter.Active = true
    Adapter.SyncFromCore()

    local raw = Reset.Read(Types.MODDATA_KEY)
    if type(raw) == "table"
        and next(raw) ~= nil
    then
        local retired = Reset.Write(
            Types.MODDATA_KEY,
            {}
        )
        if not retired then
            return false, "legacy_discovery_retire_failed"
        end
    end

    local server =
        PsychopatzCore.SurvivorWorldDiscoveryServer
    if server
        and type(server.RegisterPlayerKeyResolver)
            == "function"
    then
        server.RegisterPlayerKeyResolver(
            "ProjectHoomans",
            {
                priority = 300,
                resolve = function(player)
                    return Discovery.Internal.CharacterUUID(player)
                end,
            }
        )
    end

    Adapter.LastCutover = {
        accepted = true,
        importedLegacy = changed == true,
    }
    return true, changed
        and "legacy_cutover_complete"
        or "cutover_active"
end

local function onInitGlobalModData()
    Adapter.ActivateCutover()
end

if Events and Events.OnInitGlobalModData
    and type(Events.OnInitGlobalModData.Add) == "function"
    and not Adapter.HookRegistered
then
    Adapter.HookRegistered = true
    Events.OnInitGlobalModData.Add(
        onInitGlobalModData
    )
end

return Adapter
