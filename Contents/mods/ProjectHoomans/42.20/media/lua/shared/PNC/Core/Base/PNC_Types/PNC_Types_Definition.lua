local Types = PNC.Types
local Internal = Types.Internal

function Types.NormalizeDefinition(definition)
    local def = definition or {}
    local faction = Types.NormalizeFaction(def.faction or def.role)
    local x = tonumber(def.x) or 0
    local y = tonumber(def.y) or 0
    local z = tonumber(def.z) or 0
    local isHostile = faction == "hostile"
    local explicitName = Internal.NormalizeString(def.displayName or def.name)
    local vanillaTraitSource = def.vanillaTraits or def.physiologicalTraits
    local vanillaTraitsAuthored = def.vanillaTraitsAuthored
    if vanillaTraitsAuthored == nil then
        vanillaTraitsAuthored = vanillaTraitSource ~= nil
    end
    local dynamicTraitSource = def.dynamicTraits or def.pncTraits
    local dynamicTraitsAuthored = def.dynamicTraitsAuthored
    if dynamicTraitsAuthored == nil then
        dynamicTraitsAuthored = dynamicTraitSource ~= nil
    end

    return {
        id = def.id,
        name = explicitName,
        displayName = explicitName,
        archetypeID = Internal.NormalizeString(def.archetypeID),
        faction = faction,
        outfit = def.outfit and tostring(def.outfit) or nil,
        visualProfile = Internal.NormalizeString(def.visualProfile),
        isFemale = def.isFemale == nil and nil or def.isFemale == true,
        x = x,
        y = y,
        z = z,
        hpMax = tonumber(def.hpMax) or PNC.Const.DEFAULT_HP_MAX,
        anchorX = tonumber(def.anchorX) or x,
        anchorY = tonumber(def.anchorY) or y,
        anchorZ = tonumber(def.anchorZ) or z,
        ownerUsername = def.ownerUsername,
        ownerOnlineID = def.ownerOnlineID,
        identitySeed = tonumber(def.identitySeed) or nil,
        identity = Internal.NormalizeIdentity(def.identity),
        orderSpec = def.orderSpec,
        patrolPoints = Internal.NormalizePatrolPoints(
            def.patrolPoints, x, y, z),
        weaponMode = tostring(def.weaponMode
            or (isHostile and "mixed" or "melee")),
        attackType = Types.NormalizeAttackType(def.attackType,
            def.weaponMode or (isHostile and "mixed" or "melee")),
        equipmentSpawnMode = Internal.NormalizeEquipmentSpawnMode(
            def.equipmentSpawnMode),
        equipmentPoolID = Internal.NormalizeString(def.equipmentPoolID)
            or "Default",
        combatProfile = PNC.Core.DeepCopy(def.combatProfile or {}),
        hostility = Types.NormalizeHostility(faction, def.hostility),
        equipment = Internal.NormalizeEquipment(def.equipment),
        inventory = Internal.NormalizeInventory(def.inventory),
        allowedJobs = PNC.Core.DeepCopy(def.allowedJobs or {}),
        forceLive = def.forceLive == true,
        debug = def.debug == true,
        persist = def.persist ~= false,
        recruited = def.recruited == true,
        social = type(def.social) == "table"
            and PNC.Core.DeepCopy(def.social) or nil,
        organizationalFactionID = Internal.NormalizeString(
            def.organizationalFactionID or def.factionID),
        membershipStatus = Internal.NormalizeString(def.membershipStatus),
        factionRole = Internal.NormalizeString(def.factionRole or def.role),
        factionRank = Internal.NormalizeString(def.factionRank or def.rank),
        factionJoinedAt = tonumber(def.factionJoinedAt),
        mapPresentation = PNC.MapPresentation
            and PNC.MapPresentation.Normalize(def.mapPresentation) or nil,
        generation = type(def.generation) == "table"
            and PNC.Core.DeepCopy(def.generation) or nil,
        vanillaTraits = PNC.PlayerNeedsModel
            and PNC.PlayerNeedsModel.NormalizeTraits(vanillaTraitSource) or {},
        vanillaTraitsAuthored = vanillaTraitsAuthored == true,
        dynamicTraits = PNC.ConditionStats
            and PNC.ConditionStats.NormalizeTraits(dynamicTraitSource) or {},
        dynamicTraitsAuthored = dynamicTraitsAuthored == true,
    }
end

return Types
