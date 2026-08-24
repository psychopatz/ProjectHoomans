if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.DebugCompanionRecruit = PNC.DebugCompanionRecruit or {}
PNC.Recruitment = PNC.Recruitment or PNC.DebugCompanionRecruit
PNC.DebugCompanionRecruitInternal =
    PNC.DebugCompanionRecruitInternal or {}

local Recruit = PNC.DebugCompanionRecruit
local H = PNC.DebugCompanionRecruitInternal
local Const = PNC.Const
local Core = PNC.Core
local Factions = PNC.Factions
local Registry = PNC.Registry
local Graph = PNC.RelationshipGraph

function Recruit.Try(player, args)
    args = type(args) == "table" and args or {}
    if not player then return false, "player_unavailable" end
    local npcID = tostring(args.npcID or args.id or "")
    local record = npcID ~= "" and Registry.Get(npcID) or nil
    if not record then return false, "npc_not_found" end
    if not Recruit.IsEligible(record) then
        return false, "npc_not_debug_recruitable"
    end
    local ok
    local reason
    local result
    ok, reason, result = Recruit.Assign(player, record, {
        source = "debug_companion_recruit",
        tags = { debugCreated = true },
    })
    if not ok then return false, reason end
    if Core and Core.LogInfo then
        Core.LogInfo("PNC debug recruited npc=" .. tostring(record.id)
            .. " player=" .. tostring(player and player.getUsername
                and player:getUsername() or "unknown"))
    end
    return true, "recruited", result
end

function Recruit.TryConversation(player, args, relationship)
    args = type(args) == "table" and args or {}
    local npcID = tostring(args.npcID or args.id or "")
    local record = npcID ~= "" and Registry.Get(npcID) or nil
    if not record then return false, "npc_not_found" end
    local evaluation = Recruit.EvaluateConversation(record, relationship)
    if not evaluation.eligible then
        return false, evaluation.reason, evaluation
    end
    local ok, reason, result = Recruit.Try(player, { npcID = npcID })
    if not ok then return false, reason, result end
    result = type(result) == "table" and result or {}
    result.route = evaluation.route
    result.relationship = {
        approval = evaluation.approval,
        respect = evaluation.respect,
        attitude = evaluation.attitude,
    }
    return true, reason, result
end

return Recruit

