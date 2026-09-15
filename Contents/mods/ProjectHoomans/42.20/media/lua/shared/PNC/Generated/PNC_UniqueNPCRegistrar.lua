-- Stable registrar used by the generated unique NPC catalog.
-- The catalog imports this function instead of reaching into the registry
-- implementation directly.

local API = require "PNC/Core/API/PNC_API/UniqueNPCs"

return function(definition)
    local ok, value = API.Register(definition, {
        source = "ProjectHoomans.GeneratedUniqueNPC",
    })
    if not ok and print then
        print("[PNC][UniqueNPC] generated definition rejected: "
            .. tostring(value))
    end
    return definition
end
