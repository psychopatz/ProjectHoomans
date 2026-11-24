-- Lightweight, server-only weather-appropriate dressing for Project Hoomans.
-- Zero ModData bloat: weather band, item thermal cache, and non-owned overlays
-- live strictly in ephemeral memory. Player-owned colonists strictly use owned
-- items from personal inventory and faction storage; non-owned NPCs use an
-- ephemeral Appearance overlay and cleanly revert to their default outfit.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WeatherDressingService = PNC.WeatherDressingService or {}

local Service = PNC.WeatherDressingService
local ActorControl = PNC.ActorControl
    or require "PNC/Core/ActorControl/PNC_ActorControl"

Service.BAND_NORMAL = "NORMAL"
Service.BAND_RAIN = "RAIN"
Service.BAND_COLD = "COLD"
Service.BAND_HOT = "HOT"

Service.SAMPLE_INTERVAL_MS = 10000
Service.INDOOR_DEBOUNCE_MS = 15000
Service.MAX_NPCS_PER_TICK = 4

Service.CurrentBand = Service.CurrentBand or Service.BAND_NORMAL
Service.WeatherRevision = tonumber(Service.WeatherRevision) or 1
Service.NextSampleAt = tonumber(Service.NextSampleAt) or 0
Service.ClothingProfileCache = Service.ClothingProfileCache or {}
Service.PumpCursor = tonumber(Service.PumpCursor) or 1

local RAIN_OVERLAY_POOL = {
    { { type = "Base.PonchoGreen", wornSlot = "Jacket" } },
    { { type = "Base.PonchoYellow", wornSlot = "Jacket" } },
    { { type = "Base.Jacket_CoatArmy", wornSlot = "Jacket" } },
}

local COLD_OVERLAY_POOL = {
    {
        { type = "Base.Jacket_Padded", wornSlot = "Jacket" },
        { type = "Base.Hat_Beany", wornSlot = "Hat" },
        { type = "Base.Gloves_LeatherGloves", wornSlot = "Hands" },
    },
    {
        { type = "Base.Jacket_PaddedDOWN", wornSlot = "Jacket" },
        { type = "Base.Hat_WinterHat", wornSlot = "Hat" },
        { type = "Base.Scarf_White", wornSlot = "Scarf" },
    },
}

local HOT_HIDE_SLOTS = {
    Jacket = true,
    Jacket_Bulky = true,
    Sweater = true,
    Scarf = true,
    Hands = true,
}

local WEATHER_SLOTS = {
    Jacket = true,
    Jacket_Bulky = true,
    Sweater = true,
    Hat = true,
    Hands = true,
    Scarf = true,
}

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

local function isPlayerOwned(record)
    if type(record) ~= "table" then return false end
    if record.recruited == true or record.colonyOwned == true
        or record.ownerUsername ~= nil or record.ownerOnlineID ~= nil
    then
        return true
    end
    local verifier = PNC.Identity and PNC.Identity.Verifier or nil
    if verifier then
        if verifier.IsCompanion and verifier.IsCompanion(record) == true then
            return true
        end
        if verifier.IsColonyOwnedNPC then
            local ok, owned = pcall(verifier.IsColonyOwnedNPC, record)
            if ok and owned == true then return true end
        end
    end
    return false
end

local function isEligible(record, zombie, now)
    if type(record) ~= "table" or not zombie or record.alive == false then
        return false
    end
    if record.presenceState ~= (PNC.Const and PNC.Const.PRESENCE_LIVE or "live") then
        return false
    end
    if ActorControl and ActorControl.IsPuppetOwned
        and ActorControl.IsPuppetOwned(record)
    then
        return false
    end
    local rt = record.runtime
    if rt and (
        rt.combatTarget ~= nil or rt.attackAction ~= nil
        or now < (tonumber(rt.inCombatUntil) or 0)
    ) then
        return false
    end
    return true
end

local function isIndoors(zombie)
    local sq = zombie and zombie.getCurrentSquare and zombie:getCurrentSquare() or nil
    if not sq then return false end
    if sq.isOutside then return sq:isOutside() ~= true end
    if sq.getRoom then return sq:getRoom() ~= nil end
    return false
end

