if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Service = PNC.Semantics.CombatTargetCallouts or {}
PNC.Semantics.CombatTargetCallouts = Service

Service.VERSION = 1
Service.FAMILY = "combat_target_acquired"
Service.COOLDOWN_MS = 5000
Service.WITNESS_RADIUS = tonumber(
    PNC.Const and PNC.Const.ZOMBIE_TARGET_RADIUS
) or 12

local Common = PNC.BehaviorCommon
local Core = PNC.Core
local Registry = PNC.Registry
local Perception = PNC.Perception
local Network = PNC.Network
local Projection = PNC.TacticalSpatialProjection
    or require "PNC/Core/Spatial/PNC_TacticalSpatialProjection"
local Language = PNC.Semantics.TacticalSpatialLanguage
    or require "PNC/Semantics/PNC_SemanticTacticalSpatialLanguage"
local Profile = PNC.Semantics.CombatReactionProfile
    or require "PNC/Semantics/PNC_SemanticCombatReactionProfile"
local Banter = PNC.Semantics.CombatBanterArbiter
    or require "PNC/Semantics/PNC_SemanticCombatBanterArbiter"

local function finite(value)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then return nil end
    return value
end

local function targetPoint(target)
    if type(target) ~= "table" then return nil end
    local x = finite(target.x)
    local y = finite(target.y)
    local z = finite(target.z)
    if x and y then return x, y, z or 0, "combat_target" end
    local id = tostring(target.id or "")
    local record = id ~= "" and Registry
        and type(Registry.Get) == "function" and Registry.Get(id) or nil
    if type(record) == "table" then
        x = finite(record.x)
        y = finite(record.y)
        z = finite(record.z)
        if x and y then return x, y, z or 0, "target_record" end
    end
    return nil
end

local function playerKey(player)
    if not player then return nil end
    if type(player.getOnlineID) == "function" then
        local value = player:getOnlineID()
        if value ~= nil then return tostring(value) end
    end
    if type(player.getUsername) == "function" then
        local value = player:getUsername()
        if value and value ~= "" then return tostring(value) end
    end
    return nil
end

local function coordinate(object, method)
    if not object or type(object[method]) ~= "function" then return nil end
    return finite(object[method](object))
end

local function canHear(player, record)
    local px = coordinate(player, "getX")
    local py = coordinate(player, "getY")
    local pz = coordinate(player, "getZ")
    local nx = finite(record and record.x)
    local ny = finite(record and record.y)
    local nz = finite(record and record.z)
    if not px or not py or not pz or not nx or not ny or not nz then
        return false
    end
    if math.abs(pz - nz) >= 1 then return false end
    local dx = px - nx
    local dy = py - ny
    if (dx * dx + dy * dy) > Service.WITNESS_RADIUS ^ 2 then
        return false
    end
    if Perception and type(Perception.CanSeeWorldObject) == "function" then
        return Perception.CanSeeWorldObject(record, player) == true
    end
    return false
end

local function eventID(event, record, target)
    return table.concat({
        "combat-target-acquired",
        tostring(record and record.id or ""),
        tostring(target and (target.id or target.onlineID) or ""),
        tostring(math.floor(finite(event and event.at) or 0)),
    }, ":")
end

