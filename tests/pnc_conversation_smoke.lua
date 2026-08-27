local T = require "tests/support/test"

local SHARED = T.path("ProjectHoomans", "shared", "")
local CLIENT = T.path("ProjectHoomans", "client", "")
local COMMON_SHARED = T.path("ProjectHoomans", "common_lua", "")
local COMMON_CLIENT = T.path("ProjectHoomans", "common_client", "")
local CORE_TEXT = T.path("PsychopatzCore", "common_client",
    "PsychopatzCore/UI/Conversation/PsychopatzConversationText.lua")

T.addPackagePaths()

local opened
local registeredProvider
PNC = {
    Const = {
        MODULE = "ProjectHoomans",
        CMD_CONVERSATION_CATEGORY_REQUEST = "ConversationCategoryRequest",
        CMD_CONVERSATION_CHOICE_REQUEST = "ConversationChoiceRequest",
    },
    ContextHub = {
        RegisterProvider = function(provider) registeredProvider = provider end,
    },
}
PsychopatzCore = {
    Conversation = {
        History = { GetDay = function() return 7 end },
        Open = function(spec) opened = spec return spec end,
    },
}
getText = function(key) return key end
getTexture = function(path) return path end
getModFileReader = function(modID, path)
    local candidates = {
        T.path(tostring(modID), "common_mod", path),
        T.path(tostring(modID), "mod", path),
    }
    local file
    for _, candidate in ipairs(candidates) do
        file = io.open(candidate, "r")
        if file then break end
    end
    if not file then return nil end
    return {
        readLine = function() return file:read("*l") end,
        close = function() file:close() end,
    }
end
getGameTime = function()
    return {
        getTimeOfDay = function() return 21.5 end,
        getWorldAgeHours = function() return 189.5 end,
    }
end

T.load(CORE_TEXT)
T.load(SHARED .. "PNC/Conversation/Blocks/PNC_ConversationRegistry.lua")
T.load(SHARED .. "PNC/Conversation/Blocks/PNC_ConversationRules.lua")
T.load(SHARED .. "PNC/Conversation/Blocks/PNC_ConversationSelector.lua")
T.load(COMMON_SHARED
    .. "PNC/Conversation/Definitions/00_PNC_ConversationDefinitions.lua")
T.load(SHARED .. "PNC/Conversation/Blocks/PNC_ConversationTextLoader.lua")
T.load(CLIENT .. "PNC/Knowledge/PNC_NPCIdentityPresentation.lua")
T.load(CLIENT .. "PNC/Conversation/PNC_ConversationTime.lua")
T.load(CLIENT .. "PNC/Conversation/PNC_ConversationBackgrounds.lua")
T.load(CLIENT .. "PNC/Conversation/PNC_ConversationRelationship.lua")
T.load(CLIENT .. "PNC/UI/PNC_NPCTypePalette.lua")
PNC.Conversation.Lifecycle = {
    Create = function() return { kind = "conversation_lifecycle" } end,
    RequestCeasefire = function() return true end,
}
for _, value in ipairs({ "Dawn", "Sunrise", "Sunset", "Dusk", "Twilight" }) do
    T.load(COMMON_CLIENT .. "PNC/Conversation/PortraitBackgrounds/PNC_Background"
        .. value .. ".lua")
end
T.load(CLIENT .. "PNC/Conversation/PNC_ConversationDiary.lua")
T.load(CLIENT .. "PNC/Conversation/Blocks/ConversationComposer/PNC_ConversationComposer.lua")
T.load(CLIENT .. "PNC/Conversation/PNC_ConversationDefinition.lua")
T.load(CLIENT .. "PNC/Conversation/Debug/PNC_ConversationDebugModel.lua")
T.load(CLIENT .. "PNC/UI/Context/Providers/PNC_ContextProvider_Conversation.lua")

local Registry = PNC.Conversation.Registry
local Rules = PNC.Conversation.Rules
local Selector = PNC.Conversation.Selector
local Loader = PNC.Conversation.TextLoader

