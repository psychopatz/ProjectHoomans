-- Modular ProjectHoomans scene materializer for Core SurvivorWorld.Events.
-- Spawns bounded emergent aftermath loot or wakes sheltering SOS colonists
-- once when a player approaches, then marks the event materialized in Core.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

PNC = PNC or {}
PNC.AbstractAftermathMaterializer = PNC.AbstractAftermathMaterializer or {}

local Mod = PNC.AbstractAftermathMaterializer
local EventMaterializer = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldEventMaterializer"
local WorldEvents = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldEvents"

local STANDARD_LOOT = {
    "Base.Bandage",
    "Base.TinnedBeans",
    "Base.WaterBottleFull",
}

local HIGH_TIER_LOOT = {
    "Base.Bandage",
    "Base.FirstAidKit",
    "Base.TinnedBeans",
    "Base.ShotgunShells",
}

local function spawnLootOnSquare(square, lootList)
    if not square or type(square.AddWorldInventoryItem) ~= "function" then
        return false
    end
    local spawned = 0
    for i = 1, #lootList do
        local ox = 0.25 + ((i - 1) % 2) * 0.45
        local oy = 0.25 + math.floor((i - 1) / 2) * 0.45
        local ok = pcall(square.AddWorldInventoryItem, square, lootList[i], ox, oy, 0)
        if ok then spawned = spawned + 1 end
    end
    return spawned > 0
end

local function handleAftermathLoot(event, square)
    local payload = type(event and event.payload) == "table" and event.payload or {}
    local tier = tostring(payload.lootTier or "standard")
    local list = tier == "high" and HIGH_TIER_LOOT or STANDARD_LOOT
    return spawnLootOnSquare(square, list), "aftermath_loot_spawned"
end

local function handleColonistSOS(event, square)
    local payload = type(event and event.payload) == "table" and event.payload or {}
    local npcId = payload.npcId
    if npcId and PNC.Registry and type(PNC.Registry.Get) == "function" then
        local record = PNC.Registry.Get(npcId)
        if record and record.alive ~= false then
            record.runtime = record.runtime or {}
            record.runtime.forcePresenceCheck = true
            if PNC.SimulationClock and type(PNC.SimulationClock.Wake) == "function" then
                PNC.SimulationClock.Wake(record, "presence", PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0)
            end
        end
    end
    -- Drop a small supply marker (e.g., bandage) at the refuge if square accepts items.
    if square and type(square.AddWorldInventoryItem) == "function" then
        pcall(square.AddWorldInventoryItem, square, "Base.Bandage", 0.5, 0.5, 0)
    end
    return true, "sos_refuge_materialized"
end

EventMaterializer.RegisterHandler("COLONIST_DEAD", handleAftermathLoot)
EventMaterializer.RegisterHandler("HAZARD_OVERWHELMED", handleAftermathLoot)
EventMaterializer.RegisterHandler("COLONIST_SOS", handleColonistSOS)

local function activePlayers()
    local list = {}
    if type(getOnlinePlayers) == "function" then
        local online = getOnlinePlayers()
        if online and type(online.size) == "function" and type(online.get) == "function" then
            for i = 0, online:size() - 1 do
                local p = online:get(i)
                if p then list[#list + 1] = p end
            end
        end
    end
    if #list == 0 and type(getSpecificPlayer) == "function" then
        local p = getSpecificPlayer(0)
        if p then list[1] = p end
    end
    return list
end

-- Clear a colonist's SOS state and cancel their active COLONIST_SOS world event
-- once a player physically reaches or talks to them.
function Mod.CompleteSOSRescue(recordOrID, rescuerPlayer)
    local record = type(recordOrID) == "table" and recordOrID
        or (PNC.Registry and type(PNC.Registry.Get) == "function" and PNC.Registry.Get(recordOrID))
        or nil
    if type(record) ~= "table" or type(record.sosState) ~= "table" or record.sosState.active ~= true then
        return false, "not_in_sos"
    end
    local sosInfo = record.sosState
    record.sosState = nil
    local events = WorldEvents.List({ kind = "COLONIST_SOS" })
    for i = 1, #events do
        local ev = events[i]
        local payload = type(ev.payload) == "table" and ev.payload or {}
        if tostring(payload.npcId or "") == tostring(record.id) then
            WorldEvents.Cancel(ev.id, "colonist_rescued")
        end
    end
    if PNC.AbstractAftermathService
        and type(PNC.AbstractAftermathService.SyncToStore) == "function"
    then
        PNC.AbstractAftermathService.SyncToStore()
    end
    if PNC.HoomansWorldView and type(PNC.HoomansWorldView.Emit) == "function" then
        PNC.HoomansWorldView.Emit("ABSTRACT_COLONIST_RESCUED", {
            npcId = record.id,
            npcName = record.name or record.id,
            refugeKind = sosInfo.refugeKind,
            rescuer = rescuerPlayer and rescuerPlayer.getUsername and rescuerPlayer:getUsername() or nil,
        })
    end
    -- Reunion feedback: relieved callout and automatic rejoin into Follow.
    local body = PNC.Registry and type(PNC.Registry.GetLiveZombie) == "function"
        and PNC.Registry.GetLiveZombie(record.id) or nil
    local line = "Thank god you picked up my signal!"
    if PNC.Speech and type(PNC.Speech.Say) == "function" then
        pcall(PNC.Speech.Say, record, body, line)
    elseif body and type(body.Say) == "function" then
        pcall(body.Say, body, line)
    end
    if record.recruited == true then
        local followKind = PNC.Const and PNC.Const.ORDER_FOLLOW or "follow"
        if PNC.OrderSystem and type(PNC.OrderSystem.SetOrder) == "function" then
            pcall(PNC.OrderSystem.SetOrder, record, { kind = followKind })
        else
            record.orderSpec = { kind = followKind }
        end
    end
    return true, "rescued"
end

local function checkNearbySOSRescues(players)
    if not PNC.Registry or type(PNC.Registry.List) ~= "function" then return 0 end
    local rescued = 0
    local rescueDistSq = 8 * 8
    for _, record in ipairs(PNC.Registry.List()) do
        if type(record) == "table"
            and record.alive ~= false
            and type(record.sosState) == "table"
            and record.sosState.active == true
            and tonumber(record.x) and tonumber(record.y)
        then
            for i = 1, #players do
                local p = players[i]
                if p and type(p.getX) == "function" and type(p.getY) == "function" then
                    local dx = (tonumber(p:getX()) or 0) - record.x
                    local dy = (tonumber(p:getY()) or 0) - record.y
                    if (dx * dx + dy * dy) <= rescueDistSq then
                        if Mod.CompleteSOSRescue(record, p) then
                            rescued = rescued + 1
                            break
                        end
                    end
                end
            end
        end
    end
    return rescued
end

function Mod.Pump(worldHour, budget, playersOverride)
    local players = type(playersOverride) == "table" and playersOverride or activePlayers()
    if #players == 0 then return 0 end
    local count = EventMaterializer.PumpNearPlayers(
        players,
        EventMaterializer.DEFAULT_RADIUS,
        worldHour,
        budget or EventMaterializer.DEFAULT_BUDGET
    )
    local rescued = checkNearbySOSRescues(players)
    if (count > 0 or rescued > 0) and PNC.AbstractAftermathService
        and type(PNC.AbstractAftermathService.SyncToStore) == "function"
    then
        PNC.AbstractAftermathService.SyncToStore()
    end
    return count + rescued
end

return Mod
