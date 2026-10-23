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
        DialogueSuggestions = {
            BuildGroupFrame = function(group, revision)
                return {
                    kind = "semantic_group_click_frame",
                    candidateID = "semantic.group:" .. tostring(group.id),
                    groupID = group.id,
                    requestRevision = revision,
                }
            end,
            BuildBackFrame = function(revision, fromGroupID)
                return {
                    kind = "semantic_back_click_frame",
                    candidateID = "semantic.back:" .. tostring(fromGroupID),
                    groupID = "conversation_landing",
                    fromGroupID = fromGroupID,
                    labelFallback = "Back",
                    requestRevision = revision,
                }
            end,
            IsBackFrame = function(frame)
                return frame and frame.kind == "semantic_back_click_frame"
            end,
            IsShortcutFrame = function(frame)
                return frame and frame.kind == "semantic_shortcut_frame"
            end,
            IsGroupFrame = function(frame)
                return frame and frame.kind == "semantic_group_click_frame"
            end,
            ResolveFrameText = function(frame)
                return frame and frame.textFallback or ""
            end,
        },
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
    PBrainZ = {
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
T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticDialogueInput_Trace.lua"
)
T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticDialogueInput_ProviderFallback.lua"
)
T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticDialogueInput_Lifecycle.lua"
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
T.falsy(view.session.semanticDialoguePending,
    "provider rejection retires the pending request")

local queuedBeforeProviderAcceptance = #queued
PNC.PBrainZ.Submit = function()
    llmAttempts = llmAttempts + 1
    return true
end
local providerAccepted = Input.Submit(
    view, "Can you do something about this?"
)
T.equal(providerAccepted, true, "optional provider can accept a fallback turn")
T.equal(llmAttempts, 2, "accepted fallback is submitted once")
T.equal(view.lastSemanticDialogueResult.decision.route, "llm_fallback",
    "accepted fallback keeps its pending semantic preview")
T.equal(view.session.semanticDialoguePending.rawText,
    "Can you do something about this?",
    "accepted fallback retains the bounded request text for delivery")
T.equal(#queued, queuedBeforeProviderAcceptance,
    "accepted provider turn does not also queue a local reply")
T.falsy(Input.GetState(view).enabled,
    "pending provider turn prevents duplicate UI submissions")
local duplicateAccepted, duplicateReason = Input.Submit(
    view, "Can you do something about this?"
)
T.falsy(duplicateAccepted,
    "direct duplicate submissions are rejected while a provider turn is pending")
T.equal(duplicateReason, "conversation_busy",
    "duplicate submissions keep the existing busy response contract")
T.equal(llmAttempts, 2, "a pending provider turn is never resubmitted")
T.equal(view.session.semanticDialoguePending.rawText,
    "Can you do something about this?",
    "duplicate rejection preserves the original pending request")
view.session.semanticDialoguePending = nil

local part = Input.CreatePart({ x = 1, y = 2, width = 3, height = 4 }, {})
T.equal(part.options.partID, "llmInput", "input factory owns its part id")
T.equal(part.options.submit, Input.Submit, "input factory binds hybrid submit")

local startupState = Input.GetState(nil)
T.falsy(startupState.enabled, "input is disabled before session creation")
T.falsy(startupState.visible, "orphaned input stays hidden without a view")
local viewStartupState = Input.GetState({})
T.truthy(viewStartupState.visible,
    "full-screen input remains mounted while its session is being created")

session.busy = true
local queuedTurnState = Input.GetState(view)
T.truthy(queuedTurnState.enabled,
    "local semantic input remains enabled while an NPC line is queued")
session.busy = nil

local choiceProjection = {
    currentGroupID = "conversation",
    revision = 1,
    groups = {
        {
            id = "conversation",
            candidates = {
                {
                    id = "semantic:wellbeing",
                    display = { label = "Ask about wellbeing" },
                    frame = {
                        candidateID = "semantic:wellbeing",
                        requestRevision = 1,
                    },
                },
            },
            capabilities = {
                {
                    id = "semantic:follow",
                    display = { label = "Ask them to follow" },
                    status = "eligible",
                    frame = {
                        candidateID = "semantic:follow",
                        requestRevision = 1,
                    },
                },
            },
        },
    },
}
local choiceView = {
    semanticSuggestions = choiceProjection,
    session = {
        conversationID = "conversation-one",
        currentNodeID = "start",
    },
    spec = { npcID = "npc-alice" },
}
local presentedRows = Input.Internal.PresentSemanticChoices(choiceView, {})
T.equal(#presentedRows, 2,
    "semantic projection adapts both candidate and capability rows")
T.equal(presentedRows[1].id, "semantic:wellbeing",
    "semantic candidate keeps its stable row id")
T.equal(presentedRows[2].source.semanticFrame.candidateID,
    "semantic:follow", "capability row keeps its typed click frame")

local originalSubmitSemanticFrame = Input.SubmitSemanticFrame
local submittedFrame
Input.SubmitSemanticFrame = function(actualView, frame)
    T.equal(actualView, choiceView,
        "Core semantic row action submits against its native view")
    submittedFrame = frame
    return true, "accepted"
