PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.ActionRiskCatalog or {}
PNC.Semantics.ActionRiskCatalog = Catalog

Catalog.VERSION = 1

Catalog.FUZZY_SAFE_ACTIONS = {
    FOLLOW = true,
    STOP = true,
    STAY = true,
}

-- Exact open-text requests may defer concrete entity/item binding to an
-- existing authoritative selector. Fuzzy/recovered interpretations never
-- gain this privilege.
Catalog.DEFERRED_RESOLUTION_ACTIONS = {
    GIVE = true,
    FETCH = true,
    TAKE = true,
    EAT = true,
    DRINK = true,
    CONSUME = true,
    REFILL = true,
    WAIT_AT = true,
    CAMP = true,
}

function Catalog.IsFuzzySafe(action)
    return Catalog.FUZZY_SAFE_ACTIONS[tostring(action or "")] == true
end

function Catalog.AllowsDeferredResolution(action)
    return Catalog.DEFERRED_RESOLUTION_ACTIONS[
        tostring(action or "")
    ] == true
end

return Catalog
