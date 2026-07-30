-- Stable, serialization-safe references to social relationship targets.

PNC = PNC or {}
PNC.EntityRef = PNC.EntityRef or {}

local EntityRef = PNC.EntityRef
local MAX_COMPONENT_LENGTH = 128

local function normalizeComponent(value)
    local kind = type(value)
    local text
    if kind ~= "string" and kind ~= "number" then
        return nil
    end
    text = tostring(value)
    if text == ""
        or #text > MAX_COMPONENT_LENGTH
        or string.find(text, ":", 1, true)
        or string.find(text, "%c")
    then
        return nil
    end
    return text
end

function EntityRef.ForNPC(npcID)
    npcID = normalizeComponent(npcID)
    if not npcID then
        return nil
    end
    return "npc:" .. npcID
end

function EntityRef.ForPlayerIdentity(accountIdentity, characterUUID)
    accountIdentity = normalizeComponent(accountIdentity)
    characterUUID = normalizeComponent(characterUUID)
    if not accountIdentity or not characterUUID then
        return nil
    end
    return "player:" .. accountIdentity .. ":" .. characterUUID
end

function EntityRef.Parse(key)
    local npcID
    local accountIdentity
    local characterUUID
    if type(key) ~= "string" then
        return nil
    end
    npcID = string.match(key, "^npc:([^:]+)$")
    if npcID then
        npcID = normalizeComponent(npcID)
        if not npcID then
            return nil
        end
        return {
            key = key,
            kind = "npc",
            id = npcID,
            npcID = npcID,
            targetID = npcID,
        }
    end
    accountIdentity, characterUUID =
        string.match(key, "^player:([^:]+):([^:]+)$")
    accountIdentity = normalizeComponent(accountIdentity)
    characterUUID = normalizeComponent(characterUUID)
    if not accountIdentity or not characterUUID then
        return nil
    end
    return {
        key = key,
        kind = "player",
        id = accountIdentity .. ":" .. characterUUID,
        accountIdentity = accountIdentity,
        characterUUID = characterUUID,
        targetID = accountIdentity .. ":" .. characterUUID,
    }
end

function EntityRef.IsNPC(key)
    local parsed = EntityRef.Parse(key)
    return parsed ~= nil and parsed.kind == "npc"
end

function EntityRef.IsPlayer(key)
    local parsed = EntityRef.Parse(key)
    return parsed ~= nil and parsed.kind == "player"
end

function EntityRef.IsValid(key)
    return EntityRef.Parse(key) ~= nil
end

return EntityRef
