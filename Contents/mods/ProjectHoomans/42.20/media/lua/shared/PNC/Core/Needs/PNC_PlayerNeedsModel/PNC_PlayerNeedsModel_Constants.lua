PNC = PNC or {}
PNC.PlayerNeedsModel = PNC.PlayerNeedsModel or {}

local Model = PNC.PlayerNeedsModel
Model.Internal = Model.Internal or {}

-- Bump when seed-derived trait content changes. Existing generated records
-- re-roll lazily; authored records and mutable NPC state are preserved.
Model.GENERATION_VERSION = 1

Model.TRAITS = {
    HIGH_THIRST = "highthirst",
    LOW_THIRST = "lowthirst",
    HEARTY_APPETITE = "heartyappetite",
    LIGHT_EATER = "lighteater",
    NEEDS_LESS_SLEEP = "needslesssleep",
    NEEDS_MORE_SLEEP = "needsmoresleep",
    INSOMNIAC = "insomniac",
    NIGHT_OWL = "nightowl",
    OVERWEIGHT = "overweight",
    OBESE = "obese",
    UNDERWEIGHT = "underweight",
    VERY_UNDERWEIGHT = "veryunderweight",
    EMACIATED = "emaciated",
}

Model.TRAIT_DEFINITIONS = {
    { id = Model.TRAITS.HIGH_THIRST, labelKey = "UI_trait_HighThirst",
        descriptionKey = "UI_trait_HighThirstDesc" },
    { id = Model.TRAITS.LOW_THIRST, labelKey = "UI_trait_LowThirst",
        descriptionKey = "UI_trait_LowThirstDesc" },
    { id = Model.TRAITS.HEARTY_APPETITE,
        labelKey = "UI_trait_heartyappetite",
        descriptionKey = "UI_trait_heartyappetitedesc" },
    { id = Model.TRAITS.LIGHT_EATER, labelKey = "UI_trait_lighteater",
        descriptionKey = "UI_trait_lighteaterdesc" },
    { id = Model.TRAITS.NEEDS_LESS_SLEEP, labelKey = "UI_trait_LessSleep",
        descriptionKey = "UI_trait_LessSleepDesc" },
    { id = Model.TRAITS.NEEDS_MORE_SLEEP, labelKey = "UI_trait_MoreSleep",
        descriptionKey = "UI_trait_MoreSleepDesc" },
    { id = Model.TRAITS.INSOMNIAC, labelKey = "UI_trait_Insomniac",
        descriptionKey = "UI_trait_InsomniacDesc" },
    { id = Model.TRAITS.NIGHT_OWL, labelKey = "UI_trait_nightowl",
        descriptionKey = "UI_trait_nightowldesc" },
    { id = Model.TRAITS.OVERWEIGHT, labelKey = "UI_trait_overweight",
        descriptionKey = "UI_trait_overweightdesc" },
    { id = Model.TRAITS.OBESE, labelKey = "UI_trait_obese",
        descriptionKey = "UI_trait_obesedesc" },
    { id = Model.TRAITS.UNDERWEIGHT, labelKey = "UI_trait_underweight",
        descriptionKey = "UI_trait_underweightdesc" },
    { id = Model.TRAITS.VERY_UNDERWEIGHT,
        labelKey = "UI_trait_veryunderweight",
        descriptionKey = "UI_trait_veryunderweightdesc" },
    { id = Model.TRAITS.EMACIATED, labelKey = "UI_trait_emaciated",
        descriptionKey = "UI_trait_emaciateddesc" },
}

-- Neutral-heavy deterministic variety, preserving vanilla exclusions/math.
Model.GENERATION_GROUPS = {
    { salt = "thirst", choices = {
        { id = false, weight = 70 },
        { id = Model.TRAITS.HIGH_THIRST, weight = 20 },
        { id = Model.TRAITS.LOW_THIRST, weight = 10 },
    } },
    { salt = "appetite", choices = {
        { id = false, weight = 72 },
        { id = Model.TRAITS.HEARTY_APPETITE, weight = 16 },
        { id = Model.TRAITS.LIGHT_EATER, weight = 12 },
    } },
    { salt = "sleep_need", choices = {
        { id = false, weight = 76 },
        { id = Model.TRAITS.NEEDS_LESS_SLEEP, weight = 10 },
        { id = Model.TRAITS.NEEDS_MORE_SLEEP, weight = 14 },
    } },
    { salt = "sleep_quality", choices = {
        { id = false, weight = 86 },
        { id = Model.TRAITS.INSOMNIAC, weight = 8 },
        { id = Model.TRAITS.NIGHT_OWL, weight = 6 },
    } },
    { salt = "body_weight", choices = {
        { id = false, weight = 61 },
        { id = Model.TRAITS.OVERWEIGHT, weight = 16 },
        { id = Model.TRAITS.OBESE, weight = 5 },
        { id = Model.TRAITS.UNDERWEIGHT, weight = 12 },
        { id = Model.TRAITS.VERY_UNDERWEIGHT, weight = 5 },
        { id = Model.TRAITS.EMACIATED, weight = 1 },
    } },
}

function Model.Internal.TraitID(value)
    value = string.lower(tostring(value or ""))
    value = string.gsub(value, "^base[%.:]", "")
    value = string.gsub(value, "[^%w]", "")
    return value
end

return Model
