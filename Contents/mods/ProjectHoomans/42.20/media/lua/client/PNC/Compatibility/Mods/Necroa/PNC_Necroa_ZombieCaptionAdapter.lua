-- Necroa-owned zombie caption adapter.
--
-- These lines are external Necroa presentation, not Project Hoomans dialogue
-- content. Hoomans only supplies the ownership/policy boundary.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsClientCode()
then
    return
end

local Policy = PNC and PNC.Compatibility
    and PNC.Compatibility.Necroa
    or require "PNC/Core/Compatibility/Mods/Necroa/PNC_Necroa_Policy"
local COOLDOWN_MS = 3500
local PROBE_INTERVAL_MS = 1000
local PROBE_RADIUS = 10
local MAX_PROXIMITY_LINES_PER_PROBE = 2
local activeCache = false
local activeCheckedAt = -PROBE_INTERVAL_MS
local probeAtByCell = setmetatable({}, { __mode = "k" })
local LINES = {
    "Grrr...",
    "Hrrr...",
    "Urrgh...",
}

local function nowMillis()
    return type(getTimeInMillis) == "function" and getTimeInMillis() or 0
end

local function distanceSq(a, b)
    local dx = (tonumber(a:getX()) or 0) - (tonumber(b:getX()) or 0)
    local dy = (tonumber(a:getY()) or 0) - (tonumber(b:getY()) or 0)
    local dz = (tonumber(a:getZ()) or 0) - (tonumber(b:getZ()) or 0)
    return dx * dx + dy * dy + dz * dz * 4
end

local function canSpeak(zombie)
    if not zombie or not zombie.isAlive or not zombie:isAlive()
        or not zombie.addLineChatElement
    then
        return false
    end
    local data = zombie.getModData and zombie:getModData() or nil
    local now = nowMillis()
    local last = data and tonumber(data.PNC_NecroaHoomanFlavorAt) or 0
    if now - last < COOLDOWN_MS then return false end
    if data then data.PNC_NecroaHoomanFlavorAt = now end
    return true
end

local function say(zombie)
    if not canSpeak(zombie) then return false end
    zombie:addLineChatElement(LINES[ZombRand(#LINES) + 1])
    return true
end

local function isActive(now)
    if now - activeCheckedAt >= PROBE_INTERVAL_MS then
        activeCache = Policy.IsActive()
        activeCheckedAt = now
    end
    return activeCache
end

local function bucketKey(x, y)
    return tostring(math.floor(x / PROBE_RADIUS)) .. ":"
        .. tostring(math.floor(y / PROBE_RADIUS))
end

local function bucketHasHooman(buckets, zombie)
    local x = tonumber(zombie:getX()) or 0
    local y = tonumber(zombie:getY()) or 0
    local bucketX = math.floor(x / PROBE_RADIUS)
    local bucketY = math.floor(y / PROBE_RADIUS)
    for offsetX = -1, 1 do
        for offsetY = -1, 1 do
            local bucket = buckets[bucketKey(
                (bucketX + offsetX) * PROBE_RADIUS,
                (bucketY + offsetY) * PROBE_RADIUS
            )]
            if bucket then
                for index = 1, #bucket do
                    local candidate = bucket[index]
                    if candidate ~= zombie
                        and distanceSq(zombie, candidate)
                            <= PROBE_RADIUS * PROBE_RADIUS
                    then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function probeCell(cell)
    local list = cell.getZombieList and cell:getZombieList() or nil
    if not list or type(list.size) ~= "function"
        or type(list.get) ~= "function"
    then
        return
    end
    local ordinaryZombies = {}
    local hoomansByBucket = {}
    for index = 0, list:size() - 1 do
        local candidate = list:get(index)
        if candidate and candidate.isAlive and candidate:isAlive() then
            local x = tonumber(candidate:getX()) or 0
            local y = tonumber(candidate:getY()) or 0
            if Policy.IsHoomansOwned(candidate) then
                local key = bucketKey(x, y)
                hoomansByBucket[key] = hoomansByBucket[key] or {}
                hoomansByBucket[key][#hoomansByBucket[key] + 1] = candidate
            else
                ordinaryZombies[#ordinaryZombies + 1] = candidate
            end
        end
    end
    local spoken = 0
    for index = 1, #ordinaryZombies do
        if bucketHasHooman(hoomansByBucket, ordinaryZombies[index])
            and say(ordinaryZombies[index])
        then
            spoken = spoken + 1
            if spoken >= MAX_PROXIMITY_LINES_PER_PROBE then return end
        end
    end
end

local function onZombieUpdate(zombie)
    local now = nowMillis()
    if not isActive(now) then return end
    local cell = zombie and zombie.getCell and zombie:getCell() or nil
    if not cell then return end
    local lastProbe = tonumber(probeAtByCell[cell]) or -PROBE_INTERVAL_MS
    if now - lastProbe < PROBE_INTERVAL_MS then return end
    probeAtByCell[cell] = now
    probeCell(cell)
end

local function onWeaponHitCharacter(attacker, target)
    if not Policy.IsActive() or not attacker or not target
        or not instanceof or not instanceof(target, "IsoZombie")
        or not Policy.IsHoomansOwned(target)
        or Policy.IsHoomansOwned(attacker)
    then
        return
    end
    say(attacker)
end

if Events and Events.OnZombieUpdate then
    Events.OnZombieUpdate.Add(onZombieUpdate)
end
if Events and Events.OnWeaponHitCharacter then
    Events.OnWeaponHitCharacter.Add(onWeaponHitCharacter)
end

return PNC.Compatibility.Necroa
