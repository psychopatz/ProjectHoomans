-- Build 42.20 presentation adapter for registered conversation blocks.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

if not PNC.NPCIdentityPresentation then
    require "PNC/Knowledge/PNC_NPCIdentityPresentation"
end

local Conversation = PNC.Conversation
local Time = Conversation.Time
local Relationship = Conversation.Relationship
local Lifecycle = Conversation.Lifecycle
local Composer = Conversation.Composer
local Backgrounds = Conversation.Backgrounds
local Palette = PNC.NPCTypePalette
local IdentityPresentation = PNC.NPCIdentityPresentation
local Loader = Conversation.TextLoader

local SYSTEM_SOURCE = {
    modID = "ProjectHoomans",
    pathPattern = "media/conversation/system/shared/{language}/categories.json",
    domain = "pnc.system.shared.categories",
}

local function systemText(key)
    Loader.EnsureSource(SYSTEM_SOURCE, { key })
    return PsychopatzCore.Conversation.Text.Resolve({
        key = key,
        domain = SYSTEM_SOURCE.domain,
    })
end

local function roleLabel(value)
    value = tostring(value or "")
    local output = {}
    local capitalize = true
    for index = 1, #value do
        local character = string.sub(value, index, index)
        if character == "_" then
            output[#output + 1] = " "
            capitalize = true
        else
            if capitalize then
                character = string.upper(character)
                capitalize = false
            end
            output[#output + 1] = character
        end
    end
    return table.concat(output)
end

Conversation.FormatRoleLabel = roleLabel

local function isAggressive(entry)
    local snapshot = entry and entry.snapshot or {}
    local record = entry and entry.record or {}
    local hostility = snapshot.hostility or record.hostility or {}
    return tostring(snapshot.faction or record.faction or "") == "hostile"
        and hostility.attackPlayers ~= false
end

function Conversation.RequestCeasefire(context)
    return Lifecycle and Lifecycle.RequestCeasefire
        and Lifecycle.RequestCeasefire(context) or false
end

function Conversation.HandleCeasefireResult(args)
    args = type(args) == "table" and args or {}
    Conversation.lastCeasefireResult = args
    local source = {
        modID = "ProjectHoomans",
        pathPattern = "media/conversation/greetings/hostile/{language}/parley.json",
        domain = "pnc.greetings.hostile.parley",
    }
    Conversation.TextLoader.EnsureSource(source, {
        "result.accepted", "result.rejected",
    })
    local value = PsychopatzCore.Conversation.Text.Resolve({
        key = args.ok == true and "result.accepted" or "result.rejected",
        domain = source.domain,
    })
    local player = getSpecificPlayer and getSpecificPlayer(0)
        or getPlayer and getPlayer() or nil
    if player and HaloTextHelper and HaloTextHelper.addText then
        HaloTextHelper.addText(player, value)
    end
    return args.ok == true, args.reason
end

local function factionPresentation(entry)
    local faction = IdentityPresentation.GetFaction(entry)
    if type(faction) ~= "table" then return nil end
    local name = tostring(faction.name or "")
    local role = roleLabel(faction.role or faction.rank)
    if name == "" or role == "" then return nil end
    return {
        name = name,
        role = role,
        id = faction.id,
        emblem = faction.emblem,
    }
end

local function portraitSpec(entry)
    local snapshot = entry and entry.snapshot or {}
    local record = entry and entry.record or {}
    return {
        id = entry and entry.id,
        key = table.concat({
            tostring(entry and entry.id or ""),
            tostring(snapshot.identitySeed or record.identitySeed or 1),
            tostring(snapshot.presenceRevision or 0),
        }, "|"),
        identitySeed = snapshot.identitySeed or record.identitySeed or 1,
        isFemale = snapshot.isFemale == true or record.isFemale == true,
        preferDescriptor = entry and entry.zombie == nil,
        faceOnly = true,
        appearance = snapshot.appearance or record.appearance or {},
        equipment = snapshot.equipmentSummary or record.equipment or { worn = {} },
    }
end

function Conversation.RequestKnowledgeTopic(npcID, topicID)
    if PNC.Client and PNC.Client.RequestNPCKnowledgeTopic then
        return PNC.Client.RequestNPCKnowledgeTopic(npcID, topicID)
    end
    return false
end

local function identityProjection(entry)
    local npcID = tostring(entry and entry.id or "debug-npc")
    local clientState = PNC.Network and PNC.Network.ClientState or {}
    local projection = clientState.npcPresentations
        and clientState.npcPresentations[npcID] or nil
    local state = projection and projection.state
        or (not PNC.Network and IdentityPresentation.IsNameKnown(entry)
            and "known" or "loading")
    local name = state == "known"
        and tostring(projection and projection.displayName
            or IdentityPresentation.GetName(entry))
        or state == "loading" and systemText("status.loading")
        or IdentityPresentation.UnknownName
    return state, name, projection, clientState
end

function Conversation.BuildDefinition(entry, player, forcedTime)
    local timeID = forcedTime or Time.Resolve()
    local relationshipID = Relationship.Resolve(entry, player)
    local npcID = tostring(entry and entry.id or "debug-npc")
    local identityState, name, projection, clientState = identityProjection(entry)
    local faction = factionPresentation(entry)
    local blockContext = Composer.BuildContext(
        entry, player, timeID, relationshipID
    )
    local presentationContext = {
        entry = entry,
        player = player,
        npcName = name,
        identityState = identityState,
        timeID = faction and faction.role or timeID,
        relationshipID = faction and faction.name or relationshipID,
        conversationTimeID = timeID,
        conversationRelationshipID = relationshipID,
        factionID = faction and faction.id or nil,
        factionName = faction and faction.name or nil,
        factionRole = faction and faction.role or nil,
        factionEmblem = faction and faction.emblem or nil,
        npcType = Palette.ResolveType(entry),
        allowHostileParley = isAggressive(entry),
        conversationBlockContext = blockContext,
    }
    local askNameChoice
    if identityState == "unknown" and projection and projection.canAskName == true then
        askNameChoice = {
            id = "ask_name",
            text = {
                key = "choice.ask_name",
                domain = "pnc.system.shared.categories",
            },
            action = function()
                projection.state = "loading"
                Conversation.RequestKnowledgeTopic(npcID, "identity_name")
            end,
        }
    end
    local dossierChoice = {
        id = "view_dossier",
        text = {
            key = "choice.view_dossier",
            domain = "pnc.system.shared.categories",
        },
        response = {
            key = "response.view_dossier",
            domain = "pnc.system.shared.categories",
        },
        action = function() Relationship.OpenDossier(npcID) end,
        next = "greeting",
    }
    local root = Composer.BuildRootNode(blockContext, {
        askNameChoice = askNameChoice,
        dossierChoice = dossierChoice,
        presentationContext = presentationContext,
    })
    if identityState == "loading" then
        local goodbyeChoice
        for _, choice in ipairs(root.choices or {}) do
            if choice.id == "goodbye" then goodbyeChoice = choice end
        end
        root.choices = {
            {
                id = "identity_loading",
                text = {
                    key = "status.loading",
                    domain = "pnc.system.shared.categories",
                },
                enabled = false,
            },
        }
        if goodbyeChoice then root.choices[#root.choices + 1] = goodbyeChoice end
    end
    return {
        namespace = "ProjectHoomans",
        npcID = npcID,
        characterUUID = clientState.playerContext
            and clientState.playerContext.characterUUID or "unbound",
        character = entry and entry.zombie or nil,
        portrait = portraitSpec(entry),
        backgroundID = Backgrounds.Get(timeID),
        theme = Palette.BuildConversationTheme(entry),
        context = presentationContext,
        extensionParts = {
            {
                partID = "relationship",
                factory = Conversation.CreateRelationshipPanel,
                relationship = Relationship.GetPresentation(npcID),
                visible = Relationship.IsPresentationVisible(),
                title = {
                    key = "panel.current_relation",
                    domain = "pnc.system.shared.categories",
                },
                editLabel = {
                    key = "panel.current_relation_edit",
                    domain = "pnc.system.shared.categories",
                },
            },
        },
        lifecycle = Lifecycle.Create(),
        start = "greeting",
        nodes = { greeting = root },
    }
end

function Conversation.Open(entry, player, forcedTime)
    local npcID = tostring(entry and entry.id or "debug-npc")
    local state = PNC.Network and PNC.Network.ClientState
    if state then
        state.npcPresentations = state.npcPresentations or {}
        state.npcPresentations[npcID] = { npcID = npcID, state = "loading" }
    end
    local definition = Conversation.BuildDefinition(entry, player, forcedTime)
    local view = PsychopatzCore.Conversation.Open(definition)
    Relationship.RequestPresentation(definition.npcID)
    if PNC.Client and PNC.Client.RequestNPCKnowledge then
        PNC.Client.RequestNPCKnowledge(definition.npcID)
    end
    return view
end

local function refreshForNPC(npcID)
    local view = PsychopatzCore and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.instance or nil
    if not view or tostring(npcID or "") ~= tostring(view.spec and view.spec.npcID) then
        return false
    end
    local context = view.spec and view.spec.context or {}
    if not context.entry then return false end
    local updated = Conversation.BuildDefinition(
        context.entry, context.player, context.conversationTimeID
    )
    return view.refreshConversationSpec
        and view:refreshConversationSpec(updated) == true
end

function Conversation.ReceiveKnowledgeSnapshot(snapshot)
    return snapshot and refreshForNPC(snapshot.npcID) or false
end

function Conversation.ReceiveIdentityPresentation(presentation)
    return presentation and refreshForNPC(presentation.npcID) or false
end

function Conversation.ReceiveDisclosureResult(result)
    local view = PsychopatzCore and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.instance or nil
    if not view or not result
        or tostring(result.npcID) ~= tostring(view.spec and view.spec.npcID)
    then return false end
    if result.success == true and result.responseText
        and view.session and view.session.append
    then
        view.session:append("npc", { fallback = tostring(result.responseText) })
    end
    return refreshForNPC(result.npcID)
end

return Conversation
