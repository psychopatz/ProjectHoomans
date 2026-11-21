-- Server-authoritative witness-bounded PsychopatzSocial memory & hearsay propagation.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialWitness = PNC.SocialWitness or {}

local Service = PNC.SocialWitness

Service.VERSION = 1
Service.DEFAULT_VISION_RADIUS = 14
Service.DEFAULT_HEARING_RADIUS = 10
Service.MAX_WITNESSES = 16
Service.MAX_HEARSAY_HOPS = 2
Service.HEARSAY_STRENGTH_DECAY = 0.5
Service.MAX_HEARSAY_PER_EXCHANGE = 1

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return fallback
    end
    return value
end

local function worldAgeHours(explicit)
    local v = finite(explicit, nil)
    if v ~= nil then return math.max(0, v) end
    if getGameTime and getGameTime() and getGameTime().getWorldAgeHours then
        return math.max(0, finite(getGameTime():getWorldAgeHours(), 0))
    end
    return 0
end

local function resolveCoreSocial()
    if PsychopatzCore and PsychopatzCore.Actors and PsychopatzCore.Actors.Social then
        return PsychopatzCore.Actors.Social
    end
    if PsychopatzCore and PsychopatzCore.Social then
        return PsychopatzCore.Social
    end
    if PsychopatzCore and type(PsychopatzCore.Require) == "function" then
        local ok, facade = PsychopatzCore.Require("core.social", "PNC_SocialWitnessService")
        if ok and type(facade) == "table" then
            return facade
        end
    end
    if type(require) == "function" then
        return require "PsychopatzCore/Actors/PsychopatzSocial"
    end
    return nil
end

local function toTargetKey(idOrKey, isPlayer)
    local raw = tostring(idOrKey or "")
    if raw == "" then return nil end
    local prefix = string.match(raw, "^([%w_]+):")
    if prefix == "npc" or prefix == "actor" or prefix == "player" or prefix == "steam" then
        return raw
    end
    if PNC.EntityRef and isPlayer ~= true and type(PNC.EntityRef.ForNPC) == "function" then
        local formatted = PNC.EntityRef.ForNPC(raw)
        if type(formatted) == "string" and formatted ~= "" then
            return formatted
        end
    end
    return (isPlayer == true and "player:" or "npc:") .. raw
end

local function ensureSocialState(record, Social)
    if type(record) ~= "table" or not Social then return nil end
    if PNC.Persistence and PNC.Persistence.CoreSocial
        and type(PNC.Persistence.CoreSocial.EnsureRuntimeView) == "function"
    then
        PNC.Persistence.CoreSocial.EnsureRuntimeView(record, PsychopatzCore)
    end
    if type(record.social) ~= "table" or type(record.social.memoryBank) ~= "table" then
        record.social = Social.NewState(record.social)
    end
    return record.social
end

local function commitSocialState(record, nextState)
    if type(record) ~= "table" or type(nextState) ~= "table" then return end
    record.social = nextState
    if PNC.Persistence and PNC.Persistence.CoreSocial
        and type(PNC.Persistence.CoreSocial.SyncToCore) == "function"
    then
        PNC.Persistence.CoreSocial.SyncToCore(record, PsychopatzCore, {
            source = "witness_service",
        })
    end
end

local function hasRecordedBaseEvent(socialState, baseEventId)
    if type(socialState) ~= "table" or type(baseEventId) ~= "string" or baseEventId == "" then
        return false
    end
    local bank = socialState.memoryBank or {}
    for i = 1, #bank do
        local mem = bank[i]
        if type(mem) == "table" then
            local tags = type(mem.tags) == "table" and mem.tags or nil
            if tags and tostring(tags.baseEventId or "") == baseEventId then
                return true
            end
            if tostring(mem.id or "") == baseEventId then
                return true
            end
        end
    end
    return false
end

