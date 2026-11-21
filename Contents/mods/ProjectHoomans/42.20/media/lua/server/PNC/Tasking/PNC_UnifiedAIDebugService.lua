-- Server-authoritative Unified AI Debug Lab snapshot & interactive trigger service.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.UnifiedAIDebugService = PNC.UnifiedAIDebugService or {}

local Service = PNC.UnifiedAIDebugService
Service.MAX_LISTED_NPCS = 48

local function nowMs()
    return PNC.Core and type(PNC.Core.Now) == "function" and PNC.Core.Now() or 0
end

local function resolveShockBus()
    if PsychopatzCore and PsychopatzCore.ShockingEventBus then
        return PsychopatzCore.ShockingEventBus
    end
    if PsychopatzCore and type(PsychopatzCore.Require) == "function" then
        local ok, facade = PsychopatzCore.Require("core.shocking_events", "PNC_UnifiedAIDebugService")
        if ok and type(facade) == "table" then
            return facade
        end
    end
    return nil
end

local function collectLiveNPCs(player)
    local out = {}
    local registry = PNC.Registry
    if not registry or type(registry.Data) ~= "table" then
        return out
    end
    local px = player and player.getX and tonumber(player:getX()) or nil
    local py = player and player.getY and tonumber(player:getY()) or nil
    for id, rec in pairs(registry.Data) do
        if type(rec) == "table"
            and rec.alive ~= false
            and (rec.presenceState == nil or rec.presenceState == (PNC.Const and PNC.Const.PRESENCE_LIVE or "live"))
        then
            local distSq = math.huge
            if px and py and rec.x ~= nil and rec.y ~= nil then
                local dx = tonumber(rec.x) - px
                local dy = tonumber(rec.y) - py
                distSq = dx * dx + dy * dy
            end
            out[#out + 1] = {
                record = rec,
                id = tostring(rec.id or id),
                distSq = distSq,
            }
        end
    end
    table.sort(out, function(a, b)
        if a.distSq ~= b.distSq then return a.distSq < b.distSq end
        return a.id < b.id
    end)
    return out
end

local function findNearbyNPCs(targetRecord, radius)
    local out = {}
    if type(targetRecord) ~= "table" or targetRecord.x == nil or targetRecord.y == nil then
        return out
    end
    if PNC.SpatialIndex and type(PNC.SpatialIndex.QueryNPCs) == "function" then
        local near = PNC.SpatialIndex.QueryNPCs(tonumber(targetRecord.x), tonumber(targetRecord.y), radius or 16)
        if type(near) == "table" then
            return near
        end
    end
    return out
end

