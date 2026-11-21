-- Band-gated OPTIONAL/IDLE Tasking provider unifying ambient facility seats, roaming seats, and roam ambience.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AutonomyTaskProvider = PNC.AutonomyTaskProvider or {}

local Provider = PNC.AutonomyTaskProvider
local Scorer = PNC.AutonomyScorer or require "PNC/Tasking/Autonomy/PNC_AutonomyScorer"
local CoPresence = PNC.CoPresenceService
    or require "PNC/Tasking/Autonomy/PNC_CoPresenceService"

Provider.DOMAIN = "autonomy"
Provider.DEFAULT_CLAIM_TTL_MS = 30000
Provider.CLAIM_RENEW_INTERVAL_MS = 10000
Provider.RegistryByLease = Provider.RegistryByLease or {}

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    return PNC.Core and type(PNC.Core.Now) == "function" and PNC.Core.Now() or 0
end

local function liveZombie(npcId)
    if PNC.Registry and type(PNC.Registry.GetLiveZombie) == "function" then
        return PNC.Registry.GetLiveZombie(npcId)
    end
    return nil
end

local function resolveRecord(npcId)
    if PNC.Registry and type(PNC.Registry.Get) == "function" then
        return PNC.Registry.Get(npcId)
    end
    return nil
end

local function buildContextMap(record, at)
    local contexts = {}
    local live = liveZombie(record.id)
    local ambient = PNC.AmbientFacilityService or PNC.LivingRoomService
    local roamingSeat = PNC.RoamingSeat
    local roamAmbient = PNC.RoamAmbient

    if ambient and type(ambient.IsEligible) == "function"
        and type(ambient.PreviewSeat) == "function"
    then
        local allowed, camp, base = ambient.IsEligible(record, at, {
            allowActiveAutonomyLease = true,
            ignoreCadence = true,
        })
        if allowed then
            local preview = ambient.PreviewSeat(record, live, camp, base)
            if preview then
                local ctx = {
                    kind = "facility_seat",
                    camp = camp,
                    base = base,
                    preview = preview,
                    x = tonumber(preview.x) or record.x,
                    y = tonumber(preview.y) or record.y,
                    claimKey = "facility_seat:"
                        .. tostring(preview.facilityId or (base and base.id) or "ambient")
                        .. ":" .. tostring(preview.resourceKey or record.id),
                    situationId = camp and "situation.camp_chat" or "situation.lounge_hangout",
                }
                contexts["ad.social_lounge"] = ctx
                contexts["ad.rest_seat"] = ctx
            end
        end
    end

    if not contexts["ad.rest_seat"] and roamingSeat
        and type(roamingSeat.CanAttempt) == "function"
        and type(roamingSeat.FindCandidate) == "function"
    then
        local roaming = record.runtime and record.runtime.roaming or nil
        if roamingSeat.CanAttempt(record, live, roaming, at) then
            local seat = roamingSeat.FindCandidate(record, live)
            if seat and seat.resource and seat.target then
                contexts["ad.rest_seat"] = {
                    kind = "roaming_seat",
                    ownerKind = "roam",
                    candidate = seat,
                    x = tonumber(seat.target.x) or record.x,
                    y = tonumber(seat.target.y) or record.y,
                    claimKey = "roaming_seat:" .. tostring(seat.resource.resourceKey or record.id),
                    situationId = "situation.camp_chat",
                }
            end
        elseif type(roamingSeat.CanAttemptGuard) == "function"
            and roamingSeat.CanAttemptGuard(record, live, record.orderSpec, at)
        then
            local seat = roamingSeat.FindCandidate(record, live)
            if seat and seat.resource and seat.target then
                contexts["ad.rest_seat"] = {
                    kind = "roaming_seat",
                    ownerKind = "guard",
                    candidate = seat,
                    x = tonumber(seat.target.x) or record.x,
                    y = tonumber(seat.target.y) or record.y,
                    claimKey = "roaming_seat:" .. tostring(seat.resource.resourceKey or record.id),
                    situationId = "situation.camp_chat",
                }
            end
        end
    end

    if roamAmbient and type(roamAmbient.CanAttempt) == "function"
        and type(roamAmbient.GetActionPlan) == "function"
    then
        local orderKind = tostring(record.orderSpec and record.orderSpec.kind or "")
        local roaming = record.runtime and record.runtime.roaming or nil
        local eligibleAmbient = false
        if roaming and roamAmbient.CanAttempt(record, live, roaming, at) then
            eligibleAmbient = true
        elseif orderKind == "camp" and record.orderSpec and record.orderSpec.ambientVisit == true then
            eligibleAmbient = PNC.AmbientVisitService
                and PNC.AmbientVisitService.CanUseAmbient
                and PNC.AmbientVisitService.CanUseAmbient(record) == true
        end
        if eligibleAmbient then
            local hours = roamAmbient.GetWorldAgeHours and roamAmbient.GetWorldAgeHours() or 0
            local plan = roamAmbient.GetActionPlan(record, hours)
            if plan then
                local sleepCandidate = nil
                if plan.action == "sleep" and roamAmbient.FindSleepSurface then
                    sleepCandidate = roamAmbient.FindSleepSurface(live)
                end
                if plan.action ~= "sleep" or sleepCandidate then
                    contexts["ad.roam_patrol"] = {
                        kind = "roam_ambient",
                        plan = plan,
                        sleepCandidate = sleepCandidate,
                        x = sleepCandidate and sleepCandidate.target and sleepCandidate.target.x or record.x,
                        y = sleepCandidate and sleepCandidate.target and sleepCandidate.target.y or record.y,
                        claimKey = sleepCandidate and sleepCandidate.resource
                            and ("ambient_sleep:" .. tostring(sleepCandidate.resource.resourceKey))
                            or ("autonomy:ambient:" .. tostring(record.id)),
                        situationId = "situation.camp_chat",
                    }
                end
            end
        end
    end

    return contexts