---Samples ClimateManager once per SAMPLE_INTERVAL_MS with hysteresis.
function Service.SampleWeather(now, override)
    now = nowMs(now)
    if not override and now < Service.NextSampleAt then
        return Service.CurrentBand, Service.WeatherRevision
    end
    Service.NextSampleAt = now + Service.SAMPLE_INTERVAL_MS
    local cm = not override and type(getClimateManager) == "function"
        and getClimateManager() or nil
    local tempC = tonumber(override and override.tempC)
        or (cm and cm.getTemperature and tonumber(cm:getTemperature())) or 18.0
    local rain = tonumber(override and override.rain)
        or (cm and cm.getRainIntensity and tonumber(cm:getRainIntensity())) or 0.0
    local prev = Service.CurrentBand
    local nextBand = Service.BAND_NORMAL

    if prev == Service.BAND_RAIN and rain > 0.12 then
        nextBand = Service.BAND_RAIN
    elseif rain >= 0.25 then
        nextBand = Service.BAND_RAIN
    elseif prev == Service.BAND_COLD and tempC < 11.0 then
        nextBand = Service.BAND_COLD
    elseif tempC <= 8.0 then
        nextBand = Service.BAND_COLD
    elseif prev == Service.BAND_HOT and tempC > 25.0 then
        nextBand = Service.BAND_HOT
    elseif tempC >= 28.0 then
        nextBand = Service.BAND_HOT
    end

    if nextBand ~= prev then
        Service.CurrentBand = nextBand
        Service.WeatherRevision = Service.WeatherRevision + 1
    end
    return Service.CurrentBand, Service.WeatherRevision
end

---O(1) cached rain check with hysteresis, shared by dressing and shelter AI.
function Service.IsRaining(now, override)
    local band = Service.SampleWeather(now, override)
    return band == Service.BAND_RAIN
end

---Lazy-cached clothing thermal/rain/armor profile per item fullType.
function Service.GetClothingProfile(fullType)
    local key = tostring(fullType or "")
    if key == "" then return nil end
    local cached = Service.ClothingProfileCache[key]
    if cached ~= nil then
        return cached ~= false and cached or nil
    end
    local sm = ScriptManager and ScriptManager.instance or nil
    local scriptItem = sm and sm.getItem and sm:getItem(key) or nil
    if not scriptItem then
        Service.ClothingProfileCache[key] = false
        return nil
    end
    local bodyLoc = scriptItem.getBodyLocation
        and tostring(scriptItem:getBodyLocation() or "") or ""
    if bodyLoc == "" and PNC.Identity and PNC.Identity.Appearance
        and PNC.Identity.Appearance.ResolveBodyLocation
    then
        bodyLoc = tostring(PNC.Identity.Appearance.ResolveBodyLocation(key) or "")
    end
    local profile = {
        fullType = key,
        slot = bodyLoc,
        insulation = scriptItem.getInsulation
            and tonumber(scriptItem:getInsulation()) or 0,
        waterRes = scriptItem.getWaterResistance
            and tonumber(scriptItem:getWaterResistance()) or 0,
        biteDefense = scriptItem.getBiteDefense
            and tonumber(scriptItem:getBiteDefense()) or 0,
        scratchDefense = scriptItem.getScratchDefense
            and tonumber(scriptItem:getScratchDefense()) or 0,
    }
    Service.ClothingProfileCache[key] = profile
    return profile
end

local function itemMatchesBand(profile, band)
    if not profile or not WEATHER_SLOTS[profile.slot] then return false, 0 end
    if band == Service.BAND_RAIN then
        return profile.waterRes >= 0.45, profile.waterRes
    elseif band == Service.BAND_COLD then
        return profile.insulation >= 0.45, profile.insulation
    end
    return false, 0
end

local function refreshLiveVisuals(record, zombie)
    if PNC.Visuals and type(PNC.Visuals.ApplyResolvedAppearance) == "function" then
        pcall(PNC.Visuals.ApplyResolvedAppearance, zombie, record)
    end
end

