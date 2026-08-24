if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local SocialProfiles = PNC.SocialProfiles
local H = SocialProfiles.Internal
local Core = PNC.Core
local SocialTraits = PNC.SocialTraits
local CoreTraits = PsychopatzCore and PsychopatzCore.Traits

function H.IsAuthority()
    return Core and Core.IsAuthority and Core.IsAuthority() == true
end

function H.Copy(value)
    if Core and Core.DeepCopy then
        return Core.DeepCopy(value)
    end
    local output = {}
    local key
    local item
    for key, item in pairs(value or {}) do
        output[key] = type(item) == "table" and H.Copy(item) or item
    end
    return output
end

function H.Call(target, methodName)
    local method = target and target[methodName] or nil
    local ok
    local value
    if not method then return nil end
    ok, value = pcall(method, target)
    return ok and value or nil
end

function H.FiniteTimestamp(value)
    value = tonumber(value)
    if value == nil
        or value ~= value
        or value == math.huge
        or value == -math.huge
    then
        return nil
    end
    return math.max(0, value)
end

function H.WorldAgeHours(value)
    value = H.FiniteTimestamp(value)
    if value ~= nil then return value end
    local gameTime = getGameTime and getGameTime() or nil
    return gameTime and gameTime.getWorldAgeHours
        and math.max(0, tonumber(gameTime:getWorldAgeHours()) or 0) or 0
end

function H.ExtractTraitID(trait)
    local value
    if type(trait) == "string" then
        return SocialTraits.NormalizeTraitID(trait)
    end
    value = H.Call(trait, "toString")
    if value then
        value = SocialTraits.NormalizeTraitID(tostring(value))
        if value then return value end
    end
    value = H.Call(trait, "getName")
    return value and SocialTraits.NormalizeTraitID(tostring(value)) or nil
end

function H.ExtractTraitSet(player)
    if CoreTraits and CoreTraits.ReadPlayer then
        return CoreTraits.ReadPlayer(player, "ProjectHoomans.Social")
    end
    local characterTraits = H.Call(player, "getCharacterTraits")
    local known = H.Call(characterTraits, "getKnownTraits")
    local output = {}
    local size
    local index
    local trait
    local id
    if not known then return output, "ready" end
    size = H.Call(known, "size")
    if size ~= nil and known.get then
        for index = 0, math.max(0, tonumber(size) or 0) - 1 do
            local ok
            ok, trait = pcall(known.get, known, index)
            if ok then
                id = H.ExtractTraitID(trait)
                if id then output[id] = true end
            end
        end
        return output, "ready"
    end
    for _, trait in pairs(known) do
        id = H.ExtractTraitID(trait)
        if id then output[id] = true end
    end
    return output, "ready"
end

function H.LogProfile(kind, fields)
    if PNC.SocialProfileDebug and PNC.SocialProfileDebug.Log then
        fields = fields or {}
        fields.kind = kind
        PNC.SocialProfileDebug.Log(fields)
    end
end

function H.HasEntries(value)
    local _
    if type(value) ~= "table" then return false end
    for _, _ in pairs(value) do return true end
    return false
end

return H