local function buildSelectedDetail(record, now)
    if type(record) ~= "table" or record.id == nil then
        return nil
    end
    local npcId = tostring(record.id)
    local runtime = type(record.runtime) == "table" and record.runtime or {}
    local brain = PNC.Tasking and PNC.Tasking.Queries
        and type(PNC.Tasking.Queries.BuildBrain) == "function"
        and PNC.Tasking.Queries.BuildBrain(npcId, { includeAutonomyDetails = true })
        or {}

    local pSvc = PNC.PerceptionService
    local profile = pSvc and type(pSvc.GetProfile) == "function" and pSvc.GetProfile(record) or nil
    local halfDeg = profile and pSvc and type(pSvc.GetHalfFovDegrees) == "function"
        and pSvc.GetHalfFovDegrees(profile) or nil
    local clues = pSvc and type(pSvc.GetClues) == "function"
        and pSvc.GetClues(record, now) or {}
    local recentClue = clues[#clues]
    local frame = type(runtime.perceptionFrame) == "table" and runtime.perceptionFrame or nil

    local ag = PNC.AgitationService and type(PNC.AgitationService.GetState) == "function"
        and PNC.AgitationService.GetState(npcId, now) or nil
    local sc = type(runtime.secondaryChannel) == "table" and runtime.secondaryChannel or nil
    local joint = PNC.JointSceneLease and type(PNC.JointSceneLease.GetForNPC) == "function"
        and PNC.JointSceneLease.GetForNPC(npcId) or nil
    local dialogue = PNC.DialogueMicroBeatDirector
        and type(PNC.DialogueMicroBeatDirector.GetActorTelemetry) == "function"
        and PNC.DialogueMicroBeatDirector.GetActorTelemetry(npcId) or nil
    local scorer = PNC.AutonomyScorer
    local rejections = scorer and type(scorer.LastRejections) == "table"
        and scorer.LastRejections[npcId] or nil
    local topRejection = type(rejections) == "table" and rejections[1] or nil
    local memBank = type(record.social) == "table" and type(record.social.memoryBank) == "table"
        and record.social.memoryBank or nil

    return {
        id = npcId,
        name = tostring(record.name or record.fullName or npcId),
        x = record.x and math.floor(tonumber(record.x) * 10 + 0.5) / 10 or nil,
        y = record.y and math.floor(tonumber(record.y) * 10 + 0.5) / 10 or nil,
        z = tonumber(record.z) or 0,
        presenceState = tostring(record.presenceState or "live"),
        activeTaskKind = brain.activeTaskKind,
        activeBand = brain.activeBand,
        activeSourceDomain = brain.activeSourceDomain,
        claimsCount = type(brain.claims) == "table" and #brain.claims or 0,
        perceptionProfileId = profile and profile.id or "default",
        visionRange = profile and tonumber(profile.visionRange) or nil,
        fovDegrees = halfDeg and math.floor(halfDeg * 2 + 0.5) or nil,
        hearingRange = profile and tonumber(profile.hearingRange) or nil,
        clueCount = #clues,
        latestClueKind = recentClue and recentClue.kind or nil,
        coneRejectedCount = frame and tonumber(frame.coneRejectedCount) or 0,
        agitationStage = ag and ag.stage or "calm",
        agitationScore = ag and math.floor((tonumber(ag.score) or 0) + 0.5) or 0,
        lastTrigger = ag and ag.lastTrigger or nil,
        secondaryAlertLevel = sc and sc.alertLevel or "calm",
        secondaryPosture = sc and sc.posture or "relaxed",
        secondaryState = sc and sc.secondaryState or nil,
        lastBarkId = sc and sc.lastBarkId or nil,
        scenarioId = brain.scenarioId,
        autonomyAdId = brain.autonomyAdId,
        autonomyTopRejection = topRejection and (tostring(topRejection.adId) .. ":" .. tostring(topRejection.reason)) or nil,
        jointSceneId = joint and joint.sceneId or nil,
        dialogueSceneId = dialogue and dialogue.sceneId or nil,
        dialogueStage = dialogue and dialogue.stage or nil,
        dialogueBeatId = dialogue and dialogue.beatId or nil,
        dialogueTension = dialogue and dialogue.tension or nil,
        socialMemoryCount = memBank and #memBank or 0,
    }
end

local function listWorkReconcilers()
    local work = PNC.WorkService
    if not work or type(work.ReconcileHandlers) ~= "table" then
        return "none"
    end
    local names = {}
    for op in pairs(work.ReconcileHandlers) do
        names[#names + 1] = tostring(op)
    end
    table.sort(names)
    return #names > 0 and table.concat(names, ", ") or "none"
end

function Service.BuildSnapshot(selectedNpcId, player, statusMessage)
    local now = nowMs()
    local live = collectLiveNPCs(player)
    local npcs = {}
    local selectedRecord = nil
    local targetIdStr = selectedNpcId ~= nil and tostring(selectedNpcId) or ""

    local cap = math.min(Service.MAX_LISTED_NPCS, #live)
    for i = 1, cap do
        local entry = live[i]
        local rec = entry.record
        local ag = PNC.AgitationService and type(PNC.AgitationService.GetState) == "function"
            and PNC.AgitationService.GetState(entry.id, now) or nil
        if targetIdStr == entry.id or (selectedRecord == nil and i == 1) then
            selectedRecord = rec
            targetIdStr = entry.id
        end
        npcs[#npcs + 1] = {
            id = entry.id,
            name = tostring(rec.name or rec.fullName or entry.id),
            orderKind = tostring(rec.orderSpec and rec.orderSpec.kind or rec.activeBehavior or "-"),
            agitationStage = ag and ag.stage or "calm",
            distSq = entry.distSq ~= math.huge and math.floor(entry.distSq + 0.5) or nil,
        }
    end
    if selectedRecord == nil and targetIdStr ~= "" and PNC.Registry and PNC.Registry.Get then
        selectedRecord = PNC.Registry.Get(targetIdStr)
    end

    local pStats = PNC.PerceptionService and type(PNC.PerceptionService.GetStats) == "function"
        and PNC.PerceptionService.GetStats() or {}
    local bus = resolveShockBus()
    local bStats = bus and type(bus.GetStats) == "function" and bus.GetStats() or {}
    local cStats = PNC.Tasking and PNC.Tasking.Claims
        and type(PNC.Tasking.Claims.GetDiagnostics) == "function"
        and PNC.Tasking.Claims.GetDiagnostics() or {}
    local dStats = PNC.DialogueMicroBeatDirector and PNC.DialogueMicroBeatDirector.Stats or {}
    local lStats = PNC.JointSceneLease and PNC.JointSceneLease.Stats or {}

    return {
        serverTime = now,
        selectedId = selectedRecord and tostring(selectedRecord.id) or nil,
        npcs = npcs,
        selected = buildSelectedDetail(selectedRecord, now),
        globals = {
            liveNpcCount = #live,
            perceptionStats = pStats,
            shockBusStats = bStats,
            activeClaims = tonumber(cStats.activeCount) or 0,
            agitationActiveCount = PNC.AgitationService
                and type(PNC.AgitationService.GetActiveCount) == "function"
                and PNC.AgitationService.GetActiveCount() or 0,
            dialogueStats = dStats,
            jointLeaseStats = lStats,
            workReconcilers = listWorkReconcilers(),
        },
        lastActionStatus = statusMessage or Service._lastActionStatus,
    }
end

local function emitDebugShock(target, player, eventType, radius, severity, now)
    local bus = resolveShockBus()
    if not bus or type(bus.Emit) ~= "function" then
        return false, "shock_bus_unavailable"
    end
    local ox = (target and tonumber(target.x))
        or (player and player.getX and tonumber(player:getX())) or 0
    local oy = (target and tonumber(target.y))
        or (player and player.getY and tonumber(player:getY())) or 0
    local oz = (target and tonumber(target.z))
        or (player and player.getZ and tonumber(player:getZ())) or 0
    local _, status = bus.Emit({
        eventType = eventType,
        x = ox + 3,
        y = oy,
        z = oz,
        radius = radius,
        severity = severity,
        sourceId = player and player.getUsername and tostring(player:getUsername()) or "debug_lab",
        targetId = target and tostring(target.id) or nil,
        dedupKey = "debug:" .. eventType .. ":" .. tostring(now),
        at = now,
    })
    if target and target.id and PNC.Tasking and PNC.Tasking.Commands
        and type(PNC.Tasking.Commands.Reevaluate) == "function"
    then
        PNC.Tasking.Commands.Reevaluate(target.id, "debug_shock:" .. eventType)
    end
    return true, "emitted:" .. tostring(status)
end

function Service.PerformAction(player, args)
    args = type(args) == "table" and args or {}
    local action = tostring(args.debugAction or args.unifiedAIAction or "")
    local npcId = args.npcId ~= nil and tostring(args.npcId) or nil
    local target = npcId and PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(npcId) or nil
    local now = nowMs()
    local statusMsg = "ok"

    if action == "emit_gunfire" then
        local _, msg = emitDebugShock(target, player, "shock.gunfire", 26, 90, now)
        statusMsg = "gunfire:" .. tostring(msg)
    elseif action == "emit_explosion" then
        local _, msg = emitDebugShock(target, player, "shock.explosion", 30, 98, now)
        statusMsg = "explosion:" .. tostring(msg)
    elseif action == "emit_weapon_aimed" then
        local _, msg = emitDebugShock(target, player, "shock.weapon_aimed", 16, 82, now)
        statusMsg = "weapon_aimed:" .. tostring(msg)
    elseif action == "emit_suspicious_sound" then
        if target and PNC.PerceptionService and type(PNC.PerceptionService.OnWorldSound) == "function" then
            local n = PNC.PerceptionService.OnWorldSound(
                (tonumber(target.x) or 0) + 4,
                tonumber(target.y) or 0,
                tonumber(target.z) or 0,
                22,
                35,
                "debug_sound"
            )
            statusMsg = "world_sound:listeners=" .. tostring(n)
        else
            local _, msg = emitDebugShock(target, player, "shock.suspicious_sound", 20, 55, now)
            statusMsg = "suspicious_sound:" .. tostring(msg)
        end
    elseif action == "street_greet" or action == "street_antagonize" or action == "street_defuse" then
        if not target then
            statusMsg = "no_npc_selected"
        elseif not PNC.StreetInteraction or type(PNC.StreetInteraction.HandleStreetAct) ~= "function" then
            statusMsg = "street_interaction_unavailable"
        else
            local actMap = {
                street_greet = "GREET",
                street_antagonize = "ANTAGONIZE",
                street_defuse = "DEFUSE",
            }
            local src = player or {
                id = "debug_player",
                isPlayer = true,
                x = target.x and (tonumber(target.x) + 1) or 0,
                y = tonumber(target.y) or 0,
                z = tonumber(target.z) or 0,
            }
            local ok, res = PNC.StreetInteraction.HandleStreetAct(src, target, actMap[action], {
                at = now,
                ignoreRange = true,
                witnessCandidates = findNearbyNPCs(target, 16),
            })
            statusMsg = tostring(actMap[action]) .. ":"
                .. (ok and tostring(res and res.beatId or "ok") or tostring(res))
        end
    elseif action == "trigger_copresence" then
        if not target then
            statusMsg = "no_npc_selected"
        else
            local nearby = findNearbyNPCs(target, 12)
            if PNC.DialogueMicroBeatDirector
                and type(PNC.DialogueMicroBeatDirector.StartScene) == "function"
                and #nearby >= 2
            then
                local responder = nil
                for i = 1, #nearby do
                    if tostring(nearby[i].id) ~= tostring(target.id) then
                        responder = nearby[i]
                        break
                    end
                end
                if responder then
                    local ok, scene = PNC.DialogueMicroBeatDirector.StartScene({
                        act = "GREET",
                        speakerId = target.id,
                        responderId = responder.id,
                        participants = nearby,
                        firstContact = false,
                        maxTurns = 4,
                    }, now)
                    statusMsg = ok and ("scene:" .. tostring(scene and scene.sceneId)) or ("scene_err:" .. tostring(scene))
                else
                    statusMsg = "copresence_needs_nearby_npc"
                end
            elseif PNC.CoPresenceService and type(PNC.CoPresenceService.TryTriggerForNPC) == "function" then
                local ok, reason = PNC.CoPresenceService.TryTriggerForNPC(target, now, { situationId = "situation.camp_chat" })
                statusMsg = "copresence:" .. tostring(ok) .. ":" .. tostring(reason)
            else
                statusMsg = "copresence_unavailable"
            end
        end
    elseif action == "inject_mixin" then
        local tel = target and PNC.DialogueMicroBeatDirector
            and type(PNC.DialogueMicroBeatDirector.GetActorTelemetry) == "function"
            and PNC.DialogueMicroBeatDirector.GetActorTelemetry(target.id) or nil
        if tel and tel.sceneId and not tel.closed then
            local ok, res = PNC.DialogueMicroBeatDirector.InjectGlobalMixin(tel.sceneId, {
                mixinType = "bystander_bark",
                severity = "low",
                tensionDelta = 15,
                barkId = "bark.whisper_check",
            }, now)
            statusMsg = ok and ("mixin:" .. tostring(res and res.action)) or ("mixin_err:" .. tostring(res))
        else
            statusMsg = "no_active_scene_for_npc"
        end
    elseif action == "reevaluate_ai" then
        if target and PNC.Tasking and PNC.Tasking.Commands
            and type(PNC.Tasking.Commands.Reevaluate) == "function"
        then
            local ok, lease = PNC.Tasking.Commands.Reevaluate(target.id, "unified_ai_debug_lab")
            statusMsg = "reevaluate:" .. tostring(ok)
                .. ":" .. tostring(type(lease) == "table" and lease.kind or lease)
        else
            statusMsg = "no_npc_selected"
        end
    elseif action == "clear_npc_ai" then
        if target then
            local tid = tostring(target.id)
            local director = PNC.DialogueMicroBeatDirector
            if director then
                local activeSceneId = type(director.SceneByNPC) == "table" and director.SceneByNPC[tid] or nil
                if activeSceneId and type(director.CloseScene) == "function" then
                    director.CloseScene(activeSceneId, "debug_clear", now)
                end
                if type(director.RecentByNPC) == "table" then
                    director.RecentByNPC[tid] = nil
                end
            end
            if PNC.AgitationService and PNC.AgitationService.Clear then
                PNC.AgitationService.Clear(target.id)
            end
            if PNC.PerceptionService and PNC.PerceptionService.ClearClues then
                PNC.PerceptionService.ClearClues(target)
            end
            if PNC.JointSceneLease and PNC.JointSceneLease.OnParticipantUnavailable then
                PNC.JointSceneLease.OnParticipantUnavailable(target.id, "debug_clear", now)
            end
            if PNC.SecondaryChannel and PNC.SecondaryChannel.ClearForRecord then
                PNC.SecondaryChannel.ClearForRecord(target, PNC.Registry and PNC.Registry.GetLiveZombie and PNC.Registry.GetLiveZombie(target.id) or nil)
            end
            if PNC.AutonomyScorer and type(PNC.AutonomyScorer.Cooldowns) == "table" then
                PNC.AutonomyScorer.Cooldowns[tid] = nil
            end
            statusMsg = "cleared:" .. tid
        else
            statusMsg = "no_npc_selected"
        end
    end

    Service._lastActionStatus = statusMsg
    return Service.BuildSnapshot(target and target.id or npcId, player, statusMsg), statusMsg
end

return Service
