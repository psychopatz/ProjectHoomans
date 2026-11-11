-- Project Hoomans Semantic Pack & Action Provider Adapter
-- Registers Hoomans social dialogue blocks, concepts, and capability-gated action providers
-- with PsychopatzCore Semantics.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Pack = {}
PNC.Semantics.CoreSemanticPack = Pack

Pack.PACK_ID = "pack.projecthoomans.social_core"
Pack.VERSION = 1

function Pack.Register(core)
    core = core or PsychopatzCore
    if not core or not core.Semantics
        or type(core.Semantics.RegisterPack) ~= "function"
    then
        return nil, "core_semantics_unavailable"
    end

    local spec = {
        id = Pack.PACK_ID,
        ownerModID = "ProjectHoomans",
        version = Pack.VERSION,
        capabilitiesRequired = { "hoomans.social" },
        concepts = {
            { id = "hoomans.concept.companion", domain = "social", aliases = { "companion", "follower" } },
            { id = "hoomans.concept.command", domain = "command", aliases = { "order", "task", "instruction" } },
            { id = "hoomans.concept.settlement", domain = "social", aliases = { "settlement", "home", "colony" } },
            { id = "hoomans.concept.wellbeing", domain = "social", aliases = { "health", "feeling", "morale", "how are you" } },
            { id = "hoomans.concept.gift", domain = "social", aliases = { "gift", "present", "offering" } },
            { id = "hoomans.concept.follow", domain = "command", aliases = { "follow", "follow me", "come with me" } },
            { id = "hoomans.concept.recruit", domain = "social", aliases = { "join me", "join us", "recruit" } },
            { id = "hoomans.concept.camp", domain = "command", aliases = { "make camp", "camp", "rest here" } },
        },
        speechActs = {
            { id = "RECRUIT", intent = "RECRUIT", polarity = "positive", tone = "friendly" },
            { id = "COMMAND", intent = "COMMAND", polarity = "neutral", tone = "direct" },
            { id = "DISMISS", intent = "DISMISS", polarity = "neutral", tone = "calm" },
            { id = "GIFT", intent = "GIFT", polarity = "positive", tone = "generous" },
            { id = "ASK_WELLBEING", intent = "ASK_WELLBEING", polarity = "neutral", tone = "caring" },
            { id = "CAMP", intent = "CAMP", polarity = "neutral", tone = "practical" },
        },
        patterns = {
            {
                id = "hoomans.pattern.recruit",
                intent = "RECRUIT",
                priority = 10,
                match = { { concept = "hoomans.concept.recruit" } },
                emit = { intent = "RECRUIT", speechAct = "RECRUIT" },
            },
            {
                id = "hoomans.pattern.follow",
                intent = "COMMAND",
                priority = 10,
                match = { { concept = "hoomans.concept.follow" } },
                emit = { intent = "COMMAND", command = "follow", speechAct = "COMMAND" },
            },
            {
                id = "hoomans.pattern.camp",
                intent = "CAMP",
                priority = 10,
                match = { { concept = "hoomans.concept.camp" } },
                emit = { intent = "CAMP", speechAct = "CAMP" },
            },
            {
                id = "hoomans.pattern.wellbeing",
                intent = "ASK_WELLBEING",
                priority = 5,
                match = { { concept = "hoomans.concept.wellbeing" } },
                emit = { intent = "ASK_WELLBEING", speechAct = "ASK_WELLBEING" },
            },
        },
        dialogueBlocks = {
            {
                id = "hoomans_block_greeting_friendly",
                category = "GREETING",
                priority = 20,
                gates = {
                    { field = "relationship.approval", op = ">=", value = 30 },
                },
                entryNode = "opening",
                textKey = "conversation.content.semantic.flow.greeting.opening.friendly.warm.01",
                nodes = {
                    opening = {
                        textKey = "conversation.content.semantic.flow.greeting.opening.friendly.warm.01",
                        choices = {},
                    },
                },
            },
            {
                id = "hoomans_block_greeting_neutral",
                category = "GREETING",
                priority = 10,
                gates = {
                    { field = "relationship.approval", op = ">=", value = -20 },
                },
                entryNode = "opening",
                textKey = "conversation.content.semantic.flow.greeting.opening.default.neutral.01",
                nodes = {
                    opening = {
                        textKey = "conversation.content.semantic.flow.greeting.opening.default.neutral.01",
                        choices = {},
                    },
                },
            },
            {
                id = "hoomans_block_greeting_wary",
                category = "GREETING",
                priority = 15,
                gates = {
                    { field = "relationship.approval", op = "<", value = -20 },
                },
                entryNode = "opening",
                textKey = "conversation.content.semantic.flow.greeting.opening.default.guarded.01",
                nodes = {
                    opening = {
                        textKey = "conversation.content.semantic.flow.greeting.opening.default.guarded.01",
                        choices = {},
                    },
                },
            },
            {
                id = "hoomans_block_wellbeing_good",
                category = "WELLBEING",
                priority = 10,
                gates = {
                    { field = "relationship.approval", op = ">=", value = 20 },
                },
                entryNode = "opening",
                textKey = "conversation.content.semantic.question.wellbeing.default.warm.01",
                nodes = {
                    opening = {
                        textKey = "conversation.content.semantic.question.wellbeing.default.warm.01",
                        choices = {},
                    },
                },
            },
            {
                id = "hoomans_block_wellbeing_neutral",
                category = "WELLBEING",
                priority = 5,
                gates = {
                    { field = "relationship.approval", op = ">=", value = -20 },
                },
                entryNode = "opening",
                textKey = "conversation.content.semantic.question.wellbeing.default.neutral.01",
                nodes = {
                    opening = {
                        textKey = "conversation.content.semantic.question.wellbeing.default.neutral.01",
                        choices = {},
                    },
                },
            },
        },
        actionProviders = {
            {
                id = "hoomans.companion",
                capabilityRequired = "hoomans.companion",
                order = 20,
                collect = function(context)
                    local actions = {}
                    local isCompanion = context and context.isCompanion == true

                    if isCompanion then
                        actions[#actions + 1] = {
                            id = "hoomans.command.follow",
                            label = "Follow Me",
                            description = "Order companion to follow you.",
                            capabilityRequired = "hoomans.companion",
                            intent = "COMMAND",
                            payload = { command = "follow" },
                            order = 10,
                        }
                        actions[#actions + 1] = {
                            id = "hoomans.command.wait",
                            label = "Wait Here",
                            description = "Order companion to wait at current location.",
                            capabilityRequired = "hoomans.companion",
                            intent = "COMMAND",
                            payload = { command = "wait" },
                            order = 15,
                        }
                        actions[#actions + 1] = {
                            id = "hoomans.command.camp",
                            label = "Make Camp",
                            description = "Set up a camp site here.",
                            capabilityRequired = "hoomans.command",
                            intent = "CAMP",
                            payload = { command = "camp" },
                            order = 20,
                        }
                        actions[#actions + 1] = {
                            id = "hoomans.command.return_home",
                            label = "Return Home",
                            description = "Dismiss companion back to settlement.",
                            capabilityRequired = "hoomans.companion",
                            intent = "DISMISS",
                            payload = { command = "return_home" },
                            order = 30,
                        }
                    end
                    return actions
                end,
            },
            {
                id = "hoomans.inventory",
                capabilityRequired = "hoomans.inventory",
                order = 30,
                collect = function(context)
                    return {
                        {
                            id = "hoomans.inventory.inspect",
                            label = "Check Gear",
                            description = "Examine NPC equipment and inventory.",
                            capabilityRequired = "hoomans.inventory",
                            intent = "INSPECT_INVENTORY",
                            order = 25,
                        },
                    }
                end,
            },
            {
                id = "hoomans.social",
                capabilityRequired = "hoomans.social",
                order = 40,
                collect = function(context)
                    local actions = {}
                    local isCompanion = context and context.isCompanion == true
                    local approval = context and context.relationship and context.relationship.approval or 0

                    if not isCompanion and approval >= 25 then
                        actions[#actions + 1] = {
                            id = "hoomans.social.recruit",
                            label = "Recruit",
                            description = "Ask NPC to join as a companion.",
                            capabilityRequired = "hoomans.social",
                            intent = "RECRUIT",
                            order = 5,
                        }
                    end
                    actions[#actions + 1] = {
                        id = "hoomans.social.ask_wellbeing",
                        label = "How Are You?",
                        description = "Inquire about well-being and morale.",
                        capabilityRequired = "hoomans.social",
                        intent = "ASK_WELLBEING",
                        order = 35,
                    }
                    actions[#actions + 1] = {
                        id = "hoomans.social.gift",
                        label = "Give Gift",
                        description = "Offer an item from your inventory as a gift.",
                        capabilityRequired = "hoomans.social",
                        intent = "GIFT",
                        order = 40,
                    }
                    return actions
                end,
            },
        },
    }

    local ok, err = core.Semantics.RegisterPack(spec)
    if not ok then
        return nil, err
    end
    return true
end

-- Auto-register if PsychopatzCore is already loaded
if PsychopatzCore and PsychopatzCore.Semantics then
    Pack.Register(PsychopatzCore)
end

return Pack
