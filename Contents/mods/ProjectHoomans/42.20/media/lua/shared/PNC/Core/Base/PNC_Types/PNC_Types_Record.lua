local Types = PNC.Types
local Internal = Types.Internal

function Types.NewRecord(definition)
    local def = Types.NormalizeDefinition(definition)
    local now = PNC.Core.Now()
    local hostile = def.tacticalClass == "hostile"
    local generatedID = def.id or PNC.Core.GenerateID("npc")
    local Identity = PNC.Identity
    local record = {
        id = generatedID,
        name = def.displayName,
        identitySeed = Identity and Identity.NormalizeSeed(
            def.identitySeed,
            tostring(def.displayName or def.name or def.archetypeID
                or def.tacticalClass or "PNC NPC") .. ":" .. tostring(generatedID)
        ) or (tonumber(def.identitySeed) or 1),
        identity = Internal.NormalizeIdentity(def.identity),
        archetypeID = def.archetypeID,
        archetypeLabel = nil,
        tacticalClass = def.tacticalClass,
        outfit = def.outfit,
        visualProfile = def.visualProfile,
        isFemale = def.isFemale,
        x = def.x, y = def.y, z = def.z,
        spawnX = def.x, spawnY = def.y, spawnZ = def.z,
        anchorX = def.anchorX, anchorY = def.anchorY, anchorZ = def.anchorZ,
        ownerUsername = def.ownerUsername,
        ownerOnlineID = def.ownerOnlineID,
        allowedJobs = def.allowedJobs,
        jobPriorities = def.jobPriorities,
        patrolPoints = def.patrolPoints,
        patrolIndex = 1,
        weaponMode = def.weaponMode,
        attackType = def.attackType,
        equipmentSpawnMode = def.equipmentSpawnMode,
        equipmentPoolID = def.equipmentPoolID,
        equipment = Internal.NormalizeEquipment(def.equipment),
        inventory = Internal.NormalizeInventory(def.inventory),
        recipeKnowledge = PNC.RecipeKnowledge
            and PNC.RecipeKnowledge.Normalize(def.recipeKnowledge) or nil,
        combatProfile = {
            meleeDamage = tonumber(def.combatProfile.meleeDamage) or 10,
            rangedDamage = tonumber(def.combatProfile.rangedDamage) or 7,
            meleeCooldownMs = tonumber(def.combatProfile.meleeCooldownMs) or 900,
            rangedCooldownMs = tonumber(def.combatProfile.rangedCooldownMs) or 1800,
            unarmedDamage = tonumber(def.combatProfile.unarmedDamage)
                or PNC.Const.UNARMED_DAMAGE,
            unarmedGroundDamage = tonumber(def.combatProfile.unarmedGroundDamage)
                or PNC.Const.UNARMED_GROUND_DAMAGE,
            unarmedCooldownMs = tonumber(def.combatProfile.unarmedCooldownMs)
                or PNC.Const.UNARMED_COOLDOWN_MS,
        },
        hostility = PNC.Core.DeepCopy(def.hostility),
        affiliation = PNC.FactionTypes
            and PNC.FactionTypes.NewAffiliation() or nil,
        social = nil,
        followerAbandonment = nil,
        health = {
            current = def.hpMax,
            max = def.hpMax,
            state = "normal",
            lastDamageAt = 0,
            downedAt = 0,
            recentDamageUntil = 0,
            body = {
                wounds = {}, parts = {}, bleedingRate = 0,
                openWoundCount = 0, bandagedWoundCount = 0,
                lastBleedAt = 0,
            },
        },
        presenceState = PNC.Const.PRESENCE_ABSTRACT,
        alive = true,
        orderSpec = nil,
        activeJob = nil,
        activeBehavior = nil,
        recordRevision = 0,
        presenceRevision = 0,
        lastThinkAt = now,
        nextThinkAt = now,
        lastSyncAt = 0,
        liveBodyInstanceID = nil,
        corpse = nil,
        recruited = def.ownerOnlineID ~= nil or def.ownerUsername ~= nil
            or def.recruited == true,
        mapPresentation = PNC.MapPresentation
            and PNC.MapPresentation.Normalize(def.mapPresentation) or nil,
        persist = def.persist ~= false,
        generation = type(def.generation) == "table"
            and PNC.Core.DeepCopy(def.generation) or nil,
        vanillaTraits = {},
        vanillaTraitsAuthored = def.vanillaTraitsAuthored == true,
        vanillaTraitsGenerationVersion = 0,
        dynamicTraits = {},
        dynamicTraitsAuthored = def.dynamicTraitsAuthored == true,
        dynamicTraitsGenerationVersion = 0,
        conditionStats = nil,
        runtime = {
            target = nil,
            lastPathX = nil,
            lastPathY = nil,
            lastAttackAt = 0,
            lastZombieAttackAt = 0,
            targetKind = "none",
            combatModeResolved = tostring(def.weaponMode
                or (hostile and "mixed" or "melee")),
            weaponStatus = "barehand",
            combatBlockReason = "spawned",
            ownerSneaking = false,
            stealthActive = false,
            stealthBroken = false,
            stealthReason = "spawned",
            debug = def.debug == true,
            bodyLease = nil,
            lifecycle = {
                phase = "abstract", bodyState = "missing",
                lastReason = "spawned", lastTransitionAt = now,
                lastAuditAt = 0, lastError = nil, corpseState = "none",
            },
        },
    }

    if Identity and Identity.ApplyRecordIdentity then
        Identity.ApplyRecordIdentity(record, def)
    else
        record.name = record.name or ((hostile and "Hostile NPC")
            or (def.tacticalClass == "neutral" and "Neutral NPC")
            or "Colonist NPC")
    end

    if PNC.PlayerNeedsModel and PNC.PlayerNeedsModel.ResolveInitialTraits then
        record.vanillaTraits,
            record.vanillaTraitsAuthored,
            record.vanillaTraitsGenerationVersion =
            PNC.PlayerNeedsModel.ResolveInitialTraits(
                def.vanillaTraits,
                record.identitySeed,
                record.archetypeID,
                def.vanillaTraitsAuthored
            )
    else
        record.vanillaTraits = PNC.Core.DeepCopy(def.vanillaTraits or {})
    end
    if PNC.ConditionStats and PNC.ConditionStats.ResolveInitialTraits then
        record.dynamicTraits,
            record.dynamicTraitsAuthored,
            record.dynamicTraitsGenerationVersion =
            PNC.ConditionStats.ResolveInitialTraits(
                def.dynamicTraits,
                record.identitySeed,
                record.archetypeID,
                def.dynamicTraitsAuthored
            )
    else
        record.dynamicTraits = PNC.Core.DeepCopy(def.dynamicTraits or {})
    end

    record.social = PNC.RelationshipTypes
        and PNC.RelationshipTypes.NewSocialState(
            def.social,
            record.identitySeed,
            record.archetypeID
        ) or {
            schemaVersion = 3,
            revision = 0,
            morale = 0,
            moraleBaseline = 0,
            relationships = {},
            recentEventIDs = {},
            lastEvaluatedAt = 0,
            personality = nil,
            personalityOverrides = {},
            conduct = PNC.ConductTypes
                and PNC.ConductTypes.NewConductRecord() or nil,
        }

    return record
end

return Types
