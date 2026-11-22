if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.Semantics.CombatTargetCalloutsInternal = PNC.Semantics.CombatTargetCalloutsInternal or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_Situations"

local S = PNC.Semantics.CombatTargetCallouts or {}
local I = PNC.Semantics.CombatTargetCalloutsInternal
PNC.Semantics.CombatTargetCallouts = S

local teamStaminaCalloutAt = {}

local function findNearbyPlayerAddressee(rec, radius)
    return type(I.FindNearbyPlayerAddressee) == "function"
        and I.FindNearbyPlayerAddressee(rec, radius)
        or nil
end

--- Emit a serialized winded/exhausted semantic callout and optional squadmate cover reply.
function S.OnStaminaFatigue(record, staminaState, now, opts)
    if type(record) ~= "table" or record.alive == false or record.id == nil then return false end
    if type(record.health) == "table" and record.health.state == "incapacitated" then return false end
    staminaState = tostring(staminaState or "")
    if staminaState ~= "winded" and staminaState ~= "exhausted" then return false end
    now = I.SituationNow(now)
    record.runtime = type(record.runtime) == "table" and record.runtime or {}
    local lastWinded = tonumber(record.runtime.lastWindedCalloutAt) or -99999
    local lastExhausted = tonumber(record.runtime.lastExhaustedCalloutAt) or -99999
    if staminaState == "winded" then
        if now - lastWinded < 18000 or now - lastExhausted < 18000 then return false end
    elseif now - lastExhausted < 14000 or now - lastWinded < 4000 then
        return false
    end
    local perc = PNC.Perception
    local teamKey = tostring(perc and perc.GetTeamKey and perc.GetTeamKey(record) or "__default__")
    local lastTeamAt = tonumber(teamStaminaCalloutAt[teamKey]) or -99999
    if now - lastTeamAt < 6000 then return false end

    local mates = I.FindSquadmates(record, 14)
    local coverAlly = nil
    for i = 1, #mates do
        if tostring(mates[i].attackType or "auto") ~= "none" then
            coverAlly = mates[i]
            break
        end
    end
    local addressee = coverAlly or mates[1] or findNearbyPlayerAddressee(record, 14)
    if not addressee then return false end

    local role = staminaState == "exhausted" and "stamina_exhausted" or "stamina_winded"
    local desc = { semanticClass = "human_hostile", enemyType = "hostile", x = record.x, y = record.y, z = record.z }
    local ref = "stamina:" .. tostring(record.id) .. ":" .. tostring(math.floor(now))
    local spoke = I.EmitSituationCallout(record, addressee, desc, role, now, ref)
    if not spoke then return false end
    if staminaState == "exhausted" then
        record.runtime.lastExhaustedCalloutAt = now
    else
        record.runtime.lastWindedCalloutAt = now
    end
    teamStaminaCalloutAt[teamKey] = now

    local allyResponder = coverAlly or mates[1]
    if allyResponder and S.EnqueueCustomReply then
        local underThreat = (perc and perc.GetActiveSkirmish and perc.GetActiveSkirmish(teamKey, now) ~= nil)
            or type(record.runtime.target) == "table"
            or (type(allyResponder.runtime) == "table" and type(allyResponder.runtime.target) == "table")
        if staminaState == "exhausted" or underThreat or (type(opts) == "table" and opts.retreating == true) then
            S.EnqueueCustomReply({
                speaker = allyResponder, addressee = record, desc = desc, role = "cover_winded",
                canEngage = tostring(allyResponder.attackType or "auto") ~= "none",
                now = now, delayMs = 650, eventRef = ref .. ":cover", threadID = ref,
                barkOpts = I.SituationBarkOpts,
            })
        end
    end
    return true
end

function S.ResetStaminaCallouts()
    teamStaminaCalloutAt = {}
end

return S
