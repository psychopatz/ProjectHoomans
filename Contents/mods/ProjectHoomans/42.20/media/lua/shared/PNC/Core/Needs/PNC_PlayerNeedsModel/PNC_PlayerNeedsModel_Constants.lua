PNC = PNC or {}
PNC.PlayerNeedsModel = PNC.PlayerNeedsModel or {}

local Model = PNC.PlayerNeedsModel
Model.Internal = Model.Internal or {}

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
    { id = Model.TRAITS.HIGH_THIRST, labelKey = "UI_trait_HighThirst" },
    { id = Model.TRAITS.LOW_THIRST, labelKey = "UI_trait_LowThirst" },
    { id = Model.TRAITS.HEARTY_APPETITE,
        labelKey = "UI_trait_heartyappetite" },
    { id = Model.TRAITS.LIGHT_EATER, labelKey = "UI_trait_lighteater" },
    { id = Model.TRAITS.NEEDS_LESS_SLEEP, labelKey = "UI_trait_LessSleep" },
    { id = Model.TRAITS.NEEDS_MORE_SLEEP, labelKey = "UI_trait_MoreSleep" },
    { id = Model.TRAITS.INSOMNIAC, labelKey = "UI_trait_Insomniac" },
    { id = Model.TRAITS.NIGHT_OWL, labelKey = "UI_trait_nightowl" },
    { id = Model.TRAITS.OVERWEIGHT, labelKey = "UI_trait_overweight" },
    { id = Model.TRAITS.OBESE, labelKey = "UI_trait_obese" },
    { id = Model.TRAITS.UNDERWEIGHT, labelKey = "UI_trait_underweight" },
    { id = Model.TRAITS.VERY_UNDERWEIGHT,
        labelKey = "UI_trait_veryunderweight" },
    { id = Model.TRAITS.EMACIATED, labelKey = "UI_trait_emaciated" },
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
