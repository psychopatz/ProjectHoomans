-- Response pools for the typed weather-gate pilot flow.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.ResponseCatalog
if type(Catalog) ~= "table" or type(Catalog.Register) ~= "function" then
    return false
end

Catalog.Register("semantic.flow.weather.raining", {
    variants = {
        {
            id = "semantic.flow.weather.raining.default",
            templateID = "semantic.flow.weather.raining.default",
            fallback = "It is raining right now. I would wait for a break.",
        },
    },
})

Catalog.Register("semantic.flow.weather.clear", {
    variants = {
        {
            id = "semantic.flow.weather.clear.default",
            templateID = "semantic.flow.weather.clear.default",
            fallback = "The weather looks clear right now.",
        },
    },
})

Catalog.Register("semantic.flow.weather.unknown", {
    variants = {
        {
            id = "semantic.flow.weather.unknown.default",
            templateID = "semantic.flow.weather.unknown.default",
            fallback = "I cannot confirm the weather from here.",
        },
    },
})

return true
