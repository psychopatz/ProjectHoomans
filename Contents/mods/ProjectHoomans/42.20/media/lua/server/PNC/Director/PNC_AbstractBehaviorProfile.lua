-- Stable willingness profile plus cheap encounter-time contextual modifiers.

if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.AbstractBehaviorProfile = PNC.AbstractBehaviorProfile or {}

local Behavior = PNC.AbstractBehaviorProfile
local Config = PNC.DirectorConfig
local Store = PNC.AbstractWorldStore
local Groups = PNC.AbstractGroups
local ResourceNeeds = PNC.AbstractResourceNeeds

local function clamp01(value)
    return math.max(0, math.min(1, tonumber(value) or 0))
end

local function factionPolicy(group)
    local faction = group.factionId and PNC.Factions and PNC.Factions.Get(group.factionId) or nil
    local policy = faction and (faction.policy or faction.behaviorPolicy) or nil
    if not policy and faction and PNC.FactionArchetypes
        and PNC.FactionArchetypes.GetPolicyDefaults
    then policy = PNC.FactionArchetypes.GetPolicyDefaults(faction.archetypeID) end
    return faction, type(policy) == "table" and policy or {}
end

function Behavior.Build(groupOrID)
    local group = type(groupOrID) == "table" and groupOrID or Groups.Get(groupOrID)
    if not group then return nil, "group_not_found" end
    local base = Config.Behavior.ARCHETYPES[group.groupType]
        or Config.Behavior.ARCHETYPES.WANDERER
    local faction, policy = factionPolicy(group)
    local profile = {}
    for key, value in pairs(base) do profile[key] = value end
    local mappings = { aggression = "aggression", caution = "caution",
        greed = "opportunism", bravery = "retaliation", mercy = "hospitality" }
    for field, policyField in pairs(mappings) do
        if policy[policyField] ~= nil then
            profile[field] = clamp01(profile[field] * 0.65
                + clamp01(policy[policyField]) * 0.35)
        end
    end
    profile.builtAt = Store.WorldAgeHours()
    profile.source = faction and "archetype+faction" or "archetype"
    group.behaviorProfile = profile
    group.revision = (tonumber(group.revision) or 0) + 1
    Store.Touch("behavior_profile_rebuilt")
    return profile, "rebuilt"
end

function Behavior.Get(groupOrID, force)
    local group = type(groupOrID) == "table" and groupOrID or Groups.Get(groupOrID)
    if not group then return nil, "group_not_found" end
    if force == true or type(group.behaviorProfile) ~= "table" then
        return Behavior.Build(group)
    end
    return group.behaviorProfile, "cached"
end

function Behavior.GetContext(groupOrID, combatProfile)
    local group = type(groupOrID) == "table" and groupOrID or Groups.Get(groupOrID)
    if not group then return nil, "group_not_found" end
    local stable = Behavior.Get(group, false)
    local needs = ResourceNeeds.Get(group) or {}
    combatProfile = combatProfile or group.combatProfile or {}
    local weights = Config.Behavior.DESPERATION_WEIGHTS
    local morale = clamp01(group.morale ~= nil and group.morale
        or combatProfile.morale or 0.65)
    local condition = clamp01(combatProfile.condition or 1)
    local desperation = 0
    for category, weight in pairs(weights) do
        local value = category == "morale" and (1 - morale)
            or category == "condition" and (1 - condition)
            or clamp01(needs[category])
        desperation = desperation + value * weight
    end
    return { stable = stable, desperation = clamp01(desperation),
        needs = needs, morale = morale, condition = condition,
        mission = group.mission }, "context_built"
end

return Behavior
