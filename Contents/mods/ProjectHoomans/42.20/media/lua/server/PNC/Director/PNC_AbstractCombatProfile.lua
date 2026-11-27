-- Cached aggregate capability for strategic groups, solo/squad player colonists,
-- and unpromoted PsychopatzCore actors. This does not resolve combat.

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AbstractCombatProfile = PNC.AbstractCombatProfile or {}

local Builder = PNC.AbstractCombatProfile
local Groups = PNC.AbstractGroups
local Config = PNC.DirectorConfig
local Store = PNC.HoomansWorldView

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, tonumber(value) or minimum))
end

local function resolveParticipant(entry)
    if type(entry) == "table" then
        return entry, entry.coreActor == true and "core_actor" or "record"
    end
    local id = tostring(entry or "")
    if id == "" then return nil, nil end
    local record = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(id) or nil
    if record then
        return record, "record"
    end
    local coreActors = PsychopatzCore and PsychopatzCore.Actors or nil
    local coreReg = coreActors and coreActors.DefaultRegistry or nil
    if coreReg and type(coreReg.Get) == "function" then
        local actor = coreReg:Get(id)
        if type(actor) == "table" then
            return actor, "core_actor"
        end
    end
    return nil, nil
end

local function isAliveParticipant(entry, source)
    if type(entry) ~= "table" then return false end
    if source == "core_actor" then
        if entry.alive == false then return false end
        local status = string.lower(tostring(entry.status or entry.state or "active"))
        if status == "dead" or status == "deceased" or status == "removed" then
            return false
        end
        return true
    end
    return entry.alive ~= false
end

local function affiliationRole(record)
    local role = record and record.affiliation and record.affiliation.role
        or record and record.role
        or record and record.archetype
        or nil
    return tostring(role or "civilian")
end

local function condition(record)
    local health = type(record and record.health) == "table" and record.health or {}
    local maximum = math.max(1, tonumber(health.max) or 100)
    local current = tonumber(health.current)
    if current == nil then
        current = tonumber(record and record.hp) or maximum
    end
    local ratio = clamp(current / maximum, 0, 1)
    if health.state == "incapacitated" then ratio = ratio * 0.1 end
    local endurance = tonumber(record and record.endurance)
        or tonumber(record and record.stats and record.stats.endurance)
    if endurance ~= nil then
        local staminaFactor = 0.75 + 0.25 * clamp(endurance, 0, 1)
        ratio = ratio * staminaFactor
    end
    return ratio
end

local function weaponClass(record)
    local equipment = type(record and record.equipment) == "table" and record.equipment or {}
    local text = string.lower(tostring(equipment.primaryFullType or equipment.primary or "")
        .. " " .. tostring(equipment.secondaryFullType or equipment.secondary or ""))
    if string.find(text, "shotgun", 1, true) then return "shotgun" end
    if string.find(text, "rifle", 1, true)
        or string.find(text, "assault", 1, true)
        or string.find(text, "carbine", 1, true)
        or string.find(text, "m14", 1, true)
        or string.find(text, "m16", 1, true)
    then return "rifle" end
    if string.find(text, "pistol", 1, true)
        or string.find(text, "revolver", 1, true)
        or string.find(text, "beretta", 1, true)
        or string.find(text, "magnum", 1, true)
    then return "sidearm" end
    if string.find(text, "axe", 1, true)
        or string.find(text, "katana", 1, true)
        or string.find(text, "machete", 1, true)
        or string.find(text, "crowbar", 1, true)
        or string.find(text, "sledgehammer", 1, true)
        or string.find(text, "spear", 1, true)
    then return "strong_melee" end
    if text ~= " " then return "basic_melee" end
    if record and record.weaponMode == "ranged" then return "sidearm" end
    return "unarmed"
end

local function weaponConditionFactor(record)
    local equipment = type(record and record.equipment) == "table" and record.equipment or {}
    local cur = tonumber(equipment.primaryCondition)
    local maxCond = tonumber(equipment.primaryConditionMax)
    if cur ~= nil and maxCond ~= nil and maxCond > 0 then
        return clamp(0.45 + 0.55 * clamp(cur / maxCond, 0, 1), 0.35, 1.0)
    end
    return 1.0
end

