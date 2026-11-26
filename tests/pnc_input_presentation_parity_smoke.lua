local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "shared" },
    { "PsychopatzCore", "common" },
    { "PsychopatzCore", "common_client" },
})

local now = 5000
getTimeInMillis = function() return now end
getTimestampMs = function() return now end
getText = function(key) return key end
getGameTime = function()
    return { getWorldAgeHours = function() return 48 end }
end

local spoken = {}
local player = {
    getUsername = function() return "player-one" end,
    getDisplayName = function() return "Alex Survivor" end,
    Say = function(_, text) spoken[#spoken + 1] = text end,
    isFemale = function() return false end,
    getDescriptor = function()
        return {
            isFemale = function() return false end,
            getVoicePrefix = function() return "VoiceMale" end,
            getVoiceType = function() return 1 end,
            getVoicePitch = function() return 1.0 end,
        }
    end,
}
getSpecificPlayer = function() return player end
getPlayer = function() return player end
Events = {
    OnTick = { Add = function() end },
    OnKeyPressed = { Add = function() end },
}

-- ============================================================================
-- 1. InlineChat -> semantic submission -> same context/scene +
-- 2. Typed / fuzzy / clicked affordance equivalence
-- ============================================================================
do
    local submittedCalls = {}
    local closedReasons = {}
    local decidedIRs = {}

    PsychopatzCore = {
        Conversation = {
            Text = {
                Resolve = function(spec, fallback)
                    return (type(spec) == "table" and spec.fallback) or fallback or ""
                end,
            },
            CreateHeadless = function(def)
                return {
                    spec = def,
                    session = {
                        conversationID = "conv-parity-1",
                        characterUUID = "player-uuid",
                        semanticSuggestionReceipts = {},
                    },
                    isConversationInteractive = function() return true end,
                    close = function(self, reason)
                        self.closed = true
                        closedReasons[#closedReasons + 1] = reason
                    end,
                }
            end,
        },
        UI = {},
    }
    PsychopatzConversationLLMInput = {
        new = function() return {} end,
    }
    package.loaded["PsychopatzCore/Input/PsychopatzKeybinds"] = {}
    package.loaded["PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationLLMInput"] =
        PsychopatzConversationLLMInput
    package.loaded["PNC/Commands/PNC_CompanionTargetResolver"] = {
        NormalizeMode = function(m) return m or "nearest" end,
        NormalizeScope = function(s) return s or "colonists" end,
        BuildConversationEntry = function(c) return c end,
    }
    package.loaded["PNC/ConvoEngine/RuntimeFacade"] = {}

    local function makeRouter()
        local router = { state = { sequence = 4 } }
        function router:Preview(value, context)
            local lower = string.lower(tostring(value or ""))
            if lower == "follow me" then
                return {
                    accepted = true,
                    ir = {
                        intent = "COMMAND",
                        subject = "follow",
                        action = "FOLLOW_PLAYER",
                        normalizedText = "follow me",
                    },
                    decision = self:Decide({
                        intent = "COMMAND",
                        subject = "follow",
                        action = "FOLLOW_PLAYER",
                    }, context),
                    state = self.state,
                    sequence = self.state.sequence,
                }
            end
            return {
                accepted = true,
                ir = {
                    intent = "UNKNOWN",
                    subject = nil,
                    action = nil,
                    normalizedText = lower,
                },
                decision = { route = "llm_fallback", branch = "LLM_FALLBACK" },
                state = self.state,
                sequence = self.state.sequence,
            }
        end
        function router:Decide(ir)
            decidedIRs[#decidedIRs + 1] = ir
            if ir and ir.action == "FOLLOW_PLAYER" then
                return {
                    route = "deterministic",
                    branch = "COMMAND_FOLLOW",
                    action = "FOLLOW_PLAYER",
                }
            end
            if ir and ir.intent == "FAREWELL" then
                return {
                    route = "deterministic",
                    branch = "FAREWELL_ACKNOWLEDGED",
                    closeConversation = true,
                }
            end
            return { route = "llm_fallback", branch = "LLM_FALLBACK" }
        end
        return router
    end

    local sharedRouter = makeRouter()
    local auditEvents = {}

    PNC = {
        Core = { Now = function() return now end },
        CompanionTargetResolver = package.loaded["PNC/Commands/PNC_CompanionTargetResolver"],
        Conversation = {
            BuildDefinition = function(entry, p)
                return {
                    npcID = entry.id,
                    context = {
                        entry = entry,
                        player = p,
                        npcName = entry.name,
                        sceneID = "scene-parity-1",
                    },
                }
            end,
        },
        Semantics = {},
        ConvoEngine = {
            DialogueInput = {
                MAX_INPUT_LENGTH = 4000,
                Submit = function(view, value, part)
                    submittedCalls[#submittedCalls + 1] = { view = view, value = value, part = part }
                    return PNC.ConvoEngine.DialogueInput.Internal.SubmitSingle(view, value, part)
                end,
                Internal = {
                    Now = function() return now end,
                    Interactive = function() return true end,
                    RouterFor = function() return sharedRouter end,
                    ShallowContext = function(view)
                        return view and view.spec and view.spec.context or {}
                    end,
                    audit = function(name, data)
                        auditEvents[#auditEvents + 1] = { name = name, data = data }
                    end,
                    attachInteractionEnvelope = function() end,
                    ParseTurn = nil,
                    Recover = function(ir)
                        if ir and ir.normalizedText == "folow me" then
                            return {
                                intent = "COMMAND",
                                subject = "follow",
                                action = "FOLLOW_PLAYER",
                                normalizedText = "follow me",
                                confidence = 0.85,
                                provenance = { pattern = "fuzzy_follow" },
                            }
                        end
                        return nil
                    end,
                    Suggestions = {
                        FrameToIR = function(frame)
                            return {
                                intent = frame.intent or "COMMAND",
                                subject = frame.subject or "follow",
                                action = frame.action or "FOLLOW_PLAYER",
                                normalizedText = "follow me",
                            }
                        end,
                        CheckFrame = function() return true end,
                        ResolveFrameText = function(frame) return frame.utterance or "" end,
                    },
                    CommitSingleSubmission = function(view, prepared, interpretation)
                        view.lastSemanticDialogueResult = interpretation.preview
                        return true, "committed"
                    end,
                },
            },
        },
    }

    T.load("ProjectHoomans", "client", "PNC/Conversation/InlineChat/PNC_InlineChatConfig.lua")
    T.load("ProjectHoomans", "client", "PNC/Conversation/InlineChat/PNC_InlineChat.lua")
    T.load("ProjectHoomans", "client", "PNC/Conversation/InlineChat/PNC_InlineChatDiagnostics.lua")
    T.load("ProjectHoomans", "client", "PNC/Conversation/InlineChat/PNC_InlineChatTargets.lua")
    T.load("ProjectHoomans", "client", "PNC/Conversation/InlineChat/PNC_InlineChatHosts.lua")
    T.load("ProjectHoomans", "client", "PNC/Conversation/InlineChat/PNC_InlineChatSession.lua")
    T.load("ProjectHoomans", "client", "PNC/Conversation/InlineChat/PNC_InlineChatOpen.lua")
    package.loaded["PNC/ConvoEngine/Dialogue/Input_Lifecycle_Submission_Single_Commit"] = true
    T.load("ProjectHoomans", "client", "PNC/ConvoEngine/Dialogue/Input_Lifecycle_Submission_Single.lua")

    local InlineChat = PNC.Conversation.InlineChat
    local headlessHost = InlineChat.Internal.Hosts.Build({ id = "npc-1", name = "Mara Stone" }, player)
    T.truthy(headlessHost ~= nil, "InlineChat builds headless host")
    T.equal(headlessHost.inlineChat, true, "InlineChat host marked inlineChat")
    T.equal(headlessHost.spec.context.sceneID, "scene-parity-1", "InlineChat host preserves sceneID context")

    -- Full UI view sharing the same spec/context/router
    local fullView = {
        spec = headlessHost.spec,
        session = {
            conversationID = "conv-parity-1",
            characterUUID = "player-uuid",
            semanticSuggestionReceipts = {},
        },
    }

    -- Typed via InlineChat.Submit
    local okInline = InlineChat.Submit(headlessHost, "follow me")
    T.equal(okInline, true, "InlineChat.Submit accepts typed semantic input")
    T.equal(#submittedCalls, 1, "InlineChat.Submit delegates to ConvoEngine.DialogueInput.Submit")

    -- Typed via Full UI
    local okFull = PNC.ConvoEngine.DialogueInput.Submit(fullView, "follow me")
    T.equal(okFull, true, "Full UI Submit accepts identical typed input")

    -- Fuzzy/typo text via Full UI
    local okFuzzy = PNC.ConvoEngine.DialogueInput.Submit(fullView, "folow me")
    T.equal(okFuzzy, true, "Fuzzy/typo text recovers cleanly")

    -- Clicked affordance semanticFrame via InlineChat
    local okClicked = InlineChat.Submit(headlessHost, "Follow me", {
        semanticFrame = {
            kind = "semantic_click_frame",
            requestRevision = 4,
            candidateID = "cand-follow-1",
            intent = "COMMAND",
            subject = "follow",
            action = "FOLLOW_PLAYER",
            utterance = "Follow me",
        },
    })
    T.equal(okClicked, true, "Clicked affordance semanticFrame accepted")

    -- Verify all 4 converged onto the exact same canonical semantic meaning/action
    local inlineRes = headlessHost.lastSemanticDialogueResult
    local fullRes = fullView.lastSemanticDialogueResult
    T.equal(inlineRes.ir.intent, "COMMAND", "InlineChat typed intent matches")
    T.equal(inlineRes.ir.action, "FOLLOW_PLAYER", "InlineChat typed action matches")
    T.equal(inlineRes.decision.branch, "COMMAND_FOLLOW", "InlineChat typed branch matches")
    T.equal(fullRes.ir.action, "FOLLOW_PLAYER", "Full UI / fuzzy action matches")
    T.equal(fullRes.decision.branch, "COMMAND_FOLLOW", "Full UI / fuzzy branch matches")
    T.equal(#decidedIRs >= 3, true, "Typed, fuzzy, and clicked all routed through router:Decide")

    -- Verify InlineChat closes on semantic_farewell
    headlessHost.lastSemanticDialogueResult = nil
    local farewellRouter = {
        state = { sequence = 5 },
        Preview = function(self, _, context)
            local ir = { intent = "FAREWELL", subject = "farewell" }
            return {
                accepted = true,
                ir = ir,
                decision = self:Decide(ir, context),
                state = self.state,
                sequence = 5,
            }
        end,
        Decide = function()
            return {
                route = "deterministic",
                branch = "FAREWELL_ACKNOWLEDGED",
                closeConversation = true,
            }
        end,
    }
    PNC.ConvoEngine.DialogueInput.Internal.RouterFor = function() return farewellRouter end
    InlineChat.State.hosts = { headlessHost }
    InlineChat.State.host = headlessHost
    local okFarewell = InlineChat.Submit(headlessHost, "goodbye")
    T.equal(okFarewell, true, "InlineChat.Submit accepts farewell")
    T.equal(closedReasons[#closedReasons], "semantic_farewell",
        "InlineChat.Submit closes with semantic_farewell on FAREWELL_ACKNOWLEDGED")
end

-- ============================================================================
-- 3. Group input & 2/3/4-actor role binding (player + NPCs & NPC-only)
-- ============================================================================
do
    local singleSubmitCount = 0
    local memberDispatches = {}

    PsychopatzCore = {
        Semantics = {
            IR = { Clone = function(v) return v end },
        },
    }
    PNC = {
        Core = { Now = function() return now end },
        Conversation = {},
        ConvoEngine = {
            DialogueInput = {
                Internal = {},
            },
        },
    }

    for name in pairs(package.loaded) do
        if string.find(name, "PNC/Conversation/PNC_ConversationGroup", 1, true) then
            package.loaded[name] = nil
        end
    end
    local Group = T.load("ProjectHoomans", "client", "PNC/Conversation/PNC_ConversationGroup.lua")

    local function makeHost(id, name)
        return {
            spec = {
                npcID = id,
                context = { npcName = name, npcFullName = name, playerName = "Alex" },
            },
            session = {
                conversationID = "conv-" .. id,
                characterUUID = "player-uuid",
                queueMessage = function() end,
            },
            closed = false,
        }
    end

    local function makeGroupInput(decisionOverride)
        local input = { Internal = {} }
        input.Internal.SubmitSingle = function(primary, value)
            singleSubmitCount = singleSubmitCount + 1
            primary.lastSemanticDialogueResult = {
                accepted = true,
                ir = { intent = "SOCIAL", subject = "greeting", normalizedText = value, confidence = 0.9 },
                decision = decisionOverride or { route = "deterministic", branch = "GREETING" },
            }
            return true, "committed"
        end
        input.Internal.RouterFor = function()
            return {
                ProcessIR = function(_, ir)
                    return {
                        accepted = true,
                        ir = ir,
                        decision = { route = "deterministic", branch = "GREETING" },
                    }
                end,
            }
        end
        input.Internal.ShallowContext = function(h) return h.spec.context end
        input.Internal.Now = function() return now end
        input.Internal.QueueDeterministicResponse = function(host, _, _, _, opts)
            memberDispatches[#memberDispatches + 1] = opts.speakerID
            return true
        end
        return input
    end

    -- 2-actor (player + 1 NPC), 3-actor (player + 2 NPCs), 4-actor (player + 3 NPCs)
    local h1 = makeHost("npc-1", "Alice Garner")
    local h2 = makeHost("npc-2", "Bob Garner")
    local h3 = makeHost("npc-3", "Charlie Garner")
    local e1 = { id = "npc-1", name = "Alice Garner" }
    local e2 = { id = "npc-2", name = "Bob Garner" }
    local e3 = { id = "npc-3", name = "Charlie Garner" }

    -- 2-actor (player + h1)
    singleSubmitCount = 0
    memberDispatches = {}
    local g2 = Group.Create(h1, { h1 }, { e1 }, player, { dialogueInput = makeGroupInput() })
    T.equal(#g2.members, 1, "2-actor group has 1 NPC member + player")
    local ok2 = g2:Submit("hello")
    T.equal(ok2, true, "2-actor group submit succeeds")
    T.equal(singleSubmitCount, 1, "2-actor group runs SubmitSingle exactly once")

    -- 3-actor (player + h1, h2) with addressed single speaker
    singleSubmitCount = 0
    memberDispatches = {}
    local g3 = Group.Create(h1, { h1, h2 }, { e1, e2 }, player, { dialogueInput = makeGroupInput() })
    T.equal(#g3.members, 2, "3-actor group has 2 NPC members + player")
    local ok3 = g3:Submit("Bob how are you")
    T.equal(ok3, true, "3-actor group submit succeeds")
    T.equal(singleSubmitCount, 1, "3-actor group runs SubmitSingle exactly once")
    T.equal(#memberDispatches, 1, "3-actor addressed turn dispatches ONE ordinary next speaker")
    T.equal(memberDispatches[1], "npc-2", "3-actor addressed turn binds Bob (npc-2)")

    -- 4-actor (player + h1, h2, h3) & NPC-only (player = nil, 3 NPCs)
    singleSubmitCount = 0
    memberDispatches = {}
    local g4 = Group.Create(h1, { h1, h2, h3 }, { e1, e2, e3 }, nil, { dialogueInput = makeGroupInput() })
    T.equal(#g4.members, 3, "NPC-only 3-NPC / 4-actor-cap group binds 3 members")
    local ok4 = g4:Submit("Charlie check the perimeter")
    T.equal(ok4, true, "4-actor/NPC-only group submit succeeds")
    T.equal(singleSubmitCount, 1, "4-actor group runs SubmitSingle exactly once")
    T.equal(#memberDispatches, 1, "4-actor addressed turn dispatches ONE ordinary next speaker")
    T.equal(memberDispatches[1], "npc-3", "4-actor addressed turn binds Charlie (npc-3)")

    -- Guard giftOffer and llm_fallback against fanout duplication
    memberDispatches = {}
    local gGift = Group.Create(h1, { h1, h2 }, { e1, e2 }, player, {
        dialogueInput = makeGroupInput({
            route = "deterministic",
            giftOffer = { item = "Base.Bandage", recipientID = "npc-1" },
        }),
    })
    gGift:Submit("take this bandage")
    T.equal(#memberDispatches, 0, "giftOffer is guarded from multi-member fanout")

    memberDispatches = {}
    local gLlm = Group.Create(h1, { h1, h2 }, { e1, e2 }, player, {
        dialogueInput = makeGroupInput({ route = "llm_fallback" }),
    })
    gLlm:Submit("tell me a story")
    T.equal(#memberDispatches, 0, "llm_fallback is guarded from multi-member fanout")
end

-- ============================================================================
-- 4. Relationship-aware farewell close/handoff + SILENT_CLOSE_REASONS parity
-- ============================================================================
do
    local enqueued = {}
    local resolvedPools = {}
    local resolvedStyles = {}

    PsychopatzCore = {
        Conversation = {
            Text = { Resolve = function(s, f) return (type(s) == "table" and s.fallback) or f or "" end },
            SocialFlavorClient = {
                Enqueue = function(payload)
                    enqueued[#enqueued + 1] = payload
                    return true, "queued"
                end,
            },
        },
    }
    package.loaded["PsychopatzCore/Conversation/PsychopatzSocialFlavorClient"] =
        PsychopatzCore.Conversation.SocialFlavorClient
    package.loaded["PNC/Audio/PNC_PlayerSpeech"] = { Speak = function() return true end }
    package.loaded["PNC/ConvoEngine/Interaction/Lifecycle"] = {}
    package.loaded["PNC/Conversation/PNC_SemanticInteractionPresentationRegistry"] = {
        Remember = function() end,
    }
    package.loaded["PNC/ConvoEngine/Dialogue/RealizationAuthority"] = {
        Resolve = function(req)
            resolvedPools[#resolvedPools + 1] = req.poolID
            resolvedStyles[#resolvedStyles + 1] = req.context and req.context.socialStyle
            return {
                responsePlanID = req.responsePlanID,
                realizationFamily = req.realizationFamily,
                realizationID = "farewell.depart.1",
                semanticAct = "FAREWELL",
                topic = req.topic,
                fallback = "Stay safe.",
            }
        end,
    }
    package.loaded["PNC/ConvoEngine/SpeechRealization"] = {}

    PNC = {
        Core = { Now = function() return now end },
        ConvoEngine = {
            RealizationAuthority = package.loaded["PNC/ConvoEngine/Dialogue/RealizationAuthority"],
        },
        Conversation = { InlineChat = { State = {}, Internal = { Config = {}, Diagnostics = {}, Targets = {} } } },
        Network = {
            ClientState = {
                playerContext = { characterUUID = "player-uuid" },
                conversationRelationships = {},
            },
        },
        NPCIdentityPresentation = { GetName = function(v) return v.name or v.id end },
        PlayerSpeech = package.loaded["PNC/Audio/PNC_PlayerSpeech"],
    }

    local Farewell = T.load("ProjectHoomans", "client", "PNC/Conversation/PNC_ConversationFarewell.lua")
    Farewell.RollChance = function() return true end

    local silentReasons = {
        "danger", "npc_unavailable", "nameplate_fallback", "lifecycle_error",
        "replaced", "headless_closed", "conversation_opened", "conversation_handoff",
        "retargeted", "message_submitted", "conversation_interrupted",
        "bridge_disabled", "semantic_farewell", "inline_silent_close",
        "inline_group_silent_close",
    }
    for _, reason in ipairs(silentReasons) do
        local ok, res = Farewell.Schedule(
            { npcID = "npc-silent", context = { player = player, npcName = "Mara" } },
            { npcID = "npc-silent" },
            reason
        )
        T.equal(ok, false, "SILENT_CLOSE_REASON rejected by Farewell: " .. reason)
        T.equal(res, "ineligible_close", "Rejected as ineligible_close: " .. reason)
    end

    -- Relationship-aware ordinary close: family -> friendly, hostile -> withdrawn
    Farewell.Reset()
    local okFam, resFam = Farewell.Schedule(
        {
            npcID = "npc-fam",
            context = {
                player = player,
                npcName = "Mara Stone",
                entry = { id = "npc-fam", snapshot = { name = "Mara Stone" }, record = { generation = { relationshipKind = "sister" } } },
            },
        },
        { npcID = "npc-fam", token = "t1" },
        "user_closed"
    )
    T.equal(okFam, true, "Family ordinary close schedules farewell")
    T.equal(resFam, "scheduled", "Family farewell scheduled")
    T.equal(resolvedPools[1], "semantic.social.farewell.depart", "Resolves through canonical social.farewell.depart")
    T.equal(resolvedStyles[1], "friendly", "Family farewell uses friendly socialStyle")

    Farewell.Reset()
    local okHostile = Farewell.Schedule(
        {
            npcID = "npc-hostile",
            context = {
                player = player,
                npcName = "Vex",
                conversationRelationshipID = "Hostile",
                tacticalClass = "hostile",
            },
        },
        { npcID = "npc-hostile", token = "t2" },
        "closed"
    )
    T.equal(okHostile, true, "Hostile ordinary close schedules farewell")
    T.equal(resolvedStyles[#resolvedStyles], "withdrawn", "Hostile farewell uses withdrawn socialStyle")
end

-- ============================================================================
-- 5. Observer-only transient Beat vs addressed interactive Scene +
--    sceneID/threadID + TTS/VoiceGateway + PBrainZ optional fallback boundary
-- ============================================================================
do
    local receivedPayloads = {}
    local publishedVoicePackets = {}

    PNC = {
        SemanticSpeechPresentation = {
            Receive = function(payload)
                receivedPayloads[#receivedPayloads + 1] = payload
                return true, "received"
            end,
        },
        SemanticSpeechPresentationInternal = {
            Clean = function(v, fb)
                v = tostring(v or "")
                return v ~= "" and v or fb
            end,
            FirstBoolean = function(a, b)
                if a ~= nil then return a == true end
                return b == true
            end,
            PlayerUUID = function() return "player-uuid" end,
        },
        Registry = {
            GetLiveZombie = function()
                return {
                    isFemale = function() return true end,
                    getModData = function() return { PNC_UUID = "npc-1" } end,
                }
            end,
        },
        Network = { ClientState = { snapshots = {} } },
        NPCVoice = {
            GetProfile = function() return { prefix = "VoiceFemale", voiceType = 0, pitch = 1.0 } end,
        },
        PlayerVoice = {
            GetProfile = function() return nil end,
        },
        ConvoEngine = {
            DialoguePolicy = {
                ResponseTemplates = {
                    ASK_CLARIFICATION = "What did you mean by that?",
                },
            },
            DialogueInput = { Internal = {} },
            DialogueInputTrace = { RecordTurn = function() return true end },
        },
    }

    PsychopatzCore = {
        Conversation = {
            instance = {
                spec = { context = { sceneID = "scene-42", entry = { id = "npc-1" } } },
                session = { conversationID = "scene-42" },
            },
        },
        Audio = { IsPlayerSpeechEnabled = function() return false end },
        Bridge = {
            lifecycle = "READY",
            RegisterPacketChannel = function() return true end,
            SetPacketSnapshot = function() return true end,
            PublishPacket = function(_, _, pkt)
                publishedVoicePackets[#publishedVoicePackets + 1] = pkt
                return true, #publishedVoicePackets
            end,
            RegisterCommand = function() return true end,
        },
    }

    local ReceivePayload = T.load(
        "ProjectHoomans",
        "client",
        "PNC/Conversation/PNC_SemanticSpeechPresentation_Receive_Payload.lua"
    )
    local ScenePresentation = T.load(
        "ProjectHoomans",
        "client",
        "PNC/Conversation/PNC_SemanticInteractionScenePresentation.lua"
    )

    -- Transient Beat: lane="beat", threadID present, sceneID nil
    local beatPayload = PNC.SemanticSpeechPresentationInternal.BuildReceivePayload({
        eventID = "evt-beat-1",
        npcID = "npc-1",
        family = "ambient",
        eventType = "ambient_beat",
        role = "colonist",
        relationshipState = "friendly",
        relationshipTier = "friend",
        active = false,
        speaker = { fullName = "Mara Stone" },
        context = { threadID = "thread-99" },
        ambientFlavor = { text = "Quiet out here.", lane = "beat", threadID = "thread-99" },
        sourceOverrides = {},
        presentationOverrides = {},
    })
    T.equal(beatPayload.lane, "beat", "Transient beat uses lane='beat'")
    T.equal(beatPayload.threadID, "thread-99", "Transient beat preserves threadID")
    T.equal(beatPayload.sceneID, nil, "Transient beat has nil sceneID")
    T.equal(beatPayload.priority, 35, "Transient beat uses beat priority 35")

    -- Observer-only Scene packet: non-interactive / presentation-only
    local okObs = ScenePresentation.Receive({
        kind = "semantic_scene_speech",
        sceneID = "scene-42",
        eventID = "evt-scene-obs",
        speakerID = "npc-1",
        text = "Watch the gate.",
        observerOnly = true,
        audienceRole = "observer",
        sceneHandoff = { waiting = true, sceneID = "scene-42" },
        responsePlan = { id = "plan-1" },
        interaction = { kind = "prompt" },
        offerIDs = { "offer-1" },
    })
    T.equal(okObs, true, "Observer-only scene packet accepted for presentation")
    local obsMsg = receivedPayloads[1]
    T.equal(obsMsg.lane, "scene", "Observer scene uses lane='scene'")
    T.equal(obsMsg.sceneID, "scene-42", "Observer scene preserves sceneID")
    T.equal(obsMsg.presentationState.conversationUI, false, "Observer scene disables conversationUI")
    T.equal(obsMsg.interaction, nil, "Observer scene strips interactive envelope")
    T.equal(obsMsg.offerIDs, nil, "Observer scene strips player offerIDs")
    T.equal(obsMsg.context.sceneHandoff, nil, "Observer scene strips sceneHandoff")

    -- Addressed recipient Scene packet: interactive state preserved
    local okRec = ScenePresentation.Receive({
        kind = "semantic_scene_speech",
        sceneID = "scene-42",
        eventID = "evt-scene-rec",
        speakerID = "npc-1",
        text = "Can you help me?",
        observerOnly = false,
        audienceRole = "recipient",
        sceneHandoff = { waiting = true, sceneID = "scene-42" },
        responsePlan = { id = "plan-2" },
        interaction = { kind = "prompt" },
        offerIDs = { "offer-2" },
    })
    T.equal(okRec, true, "Addressed recipient scene packet accepted")
    local recMsg = receivedPayloads[2]
    T.equal(recMsg.lane, "scene", "Addressed scene uses lane='scene'")
    T.equal(recMsg.sceneID, "scene-42", "Addressed scene preserves sceneID")
    T.equal(recMsg.presentationState.conversationUI, true, "Addressed scene enables conversationUI")
    T.truthy(recMsg.context.sceneHandoff ~= nil, "Addressed scene preserves sceneHandoff")
    T.truthy(recMsg.interaction ~= nil, "Addressed scene preserves interaction")

    -- VoiceGateway TTS routing with sceneID
    T.load("PsychopatzCore", "common", "PsychopatzCore/Events/PC_EventBus.lua")
    T.load("PsychopatzCore", "common", "PsychopatzCore/Voice/PsychopatzVoiceGateway.lua")
    T.load("ProjectHoomans", "client", "PNC/Integrations/PNC_VoiceGateway.lua")
    local Message = PsychopatzCore.Conversation.Message
    Message.Publish(Message.New({
        saveUUID = "save-1",
        conversationID = "scene-42",
        sequence = 1,
        speaker = "npc",
        speakerID = "npc-1",
        speakerName = "Mara Stone",
        speakerKind = "npc",
        npcUUID = "npc-1",
        text = "Can you help me?",
        source = { lane = "scene", sceneID = "scene-42", channel = "interaction_scene" },
    }))
    T.equal(#publishedVoicePackets, 1, "VoiceGateway publishes TTS packet for scene speech")
    T.equal(publishedVoicePackets[1].speech.priority, 80, "Scene TTS priority defaults to 80")

    -- PBrainZ strictly optional: absent -> deterministic ASK_CLARIFICATION
    local Fallback = T.load(
        "ProjectHoomans",
        "client",
        "PNC/ConvoEngine/Dialogue/Input_ProviderFallback.lua"
    )
    local view = { session = {} }
    local decision = { route = "llm_fallback", branch = "LLM_FALLBACK" }
    local context = { llmAvailable = false, llmEnabled = false }
    local options = {}
    local llmUsed = Fallback.SubmitProviderFallback(
        view, "blargle", nil, { ir = { normalizedText = "blargle" } }, decision, context, options
    )
    T.equal(llmUsed, false, "Absent PBrainZ does not submit LLM fallback")
    T.equal(decision.route, "deterministic", "Absent PBrainZ falls back to deterministic route")
    T.equal(decision.branch, "ASK_CLARIFICATION", "Absent PBrainZ falls back to ASK_CLARIFICATION")
    T.equal(decision.response, "What did you mean by that?", "Absent PBrainZ uses deterministic clarification text")
end