end

local function makeCandidate(record, entry)
    local ad = entry.ad
    local ctx = entry.context
    local band = entry.band == "OPTIONAL" and "OPTIONAL" or "IDLE"
    local urgency = tonumber(entry.urgency) or 0
    if PNC.ScenarioScheduler
        and type(PNC.ScenarioScheduler.GetScenarioBoostForAd) == "function"
    then
        local boost = PNC.ScenarioScheduler.GetScenarioBoostForAd(record, ad.id)
        if tonumber(boost) and boost > 0 then
            urgency = math.min(1.0, urgency + boost)
        end
    end
    return {
        taskId = "autonomy:" .. tostring(ad.id) .. ":" .. tostring(record.id),
        npcId = tostring(record.id),
        kind = ctx and ctx.kind or tostring(ad.capability or "autonomy"),
        operation = tostring(ad.id),
        sourceDomain = Provider.DOMAIN,
        sourceRef = tostring(ad.id),
        precedence = band,
        urgency = urgency,
        capability = tostring(ad.capability or "facility.idle"),
        interruptPolicy = "NORMAL",
        adId = tostring(ad.id),
        autonomyContext = ctx,
        claimKey = ctx and ctx.claimKey or ("autonomy:" .. tostring(ad.id) .. ":" .. tostring(record.id)),
    }
end

