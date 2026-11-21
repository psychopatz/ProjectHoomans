-- Authoritative narrow domain-delta builders, event-to-domain classifier,
-- and per-record incarnation/domain-revision metadata stamping.

local BodyBinding = require "PNC/Core/Networking/PNC_MultiplayerBodyBinding"

local Network = PNC.Network
local Internal = Network.Internal
local Core = PNC.Core
local Const = PNC.Const
local Parts = Internal and Internal.SnapshotParts or {}
local PresencePayload = Internal and Internal.PresencePayload or {}

local DOMAIN_KEYS = {
    "presence",
    "combat_damage",
    "combat_state",
    "health_wounds",
    "equipment",
}

Network.SUPPORTED_DELTA_KINDS = Network.SUPPORTED_DELTA_KINDS or {
    presence = true,
    combat_damage = true,
    combat_state = true,
    health_wounds = true,
    equipment = true,
    full = true,
}

local EVENT_TO_DOMAIN = {
    -- Presence / motion / animation / courier micro-events.
    tick = "presence",
    presence = "presence",
    body_online_id = "presence",
    position_recovery = "presence",
    grounded_recovery = "presence",
    mobile_group_relocation = "presence",
    work_sequence_complete = "presence",
    animation_scene = "presence",
    animation_scene_debug = "presence",
    secondary_channel = "presence",
    agitation = "presence",
    bark = "presence",
    storage_courier = "presence",
    manual_corpse_haul_result = "presence",

    -- Combat damage & health impact.
    combat_damage = "combat_damage",
    damage = "combat_damage",
    player_damage = "combat_damage",
    zombie_bite = "combat_damage",

    -- Combat stance / weapon action / reload / hostility state.
    combat_state = "combat_state",
    attack_start = "combat_state",
    attack_hit = "combat_state",
    attack_finish = "combat_state",
    reload_finished = "combat_state",
    weapon_restore_ranged = "combat_state",
    weapon_fallback_melee = "combat_state",
    weapon_fallback_shove = "combat_state",
    weapon_mode = "combat_state",
    hostility = "combat_state",

    -- Wounds / medical / treatment / infection / healing.
    health_wounds = "health_wounds",
    npc_wound = "health_wounds",
    debug_wound = "health_wounds",
    wound_treated = "health_wounds",
    bandaged = "health_wounds",
    bandaged_all = "health_wounds",
    self_bandaged = "health_wounds",
    npc_treated = "health_wounds",
    heal = "health_wounds",
    knox_cured = "health_wounds",
    necroa_airborne_exposure = "health_wounds",
    self_treatment_started = "health_wounds",
    self_treatment_interrupted = "health_wounds",
    medical_care_started = "health_wounds",
    medical_care_treating = "health_wounds",
    medical_care_ended = "health_wounds",
    medical_bandage_shared = "health_wounds",
    debug_bandage_almost_dirty = "health_wounds",
    debug_infection = "health_wounds",
    infection_cleared = "health_wounds",

    -- Equipment / visible apparel deltas.
    equipment = "equipment",
    equipment_changed = "equipment",
    equipment_visuals = "equipment",

    -- Full snapshot / repair / structural lifecycle transitions.
    interest_enter = "full",
    spawn = "full",
    materialize = "full",
    death = "full",
    repair = "full",
    gap_repair = "full",
    reconnect = "full",
    fallback = "full",
    unsupported_delta = "full",
    missing_baseline = "full",
    incarnation_mismatch = "full",
    order = "full",
    map_presentation = "full",
    debug_toggle = "full",
    scavenge_collect = "full",
    scavenge_batch = "full",
    ambient_visit = "full",
    colonist_departure = "full",
    colonist_recovered = "full",
    faction_dogtag_renamed = "full",
    faction_dogtag_refreshed = "full",
    companion_owner_character_released = "full",
    starting_companion_shared_appearance = "full",
    starting_companion_shared_name = "full",
}

local PREFIX_TO_DOMAIN = {
    { prefix = "animation_scene", domain = "presence" },
    { prefix = "attack_", domain = "combat_state" },
    { prefix = "reload_", domain = "combat_state" },
    { prefix = "weapon_", domain = "combat_state" },
    { prefix = "infection_", domain = "health_wounds" },
    { prefix = "debug_infection_", domain = "health_wounds" },
    { prefix = "wound_", domain = "health_wounds" },
    { prefix = "medical_", domain = "health_wounds" },
    { prefix = "treatment_", domain = "health_wounds" },
    { prefix = "bandage_", domain = "health_wounds" },
    { prefix = "equipment_", domain = "equipment" },
}

