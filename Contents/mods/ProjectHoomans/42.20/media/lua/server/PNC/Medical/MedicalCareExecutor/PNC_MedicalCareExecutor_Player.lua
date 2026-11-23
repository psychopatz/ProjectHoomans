-- Build 42 player-patient resolution, treatable wound inspection, and authoritative bandaging.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Executor = PNC.MedicalCareExecutor
local Internal = Executor.Internal
local Service = Internal.Service
local Core = PNC.Core
local Treatment = Internal.Treatment
local Dressing = require "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Dressing"

local PLAYER_POLL_MS = 3000
local lastPlayerPollAt = -99999

local function call(obj, m, ...)
    local fn = obj and obj[m]
    if type(fn) ~= "function" then return nil end
    local ok, v = pcall(fn, obj, ...)
    if ok then return v end
end

local function playerEntityKey(p)
    if PNC.PlayerCharacters and type(PNC.PlayerCharacters.GetEntityKey) == "function" then
        local k = PNC.PlayerCharacters.GetEntityKey(p)
        if k and tostring(k) ~= "" then return tostring(k) end
    end
    local oid = call(p, "getOnlineID")
    if oid ~= nil and tonumber(oid) and tonumber(oid) >= 0 then return "player:" .. tostring(oid) end
    local uname = call(p, "getUsername")
    return (uname and tostring(uname) ~= "") and ("player:" .. tostring(uname)) or "player:local"
end

function Internal.ResolvePlayer(task)
    local key = type(task) == "table" and tostring(task.patientId or "") or tostring(task or "")
    if key == "" or not Core or type(Core.ForEachPlayer) ~= "function" then return nil end
    local found = nil
    Core.ForEachPlayer(function(p)
        if found or not p or call(p, "isDead") == true then return end
        local oid, uname = call(p, "getOnlineID"), call(p, "getUsername")
        if playerEntityKey(p) == key or (uname and (uname == key or ("player:" .. tostring(uname)) == key))
            or (oid ~= nil and (tostring(oid) == key or ("player:" .. tostring(oid)) == key)) then
            found = p
        end
    end)
    return found
end

local function findTreatablePlayerPart(player)
    if not player or call(player, "isDead") == true then return nil end
    local bd = call(player, "getBodyDamage")
    local parts = bd and call(bd, "getBodyParts") or nil
    local count = tonumber(parts and call(parts, "size")) or 0
    local bestOpen, bestDirty = nil, nil
    for i = 0, count - 1 do
        local part = call(parts, "get", i)
        if part then
            local idx = tonumber(call(part, "getIndex")) or i
            local pId = tostring(call(part, "getType") or ("Part_" .. tostring(idx)))
            local isB = call(part, "bandaged") == true
            if isB and call(part, "isBandageDirty") == true then
                if not bestDirty then
                    bestDirty = { part = part, index = idx, partId = pId, dirty = true, bleeding = false, pri = 0 }
                end
            elseif not isB then
                local bld = call(part, "bleeding") == true or (tonumber(call(part, "getBleedingTime")) or 0) > 0
                local open = bld or call(part, "bitten") == true or call(part, "isCut") == true
                    or call(part, "scratched") == true or call(part, "isDeepWounded") == true
                    or (tonumber(call(part, "getBurnTime")) or 0) > 0
                if open then
                    local pri = (call(part, "bitten") == true and 4 or 0) + (bld and 3 or 1)
                    if not bestOpen or pri > bestOpen.pri then
                        bestOpen = { part = part, index = idx, partId = pId, dirty = false, bleeding = bld, pri = pri }
                    end
                end
            end
        end
    end
    return bestOpen or bestDirty
end
Internal.FindTreatablePlayerPart = findTreatablePlayerPart

function Internal.ApplyNPCTreatmentToPlayer(actor, player, partInfo, options)
    options = type(options) == "table" and options or {}
    if not (Core and Core.IsAuthority and Core.IsAuthority() == true) then return false, "not_authority" end
    if not actor or actor.alive == false then return false, "actor_missing" end
    if not player or call(player, "isDead") == true then return false, "patient_missing" end
    local part, partIdx = type(partInfo) == "table" and partInfo.part, type(partInfo) == "table" and partInfo.index
    if not part or partIdx == nil then return false, "patient_has_no_treatable_wound" end

    local policy = Treatment.GetNPCMedicalPolicy(actor, options)
    local supply, consumed, undo = nil, true, nil
    if policy.requiresItem then
        supply = Treatment.Internal.FindNPCBandage(actor, options.bandageType)
        if not supply then return false, "missing_bandage" end
        consumed, undo = Treatment.Internal.ConsumeNPCBandage(actor, supply, options.consumeReason or "medical_care_player")
        if not consumed then return false, "bandage_consumption_failed" end
    end

    local fullType = supply and supply.fullType or policy.bandageType
    local profile = Dressing.Profile(fullType) or { power = 2, sterile = false }
    local life = Dressing.Life(profile, Treatment.GetNPCFirstAidLevel(actor))
    local oldType = call(part, "bandaged") == true and call(part, "getBandageType") or nil
    local oldDirty = oldType and (Dressing.ReturnType({ bandaged = true, bandageType = oldType, bandageDirty = true }) or oldType) or nil
    local bd = call(player, "getBodyDamage")
    local ok = (bd and bd.SetBandaged and pcall(bd.SetBandaged, bd, partIdx, true, life, profile.sterile == true, fullType))
        or (part.setBandaged and pcall(part.setBandaged, part, true, life, profile.sterile == true, fullType))
    if ok ~= true then
        if undo then undo() end
        return false, "player_bandage_apply_failed"
    end
    if type(syncBodyPart) == "function" then pcall(syncBodyPart, part, 0xc001966b8e) end
    local inv = PNC.Inventory
    if policy.requiresItem and oldDirty and oldDirty ~= "PNC.AbstractMedical" and inv and inv.AddItems then
        local addOk, _, ids = inv.AddItems(actor, { { type = oldDirty, stack = 1 } }, "root", "removed_dressing")
        local b = addOk and ids and ids[1] and PNC.Registry and PNC.Registry.GetLiveZombie and PNC.Registry.GetLiveZombie(actor.id)
        if b and inv.MaterializeItem then inv.MaterializeItem(actor, b, ids[1]) end
    end
    if PNC.Skills and PNC.Skills.AddXP then PNC.Skills.AddXP(actor, "FirstAid", 1) end
    return true, supply and supply.displayName or policy.bandageName, { dirtyReplaced = partInfo.dirty == true, partId = partInfo.partId }
end

function Executor.PollInjuredPlayers(now)
    now = tonumber(now) or (Core and Core.Now and Core.Now()) or 0
    if now - lastPlayerPollAt < PLAYER_POLL_MS then return 0 end
    lastPlayerPollAt = now
    if not (Core and Core.IsAuthority and Core.IsAuthority() == true) or not Core.ForEachPlayer or not Service then return 0 end
    local count = 0
    Core.ForEachPlayer(function(player)
        if not player or call(player, "isDead") == true then return end
        local key, partInfo = playerEntityKey(player), findTreatablePlayerPart(player)
        local active = Service.FindForPatient("player", key)
        if partInfo and not active then
            Service.RequestPlayer(key, {
                source = partInfo.dirty and "player_bandage_dirty" or "player_wound",
                woundParts = { partInfo.partId }, severity = partInfo.bleeding and 50 or 25,
                policy = { requireItem = true },
            })
            count = count + 1
        elseif not partInfo and active then
            Service.ResolveForPatient("player", key, "patient_wound_resolved")
        end
    end)
    return count
end

return Executor
