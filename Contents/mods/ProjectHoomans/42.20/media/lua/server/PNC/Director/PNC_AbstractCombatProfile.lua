-- Cached aggregate capability for strategic groups. This does not resolve combat.

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AbstractCombatProfile = PNC.AbstractCombatProfile or {}

local Builder = PNC.AbstractCombatProfile
local Groups = PNC.AbstractGroups
local Config = PNC.DirectorConfig
local Store = PNC.AbstractWorldStore

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, tonumber(value) or minimum))
end

local function affiliationRole(record)
    return tostring(record and record.affiliation and record.affiliation.role
        or "civilian")
end

local function condition(record)
    local health = record and record.health or {}
    local maximum = math.max(1, tonumber(health.max) or 100)
    local ratio = clamp((tonumber(health.current) or maximum) / maximum, 0, 1)
    if health.state == "incapacitated" then ratio = ratio * 0.1 end
    return ratio
end

local function weaponClass(record)
    local equipment = record and record.equipment or {}
    local text = string.lower(tostring(equipment.primaryFullType or "")
        .. " " .. tostring(equipment.secondaryFullType or ""))
    if string.find(text, "shotgun", 1, true) then return "shotgun" end
    if string.find(text, "rifle", 1, true)
        or string.find(text, "assault", 1, true)
    then return "rifle" end
    if string.find(text, "pistol", 1, true)
        or string.find(text, "revolver", 1, true)
    then return "sidearm" end
    if string.find(text, "axe", 1, true)
        or string.find(text, "katana", 1, true)
        or string.find(text, "machete", 1, true)
    then return "strong_melee" end
    if text ~= " " then return "basic_melee" end
    if record and record.weaponMode == "ranged" then return "sidearm" end
    return "unarmed"
end

local function profileSignature(group)
    local parts = { tostring(group.resources and group.resources.ammo or 0) }
    for _, npcID in ipairs(group.memberIds or {}) do
        local record = PNC.Registry and PNC.Registry.Get(npcID) or nil
        if record then
            parts[#parts + 1] = table.concat({ npcID,
                tostring(record.alive ~= false), affiliationRole(record),
                string.format("%.2f", condition(record)), weaponClass(record),
                tostring(record.equipment and record.equipment.primaryFullType or ""),
                tostring(record.equipment and record.equipment.secondaryFullType or ""),
            }, ":")
        else
            parts[#parts + 1] = npcID .. ":missing"
        end
    end
    return table.concat(parts, "|")
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

function Builder.Build(groupOrID)
    local group = type(groupOrID) == "table" and groupOrID
        or Groups.Get(groupOrID)
    if not group then return nil, "group_not_found" end
    local combatants, memberCount = 0, 0
    local melee, rawRanged, defense, mobility, experience, medical = 0, 0, 0, 0, 0, 0
    local totalCondition = 0
    local ratings = Config.COMBAT.WEAPON_RATINGS
    for _, npcID in ipairs(group.memberIds or {}) do
        local record = PNC.Registry and PNC.Registry.Get(npcID) or nil
        if record and record.alive ~= false then
            memberCount = memberCount + 1
            local role = affiliationRole(record)
            local roleFactor = Config.COMBAT.ROLE_FACTORS[role] or 0.35
            local healthFactor = condition(record)
            local rating = ratings[weaponClass(record)] or ratings.unarmed
            totalCondition = totalCondition + healthFactor
            combatants = combatants + roleFactor * healthFactor
            melee = melee + rating.melee * roleFactor * healthFactor
            rawRanged = rawRanged + rating.ranged * roleFactor * healthFactor
            defense = defense + (0.45 + roleFactor * 0.35) * healthFactor
            mobility = mobility + healthFactor
            experience = experience + roleFactor * 0.4
            if role == "medic" then medical = medical + healthFactor end
        end
    end
    local ammoValue = group.resources and group.resources.ammo or 0
    local ammoFactor, ammoState = ammoModifier(ammoValue)
    local effectiveManpower = combatants ^ Config.MANPOWER_EXPONENT
    local needs = Groups.GetNeeds(group) or {}
    local morale = 0.5
        + (1 - clamp(tonumber(needs.hunger) or 0, 0, 1)) * 0.15
        + (1 - clamp(tonumber(needs.thirst) or 0, 0, 1)) * 0.15
        + (1 - clamp(tonumber(needs.fatigue) or 0, 0, 1)) * 0.2
    local profile = {
        manpower = effectiveManpower,
        meleePower = melee,
        rangedPower = rawRanged * ammoFactor,
        defense = defense ^ Config.MANPOWER_EXPONENT,
        mobility = memberCount > 0 and mobility / memberCount or 0,
        morale = morale,
        experience = experience ^ Config.MANPOWER_EXPONENT,
        medical = medical,
        ammoState = ammoValue,
        ammoLabel = ammoState,
        condition = memberCount > 0 and totalCondition / memberCount or 0,
        memberCount = memberCount,
        combatantCount = combatants,
        builtAt = Store.WorldAgeHours(),
        revision = (group.combatProfile and group.combatProfile.revision or 0) + 1,
    }
    local total = 0
    for _, field in ipairs({ "manpower", "meleePower", "rangedPower",
        "defense", "mobility", "morale", "experience", "medical" }) do
        total = total + (tonumber(profile[field]) or 0)
            * (tonumber(Config.COMBAT.OVERALL_WEIGHTS[field]) or 0)
    end
    profile.overallPower = total
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
