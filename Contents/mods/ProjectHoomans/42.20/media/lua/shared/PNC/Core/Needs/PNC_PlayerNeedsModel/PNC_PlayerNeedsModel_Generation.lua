local Model = PNC.PlayerNeedsModel
local Internal = Model.Internal

function Model.NormalizeTraits(source)
    local output = {}
    for key, value in pairs(type(source) == "table" and source or {}) do
        local id = type(key) == "number"
            and Internal.TraitID(value) or Internal.TraitID(key)
        local enabled = type(key) == "number" or value == true
        if id ~= "" and enabled then output[id] = true end
    end
    return output
end

local function weightedChoice(seed, salt, choices)
    local total = 0
    local index
    for index = 1, #choices do
        total = total + math.max(0, tonumber(choices[index].weight) or 0)
    end
    if total <= 0 then return nil end
    local roll
    if PNC.Identity and PNC.Identity.Float then
        roll = PNC.Identity.Float(seed, salt) * total
    elseif PNC.Identity and PNC.Identity.MixSeed then
        roll = (PNC.Identity.MixSeed(seed, salt) % 100000) / 100000 * total
    else
        roll = 0
    end
    local cursor = 0
    for index = 1, #choices do
        cursor = cursor + math.max(0, tonumber(choices[index].weight) or 0)
        if roll < cursor then return choices[index].id end
    end
    return choices[#choices].id
end

function Model.GenerateTraits(identitySeed, archetypeID)
    local seed = PNC.Identity and PNC.Identity.NormalizeSeed
        and PNC.Identity.NormalizeSeed(identitySeed, archetypeID)
        or math.max(1, math.floor(tonumber(identitySeed) or 1))
    local prefix = "npc_vanilla_traits:v"
        .. tostring(Model.GENERATION_VERSION) .. ":"
        .. tostring(archetypeID or "General") .. ":"
    local output = {}
    local index
    for index = 1, #Model.GENERATION_GROUPS do
        local group = Model.GENERATION_GROUPS[index]
        local selected = weightedChoice(
            seed,
            prefix .. tostring(group.salt),
            group.choices
        )
        if selected then output[selected] = true end
    end
    if output[Model.TRAITS.VERY_UNDERWEIGHT] then
        output[Model.TRAITS.HEARTY_APPETITE] = nil
    end
    if output[Model.TRAITS.OBESE] then
        output[Model.TRAITS.LIGHT_EATER] = nil
    end
    return output
end

function Model.ResolveInitialTraits(source, identitySeed, archetypeID, authored)
    if authored == true then
        return Model.NormalizeTraits(source), true, 0
    end
    return Model.GenerateTraits(identitySeed, archetypeID), false,
        Model.GENERATION_VERSION
end

return Model