local localSerial = 0

local function copyMap(tbl)
    if type(tbl) ~= "table" then return {} end
    local out = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            out[k] = copyMap(v)
        else
            out[k] = v
        end
    end
    return out
end

local function ensureReplicaMeta(record)
    if type(record) ~= "table" then return nil end
    record.runtime = type(record.runtime) == "table" and record.runtime or {}
    local runtime = record.runtime
    if type(runtime.domainRevisions) ~= "table" then
        local revs = {}
        for i = 1, #DOMAIN_KEYS do
            revs[DOMAIN_KEYS[i]] = 0
        end
        runtime.domainRevisions = revs
    else
        for i = 1, #DOMAIN_KEYS do
            local key = DOMAIN_KEYS[i]
            runtime.domainRevisions[key] = tonumber(runtime.domainRevisions[key]) or 0
        end
    end
    if type(runtime.replicaIncarnation) ~= "string"
        or runtime.replicaIncarnation == ""
    then
        if Internal and type(Internal.GetPortraitReference) == "function" then
            local ref = Internal.GetPortraitReference(record)
            if type(ref) == "table" and type(ref.incarnation) == "string"
                and ref.incarnation ~= ""
            then
                runtime.replicaIncarnation = ref.incarnation
            end
        end
        if type(runtime.replicaIncarnation) ~= "string"
            or runtime.replicaIncarnation == ""
        then
            local safeNow = Core and Core.Now and Core.Now() or 0
            localSerial = localSerial + 1
            runtime.replicaIncarnation =
                "rep:" .. tostring(safeNow) .. ":" .. tostring(localSerial)
        end
    end
    return runtime
end

