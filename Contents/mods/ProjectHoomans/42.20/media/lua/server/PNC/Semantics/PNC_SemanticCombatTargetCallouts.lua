if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local S = PNC.Semantics.CombatTargetCallouts or {}
PNC.Semantics.CombatTargetCallouts = S

S.VERSION = 2
S.FAMILY = "combat_target_acquired"
S.COOLDOWN_MS = 5000
S.WITNESS_RADIUS = tonumber(PNC.Const and PNC.Const.ZOMBIE_TARGET_RADIUS) or 12

require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_Medical"

local Common, Core, Registry = PNC.BehaviorCommon, PNC.Core, PNC.Registry
local Projection = PNC.TacticalSpatialProjection or require "PNC/Core/Spatial/PNC_TacticalSpatialProjection"
local Language = PNC.Semantics.TacticalSpatialLanguage or require "PNC/Semantics/PNC_SemanticTacticalSpatialLanguage"
local Profile = PNC.Semantics.CombatReactionProfile or require "PNC/Semantics/PNC_SemanticCombatReactionProfile"

local VALID_KINDS = { zombie = true, npc = true, player = true, foreign_npc = true }

local function finite(v) return S.Finite(v) end

local function targetPoint(target, wr)
    if type(target) ~= "table" then return nil end
    local x, y, z = finite(target.x), finite(target.y), finite(target.z)
    if x and y then return x, y, z or 0, "combat_target" end
    local id = tostring(target.id or target.zombieId or target.actorId or "")
    local reg = (PNC and PNC.Registry) or Registry
    local rec = id ~= "" and reg and type(reg.Get) == "function" and reg.Get(id) or nil
    if type(rec) == "table" then
        x, y, z = finite(rec.x), finite(rec.y), finite(rec.z)
        if x and y then return x, y, z or 0, "target_record" end
    end
    local desc = type(wr) == "table" and wr.descriptor or nil
    if type(desc) == "table" and finite(desc.x) and finite(desc.y) then
        return finite(desc.x), finite(desc.y), finite(desc.z) or 0, "ally_warning_descriptor"
    end
    return nil
end

local function eventID(ev, rec, t)
    return table.concat({
        "combat-target-acquired", tostring(rec and rec.id or ""),
        tostring(t and (t.id or t.zombieId or t.actorId or t.onlineID) or ""),
        tostring(math.floor(finite(ev and ev.at) or 0)),
    }, ":")
end

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
    if wr and wr.emitted == false and wr.reason == "skirmish_active" and S.HandleSkirmishActive then
        return S.HandleSkirmishActive(record, wr, now, eventID(event, record, target))
    end

    local x, y, z, source = targetPoint(target, wr)
    if not x and not (wr and wr.emitted) then return false, "target_position_unavailable" end
    local tCls = (kind == "zombie" or tostring(target.threatClass or "") == "zombie") and "zombie" or "human_hostile"
    local tid = target.id or target.zombieId or target.actorId or target.onlineID
    local spatial, spatialReason, pres, textReason, mode, modeReason, text
    if x then
        spatial, spatialReason = Projection.Project(record, {
            kind = tCls, id = tid, x = x, y = y, z = z, observedAt = now, positionSource = source,
        }, { now = now, sameAreaThreshold = 0.5, maxThreatAgeMs = 2000 })
    end

    local ref = eventID(event, record, target)
    local evType = (tCls == "zombie") and "combat_zombie_acquired" or "combat_hostile_acquired"
    local spID = "semantic.combat." .. ((tCls == "zombie") and "zombie_acquired" or "hostile_acquired")
    local pCls, resolved, ctx = "TACTICAL_BARK", nil, nil
    if wr and wr.emitted == true then
        local tone, desc = S.ResolveAllyWarnTone(record, nil), wr.descriptor
        local toks = S.BuildRichSpeechTokens and S.BuildRichSpeechTokens(record, record, desc, now, tone, { spatial = spatial }) or nil
        local extra = (desc and desc.enemyPosture == "crawler") and { replyRole = "crawler" } or nil
        local rich, rRes = S.ResolveSemanticLine(record, "combat_ally_warn_callout", "WARN", tCls, ref, nil, toks, extra)
        if rich then
            text, resolved, evType = rich, rRes, "combat_ally_warn_callout"
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
    if pres or (wr and wr.emitted == true and text) then
        ctx = {
            eventType = evType, eventRef = ref, threadID = ref, targetKind = tCls, targetRef = tostring(tid or ""),
            tacticalSpatial = spatial, tacticalPresentationMode = mode, tacticalPresentationReason = modeReason,
            tacticalSpatialPresentation = pres, presentationClass = pCls, transient = true,
        }
    else
        return false, textReason or spatialReason
    end

    local net = PNC and PNC.Network or nil
    local hasNet = core and type(core.ForEachPlayer) == "function" and net and type(net.SendConversationRelationshipForNPC) == "function"
    if not hasNet and not (wr and wr.emitted == true) then return false, "presentation_transport_unavailable" end

    local sent = hasNet and text and S.DeliverBark(record, now, {
        eventType = evType, speechEventID = spID, act = "WARN", family = S.FAMILY, threadID = ref,
        eventRef = ref, text = text, priority = 62, priorityHoldMs = 700, ttlMs = 9000,
        presentationClass = pCls, context = ctx, tacticalSpatial = spatial, tacticalPresentation = pres,
    }) or 0

    local sec = PNC and PNC.SecondaryChannel or nil
    if sec and type(sec.RequestBark) == "function" and (sent > 0 or (wr and wr.emitted == true)) then
        sec.RequestBark(record, "bark.alert_hey", now)
    end
    if wr and wr.emitted == true then S.EnqueueAllyReplies(record, wr, now, ref) end
    local emitted = sent > 0 or (wr and wr.emitted == true)
    return emitted, emitted and { eventRef = ref, spatial = spatial, presentation = pres, sent = sent, warning = wr } or "no_audience"
end

if Common and type(Common.RegisterCombatTargetListener) == "function" then
    Common.RegisterCombatTargetListener("semantic.combat_target_callouts", S.OnTargetChanged)
end

return S
