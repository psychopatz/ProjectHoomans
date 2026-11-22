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

local function distSq(x1, y1, x2, y2)
    if type(I.DistSq) == "function" then return I.DistSq(x1, y1, x2, y2) end
    local dx, dy = (tonumber(x2) or 0) - (tonumber(x1) or 0), (tonumber(y2) or 0) - (tonumber(y1) or 0)
    return dx * dx + dy * dy
end

local function findNearbyPlayerAddressee(rec, radius)
    local core = PNC.Core
    if not (core and type(core.ForEachPlayer) == "function") then return nil end
    local nx, ny, nz = tonumber(rec.x) or 0, tonumber(rec.y) or 0, tonumber(rec.z) or 0
    local rSq, found, bestDist = radius * radius, nil, nil
    core.ForEachPlayer(function(p)
        if not p or (type(p.isDead) == "function" and p:isDead()) then return end
        local px = type(p.getX) == "function" and tonumber(p:getX()) or nil
        local py = type(p.getY) == "function" and tonumber(p:getY()) or nil
        local pz = type(p.getZ) == "function" and tonumber(p:getZ()) or 0
        if px == nil or py == nil or math.abs(pz - nz) >= 1 then return end
        local d = distSq(nx, ny, px, py)
        if d <= rSq and (bestDist == nil or d < bestDist) then
            local desc = type(p.getDescriptor) == "function" and p:getDescriptor() or nil
            local fore = desc and type(desc.getForename) == "function" and tostring(desc:getForename() or "") or ""
            local uname = type(p.getUsername) == "function" and tostring(p.getUsername() or "") or ""
            local pname = (fore ~= "" and fore) or (uname ~= "" and uname) or "partner"
            found, bestDist = { id = "player", name = pname }, d
        end
    end)
    return found
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
