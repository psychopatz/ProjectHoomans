if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Discovery = PNC.WorldDiscovery
local Internal = Discovery.RadioBroadcastsInternal
local Types = PNC.WorldDiscoveryTypes
local FlavorAddress = PNC.FlavorAddress
local playerContextFor = Internal.PlayerContextFor
local pickSpeakers = Internal.PickSpeakers
local pickConflictParticipant = Internal.PickConflictParticipant
local conflictRoll = Internal.ConflictRoll
local revealRoll = Internal.RevealRoll
local argumentRoll = Internal.ArgumentRoll
local factionName = Internal.FactionName
local factionID = Internal.FactionID

function Discovery.BuildRadioTemplateContext(player, entity, phase)
    if not entity then return nil end
    local exact = phase >= Types.PHASE_LOCATED
    local location = exact
        and tostring(math.floor(entity.x)) .. ", "
            .. tostring(math.floor(entity.y))
        or "grid " .. tostring(math.floor(entity.x / 100)) .. ", "
            .. tostring(math.floor(entity.y / 100))
    local playerContext = playerContextFor(player)
    local speaker, second = pickSpeakers(entity)
    local conflict = speaker and pickConflictParticipant(
        player, entity, speaker) or nil
    local conflictVariant = conflict ~= nil and conflictRoll() or false
    if not conflictVariant then conflict = nil end
    local playerAddress = FlavorAddress.ResolveForNPC({
        npcID = speaker and speaker.npcID or "radio:unknown",
        npcIdentitySeed = speaker and speaker.identitySeed,
        player = player,
        playerContext = playerContext,
        playerUUID = playerContext and playerContext.characterUUID,
        state = playerContext,
    })
    local introduced = speaker ~= nil and revealRoll()
    local argumentVariant = not conflictVariant
        and second ~= nil and argumentRoll() or false
    local activeSecond = conflictVariant and conflict.speaker or second
    return {
        entityID = entity.entityID,
        kind = entity.kind,
        groupType = entity.groupType,
        archetypeID = entity.archetypeID,
        phase = phase,
        location = location,
        settlementName = tostring(entity.name or "unknown enclave"),
        playerFirstName = playerAddress.firstName,
        playerLastName = playerAddress.lastName,
        playerSurname = playerAddress.surname,
        playerFullName = playerAddress.fullName,
        playerAddressName = playerAddress.addressName,
        playerNameKnown = playerAddress.known,
        playerIsFemale = playerAddress.isFemale,
        playerNicknameID = playerAddress.nicknameID,
        npcIdentitySeed = speaker and speaker.identitySeed,
        npcFirstName = introduced and speaker.firstName or "unknown caller",
        npcLastName = introduced and speaker.lastName or "",
        npcFullName = introduced and speaker.fullName or "unknown caller",
        npc2FirstName = introduced and second and second.firstName or "",
        npc2LastName = introduced and second and second.lastName or "",
        npc2FullName = introduced and second and second.fullName or "",
        hasSecondSpeaker = activeSecond ~= nil,
        factionName = introduced and factionName(entity) or "our group",
        speakerNPCID = speaker and speaker.npcID or nil,
        secondarySpeakerNPCID = activeSecond and activeSecond.npcID or nil,
        -- Presentation-only flag: the broadcast may speak the NPC's name,
        -- but radio disclosure never grants identity.name knowledge.
        identityIntroduced = introduced,
        argumentVariant = argumentVariant,
        -- Argument names are deliberately separate from the knowledge-facing
        -- identity fields. They exist only for the named flavor exchange.
        argumentPrimaryName = argumentVariant and speaker
            and speaker.firstName or "",
        argumentSecondaryName = argumentVariant and second
            and second.firstName or "",
        -- Cross-faction conflict names are presentation-only. They are kept
        -- separate from the normal identity fields and never persisted as
        -- identity.name knowledge.
        conflictVariant = conflictVariant,
        conflictScenario = conflict and conflict.scenario or nil,
        conflictPrimaryName = conflictVariant and speaker
            and speaker.firstName or "",
        conflictSecondaryName = conflictVariant and conflict.speaker
            and conflict.speaker.firstName or "",
        conflictPrimaryFactionID = conflictVariant
            and factionID(entity) or nil,
        conflictSecondaryFactionID = conflictVariant
            and factionID(conflict.entity) or nil,
        conflictSecondaryEntityID = conflictVariant
            and conflict.entity.entityID or nil,
        conflictSecondaryKind = conflictVariant
            and conflict.entity.kind or nil,
    }
end

local function nextAmbientVariant()
    local state = Discovery.RadioAmbientState
        or { lastAiredAt = nil, hasAired = false,
            lastVariant = nil, sequence = 0 }
    Discovery.RadioAmbientState = state
    local previous = tostring(state.lastVariant or "")
    local variant = Discovery.RADIO_AMBIENT_VARIANTS[1]
    if previous == variant then
        variant = Discovery.RADIO_AMBIENT_VARIANTS[2]
    end
    state.lastVariant = variant
    state.sequence = (tonumber(state.sequence) or 0) + 1
    return variant, state.sequence
end

function Discovery.BuildAmbientTemplateContext()
    local variant, sequence = nextAmbientVariant()
    local prefix = "radio:ambient:" .. tostring(sequence)
    return {
        eventType = "ambient",
        ambientVariant = variant,
        ambientSequence = sequence,
        -- These IDs only keep the two generic radio voices consistent through
        -- the client TTS bridge. They are deliberately not NPC identities.
        speakerNPCID = prefix .. ":primary",
        secondarySpeakerNPCID = prefix .. ":secondary",
        hasSecondSpeaker = variant == "cross_talk",
    }
end

