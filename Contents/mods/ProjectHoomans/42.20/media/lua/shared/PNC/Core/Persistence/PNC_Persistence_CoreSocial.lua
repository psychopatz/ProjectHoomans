-- Read/project bridge for Core-owned directed social state. Hoomans remains
-- the source of legacy records, while Core owns the canonical social ledger.

PNC = PNC or {}
PNC.Persistence = PNC.Persistence or {}

local Persistence = PNC.Persistence
local Adapter = Persistence.CoreSocial or {}
Persistence.CoreSocial = Adapter

local function service(core)
    return core and core.Actors and core.Actors.Social
end

function Adapter.Project(record, core)
    local Social = service(core)
    if not Social or type(Social.NewState) ~= "function" then
        return nil, "core_social_unavailable"
    end
    if type(record) ~= "table" or type(record.social) ~= "table" then
        return nil, "source_social_missing"
    end
    return Social.NewState(record.social)
end

function Adapter.RecordAuthorizedEvent(state, core, event)
    local Social = service(core)
    if not Social or type(Social.RecordAuthorizedEvent) ~= "function" then
        return nil, "core_social_unavailable"
    end
    return Social.RecordAuthorizedEvent(state, event)
end

return Adapter
