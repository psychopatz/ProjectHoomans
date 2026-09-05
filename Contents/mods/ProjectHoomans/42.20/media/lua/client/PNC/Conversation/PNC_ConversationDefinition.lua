-- Build 42.20 presentation adapter for registered conversation blocks.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

if not PNC.NPCIdentityPresentation then
    require "PNC/Knowledge/PNC_NPCIdentityPresentation"
end
require "PNC/Conversation/Blocks/PNC_ConversationIdentityChoice"

local Conversation = PNC.Conversation
local Time = Conversation.Time
local Relationship = Conversation.Relationship
local Lifecycle = Conversation.Lifecycle
local Composer = Conversation.Composer
local Backgrounds = Conversation.Backgrounds
local Palette = PNC.NPCTypePalette
local IdentityPresentation = PNC.NPCIdentityPresentation
local Loader = Conversation.TextLoader
local Registry = Conversation.Registry
local IdentityChoice = Conversation.IdentityChoice

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

local function cleanName(value)
    value = type(value) == "string" and value or nil
    if not value then return nil end
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value ~= "" and value or nil
end

local function nameParts(fullName, firstName, lastName)
    fullName = cleanName(fullName)
    firstName = cleanName(firstName)
    lastName = cleanName(lastName)
    if not firstName and fullName then
        firstName = string.match(fullName, "^(%S+)")
    end
    if not lastName and fullName then
        lastName = string.match(fullName, "^%S+%s+(.+)$")
    end
    if not fullName then
        fullName = table.concat({ firstName or "", lastName or "" }, " ")
        fullName = cleanName(fullName)
    end
    return fullName, firstName, lastName
end

local function playerIdentity(player, clientState)
    local context = clientState and clientState.playerContext or {}
    local descriptor = player and player.getDescriptor
        and player:getDescriptor() or nil
    local firstName = context.forename
        or descriptor and descriptor.getForename and descriptor:getForename()
    local lastName = context.surname
        or descriptor and descriptor.getSurname and descriptor:getSurname()
    local fullName = context.displayName
        or player and player.getDisplayName and player:getDisplayName()
    return nameParts(fullName, firstName, lastName)
end

local function npcIdentity(entry, projection, displayedName)
    local snapshot = projection and projection.snapshot
        or entry and entry.snapshot or {}
    local record = entry and entry.record or {}
    local identity = snapshot.identity or record.identity or {}
    local survivor = identity.survivor or snapshot.survivor
        or record.survivor or {}
    return nameParts(
        displayedName,
        survivor.forename or snapshot.forename or record.forename,
        survivor.surname or snapshot.surname or record.surname
    )
end

local function visibleIdentityArguments(
    entry,
    player,
    projection,
    clientState,
    npcName,
    npcKnown,
    playerKnown
)
    local stranger = systemText("identity.stranger")
    local playerFull, playerFirst, playerLast = playerIdentity(
        player, clientState
    )
    local npcFull, npcFirst, npcLast = npcIdentity(
        entry, projection, npcName
    )
    if not playerKnown then
        playerFull, playerFirst, playerLast = stranger, stranger, stranger
    end
    if not npcKnown then
        npcFull, npcFirst, npcLast = stranger, stranger, stranger
    end
    return {
        playerName = playerFull or stranger,
        playerFullName = playerFull or stranger,
        playerFirstName = playerFirst or playerFull or stranger,
        playerLastName = playerLast or "",
        playerSurname = playerLast or "",
        npcName = npcFull or stranger,
        npcFullName = npcFull or stranger,
        npcFirstName = npcFirst or npcFull or stranger,
        npcLastName = npcLast or "",
        npcSurname = npcLast or "",
    }
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
    return hostility.attackPlayers == true
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
        -- Live NPCs use IsoZombie carriers for engine animation/replication.
        -- Conversation portraits must render the descriptor-backed human
        -- preview instead of exposing that carrier's zombie appearance.
        preferDescriptor = true,
        faceOnly = true,
        appearance = snapshot.appearance or record.appearance or {},
        equipment = snapshot.equipmentSummary or record.equipment or { worn = {} },
    }
end