local function tryBorrowFromFactionStorage(record, band)
    local factionId = record and (record.factionID
        or (record.affiliation and record.affiliation.factionID)) or nil
    local repo = PNC.ColonyStorageRepository
    local invSvc = PNC.Inventory
    if not factionId or not repo or not repo.PrimaryByFaction
        or not invSvc or not invSvc.AddItems
    then
        return nil
    end
    local storage = repo.PrimaryByFaction[tostring(factionId)]
    local records = storage and storage.inventory and storage.inventory.records or nil
    if type(records) ~= "table" then return nil end
    local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
    local coreInv = PsychopatzCore and PsychopatzCore.Inventory or nil
    local bestScore, bestProfile, bestRecord, bestTypeKey
    for i = 1, #records do
        local rec = records[i]
        local rawType = rec and rec[C.TYPE_ID] or nil
        local ft = type(rawType) == "string" and rawType or nil
        if not ft and type(rawType) == "number" and coreInv
            and coreInv.Registry and coreInv.Registry.getFullType
        then
            ft = coreInv.Registry.getFullType(rawType)
        end
        local qty = rec and tonumber(rec[C.QUANTITY]) or 0
        if ft and qty >= 1 then
            local prof = Service.GetClothingProfile(ft)
            local matches, score = itemMatchesBand(prof, band)
            if matches and (not bestScore or score > bestScore) then
                bestScore, bestProfile, bestRecord, bestTypeKey = score, prof, rec, rawType
            end
        end
    end
    if not bestRecord or not bestProfile then return nil end
    local removedOk = storage.inventory.remove
        and storage.inventory:remove(bestTypeKey, 1)
    if not removedOk then return nil end
    local addedOk, addedItems = invSvc.AddItems(record, {
        { type = bestProfile.fullType, count = 1 },
    }, "weather_storage_borrow")
    if not addedOk then
        if storage.inventory.add then
            storage.inventory:add(bestRecord)
        end
        return nil
    end
    if repo.MarkDirty then repo.MarkDirty() end
    local added = type(addedItems) == "table" and addedItems[1] or nil
    return added and added.id or nil, bestProfile.slot, storage.id, bestTypeKey
end

local function revertOwnedWeatherItems(record, zombie)
    local rt = record.runtime
    local tracked = rt and rt.weatherEquipped or nil
    if type(tracked) ~= "table" then return false end
    local invSvc = PNC.Inventory
    local repo = PNC.ColonyStorageRepository
    local changed = false
    for i = #tracked, 1, -1 do
        local entry = tracked[i]
        if invSvc and invSvc.ClearWorn and entry.itemId then
            invSvc.ClearWorn(record, entry.itemId, "weather_revert")
            changed = true
        end
        if entry.fromStorageId and entry.itemId and invSvc
            and invSvc.RemoveItems and repo and repo.ByID
        then
            local storage = repo.ByID[entry.fromStorageId]
            if storage and storage.inventory and storage.inventory.add then
                local removed = invSvc.RemoveItems(
                    record, { entry.itemId }, "weather_storage_return")
                if removed then
                    storage.inventory:add({ entry.fullType, 1 })
                    if repo.MarkDirty then repo.MarkDirty() end
                end
            end
        end
        tracked[i] = nil
    end
    rt.weatherEquipped = nil
    if changed then refreshLiveVisuals(record, zombie) end
    return changed
end

local function dressOwnedColonist(record, zombie, effectiveBand)
    local invSvc = PNC.Inventory
    if not invSvc or not invSvc.EnsureRecordInventory or not invSvc.SetWorn then
        return false
    end
    if effectiveBand == Service.BAND_NORMAL or effectiveBand == Service.BAND_HOT then
        return revertOwnedWeatherItems(record, zombie)
    end
    local inv = invSvc.EnsureRecordInventory(record, {
        reconcileWaterContainer = false,
    })
    if not inv or type(inv.items) ~= "table" then return false end
    local bestBySlot = {}
    for itemId, item in pairs(inv.items) do
        if item and item.type and not item.wornSlot then
            local prof = Service.GetClothingProfile(item.type)
            local matches, score = itemMatchesBand(prof, effectiveBand)
            if matches then
                local current = bestBySlot[prof.slot]
                if not current or score > current.score then
                    bestBySlot[prof.slot] = {
                        itemId = itemId, slot = prof.slot,
                        score = score, fullType = item.type,
                    }
                end
            end
        end
    end
    local rt = record.runtime or {}
    record.runtime = rt
    rt.weatherEquipped = rt.weatherEquipped or {}
    local equippedAny = false
    for slot, pick in pairs(bestBySlot) do
        if not (inv.worn and inv.worn[slot]) then
            local ok = invSvc.SetWorn(record, pick.itemId, slot, "weather_dress")
            if ok then
                rt.weatherEquipped[#rt.weatherEquipped + 1] = {
                    itemId = pick.itemId, slot = slot, fullType = pick.fullType,
                }
                equippedAny = true
            end
        end
    end
    if not equippedAny and not (inv.worn and inv.worn.Jacket) then
        local borrowedId, slot, storageId, fullType =
            tryBorrowFromFactionStorage(record, effectiveBand)
        if borrowedId and slot then
            local ok = invSvc.SetWorn(record, borrowedId, slot, "weather_dress")
            if ok then
                rt.weatherEquipped[#rt.weatherEquipped + 1] = {
                    itemId = borrowedId, slot = slot,
                    fromStorageId = storageId, fullType = fullType,
                }
                equippedAny = true
            end
        end
    end
    if equippedAny then refreshLiveVisuals(record, zombie) end
    return equippedAny
