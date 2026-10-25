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
                    Decide = function(_, ir)
                        return {
                            route = "deterministic",
                            branch = "SEMANTIC_NAVIGATION_RECEIVED",
                            response = {
                                templateID = "semantic.navigation.subject_change",
                                fallback = "All right. What did you want to talk about?",
                            },
                            ir = ir,
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
            IsConversationRootChoiceFrame = function(frame)
                return frame and frame.kind == "semantic_conversation_root_choice"
            end,
            ResolveFrameText = function(frame)
                return frame and frame.textFallback or ""
            end,
            IsNavigationFrame = function(frame)
                return frame and (
                    frame.kind == "semantic_back_click_frame"
                    or frame.kind == "semantic_group_click_frame"
                )
            end,
            FrameToIR = function(frame)
                return {
                    kind = "semantic_navigation_frame",
                    rawText = frame.textFallback,
                    normalizedText = string.lower(frame.textFallback),
                    intent = "NAVIGATE",
                    speechAct = "NAVIGATE",
                    subject = "CONVERSATION_TOPIC",
                    confidence = 1,
                    provenance = {
                        provider = "suggestion",
                        parser = "semantic_navigation_frame",
                        pattern = "subject_change",
                    },
                }
            end,
            CheckFrame = function()
                return true, "frame_allowed"
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
T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticDialogueInput_Lifecycle_Presentation.lua"
)
T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticDialogueInput_Lifecycle_Navigation.lua"
)
T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticDialogueInput_Lifecycle_Submission.lua"
)
for _, spoke in ipairs({
    "PNC/Semantics/PNC_SemanticDialogueInput_Lifecycle_Submission_Receipts.lua",
    "PNC/Semantics/PNC_SemanticDialogueInput_Lifecycle_Submission_Compound.lua",
    "PNC/Semantics/PNC_SemanticDialogueInput_Lifecycle_Submission_Single.lua",
    "PNC/Semantics/PNC_SemanticDialogueInput_Lifecycle_Submission_Gossip.lua",
}) do
    T.load(
        "ProjectHoomans",
        "client",
        spoke
    )
end
for _, spoke in ipairs({
    "PNC/Semantics/PNC_SemanticDialogueInput_FrameSupport.lua",
    "PNC/Semantics/PNC_SemanticDialogueInput_NavigationFrames.lua",
    "PNC/Semantics/PNC_SemanticDialogueInput_SubmissionFrames.lua",
    "PNC/Semantics/PNC_SemanticDialogueInput_State.lua",
}) do
    T.load(
        "ProjectHoomans",
        "client",
        spoke
    )
end
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

local unavailableProjection = {
    currentGroupID = "conversation",
    revision = 2,
    groups = {
        {
            id = "conversation",
            candidates = {},
            capabilities = {
                {
                    id = "action.go_home",
                    display = { label = "Go home." },
                    status = "unavailable_rejected",
                    enabled = false,
                    reasonKey = "test.no_base",
                    reasonFallback = "No base has been established.",
                    frame = {
                        candidateID = "action.go_home",
                        requestRevision = 2,
                    },
                },
            },
        },
    },
}
local unavailableView = {
    semanticSuggestions = unavailableProjection,
    session = {
        conversationID = "conversation-one",
        currentNodeID = "start",
    },
    spec = { npcID = "npc-alice" },
}
local unavailableRows = Input.Internal.PresentSemanticChoices(
    unavailableView, {}
)
T.equal(#unavailableRows, 1,
    "unavailable capability remains visible as a semantic row")
T.falsy(unavailableRows[1].enabled,
    "unavailable capability is disabled at the native UI boundary")
T.equal(unavailableRows[1].tooltip, "No base has been established.",
    "unavailable capability exposes its specific reason on hover")

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

local authoredActionCount = 0
local authoredResponseCount = 0
local authoredHighlightCount = 0
local rootFrame = {
    kind = "semantic_conversation_root_choice",
    candidateID = "conversation.root:menu:goodbye",
    requestRevision = 0,
    extensions = {
        origin = "conversation_root",
        rootNodeID = "menu",
        rootChoiceID = "goodbye",
        route = "conversation_root_choice",
    },
}
local authoredGoodbye = {
    id = "goodbye",
    text = "That's all. Stay safe.",
    log = true,
    enabled = true,
    action = function()
        authoredActionCount = authoredActionCount + 1
    end,
    response = function()
        authoredResponseCount = authoredResponseCount + 1
        return { fallback = "Farewell." }
    end,
    close = true,
    closeReason = "goodbye",
    onHighlightChanged = function(_, highlighted)
        if highlighted then authoredHighlightCount = authoredHighlightCount + 1 end
    end,
}
local coreView
local coreSession = {
    conversationID = "conversation-native-bridge",
    context = {},
    currentNodeID = "menu",
    choices = {},
    busy = false,
    selectionCalls = 0,
    selectChoice = function(self, choice)
        self.selectionCalls = self.selectionCalls + 1
        self.choices = {}
        if choice.log ~= false then
            self.loggedText = choice.text
        end
        choice.action(self.context, choice, self)
        self.response = type(choice.response) == "function"
            and choice.response(self.context, choice.source, self)
            or choice.response
        self.pendingClose = type(choice.close) == "function"
            and choice.close(self.context, choice.source, self) == true
            or choice.close == true
        self.pendingCloseReason = type(choice.closeReason) == "function"
            and choice.closeReason(self.context, choice.source, self)
            or choice.closeReason
        if self.pendingClose then
            coreView:close(self.pendingCloseReason)
        end
        return true
    end,
}
coreView = {
    semanticSuggestions = {
        currentGroupID = "conversation_landing",
        rootGroupID = "conversation_landing",
        revision = 0,
        groups = {
            {
                id = "conversation_landing",
                candidates = {
                    {
                        id = "conversation.root:menu:goodbye",
                        display = { label = "That's all. Stay safe." },
                        frame = rootFrame,
                    },
                },
                capabilities = {},
            },
        },
    },
    session = coreSession,
    spec = { npcID = "npc-alice", context = {} },
    isConversationInteractive = function() return true end,
    close = function(self, reason)
        self.closed = true
        self.closeReason = reason
    end,
}
coreSession.view = coreView
local coreRows = Input.Internal.PresentSemanticChoices(
    coreView, { {
        id = "goodbye",
        text = authoredGoodbye.text,
        log = authoredGoodbye.log,
        enabled = authoredGoodbye.enabled,
        action = authoredGoodbye.action,
        response = authoredGoodbye.response,
        close = authoredGoodbye.close,
        closeReason = authoredGoodbye.closeReason,
        onHighlightChanged = authoredGoodbye.onHighlightChanged,
        source = authoredGoodbye,
    } }
)
T.equal(#coreRows, 1,
    "native Core presentation keeps the authored semantic root row")