function Service.OnTargetChanged(event, record)
    if type(event) ~= "table" or type(record) ~= "table" then
        return false, "target_event_invalid"
    end
    local target = event.target
    if type(target) ~= "table"
        or tostring(target.kind or "") ~= "npc"
    then
        return false, "target_not_human_hostile"
    end

    local x, y, z, source = targetPoint(target)
    if not x then return false, "target_position_unavailable" end
    local now = finite(event.at)
        or (Core and type(Core.Now) == "function" and finite(Core.Now()))
        or 0
    local spatial, spatialReason = Projection.Project(record, {
        kind = "human_hostile",
        id = target.id or target.onlineID,
        x = x,
        y = y,
        z = z,
        observedAt = now,
        positionSource = source,
    }, {
        now = now,
        sameAreaThreshold = 0.5,
        maxThreatAgeMs = 2000,
    })
    if not spatial then return false, spatialReason end

    local profile = Profile.Build(record, "", {
        role = "witness",
        actorKind = "npc",
        inCombat = true,
    })
    local mode, modeReason = Language.SelectMode(record, profile, spatial)
    spatial.presentationMode = mode
    spatial.presentationReason = modeReason
    local text, textReason, presentation = Language.Decorate(
        "", "human_hostile", spatial, mode
    )
    if not presentation then return false, textReason end

    local sent = 0
    if not Core or type(Core.ForEachPlayer) ~= "function"
        or not Network
        or type(Network.SendConversationRelationshipForNPC) ~= "function"
    then
        return false, "presentation_transport_unavailable"
    end
    local ref = eventID(event, record, target)
    Core.ForEachPlayer(function(player)
        if not canHear(player, record) then return end
        local audience = playerKey(player)
        if not audience then return end
        local allowed = Banter.Reserve({
            streamKey = "combat-target:" .. tostring(record.id),
            now = now,
            cooldownMs = Service.COOLDOWN_MS,
            maxSpeakers = 1,
            speakerID = tostring(record.id),
            audienceKey = audience,
            family = Service.FAMILY,
            familyCooldownMs = Service.COOLDOWN_MS,
            priority = 75,
        })
        if allowed ~= true then return end

        local context = {
            eventType = "combat_hostile_acquired",
            eventRef = ref,
            targetKind = "human_hostile",
            targetRef = tostring(target.id or target.onlineID or ""),
            tacticalSpatial = spatial,
            tacticalPresentationMode = mode,
            tacticalPresentationReason = modeReason,
            tacticalSpatialPresentation = presentation,
            presentationClass = "TACTICAL_BARK",
            transient = true,
        }
        local result = {
            source = "combat_hostile_acquired",
            eventID = ref,
            npcID = tostring(record.id),
            meaningful = false,
            transientInteraction = true,
            interactionTTLHours = 10 / 3600,
            ambientFlavor = {
                eventID = ref,
                eventRef = ref,
                speechEventID = "semantic.combat.hostile_acquired",
                text = text,
                semanticOwned = true,
                eventType = "combat_hostile_acquired",
                act = "WARN",
                topic = "combat",
                factRefs = {},
                offerIDs = {},
                family = Service.FAMILY,
                priority = 75,
                weight = 0.25,
                llmEligible = false,
                memoryEligible = false,
                npcID = tostring(record.id),
                mergeKey = ref,
                ttlMs = 6000,
                holdMs = 1500,
                context = context,
                presentationClass = "TACTICAL_BARK",
                source = {
                    kind = "semantic_speech",
                    channel = "combat",
                    eventType = "combat_hostile_acquired",
                },
            },
        }
        local delivered = Network.SendConversationRelationshipForNPC(
            player,
            tostring(record.id),
            "combat_hostile_acquired",
            result
        ) == true
        if Banter and type(Banter.RecordPresentation) == "function" then
            Banter.RecordPresentation({
                accepted = delivered,
                reason = delivered and "presentation_sent"
                    or "presentation_transport_refused",
                at = now,
                speakerID = tostring(record.id),
                audienceKey = audience,
                family = Service.FAMILY,
                eventRef = ref,
                presentationClass = "TACTICAL_BARK",
                tacticalSpatial = spatial,
                tacticalPresentation = presentation,
            })
        end
        if delivered then
            sent = sent + 1
        end
    end)
    return sent > 0, sent > 0 and {
        eventRef = ref,
        spatial = spatial,
        presentation = presentation,
        sent = sent,
    } or "no_audience"
end

if Common and type(Common.RegisterCombatTargetListener) == "function" then
    Common.RegisterCombatTargetListener(
        "semantic.combat_target_callouts",
        Service.OnTargetChanged
    )
end

return Service
