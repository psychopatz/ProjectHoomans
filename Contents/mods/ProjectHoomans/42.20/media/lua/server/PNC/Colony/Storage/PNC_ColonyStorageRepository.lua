if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.ColonyStorageRepository = PNC.ColonyStorageRepository or {}

local Repository = PNC.ColonyStorageRepository
local Definitions = require "PNC/Core/Colony/Storage/PNC_ColonyStorageDefinitions"
local Journal = require "PNC/Core/Colony/Storage/PNC_ColonyStorageJournal"
local Inventory = require "PsychopatzCore/Inventory/PsychopatzInventory"

Repository.ByID = Repository.ByID or {}
Repository.PrimaryByFaction = Repository.PrimaryByFaction or {}
Repository.Loaded = Repository.Loaded == true
Repository.Dirty = Repository.Dirty == true

local function copy(value)
    return PNC.Core and PNC.Core.DeepCopy and PNC.Core.DeepCopy(value) or value
end

local function assign(target, source)
    for key, _ in pairs(target) do target[key] = nil end
    for key, value in pairs(source or {}) do target[key] = value end
end

local function serializedStorage(storage)
    local snapshot = Inventory.Serializer.serialize(storage.inventory)
    if not snapshot then return nil end
    snapshot[4] = false -- Capacity is derived exclusively from tier.
    return {
        schemaVersion = Definitions.SCHEMA_VERSION,
        storageId = storage.id,
        ownerFactionId = storage.ownerFactionId,
        settlementId = storage.settlementId,
        storageType = storage.storageType,
        tier = storage.tier,
        revision = storage.revision,
        inventorySnapshot = snapshot,
        activityJournal = Journal.Serialize(storage),
    }
end

local function hydrate(raw)
    if type(raw) ~= "table"
        or tonumber(raw.schemaVersion) ~= Definitions.SCHEMA_VERSION
        or tostring(raw.storageId or "") == ""
        or tostring(raw.ownerFactionId or "") == ""
    then return nil, "storage_schema_invalid" end
    local store, reason = Inventory.Serializer.deserialize(raw.inventorySnapshot)
    if not store then return nil, reason end
    local tier = Definitions.NormalizeTier(raw.tier)
    store.maxWeight = Definitions.GetCapacity(tier)
    local storage = {
        id = tostring(raw.storageId),
        ownerFactionId = tostring(raw.ownerFactionId),
        settlementId = raw.settlementId and tostring(raw.settlementId) or nil,
        storageType = tostring(raw.storageType or Definitions.PRIMARY_TYPE),
        tier = tier,
        revision = math.max(0, math.floor(tonumber(raw.revision) or 0)),
        inventory = store,
    }
    Journal.Deserialize(raw.activityJournal, storage.id)
    return storage
end

function Repository.Load()
    if Repository.Loaded then return true end
    local raw = ModData and ModData.getOrCreate
        and ModData.getOrCreate(Definitions.MODDATA_KEY) or {}
    for storageID, _ in pairs(Repository.ByID) do
        Journal.Remove(storageID)
    end
    Repository.ByID = {}
    Repository.PrimaryByFaction = {}
    for storageID, payload in pairs(raw.byID or {}) do
        local storage = hydrate(payload)
        if storage then
            Repository.ByID[storage.id] = storage
            if storage.storageType == Definitions.PRIMARY_TYPE then
                Repository.PrimaryByFaction[storage.ownerFactionId] = storage.id
            end
        elseif PNC.Core and PNC.Core.LogWarn then
            PNC.Core.LogWarn("Rejected colony storage payload id="
                .. tostring(storageID))
        end
    end
    Repository.Loaded = true
    Repository.Dirty = false
    return true
end

function Repository.EnsureLoaded()
    if not Repository.Loaded then return Repository.Load() end
    return true
end

function Repository.MarkDirty()
    Repository.Dirty = true
end

function Repository.Save()
    Repository.EnsureLoaded()
    if not Repository.Dirty then return false, "not_dirty" end
    local target = ModData and ModData.getOrCreate
        and ModData.getOrCreate(Definitions.MODDATA_KEY) or nil
    if not target then return false, "moddata_unavailable" end
    local output = { schemaVersion = Definitions.SCHEMA_VERSION, byID = {} }
    for storageID, storage in pairs(Repository.ByID) do
        output.byID[storageID] = serializedStorage(storage)
    end
    assign(target, output)
    Repository.Dirty = false
    return true, "saved"
end

function Repository.Get(storageID)
    Repository.EnsureLoaded()
    return Repository.ByID[tostring(storageID or "")]
end

function Repository.GetPrimary(factionID, settlementID)
    Repository.EnsureLoaded()
    factionID = tostring(factionID or "")
    if factionID == "" then return nil, "faction_required" end
    local storageID = Repository.PrimaryByFaction[factionID]
        or Definitions.PrimaryStorageID(factionID)
    local storage = Repository.ByID[storageID]
    if not storage then
        local tier = Definitions.PRIMARY.initialTier
        storage = {
            id = storageID,
            ownerFactionId = factionID,
            settlementId = settlementID and tostring(settlementID) or nil,
            storageType = Definitions.PRIMARY_TYPE,
            tier = tier,
            revision = 0,
            inventory = Inventory.createVirtualInventory({
                maxWeight = Definitions.GetCapacity(tier),
                authority = "server",
            }),
        }
        Repository.ByID[storageID] = storage
        Repository.PrimaryByFaction[factionID] = storageID
        Repository.Dirty = true
    elseif settlementID and storage.settlementId ~= tostring(settlementID) then
        storage.settlementId = tostring(settlementID)
        Repository.Dirty = true
    end
    return storage
end

function Repository.SerializeStorage(storage)
    return copy(serializedStorage(storage))
end

if Events and Events.OnInitGlobalModData and not Repository.LoadHookRegistered then
    Events.OnInitGlobalModData.Add(Repository.Load)
    Repository.LoadHookRegistered = true
end

return Repository
