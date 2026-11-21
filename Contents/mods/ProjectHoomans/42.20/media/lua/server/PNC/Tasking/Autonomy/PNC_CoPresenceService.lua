-- Lightweight Co-Presence Situations submitting bounded social opportunities into SceneAdopters.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CoPresenceService = PNC.CoPresenceService or {}

local Service = PNC.CoPresenceService
local AutonomyAdRegistry = PNC.AutonomyAd and PNC.AutonomyAd.Registry
if not AutonomyAdRegistry and type(require) == "function" then
    AutonomyAdRegistry = require "PNC/AutonomyAd/Registry"
end

Service.MAX_NEIGHBORS = 16
Service.DEFAULT_COOLDOWN_MS = 45000
Service.CooldownUntil = Service.CooldownUntil or {}
Service.PairCooldownUntil = Service.PairCooldownUntil or {}
Service.LastDiagnostics = Service.LastDiagnostics or {}

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    return PNC.Core and type(PNC.Core.Now) == "function" and PNC.Core.Now() or 0
end

local function registry()
    if PNC.AutonomyAd and PNC.AutonomyAd.Registry then
        return PNC.AutonomyAd.Registry
    end
    return AutonomyAdRegistry
end

local function resolveSubmitter(opts)
    if type(opts) == "table" and type(opts.submitSocial) == "function" then
        return opts.submitSocial
    end
    local convo = PNC.ConvoEngine
    local adopters = convo and (convo.InteractionSceneAdopters
        or (convo.Interaction and convo.Interaction.SceneAdopters)) or nil
    if adopters and type(adopters.SubmitSocial) == "function" then
        return adopters.SubmitSocial
    end
    return nil
end

local function isParticipantEligible(candidate, at)
    if type(candidate) ~= "table" or candidate.alive == false then
        return false
    end
    local runtime = type(candidate.runtime) == "table" and candidate.runtime or nil
    if runtime then
        if runtime.combatTarget ~= nil
            or runtime.attackAction ~= nil
            or runtime.medicalCare ~= nil
            or runtime.treatment ~= nil
            or at < (tonumber(runtime.inCombatUntil) or 0)
        then
            return false
        end
    end
    local actorControl = PNC.ActorControl
    if actorControl and type(actorControl.IsPuppetOwned) == "function"
        and actorControl.IsPuppetOwned(candidate) == true
    then
        return false
    end
    return true
end

local function collectNearbyPeers(record, maxRadius, at, opts)
    local npcId = tostring(record.id or "")
    local originX = tonumber(record.x)
    local originY = tonumber(record.y)
    if not originX or not originY then return {} end

    local radius = tonumber(maxRadius) or 5.0
    local radiusSq = radius * radius
    local originZ = tonumber(record.z) or 0
    local sourceList = type(opts) == "table" and opts.candidates or nil

    local matches = {}
    local function considerPeer(peer)
        if type(peer) ~= "table" then return end
        local peerId = tostring(peer.id or "")
        if peerId == "" or peerId == npcId or not isParticipantEligible(peer, at) then
            return
        end
        local px = tonumber(peer.x)
        local py = tonumber(peer.y)
        local pz = tonumber(peer.z) or 0
        if px and py and math.abs(pz - originZ) < 1.0 then
            local dx = px - originX
            local dy = py - originY
            local distSq = dx * dx + dy * dy
            if distSq <= radiusSq then
                matches[#matches + 1] = {
                    record = peer,
                    id = peerId,
                    distSq = distSq,
                }
            end
        end
    end

    if type(sourceList) == "table" then
        for i = 1, #sourceList do
            considerPeer(sourceList[i])
        end
    elseif PNC.SpatialIndex and type(PNC.SpatialIndex.QueryNPCs) == "function" then
        local nearby = PNC.SpatialIndex.QueryNPCs(originX, originY, radius)
        if type(nearby) == "table" then
            for i = 1, #nearby do
                considerPeer(nearby[i])
            end
        end
    elseif PNC.Registry and type(PNC.Registry.Data) == "table" then
        for _, peer in pairs(PNC.Registry.Data) do
            considerPeer(peer)
        end
    end

    table.sort(matches, function(a, b)
        if math.abs(a.distSq - b.distSq) > 1e-6 then
            return a.distSq < b.distSq
        end
        return a.id < b.id
    end)

    if #matches > Service.MAX_NEIGHBORS then
        local trimmed = {}
        for i = 1, Service.MAX_NEIGHBORS do
            trimmed[i] = matches[i]
        end
        return trimmed
    end
    return matches
end

local function matchesSituationContext(record, sitId, opts)
    local explicitSit = type(opts) == "table" and opts.situationId or nil
    if explicitSit ~= nil then
        return tostring(explicitSit) == sitId
    end
    local adId = tostring(type(opts) == "table" and opts.adId or "")
    if sitId == "situation.lounge_hangout" then
        if adId == "ad.social_lounge" or adId == "ad.rest_seat" then
            return true
        end
        local activity = record.runtime and record.runtime.facilityActivity or nil
        if type(activity) == "table" and activity.seating == true then
            return true
        end
        return false
    end
    if sitId == "situation.camp_chat" then
        if adId == "ad.roam_patrol" or adId == "ad.rest_seat" or adId == "" then
            return true
        end
        local kind = tostring(record.orderSpec and record.orderSpec.kind or "")
        return kind == "camp" or kind == "colony_home" or kind == "roam"
    end
    return true