end
local clicked = presentedRows[1].action()
T.truthy(clicked, "Core semantic row action accepts the typed frame")
T.equal(submittedFrame.candidateID, "semantic:wellbeing",
    "Core semantic row action forwards the canonical frame")
T.equal(choiceView.lastSemanticSuggestionReason, "accepted",
    "accepted semantic click records its result")

local restoredChoices = 0
PNC.Conversation = {
    Composer = {
        Internal = {
            RestoreCurrentChoices = function(actualView)
                T.equal(actualView, choiceView,
                    "rejected semantic click restores the native view")
                restoredChoices = restoredChoices + 1
                return true
            end,
        },
    },
}
Input.SubmitSemanticFrame = function()
    return false, "stale_suggestion"
end
local rejected = presentedRows[2].action()
T.falsy(rejected, "rejected Core semantic row action reports failure")
T.equal(choiceView.lastSemanticSuggestionReason, "stale_suggestion",
    "rejected semantic click records its reason")
T.equal(choiceView.lastSemanticSuggestionFailure.candidateID,
    "semantic:follow", "rejected click stores the failing candidate")
T.equal(restoredChoices, 1,
    "rejected semantic click restores the production choice surface")

local presentedWhileBusy = 0
local busyView = {
    session = {
        busy = true,
        setPresentedChoices = function()
            presentedWhileBusy = presentedWhileBusy + 1
            return true
        end,
    },
    semanticSuggestions = choiceProjection,
}
local deferredRows = Input.Internal.PresentSemanticChoices(busyView, {})
T.equal(deferredRows, nil,
    "Core presentation callback hides semantic rows while busy")
local applied, deferredReason = Input.Internal.ApplySemanticChoices(
    busyView, choiceProjection
)
T.falsy(applied, "semantic rows are deferred while Core is busy")
T.equal(deferredReason, "semantic_choices_deferred",
    "busy semantic presentation has an explicit deferred reason")
T.equal(presentedWhileBusy, 0,
    "busy Core sessions do not receive clickable semantic rows")

Input.SubmitSemanticFrame = originalSubmitSemanticFrame

local shortcutRoutedBefore = routed
local shortcutAccepted, shortcutReason = Input.SubmitSemanticFrame(view, {
    kind = "semantic_shortcut_frame",
    candidateID = "conversation.landing:whats_up",
    textFallback = "What's up?",
    requestRevision = 0,
})
T.truthy(shortcutAccepted, "shortcut frame uses the canonical text submit path")
T.equal(shortcutReason, "accepted", "accepted shortcut has a stable reason")
T.equal(routed, shortcutRoutedBefore + 1,
    "shortcut is parsed by the same semantic router as typed input")
T.equal(appended[#appended].value, "What's up?",
    "shortcut submits its canonical utterance")

local backView = {
    semanticSuggestions = {
        currentGroupID = "topic:wellbeing",
        rootGroupID = "conversation_landing",
        allowBack = true,
        revision = 0,
        groups = {
            { id = "conversation_landing", candidates = {}, capabilities = {} },
            { id = "topic:wellbeing", candidates = {}, capabilities = {} },
        },
    },
    session = {
        conversationID = "conversation-back",
        currentNodeID = "start",
        setPresentedChoices = function(self, rows)
            self.presentedRows = rows
            return true
        end,
    },
    isConversationInteractive = function() return true end,
}
local backRows = Input.Internal.PresentSemanticChoices(
    backView, backView.semanticSuggestions
)
T.equal(#backRows, 1, "nested topic exposes a Back row")
T.equal(backRows[1].text, "Back", "Back row is presented first")
local backAccepted, backReason = Input.SubmitSemanticFrame(backView, {
    kind = "semantic_back_click_frame",
    candidateID = "semantic.back:topic:wellbeing",
    groupID = "conversation_landing",
    fromGroupID = "topic:wellbeing",
    requestRevision = 0,
})
T.truthy(backAccepted, "Back returns to the production landing group")
T.equal(backReason, "accepted", "accepted Back has a stable reason")
T.equal(backView.semanticSuggestions.currentGroupID,
    "conversation_landing", "Back changes only the selected group")
T.equal(routed, shortcutRoutedBefore + 1,
    "Back does not create a semantic conversation turn")

backView.semanticSuggestions.currentGroupID = "topic:wellbeing"
backView.semanticSuggestions.allowBack = false
local disabledBackRows = Input.Internal.PresentSemanticChoices(
    backView, backView.semanticSuggestions
)
T.equal(disabledBackRows, nil,
    "required branches can disable Back through projection metadata")
backView.semanticSuggestions.allowBack = true
backView.semanticSuggestions.groups[2].allowBack = false
local disabledGroupBackRows = Input.Internal.PresentSemanticChoices(
    backView, backView.semanticSuggestions
)
T.equal(disabledGroupBackRows, nil,
    "required groups can disable Back without disabling the whole projection")

PNC = originalPNC
PsychopatzCore = originalCore
PsychopatzConversationLLMInput = originalInputClass

T.finish("pnc_semantic_dialogue_input_smoke")
