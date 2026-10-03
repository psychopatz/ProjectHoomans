local Entries = PNC.NameplateEntries
local ClientState = PNC.Network.ClientState
local Presentation = PNC.NameplatePresentation
local DisplaySettings = PNC.NameplateDisplaySettings

local function nameplateFont()
    if DisplaySettings and DisplaySettings.GetNameplateFont then
        return DisplaySettings.GetNameplateFont()
    end
    return Presentation.Fonts.name
end

local function rounded(value)
    value = tonumber(value) or 0
    if value < 0 then
        return math.ceil(value * 10 - 0.5) / 10
    end
    return math.floor(value * 10 + 0.5) / 10
end

local function signed(value)
    value = rounded(value)
    return (value > 0 and "+" or "") .. tostring(value)
end

local function factionDebugLines(snapshot, settings)
    if not settings
        or settings.showFactionDebug ~= true
        or not PNC.FactionDebugOverlay
        or not PNC.FactionDebugOverlay.GetNPCDiagnostic
    then
        return "", "", "", "", "", nil, nil, nil
    end
    local value =
        PNC.FactionDebugOverlay.GetNPCDiagnostic(snapshot.id)
    if not value then
        return "FACTION waiting for server diagnostic",
            "", "", "", "", "warning", "neutral", nil
    end
    local faction = value.factionName
        or value.factionID or "unaffiliated"
    local first = "FACTION " .. tostring(faction)
        .. " [" .. tostring(value.archetypeID or "-") .. "]"
        .. " " .. tostring(value.role or "-")
        .. "/" .. tostring(value.rank or "-")
    local second = "PLAYER relation="
        .. tostring(value.relationState or "unknown")
        .. " war=" .. tostring(value.atWarWithPlayer == true)
        .. " intent=" .. tostring(value.intent or "observe")
        .. " attack=" .. tostring(value.attackAllowed == true)
        .. " (" .. tostring(value.intentReason or "-") .. ")"
    local target = value.target
    local third = "TACTICAL "
        .. tostring(value.tacticalClass or "neutral")
        .. " P/N/Z="
        .. tostring(value.attackPlayers == true) .. "/"
        .. tostring(value.attackNPCs == true) .. "/"
        .. tostring(value.attackZombies == true)
        .. " order=" .. tostring(value.orderKind or "-")
        .. " job=" .. tostring(value.activeJob or "-")
        .. " target=" .. tostring(
            target and (
                tostring(target.kind or "?")
                    .. ":" .. tostring(target.id or "-")
            ) or "none"
        )
    local tone = value.attackAllowed == true and "danger"
        or value.commandable == true and "success"
        or value.atWarWithPlayer == true and "warning"
        or "neutral"
    local relationship = value.relationship or {}
    local fourth = "REL player A="
        .. signed(relationship.approval)
        .. " R=" .. signed(relationship.respect)
        .. " F=" .. tostring(
            rounded(relationship.familiarity)
        )
        .. " state=" .. tostring(
            relationship.state or "unknown"
        )
        .. " rev=" .. tostring(
            tonumber(relationship.revision) or 0
        )
        .. " morale=" .. signed(value.morale)
    local relationshipTone =
        (tonumber(relationship.approval) or 0) < 0
            and "danger"
        or relationship.state == "friend" and "success"
        or relationship.state == "enemy" and "danger"
        or relationship.state == "rival" and "warning"
        or "neutral"
    local change
    local changeCount
    if PNC.FactionDebugOverlay.GetRelationshipChange then
        change, changeCount =
            PNC.FactionDebugOverlay.GetRelationshipChange(
                snapshot.id
            )
    end
    local fifth = ""
    local changeTone
    if change then
        local changeType = tostring(
            change.memoryType
                or change.kind
                or "relationship_changed"
        )
        fifth = "CHANGE " .. changeType
            .. " [" .. tostring(
                change.kind or "relationship_changed"
            ) .. "]"
            .. " dA=" .. signed(change.approvalDelta)
            .. " dR=" .. signed(change.respectDelta)
            .. " dF=" .. signed(change.familiarityDelta)
            .. " dM=" .. signed(change.moraleDelta)
        if change.stateBefore ~= change.stateAfter then
            fifth = fifth .. " "
                .. tostring(change.stateBefore or "unknown")
                .. ">" .. tostring(
                    change.stateAfter or "unknown"
                )
        end
        if (tonumber(changeCount) or 0) > 1 then
            fifth = fifth .. " x"
                .. tostring(changeCount)
        end
        if change.knowledgeSource then
            fifth = fifth .. " src="
                .. tostring(change.knowledgeSource)
        end
        local net = (tonumber(change.approvalDelta) or 0)
            + (tonumber(change.respectDelta) or 0)
            + (tonumber(change.moraleDelta) or 0)
        changeTone = net < 0 and "danger"
            or net > 0 and "success"
            or "warning"
    end
    return first, second, third, fourth, fifth,
        tone, relationshipTone, changeTone
end

Entries.BuildFactionDebugLines = factionDebugLines

local function communityDebugLines(snapshot, settings)
    if not settings
        or settings.showCommunityDebug ~= true
        or not PNC.CommunityDebugOverlay
        or not PNC.CommunityDebugOverlay.GetNPCDiagnostic
    then
        return "", "", "neutral"
    end
    local value =
        PNC.CommunityDebugOverlay.GetNPCDiagnostic(snapshot.id)
    if not value then
        return "COMMUNITY waiting for server diagnostic",
            "", "warning"
    end
    if not value.communityID then
        return "COMMUNITY none | faction="
            .. tostring(value.factionID or "unaffiliated"),
            "LOCATION "
                .. tostring(math.floor(value.x or 0))
                .. "," .. tostring(math.floor(value.y or 0))
                .. "," .. tostring(math.floor(value.z or 0)),
            "neutral"
    end
    local snapshotValue = ClientState.communityDebug
        and ClientState.communityDebug.communities or {}
    local community
    for _, item in ipairs(snapshotValue) do
        if item.id == value.communityID then
            community = item
            break
        end
    end
    local first = "COMMUNITY "
        .. tostring(value.communityName or value.communityID)
        .. " role=" .. tostring(value.communityRole)
        .. " " .. tostring(
            community and community.mode or "-"
        )
        .. "/" .. tostring(
            community and community.status or "-"
        )
    local second = "HOME distance="
        .. tostring(rounded(value.distanceFromHome))
        .. " inside=" .. tostring(value.insideHome == true)
        .. " population="
        .. tostring(
            community and community.currentPopulation or 0
        )
        .. "/" .. tostring(
            community and community.populationCapacity or 0
        )
        .. " security=" .. tostring(
            community and community.security or 0
        )
        .. " morale=" .. signed(
            community and community.morale or 0
        )
        .. " rev=" .. tostring(
            community and community.revision or 0
        )
    return first, second,
        value.insideHome == true and "success" or "warning"
end

Entries.BuildCommunityDebugLines = communityDebugLines
Entries._NameplateFont = nameplateFont