T.equal(#Registry.ListCategories(), 12, "built-in category count")
T.equal(#Registry.ListBlocks(), 49, "expanded built-in block count")
T.equal(Registry.GetFingerprint(), Registry.GetFingerprint(),
    "registry fingerprint stable")
T.equal(#Registry.ListBlocks({ includeInvalid = true }), 49,
    "built-ins all validate")

local whatsUpBlocks = Registry.ListBlocks({
    category = "projecthoomans:whats_up",
})
T.equal(#whatsUpBlocks, 9, "What's Up has three daily topics per audience")
for _, block in ipairs(whatsUpBlocks) do
    T.equal(#block.nodes, 0, "nodes are keyed rather than array-shaped")
    local nodeCount = 0
    for _ in pairs(block.nodes) do nodeCount = nodeCount + 1 end
    T.equal(nodeCount, 5, block.id .. " supports a five-node branch graph")
    T.equal(#block.nodes.opening.choices[1].outcomes, 2,
        block.id .. " uses weighted randomized outcomes")
end
T.equal(Registry.GetCategory("projecthoomans:whats_up")["repeat"].oncePerDay,
    true, "What's Up category is limited to one trigger per world day")

for _, block in ipairs(Registry.ListBlocks()) do
    local ok, errors = Loader.EnsureSource(
        block.textSource,
        Registry.CollectTextKeys(block)
    )
    T.truthy(ok, block.id .. " translation: "
        .. tostring(errors and errors[1]))
end
for _, category in ipairs(Registry.ListCategories()) do
    T.truthy(Loader.EnsureSource(category.textSource, { category.labelKey }),
        category.id .. " category translation")
end

local decoded = T.truthy(Loader.Decode(
    '{"plain":"value","escape":"line\\nnext","unicode":"\\u263a"}'
))
T.equal(decoded.escape, "line\nnext", "JSON escape")
T.truthy(decoded.unicode ~= "", "JSON unicode")
T.equal(Loader.Decode('{"duplicate":"a","duplicate":"b"}'), nil,
    "duplicate JSON key rejected")
T.equal(Loader.Decode('{"notFlat":true}'), nil,
    "non-string JSON value rejected")

local Time = PNC.Conversation.Time
T.equal(Time.Resolve(4.9), "twilight", "twilight band")
T.equal(Time.Resolve(5), "dawn", "dawn band")
T.equal(Time.Resolve(6.5), "sunrise", "sunrise band")
T.equal(Time.Resolve(12), "sunset", "sunset band")
T.equal(Time.Resolve(18), "dusk", "dusk band")
T.equal(Time.Resolve(21), "twilight", "night band")

local selectionContext = {
    worldID = "world-a",
    characterUUID = "character-a",
    npcID = "npc-a",
    worldAgeHours = 5.5,
    hour = 5.5,
    relationshipState = "FirstMeet",
    relationship = {},
    audiences = { neutral = true, shared = true },
}
local first = Selector.SelectBlock("projecthoomans:greetings", selectionContext)
local reopened = Selector.SelectBlock("projecthoomans:greetings", selectionContext)
T.equal(first.id, "projecthoomans:greeting_firstmeet_dawn",
    "relationship/time-gated greeting")
T.equal(reopened.id, first.id, "reopen does not reroll")
selectionContext.worldAgeHours = selectionContext.worldAgeHours + 24
local nextDay = Selector.SelectBlock("projecthoomans:greetings", selectionContext)
T.equal(nextDay.id, first.id, "only eligible authored block remains stable")

local dailyTopicContext = {
    worldID = "daily-topic-world",
    characterUUID = "daily-topic-character",
    npcID = "daily-topic-npc",
    worldAgeHours = 12,
    hour = 12,
    relationshipState = "Acquaintance",
    relationship = { approval = 12, respect = 8, familiarity = 12 },
    audiences = { neutral = true, shared = true },
}
local dailyTopics = {}
for day = 0, 20 do
    dailyTopicContext.worldAgeHours = day * 24 + 12
    local topic = Selector.SelectBlock(
        "projecthoomans:whats_up",
        dailyTopicContext
    )
    T.truthy(topic, "daily What's Up topic selected")
    T.equal(Selector.SelectBlock(
        "projecthoomans:whats_up",
        dailyTopicContext
    ).id, topic.id, "same day cannot reroll the daily topic")
    dailyTopics[topic.id] = true
end
local dailyTopicCount = 0
for _ in pairs(dailyTopics) do dailyTopicCount = dailyTopicCount + 1 end
T.truthy(dailyTopicCount >= 2,
    "different world days produce different deterministic topics")
local randomizedOutcomes = {}
local randomBlock = Registry.GetBlock(
    "projecthoomans:whats_up_local_activity_neutral"
)
local randomChoice = Selector.GetChoice(randomBlock, "details", "press")
for day = 0, 20 do
    dailyTopicContext.worldAgeHours = day * 24 + 12
    dailyTopicContext.historySlot = day
    local randomOutcome = Selector.SelectOutcome(
        randomBlock,
        "details",
        randomChoice,
        dailyTopicContext
    )
    randomizedOutcomes[randomOutcome.id] = true
end
T.truthy(randomizedOutcomes.open and randomizedOutcomes.guarded,
    "daily deterministic outcomes vary relationship consequences")
T.equal(Rules.CheckRepeat({ oncePerDay = true }, {
    lastUsedWorldHour = 26,
}, 47), false, "once-per-day rejects another use before midnight")
T.truthy(Rules.CheckRepeat({ oncePerDay = true }, {
    lastUsedWorldHour = 26,
}, 48), "once-per-day resets at the next world day")

local categoriesManifest = T.read(
    "ProjectHoomans", "common_lua",
    "PNC/Conversation/Definitions/00_PNC_ConversationDefinitions.lua"
)
T.equal(string.find(categoriesManifest, "RegisterBlock", 1, true), nil,
    "definition manifest remains require-only rather than monolithic")

T.truthy(Rules.EvaluateGate({
    type = "pnc:skill", actor = "player", skill = "Aiming",
    operator = ">=", value = 3,
}, { playerSkills = { Aiming = 4 } }), "skill gate")
T.truthy(Rules.EvaluateGate({
    type = "pnc:personality", actor = "npc", dimension = "bravery",
    operator = ">", value = 0.5,
}, { npcPersonality = { bravery = 0.8 } }), "personality gate")
T.truthy(Rules.EvaluateGate({
    type = "pnc:time", startHour = 21, endHour = 5,
}, { hour = 23 }), "midnight wrap gate")
T.truthy(Rules.EvaluateGate({
    type = "all",
    gates = {
        { type = "pnc:audience", value = "member" },
        { type = "not", gate = { type = "pnc:audience", value = "hostile" } },
    },
}, { audiences = { member = true } }), "composite gate")

local duplicateOK = Registry.RegisterCategory(
    "projecthoomans:whats_up",
    Registry.GetCategory("projecthoomans:whats_up")
)
T.equal(duplicateOK, false, "duplicate category rejected")
local unsafeOK = Registry.RegisterBlock("testmod:unsafe", {
    schemaVersion = 1,
    ownerModID = "testmod",
    category = "projecthoomans:whats_up",
    audiences = { "neutral" },
    textSource = {
        modID = "ProjectHoomans",
        pathPattern = "media/conversation/whats_up/neutral/{language}/basic.json",
        domain = "test.unsafe",
    },
    entryNode = "opening",
    callback = function() end,
    nodes = { opening = {} },
})
T.equal(unsafeOK, false, "inline callback quarantined")
T.truthy(Registry.ListBlocks({ includeInvalid = true })[#Registry.ListBlocks({
    includeInvalid = true,
})].errors ~= nil, "invalid block visible to debugger")

local entry = {
    id = "npc-12",
    name = "Morgan Hale",
    zombie = { live = true },
    snapshot = {
        displayName = "Morgan Hale",
        survivor = { forename = "Morgan", surname = "Hale" },
        identitySeed = 42,
        isFemale = true,
        tacticalClass = "neutral",
        relationshipCategory = "Acquaintance",
        organizationalFaction = {
            id = "crossroads", name = "Crossroads Exchange",
            role = "lead_scavenger",
            emblem = { backgroundColorID = "black", layers = {} },
        },
    },
}
local player = {
    getDisplayName = function() return "Alex Mercer" end,
    getDescriptor = function()
        return {
            getForename = function() return "Alex" end,
            getSurname = function() return "Mercer" end,
        }
    end,
}
local definition = PNC.Conversation.BuildDefinition(entry, player, "dawn")
T.equal(definition.namespace, "ProjectHoomans", "history namespace")
T.equal(definition.npcID, "npc-12", "NPC id")
T.equal(definition.backgroundID, "dawn", "background definition")
T.equal(definition.context.relationshipID, "Crossroads Exchange",
    "faction subtitle")
T.equal(definition.context.timeID, "Lead Scavenger", "role subtitle")
T.equal(definition.context.conversationRelationshipID, "Acquaintance",
    "semantic relationship")
T.equal(definition.context.playerFullName, "Alex Mercer", "player full name")
T.equal(definition.context.playerFirstName, "Alex", "player first name")
T.equal(definition.context.playerLastName, "Mercer", "player last name")
T.equal(definition.context.npcFullName, "Morgan Hale", "NPC full name")
T.equal(definition.context.npcFirstName, "Morgan", "NPC first name")
T.equal(definition.context.npcLastName, "Hale", "NPC last name")
T.equal(definition.lifecycle.kind, "conversation_lifecycle", "lifecycle")
T.truthy(#definition.nodes.greeting.choices >= 8,
    "registered category menu composed")
local askAboutChoice
for _, choice in ipairs(definition.nodes.greeting.choices) do
    if choice.id == "projecthoomans:ask_about" then
        askAboutChoice = choice
    end
    if string.sub(tostring(choice.id), 1, 15) == "projecthoomans:" then
        T.equal(
            choice.log,
            choice.id ~= "projecthoomans:ask_about",
            "ordinary categories speak; Ask About remains a silent topic browser"
        )
    end
end
T.truthy(askAboutChoice, "Ask About category is available")
local greeting = PsychopatzCore.Conversation.Text.Resolve(
    definition.nodes.greeting.npc
)
T.truthy(string.find(greeting, "dawn", 1, true)
    or string.find(greeting, "light", 1, true)
    or string.find(greeting, "early", 1, true),
    "modular greeting resolves")

local enteredNode
local routedChoices
local fakeSession = {
    spec = definition,
    queue = {},
    enterNode = function(self, nodeID)
        enteredNode = nodeID
        self.currentNode = self.spec.nodes[nodeID]
        routedChoices = self.currentNode and self.currentNode.choices or nil
    end,
    setChoices = function(_, choices) routedChoices = choices end,
    queueMessage = function(self, speaker, value)
        self.queue[#self.queue + 1] = { speaker = speaker, value = value }
    end,
    finishPending = function(self) self.finishedPending = true end,
}
local fakeView = { spec = definition, session = fakeSession }
definition.context.conversationLifecycleState = { token = "lease-test" }
PsychopatzCore.Conversation.instance = fakeView
PNC.Conversation.Authority = {
    HandleCategory = function(_, args)
        return PNC.Conversation.Composer.ReceiveBlock({
            requestID = args.requestID,
            success = true,
            npcID = args.npcID,
            categoryID = args.categoryID,
            blockID = "projecthoomans:ask_about_basic_neutral",
            nodeID = "opening",
        })
    end,
}
askAboutChoice.action()
PNC.Conversation.Composer.PumpLocalRequests()
T.equal(enteredNode, "block:opening", "Ask About opens its topic node")
T.equal(#routedChoices, 2, "Ask About exposes authored topic choices")
T.equal(routedChoices[1].id, "background", "first Ask About topic")
T.equal(routedChoices[2].id, "skills", "second Ask About topic")
definition.context.pendingConversationRequest = "choice:return-to-root"
T.truthy(PNC.Conversation.Composer.ReceiveOutcome({
    requestID = "choice:return-to-root",
    success = true,
    npcID = "npc-12",
    blockID = "projecthoomans:ask_about_basic_neutral",
    nodeID = "opening",
    choiceID = "background",
    outcomeID = "reply",
    responseKey = "response.background",
    nextNodeID = "$root",
    close = false,
}), "client accepts a menu-return outcome")
T.equal(fakeSession.pendingNext, "menu",
    "reserved root route maps back to the category menu")
T.equal(definition.nodes.menu.npc, nil,
    "returning to the menu does not repeat greeting dialogue")
T.equal(fakeSession.pendingClose, false,
    "menu-return outcome leaves the GUI open")
PsychopatzCore.Conversation.instance = nil

local memberAskNode = PNC.Conversation.Composer.BuildBlockNode(
    Registry.GetBlock("projecthoomans:ask_about_basic_member"),
    "opening",
    definition.context.conversationBlockContext
)
T.equal(
    PsychopatzCore.Conversation.Text.Resolve(memberAskNode.npc),
    "Go ahead, Alex. What do you want to ask about?",
    "dialogue name placeholders resolve"
)

local giftMessages = {}
local relationshipRefreshes = 0
fakeSession.currentNodeID = "block:gift"
fakeSession.append = function(_, speaker, value)
    giftMessages[#giftMessages + 1] = {
        speaker = speaker,
        value = value,
    }
end
definition.context.conversationBlockContext.activeConversationBlockID =
    "projecthoomans:needs_basic_neutral"
PNC.Client = {
    RequestConversationRelationship = function()
        relationshipRefreshes = relationshipRefreshes + 1
        return true
    end,
}
PsychopatzCore.Conversation.instance = fakeView
T.truthy(PNC.Conversation.Composer.ReceiveGiftResult({
    success = true,
    npcId = "npc-12",
    itemTypes = { "Base.Katana" },
    giftReplyKey = "gift.received.equipment",
    relationshipDelta = { approval = 0, respect = 2, familiarity = 0.5 },
}), "gift result accepted")
T.equal(giftMessages[1].speaker, "player", "gift offer is a player line")
T.equal(
    PsychopatzCore.Conversation.Text.Resolve(giftMessages[1].value),
    "Here's a Katana.",
    "gift offer names and formats the item"
)
T.equal(giftMessages[2].speaker, "npc", "gift response is an NPC line")
T.equal(relationshipRefreshes, 1, "gift refreshes the live relationship panel")
T.truthy(PNC.Conversation.Diary.Get("npc-12")[1],
    "gift is recorded in the interaction diary")
giftMessages = {}
T.truthy(PNC.Conversation.Composer.ReceiveGiftResult({
    success = true,
    npcId = "npc-12",
    itemTypes = { "Base.WaterBottleFull", "Base.Bandage" },
    giftEffect = { kind = "medical" },
}), "gift result without an optional reply key is accepted")
T.truthy(#giftMessages == 2, "gift still appends offer and reply without reply key")
local formattedGift = PsychopatzCore.Conversation.Text.Resolve(
    giftMessages[1].value
)
T.truthy(string.find(formattedGift, "Water Bottle Full", 1, true),
    "gift offer includes the current water item")
T.truthy(string.find(formattedGift, "Bandage", 1, true),
    "gift offer includes the current bandage item")
PsychopatzCore.Conversation.instance = nil

local previewRequirement
PsychopatzCore.Conversation.instance = {
    spec = { npcID = "npc-12" },
    extensionParts = {
        relationship = {
            setRequirement = function(_, value)
                previewRequirement = value
            end,
        },
    },
}
T.truthy(
    PNC.Conversation.Relationship.SetPreviewRequirement(
        "npc-12", "recruit"
    ),
    "recruit preview requirement accepted"
)
T.equal(previewRequirement, "recruit", "recruit uses the threshold graph")
PsychopatzCore.Conversation.instance = nil

PNC.Network = { ClientState = {
    playerContext = {
        characterUUID = "character-alex",
        forename = "Alex",
        surname = "Mercer",
        displayName = "Alex Mercer",
    },
    npcPresentations = {
        ["npc-unknown"] = { state = "unknown", canAskName = true },
    },
} }
local unknownDefinition = PNC.Conversation.BuildDefinition({
    id = "npc-unknown",
    snapshot = {
        displayName = "Hidden Name",
        survivor = { forename = "Hidden", surname = "Name" },
        tacticalClass = "neutral",
        relationshipCategory = "FirstMeet",
    },
}, player, "dawn")
T.equal(unknownDefinition.context.npcFullName, "Stranger",
    "unknown NPC full name is hidden")
T.equal(unknownDefinition.context.npcFirstName, "Stranger",
    "unknown NPC first name is hidden")
T.equal(unknownDefinition.context.npcLastName, "Stranger",
    "unknown NPC last name is hidden")
T.equal(unknownDefinition.context.playerFullName, "Stranger",
    "player name is hidden from an unintroduced NPC")

PNC.Network.ClientState.npcPresentations["npc-daily"] = {
    state = "known",
    canAskName = false,
    displayName = "Daily NPC",
}
local dailyDefinition = PNC.Conversation.BuildDefinition({
    id = "npc-daily",
    snapshot = {
        displayName = "Daily NPC",
        survivor = { forename = "Daily", surname = "NPC" },
        tacticalClass = "neutral",
        relationshipCategory = "Acquaintance",
    },
}, player, "dawn")
local dailySession = {
    queue = {},
    currentNodeID = "menu",
    currentNode = dailyDefinition.nodes.menu,
    queueMessage = function(self, speaker, value)
        self.queue[#self.queue + 1] = { speaker = speaker, value = value }
    end,
    setChoices = function() end,
    finishPending = function() end,
}
dailyDefinition.context.pendingConversationRequest = "daily-outcome"
PsychopatzCore.Conversation.instance = {
    spec = dailyDefinition,
    session = dailySession,
}
T.truthy(PNC.Conversation.Composer.ReceiveOutcome({
    requestID = "daily-outcome",
    success = true,
    npcID = "npc-daily",
    blockID = "projecthoomans:whats_up_local_activity_neutral",
    nodeID = "followup",
    choiceID = "wrap_up",
    outcomeID = "open",
    responseKey = "response.wrap_up.open",
    nextNodeID = "$root",
    close = false,
}), "client accepts completed daily topic")
local dailyCategoryVisible = false
for _, choiceValue in ipairs(dailyDefinition.nodes.menu.choices or {}) do
    if choiceValue.id == "projecthoomans:whats_up" then
        dailyCategoryVisible = true
    end
end
T.equal(dailyCategoryVisible, false,
    "completed daily topic disappears from the live category menu")
T.truthy(PNC.Network.ClientState.conversationHistory["npc-daily"]
    ["category:projecthoomans:whats_up"],
    "client remembers the authoritative daily use for the active session")
PNC.Client.CanUseDebug = function() return true end
local openedDebugContext
PNC.ConversationDebugUI = {
    Open = function(context)
        openedDebugContext = context
        return true
    end,
}
local debugDailyMenu = PNC.Conversation.Composer.BuildMenuNode(
    dailyDefinition.context.conversationBlockContext,
    dailyDefinition.context.conversationMenuOptions
)
local debugDailyLabel
local debugChoice
for _, choiceValue in ipairs(debugDailyMenu.choices or {}) do
    if choiceValue.id == "projecthoomans:whats_up" then
        debugDailyLabel = PsychopatzCore.Conversation.Text.Resolve(
            choiceValue.text
        )
    elseif choiceValue.id == "show_debug_text" then
        debugChoice = choiceValue
    end
end
T.equal(debugDailyLabel, nil,
    "debug does not expose unavailable topics in the response channel")
T.truthy(debugChoice, "debug exposes a single debug-text choice")
T.equal(debugChoice.log, false, "debug-text choice does not enter the transcript")
T.equal(debugChoice.next, "menu", "debug-text choice returns to the menu")
debugChoice.action()
T.equal(openedDebugContext, dailyDefinition.context.conversationBlockContext,
    "debug-text choice opens the debugger with the live conversation context")
PNC.ConversationDebugUI = nil
PsychopatzCore.Conversation.instance = nil
PNC.Network = nil

local relationshipEffects = Registry.effectHandlers["pnc:relationship"]
T.truthy(relationshipEffects.validate({
    npcID = "npc-12", playerEntityKey = "player:alex",
}, { approval = 2, respect = -1, familiarity = 1 }),
    "canonical conversation relationship deltas validate")
local moraleValid = relationshipEffects.validate({
    npcID = "npc-12", playerEntityKey = "player:alex",
}, { morale = 1 })
T.equal(moraleValid, false, "conversation morale points are rejected")
local attitudeValid = relationshipEffects.validate({
    npcID = "npc-12", playerEntityKey = "player:alex",
}, { admire = 1 })
T.equal(attitudeValid, false, "derived attitude points are rejected")
local preview = relationshipEffects.simulate({}, {
    approval = 2, respect = 1, familiarity = 3,
})
T.equal(preview.relationship.approval, 2, "approval delta preview")
T.equal(preview.relationship.respect, 1, "respect delta preview")
T.equal(preview.relationship.familiarity, 3, "familiarity delta preview")
T.equal(preview.relationship.morale, nil, "morale is not a conversation axis")

local debugContext = PNC.ConversationDebugModel.DefaultContext()
local before = debugContext.relationship.familiarity
local sandboxDefinition = T.truthy(PNC.ConversationDebugModel.BuildSandboxDefinition(
    "projecthoomans:whats_up_local_activity_neutral",
    debugContext
))
T.equal(sandboxDefinition.persistHistory, false,
    "GUI sandbox conversation history is non-persistent")
T.equal(sandboxDefinition.start,
    "sandbox:category:projecthoomans:whats_up",
    "GUI sandbox opens the selected block's registry category")
T.truthy(sandboxDefinition.nodes["sandbox:categories"],
    "GUI sandbox exposes the complete category browser")
local browsedBlockCount = 0
for nodeID, node in pairs(sandboxDefinition.nodes) do
    if string.sub(nodeID, 1, 17) == "sandbox:category:" then
        for _, choice in ipairs(node.choices or {}) do
            if string.sub(tostring(choice.id), 1, 15) == "projecthoomans:" then
                browsedBlockCount = browsedBlockCount + 1
            end
        end
    end
end
T.equal(browsedBlockCount, #Registry.ListBlocks(),
    "GUI sandbox lists every registered conversation block")
local sandboxOpeningID =
    "sandbox:block:projecthoomans:whats_up_local_activity_neutral:opening"
T.equal(#sandboxDefinition.nodes[sandboxOpeningID].choices, 3,
    "GUI sandbox exposes authored choices plus browser navigation")
local sandboxRelationshipUpdate
local sandboxSession = {
    view = { extensionParts = { relationship = {
        setRelationship = function(_, value)
            sandboxRelationshipUpdate = value
        end,
    } } },
}
local sandboxChoice = sandboxDefinition.nodes[sandboxOpeningID].choices[1]
sandboxChoice.action(nil, nil, sandboxSession)
T.truthy(sandboxChoice.response(), "GUI sandbox resolves an NPC response")
T.equal(sandboxChoice.next(),
    "sandbox:block:projecthoomans:whats_up_local_activity_neutral:details",
    "sandbox follows the authored multi-node branch")
T.equal(sandboxDefinition.context.relationship.familiarity, before + 1,
    "GUI sandbox updates only its cloned relationship")
T.equal(debugContext.relationship.familiarity, before,
    "GUI sandbox leaves debugger source context unchanged")
T.equal(sandboxRelationshipUpdate.familiarity, before + 1,
    "GUI sandbox refreshes the real relationship panel")
local sandboxView = T.truthy(PNC.ConversationDebugModel.OpenSandbox(
    "projecthoomans:ask_about_basic_neutral",
    debugContext
))
T.equal(sandboxView.start,
    "sandbox:category:projecthoomans:ask_about",
    "sandbox execution opens the actual GUI registry browser")

local refreshedSpec
definition.context.conversationLifecycleState = { token = "lease-persist" }
definition.context.pendingConversationRequest = "category:pending"
definition.context.activeConversationBlockID =
    "projecthoomans:ask_about_basic_neutral"
PsychopatzCore.Conversation.instance = {
    spec = definition,
    refreshConversationSpec = function(self, value)
        refreshedSpec = value
        self.spec = value
        return true
    end,
}
PNC.Network = { ClientState = {
    playerContext = {
        characterUUID = "character-alex",
        forename = "Alex",
        surname = "Mercer",
        displayName = "Alex Mercer",
    },
    npcKnowledge = {
        ["npc-12"] = {
            npcID = "npc-12",
            categories = { { descriptors = { {
                descriptorID = "identity.name",
                value = "Morgan Hale",
                status = "confirmed",
            } } } },
        },
    },
    npcPresentations = {
        ["npc-12"] = { state = "unknown", canAskName = true },
    },
} }
T.truthy(PNC.Conversation.ReceiveKnowledgeSnapshot({ npcID = "npc-12" }),
    "identity refresh updates the active conversation")
T.equal(refreshedSpec.context.conversationLifecycleState.token, "lease-persist",
    "identity refresh preserves the conversation lease")
T.equal(refreshedSpec.context.pendingConversationRequest, "category:pending",
    "identity refresh preserves an in-flight category request")
T.truthy(refreshedSpec.nodes["block:opening"],
    "identity refresh rebuilds the active authored block")
T.equal(refreshedSpec.context.npcFullName, "Morgan Hale",
    "persisted knowledge wins over a stale unknown presentation")
for _, choice in ipairs(refreshedSpec.nodes.greeting.choices or {}) do
    T.truthy(choice.id ~= "ask_name",
        "persisted identity does not offer Ask Name again")
end
PNC.Network = nil
PsychopatzCore.Conversation.instance = nil

local hostile = PNC.Conversation.BuildDefinition({
    id = "hostile", name = "Hostile",
    snapshot = { tacticalClass = "hostile", hostility = { attackPlayers = true } },
}, {}, "twilight")
T.equal(hostile.context.allowHostileParley, true, "hostile parley context")
T.equal(hostile.nodes.greeting.choices[1].id, "ceasefire",
    "hostile block exposes ceasefire")

local factionWarOnly = PNC.Conversation.BuildDefinition({
    id = "faction-war-only", name = "Faction War Only",
    snapshot = {
        tacticalClass = "hostile",
        hostility = { attackPlayers = false, attackNPCs = true },
    },
}, {}, "twilight")
T.equal(factionWarOnly.context.allowHostileParley, false,
    "NPC-only faction war does not bleed into player hostility")

local incompleteReplica = PNC.Conversation.BuildDefinition({
    id = "incomplete-replica", name = "Incomplete Replica",
    snapshot = { tacticalClass = "hostile" },
}, {}, "twilight")
T.equal(incompleteReplica.context.allowHostileParley, false,
    "missing MP hostility data fails closed")

local sandbox = T.truthy(PNC.ConversationDebugModel.ExecuteSandbox(
    "projecthoomans:whats_up_local_activity_neutral",
    "opening", "detail", debugContext
))
T.equal(sandbox.persisted, false, "sandbox does not persist")
T.equal(sandbox.networked, false, "sandbox does not network")
T.equal(debugContext.relationship.familiarity, before,
    "sandbox does not mutate input")
T.equal(sandbox.after.relationship.familiarity, before + 1,
    "sandbox previews relationship delta")

T.truthy(registeredProvider and registeredProvider.id == "conversation",
    "Talk context provider registered")
local option
registeredProvider.addOptions({
    addOption = function(_, label, target, callback)
        option = { label = label, callback = callback }
        return option
    end,
}, entry, {})
T.truthy(option, "Talk option created")
option.callback()
T.equal(opened.npcID, "npc-12", "Talk opens selected NPC")

local ui = T.read("ProjectHoomans", "common_lua", "Translate/EN/UI.json")
T.equal(string.find(ui, "UI_PNC_Conversation_", 1, true), nil,
    "conversation strings removed from UI.json")
T.equal(string.find(ui, "UI_PNC_Greeting_", 1, true), nil,
    "greeting strings removed from UI.json")
T.finish("pnc_conversation_smoke")

T.finish("pnc_conversation_smoke")