function Network.ResolveEventDeltaKind(eventName)
    if eventName == nil then return "full" end
    local key = tostring(eventName)
    if key == "" then return "full" end
    local direct = EVENT_TO_DOMAIN[key]
    if direct then return direct end
    for i = 1, #PREFIX_TO_DOMAIN do
        local rule = PREFIX_TO_DOMAIN[i]
        if string.sub(key, 1, #rule.prefix) == rule.prefix then
            return rule.domain
        end
    end
    return "full"
end

function Network.StampDomainMetadata(record, snapshot, deltaKind, advanceDomainRev)
    if type(snapshot) ~= "table" then return snapshot end
    local resolvedKind = tostring(deltaKind or snapshot.deltaKind or "full")
    if not Network.SUPPORTED_DELTA_KINDS[resolvedKind] then
        resolvedKind = "full"
    end
    snapshot.deltaKind = resolvedKind
    snapshot.deltaProtocol = Const and Const.DOMAIN_DELTA_PROTOCOL or 1
    if type(record) ~= "table" then return snapshot end

    local runtime = ensureReplicaMeta(record)
    snapshot.replicaIncarnation = runtime.replicaIncarnation
    if resolvedKind == "full" then
        snapshot.domainRevisions = copyMap(runtime.domainRevisions)
    else
        local currentRev = tonumber(runtime.domainRevisions[resolvedKind]) or 0
        if advanceDomainRev == true then
            currentRev = currentRev + 1
            runtime.domainRevisions[resolvedKind] = currentRev
        end
        snapshot.domainRevision = currentRev
        snapshot.baseDomainRevision = math.max(0, currentRev - 1)
    end
    return snapshot
end

function Network.BuildCombatStateDelta(record)
    local Equipment = PNC.Equipment
    local Firearms = PNC.Firearms
    local runtime = type(record) == "table" and record.runtime or {}
    local resolveAIState = Parts.ResolveAIState
    local buildCombatSummary = Parts.BuildCombatSummary
    local buildVisualState = Parts.BuildVisualState
    local buildCombatDebugDelta = PresencePayload.BuildCombatDebugDelta
    local now = Core and Core.Now and Core.Now() or 0

    local aiState, inCombat = "Idle", false
    if type(resolveAIState) == "function" then
        aiState, inCombat = resolveAIState(record)
    end
    local equipmentInfo = Equipment and Equipment.Describe
        and Equipment.Describe(record) or {}
    local combat = type(buildCombatSummary) == "function"
        and buildCombatSummary(record, equipmentInfo) or {}
    local firearmState = Firearms and Firearms.BuildDebugState
        and Firearms.BuildDebugState(record) or nil
    local combatDebugState = type(buildCombatDebugDelta) == "function"
        and buildCombatDebugDelta(record, inCombat, now, firearmState) or nil
    local bodyBinding, liveBodyOnlineID, liveBodyLease =
        BodyBinding.Projection(record)
    local attackMode = runtime and (
        runtime.target ~= nil
        or (runtime.attackAction ~= nil
            and now < (tonumber(runtime.attackAction.finishAt) or 0))
    ) or false

    return {
        deltaKind = "combat_state",
        interestDetailed = true,
        id = record and record.id or nil,
        x = record and record.x or nil,
        y = record and record.y or nil,
        z = record and record.z or nil,
        presenceState = record and record.presenceState or nil,
        alive = record and record.alive ~= false or false,
        activeJob = record and record.activeJob or nil,
        activeBehavior = record and record.activeBehavior or nil,
        aiState = aiState,
        inCombat = inCombat,
        attackMode = attackMode,
        combatStance = combat.combatStance == true or inCombat == true,
        attackType = record and record.attackType or "auto",
        weaponMode = record and record.weaponMode or nil,
        weaponFullType = record and record.equipment
            and record.equipment.primaryFullType or nil,
        combatModeResolved = equipmentInfo.combatModeResolved
            or (record and record.weaponMode),
        weaponStatus = equipmentInfo.weaponStatus or "unknown",
        firearmState = firearmState,
        hostility = type(record and record.hostility) == "table"
            and copyMap(record.hostility) or nil,
        visualState = type(buildVisualState) == "function"
            and buildVisualState(record) or nil,
        combatDebugState = combatDebugState,
        presenceRevision = record and record.presenceRevision or nil,
        replicaSequence = runtime and runtime.replicaSequence or nil,
        liveBodyInstanceID = record and record.liveBodyInstanceID or nil,
        bodyBinding = bodyBinding,
        liveBodyOnlineID = liveBodyOnlineID,
        liveBodyLease = liveBodyLease,
    }
end

function Network.BuildHealthWoundsDelta(record)
    local Stamina = PNC.Stamina
    local Wounds = PNC.NPCWounds
    local health = type(record) == "table" and record.health or {}
    local runtime = type(record) == "table" and record.runtime or {}
    local buildBandageFeedback = Parts.BuildBandageFeedback
    local buildVisualState = Parts.BuildVisualState
    local staminaInfo = Stamina and Stamina.BuildSnapshot
        and Stamina.BuildSnapshot(record) or {}
    local bodyBinding, liveBodyOnlineID, liveBodyLease =
        BodyBinding.Projection(record)

    return {
        deltaKind = "health_wounds",
        interestDetailed = true,
        id = record and record.id or nil,
        x = record and record.x or nil,
        y = record and record.y or nil,
        z = record and record.z or nil,
        presenceState = record and record.presenceState or nil,
        alive = record and record.alive ~= false or false,
        hpCurrent = health.current,
        hpMax = health.max,
        healthState = health.state,
        canRevive = PNC.Health and PNC.Health.CanRevive
            and PNC.Health.CanRevive(record) or false,
        reviveUntil = health.reviveUntil or 0,
        recentDamageUntil = health.recentDamageUntil or 0,
        recentDamageType = health.recentDamageType,
        bodyHealth = Wounds and Wounds.BuildSnapshot
            and Wounds.BuildSnapshot(record) or nil,
        treatmentState = PNC.BehaviorTreatment
            and PNC.BehaviorTreatment.BuildSnapshot
            and PNC.BehaviorTreatment.BuildSnapshot(record) or nil,
        medicalCareState = PNC.Treatment
            and PNC.Treatment.BuildMedicalCareSnapshot
            and PNC.Treatment.BuildMedicalCareSnapshot(record) or nil,
        bandageFeedback = type(buildBandageFeedback) == "function"
            and buildBandageFeedback(record) or nil,
        staminaCurrent = staminaInfo.current,
        staminaMax = staminaInfo.max,
        staminaState = staminaInfo.state,
        visualState = type(buildVisualState) == "function"
            and buildVisualState(record) or nil,
        presenceRevision = record and record.presenceRevision or nil,
        replicaSequence = runtime and runtime.replicaSequence or nil,
        liveBodyInstanceID = record and record.liveBodyInstanceID or nil,
        bodyBinding = bodyBinding,
        liveBodyOnlineID = liveBodyOnlineID,
        liveBodyLease = liveBodyLease,
    }
end

function Network.BuildEquipmentDelta(record, leanPortrait)
    local Equipment = PNC.Equipment
    local Firearms = PNC.Firearms
    local Identity = PNC.Identity
    local runtime = type(record) == "table" and record.runtime or {}
    local buildVisualState = Parts.BuildVisualState
    local equipmentInfo = Equipment and Equipment.Describe
        and Equipment.Describe(record) or {}
    local bodyBinding, liveBodyOnlineID, liveBodyLease =
        BodyBinding.Projection(record)
    local eq = type(record) == "table" and record.equipment or {}

    local payload = {
        deltaKind = "equipment",
        interestDetailed = true,
        id = record and record.id or nil,
        presenceState = record and record.presenceState or nil,
        weaponMode = record and record.weaponMode or nil,
        weaponFullType = eq and eq.primaryFullType or nil,
        combatModeResolved = equipmentInfo.combatModeResolved
            or (record and record.weaponMode),
        weaponStatus = equipmentInfo.weaponStatus or "unknown",
        firearmState = Firearms and Firearms.BuildDebugState
            and Firearms.BuildDebugState(record) or nil,
        radioGear = Equipment and Equipment.RadioGear
            and Equipment.RadioGear.Describe
            and Equipment.RadioGear.Describe(record) or nil,
        equipmentSummary = {
            primaryFullType = eq and eq.primaryFullType or nil,
            primaryVisual = Equipment
                and Equipment.BuildPrimaryVisualSummary
                and Equipment.BuildPrimaryVisualSummary(record) or nil,
            secondaryFullType = eq and eq.secondaryFullType or nil,
            worn = copyMap(eq and eq.worn or {}),
            wornVisuals = Equipment
                and Equipment.BuildWornVisualSummary
                and Equipment.BuildWornVisualSummary(record) or {},
            attached = copyMap(eq and eq.attached or {}),
            workPresentation = Equipment
                and Equipment.BuildWorkPresentationSummary
                and Equipment.BuildWorkPresentationSummary(record) or nil,
        },
        visualState = type(buildVisualState) == "function"
            and buildVisualState(record) or nil,
        presenceRevision = record and record.presenceRevision or nil,
        replicaSequence = runtime and runtime.replicaSequence or nil,
        liveBodyInstanceID = record and record.liveBodyInstanceID or nil,
        bodyBinding = bodyBinding,
        liveBodyOnlineID = liveBodyOnlineID,
        liveBodyLease = liveBodyLease,
    }
    if leanPortrait == true and Internal
        and type(Internal.GetPortraitReference) == "function"
    then
        payload.portraitRef = Internal.GetPortraitReference(record)
    elseif leanPortrait ~= true and Identity
        and type(Identity.BuildPortraitSummary) == "function"
    then
        payload.portrait = Identity.BuildPortraitSummary(record)
    end
    return payload
end

function Network.BuildDomainDelta(record, deltaKind, leanPortrait)
    local kind = tostring(deltaKind or "full")
    local snapshot
    if kind == "presence" and type(Network.BuildPresenceDelta) == "function" then
        snapshot = Network.BuildPresenceDelta(record)
    elseif kind == "combat_damage"
        and type(Network.BuildCombatDamageDelta) == "function"
    then
        snapshot = Network.BuildCombatDamageDelta(record)
    elseif kind == "combat_state" then
        snapshot = Network.BuildCombatStateDelta(record)
    elseif kind == "health_wounds" then
        snapshot = Network.BuildHealthWoundsDelta(record)
    elseif kind == "equipment" then
        snapshot = Network.BuildEquipmentDelta(record, leanPortrait)
    else
        kind = "full"
        snapshot = Network.BuildSnapshot
            and Network.BuildSnapshot(record, nil, leanPortrait)
            or nil
    end
    return Network.StampDomainMetadata(record, snapshot, kind, kind ~= "full")
end

return Network
