PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Suggestions = PNC.Semantics.DialogueSuggestions
local Internal = Suggestions.Internal

local CampSite = Internal.CampSite
local copyValue = Internal.copyValue
local resolvedText = Internal.resolvedText
local normalizeCandidate = Internal.normalizeCandidate
local capabilityFrame = Internal.capabilityFrame
local companionOrderStateEligible = Internal.companionOrderStateEligible
local companionUnavailableReason = Internal.companionUnavailableReason
local campSiteCandidates = Internal.campSiteCandidates
local campCandidateTarget = Internal.campCandidateTarget
local campCandidateUsable = Internal.campCandidateUsable
local firstCampSiteCandidate = Internal.firstCampSiteCandidate
local CAMP_HERE_TEXT_KEY = Internal.CAMP_HERE_TEXT_KEY
local CAMP_CAMPFIRE_TEXT_KEY = Internal.CAMP_CAMPFIRE_TEXT_KEY
local CAMP_ROOM_TEXT_KEY = Internal.CAMP_ROOM_TEXT_KEY

local function campTargetForCandidate(candidate)
    local target = copyValue(campCandidateTarget(candidate))
    local campfire
    if type(target) ~= "table" then return nil, false end
    campfire = target.campfireID ~= nil or target.kind == "campfire"
    if campfire then
        target.kind = "camp_site"
        target.scope = target.scope or "campfire"
        target.siteScope = target.siteScope or target.scope
    end
    return target, campfire
end

local function campDisplayLabel(candidate, target, campfire)
    local label
    if campfire then return "campfire" end
    if CampSite and type(CampSite.DisplayLabel) == "function" then
        label = CampSite.DisplayLabel(target or candidate)
        if label and label ~= "" then return label end
    end
    return candidate and (candidate.label or candidate.roomName
        or candidate.roomType) or "room"
end

local function campDisplayText(candidate, target, campfire, automatic)
    local label
    local text
    if automatic then
        return resolvedText(CAMP_HERE_TEXT_KEY, "Let's camp here.")
    end
    if candidate and (candidate.utterance or candidate.displayText) then
        return candidate.utterance or candidate.displayText
    end
    label = campDisplayLabel(candidate, target, campfire)
    if campfire then
        return resolvedText(
            CAMP_CAMPFIRE_TEXT_KEY,
            "Let's camp by the campfire."
        )
    end
    text = resolvedText(
        CAMP_ROOM_TEXT_KEY,
        "Let's camp in the %1."
    )
    return string.gsub(text, "%%1", function()
        return tostring(label)
    end, 1)
end

