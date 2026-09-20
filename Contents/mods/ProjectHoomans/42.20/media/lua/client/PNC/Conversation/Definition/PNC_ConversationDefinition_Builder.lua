-- Build the stable PsychopatzCore Conversation definition contract.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Conversation = PNC.Conversation
local Time = Conversation.Time
local Relationship = Conversation.Relationship
local Lifecycle = Conversation.Lifecycle
local Composer = Conversation.Composer
local Backgrounds = Conversation.Backgrounds
local Palette = PNC.NPCTypePalette
local FlavorAddress = PNC.FlavorAddress
local Context = require "PNC/Conversation/Definition/PNC_ConversationDefinition_Context"
local ExtensionParts = require "PNC/Conversation/Definition/PNC_ConversationDefinition_ExtensionParts"

local function semanticInputFactory()
    if type(Conversation.CreateSemanticDialogueInput) == "function" then
        return Conversation.CreateSemanticDialogueInput
    end

    -- BuildDefinition is also used by debug and preview entry points. Those
    -- callers can run before the full client composition root has completed.
    -- The Core input widget is optional in headless previews. Keep its lazy
    -- load guarded so those callers can use the base conversation input.
    require "PNC/Conversation/PNC_ConversationTime"
    require "PNC/Conversation/PNC_ConversationGroup"
    local loaded = pcall(require, "PNC/PNC_ConversationSemantics")
    local adapter = PNC.ConversationSemantics
    if not loaded or not adapter
        or type(adapter.RegisterConversation) ~= "function"
    then
        return nil
    end
    adapter.RegisterConversation(
        Conversation, PNC.Conversation.Group, PNC.Conversation.Time)
    return type(Conversation.CreateSemanticDialogueInput) == "function"
        and Conversation.CreateSemanticDialogueInput or nil
end

local function buildConversationContext(entry, player, timeID, relationshipID, npcID)
    local identityState, name, projection, clientState = Context.IdentityProjection(entry)
    local faction = Context.FactionPresentation(entry)
    local blockContext = Composer.BuildContext(
        entry, player, timeID, relationshipID
    )
    local identityArguments = Context.VisibleIdentityArguments(
        entry,
        player,
        projection,
        clientState,
        name,
        identityState == "known",
        npcID
    )
    Composer.SetIdentityArguments(blockContext, identityArguments)
    blockContext.conversationTopic = "greeting"
    local presentationContext = {
        entry = entry,
        player = player,
        npcName = name,
        identityState = identityState,
        -- Transport state is deliberately separate from what the player is
        -- allowed to see. A pending snapshot must not erase the social menu.
        identityRequestState = projection and (
            projection.requestState
            or projection.state == "loading" and "loading"
            or projection.state == "error" and "error"
        ) or nil,
        timeID = faction and faction.role or timeID,
        relationshipID = faction and faction.name or relationshipID,
        conversationTimeID = timeID,
        conversationRelationshipID = relationshipID,
        conversationTopic = "greeting",
        factionID = faction and faction.id or nil,
        factionName = faction and faction.name or nil,
        factionRole = faction and faction.role or nil,
        factionEmblem = faction and faction.emblem or nil,
        npcType = Palette.ResolveType(entry),
        audience = blockContext.audience,
        conversationAudience = blockContext.conversationAudience,
        tacticalClass = blockContext.tacticalClass,
        playerHostile = blockContext.playerHostile,
        conversationProfile = blockContext.conversationProfile,
        allowHostileParley = blockContext.playerHostile,
        settlementVisit = blockContext.settlementVisit,
        ambientVisitPreview = blockContext.ambientVisitPreview,
        conversationBlockContext = blockContext,
        npcIdentitySeed = FlavorAddress.ResolveNPCSeed(entry, npcID),
    }
    for key, value in pairs(identityArguments) do
        presentationContext[key] = value
    end

    return {
        identityState = identityState,
        projection = projection,
        clientState = clientState,
        identityArguments = identityArguments,
        blockContext = blockContext,
        presentationContext = presentationContext,
    }
end

local function buildConversationMenu(contextData, npcID)
    local identityArguments = contextData.identityArguments
    local blockContext = contextData.blockContext
    local presentationContext = contextData.presentationContext
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
        dossierChoice = dossierChoice,
        presentationContext = presentationContext,
    }
    blockContext.conversationMenuOptions = menuOptions
    local root = Composer.BuildRootNode(blockContext, menuOptions)
    presentationContext.categoryDiagnostics = blockContext.categoryDiagnostics
    local displayedChoiceIDs = {}
    for _, choice in ipairs(root.choices or {}) do
        displayedChoiceIDs[#displayedChoiceIDs + 1] = choice.id
    end
    presentationContext.displayedChoiceIDs = displayedChoiceIDs
    presentationContext.choiceSuppressionReason = nil
    return root
end

function Conversation.BuildDefinition(entry, player, forcedTime)
    local timeID = forcedTime or Time.Resolve()
    local semanticFactory = semanticInputFactory()
    local relationshipID = Relationship.Resolve(entry, player)
    local npcID = tostring(entry and entry.id or "debug-npc")
    local contextData = buildConversationContext(
        entry, player, timeID, relationshipID, npcID
    )
    local root = buildConversationMenu(contextData, npcID)
    return {
        namespace = "ProjectHoomans",
        npcID = npcID,
        characterUUID = contextData.clientState.playerContext
            and contextData.clientState.playerContext.characterUUID or "unbound",
        -- Hoomans conversation text is session-local. The Lua NPC memory
        -- projection stores only bounded current-day topic codes on close.
        persistHistory = false,
        activeMessageLimit = 64,
        character = entry and entry.zombie or nil,
        -- Standard face-to-face talk uses the readable subtle treatment.
        -- Radio and walkie-talkie callers can opt into CRT with their own
        -- explicit conversation screenVariant.
        screenVariant = "subtle",
        portrait = Context.PortraitSpec(entry),
        backgroundID = Backgrounds.Get(timeID),
        theme = Palette.BuildConversationTheme(entry),
        context = contextData.presentationContext,
        extensionParts = ExtensionParts.Build(
            npcID, semanticFactory
        ),
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

return Conversation
