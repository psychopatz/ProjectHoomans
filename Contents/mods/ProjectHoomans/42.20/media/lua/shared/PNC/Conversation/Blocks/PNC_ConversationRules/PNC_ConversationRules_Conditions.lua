local Rules = PNC.Conversation.Rules
local Internal = Rules.Internal
local Registry = PNC.Conversation.Registry

function Internal.Compare(actual, operator, expected)
    operator = operator or ">="
    if operator == "==" then return actual == expected end
    if operator == "~=" then return actual ~= expected end
    actual = tonumber(actual)
    expected = tonumber(expected)
    if actual == nil or expected == nil then return false end
    if operator == ">=" then return actual >= expected end
    if operator == "<=" then return actual <= expected end
    if operator == ">" then return actual > expected end
    if operator == "<" then return actual < expected end
    return false
end

local function tableValue(root, key)
    return type(root) == "table" and root[key] or nil
end

local function skillLevel(context, gate)
    local actor = gate.actor == "npc" and "npc" or "player"
    local values = context[actor .. "Skills"]
    local level = tableValue(values, gate.skill)
    local player
    local perk
    if level ~= nil then return tonumber(level) or 0 end
    if actor == "npc" and PNC.Skills and PNC.Skills.GetLevel
        and context.npcRecord
    then
        return tonumber(
            PNC.Skills.GetLevel(context.npcRecord, gate.skill)
        ) or 0
    end
    player = context.player
    if actor == "player" and player and player.getPerkLevel then
        perk = gate.perk
        if not perk and Perks and Perks.FromString then
            perk = Perks.FromString(tostring(gate.skill or ""))
        end
        if perk then return tonumber(player:getPerkLevel(perk)) or 0 end
    end
    return 0
end

local function personalityValue(context, gate)
    local actor = gate.actor == "player" and "player" or "npc"
    local values = actor == "npc"
        and (context.npcPersonality
            or context.npcRecord and context.npcRecord.personality)
        or (context.playerPersonality or context.playerSocialProfile)
    return tableValue(values, gate.key or gate.dimension)
end

local function hasTrait(context, gate)
    local traits
    local value
    local player
    if gate.actor == "npc" then
        traits = context.npcTraits
    else
        traits = context.playerTraits
            or context.playerSocialProfile
                and context.playerSocialProfile.sourceTraits
    end
    if type(traits) == "table" then
        if traits[gate.trait] == true then return true end
        for _, value in ipairs(traits) do
            if value == gate.trait then return true end
        end
    end
    player = context.player
    return gate.actor ~= "npc" and player and player.HasTrait
        and player:HasTrait(gate.trait) == true or false
end

local function timeMatches(context, gate)
    local hour = tonumber(context.hour)
    local first = tonumber(gate.startHour) or 0
    local last = tonumber(gate.endHour) or 24
    if hour == nil then
        hour = (tonumber(context.worldAgeHours) or 0) % 24
    end
    if first <= last then return hour >= first and hour < last end
    return hour >= first or hour < last
end

local function historyMatches(context, gate)
    local entry = context.historyEntry
    if type(context.historyLookup) == "function" then
        entry = context.historyLookup(gate.subjectID, gate.scope)
    end
    entry = type(entry) == "table" and entry or {}
    if gate.maxUses ~= nil
        and (tonumber(entry.useCount) or 0) >= tonumber(gate.maxUses)
    then
        return false
    end
    if gate.cooldownHours ~= nil and entry.lastUsedWorldHour ~= nil
        and (tonumber(context.worldAgeHours) or 0)
            < tonumber(entry.lastUsedWorldHour)
                + tonumber(gate.cooldownHours)
    then
        return false
    end
    return true
end

local BUILTINS = {
    ["pnc:skill"] = function(context, gate)
        return Internal.Compare(
            skillLevel(context, gate), gate.operator, gate.value
        )
    end,
    ["pnc:trait"] = function(context, gate)
        return hasTrait(context, gate) == (gate.present ~= false)
    end,
    ["pnc:personality"] = function(context, gate)
        return Internal.Compare(
            personalityValue(context, gate), gate.operator, gate.value
        )
    end,
    ["pnc:relationship"] = function(context, gate)
        local relationship = context.relationship or {}
        return Internal.Compare(
            relationship[gate.axis or gate.key],
            gate.operator,
            gate.value
        )
    end,
    ["pnc:relationship_state"] = function(context, gate)
        return tostring(context.relationshipState or "")
            == tostring(gate.value or "")
    end,
    ["pnc:audience"] = function(context, gate)
        return context.audiences
            and context.audiences[
                tostring(gate.value or gate.audience)
            ] == true or false
    end,
    ["pnc:time"] = timeMatches,
    ["pnc:history"] = historyMatches,
    ["pnc:base_not_established"] = function(context)
        return context.baseEstablished ~= true
    end,
}

local id
local evaluate
for id, evaluate in pairs(BUILTINS) do
    if not Registry.conditionHandlers[id] then
        Registry.RegisterConditionHandler(id, {
            evaluate = evaluate,
            builtin = true,
        })
    end
end