local function scoreArmorText(text)
    if type(text) ~= "string" or text == "" then return 0 end
    local lower = string.lower(text)
    local bonus = 0
    if string.find(lower, "bulletproof", 1, true) or string.find(lower, "vest_bullet", 1, true) then
        bonus = bonus + 0.45
    end
    if string.find(lower, "helmet", 1, true)
        or string.find(lower, "hat_army", 1, true)
        or string.find(lower, "hat_fireman", 1, true)
    then
        bonus = bonus + 0.22
    end
    if string.find(lower, "jacket_fireman", 1, true) or string.find(lower, "jacket_leather", 1, true)
        or string.find(lower, "jacket_army", 1, true) or string.find(lower, "armor", 1, true)
    then
        bonus = bonus + 0.25
    elseif string.find(lower, "jacket", 1, true) or string.find(lower, "coat", 1, true) then
        bonus = bonus + 0.08
    end
    if string.find(lower, "gloves_leather", 1, true) then
        bonus = bonus + 0.08
    end
    if string.find(lower, "boots_army", 1, true) or string.find(lower, "boots", 1, true) then
        bonus = bonus + 0.06
    end
    return bonus
end

local function armorRatingFor(record)
    local total = 0
    local equipment = type(record and record.equipment) == "table" and record.equipment or {}
    if tonumber(equipment.armorRating) then
        total = total + clamp(tonumber(equipment.armorRating), 0, 1.5)
    end
    local lists = {
        equipment.wornItems,
        record and record.wornItems,
        record and record.visuals and record.visuals.clothing,
    }
    for i = 1, #lists do
        local list = lists[i]
        if type(list) == "table" then
            for _, item in pairs(list) do
                if type(item) == "string" then
                    total = total + scoreArmorText(item)
                elseif type(item) == "table" then
                    total = total + scoreArmorText(tostring(item.fullType or item.type or item.name or ""))
                end
            end
        end
    end
    if type(record and record.outfit) == "string" then
        total = total + scoreArmorText(record.outfit)
    end
    return clamp(total, 0, 1.25)
end

local function skillLevel(record, name)
    local skills = type(record and record.skills) == "table" and record.skills or nil
    if not skills then return 0 end
    local val = tonumber(skills[name])
    if val == nil then
        val = tonumber(skills[string.lower(name)])
    end
    return clamp(val or 0, 0, 10)
end

local function inventoryCounts(record)
    local ammo = tonumber(record and record.equipment and record.equipment.ammoCount) or 0
    local medItems = 0
    local inv = record and (record.inventory or record.items) or nil
    if type(inv) == "table" then
        local items = type(inv.items) == "table" and inv.items or inv
        for _, item in ipairs(items) do
            if type(item) == "table" then
                local ft = string.lower(tostring(item.fullType or item.type or ""))
                local count = math.max(1, math.floor(tonumber(item.count or item.qty) or 1))
                if string.find(ft, "bullets", 1, true) or string.find(ft, "shells", 1, true)
                    or string.find(ft, "ammo", 1, true) or string.find(ft, "556", 1, true)
                    or string.find(ft, "308", 1, true) or string.find(ft, "9mm", 1, true)
                then
                    ammo = ammo + count
                elseif string.find(ft, "bandage", 1, true) or string.find(ft, "firstaid", 1, true)
                    or string.find(ft, "medkit", 1, true) or string.find(ft, "suture", 1, true)
                then
                    medItems = medItems + count
                end
            end
        end
    end
    return ammo, medItems
end

local function ammoModifier(ammo)
    ammo = math.max(0, tonumber(ammo) or 0)
    if ammo <= 0 then return 0, "EMPTY" end
    if ammo < 10 then return 0.2, "CRITICAL" end
    if ammo < 25 then return 0.45, "LOW" end
    if ammo < 50 then return 0.7, "MEDIUM" end
    if ammo < 80 then return 0.9, "HIGH" end
    return 1, "FULL"
end

