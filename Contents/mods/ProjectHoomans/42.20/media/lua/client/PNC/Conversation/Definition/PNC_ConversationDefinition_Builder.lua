-- Build the stable PsychopatzCore Conversation definition contract.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Conversation = PNC.Conversation

-- Definition rebuilds can be requested by identity/knowledge result handlers
-- before the full client composition root has completed. Load the existing
-- owners here as a guarded composition fallback, then capture their tables.
if type(Conversation.Time) ~= "table"
    or type(Conversation.Time.Resolve) ~= "function"
then
    pcall(require, "PNC/Conversation/PNC_ConversationTime")
end
if type(Conversation.TextLoader) ~= "table"
    or type(Conversation.TextLoader.EnsureSource) ~= "function"
then
    pcall(require, "PNC/Conversation/Blocks/PNC_ConversationTextLoader")
end
if type(Conversation.Backgrounds) ~= "table"
    or type(Conversation.Backgrounds.Get) ~= "function"
then
    pcall(require, "PNC/Conversation/PNC_ConversationBackgrounds")
end
if type(Conversation.Relationship) ~= "table"
    or type(Conversation.Relationship.GetPresentation) ~= "function"
    or type(Conversation.Relationship.IsPresentationVisible) ~= "function"
then
    pcall(require, "PNC/Conversation/ConversationRelationship/PNC_ConversationRelationship")
end
if type(Conversation.TalkStart) ~= "table"
    or type(Conversation.TalkStart.Project) ~= "function"
then
    pcall(require, "PNC/Conversation/PNC_ConversationTalkStart")
end
if type(Conversation.Lifecycle) ~= "table"
    or type(Conversation.Lifecycle.Create) ~= "function"
then
    pcall(require, "PNC/Conversation/PNC_ConversationLifecycle")
end
if type(Conversation.Composer) ~= "table"
    or type(Conversation.Composer.BuildContext) ~= "function"
    or type(Conversation.Composer.BuildRootNode) ~= "function"
then
    pcall(require, "PNC/Conversation/Blocks/ConversationComposer/PNC_ConversationComposer")
end
if type(PNC.NPCTypePalette) ~= "table"
    or type(PNC.NPCTypePalette.ResolveType) ~= "function"
    or type(PNC.NPCTypePalette.BuildConversationTheme) ~= "function"
then
    pcall(require, "PNC/UI/PNC_NPCTypePalette")
end

local Relationship = Conversation.Relationship
local Lifecycle = Conversation.Lifecycle
local Composer = Conversation.Composer
local Backgrounds = Conversation.Backgrounds
local Palette = PNC.NPCTypePalette
local FlavorAddress = PNC.FlavorAddress
local TalkStart = Conversation.TalkStart
    or require "PNC/Conversation/PNC_ConversationTalkStart"
local Context = require "PNC/Conversation/Definition/PNC_ConversationDefinition_Context"
local ExtensionParts = require "PNC/Conversation/Definition/PNC_ConversationDefinition_ExtensionParts"
local IdentityChoice = require "PNC/Conversation/Blocks/PNC_ConversationIdentityChoice"
local semanticInputWarningEmitted = false

if type(FlavorAddress) ~= "table"
    or type(FlavorAddress.ResolveNPCSeed) ~= "function"
then
    pcall(require, "PNC/Core/Identity/PNC_FlavorAddress")
    FlavorAddress = PNC.FlavorAddress
end

local function conversationTime()
    local time = Conversation.Time
    if type(time) == "table" and type(time.Resolve) == "function" then
        return time
    end
    pcall(require, "PNC/Conversation/PNC_ConversationTime")
    return Conversation.Time
end

local function warnSemanticInput(reason)
    if semanticInputWarningEmitted then return end
    semanticInputWarningEmitted = true
    local message = "conversation_input_unavailable reason=" .. tostring(reason)
    if PNC.Core and type(PNC.Core.LogWarn) == "function" then
        PNC.Core.LogWarn(message)
    elseif type(print) == "function" then
        print("[PNC][WARN] " .. message)
    end
end

local function semanticInputFactory()
    if type(Conversation.CreateSemanticDialogueInput) == "function" then
        return Conversation.CreateSemanticDialogueInput
    end

    -- The composition root normally installs this adapter. BuildDefinition
    -- is also called by preview/debug entry points, though, and those can
    -- arrive before the registration callback. The semantic input module is
    -- already the owner of the widget factory, so use it directly as a safe
    -- same-process fallback and then publish the canonical Conversation
    -- factory for later definitions.
    local directInput = PNC.Semantics
        and PNC.Semantics.DialogueInput or nil
    if directInput and type(directInput.CreatePart) == "function" then
        Conversation.CreateSemanticDialogueInput = function(bounds, options)
            return directInput.CreatePart(bounds, options)
        end
        return Conversation.CreateSemanticDialogueInput
    end

    -- BuildDefinition is also used by debug and preview entry points. Those
    -- callers can run before the full client composition root has completed.
    -- The Core input widget is optional in headless previews. Keep its lazy
    -- load guarded so those callers can use the base conversation input.
    require "PNC/Conversation/PNC_ConversationTime"
    require "PNC/Conversation/PNC_ConversationGroup"
    local loaded, loadError = pcall(require, "PNC/PNC_ConversationSemantics")
    local adapter = PNC.ConversationSemantics
    if not loaded or not adapter
        or type(adapter.RegisterConversation) ~= "function"
    then
        warnSemanticInput(loadError or "adapter_unavailable")
        return nil
    end
    local _, registrationReason = adapter.RegisterConversation(
        Conversation, PNC.Conversation.Group, PNC.Conversation.Time)
    if type(Conversation.CreateSemanticDialogueInput) ~= "function" then
        warnSemanticInput(registrationReason or "factory_unavailable")
        return nil
    end
    return Conversation.CreateSemanticDialogueInput