function Provider.GetCandidates(npcId, options)
    local record = resolveRecord(npcId)
    if not record or record.alive == false then return {} end
    if record.runtime and (record.runtime.workOrderId or record.runtime.medicalCare or record.runtime.treatment) then
        return {}
    end
    local at = nowMs(type(options) == "table" and options.at or nil)
    local contexts = buildContextMap(record, at)
    local hasAny = false
    for _ in pairs(contexts) do
        hasAny = true
        break
    end
    if not hasAny then
        return {}
    end

    local scored = Scorer.EvaluateAll(record, function(adSpec)
        local ctx = contexts[adSpec.id]
        if not ctx then return false end
        return ctx
    end, at, options)

    local candidates = {}
    for i = 1, #scored do
        candidates[#candidates + 1] = makeCandidate(record, scored[i])
    end
    return candidates
end

function Provider.Validate(intent)
    if type(intent) ~= "table" or not intent.npcId then return false end
    local record = resolveRecord(intent.npcId)
    if not record or record.alive == false then return false end
    local candidates = Provider.GetCandidates(intent.npcId)
    for i = 1, #candidates do
        if candidates[i].taskId == intent.taskId then
            return true
        end
    end
    return false
end

function Provider.Assign(intent)
    local record = resolveRecord(intent.npcId)
    if not record or record.alive == false then
        return nil, "NPC_UNAVAILABLE"
    end
    local at = nowMs()
    local adId = tostring(intent.adId or intent.sourceRef or "")
    local ctx = intent.autonomyContext
    if not ctx then
        local contexts = buildContextMap(record, at)
        ctx = contexts[adId]
    end
    if not ctx then
        Scorer.RecordFailure(intent.npcId, adId, "CONTEXT_EXPIRED", at)
        return nil, "AUTONOMY_CONTEXT_UNAVAILABLE"
    end

    local claims = PNC.Tasking and PNC.Tasking.Claims or nil
    local live = liveZombie(intent.npcId)
    local acquired = nil
    local ambient = PNC.AmbientFacilityService or PNC.LivingRoomService
    local claimKey = tostring(ctx.claimKey or intent.claimKey or ("autonomy:" .. adId .. ":" .. tostring(intent.npcId)))

    if ctx.kind == "facility_seat" then
        if not ambient or type(ambient.AcquireSeat) ~= "function" then
            Scorer.RecordFailure(intent.npcId, adId, "SEAT_SERVICE_UNAVAILABLE", at)
            return nil, "SEAT_SERVICE_UNAVAILABLE"
        end
        acquired = ambient.AcquireSeat(record, live, ctx.camp, ctx.base)
        if not acquired or not acquired.target then
            Scorer.RecordFailure(intent.npcId, adId, "SEAT_UNAVAILABLE", at)
            return nil, "SEAT_UNAVAILABLE"
        end
        claimKey = "facility_seat:"
            .. tostring(acquired.facilityId or (ctx.base and ctx.base.id) or "ambient")
            .. ":" .. tostring(acquired.resourceKey or acquired.id or record.id)
    end

    local claimKeys = nil
    if claims and type(claims.Acquire) == "function" then
        local claimed, claimOrReason = claims.Acquire(claimKey, intent.npcId, {
            domain = Provider.DOMAIN,
            ttlMs = Provider.DEFAULT_CLAIM_TTL_MS,
            at = at,
            metadata = { adId = adId, kind = ctx.kind },
        })
        if not claimed then
            if acquired and acquired.reservationId and PNC.FacilityReservations
                and type(PNC.FacilityReservations.Release) == "function"
            then
                PNC.FacilityReservations.Release(acquired.reservationId, "autonomy_claim_conflict")
            end
            Scorer.RecordFailure(intent.npcId, adId, claimOrReason, at)
            return nil, tostring(claimOrReason or "AUTONOMY_CLAIM_CONFLICT")
        end
        claimKeys = { claimKey }
    end

    local ok = false
    local startReason = nil
    if ctx.kind == "facility_seat" then
        if ambient and type(ambient.StartSeat) == "function" then
            ok, startReason = ambient.StartSeat(record, acquired, ctx.camp, live)
        end
    elseif ctx.kind == "roaming_seat" then
        local roamingSeat = PNC.RoamingSeat
        if roamingSeat and type(roamingSeat.StartCandidate) == "function" then
            ok, startReason = roamingSeat.StartCandidate(record, live, ctx.candidate, at, ctx.ownerKind or "roam")
        elseif roamingSeat and ctx.ownerKind == "guard" and roamingSeat.TryStartGuard then
            ok = roamingSeat.TryStartGuard(record, live, record.orderSpec, at) == true
        elseif roamingSeat and roamingSeat.TryStart then
            ok = roamingSeat.TryStart(record, live, record.orderSpec, record.runtime and record.runtime.roaming, at) == true
        end
    elseif ctx.kind == "roam_ambient" then
        local roamAmbient = PNC.RoamAmbient
        if roamAmbient then
            local plan = ctx.plan
            if plan and plan.action == "sleep" and roamAmbient.StartSleep and ctx.sleepCandidate then
                ok, startReason = roamAmbient.StartSleep(record, live, plan, ctx.sleepCandidate, at)
            elseif plan and roamAmbient.StartInstantAction then
                ok, startReason = roamAmbient.StartInstantAction(record, live, plan, at)
            end
        end
    end

    if not ok then
        if claimKeys and claims and type(claims.Release) == "function" then
            claims.Release(claimKey, intent.npcId, "autonomy_start_failed")
        end
        if acquired and acquired.reservationId and PNC.FacilityReservations
            and type(PNC.FacilityReservations.Release) == "function"
        then
            PNC.FacilityReservations.Release(acquired.reservationId, "autonomy_start_failed")
        end
        Scorer.RecordFailure(intent.npcId, adId, startReason or "AUTONOMY_START_FAILED", at)
        return nil, tostring(startReason or "AUTONOMY_START_FAILED")
    end

    local reservationId = acquired and acquired.reservationId or nil
    if not reservationId and ctx.kind == "roaming_seat" and record.runtime and record.runtime.roamingSeat then
        reservationId = record.runtime.roamingSeat.reservationId
    elseif not reservationId and ctx.kind == "roam_ambient" and record.runtime and record.runtime.roamAmbient then
        reservationId = record.runtime.roamAmbient.reservationId
    elseif not reservationId and ctx.kind == "facility_seat" and record.runtime and record.runtime.facilityActivity then
        reservationId = record.runtime.facilityActivity.reservationId
    end

    return {
        adId = adId,
        kind = ctx.kind,
        claimKey = claimKey,
        claimKeys = claimKeys,
        claimOwnerId = tostring(intent.npcId),
        reservationId = reservationId,
        situationId = ctx.situationId,
        capability = intent.capability,
        executionMode = live and "LIVE" or "ABSTRACT",
    }
end

function Provider.Start(lease, assignment)
    if type(lease) ~= "table" then return false, "LEASE_REQUIRED" end
    local record = resolveRecord(lease.npcId)
    if not record then return false, "NPC_UNAVAILABLE" end
    local at = nowMs()
    record.runtime = type(record.runtime) == "table" and record.runtime or {}
    local adId = assignment and assignment.adId or lease.sourceRef
    local kind = assignment and assignment.kind or nil
    record.runtime.autonomyAdId = adId
    record.runtime.autonomyKind = kind
    record.runtime.taskLeaseId = lease.leaseId
    if kind == "facility_seat" and type(record.runtime.facilityActivity) == "table" then
        record.runtime.facilityActivity.taskLeaseId = lease.leaseId
    elseif kind == "roaming_seat" and type(record.runtime.roamingSeat) == "table" then
        record.runtime.roamingSeat.taskLeaseId = lease.leaseId
    elseif kind == "roam_ambient" and type(record.runtime.roamAmbient) == "table" then
        record.runtime.roamAmbient.taskLeaseId = lease.leaseId
    end
    Provider.RegistryByLease[lease.leaseId] = {
        adId = adId,
        kind = kind,
        claimKey = assignment and assignment.claimKey or nil,
        nextClaimRenewAt = at + Provider.CLAIM_RENEW_INTERVAL_MS,
    }
    CoPresence.TryTriggerForNPC(record, at, {
        adId = adId,
        situationId = assignment and assignment.situationId or nil,
    })
    return true
end

function Provider.CanContinue(lease)
    if type(lease) ~= "table" then return false, "LEASE_REQUIRED" end
    local record = resolveRecord(lease.npcId)
    if not record or record.alive == false then return false, "NPC_UNAVAILABLE" end
    local meta = Provider.RegistryByLease[lease.leaseId]
    local runtime = type(record.runtime) == "table" and record.runtime or {}
    local kind = meta and meta.kind or runtime.autonomyKind
    if kind == "facility_seat" then
        return runtime.facilityActivity ~= nil, runtime.facilityActivity == nil and "FACILITY_ACTIVITY_ENDED" or nil
    elseif kind == "roaming_seat" then
        return runtime.roamingSeat ~= nil, runtime.roamingSeat == nil and "ROAMING_SEAT_ENDED" or nil
    elseif kind == "roam_ambient" then
        return runtime.roamAmbient ~= nil, runtime.roamAmbient == nil and "ROAM_AMBIENT_ENDED" or nil
    end
    return false, "AUTONOMY_STATE_MISSING"
end

function Provider.Tick(lease)
    if type(lease) ~= "table" then return false, "LEASE_REQUIRED" end
    local record = resolveRecord(lease.npcId)
    if not record or record.alive == false then
        return PNC.Tasking.Commands.Complete(lease.leaseId, "NPC_UNAVAILABLE")
    end
    local at = nowMs()
    local meta = Provider.RegistryByLease[lease.leaseId]
    local claims = PNC.Tasking and PNC.Tasking.Claims or nil
    if meta and meta.claimKey and claims and type(claims.Renew) == "function"
        and at >= (tonumber(meta.nextClaimRenewAt) or 0)
    then
        claims.Renew(meta.claimKey, lease.npcId, Provider.DEFAULT_CLAIM_TTL_MS, at)
        meta.nextClaimRenewAt = at + Provider.CLAIM_RENEW_INTERVAL_MS
    end
    local runtime = type(record.runtime) == "table" and record.runtime or {}
    local kind = meta and meta.kind or runtime.autonomyKind
    local live = liveZombie(lease.npcId)

    if kind == "facility_seat" then
        if not runtime.facilityActivity then
            return PNC.Tasking.Commands.Complete(lease.leaseId, "AUTONOMY_FACILITY_COMPLETE")
        end
        if PNC.FacilityJobs and type(PNC.FacilityJobs.TickRecord) == "function" then
            PNC.FacilityJobs.TickRecord(record, live, at)
        end
        if not runtime.facilityActivity then
            return PNC.Tasking.Commands.Complete(lease.leaseId, "AUTONOMY_FACILITY_COMPLETE")
        end
        lease.lastProgressAt = at
        return true
    elseif kind == "roaming_seat" then
        if not runtime.roamingSeat then
            return PNC.Tasking.Commands.Complete(lease.leaseId, "AUTONOMY_SEAT_COMPLETE")
        end
        if PNC.RoamingSeat and type(PNC.RoamingSeat.Tick) == "function" then
            PNC.RoamingSeat.Tick(record, live, at)
        end
        if not runtime.roamingSeat then
            return PNC.Tasking.Commands.Complete(lease.leaseId, "AUTONOMY_SEAT_COMPLETE")
        end
        lease.lastProgressAt = at
        return true
    elseif kind == "roam_ambient" then
        if not runtime.roamAmbient then
            return PNC.Tasking.Commands.Complete(lease.leaseId, "AUTONOMY_AMBIENT_COMPLETE")
        end
        if PNC.RoamAmbient and type(PNC.RoamAmbient.Tick) == "function" then
            PNC.RoamAmbient.Tick(record, live, at)
        end
        if not runtime.roamAmbient then
            return PNC.Tasking.Commands.Complete(lease.leaseId, "AUTONOMY_AMBIENT_COMPLETE")
        end
        lease.lastProgressAt = at
        return true
    end

    return PNC.Tasking.Commands.Complete(lease.leaseId, "AUTONOMY_STATE_MISSING")
end

local function cleanupLeaseState(lease, reason, isAbort)
    if type(lease) ~= "table" then return true end
    local record = resolveRecord(lease.npcId)
    local meta = Provider.RegistryByLease[lease.leaseId]
    Provider.RegistryByLease[lease.leaseId] = nil
    local claims = PNC.Tasking and PNC.Tasking.Claims or nil
    if claims and type(claims.ReleaseByLease) == "function" then
        claims.ReleaseByLease(lease.leaseId, reason or "autonomy_lease_released")
    end
    if record and record.runtime then
        local runtime = record.runtime
        local live = liveZombie(lease.npcId)
        local kind = meta and meta.kind or runtime.autonomyKind
        local adId = meta and meta.adId or runtime.autonomyAdId or lease.sourceRef
        if kind == "facility_seat" and runtime.facilityActivity then
            local ambient = PNC.AmbientFacilityService or PNC.LivingRoomService
            if ambient and type(ambient.StopSeat) == "function" then
                ambient.StopSeat(record, reason or "autonomy_cancelled")
            elseif PNC.FacilityJobs and type(PNC.FacilityJobs.Stop) == "function" then
                PNC.FacilityJobs.Stop(record, reason or "autonomy_cancelled")
            end
        elseif kind == "roaming_seat" and runtime.roamingSeat then
            if PNC.RoamingSeat and type(PNC.RoamingSeat.Stop) == "function" then
                PNC.RoamingSeat.Stop(record, live, reason or "autonomy_cancelled")
            end
        elseif kind == "roam_ambient" and runtime.roamAmbient then
            if PNC.RoamAmbient and type(PNC.RoamAmbient.Stop) == "function" then
                PNC.RoamAmbient.Stop(record, live, reason or "autonomy_cancelled", "task_preempted")
            end
        end
        if runtime.taskLeaseId == lease.leaseId then
            runtime.taskLeaseId = nil
        end
        runtime.autonomyAdId = nil
        runtime.autonomyKind = nil
        if isAbort and adId then
            Scorer.RecordFailure(lease.npcId, adId, reason or "autonomy_aborted", nowMs())
        end
    end
    return true
end

function Provider.Cancel(lease, reason)
    return cleanupLeaseState(lease, reason, true)
end

function Provider.Complete(lease, reason)
    return cleanupLeaseState(lease, reason, false)
end

function Provider.RollbackAssignment(intent, assignment, reason)
    local record = intent and resolveRecord(intent.npcId) or nil
    local live = intent and liveZombie(intent.npcId) or nil
    local kind = assignment and assignment.kind or nil
    if record and record.runtime then
        if kind == "facility_seat" and record.runtime.facilityActivity then
            local ambient = PNC.AmbientFacilityService or PNC.LivingRoomService
            if ambient and type(ambient.StopSeat) == "function" then
                ambient.StopSeat(record, reason or "autonomy_rollback")
            end
        elseif kind == "roaming_seat" and record.runtime.roamingSeat
            and PNC.RoamingSeat and PNC.RoamingSeat.Stop
        then
            PNC.RoamingSeat.Stop(record, live, reason or "autonomy_rollback")
        elseif kind == "roam_ambient" and record.runtime.roamAmbient
            and PNC.RoamAmbient and PNC.RoamAmbient.Stop
        then
            PNC.RoamAmbient.Stop(record, live, reason or "autonomy_rollback", "rollback")
        end
    end
    if intent and intent.npcId and (intent.adId or intent.sourceRef) then
        Scorer.RecordFailure(intent.npcId, intent.adId or intent.sourceRef, reason or "autonomy_rollback", nowMs())
    end
    return true
end

function Provider.GetRecoveryState(lease)
    if type(lease) ~= "table" then return { terminal = true } end
    local record = resolveRecord(lease.npcId)
    if not record or record.alive == false then return { terminal = true } end
    local ok = Provider.CanContinue(lease)
    if not ok then return { terminal = true } end
    return {
        lastProgressAt = tonumber(lease.lastProgressAt) or nowMs(),
        phase = tostring(lease.phase or "WORKING"),
    }
end

function Provider.GetDiagnostics(npcId)
    local record = resolveRecord(npcId)
    if not record then
        return { unavailable = "NPC_NOT_FOUND" }
    end
    local at = nowMs()
    local contexts = buildContextMap(record, at)
    local scored, rejected = Scorer.EvaluateAll(record, function(adSpec)
        local ctx = contexts[adSpec.id]
        if not ctx then return false end
        return ctx
    end, at, { includeDiagnostics = true })

    local top = {}
    for i = 1, math.min(6, #scored) do
        local item = scored[i]
        local d = item.diagnostics or {}
        top[#top + 1] = {
            adId = item.adId,
            band = item.band,
            score = item.urgency,
            rawNeed = d.rawNeed,
            baseCurve = d.baseCurve,
            traitDelta = d.traitDelta,
            moodDelta = d.moodDelta,
            distancePenalty = d.distancePenalty,
            traits = d.traits,
            moods = d.moods,
            kind = item.context and item.context.kind or nil,
        }
    end
    return {
        activeAdId = record.runtime and record.runtime.autonomyAdId or nil,
        candidates = top,
        rejections = rejected or {},
        coPresence = CoPresence.GetDiagnostics(npcId),
        hydrated = record.runtime and record.runtime.autonomyHydration or nil,
    }
end

if PNC.Tasking and PNC.Tasking.Commands
    and type(PNC.Tasking.Commands.RegisterProvider) == "function"
then
    PNC.Tasking.Commands.RegisterProvider(Provider.DOMAIN, Provider)
end

return Provider
