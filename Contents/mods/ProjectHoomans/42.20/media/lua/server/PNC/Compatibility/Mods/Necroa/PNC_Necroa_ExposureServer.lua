-- Server-authoritative Necroa airborne-exposure compatibility.
-- Only Hoomans records enter NPCWounds; native Necroa zombies are untouched.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
PNC.Compatibility.Necroa = PNC.Compatibility.Necroa or {}

local Policy = PNC.Compatibility.Necroa
    or require "PNC/Core/Compatibility/Mods/Necroa/PNC_Necroa_Policy"
local Mask = Policy.Mask
    or require "PNC/Core/Compatibility/Mods/Necroa/PNC_Necroa_Mask"
local Registry = PNC.Registry
local Network = PNC.Network
local Observers = require "PNC/Compatibility/Mods/Necroa/PNC_Necroa_ExposureServer_Observers"

local Exposure = PNC.Compatibility.Necroa.Exposure or {}
PNC.Compatibility.Necroa.Exposure = Exposure
Exposure.INTERVAL_MS = 1000
Exposure.RADIUS = 14
Exposure.State = Exposure.State or { npcMask = {}, playerMask = {} }
Exposure.State.npcMask = Exposure.State.npcMask or {}
Exposure.State.playerMask = Exposure.State.playerMask or {}
Exposure.State.playerWarningAt = Exposure.State.playerWarningAt or {}
Exposure.LastPumpAt = Exposure.LastPumpAt or 0

local function nowMillis()
    if getTimeInMillis then return tonumber(getTimeInMillis()) or 0 end
    return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

local function players()
    local output = {}
    local list
    if isServer and isServer() and getOnlinePlayers then
        list = getOnlinePlayers()
        if list and list.size and list.get then
            for index = 0, list:size() - 1 do
                output[#output + 1] = list:get(index)
            end
        end
    end
    return output
end

local function broadcastInfection(record)
    if Network and Network.BroadcastRecord then
        Network.BroadcastRecord(record, "necroa_airborne_exposure")
    end
end

local function infectIfUnmasked(record, hasMask)
    local infection = record.health and record.health.body
        and record.health.body.infection or nil
    local wounds = PNC.NPCWounds
    if hasMask or not wounds or not wounds.ForceInfection then
        return false
    end
    if infection and (infection.active == true or infection.fatal == true) then
        return false
    end
    local applied = wounds.ForceInfection(record, "head")
    if applied == true then broadcastInfection(record) end
    return applied == true
end

function Exposure.Pump(now)
    local timestamp = tonumber(now) or nowMillis()
    local onlinePlayers
    if timestamp - (Exposure.LastPumpAt or 0) < Exposure.INTERVAL_MS
    then
        return false
    end
    if not Policy.IsActive() then return false end
    Exposure.LastPumpAt = timestamp
    onlinePlayers = players()
    Registry.ForEachLive(function(record, body)
        local hasMask
        local previous
        if not record or record.alive == false or not body
            or (body.isDead and body:isDead())
        then
            return
        end
        -- Hoomans' logical inventory/equipment state is authoritative for
        -- NPCs. It is updated by the same transfer pipeline that removes a
        -- mask from the NPC inventory UI. Only use the live body as a
        -- compatibility fallback for legacy records without that state.
        if record.equipment or record.inventory then
            hasMask = Mask.HasRecordMask(record)
        else
            hasMask = Mask.HasMask(body)
        end
        previous = Exposure.State.npcMask[record.id]
        Exposure.State.npcMask[record.id] = hasMask
        infectIfUnmasked(record, hasMask)
        if previous == true and not hasMask then
            Observers.NPC(Exposure, record, body, onlinePlayers)
        end
    end)
    for _, player in ipairs(onlinePlayers) do
        if player and not (player.isDead and player:isDead()) then
            Observers.Player(Exposure, player)
        end
    end
    return true
end

return Exposure
