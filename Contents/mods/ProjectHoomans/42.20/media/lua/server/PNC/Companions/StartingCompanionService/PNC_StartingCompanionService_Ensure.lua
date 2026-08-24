if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.StartingCompanions = PNC.StartingCompanions or {}
PNC.StartingCompanionServiceInternal =
    PNC.StartingCompanionServiceInternal or {}

local Starting = PNC.StartingCompanions
local H = PNC.StartingCompanionServiceInternal
local Traits = PNC.StartingCompanionTraits
local Identity = PNC.Identity
local Registry = PNC.Registry

function H.DefinitionsForState(state)
    local output = {}
    for index = 1, #Traits.DEFINITIONS do
        local spec = Traits.DEFINITIONS[index]
        if state.grants[spec.id] then output[#output + 1] = spec end
    end
    return output
end

function Starting.Ensure(player, characterUUID, at)
    if not player or not characterUUID then return false, "invalid_player" end
    local now = H.NowMs()
    if (Starting.NextRetryAt[characterUUID] or 0) > now then
        return false, "retry_throttled"
    end
    local character = PNC.PlayerCharacters.GetRegistryRecord(characterUUID)
    if not character then return false, "character_not_found" end
    local state = PNC.PlayerCharacterTypes.NormalizeStartingCompanionState(
        character.startingCompanions
    )
    local selections
    local reason
    if not state.resolved then
        selections, reason = Traits.ResolveSelections(player)
        if not selections then return false, reason or "traits_not_ready" end
        state.resolved = true
        for index = 1, #selections do
            local spec = selections[index]
            state.grants[spec.id] = {
                status = "pending",
                traitID = spec.id,
                relationshipKind = spec.relationshipKind,
                npcID = H.MakeNPCID(characterUUID, spec.id),
                selectedAt = at,
                grantedAt = 0,
                enrichmentVersion = 0,
            }
        end
        local recorded
        recorded, reason = H.UpdateState(
            characterUUID, state, "starting_companion_selection"
        )
        if not recorded then
            Starting.NextRetryAt[characterUUID] =
                now + Starting.RETRY_DELAY_MS
            return false, reason
        end
    else
        selections = H.DefinitionsForState(state)
    end
    if #selections == 0 then return false, "none" end

    local needsWork = false
    for index = 1, #selections do
        local grant = state.grants[selections[index].id]
        if not grant or grant.status ~= "granted"
            or (tonumber(grant.enrichmentVersion) or 0)
                < Starting.ENRICHMENT_VERSION
        then
            needsWork = true
            break
        end
    end
    if not needsWork then return false, "granted" end

    local granted = {}
    local firstFailure
    for index = 1, #selections do
        local spec = selections[index]
        local ok
        ok, reason = H.EnsureOne(
            player, character, state, spec, index, at
        )
        if ok then
            granted[#granted + 1] = state.grants[spec.id].npcID
        else
            firstFailure = firstFailure or reason
        end
    end
    if firstFailure then
        Starting.NextRetryAt[characterUUID] = now + Starting.RETRY_DELAY_MS
        return false, firstFailure, { npcIDs = granted }
    end
    Starting.NextRetryAt[characterUUID] = nil
    if PNC.Core and PNC.Core.LogInfo then
        PNC.Core.LogInfo("PNC starting companions ready character="
            .. tostring(characterUUID) .. " count=" .. tostring(#granted))
    end
    return true, "granted", { npcIDs = granted }
end

return Starting

