if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Conduct = PNC.Conduct
local H = Conduct.Internal
local Core = PNC.Core
local EntityRef = PNC.EntityRef
local Types = PNC.ConductTypes
local Math = PNC.ConductMath
local Constants = PNC.ConductConstants

function Conduct.PrepareSocialEvent(event, definition)
    local participants = {}
    local function add(actorKey, subjectKey, role)
        participants[#participants + 1] = {
            actorKey = actorKey,
            subjectKey = subjectKey,
            role = role,
        }
    end
    if type(event) ~= "table" or type(definition) ~= "table" then
        return nil, "invalid_social_event"
    end
    if definition.participants == "actor_and_target" then
        add(event.actorKey, event.targetKey, definition.role)
        add(event.targetKey, event.actorKey, definition.role)
    else
        add(event.actorKey, event.targetKey, definition.role)
    end
    local prepared = {}
    for _, participant in ipairs(participants) do
        local evidenceID = "conduct:" .. event.id .. ":"
            .. participant.actorKey .. ":" .. participant.role
        local item, reason = H.PrepareEvidence(
            participant.actorKey,
            {
                id = evidenceID,
                eventID = event.id,
                eventType = event.type,
                actorKey = participant.actorKey,
                subjectKey = participant.subjectKey,
                createdAt = event.occurredAt,
                lastEvaluatedAt = event.occurredAt,
                effects = definition.effects,
                strength = 1,
                decayPerDay = definition.decayPerDay,
                permanent = definition.permanent == true,
                visibility = definition.visibility,
                shareable = definition.shareable == true,
                tags = definition.tags,
            }
        )
        if not item then return nil, reason end
        prepared[#prepared + 1] = item
    end
    return prepared
end

function Conduct.CommitPrepared(prepared)
    if not H.Authority() then return false, "not_authority" end
    for _, item in ipairs(prepared or {}) do
        local current, reason = Conduct.GetForEntity(item.entityKey)
        if not current then return false, reason end
        if not Types.AreEqual(current, item.before) then
            return false, "conduct_changed_during_event"
        end
    end
    local details = {}
    for _, item in ipairs(prepared or {}) do
        local ok, reason, conduct = H.Commit(item.owner, item.after)
        if not ok then return false, reason end
        details[#details + 1] = {
            entityKey = item.entityKey,
            evidenceID = item.evidenceID,
            evidence = H.Copy(item.evidence),
            conduct = conduct,
        }
    end
    return true, "applied", details
end

function Conduct.ApplySocialEvent(event, definition)
    local prepared, reason =
        Conduct.PrepareSocialEvent(event, definition)
    if not prepared then return false, reason end
    return Conduct.CommitPrepared(prepared)
end
