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

        },
    },
})

Catalog.Register("semantic.flow.weather.clear", {
    variants = {
        {
            id = "semantic.flow.weather.clear.default",
            templateID = "semantic.flow.weather.clear.default",

        },
    },
})

Catalog.Register("semantic.flow.weather.unknown", {
    variants = {
        {
            id = "semantic.flow.weather.unknown.default",
            templateID = "semantic.flow.weather.unknown.default",

        },
    },
})

return true
