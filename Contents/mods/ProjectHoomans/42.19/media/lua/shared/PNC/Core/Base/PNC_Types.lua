PNC = PNC or {}
PNC.Types = PNC.Types or {}

local Types = PNC.Types
local Core = PNC.Core
local Const = PNC.Const
local Identity = PNC.Identity

local function normalizeString(value)
    if value == nil or value == "" then
        return nil
    end
    return tostring(value)
end

local function normalizeStringMap(source)
    local output = {}
    local key
    local value
    if type(source) ~= "table" then
        return output
    end
    for key, value in pairs(source) do
        key = normalizeString(key)
        value = normalizeString(value)
        if key and value then
            output[key] = value
        end
    end
    return output
end

local function normalizeEquipment(equipment)
    local source = type(equipment) == "table" and equipment or {}
    return {
        primaryFullType = normalizeString(source.primaryFullType),
        secondaryFullType = normalizeString(source.secondaryFullType),
        worn = normalizeStringMap(source.worn),
        attached = normalizeStringMap(source.attached),
    }
end

local function normalizeIdentity(identity)
    if type(identity) ~= "table" then
        return nil
    end
    return Core.DeepCopy(identity)
end

local function normalizeInventory(inventory)
    if type(inventory) ~= "table" then
        return nil
    end
    return Core.DeepCopy(inventory)
end

function Types.NormalizeFaction(value)
    local faction = string.lower(tostring(value or "companion"))
    if faction == "hostile" or faction == "neutral" or faction == "friendly" or faction == "companion" then
        return faction
    end
    if faction == "enemy" or faction == "bandit" then
        return "hostile"
    end
    if faction == "ally" or faction == "survivor" then
        return "friendly"
    end
    return "companion"
end

function Types.DefaultHostility(faction)
    faction = Types.NormalizeFaction(faction)
    if faction == "hostile" then
        return { mode = "hostile_any_player", attackPlayers = true, attackNPCs = true, attackZombies = true }
    end
    if faction == "neutral" then
        return { mode = "neutral", attackPlayers = false, attackNPCs = false, attackZombies = false }
    end
    if faction == "friendly" then
        return { mode = "defend_allies", attackPlayers = false, attackNPCs = true, attackZombies = true }
    end
    return { mode = "defend_owner", attackPlayers = false, attackNPCs = true, attackZombies = true }
end

function Types.NormalizeHostility(faction, value)
    local source = type(value) == "table" and value or {}
    local defaults = Types.DefaultHostility(faction)
    return {
        mode = tostring(source.mode or defaults.mode),
        attackPlayers = source.attackPlayers == nil and defaults.attackPlayers or source.attackPlayers == true,
        attackNPCs = source.attackNPCs == nil and defaults.attackNPCs or source.attackNPCs == true,
        attackZombies = source.attackZombies == nil and defaults.attackZombies or source.attackZombies == true,
    }
end

local function normalizePatrolPoints(points, fallbackX, fallbackY, fallbackZ)
    local output = {}
    local i
    local entry
    if type(points) == "table" then
        for i = 1, #points do
            entry = points[i]
            if type(entry) == "table" and entry.x ~= nil and entry.y ~= nil then
                output[#output + 1] = {
                    x = tonumber(entry.x) or fallbackX or 0,
                    y = tonumber(entry.y) or fallbackY or 0,
                    z = tonumber(entry.z) or fallbackZ or 0,
                }
            end
        end
    end
    if #output <= 0 then
        output[1] = { x = fallbackX or 0, y = fallbackY or 0, z = fallbackZ or 0 }
    end
    return output
end

function Types.NormalizeDefinition(definition)
    local def = definition or {}
    local faction = Types.NormalizeFaction(def.faction or def.role)
    local x = tonumber(def.x) or 0
    local y = tonumber(def.y) or 0
    local z = tonumber(def.z) or 0
    local isHostile = faction == "hostile"
    local explicitName = normalizeString(def.displayName or def.name)

    return {
        id = def.id,
        name = explicitName,
        displayName = explicitName,
        archetypeID = normalizeString(def.archetypeID),
        faction = faction,
        outfit = def.outfit and tostring(def.outfit) or nil,
        visualProfile = normalizeString(def.visualProfile),
        isFemale = def.isFemale == nil and nil or def.isFemale == true,
        x = x,
        y = y,
        z = z,
        hpMax = tonumber(def.hpMax) or Const.DEFAULT_HP_MAX,
        anchorX = tonumber(def.anchorX) or x,
        anchorY = tonumber(def.anchorY) or y,
        anchorZ = tonumber(def.anchorZ) or z,
        ownerUsername = def.ownerUsername,
        ownerOnlineID = def.ownerOnlineID,
        identitySeed = tonumber(def.identitySeed) or nil,
        identity = normalizeIdentity(def.identity),
        orderSpec = def.orderSpec,
        patrolPoints = normalizePatrolPoints(def.patrolPoints, x, y, z),
        weaponMode = tostring(def.weaponMode or (isHostile and "mixed" or "melee")),
        combatProfile = Core.DeepCopy(def.combatProfile or {}),
        hostility = Types.NormalizeHostility(faction, def.hostility),
        equipment = normalizeEquipment(def.equipment),
        inventory = normalizeInventory(def.inventory),
        allowedJobs = Core.DeepCopy(def.allowedJobs or {}),
        forceLive = def.forceLive == true,
        debug = def.debug == true,
        persist = def.persist ~= false,
        recruited = def.recruited == true,
    }