end

local function pairKey(sitId, participantIds)
    local sorted = {}
    for i = 1, #participantIds do
        sorted[i] = participantIds[i]
    end
    table.sort(sorted)
    return sitId .. ":" .. table.concat(sorted, ",")
end

local function setDiagnostic(npcId, entry)
    if npcId == "" then return end
    Service.LastDiagnostics[npcId] = entry
end

---Attempts to trigger a compiled Co-Presence Situation around `record`.
function Service.TryTriggerForNPC(record, at, opts)
    if type(record) ~= "table" or not record.id then
        return false, "INVALID_RECORD"
    end
    local npcId = tostring(record.id)
    local current = nowMs(at)
    if not isParticipantEligible(record, current) then
        setDiagnostic(npcId, {
            at = current,
            triggered = false,
            reason = "INITIATOR_INELIGIBLE",
        })
        return false, "INITIATOR_INELIGIBLE"
    end

    local reg = registry()
    local situations = reg and reg.situations or nil
    if type(situations) ~= "table" then
        setDiagnostic(npcId, {
            at = current,
            triggered = false,
            reason = "SITUATIONS_REGISTRY_UNAVAILABLE",
        })
        return false, "SITUATIONS_REGISTRY_UNAVAILABLE"
    end

    local sitIds = {}
    for sitId in pairs(situations) do
        sitIds[#sitIds + 1] = sitId
    end
    table.sort(sitIds)

    local lastReason = "NO_MATCHING_SITUATION"
    for i = 1, #sitIds do
        local sitId = sitIds[i]
        local sitSpec = situations[sitId]
        if type(sitSpec) == "table" and matchesSituationContext(record, sitId, opts) then
            local cooldownUntil = tonumber(Service.CooldownUntil[sitId]) or 0
            if current < cooldownUntil then
                lastReason = "SITUATION_COOLDOWN"
            else
                local minParticipants = math.max(2, tonumber(sitSpec.minParticipants) or 2)
                local maxParticipants = math.max(minParticipants, tonumber(sitSpec.maxParticipants) or minParticipants)
                local peers = collectNearbyPeers(record, sitSpec.maxRadius, current, opts)
                if 1 + #peers < minParticipants then
                    lastReason = "INSUFFICIENT_PEERS"
                else
                    local participantIds = { npcId }
                    for j = 1, #peers do
                        if #participantIds >= maxParticipants then break end
                        participantIds[#participantIds + 1] = peers[j].id
                    end
                    local pKey = pairKey(sitId, participantIds)
                    local pairWait = tonumber(Service.PairCooldownUntil[pKey]) or 0
                    if current < pairWait then
                        lastReason = "PAIR_COOLDOWN"
                    else
                        local submitSocial = resolveSubmitter(opts)
                        if not submitSocial then
                            setDiagnostic(npcId, {
                                at = current,
                                situationId = sitId,
                                triggered = false,
                                reason = "SCENE_ADOPTERS_UNAVAILABLE",
                                participants = participantIds,
                            })
                            return false, "SCENE_ADOPTERS_UNAVAILABLE"
                        end
                        local roleMap = {}
                        local roles = type(sitSpec.roles) == "table" and sitSpec.roles or {}
                        for pIdx = 1, #participantIds do
                            local roleName = roles[pIdx] or roles[#roles] or "participant"
                            roleMap[participantIds[pIdx]] = roleName
                        end
                        local ok, submitReason, submitResult = submitSocial({
                            motive = sitId,
                            opportunityId = sitSpec.socialOpportunityId,
                            situationId = sitId,
                            convoFamilyId = sitSpec.convoFamilyId,
                            speakerID = npcId,
                            participants = participantIds,
                            roles = roleMap,
                            source = "PNC.CoPresenceService",
                            now = current,
                        })
                        if ok == true then
                            local cooldownMs = tonumber(sitSpec.cooldownMs) or Service.DEFAULT_COOLDOWN_MS
                            Service.CooldownUntil[sitId] = current + cooldownMs
                            Service.PairCooldownUntil[pKey] = current + cooldownMs
                            setDiagnostic(npcId, {
                                at = current,
                                situationId = sitId,
                                opportunityId = sitSpec.socialOpportunityId,
                                convoFamilyId = sitSpec.convoFamilyId,
                                triggered = true,
                                reason = "SUBMITTED",
                                participants = participantIds,
                                roles = roleMap,
                            })
                            return true, "SUBMITTED", submitResult
                        else
                            lastReason = tostring(submitReason or "SUBMIT_REJECTED")
                            setDiagnostic(npcId, {
                                at = current,
                                situationId = sitId,
                                triggered = false,
                                reason = lastReason,
                                participants = participantIds,
                            })
                        end
                    end
                end
            end
        end
    end

    setDiagnostic(npcId, {
        at = current,
        triggered = false,
        reason = lastReason,
    })
    return false, lastReason
end

function Service.GetDiagnostics(npcId)
    local key = tostring(npcId or "")
    local entry = Service.LastDiagnostics[key]
    if not entry then return nil end
    if PNC.Core and type(PNC.Core.DeepCopy) == "function" then
        return PNC.Core.DeepCopy(entry)
    end
    return entry
end

function Service.Reset()
    Service.CooldownUntil = {}
    Service.PairCooldownUntil = {}
    Service.LastDiagnostics = {}
end

return Service
