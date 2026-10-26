-- Project the production NPC health record into semantic context fields.

local Health = {}

local function legacyBody(state)
    if state ~= "injured" and state ~= "wounded" and state ~= "critical" then
        return nil
    end
    return {
        openWoundCount = 1,
        bandagedWoundCount = 0,
        infected = false,
        wounds = { legacy = { type = "legacy_fixture_injury" } },
        overallPercent = state == "critical" and 50 or 98,
    }
end

function Health.project(npc, copy, number)
    local record = type(npc.health) == "table" and npc.health or {}
    local state = record.state
    local current = number(record.current, nil)
    local maximum = number(record.max, nil)
    local body = type(record.body) == "table" and copy(record.body) or nil

    -- Transitional adapter for callers that bypass the Python scenario
    -- normalizer. New worker traffic never needs these top-level fields.
    if npc.healthState ~= nil then state = npc.healthState end
    if npc.hpCurrent ~= nil then current = number(npc.hpCurrent, nil) end
    if npc.hpMax ~= nil then maximum = number(npc.hpMax, nil) end
    if npc.bodyHealth ~= nil then
        body = type(npc.bodyHealth) == "table" and copy(npc.bodyHealth) or nil
    end
    if state ~= nil then state = string.lower(tostring(state)) end
    if state == "healthy" then state = "normal" end
    if state == "unknown" then state = nil end
    if state == "injured" or state == "wounded" or state == "critical" then
        body = body or legacyBody(state)
        state = "normal"
    end
    return {
        state = state,
        current = current,
        maximum = maximum,
        body = body,
        record = copy(record),
    }
end

return Health