---Determines whether observerRecord could witness an event at (eventX, eventY, eventZ).
function Service.CanWitness(observerRecord, eventX, eventY, eventZ, opts)
    opts = type(opts) == "table" and opts or {}
    if type(observerRecord) ~= "table" or observerRecord.alive == false then
        return false, "OBSERVER_UNAVAILABLE"
    end
    local observerId = tostring(observerRecord.id or "")
    if observerId == "" then
        return false, "OBSERVER_ID_MISSING"
    end
    if type(opts.directParticipants) == "table" and opts.directParticipants[observerId] == true then
        return true, "DIRECT_PARTICIPANT"
    end

    local ox = tonumber(observerRecord.x)
    local oy = tonumber(observerRecord.y)
    local oz = tonumber(observerRecord.z) or 0
    local ex = tonumber(eventX)
    local ey = tonumber(eventY)
    local ez = tonumber(eventZ) or 0
    if not ox or not oy or not ex or not ey then
        return false, "COORDINATES_MISSING"
    end
    if math.abs(oz - ez) >= 1 then
        return false, "DIFFERENT_FLOOR"
    end

    local visionR = math.max(1, tonumber(opts.visionRadius) or Service.DEFAULT_VISION_RADIUS)
    local hearingR = math.max(0, tonumber(opts.hearingRadius) or Service.DEFAULT_HEARING_RADIUS)
    local maxR = math.max(visionR, hearingR)
    local dx = ox - ex
    local dy = oy - ey
    local d2 = dx * dx + dy * dy
    if d2 > maxR * maxR then
        return false, "OUT_OF_RANGE"
    end

    if hearingR > 0 and d2 <= hearingR * hearingR and opts.audible ~= false then
        if type(opts.hearingCheck) == "function" then
            if opts.hearingCheck(observerRecord, ex, ey, ez) then
                return true, "HEARD"
            end
        elseif opts.hearingBlocked ~= true then
            return true, "HEARD"
        end
    end

    if d2 <= visionR * visionR then
        if type(opts.losCheck) == "function" then
            if opts.losCheck(observerRecord, ex, ey, ez) == true then
                return true, "SEEN"
            end
            return false, "LOS_BLOCKED"
        end
        local body = PNC.Registry and type(PNC.Registry.GetLiveZombie) == "function"
            and PNC.Registry.GetLiveZombie(observerId) or nil
        if body and type(body.CanSee) == "function" and opts.targetBody ~= nil then
            if body:CanSee(opts.targetBody) == true then
                return true, "SEEN"
            end
            return false, "LOS_BLOCKED"
        end
        if PNC.PerceptionService and type(PNC.PerceptionService.CanDetectTarget) == "function"
            and opts.targetRecord ~= nil
        then
            local seen = PNC.PerceptionService.CanDetectTarget(
                observerRecord, opts.targetRecord, body, opts.targetBody, opts
            )
            if seen then
                return true, "SEEN"
            end
            return false, "LOS_BLOCKED"
        end
        return true, "SEEN"
    end

    return false, "OUT_OF_VISION"
end