T.equal(coreRows[1].log, true,
    "semantic root row preserves authored Core logging behavior")
T.equal(coreRows[1].close, true,
    "semantic root row preserves authored close behavior")
T.equal(coreRows[1].closeReason, "goodbye",
    "semantic root row preserves authored close reason")
coreRows[1].onHighlightChanged(coreRows[1], true)
local nativeAccepted = coreSession:selectChoice(coreRows[1])
T.truthy(nativeAccepted, "native Core selection accepts the authored bridge")
T.equal(coreSession.selectionCalls, 1,
    "semantic root execution does not re-enter Session:selectChoice")
T.equal(authoredActionCount, 1,
    "authored Goodbye action executes exactly once")
T.equal(authoredResponseCount, 1,
    "authored Goodbye response is evaluated exactly once")
T.equal(coreSession.response.fallback, "Farewell.",
    "authored Goodbye response survives semantic decoration")
T.equal(authoredHighlightCount, 1,
    "authored highlight callback survives semantic decoration")
T.truthy(coreView.closed,
    "native Core close lifecycle survives semantic decoration")
T.equal(coreView.closeReason, "goodbye",
    "native Core close lifecycle keeps the authored reason")

local shortcutRoutedBefore = routed
local shortcutPart
local originalInputSubmit = Input.Submit
Input.Submit = function(actualView, value, part)
    shortcutPart = part
    return originalInputSubmit(actualView, value, part)
end
local shortcutAccepted, shortcutReason = Input.SubmitSemanticFrame(view, {
    kind = "semantic_shortcut_frame",
    candidateID = "conversation.landing:whats_up",
    textFallback = "What's up?",
    requestRevision = 0,
    intent = "QUESTION",
    speechAct = "QUESTION",
    subject = "CONVERSATION_TOPIC",
    extensions = { route = "semantic_hub", hubID = "whats_up" },
})
T.truthy(shortcutAccepted, "shortcut frame uses the canonical text submit path")
T.equal(shortcutReason, "accepted", "accepted shortcut has a stable reason")
T.equal(routed, shortcutRoutedBefore,
    "shortcut is not reparsed as a second raw text turn")
T.equal(appended[#appended].value, "What's up?",
    "shortcut submits its canonical utterance")
T.equal(shortcutPart.semanticFrame.kind, "semantic_shortcut_frame",
    "shortcut keeps its typed semantic frame through the input seam")
T.equal(shortcutPart.semanticFrame.extensions.route, "semantic_hub",
    "shortcut keeps its semantic hub route through the input seam")
Input.Submit = originalInputSubmit

    local backAppended = {}
    local backQueued = {}
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
            append = function(self, speaker, value, metadata)
                backAppended[#backAppended + 1] = {
                    speaker = speaker,
                    value = value,
                    metadata = metadata,
                }
                return { messageID = "back-message" }
            end,
            queueMessage = function(self, speaker, payload, metadata)
                backQueued[#backQueued + 1] = {
                    speaker = speaker,
                    payload = payload,
                    metadata = metadata,
                }
            end,
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
    textFallback = "Let's talk about something else.",
    requestRevision = 0,
})
T.equal(backAccepted, true, "Back navigation uses semantic exchange path")
T.equal(backReason, "accepted", "accepted Back navigation has stable reason")
T.equal(#backAppended, 1, "Back navigation records one player line")
T.equal(backAppended[1].speaker, "player",
        "Back navigation player line is attributed to player")
T.equal(#backQueued, 1, "Back navigation queues one NPC acknowledgement")
T.equal(backQueued[1].speaker, "npc",
        "Back navigation acknowledgement is attributed to NPC")
T.truthy(type(backView.session.presentedRows) == "table",
    "navigation exchange reprojection leaves native choice surface valid")
T.equal(backView.semanticSuggestions.currentGroupID,
    "conversation_landing", "Back navigation returns to landing group")

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
