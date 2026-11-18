-- Reusable authored characters; death/reservation stays in the world's registry.
require "PNC/Core/Definitions/PNC_DefinitionDatabase"
require "PNC/Core/Definitions/PNC_NPCDefinitionFile"
require "PNC/Core/Identity/PNC_UniqueNPCs"
PNC.LocalNPCCollection = PNC.LocalNPCCollection or { owned = {} }
local Collection = PNC.LocalNPCCollection
local Database, File, B = PNC.DefinitionDatabase, PNC.NPCDefinitionFile, PNC.NPCAuthoring.Blueprint
function Collection.CanPublish(player)
    if isClient and isClient() or isServer and isServer() then
        return player ~= nil and player.getAccessLevel ~= nil
            and string.lower(tostring(player:getAccessLevel())) == "admin"
    end
    return true
end
function Collection.Register(blueprint, fileName)
    local definition, reason = B.ToDefinition(blueprint)
    if not definition then return false, reason end
    if PNC.UniqueNPCs.Get(definition.id) and Collection.owned[definition.id] ~= fileName then
        return false, "duplicate_unique_definition"
    end
    local ok
    ok, reason = PNC.UniqueNPCs.Register(definition, { override = Collection.owned[definition.id] == fileName })
    if ok then Collection.owned[definition.id] = fileName end
    return ok, reason
end
function Collection.Load()
    -- Remote players' files are never discovered by the authority. A server
    -- reads only its own administrator-controlled local definition directory.
    if isClient and isClient() then return false, "not_authority" end
    local count, rejected = 0, 0
    for index, entry in ipairs(Database.List("npc")) do
        if index > 256 then break end
        local blueprint, _, produced = File.Decode(Database.ReadFile("npc", entry.fileName))
        if blueprint and produced then
            local ok = Collection.Register(blueprint, entry.fileName)
            if ok then count = count + 1 else rejected = rejected + 1 end
        end
    end
    return true, count, rejected
end
function Collection.Publish(player, fileName, serialized)
    if isClient and isClient() then return false, "not_authority" end
    if not Collection.CanPublish(player) then return false, "admin_required" end
    fileName = Database.SafeFileName(fileName)
    if not fileName then return false, "invalid_file_name" end
    local blueprint, reason = B.Deserialize(serialized)
    if not blueprint then return false, reason end
    local definition
    definition, reason = PNC.UniqueNPCs.NormalizeDefinition(blueprint)
    if not definition then return false, reason end
    if PNC.UniqueNPCs.Get(definition.id) and Collection.owned[definition.id] ~= fileName then return false, "duplicate_unique_definition" end
    local encoded
    encoded, reason = File.Encode(blueprint, true)
    if not encoded then return false, reason end
    local ok
    ok, reason = Database.WriteFile("npc", fileName, encoded)
    if not ok then return false, reason end
    ok, reason = Database.Upsert("npc", fileName, { definitionId = definition.id, displayName = definition.displayName, schemaVersion = 2 })
    if not ok then return false, reason end
    return Collection.Register(blueprint, fileName)
end
function Collection.ForgetFile(fileName)
    if isClient and isClient() then return end
    for id, ownedFile in pairs(Collection.owned) do
        if ownedFile == fileName then
            PNC.UniqueNPCs.Unregister(id)
            Collection.owned[id] = nil
        end
    end
end
function Collection.Delete(player, fileName)
    if isClient and isClient() then return false, "not_authority" end
    if not Collection.CanPublish(player) then return false, "admin_required" end
    local ok, reason = Database.Delete("npc", fileName)
    if not ok then return false, reason end
    Collection.ForgetFile(fileName)
    return true
end
return Collection