local function identityProjection(entry)
    local npcID = tostring(entry and entry.id or "debug-npc")
    local clientState = PNC.Network and PNC.Network.ClientState or {}
    local projection = clientState.npcPresentations
        and clientState.npcPresentations[npcID] or nil
    local learnedName = IdentityPresentation.GetFact(entry, "identity.name")
    local state = learnedName and "known" or projection and projection.state
        or (not PNC.Network and IdentityPresentation.IsNameKnown(entry)
            and "known" or "loading")
    local name = state == "known"
        and tostring(learnedName and learnedName.value
            or projection and projection.displayName
            or IdentityPresentation.GetName(entry))
        or systemText("identity.stranger")
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
    local identityArguments = visibleIdentityArguments(
        entry,
        player,
        projection,
        clientState,
        name,
        identityState == "known",
        relationshipID ~= "FirstMeet"
    )
    Composer.SetIdentityArguments(blockContext, identityArguments)
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
    for key, value in pairs(identityArguments) do
        presentationContext[key] = value
    end
    local askNameChoice
    if identityState == "unknown" and projection and projection.canAskName == true then
        askNameChoice = IdentityChoice.Build(
            npcID,
            projection,
            identityArguments
        )
    end
    local dossierChoice = {
        id = "view_dossier",
        log = false,
        text = {
            key = "choice.view_dossier",
            domain = "pnc.system.shared.categories",
            args = identityArguments,
        },
        action = function() Relationship.OpenDossier(npcID) end,
        next = "greeting",
    }
    local menuOptions = {
        askNameChoice = askNameChoice,
        dossierChoice = dossierChoice,
        presentationContext = presentationContext,
    }
    blockContext.conversationMenuOptions = menuOptions
    local root = Composer.BuildRootNode(blockContext, menuOptions)
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
            {
                partID = "llmInput",
                factory = Conversation.CreateHoomansLLMInput,
                visible = true,
                title = {
                    key = "panel.llm_input",
                    domain = "pnc.system.shared.categories",
                    fallback = "TYPE TO TALK",
                },
            },
        },
        lifecycle = Lifecycle.Create(),
        start = "greeting",
        nodes = {
            greeting = root,
            -- Returning from an authored subtopic must reveal the category
            -- selector without replaying the opening greeting in the log.
            menu = { choices = root.choices },
        },
    }
end

function Conversation.Open(entry, player, forcedTime)
    local npcID = tostring(entry and entry.id or "debug-npc")
    -- Hostile NPCs use the compact nameplate chat route. Opening the full
    -- conversation view first would create a normal scene lease and let the
    -- combat safety gate reject it before the player can type anything.
    -- Keep this handoff targeted to the selected entry so it cannot silently
    -- switch the player to the nearest unrelated NPC.
    if isAggressive(entry)
        and PNC.HoomansLLM
        and PNC.HoomansLLM.OpenInlineForTarget
        and PNC.HoomansLLM.OpenInlineForTarget(entry)
    then
        Relationship.RequestPresentation(npcID)
        if PNC.Client and PNC.Client.RequestNPCKnowledge then
            PNC.Client.RequestNPCKnowledge(npcID)
        end
        return nil
    end
    local state = PNC.Network and PNC.Network.ClientState
    if state then
        state.npcPresentations = state.npcPresentations or {}
        local current = state.npcPresentations[npcID]
        if not current or current.state ~= "known" then
            state.npcPresentations[npcID] = {
                npcID = npcID,
                state = "loading",
            }
        end
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
    local updatedContext = updated.context or {}
    for _, key in ipairs({
        "conversationLifecycleState",
        "pendingConversationRequest",
        "pendingConversationAutoChoice",
        "activeConversationBlockID",
        "lastConversationError",
    }) do
        if context[key] ~= nil then updatedContext[key] = context[key] end
    end
    updated.context = updatedContext
    updated.lifecycle = view.spec.lifecycle or updated.lifecycle
    local activeBlockID = context.activeConversationBlockID
    local activeBlock = activeBlockID and Registry.GetBlock(activeBlockID) or nil
    if activeBlock then
        Composer.AttachBlock(
            updated,
            activeBlock,
            updatedContext.conversationBlockContext
        )
    end
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
