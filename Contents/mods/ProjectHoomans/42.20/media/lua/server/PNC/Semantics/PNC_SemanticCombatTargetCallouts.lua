if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.Semantics.CombatTargetCalloutsInternal = PNC.Semantics.CombatTargetCalloutsInternal or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local S = PNC.Semantics.CombatTargetCallouts or {}
local I = PNC.Semantics.CombatTargetCalloutsInternal
PNC.Semantics.CombatTargetCallouts = S

S.VERSION = 2
S.FAMILY = "combat_target_acquired"
S.COOLDOWN_MS = 5000
S.WITNESS_RADIUS = tonumber(PNC.Const and PNC.Const.ZOMBIE_TARGET_RADIUS) or 12

require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_Medical"
require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_Stamina"
require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_TargetHelpers"

local Common, Core = PNC.BehaviorCommon, PNC.Core
local Projection = PNC.TacticalSpatialProjection or require "PNC/Core/Spatial/PNC_TacticalSpatialProjection"
local Language = PNC.Semantics.TacticalSpatialLanguage or require "PNC/Semantics/PNC_SemanticTacticalSpatialLanguage"
local Profile = PNC.Semantics.CombatReactionProfile or require "PNC/Semantics/PNC_SemanticCombatReactionProfile"

local VALID_KINDS = { zombie = true, npc = true, player = true, foreign_npc = true }

local function finite(v) return S.Finite(v) end