function Builder.ScoreActor(actorOrRecord, opts)
    opts = type(opts) == "table" and opts or {}
    local entry, source = resolveParticipant(actorOrRecord)
    if not entry or not isAliveParticipant(entry, source) then
        return nil
    end
    local ratings = (Config and Config.COMBAT and Config.COMBAT.WEAPON_RATINGS) or {
        unarmed = { melee = 0.2, ranged = 0 },
        basic_melee = { melee = 0.55, ranged = 0 },
        strong_melee = { melee = 0.9, ranged = 0 },
        sidearm = { melee = 0.3, ranged = 0.65 },
        shotgun = { melee = 0.35, ranged = 0.95 },
        rifle = { melee = 0.35, ranged = 1.0 },
    }
    local roleFactors = (Config and Config.COMBAT and Config.COMBAT.ROLE_FACTORS) or {}
    local role = affiliationRole(entry)
    local roleFactor = roleFactors[role] or 0.35
    local healthFactor = condition(entry)
    local wClass = weaponClass(entry)
    local rating = ratings[wClass] or ratings.unarmed
    local wCond = weaponConditionFactor(entry)
    local armor = armorRatingFor(entry)
    local ammo, medItems = inventoryCounts(entry)

    local aiming = skillLevel(entry, "Aiming")
    local reloading = skillLevel(entry, "Reloading")
    local meleeSkill = math.max(
        skillLevel(entry, "Axe"),
        skillLevel(entry, "LongBlade"),
        skillLevel(entry, "SmallBlade"),
        skillLevel(entry, "Blunt"),
        skillLevel(entry, "SmallBlunt"),
        skillLevel(entry, "Spear")
    )
    local doctor = math.max(skillLevel(entry, "Doctor"), skillLevel(entry, "FirstAid"))
    local fitness = skillLevel(entry, "Fitness")
    local strength = skillLevel(entry, "Strength")

    local meleeSkillMult = 1 + meleeSkill * 0.07 + strength * 0.03
    local rangedSkillMult = 1 + aiming * 0.08 + reloading * 0.04
    local mobilitySkillMult = 1 + fitness * 0.03

    local melee = rating.melee * roleFactor * healthFactor * wCond * meleeSkillMult
    local rawRanged = rating.ranged * roleFactor * healthFactor * wCond * rangedSkillMult
    local defense = (0.45 + roleFactor * 0.35 + armor * 0.65) * healthFactor
    local mobility = clamp(healthFactor * mobilitySkillMult, 0, 1.5)
    local experience = roleFactor * 0.4 + (aiming + meleeSkill) * 0.03
    local medical = (role == "medic" and healthFactor or 0)
        + doctor * 0.08 * healthFactor
        + math.min(0.4, medItems * 0.08)

    local ammoFactor = 1
    if opts.applyPersonalAmmo == true then
        ammoFactor = ammoModifier(ammo)
    end
    return {
        source = source,
        role = role,
        roleFactor = roleFactor,
        healthFactor = healthFactor,
        weaponClass = wClass,
        weaponConditionFactor = wCond,
        armorRating = armor,
        ammoCount = ammo,
        medItems = medItems,
        combatants = roleFactor * healthFactor,
        melee = melee,
        rawRanged = rawRanged,
        ranged = rawRanged * ammoFactor,
        defense = defense,
        mobility = mobility,
        experience = experience,
        medical = medical,
    }
end

