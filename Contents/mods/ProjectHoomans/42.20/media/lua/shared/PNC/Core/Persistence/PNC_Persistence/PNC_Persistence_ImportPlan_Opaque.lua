-- Preserve serialized roots that are outside the bounded Core NPC contract.

local Utils = require
    "PNC/Core/Persistence/PNC_Persistence/PNC_Persistence_ImportPlan_Utils"

local Opaque = {}

-- These roots have an explicit adapter in the bounded P0B candidate. Every
-- other serialized root must remain visible to a future writer instead of
-- disappearing between the source record and the candidate.
local REPRESENTED = {
    schemaVersion = true,
    id = true,
    identity = true,
    inventory = true,
    social = true,
    position = true,
    spawn = true,
    anchor = true,
    travel = true,
}

local function add(decisions, ...)
    return Utils.AddDecision(decisions, ...)
end

function Opaque.Build(raw, decisions)
    local output = {}
    local count = 0
    local key

    if type(raw) ~= "table" then return output end
    for key, value in pairs(raw) do
        if not REPRESENTED[key] then
            output[key] = Utils.Copy(value)
            count = count + 1
            add(decisions, "source.opaque." .. tostring(key), "projected",
                tostring(key), "canonical_mapping_deferred")
        end
    end
    if count > 0 then
        add(decisions, "source.opaque", "projected", "<serialized-root>",
            "canonical_mapping_deferred")
    end
    return output
end

return Opaque