local function resolveCandidates(candidateRecords, x, y, radius)
    if type(candidateRecords) == "table" then
        return candidateRecords
    end
    if PNC.SpatialIndex and type(PNC.SpatialIndex.QueryNPCs) == "function"
        and tonumber(x) ~= nil and tonumber(y) ~= nil
    then
        local near = PNC.SpatialIndex.QueryNPCs(tonumber(x), tonumber(y), radius)
        if type(near) == "table" then
            return near
        end
    end
    local out = {}
    if PNC.Registry and type(PNC.Registry.Data) == "function" == false
        and type(PNC.Registry.Data) == "table"
    then
        for _, rec in pairs(PNC.Registry.Data) do
            if type(rec) == "table" and rec.alive ~= false then
                out[#out + 1] = rec
            end
        end
        table.sort(out, function(a, b)
            return tostring(a.id or "") < tostring(b.id or "")
        end)
    end
    return out
end

---Records a social memory ONLY on NPCs that satisfy CanWitness for the event.
function Service.RecordWitnessedEvent(eventSpec, candidateRecords, opts)
    eventSpec = type(eventSpec) == "table" and eventSpec or {}
    opts = type(opts) == "table" and opts or {}

    local Social = resolveCoreSocial()
    if not Social or type(Social.RecordAuthorizedEvent) ~= "function" then
        return { ok = false, reason = "CORE_SOCIAL_UNAVAILABLE", witnesses = {}, excluded = {}, recordedCount = 0 }
    end

    local eventId = tostring(eventSpec.eventId or eventSpec.id or "")
    if eventId == "" then
        return { ok = false, reason = "EVENT_ID_REQUIRED", witnesses = {}, excluded = {}, recordedCount = 0 }
    end

    local ex = tonumber(eventSpec.x)
    local ey = tonumber(eventSpec.y)
    local ez = tonumber(eventSpec.z) or 0
    local maxR = math.max(
        tonumber(opts.visionRadius) or Service.DEFAULT_VISION_RADIUS,
        tonumber(opts.hearingRadius) or Service.DEFAULT_HEARING_RADIUS
    )
    local list = resolveCandidates(candidateRecords, ex, ey, maxR)
    local aboutKey = toTargetKey(eventSpec.aboutKey or eventSpec.targetId or eventSpec.sourceId,
        eventSpec.aboutIsPlayer == true)
    if not aboutKey then
        return { ok = false, reason = "TARGET_KEY_REQUIRED", witnesses = {}, excluded = {}, recordedCount = 0 }
    end

    local worldAge = worldAgeHours(eventSpec.worldAgeHours or eventSpec.occurredAt)
    local createdAt = tonumber(eventSpec.createdAt) or worldAge
    local eventType = tostring(eventSpec.type or "social.grievance")
    local witnesses = {}
    local excluded = {}
    local seen = {}
    local recordedCount = 0

    local limit = math.min(#list, tonumber(opts.maxWitnesses) or Service.MAX_WITNESSES)
    for i = 1, limit do
        local rec = list[i]
        local obsId = type(rec) == "table" and rec.id ~= nil and tostring(rec.id) or ""
        if obsId ~= "" and not seen[obsId] and toTargetKey(obsId, false) ~= aboutKey then
            seen[obsId] = true
            local can, why = Service.CanWitness(rec, ex, ey, ez, opts)
            if not can then
                excluded[#excluded + 1] = { npcId = obsId, reason = why }
            else
                local socialState = ensureSocialState(rec, Social)
                if hasRecordedBaseEvent(socialState, eventId) then
                    excluded[#excluded + 1] = { npcId = obsId, reason = "ALREADY_RECORDED" }
                else
                    local scale = why == "DIRECT_PARTICIPANT" and 1.0 or 0.75
                    local tags = {}
                    if type(eventSpec.tags) == "table" then
                        for tk, tv in pairs(eventSpec.tags) do
                            tags[tk] = tv
                        end
                    end
                    tags.baseEventId = eventId
                    tags.hopCount = 0
                    tags.source = why == "DIRECT_PARTICIPANT" and "direct_participant" or "direct_witness"
                    if eventSpec.act then
                        tags.act = tostring(eventSpec.act)
                    end
                    if eventSpec.sceneId then
                        tags.sceneId = tostring(eventSpec.sceneId)
                    end

                    local updated, err = Social.RecordAuthorizedEvent(socialState, {
                        authorized = true,
                        authority = "server",
                        eventID = "witness:" .. eventId .. ":" .. obsId,
                        type = eventType,
                        targetKey = aboutKey,
                        worldAgeHours = worldAge,
                        createdAt = createdAt,
                        approvalDelta = (tonumber(eventSpec.approvalDelta) or 0) * scale,
                        respectDelta = (tonumber(eventSpec.respectDelta) or 0) * scale,
                        familiarityDelta = tonumber(eventSpec.familiarityDelta) or 1,
                        retentionClass = eventSpec.retentionClass or "SHORT",
                        shareable = eventSpec.shareable ~= false,
                        knowledgeSource = "witnessed",
                        sourceMode = "witnessed",
                        cooldownHours = 0,
                        consolidate = false,
                        tags = tags,
                    })
                    if updated then
                        commitSocialState(rec, updated)
                        recordedCount = recordedCount + 1
                        witnesses[#witnesses + 1] = {
                            npcId = obsId,
                            mode = why,
                            eventId = "witness:" .. eventId .. ":" .. obsId,
                        }
                    else
                        excluded[#excluded + 1] = { npcId = obsId, reason = tostring(err or "RECORD_FAILED") }
                    end
                end
            end
        end
    end

    return {
        ok = true,
        eventId = eventId,
        recordedCount = recordedCount,
        witnesses = witnesses,
        excluded = excluded,
    }
end

---Propagates at most one attenuated shareable memory from speakerRecord to listenerRecord.
function Service.PropagateHearsay(speakerRecord, listenerRecord, opts)
    opts = type(opts) == "table" and opts or {}
    if type(speakerRecord) ~= "table" or type(listenerRecord) ~= "table"
        or speakerRecord.alive == false or listenerRecord.alive == false
    then
        return { ok = false, propagated = false, reason = "PARTICIPANT_UNAVAILABLE" }
    end
    local speakerId = tostring(speakerRecord.id or "")
    local listenerId = tostring(listenerRecord.id or "")
    if speakerId == "" or listenerId == "" or speakerId == listenerId then
        return { ok = false, propagated = false, reason = "PARTICIPANT_INVALID" }
    end

    local Social = resolveCoreSocial()
    if not Social or type(Social.RecordAuthorizedEvent) ~= "function" then
        return { ok = false, propagated = false, reason = "CORE_SOCIAL_UNAVAILABLE" }
    end

    local speakerSocial = ensureSocialState(speakerRecord, Social)
    local listenerSocial = ensureSocialState(listenerRecord, Social)
    local listenerKey = toTargetKey(listenerId, false)
    local speakerKey = toTargetKey(speakerId, false)
    local maxHops = math.max(1, tonumber(opts.maxHops) or Service.MAX_HEARSAY_HOPS)
    local decay = tonumber(opts.strengthDecay) or Service.HEARSAY_STRENGTH_DECAY
    local worldAge = worldAgeHours(opts.worldAgeHours or opts.at)

    local bank = speakerSocial.memoryBank or {}
    local selected = nil
    local selectedScore = -math.huge
    for i = #bank, 1, -1 do
        local mem = bank[i]
        if type(mem) == "table" and mem.shareable == true and mem.aboutKey and mem.aboutKey ~= listenerKey then
            local tags = type(mem.tags) == "table" and mem.tags or {}
            local hop = tonumber(tags.hopCount) or (mem.sourceMode == "hearsay" and 1 or 0)
            local baseId = tostring(tags.baseEventId or mem.id or "")
            if hop < maxHops and baseId ~= "" and not hasRecordedBaseEvent(listenerSocial, baseId) then
                local salienceScore = (tonumber(mem.salience) or 100) + (tonumber(mem.createdAt) or 0) * 0.01 - hop * 10
                if salienceScore > selectedScore then
                    selected = mem
                    selectedScore = salienceScore
                end
            end
        end
    end

    if not selected then
        return { ok = true, propagated = false, reason = "NO_ELIGIBLE_SHAREABLE_MEMORY" }
    end

    local srcTags = type(selected.tags) == "table" and selected.tags or {}
    local baseId = tostring(srcTags.baseEventId or selected.id or "")
    local nextHop = (tonumber(srcTags.hopCount) or (selected.sourceMode == "hearsay" and 1 or 0)) + 1
    local newTags = {}
    for tk, tv in pairs(srcTags) do
        newTags[tk] = tv
    end
    newTags.baseEventId = baseId
    newTags.hopCount = nextHop
    newTags.source = "hearsay"
    newTags.heardFrom = speakerId

    local hearsayEventId = "hearsay:" .. baseId .. ":" .. listenerId .. ":h" .. tostring(nextHop)
    local updated, err = Social.RecordAuthorizedEvent(listenerSocial, {
        authorized = true,
        authority = "server",
        eventID = hearsayEventId,
        type = "social.hearsay_report",
        targetKey = selected.aboutKey,
        sourceKey = speakerKey,
        worldAgeHours = worldAge,
        createdAt = worldAge,
        approvalDelta = (tonumber(selected.approvalEffect) or 0) * decay,
        respectDelta = (tonumber(selected.respectEffect) or 0) * decay,
        familiarityDelta = 0.5,
        retentionClass = "SHORT",
        shareable = nextHop < maxHops,
        knowledgeSource = "told_by_trusted_person",
        sourceMode = "hearsay",
        strength = (tonumber(selected.strength) or 1.0) * decay,
        cooldownHours = 0,
        consolidate = false,
        tags = newTags,
    })
    if not updated then
        return { ok = false, propagated = false, reason = tostring(err or "HEARSAY_RECORD_FAILED") }
    end

    commitSocialState(listenerRecord, updated)
    return {
        ok = true,
        propagated = true,
        memoryId = hearsayEventId,
        baseEventId = baseId,
        aboutKey = selected.aboutKey,
        hopCount = nextHop,
    }
end

return Service
