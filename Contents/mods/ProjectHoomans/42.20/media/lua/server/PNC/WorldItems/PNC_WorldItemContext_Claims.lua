-- Transient TTL item-claim table preventing concurrent NPCs from targeting the same item.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorldItemContext = PNC.WorldItemContext or {}
PNC.WorldItemContext.Claims = PNC.WorldItemContext.Claims or {}

local Claims = PNC.WorldItemContext.Claims
local CLAIM_TTL_MS = 20000

Claims._byKey = Claims._byKey or {}

local function nowMs()
    return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

local function itemIdentity(item)
    if item and type(item.getID) == "function" then
        local ok, id = pcall(item.getID, item)
        if ok and id ~= nil then return id end
    end
    if type(item) == "table" and item.id ~= nil then return item.id end
    return tostring(item)
end

function Claims.Prune(now)
    now = tonumber(now) or nowMs()
    local expired = {}
    for key, claim in pairs(Claims._byKey) do
        if (tonumber(claim.expiresAt) or 0) <= now then
            expired[#expired + 1] = key
        end
    end
    for index = 1, #expired do
        Claims._byKey[expired[index]] = nil
    end
end

function Claims.MakeKey(sourceType, x, y, z, item)
    return tostring(sourceType or "") .. ":" .. tostring(x) .. ":"
        .. tostring(y) .. ":" .. tostring(z) .. ":" .. tostring(itemIdentity(item))
end

function Claims.IsClaimedByOther(key, npcId, now)
    local claim = Claims._byKey[tostring(key or "")]
    if not claim then return false end
    now = tonumber(now) or nowMs()
    if (tonumber(claim.expiresAt) or 0) <= now then
        Claims._byKey[tostring(key)] = nil
        return false
    end
    return tostring(claim.npcId or "") ~= tostring(npcId or "")
end

function Claims.Claim(key, npcId, now, ttlMs)
    key = tostring(key or "")
    if key == "" then return false end
    now = tonumber(now) or nowMs()
    if Claims.IsClaimedByOther(key, npcId, now) then return false end
    Claims._byKey[key] = {
        key = key,
        npcId = tostring(npcId or ""),
        expiresAt = now + (tonumber(ttlMs) or CLAIM_TTL_MS),
    }
    return true
end

function Claims.Release(key, npcId)
    key = tostring(key or "")
    local claim = Claims._byKey[key]
    if not claim then return false end
    if npcId ~= nil and tostring(claim.npcId or "") ~= tostring(npcId) then
        return false
    end
    Claims._byKey[key] = nil
    return true
end

function Claims.ReleaseForNPC(npcId)
    local targetId = tostring(npcId or "")
    local removeKeys = {}
    for key, claim in pairs(Claims._byKey) do
        if tostring(claim.npcId or "") == targetId then
            removeKeys[#removeKeys + 1] = key
        end
    end
    for index = 1, #removeKeys do
        Claims._byKey[removeKeys[index]] = nil
    end
end

return Claims
