if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Service = PNC.Semantics.CombatTargetCallouts or {}
PNC.Semantics.CombatTargetCallouts = Service

Service.VERSION = 2
Service.FAMILY = "combat_target_acquired"
Service.COOLDOWN_MS = 5000
Service.WITNESS_RADIUS = tonumber(
    PNC.Const and PNC.Const.ZOMBIE_TARGET_RADIUS
) or 12

require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_AllyReplies"

local Common = PNC.BehaviorCommon
local Core = PNC.Core
local Registry = PNC.Registry
local Projection = PNC.TacticalSpatialProjection
    or require "PNC/Core/Spatial/PNC_TacticalSpatialProjection"
local Language = PNC.Semantics.TacticalSpatialLanguage
    or require "PNC/Semantics/PNC_SemanticTacticalSpatialLanguage"
local Profile = PNC.Semantics.CombatReactionProfile
    or require "PNC/Semantics/PNC_SemanticCombatReactionProfile"

local VALID_TARGET_KINDS = { zombie = true, npc = true, player = true, foreign_npc = true }

local function finite(value) return Service.Finite(value) end

local function targetPoint(target, warningResult)
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
    local desc = type(warningResult) == "table" and warningResult.descriptor or nil
    if type(desc) == "table" and finite(desc.x) and finite(desc.y) then
        return finite(desc.x), finite(desc.y), finite(desc.z) or 0, "ally_warning_descriptor"
    end
    return nil
end

local function eventID(event, record, target)
    return table.concat({
        "combat-target-acquired",
        tostring(record and record.id or ""),
        tostring(target and (target.id or target.zombieId or target.actorId or target.onlineID) or ""),
        tostring(math.floor(finite(event and event.at) or 0)),
    }, ":")
end

function Service.OnTargetChanged(event, record)
    if type(event) ~= "table" or type(record) ~= "table" then
        return false, "target_event_invalid"
    end
    local target = event.target
    local kind = tostring(type(target) == "table" and target.kind or "")
    if type(target) ~= "table" or not VALID_TARGET_KINDS[kind] then
        return false, "target_kind_unsupported"
    end

    local core = (PNC and PNC.Core) or Core
    local now = finite(event.at)
        or (core and type(core.Now) == "function" and finite(core.Now()))
        or 0
    local perception = PNC and PNC.Perception or nil
    local warningResult = nil
    if target.viaAllyWarning ~= true
        and tostring(event.source or "") ~= "ally_threat_warning"
        and perception and type(perception.PublishAllyThreatWarning) == "function"
    then
        warningResult = perception.PublishAllyThreatWarning(record, target, {
            at = now,
            hopDepth = 0,
            ignoreCooldown = event.ignoreWarningCooldown == true,
        })
    end

    local x, y, z, source = targetPoint(target, warningResult)
    if not x and not (warningResult and warningResult.emitted) then
        return false, "target_position_unavailable"
    end
    local semanticClass = (kind == "zombie" or tostring(target.threatClass or "") == "zombie")
        and "zombie" or "human_hostile"
    local targetId = target.id or target.zombieId or target.actorId or target.onlineID
    local profile = Profile.Build(record, "", { role = "witness", actorKind = "npc", inCombat = true })
    local spatial, spatialReason, presentation, textReason, mode, modeReason, text
    if x then
        spatial, spatialReason = Projection.Project(record, {
            kind = semanticClass, id = targetId, x = x, y = y, z = z,
            observedAt = now, positionSource = source,
        }, { now = now, sameAreaThreshold = 0.5, maxThreatAgeMs = 2000 })
        if spatial then
            mode, modeReason = Language.SelectMode(record, profile, spatial)
            spatial.presentationMode, spatial.presentationReason = mode, modeReason
            text, textReason, presentation = Language.Decorate("", semanticClass, spatial, mode)
        end
    end

    local ref = eventID(event, record, target)
    local evType = (semanticClass == "zombie") and "combat_zombie_acquired" or "combat_hostile_acquired"
    local speechID = "semantic.combat." .. ((semanticClass == "zombie") and "zombie_acquired" or "hostile_acquired")
    local presClass, resolved, ctx = "TACTICAL_BARK", nil, nil
    if warningResult and warningResult.emitted == true then
        local tone = Service.ResolveAllyWarnTone(record, profile)
        local toks = Service.BuildRichSpeechTokens and Service.BuildRichSpeechTokens(
            record, record, warningResult.descriptor, now, tone
        ) or nil
        local rich, rRes = Service.ResolveSemanticLine(
            record, "combat_ally_warn_callout", "WARN", semanticClass, ref, profile, toks
        )
        if rich then
            text, resolved = rich, rRes
            evType = "combat_ally_warn_callout"
            speechID = rRes and rRes.realizationID or "semantic.combat.ally_warn.callout"
            presClass = rRes and rRes.presentationClass or "BARK"
        end
    end
    if presentation or (warningResult and warningResult.emitted == true and text) then
        ctx = {
            eventType = evType, eventRef = ref, targetKind = semanticClass,
            targetRef = tostring(targetId or ""), tacticalSpatial = spatial,
            tacticalPresentationMode = mode, tacticalPresentationReason = modeReason,
            tacticalSpatialPresentation = presentation, presentationClass = presClass,
            transient = true,
        }
    else
        return false, textReason or spatialReason
    end

    local network = PNC and PNC.Network or nil
    local hasTransport = core and type(core.ForEachPlayer) == "function"
        and network and type(network.SendConversationRelationshipForNPC) == "function"
    if not hasTransport and not (warningResult and warningResult.emitted == true) then
        return false, "presentation_transport_unavailable"
    end

    local sent = 0
    if hasTransport and text then
        sent = Service.DeliverBark(record, now, {
            eventType = evType,
            speechEventID = speechID,
            act = "WARN",
            family = Service.FAMILY,
            eventRef = ref,
            text = text,
            priority = 75,
            presentationClass = presClass,
            context = ctx,
            tacticalSpatial = spatial,
            tacticalPresentation = presentation,
        })
    end

    local sec = PNC and PNC.SecondaryChannel or nil
    if sec and type(sec.RequestBark) == "function"
        and (sent > 0 or (warningResult and warningResult.emitted == true))
    then
        sec.RequestBark(record, "bark.alert_hey", now)
    end
    if warningResult and warningResult.emitted == true then
        Service.EnqueueAllyReplies(record, warningResult, now, ref)
    end

    local emitted = sent > 0 or (warningResult and warningResult.emitted == true)
    return emitted, emitted and {
        eventRef = ref,
        spatial = spatial,
        presentation = presentation,
        sent = sent,
        warning = warningResult,
    } or "no_audience"
end

if Common and type(Common.RegisterCombatTargetListener) == "function" then
    Common.RegisterCombatTargetListener(
        "semantic.combat_target_callouts",
        Service.OnTargetChanged
    )
end

return Service