end

local function buildConversationContext(
    entry,
    player,
    timeID,
    relationshipID,
    npcID,
    talkStartProjection
)
    local identityState, name, projection, clientState, identityClaimVerified =
        Context.IdentityProjection(entry)
    local faction = Context.FactionPresentation(entry)
    local blockContext = Composer.BuildContext(
        entry,
        player,
        timeID,
        relationshipID,
        talkStartProjection
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
        identityClaimVerified = identityClaimVerified == true,
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
        npcType = talkStartProjection
            and talkStartProjection.targetType
            or Palette.ResolveType(entry),
        audience = talkStartProjection
            and talkStartProjection.audience or blockContext.audience,
        conversationAudience = talkStartProjection
            and talkStartProjection.audience
            or blockContext.conversationAudience,
        tacticalClass = talkStartProjection
            and talkStartProjection.tacticalClass
            or blockContext.tacticalClass,
        playerHostile = talkStartProjection
            and talkStartProjection.hostile or blockContext.playerHostile,
        conversationProfile = blockContext.conversationProfile,
        allowHostileParley = talkStartProjection
            and talkStartProjection.hostile or blockContext.playerHostile,
        talkStartProjection = talkStartProjection,
        talkStartRoute = talkStartProjection
            and talkStartProjection.route or nil,
        talkStartAvailability = talkStartProjection
            and talkStartProjection.availability or nil,
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
        identityClaimVerified = identityClaimVerified == true,
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
    local askNameChoice
    if contextData.identityState == "unknown" and contextData.projection
        and (contextData.projection.canAskName == true
            or contextData.projection.state == "loading")
    then
        askNameChoice = IdentityChoice.Build(
            npcID,
            contextData.projection,
            identityArguments
        )
    end
    local dossierChoice = {
        id = "view_dossier",
        log = false,
        semantic = {
            route = "conversation_root_choice",
            actionID = "view_dossier",
            groupID = "conversation_utilities",
        },
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
    presentationContext.categoryDiagnostics = blockContext.categoryDiagnostics
    local displayedChoiceIDs = {}
    for _, choice in ipairs(root.choices or {}) do
        displayedChoiceIDs[#displayedChoiceIDs + 1] = choice.id
    end
    presentationContext.displayedChoiceIDs = displayedChoiceIDs
    presentationContext.choiceSuppressionReason = nil
    return root
end

function Conversation.BuildDefinition(
    entry,
    player,
    forcedTime,
    talkStartProjection
)
    local time = conversationTime()
    local timeID = forcedTime or time.Resolve()
    local semanticFactory = semanticInputFactory()
    local projection = talkStartProjection
        or TalkStart.Project(entry, player, { source = "definition" })
    local relationshipID = projection.relationshipID
    local npcID = tostring(entry and entry.id or "debug-npc")
    local contextData = buildConversationContext(
        entry,
        player,
        timeID,
        relationshipID,
        npcID,
        projection
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
        -- Preserve Core's staged opening so the conversation presentation
        -- enters through its normal portrait/history/choice reveal sequence.
        animateOpening = true,
        -- Standard face-to-face talk uses the readable subtle treatment.
        -- Radio and walkie-talkie callers can opt into CRT with their own
        -- explicit conversation screenVariant.
        screenVariant = "subtle",
        -- Core owns the single player-facing choice surface. Semantic
        -- projections are adapted into this existing scrollable part so
        -- authored branches, contextual actions, and compatibility handlers
        -- share one interaction path.
        choicePartVisible = true,
        -- Core invokes this generic presentation seam after every normalized
        -- choice write. Hoomans supplies semantic rows when a valid
        -- projection exists; Core keeps authored choices as the fallback.
        choicePresentation = function(view, authoredChoices)
            local input = PNC.Semantics
                and PNC.Semantics.DialogueInput or nil
            local internal = input and input.Internal or nil
            if internal
                and type(internal.PresentSemanticChoices) == "function"
            then
                return internal.PresentSemanticChoices(
                    view, authoredChoices
                )
            end
            return nil
        end,
        -- Core owns native click gating. Hoomans supplies only the
        -- conversation-authority pending check so an async category/choice
        -- request cannot be clicked twice while the server reply is in flight.
        choiceInteractionGuard = function(view)
            local context = view and view.spec and view.spec.context or nil
            return type(context) ~= "table"
                or context.pendingConversationRequest == nil
        end,
        portrait = Context.PortraitSpec(entry),
        backgroundID = Backgrounds.Get(timeID),
        theme = Palette.BuildConversationTheme(entry),
        context = contextData.presentationContext,
        talkStartProjection = projection,
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
