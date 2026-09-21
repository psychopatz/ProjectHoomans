-- Server-side canonical name lookup and identity response projection.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Presentation = {}

local function clean(value)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
end

function Presentation.Clean(value)
    return clean(value)
end

function Presentation.PlayerName(player, context)
    local record = context and context.characterUUID
        and PNC.PlayerCharacters
        and PNC.PlayerCharacters.GetRegistryRecord
        and PNC.PlayerCharacters.GetRegistryRecord(context.characterUUID)
        or nil
    local name = clean(record and record.displayName)
    if name == "" then
        name = clean(record and record.identity
            and record.identity.displayName)
    end
    if record then
        local forename = clean(record.forename)
        local surname = clean(record.surname)
        if forename ~= "" or surname ~= "" then
            local composed = forename
            if surname ~= "" then
                composed = composed .. (composed ~= "" and " " or "")
                    .. surname
            end
            name = composed
        end
    end
    if name == "" and player and player.getDescriptor then
        local descriptor = player:getDescriptor()
        local forename = descriptor and descriptor.getForename
            and clean(descriptor:getForename()) or ""
        local surname = descriptor and descriptor.getSurname
            and clean(descriptor:getSurname()) or ""
        if forename ~= "" or surname ~= "" then
            name = forename
            if surname ~= "" then
                name = name .. (name ~= "" and " " or "") .. surname
            end
        end
    end
    if name == "" and player and player.getDisplayName then
        name = clean(player:getDisplayName())
    end
    return clean(name)
end

local function npcName(record)
    local identity = record and record.identity
    return clean(identity and identity.displayName
        or record and (record.displayName or record.name))
end

local function firstName(value)
    value = clean(value)
    return string.match(value, "^(%S+)") or value
end

local function localized(key, fallback, ...)
    local translation = PNC.Translation
    if translation and type(translation.TrFormat) == "function" then
        return translation.TrFormat(key, fallback, ...)
    end
    return fallback
end

function Presentation.BuildResponse(
    record, truthful, introduction, playerName, disclosureSucceeded
)
    if truthful then
        local name = npcName(record)
        local playerFirst = firstName(playerName)
        if name == "" and introduction then
            local introduced = clean(introduction)
            local extracted = string.match(introduced, "^[Ii]'m%s+(.+)%.$")
            name = clean(extracted or "")
        end
        if disclosureSucceeded == true and name ~= ""
            and playerFirst ~= ""
        then
            local fallback = "Okay " .. playerFirst
                .. ", nice to meet you. I'm " .. name .. "."
            local key = "UI_PNC_Conversation_Semantic_IdentityExchangeConfirmed"
            return localized(key, fallback, playerFirst, name), key,
                { playerFirst, name }
        end
        if playerFirst ~= "" then
            local fallback = "Okay " .. playerFirst
                .. ", nice to meet you."
            local key = "UI_PNC_Conversation_Semantic_IdentityExchangeConfirmedUnnamed"
            return localized(key, fallback, playerFirst), key,
                { playerFirst }
        end
        return localized(
            "UI_PNC_Conversation_ToolReply_AskNameUnnamed_1",
            "Nice to meet you."
        ), "UI_PNC_Conversation_ToolReply_AskNameUnnamed_1", nil
    end
    local key = "UI_PNC_Conversation_Identity_FalseName"
    return localized(key, "That isn't your exact name. Don't lie to me."),
        key, nil
end

function Presentation.ResolveClaim(
    player, request, record, truthful, verifiedPlayerName
)
    local introduction
    local disclosureSucceeded = false
    if truthful and clean(verifiedPlayerName) ~= "" then
        local knowledge = PNC.NPCKnowledgeAPI
        if knowledge and type(knowledge.DiscloseForPlayer) == "function" then
            local disclosure = knowledge.DiscloseForPlayer(player, {
                npcID = request.npcID,
                topicID = "identity_name",
                requestID = request.requestID .. ":identity_name",
                conversationToken = request.args.conversationToken
                    or request.args.token,
                origin = "semantic_identity_claim",
                verifiedIdentityClaim = true,
            })
            disclosureSucceeded = type(disclosure) == "table"
                and disclosure.accepted == true
        end
        if disclosureSucceeded then
            local commands = PNC.PlayerKnowledgeCommands
            local internal = commands and commands.Internal or nil
            if internal and type(internal.IntroductionText) == "function" then
                introduction = internal.IntroductionText(request.npcID)
            end
        end
    end
    return Presentation.BuildResponse(
        record,
        truthful,
        introduction,
        verifiedPlayerName,
        disclosureSucceeded
    )
end

return Presentation