local function appendCampCapabilityRow(
    rows, revision, context, candidate, stateEligible,
    disabledCode, disabledKey, disabledFallback, automatic
)
    local target
    local campfire
    local targetKey
    local candidateID
    local displayText
    local definition
    local frame
    local rowAvailable
    local rowStatus
    local rowReasonCode
    local rowReasonKey
    local rowReasonFallback
    if automatic then
        target = {
            kind = CampSite.KIND or "camp_site",
            scope = CampSite.SCOPES.HERE or "here",
            siteScope = CampSite.SCOPES.HERE or "here",
        }
        if campCandidateUsable(candidate) then
            local candidateTarget = campCandidateTarget(candidate)
            local hint = candidateTarget.clientHint or candidateTarget
            if type(hint) == "table" then
                target.clientHint = copyValue(hint)
            end
        end
        candidateID = "action.camp_here"
        targetKey = "auto"
    else
        target, campfire = campTargetForCandidate(candidate)
        if not target then return false end
        if campfire then
            targetKey = target.campfireID
        elseif target.siteID ~= nil and target.roomID ~= nil then
            targetKey = tostring(target.siteID) .. "|"
                .. tostring(target.roomID)
        else
            targetKey = target.roomID or target.siteID
        end
        candidateID = candidate.id
            or ("action.camp_site:" .. tostring(targetKey or "unknown"))
    end
    displayText = campDisplayText(candidate, target, campfire, automatic)
    rowAvailable = stateEligible and campCandidateUsable(candidate)
    if rowAvailable then
        rowStatus = "eligible"
        rowReasonCode = "valid_client_camp_site_hint"
    elseif automatic and not campCandidateUsable(candidate)
        and stateEligible
    then
        rowStatus = "unavailable_no_camp_site"
        rowReasonCode = "no_camp_site"
        rowReasonKey = "UI_PNC_Conversation_Suggestion_NoCampSite_Tooltip"
        rowReasonFallback = "No valid camp location is currently available."
    else
        rowStatus = "unavailable_companion"
        rowReasonCode = disabledCode
        rowReasonKey = disabledKey
        rowReasonFallback = disabledFallback
    end
    definition = {
        id = candidateID,
        topic = "movement",
        groupID = Suggestions.COMPANION_CAMP_GROUP_ID,
        labelFallback = displayText,
        utteranceFallback = displayText,
        target = target,
        slots = {
            npcID = { kind = "conversation_actor", ref = "npc" },
        },
    }
    frame = capabilityFrame("CAMP", definition, revision)
    if not frame then return false end
    rows[#rows + 1] = {
        id = candidateID,
        topic = "movement",
        groupID = Suggestions.COMPANION_CAMP_GROUP_ID,
        rank = #rows + 1,
        enabled = rowAvailable,
        status = rowStatus,
        reasonCode = rowReasonCode,
        reasonKey = rowReasonKey,
        reasonFallback = rowReasonFallback,
        frame = frame,
        semanticFrame = frame,
        source = {
            groupID = Suggestions.COMPANION_CAMP_GROUP_ID,
            kind = automatic and "automatic_camp_capability"
                or "permitted_capability",
        },
        text = displayText,
        display = {
            label = displayText,
            utterance = displayText,
            visibility = "player",
        },
        visibility = "player",
        eligibility = {
            status = rowAvailable and "allowed" or "rejected",
            allowed = rowAvailable,
            reasonCode = rowReasonCode,
            reason = rowReasonCode,
            reasonKey = rowReasonKey,
            reasonFallback = rowReasonFallback,
        },
        capability = {
            id = candidateID,
            action = "CAMP",
            source = automatic and "automatic_camp_site"
                or "production_camp_site",
            status = rowStatus,
            groupID = Suggestions.COMPANION_CAMP_GROUP_ID,
            selectionMode = automatic and "auto" or "specific",
            targetKey = targetKey,
        },
    }
    rows[#rows] = normalizeCandidate(
        rows[#rows], "permitted_capability", #rows
    )
    return true
end

local function appendCampSiteCapabilityRows(rows, revision, context, ir)
    local candidates = campSiteCandidates(context)
    if type(candidates) ~= "table" then return end
    local stateEligible = companionOrderStateEligible(context)
    local unavailable = not stateEligible
        and companionUnavailableReason(context) or nil
    local disabledCode = unavailable and unavailable.code
        or "companion_unavailable"
    local disabledKey = unavailable and unavailable.key
        or "UI_PNC_Conversation_Suggestion_CompanionUnavailable_Tooltip"
    local disabledFallback = unavailable and unavailable.fallback
        or "Unavailable because this companion cannot receive orders right now."

    local seen = {}
    local count = 0

    -- The generic action is intentionally first.  It carries the best
    -- observed primitive as a hint, while the target remains scope="here" so
    -- the normal camp resolver owns the final room/campfire choice.
    appendCampCapabilityRow(
        rows, revision, context, firstCampSiteCandidate(candidates),
        stateEligible,
        disabledCode, disabledKey, disabledFallback, true
    )

    for _, candidate in ipairs(candidates) do
        if count >= Suggestions.MAX_CAMP_DESTINATIONS then break end
        if campCandidateUsable(candidate) then
            local target, campfire = campTargetForCandidate(candidate)
            local targetKey
            if campfire then targetKey = target and target.campfireID
            elseif target and target.siteID ~= nil and target.roomID ~= nil then
                targetKey = tostring(target.siteID) .. "|"
                    .. tostring(target.roomID)
            else targetKey = target and (target.roomID or target.siteID) end
            local candidateID = candidate.id
                or ("action.camp_site:" .. tostring(targetKey or count + 1))
            local dedupeKey = tostring(candidateID) .. "|"
                .. tostring(targetKey or "")
            if targetKey ~= nil and not seen[dedupeKey] then
                seen[dedupeKey] = true
                appendCampCapabilityRow(
                    rows, revision, context, candidate, stateEligible,
                    disabledCode, disabledKey, disabledFallback, false
                )
                count = count + 1
            end
        end
    end
end


Internal.appendCampSiteCapabilityRows = appendCampSiteCapabilityRows

return Suggestions