function S.OnTargetChanged(event, record)
    if type(event) ~= "table" or type(record) ~= "table" then return false, "target_event_invalid" end
    local target = event.target
    local kind = tostring(type(target) == "table" and target.kind or "")
    if type(target) ~= "table" or not VALID_KINDS[kind] then return false, "target_kind_unsupported" end

    local core = (PNC and PNC.Core) or Core
    local now = finite(event.at) or (core and type(core.Now) == "function" and finite(core.Now())) or 0
    local perc = PNC and PNC.Perception or nil
    local wr = nil
    if target.viaAllyWarning ~= true and tostring(event.source or "") ~= "ally_threat_warning"
        and perc and type(perc.PublishAllyThreatWarning) == "function"
    then
        wr = perc.PublishAllyThreatWarning(record, target, {
            at = now, hopDepth = 0, ignoreCooldown = event.ignoreWarningCooldown == true,
        })
    end
    local ref = I.TargetEventID(event, record, target)
    if wr and wr.emitted == false and wr.reason == "skirmish_active" and S.HandleSkirmishActive then
        return S.HandleSkirmishActive(record, wr, now, ref)
    end

    local x, y, z, source = I.TargetPoint(target, wr)
    if not x and not (wr and wr.emitted) then return false, "target_position_unavailable" end
    local tCls = (kind == "zombie" or tostring(target.threatClass or "") == "zombie") and "zombie" or "human_hostile"
    local tid = target.id or target.zombieId or target.actorId or target.onlineID
    local spatial, spatialReason, pres, textReason, mode, modeReason, text
    if x then
        spatial, spatialReason = Projection.Project(record, {
            kind = tCls, id = tid, x = x, y = y, z = z, observedAt = now, positionSource = source,
        }, { now = now, sameAreaThreshold = 0.5, maxThreatAgeMs = 2000 })
    end

    local evType = (tCls == "zombie") and "combat_zombie_acquired" or "combat_hostile_acquired"
    local spID = "semantic.combat." .. ((tCls == "zombie") and "zombie_acquired" or "hostile_acquired")
    local pCls, ctx = "TACTICAL_BARK", nil
    if wr and wr.emitted == true then
        local tone, desc = S.ResolveAllyWarnTone(record, nil), wr.descriptor
        local listeners = {}
        local notified = type(wr.notified) == "table" and wr.notified or {}
        for i = 1, #notified do
            local ally = type(notified[i]) == "table" and notified[i].record or nil
            if type(ally) == "table" and ally.alive ~= false then
                listeners[#listeners + 1] = ally
            end
        end
        local audSvc = PNC.Semantics and PNC.Semantics.AudienceContext or nil
        local aud = audSvc and type(audSvc.Resolve) == "function"
            and audSvc.Resolve(record, listeners, {
                includeNearbyPlayer = true,
                playerRadius = S.WITNESS_RADIUS or 12,
                targetCount = desc and desc.enemyCount or 1,
            }) or nil
        local firstAlly = listeners[1] or (aud and aud.includesPlayer and { id = "player", name = aud.playerName, isPlayer = true }) or nil
        local toks = S.BuildRichSpeechTokens and S.BuildRichSpeechTokens(record, firstAlly, desc, now, tone, { spatial = spatial, audience = aud }) or nil
        local extra = {}
        if desc and desc.enemyPosture == "crawler" then extra.replyRole = "crawler" end
        if aud and type(aud.context) == "table" then
            extra.context = aud.context
        end
        local rich, rRes = S.ResolveSemanticLine(record, "combat_ally_warn_callout", "WARN", tCls, ref, nil, toks, extra)
        if rich then
            text, evType = rich, "combat_ally_warn_callout"
            spID = rRes and rRes.realizationID or "semantic.combat.ally_warn.callout"
            pCls = rRes and rRes.presentationClass or "BARK"
        end
    end
    if not text and spatial then
        local prof = Profile.Build(record, "", { role = "witness", actorKind = "npc", inCombat = true })
        mode, modeReason = Language.SelectMode(record, prof, spatial)
        spatial.presentationMode, spatial.presentationReason = mode, modeReason
        text, textReason, pres = Language.Decorate("", tCls, spatial, mode)
    end

    local tauntEmitted = I.TryEmitHostilePlayerTaunt(record, target, kind, core, now)
    if pres or (wr and wr.emitted == true and text) then
        ctx = {
            eventType = evType, eventRef = ref, threadID = ref, targetKind = tCls, targetRef = tostring(tid or ""),
            tacticalSpatial = spatial, tacticalPresentationMode = mode, tacticalPresentationReason = modeReason,
            tacticalSpatialPresentation = pres, presentationClass = pCls, transient = true,
        }
    elseif tauntEmitted then
        if wr and wr.emitted == true then S.EnqueueAllyReplies(record, wr, now, ref) end
        return true, { eventRef = ref, tauntEmitted = true, sent = 1, warning = wr }
    else
        return false, textReason or spatialReason
    end

    local net = PNC and PNC.Network or nil
    local hasNet = core and type(core.ForEachPlayer) == "function" and net and type(net.SendConversationRelationshipForNPC) == "function"
    if not hasNet and not (wr and wr.emitted == true) then return false, "presentation_transport_unavailable" end

    local sent = (not tauntEmitted and hasNet and text) and S.DeliverBark(record, now, {
        eventType = evType, speechEventID = spID, act = "WARN", family = S.FAMILY, threadID = ref,
        eventRef = ref, text = text, priority = 62, priorityHoldMs = 700, ttlMs = 9000,
        presentationClass = pCls, context = ctx, tacticalSpatial = spatial, tacticalPresentation = pres,
    }) or (tauntEmitted and 1 or 0)
    if sent > 0 and PNC.Semantics and PNC.Semantics.DialogueBeats
        and type(PNC.Semantics.DialogueBeats.NotifyExternalSpeech) == "function"
    then
        PNC.Semantics.DialogueBeats.NotifyExternalSpeech(now, 1500)
    end

    local sec = PNC and PNC.SecondaryChannel or nil
    if sec and type(sec.RequestBark) == "function" and (sent > 0 or (wr and wr.emitted == true)) then
        sec.RequestBark(record, "bark.alert_hey", now)
    end
    if wr and wr.emitted == true then S.EnqueueAllyReplies(record, wr, now, ref) end
    local injTriggered = false
    if not tauntEmitted and sent == 0 and (not wr or wr.emitted ~= true)
        and type(S.OnFightingWhileInjured) == "function"
    then
        local okInj = S.OnFightingWhileInjured(record, target, now, { threadID = ref })
        if okInj then injTriggered = true end
    end
    local emitted = sent > 0 or injTriggered or (wr and wr.emitted == true)
    return emitted, emitted and { eventRef = ref, spatial = spatial, presentation = pres, sent = sent, warning = wr } or "no_audience"
end

if Common and type(Common.RegisterCombatTargetListener) == "function" then
    Common.RegisterCombatTargetListener("semantic.combat_target_callouts", S.OnTargetChanged)
end

return S
