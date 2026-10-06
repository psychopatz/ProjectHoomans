local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
local CorpseItems =
    require "PsychopatzCore/Inventory/PsychopatzCorpseItems"
local FACTION_DOGTAG_SCHEMA_VERSION = 1
local corpseItemNeedsStateUpdate = Internal.CorpseItemNeedsStateUpdate
local factionDogtagKey = Internal.FactionDogtagKey

local function factionDogtagMetadata(record)
    local inv = record and record.inventory or nil
    local runtime = record and record.runtime or nil
    local candidate
    local metadata
    local factionID = record and record.affiliation
        and tostring(record.affiliation.factionID or "") or ""
    local factionName = record and tostring(record.factionName or "") or ""
    factionID = factionID ~= "" and factionID
        or tostring(record and record.factionID or "")
    factionID = factionID ~= "" and factionID
        or tostring(record and record.corpse
            and record.corpse.factionID or "")
    factionName = factionName ~= "" and factionName
        or tostring(record and record.corpse
            and record.corpse.factionName or "")
    local faction
    local npcID = tostring(record and record.id or "")
    local inventoryRevision = inv and tonumber(inv.revision) or 0
    local generatorVersion = inv and inv.template
        and tonumber(inv.template.generatorVersion) or 0
    if type(runtime) ~= "table" and record then
        runtime = {}
        record.runtime = runtime
    end
    if runtime
        and runtime.corpseFactionDogTagSourceInventory == inv
        and tonumber(runtime.corpseFactionDogTagSourceRevision)
            == inventoryRevision
        and tonumber(runtime.corpseFactionDogTagGeneratorVersion)
            == generatorVersion
        and tostring(runtime.corpseFactionDogTagSourceFactionID or "")
            == factionID
    then
        return runtime.corpseFactionDogTagSourceMetadata
    end
    for _, candidate in pairs(inv and inv.items or {}) do
        metadata = candidate and candidate.itemState
            and candidate.itemState.modData or nil
        if metadata and metadata.PNC_FactionDogTag == true
            and tostring(metadata.PNC_FactionDogTagNPCId or "") == npcID
            and tostring(metadata.PNC_FactionDogTagFactionId or "") ~= ""
            and tostring(metadata.PNC_FactionDogTagFactionName or "") ~= ""
        then
            metadata = {
                PNC_FactionDogTag = true,
                PNC_FactionDogTagVersion = FACTION_DOGTAG_SCHEMA_VERSION,
                PNC_FactionDogTagNPCId = npcID,
                PNC_FactionDogTagFactionId = tostring(
                    metadata.PNC_FactionDogTagFactionId
                ),
                PNC_FactionDogTagFactionName = tostring(
                    metadata.PNC_FactionDogTagFactionName
                ),
            }
            break
        end
    end
    faction = not metadata and factionID ~= "" and PNC.Factions
        and PNC.Factions.Get and PNC.Factions.Get(factionID) or nil
    if factionName == "" and faction then
        factionName = tostring(faction.name or "")
    end
    if not metadata and factionID ~= "" and factionName ~= ""
        and npcID ~= ""
    then
        metadata = {
            PNC_FactionDogTag = true,
            PNC_FactionDogTagVersion = FACTION_DOGTAG_SCHEMA_VERSION,
            PNC_FactionDogTagNPCId = npcID,
            PNC_FactionDogTagFactionId = factionID,
            PNC_FactionDogTagFactionName = factionName,
        }
    end
    if runtime then
        runtime.corpseFactionDogTagSourceInventory = inv
        runtime.corpseFactionDogTagSourceRevision = inventoryRevision
        runtime.corpseFactionDogTagGeneratorVersion = generatorVersion
        runtime.corpseFactionDogTagSourceFactionID = factionID
        runtime.corpseFactionDogTagSourceMetadata = metadata
    end
    return metadata
end

local function factionDogtagSpec(record, metadata)
    local npcID = tostring(record and record.id or "")
    local factionName = tostring(
        metadata.PNC_FactionDogTagFactionName or ""
    )
    return {
        fullType = "Base.Necklace_DogTag",
        key = factionDogtagKey(npcID),
        customName = "Dog Tags: " .. factionName,
        modData = metadata,
        match = function(item)
            local modData = item and item.getModData
                and item:getModData() or nil
            return Internal.itemFullType(item)
                == "Base.Necklace_DogTag"
                and modData and modData.PNC_FactionDogTag == true
                and tonumber(modData.PNC_FactionDogTagVersion)
                    == FACTION_DOGTAG_SCHEMA_VERSION
                and tostring(modData.PNC_FactionDogTagNPCId or "") == npcID
        end,
        create = function()
            return PNC.Equipment and PNC.Equipment.CreateItem
                and PNC.Equipment.CreateItem("Base.Necklace_DogTag") or nil
        end,
    }
end

function Internal.ensureCorpseFactionDogTag(record, target)
    local container
    local metadata
    local existing
    local item
    local created
    local reason
    local spec
    local changed
    if not record or not target then
        return nil, false, "invalid_faction_dogtag_target"
    end
    container = target.getContainer and target:getContainer()
        or target.getInventory and target:getInventory()
        or nil
    existing = CorpseItems.Find(container, {
        fullType = "Base.Necklace_DogTag",
        match = function(candidate)
            local data = candidate and candidate.getModData
                and candidate:getModData() or nil
            return Internal.itemFullType(candidate)
                == "Base.Necklace_DogTag"
                and data and data.PNC_FactionDogTag == true
                and tostring(data.PNC_FactionDogTagNPCId or "")
                    == tostring(record.id or "")
        end,
    })
    if existing then
        local data = existing.getModData
            and existing:getModData() or nil
        if data and tostring(data.PNC_FactionDogTagFactionId or "") ~= ""
            and tostring(data.PNC_FactionDogTagFactionName or "") ~= ""
        then
            metadata = {
                PNC_FactionDogTag = true,
                PNC_FactionDogTagVersion = FACTION_DOGTAG_SCHEMA_VERSION,
                PNC_FactionDogTagNPCId = tostring(record.id),
                PNC_FactionDogTagFactionId = tostring(
                    data.PNC_FactionDogTagFactionId
                ),
                PNC_FactionDogTagFactionName = tostring(
                    data.PNC_FactionDogTagFactionName
                ),
            }
            spec = factionDogtagSpec(record, metadata)
            changed = corpseItemNeedsStateUpdate(existing, spec)
            if changed then CorpseItems.ApplyState(existing, spec) end
            return existing, false, nil, changed
        end
    end
    metadata = factionDogtagMetadata(record)
    if not metadata then return nil, false, "faction_unavailable" end
    spec = factionDogtagSpec(record, metadata)
    existing = CorpseItems.Find(container, spec)
    changed = corpseItemNeedsStateUpdate(existing, spec)
    item, created, reason = CorpseItems.Inject(container, spec)
    return item, created == true, reason,
        item ~= nil and (created == true or changed) or false
end
