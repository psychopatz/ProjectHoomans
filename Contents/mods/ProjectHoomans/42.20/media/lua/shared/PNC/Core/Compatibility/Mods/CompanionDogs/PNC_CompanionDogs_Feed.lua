-- Companion Dogs compatibility: NPC inventory to Companion Dogs food bridge.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
local Bridge = PNC.Compatibility.CompanionDogs or {}
local Internal = Bridge.Internal or {}
Bridge.Internal = Internal
PNC.Compatibility.CompanionDogs = Bridge

local function findDogFood(record, body, dog)
    local supply = PNC.SupplyInventory
    local queries = supply and supply.Queries
    local supplyInternal = PNC.SupplyInventoryInternal
    local cd = Internal.CompanionDogs()
    local request
    local candidates
    local candidate
    local nativeCandidates
    local native
    local ok
    local rotten
    local bad
    local badOK
    local bite
    local biteOK
    local breed
    local breedOK
    local dogHunger
    if not queries or type(queries.FindPersonal) ~= "function"
        or not supplyInternal
        or type(supplyInternal.NativeCandidates) ~= "function"
        or not cd or type(cd.computeBite) ~= "function"
    then
        return nil
    end
    dogHunger = tonumber(dog:getHunger()) or 0
    request = {
        requesterId = tostring(record.id),
        purpose = "NEED",
        resourceKind = "FOOD",
        required = { hunger = math.max(0.001, dogHunger), thirst = 0 },
        fulfillment = "INSTANT",
    }
    ok, candidates = Internal.SafeCall(
        queries.FindPersonal, record, request, math.max(0.001, dogHunger))
    if not ok or type(candidates) ~= "table" then return nil end
    for index = 1, #candidates do
        candidate = candidates[index]
        nativeCandidates = supplyInternal.NativeCandidates(
            body, candidate and candidate.item)
        native = nativeCandidates and nativeCandidates[1]
            and nativeCandidates[1].item or nil
        if native and type(native.getHungerChange) == "function"
            and tonumber(native:getHungerChange()) < 0
        then
            rotten = type(native.isRotten) == "function"
                and native:isRotten() or false
            if type(cd.getBreed) == "function" then
                breedOK, breed = Internal.SafeCall(cd.getBreed, dog)
                if not breedOK then breed = nil end
            end
            if type(cd.isBadDogFood) == "function" then
                badOK, bad = Internal.SafeCall(cd.isBadDogFood, native, breed)
                bad = not badOK or bad == true
            else
                bad = true
            end
            if not rotten and not bad then
                biteOK, bite = Internal.SafeCall(
                    cd.computeBite, native, dogHunger)
                if biteOK and bite and tonumber(bite.hunger)
                    and tonumber(bite.hunger) < 0
                then
                    return candidate, native, bite
                end
            end
        end
    end
    return nil
end

function Bridge.FeedDog(record, body, dog)
    -- CompanionDogs.Server.feed is player/owner-only. Consume the NPC's real
    -- Hoomans inventory item, then apply the shared Companion Dogs bite result.
    local supply = PNC.SupplyInventory
    local commands = supply and supply.Commands
    local candidate
    local native
    local bite
    local request
    local callOK
    local consumed
    local reason
    local effect
    local stats
    local hungerBefore
    local hungerCut
    local thirstCut
    local setOK
    local cd
    if not Bridge.IsDogHungry(dog) or not Bridge.IsNPCNotHungry(record) then
        return false, "need_gate"
    end
    if not commands or type(commands.Consume) ~= "function"
        or not body or not record
    then
        return false, "supply_unavailable"
    end
    candidate, native, bite = findDogFood(record, body, dog)
    if not candidate or not native or not bite then
        return false, "dog_food_unavailable"
    end
    request = {
        requesterId = tostring(record.id),
        purpose = "NEED",
        resourceKind = "FOOD",
        required = { hunger = math.max(0.001, -bite.hunger), thirst = 0 },
        fulfillment = "INSTANT",
    }
    callOK, consumed, reason, effect = Internal.SafeCall(
        commands.Consume, record, candidate.itemID, request)
    if not callOK or consumed ~= true or reason ~= "consumed" then
        return false, reason or "food_consume_failed"
    end
    hungerBefore = tonumber(dog:getHunger()) or 0
    hungerCut = math.min(hungerBefore, math.max(0, -tonumber(bite.hunger)))
    stats = type(dog.getStats) == "function" and dog:getStats() or nil
    if not stats or type(stats.set) ~= "function" or not CharacterStat then
        if effect and type(effect.undo) == "function" then effect.undo() end
        return false, "dog_need_api_unavailable"
    end
    setOK = pcall(stats.set, stats, CharacterStat.HUNGER,
        math.max(0, hungerBefore - hungerCut))
    if not setOK then
        if effect and type(effect.undo) == "function" then effect.undo() end
        return false, "dog_hunger_update_failed"
    end
    thirstCut = bite.thirst and math.max(0, -tonumber(bite.thirst)) or 0
    if thirstCut > 0 and type(dog.getThirst) == "function" then
        pcall(stats.set, stats, CharacterStat.THIRST,
            math.max(0, (tonumber(dog:getThirst()) or 0) - thirstCut))
    end
    cd = Internal.CompanionDogs()
    if cd and type(cd.pulseEatAnim) == "function" then
        pcall(cd.pulseEatAnim, dog, nil, "hoomans-npc-feed")
    end
    if cd and type(cd.transmit) == "function" then
        pcall(cd.transmit, dog)
    end
    return true, "fed"
end

Internal.FindDogFood = findDogFood

return Bridge