end

local function dressDynamicNPC(record, zombie, effectiveBand)
    local rt = record.runtime or {}
    record.runtime = rt
    if effectiveBand == Service.BAND_NORMAL then
        if rt.weatherOverlay ~= nil then
            rt.weatherOverlay = nil
            refreshLiveVisuals(record, zombie)
            return true
        end
        return false
    end
    local seed = math.abs(tonumber(record.identitySeed) or 1)
    local overlay = nil
    if effectiveBand == Service.BAND_RAIN then
        local idx = (seed % #RAIN_OVERLAY_POOL) + 1
        overlay = { band = effectiveBand, addItems = RAIN_OVERLAY_POOL[idx] }
    elseif effectiveBand == Service.BAND_COLD then
        local idx = (seed % #COLD_OVERLAY_POOL) + 1
        overlay = { band = effectiveBand, addItems = COLD_OVERLAY_POOL[idx] }
    elseif effectiveBand == Service.BAND_HOT then
        overlay = { band = effectiveBand, hideSlots = HOT_HIDE_SLOTS }
    end
    if rt.weatherOverlay and rt.weatherOverlay.band == effectiveBand then
        return false
    end
    rt.weatherOverlay = overlay
    refreshLiveVisuals(record, zombie)
    return true
end

function Service.EvaluateNPC(record, zombie, now)
    now = nowMs(now)
    if not isEligible(record, zombie, now) then return false end
    local rt = record.runtime or {}
    record.runtime = rt
    local indoors = isIndoors(zombie)
    if rt.lastWeatherIndoors ~= nil and rt.lastWeatherIndoors ~= indoors then
        if now < (tonumber(rt.weatherIndoorDebounceUntil) or 0) then
            return false
        end
        rt.weatherIndoorDebounceUntil = now + Service.INDOOR_DEBOUNCE_MS
    end
    local effectiveBand = Service.CurrentBand
    if indoors and effectiveBand == Service.BAND_RAIN then
        effectiveBand = Service.BAND_NORMAL
    end
    if rt.lastWeatherDressRevision == Service.WeatherRevision
        and rt.lastWeatherEffectiveBand == effectiveBand
    then
        return false
    end
    rt.lastWeatherDressRevision = Service.WeatherRevision
    rt.lastWeatherEffectiveBand = effectiveBand
    rt.lastWeatherIndoors = indoors
    if isPlayerOwned(record) then
        return dressOwnedColonist(record, zombie, effectiveBand)
    end
    return dressDynamicNPC(record, zombie, effectiveBand)
end

function Service.Pump(now)
    now = nowMs(now)
    Service.SampleWeather(now)
    local reg = PNC.Registry
    if not reg or type(reg.LiveList) ~= "table" then return 0 end
    local live = reg.LiveList
    local total = #live
    if total == 0 then return 0 end
    local processed = 0
    local limit = math.min(total, Service.MAX_NPCS_PER_TICK)
    for _ = 1, limit do
        if Service.PumpCursor > total then Service.PumpCursor = 1 end
        local record = live[Service.PumpCursor]
        Service.PumpCursor = Service.PumpCursor + 1
        if record and record.id then
            local zombie = reg.GetLiveZombie and reg.GetLiveZombie(record.id) or nil
            if zombie then
                Service.EvaluateNPC(record, zombie, now)
                processed = processed + 1
            end
        end
    end
    return processed
end

function Service.Reset()
    Service.CurrentBand = Service.BAND_NORMAL
    Service.WeatherRevision = 1
    Service.NextSampleAt = 0
    Service.ClothingProfileCache = {}
    Service.PumpCursor = 1
end

return Service
