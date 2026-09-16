-- Necroa policy boundary.
--
-- Necroa variants are native IsoZombie bodies, so they must stay on the
-- ordinary zombie lane. This module only tells Necroa when an IsoZombie or
-- corpse is actually owned by Hoomans and which Necroa-only behaviors must
-- be skipped. It deliberately does not register Necroa as a foreign actor
-- provider.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
PNC.Compatibility.Necroa = PNC.Compatibility.Necroa or {}

local Policy = PNC.Compatibility.Necroa
local ActorOwnership = PNC.Compatibility.ActorOwnership

local Mask = Policy.Mask
    or require "PNC/Core/Compatibility/Mods/Necroa/PNC_Necroa_Mask"

Policy.VERSION = 1
Policy.API_VERSION = 1

local function collectionContains(collection, wanted)
    local ok
    local result
    local index
    if not collection then return false end
    if collection.contains then
        ok, result = pcall(collection.contains, collection, wanted)
        if ok and result == true then return true end
    end
    if collection.size and collection.get then
        for index = 0, collection:size() - 1 do
            if tostring(collection:get(index)) == tostring(wanted) then
                return true
            end
        end
    end
    return false
end

function Policy.IsActive()
    local ok
    local mods
    if type(getActivatedMods) == "function" then
        ok, mods = pcall(getActivatedMods)
        if ok and collectionContains(mods, "Necroa") then
            return true
        end
    end
    -- These globals are client-side in current Necroa releases. They are
    -- still useful as a harmless fallback for single-player load order.
    return SusceptibleMod ~= nil or SusceptibleMaskItems ~= nil
end

local function modDataOf(object)
    local ok
    local value
    if not object or not object.getModData then return nil end
    ok, value = pcall(object.getModData, object)
    return ok and value or nil
end

local function isHoomansOwned(object)
    if not object then return false end
    if ActorOwnership and ActorOwnership.IsHoomansOwned then
        local ok, owned = pcall(ActorOwnership.IsHoomansOwned, object)
        if ok and owned == true then return true end
    end
    local data = modDataOf(object)
    return data and data.PNC_Owner == "ProjectHoomans"
        or false
end

function Policy.IsHoomansOwned(object)
    return isHoomansOwned(object)
end

function Policy.IsHoomansCorpse(object)
    local data = modDataOf(object)
    if not data then return false end
    return data.PNC_DeathMarkerID ~= nil
        or data.PNC_CorpseToken ~= nil
        or data.PNC_Owner == "ProjectHoomans"
end

function Policy.IsHoomansManagedObject(object)
    return isHoomansOwned(object) or Policy.IsHoomansCorpse(object)
end

function Policy.GetNPCID(object)
    local data = modDataOf(object)
    local id = data and data.PNC_UUID or nil
    return id and tostring(id) or nil
end

function Policy.ShouldSkipFeature(object, feature)
    feature = tostring(feature or "")

    -- Explosions are allowed to affect Hoomans, but only through the
    -- IncomingDamage capability. The Necroa client must never mutate health
    -- on a managed body directly.
    if feature == "incoming_damage" or feature == "explosion_aoe" then
        return false
    end

    -- Only Hoomans death markers are protected from Necroa reanimation and
    -- corpse contact infection. Ordinary Necroa/vanilla corpses keep their
    -- existing behavior.
    if feature == "corpse_reanimation"
        or feature == "corpse_infection"
    then
        return Policy.IsHoomansCorpse(object)
    end

    return Policy.IsHoomansManagedObject(object)
end

function Policy.ShouldRouteIncomingDamage(object)
    return Policy.IsHoomansOwned(object)
end

function Policy.CanNecroaInfect(object)
    return not Policy.IsHoomansManagedObject(object)
end

Policy.Mask = Mask

local function copyContext(context)
    local copy = {}
    local key
    if type(context) == "table" then
        for key, value in pairs(context) do
            copy[key] = value
        end
    end
    return copy
end

function Policy.ApplyIncomingDamage(target, context)
    local payload
    local data
    local amount
    local player
    local incoming
    local core = PNC.Core
    local const = PNC.Const or {}

    if not Policy.ShouldRouteIncomingDamage(target) then
        return false, "necroa_target_not_hoomans_owned"
    end

    payload = copyContext(context)
    amount = tonumber(payload.amount or payload.damage) or 0
    if amount <= 0 then return false, "necroa_damage_invalid" end
    payload.target = target
    payload.amount = math.min(amount, 100)
    payload.attackerProvider = payload.attackerProvider or "Necroa"
    payload.attackerKind = payload.attackerKind or "foreign_npc"
    payload.type = payload.type or "necroa_damage"

    if core and core.IsAuthority and core.IsAuthority() then
        incoming = PNC.Compatibility.IncomingDamage
        if not incoming or type(incoming.Apply) ~= "function" then
            return false, "incoming_damage_pipeline_unavailable"
        end
        return incoming.Apply(payload)
    end

    -- Multiplayer clients submit a bounded request. The server resolves the
    -- current live body by PNC_UUID and applies the authoritative wound event.
    if not isClient or not isClient() or type(sendClientCommand) ~= "function" then
        return false, "necroa_damage_authority_unavailable"
    end
    data = modDataOf(target)
    if not data or not data.PNC_UUID then
        return false, "necroa_target_identity_missing"
    end
    player = payload.player or (getPlayer and getPlayer() or nil)
    if not player then return false, "necroa_damage_request_player_missing" end
    sendClientCommand(
        player,
        const.MODULE or "PNC",
        const.CMD_NECROA_INCOMING_DAMAGE or "NecroaIncomingDamage",
        {
            npcID = tostring(data.PNC_UUID),
            amount = payload.amount,
            type = tostring(payload.type),
            woundType = payload.woundType and tostring(payload.woundType) or nil,
            attackerX = tonumber(payload.attackerX),
            attackerY = tonumber(payload.attackerY),
            attackerZ = tonumber(payload.attackerZ),
        }
    )
    return true, "necroa_damage_request_sent"
end

return Policy
