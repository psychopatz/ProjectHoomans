PNC = PNC or {}
PNC.Persistence = PNC.Persistence or {}
PNC.Persistence.Internal = PNC.Persistence.Internal or {}

local Persistence = PNC.Persistence
local Internal = Persistence.Internal
local Core = PNC.Core
local Const = PNC.Const
local Identity = PNC.Identity
local Types = PNC.Types
local Inventory = PNC.Inventory
local RelationshipTypes = PNC.RelationshipTypes
local RelationshipMath = PNC.RelationshipMath
local FactionTypes = PNC.FactionTypes

function Persistence.LoadAll(serializedRecords)
    local output = {}
    local id
    local raw
    local record
    if type(serializedRecords) ~= "table" then
        return output
    end
    for id, raw in pairs(serializedRecords) do
        record = Persistence.DeserializeRecord(raw, id)
        if record and record.id then
            output[record.id] = record
        end
    end
    return output
end

function Persistence.SaveAll(records)
    local output = {}
    local id
    local raw
    if type(records) ~= "table" then
        return output
    end
    for id, raw in pairs(records) do
        raw = Persistence.SerializeRecord(raw)
        if raw then
            output[id] = raw
        end
    end
    return output
end
