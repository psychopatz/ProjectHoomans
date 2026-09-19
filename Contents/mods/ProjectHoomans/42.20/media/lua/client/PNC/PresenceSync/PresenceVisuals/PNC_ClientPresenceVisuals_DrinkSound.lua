--[[
    PNC Client Presence Visuals: resolve and synchronize drink sounds.
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Internal = PNC.ClientPresenceSync.Internal

local function resolveDrinkSound(snapshot)
    local action = snapshot and snapshot.actionInformation or nil
    local visual = snapshot and snapshot.visualState or nil
    local capability = tostring(action and action.capability or "")
    local resourceKind = tostring(action and action.resourceKind or "")
    local fullType = string.lower(tostring(
        action and action.activityItemFullType or ""))
    local waterFill = capability == "survival.fill.water"
        or resourceKind == "water_refill"
    local inventoryDrink = capability == "survival.drink.inventory"
        or resourceKind == "personal_drink"
    local worldDrink = capability == "survival.drink.world"
        or resourceKind == "world_water"
    if not visual or visual.sceneActive ~= true then
        return nil
    end
    if waterFill then
        if tostring(visual.sceneStepId or "") ~= "fill" then
            return nil
        end
        return "GetWaterFromTap"
    end
    if tostring(visual.sceneStepId or "") ~= "drink"
        or not (inventoryDrink or worldDrink)
    then return nil end
    if string.find(fullType, "bottleglass", 1, true)
        or string.find(fullType, "glass", 1, true)
    then return "DrinkingFromBottleGlass" end
    if string.find(fullType, "bottle", 1, true) then
        return "DrinkingFromBottlePlastic"
    end
    if string.find(fullType, "can", 1, true) then
        return "DrinkingFromCan"
    end
    if string.find(fullType, "carton", 1, true) then
        return "DrinkingFromCarton"
    end
    if string.find(fullType, "mug", 1, true) then
        return "DrinkingFromMug"
    end
    if inventoryDrink then return "DrinkingFromGeneric" end
    if resourceKind == "faucet" or fullType == "" then
        return "DrinkingFromTap"
    end
    return "DrinkingFromRiver"
end

local function syncDrinkSound(zombie, snapshot, modData)
    local visual = snapshot and snapshot.visualState or nil
    local sound = resolveDrinkSound(snapshot)
    local key
    local emitter
    local handle
    local stopped
    if not modData then return end
    local function stopCurrentDrinkSound()
        local currentHandle = modData.PNC_ClientDrinkSoundHandle
        local currentSound = modData.PNC_ClientDrinkSoundName
        local currentEmitter = zombie and zombie.getEmitter
            and zombie:getEmitter() or nil
        local ok
        if currentEmitter and currentHandle
            and currentEmitter.stopSoundLocal
        then
            ok = pcall(currentEmitter.stopSoundLocal, currentEmitter,
                currentHandle)
            stopped = ok == true
        end
        if not stopped and currentEmitter and currentSound
            and currentEmitter.stopSoundByName
        then
            pcall(currentEmitter.stopSoundByName, currentEmitter, currentSound)
        end
        if not stopped and zombie and currentHandle
            and zombie.stopOrTriggerSound
        then
            pcall(zombie.stopOrTriggerSound, zombie, currentHandle)
        end
        modData.PNC_ClientDrinkSoundHandle = nil
        modData.PNC_ClientDrinkSoundName = nil
        modData.PNC_ClientDrinkSoundKey = nil
    end
    if not sound then
        stopCurrentDrinkSound()
        return
    end
    key = tostring(visual.sceneId or "") .. ":"
        .. tostring(visual.sceneRevision or 0) .. ":"
        .. tostring(visual.scenePlaybackRevision or 0) .. ":"
        .. tostring(visual.sceneStepStartedAt or 0)
    if modData.PNC_ClientDrinkSoundKey == key then return end
    if modData.PNC_ClientDrinkSoundKey ~= nil then
        stopCurrentDrinkSound()
    end
    emitter = zombie and zombie.getEmitter and zombie:getEmitter() or nil
    if emitter and emitter.playSound then
        local ok
        ok, handle = pcall(emitter.playSound, emitter, sound)
        if not ok then handle = nil end
        modData.PNC_ClientDrinkSoundKey = key
        modData.PNC_ClientDrinkSoundHandle = handle
        modData.PNC_ClientDrinkSoundName = sound
    elseif zombie and zombie.playSound then
        local ok
        ok, handle = pcall(zombie.playSound, zombie, sound)
        if not ok then handle = nil end
        modData.PNC_ClientDrinkSoundKey = key
        modData.PNC_ClientDrinkSoundHandle = handle
        modData.PNC_ClientDrinkSoundName = sound
    end
end

Internal.ResolveDrinkSound = resolveDrinkSound
Internal.SyncDrinkSound = syncDrinkSound