end

function Types.NewRecord(definition)
    local def = Types.NormalizeDefinition(definition)
    local now = Core.Now()
    local hostile = def.faction == "hostile"
    local generatedID = def.id or Core.GenerateID("npc")
    local record = {
        id = generatedID,
        name = def.displayName,
        identitySeed = Identity and Identity.NormalizeSeed(
            def.identitySeed,
            tostring(def.displayName or def.name or def.archetypeID or def.faction or "PNC NPC") .. ":" .. tostring(generatedID)
        ) or (tonumber(def.identitySeed) or 1),
        identity = normalizeIdentity(def.identity),
        archetypeID = def.archetypeID,
        archetypeLabel = nil,
        faction = def.faction,
        outfit = def.outfit,
        visualProfile = def.visualProfile,
        isFemale = def.isFemale,
        x = def.x,
        y = def.y,
        z = def.z,
        spawnX = def.x,
        spawnY = def.y,
        spawnZ = def.z,
        anchorX = def.anchorX,
        anchorY = def.anchorY,
        anchorZ = def.anchorZ,
        ownerUsername = def.ownerUsername,
        ownerOnlineID = def.ownerOnlineID,
        allowedJobs = def.allowedJobs,
        patrolPoints = def.patrolPoints,
        patrolIndex = 1,
        weaponMode = def.weaponMode,
        equipment = normalizeEquipment(def.equipment),
        inventory = normalizeInventory(def.inventory),
        combatProfile = {
            meleeDamage = tonumber(def.combatProfile.meleeDamage) or 10,
            rangedDamage = tonumber(def.combatProfile.rangedDamage) or 7,
            meleeCooldownMs = tonumber(def.combatProfile.meleeCooldownMs) or 900,
            rangedCooldownMs = tonumber(def.combatProfile.rangedCooldownMs) or 1800,
            unarmedDamage = tonumber(def.combatProfile.unarmedDamage) or Const.UNARMED_DAMAGE,
            unarmedGroundDamage = tonumber(def.combatProfile.unarmedGroundDamage) or Const.UNARMED_GROUND_DAMAGE,
            unarmedCooldownMs = tonumber(def.combatProfile.unarmedCooldownMs) or Const.UNARMED_COOLDOWN_MS,
        },
        hostility = Core.DeepCopy(def.hostility),
        health = {
            current = def.hpMax,
            max = def.hpMax,
            state = "normal",
            lastDamageAt = 0,
            downedAt = 0,
            recentDamageUntil = 0,
        },
        presenceState = Const.PRESENCE_ABSTRACT,
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
        recruited = def.ownerOnlineID ~= nil or def.ownerUsername ~= nil or def.recruited == true,
        persist = def.persist ~= false,
        runtime = {
            target = nil,
            lastPathX = nil,
            lastPathY = nil,
            lastAttackAt = 0,
            lastZombieAttackAt = 0,
            targetKind = "none",
            combatModeResolved = tostring(def.weaponMode or (hostile and "mixed" or "melee")),
            weaponStatus = "barehand",
            combatBlockReason = "spawned",
            ownerSneaking = false,
            stealthActive = false,
            stealthBroken = false,
            stealthReason = "spawned",
            debug = def.debug == true,
            bodyLease = nil,
            lifecycle = {
                phase = "abstract",
                bodyState = "missing",
                lastReason = "spawned",
                lastTransitionAt = now,
                lastAuditAt = 0,
                lastError = nil,
                corpseState = "none",
            },
        },
    }

    if Identity and Identity.ApplyRecordIdentity then
        Identity.ApplyRecordIdentity(record, def)
    else
        record.name = record.name or ((hostile and "Hostile NPC") or (def.faction == "neutral" and "Neutral NPC") or "Friendly NPC")
    end

    return record
end