local function profileSignature(group)
    local parts = { tostring(group.resources and group.resources.ammo or 0) }
    for _, npcID in ipairs(group.memberIds or {}) do
        local entry, source = resolveParticipant(npcID)
        if entry then
            parts[#parts + 1] = table.concat({
                tostring(npcID),
                tostring(source or ""),
                tostring(isAliveParticipant(entry, source)),
                affiliationRole(entry),
                string.format("%.2f", condition(entry)),
                weaponClass(entry),
                string.format("%.2f", armorRatingFor(entry)),
                tostring(entry.equipment and entry.equipment.primaryFullType or ""),
                tostring(entry.equipment and entry.equipment.secondaryFullType or ""),
                tostring(entry.revision or 0),
            }, ":")
        else
            parts[#parts + 1] = tostring(npcID) .. ":missing"
        end
    end
    return table.concat(parts, "|")
end

function Builder.BuildForParticipants(memberList, resources, opts)
    opts = type(opts) == "table" and opts or {}
    resources = type(resources) == "table" and resources or {}
    local combatants, memberCount = 0, 0
    local melee, rawRanged, defense, mobility, experience, medical = 0, 0, 0, 0, 0, 0
    local totalCondition, totalArmor, personalAmmo = 0, 0, 0

    for _, member in ipairs(type(memberList) == "table" and memberList or {}) do
        local score = Builder.ScoreActor(member)
        if score then
            memberCount = memberCount + 1
            totalCondition = totalCondition + score.healthFactor
            totalArmor = totalArmor + score.armorRating
            personalAmmo = personalAmmo + score.ammoCount
            combatants = combatants + score.combatants
            melee = melee + score.melee
            rawRanged = rawRanged + score.rawRanged
            defense = defense + score.defense
            mobility = mobility + score.mobility
            experience = experience + score.experience
            medical = medical + score.medical
        end
    end

    local poolAmmo = tonumber(resources.ammo)
    local ammoValue = poolAmmo ~= nil and (poolAmmo + personalAmmo) or personalAmmo
    local ammoFactor, ammoState = ammoModifier(ammoValue)
    local exponent = (Config and tonumber(Config.MANPOWER_EXPONENT)) or 0.85
    local effectiveManpower = combatants ^ exponent
    local needs = type(opts.needs) == "table" and opts.needs or {}
    local morale = 0.5
        + (1 - clamp(tonumber(needs.hunger) or 0, 0, 1)) * 0.15
        + (1 - clamp(tonumber(needs.thirst) or 0, 0, 1)) * 0.15
        + (1 - clamp(tonumber(needs.fatigue) or 0, 0, 1)) * 0.2

    local profile = {
        manpower = effectiveManpower,
        meleePower = melee,
        rangedPower = rawRanged * ammoFactor,
        defense = defense ^ exponent,
        armorRating = memberCount > 0 and (totalArmor / memberCount) or 0,
        mobility = memberCount > 0 and (mobility / memberCount) or 0,
        morale = morale,
        experience = experience ^ exponent,
        medical = medical,
        ammoState = ammoValue,
        ammoLabel = ammoState,
        condition = memberCount > 0 and (totalCondition / memberCount) or 0,
        memberCount = memberCount,
        combatantCount = combatants,
        builtAt = Store and Store.WorldAgeHours and Store.WorldAgeHours() or 0,
        revision = (tonumber(opts.previousRevision) or 0) + 1,
    }
    local weights = (Config and Config.COMBAT and Config.COMBAT.OVERALL_WEIGHTS) or {
        manpower = 1, meleePower = 1, rangedPower = 1, defense = 1,
        mobility = 0.5, morale = 0.5, experience = 0.5, medical = 0.5,
    }
    local total = 0
    for _, field in ipairs({ "manpower", "meleePower", "rangedPower",
        "defense", "mobility", "morale", "experience", "medical" }) do
        total = total + (tonumber(profile[field]) or 0)
            * (tonumber(weights[field]) or 0)
    end
    profile.overallPower = total
    return profile
end

function Builder.Build(groupOrID)
    local group = type(groupOrID) == "table" and groupOrID
        or Groups.Get(groupOrID)
    if not group then return nil, "group_not_found" end
    local needs = Groups.GetNeeds(group) or {}
    local profile = Builder.BuildForParticipants(
        group.memberIds or group.memberActorIDs or {},
        group.resources,
        {
            needs = needs,
            previousRevision = group.combatProfile and group.combatProfile.revision or 0,
        }
    )
    group.combatProfile = profile
    group.combatProfileDirty = false
    group.combatProfileReason = nil
    group.combatProfileSignature = profileSignature(group)
    group.revision = (tonumber(group.revision) or 0) + 1
    Store.Touch("combat_profile_rebuilt")
    return profile, "rebuilt"
end

function Builder.Get(groupOrID, force)
    local group = type(groupOrID) == "table" and groupOrID
        or Groups.Get(groupOrID)
    if not group then return nil, "group_not_found" end
    local signature = profileSignature(group)
    if signature ~= group.combatProfileSignature then
        Groups.MarkCombatProfileDirty(group, "profile_inputs_changed")
    end
    if force == true or group.combatProfileDirty == true
        or type(group.combatProfile) ~= "table"
    then return Builder.Build(group) end
    return group.combatProfile, "cached"
end

function Builder.InvalidateForMember(npcID, reason)
    return Groups.MarkMemberChanged(npcID, reason or "member_changed")
end

return Builder
