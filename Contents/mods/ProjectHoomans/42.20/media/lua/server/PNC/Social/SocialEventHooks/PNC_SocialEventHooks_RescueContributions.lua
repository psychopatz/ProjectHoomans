if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEventHooks = PNC.SocialEventHooks or {}
PNC.SocialEventHooksInternal = PNC.SocialEventHooksInternal or {}

local Hooks = PNC.SocialEventHooks
local H = PNC.SocialEventHooksInternal
local EntityRef = PNC.EntityRef
local Core = PNC.Core

function Hooks.GetDownedEpisodeID(record, downedAt)
    downedAt = tonumber(downedAt)
        or tonumber(record and record.health and record.health.downedAt)
    if not record or not record.id or not downedAt or downedAt <= 0 then
        return nil
    end
    return "downed:" .. tostring(record.id)
        .. ":" .. tostring(math.floor(downedAt))
end

function Hooks.RecordRescueContribution(
    targetRecord,
    actorKey,
    occurredAt
)
    local episodeID = Hooks.GetDownedEpisodeID(targetRecord)
    local contributors
    local entry
    if not episodeID or not EntityRef.IsValid(actorKey) then
        return false, "invalid_rescue_contribution"
    end
    contributors = Hooks.RescueContributions[episodeID] or {}
    entry = contributors[actorKey] or {
        actorKey = actorKey,
        actionCount = 0,
        lastAt = 0,
    }
    entry.actionCount = entry.actionCount + 1
    entry.lastAt = math.max(
        tonumber(entry.lastAt) or 0,
        tonumber(occurredAt) or H.WorldAgeHours()
    )
    contributors[actorKey] = entry
    Hooks.RescueContributions[episodeID] = contributors
    return true, episodeID
end

function Hooks.DiscardRescueContributions(targetRecord)
    local prefix = targetRecord and targetRecord.id
        and ("downed:" .. tostring(targetRecord.id) .. ":") or nil
    local episodeID
    local removed = 0
    if not prefix then
        return 0
    end
    for episodeID, _ in pairs(Hooks.RescueContributions) do
        if string.sub(episodeID, 1, #prefix) == prefix then
            Hooks.RescueContributions[episodeID] = nil
            removed = removed + 1
        end
    end
    return removed
end

return Hooks

