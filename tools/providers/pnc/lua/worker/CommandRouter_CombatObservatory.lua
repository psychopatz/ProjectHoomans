-- Combat Observatory worker commands. Inspection is read-only; fixture
-- orchestration is explicit and disposable.
local Handler = {}
local CombatObservatory = require "worker/CombatObservatory"

function Handler.handle(context, command, payload)
    if command == "COMBAT_OBSERVATORY_FIXTURE" then
        if type(payload) ~= "table" then
            return nil, "combat_observatory_fixture_must_be_object"
        end
        return CombatObservatory.fixture(context, payload)
    elseif command == "COMBAT_OBSERVATORY_INSPECT" then
        if payload ~= nil and type(payload) ~= "table" then
            return nil, "combat_observatory_inspect_must_be_object"
        end
        return CombatObservatory.inspect(context, payload or {})
    end
    return false
end

return Handler
