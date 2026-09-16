local T = require "tests/support/test"
T.addPackagePaths()

local originalRequire = require
local originalCore = PsychopatzCore
local originalPNC = PNC
local originalInputClass = PsychopatzConversationLLMInput

local routed = 0
local dispatched = 0
local queued = {}
local appended = {}
local testRouter
local llmAttempts = 0

PsychopatzCore = {
    Semantics = {
        DialogueState = {
            New = function()
                return { sequence = 0 }
            end,
        },
        DialogueRouter = {
            New = function()
                return {
                    SetContext = function() end,
                    SetPolicy = function() end,
                    Process = function(_, value)
                        routed = routed + 1
                        if value == "Can you do something about this?" then
                            return {
                                accepted = true,
                                sequence = routed,
                                ir = {
                                    confidence = 0.20,
                                    diagnostics = { noMatch = true },
                                    provenance = {
                                        provider = "lua",
                                        parser = "deterministic",
                                    },
                                },
                                decision = {
                                    route = "llm_fallback",
                                    branch = "AMBIGUOUS_INPUT",
                                    response = {
                                        templateID = "semantic.ambiguous",
                                        fallback = "provider response",
                                    },
                                },
                                input = value,
                            }
                        end
                        return {
                            accepted = true,
                            sequence = routed,
                            ir = {
                                confidence = 0.96,
                                provenance = {
                                    provider = "lua",
                                    parser = "deterministic",
                                    pattern = "test.follow",
                                },
                            },
                            decision = {
                                route = "deterministic",
                                branch = "COMMAND_ACCEPTED",
                                action = "FOLLOW",
                                actionIntent = { action = "FOLLOW" },
                                response = {
                                    templateID = "semantic.test.follow",
                                    fallback = "Okay.",
                                },
                            },
                            input = value,
                        }
                    end,
                }
            end,
        },
    },
    Conversation = {
        Text = {
            Resolve = function(value)
                return value.fallback
            end,
        },
    },
}
PNC = {
    Conversation = {},
    Semantics = {
        DialogueInput = {
            Internal = {
                Now = function() return 0 end,
                ShallowContext = function()
                    return { llmEnabled = true, llmAvailable = true }
                end,
                LLMEnabled = function() return false end,
                Interactive = function(view)
                    return view and view.session
                        and view:isConversationInteractive() == true
                end,
                RouterFor = function()
                    if not testRouter then
                        testRouter = PsychopatzCore.Semantics.DialogueRouter.New()
                    end
                    return testRouter
                end,
                AppendPlayerInput = function(view, value, result)
                    return view.session:append("player", value, {
                        source = {
                            kind = "semantic",
                            channel = "input",
                            route = result.decision.route,
                            branch = result.decision.branch,
                        },
                        provenance = {
                            provider = result.ir.provenance.provider,
                            parser = result.ir.provenance.parser,
                            pattern = result.ir.provenance.pattern,
                            confidence = result.ir.confidence,
                        },
                    })
                end,
                DispatchAction = function()
                    dispatched = dispatched + 1
                    return { status = "accepted", accepted = true }
                end,
                QueueDeterministicResponse = function(view, value, result,
                    actionResult)
                    local session = view.session
                    session:queueMessage("npc", {
                        key = result.decision.response.templateID,
                        domain = "pnc.system.shared.categories",
                        fallback = result.decision.response.fallback,
                    }, {
                        source = {
                            kind = "semantic",
                            channel = "response",
                            branch = result.decision.branch,
                            action = result.decision.action,
                            actionResult = actionResult,
                            input = tostring(value or ""),
                        },
                    })
                    return true
                end,
            },
        },
        DialoguePolicy = {
            ResponseTemplates = {
                ASK_CLARIFICATION = {
                    templateID = "semantic.ask_clarification",
                    fallback = "I'm not sure what you mean.",
                },
            },
        },
        CommandAdapter = {
            Dispatch = function()
                dispatched = dispatched + 1
                return { status = "accepted", accepted = true }
            end,
        },
    },
    HoomansLLM = {
        IsBridgeEnabled = function() return false end,
        Submit = function()
            llmAttempts = llmAttempts + 1
            return false, "provider_unavailable"
        end,
    },
}
PsychopatzConversationLLMInput = {
    new = function(_, x, y, width, height, options)
        return {
            x = x,
            y = y,
            width = width,
            height = height,
            options = options,
        }
    end,
}

require = function() return true end
local Input = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticDialogueInput.lua"
)
require = originalRequire

local session = {
    characterUUID = "player-one",
    conversationID = "conversation-one",
    currentNode = { choices = { { id = "menu" } } },
    append = function(self, speaker, value, metadata)
        appended[#appended + 1] = {
            speaker = speaker,
            value = value,
            metadata = metadata,
        }
        return { messageID = "message-one" }
    end,
    queueMessage = function(self, speaker, payload, metadata)
        queued[#queued + 1] = {
            speaker = speaker,
            payload = payload,
            metadata = metadata,
        }
    end,
}
local view = {
    spec = { npcID = "npc-alice" },
    session = session,
    isConversationInteractive = function() return true end,
}

local accepted, reason = Input.Submit(view, "Follow me.")
T.equal(accepted, true, "deterministic input is accepted")
T.equal(reason, nil, "deterministic input has no rejection reason")
T.equal(routed, 1, "input is routed through semantic parsing")
T.equal(dispatched, 1, "known actions use the downstream adapter")
T.equal(appended[1].speaker, "player", "player utterance enters conversation history")
T.equal(appended[1].metadata.source.kind, "semantic",
    "history records semantic provenance")
T.equal(queued[1].speaker, "npc", "deterministic response uses the queue")
T.equal(queued[1].payload.fallback, "Okay.",
    "deterministic response has a safe fallback")

local fallbackAccepted = Input.Submit(
    view, "Can you do something about this?"
)
T.equal(fallbackAccepted, true,
    "low-confidence input remains usable after provider rejection")
T.equal(routed, 2, "low-confidence input still passes through the router")
T.equal(llmAttempts, 1, "low-confidence input attempts the optional provider")
T.equal(queued[2].payload.fallback, "I'm not sure what you mean.",
    "provider rejection uses the deterministic clarification")

local part = Input.CreatePart({ x = 1, y = 2, width = 3, height = 4 }, {})
T.equal(part.options.partID, "semanticInput", "input factory owns its part id")
T.equal(part.options.submit, Input.Submit, "input factory binds hybrid submit")

local startupState = Input.GetState(nil)
T.falsy(startupState.enabled, "input is disabled before session creation")
T.falsy(startupState.visible, "orphaned input stays hidden without a view")
local viewStartupState = Input.GetState({})
T.truthy(viewStartupState.visible,
    "full-screen input remains mounted while its session is being created")

PNC = originalPNC
PsychopatzCore = originalCore
PsychopatzConversationLLMInput = originalInputClass

T.finish("pnc_semantic_dialogue_input_smoke")
