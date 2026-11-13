-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_semantic_responses",
        ["id"] = "semantic.accept",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "accept",
            ["sourceId"] = "semantic.accept",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/accept.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "semantic",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["metadata"] = {
                ["responsePoolID"] = "semantic.accept",
                ["sourceProfile"] = "conversation.source.project.hoomans.common.interaction.seed.7a0582ab2e",
            },
            ["response"] = {
                ["act"] = "ACCEPT",
                ["variants"] = {
                    {
                        ["id"] = "semantic.accept.dataset.pending_started",
                        ["metadata"] = {
                            ["fallback"] = "Okay, I'll get started.",
                            ["priority"] = 1,
                            ["templateID"] = "semantic.accept.dataset.pending_started",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Okay, I'll get started.",
                            },
                            ["TL"] = {
                                "Okay, I'll get started.",
                            },
                        },
                        ["when"] = {
                            ["op"] = "eq",
                            ["path"] = "conversation.hasPendingRequest",
                            ["value"] = true,
                        },
                    },
                    {
                        ["id"] = "semantic.accept.dataset.pending_care",
                        ["metadata"] = {
                            ["fallback"] = "All right. I can take care of that.",
                            ["priority"] = 1,
                            ["templateID"] = "semantic.accept.dataset.pending_care",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "All right. I can take care of that.",
                            },
                            ["TL"] = {
                                "All right. I can take care of that.",
                            },
                        },
                        ["when"] = {
                            ["op"] = "eq",
                            ["path"] = "conversation.hasPendingRequest",
                            ["value"] = true,
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/accept.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["id"] = "semantic.compliment",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "compliment",
            ["sourceId"] = "semantic.compliment",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/compliment.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "semantic",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["metadata"] = {
                ["responsePoolID"] = "semantic.compliment",
                ["sourceProfile"] = "conversation.source.project.hoomans.common.interaction.seed.7a0582ab2e",
            },
            ["response"] = {
                ["act"] = "COMPLIMENT",
                ["variants"] = {
                    {
                        ["id"] = "semantic.compliment.dataset.kind_of_you",
                        ["metadata"] = {
                            ["fallback"] = "That's kind of you. I appreciate it.",
                            ["templateID"] = "semantic.compliment.dataset.kind_of_you",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "That's kind of you. I appreciate it.",
                            },
                            ["TL"] = {
                                "That's kind of you. I appreciate it.",
                            },
                        },
                    },
                    {
                        ["id"] = "semantic.compliment.dataset.means_a_lot",
                        ["metadata"] = {
                            ["fallback"] = "Aw, thank you. That means a lot.",
                            ["templateID"] = "semantic.compliment.dataset.means_a_lot",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Aw, thank you. That means a lot.",
                            },
                            ["TL"] = {
                                "Aw, thank you. That means a lot.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/compliment.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["id"] = "semantic.flow.weather.raining",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "raining",
            ["sourceId"] = "semantic.flow.weather.raining",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/flow_weather_raining.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "semantic.flow.weather",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["metadata"] = {
                ["responsePoolID"] = "semantic.flow.weather.raining",
                ["sourceProfile"] = "conversation.source.project.hoomans.common.interaction.seed.7a0582ab2e",
            },
            ["response"] = {
                ["act"] = "RAINING",
                ["variants"] = {
                    {
                        ["id"] = "semantic.flow.weather.raining.dataset.contextual_switch",
                        ["metadata"] = {
                            ["fallback"] = "It is raining right now. We can return to that proposal when you are ready.",
                            ["plan"] = {
                                ["dialogueAct"] = "WEATHER_REPORT",
                                ["groundedFactRefs"] = {
                                    "world.weather.raining",
                                },
                                ["personalityStyle"] = "contextual",
                                ["sourcePoolID"] = "semantic.flow.weather.raining",
                                ["tone"] = "conversational",
                                ["topic"] = "WEATHER",
                                ["turns"] = {
                                    {
                                        ["continuation"] = "continue",
                                        ["id"] = "dataset_contextual_weather_switch",
                                        ["segments"] = {
                                            {
                                                ["fallback"] = "It is raining right now. We can return to that proposal when you are ready.",
                                                ["kind"] = "translation",
                                                ["templateID"] = "UI_PNC_Conversation_Semantic_DatasetWeatherContextualSwitch",
                                                ["translations"] = {
                                                    ["EN"] = "It is raining right now. We can return to that proposal when you are ready.",
                                                    ["TL"] = "Umuulan ngayon. Maaari tayong bumalik sa panukalang iyon kapag handa ka na.",
                                                },
                                            },
                                        },
                                    },
                                },
                                ["uncertainty"] = "known",
                            },
                            ["priority"] = 4,
                            ["reviewed"] = true,
                            ["sourceRefs"] = {
                                "MASSIVE",
                                "SGD",
                            },
                            ["templateID"] = "UI_PNC_Conversation_Semantic_DatasetWeatherContextualSwitch",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "It is raining right now. We can return to that proposal when you are ready.",
                            },
                            ["TL"] = {
                                "Umuulan ngayon. Maaari tayong bumalik sa panukalang iyon kapag handa ka na.",
                            },
                        },
                        ["when"] = {
                            ["op"] = "eq",
                            ["path"] = "conversation.pattern",
                            ["value"] = "pnc.dataset.question.weather.can_we_talk_about_the_weather",
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/flow_weather_raining.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["id"] = "semantic.greeting",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "greeting",
            ["sourceId"] = "semantic.greeting",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/greeting.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "semantic",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["metadata"] = {
                ["responsePoolID"] = "semantic.greeting",
                ["sourceProfile"] = "conversation.source.project.hoomans.common.interaction.seed.7a0582ab2e",
            },
            ["response"] = {
                ["act"] = "GREETING",
                ["variants"] = {
                    {
                        ["id"] = "semantic.greeting.dataset.holding_up",
                        ["metadata"] = {
                            ["fallback"] = "Hey. How are you holding up?",
                            ["templateID"] = "semantic.greeting.dataset.holding_up",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Hey. How are you holding up?",
                            },
                            ["TL"] = {
                                "Hey. How are you holding up?",
                            },
                        },
                    },
                    {
                        ["id"] = "semantic.greeting.dataset.good_to_see",
                        ["metadata"] = {
                            ["fallback"] = "Good to see you again.",
                            ["templateID"] = "semantic.greeting.dataset.good_to_see",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Good to see you again.",
                            },
                            ["TL"] = {
                                "Good to see you again.",
                            },
                        },
                    },
                    {
                        ["id"] = "semantic.greeting.dataset.how_things",
                        ["metadata"] = {
                            ["fallback"] = "Hey. How are things going?",
                            ["templateID"] = "semantic.greeting.dataset.how_things",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Hey. How are things going?",
                            },
                            ["TL"] = {
                                "Hey. How are things going?",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/greeting.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["id"] = "semantic.offer",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "offer",
            ["sourceId"] = "semantic.offer",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/offer.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "semantic",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["metadata"] = {
                ["responsePoolID"] = "semantic.offer",
                ["sourceProfile"] = "conversation.source.project.hoomans.common.interaction.seed.7a0582ab2e",
            },
            ["response"] = {
                ["act"] = "OFFER",
                ["variants"] = {
                    {
                        ["id"] = "semantic.offer.dataset.hungry_share",
                        ["metadata"] = {
                            ["fallback"] = "That would help a lot. Could I have some?",
                            ["priority"] = 2,
                            ["templateID"] = "semantic.offer.dataset.hungry_share",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "That would help a lot. Could I have some?",
                            },
                            ["TL"] = {
                                "That would help a lot. Could I have some?",
                            },
                        },
                        ["when"] = {
                            ["all"] = {
                                {
                                    ["op"] = "eq",
                                    ["path"] = "conversation.needType",
                                    ["value"] = "hunger",
                                },
                                {
                                    ["op"] = "in",
                                    ["path"] = "conversation.needUrgency",
                                    ["values"] = {
                                        "moderate",
                                        "severe",
                                        "emergency",
                                        "critical",
                                    },
                                },
                            },
                        },
                    },
                    {
                        ["id"] = "semantic.offer.dataset.hungry_appreciate",
                        ["metadata"] = {
                            ["fallback"] = "I'd appreciate a bite. Would you share?",
                            ["priority"] = 2,
                            ["templateID"] = "semantic.offer.dataset.hungry_appreciate",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'd appreciate a bite. Would you share?",
                            },
                            ["TL"] = {
                                "I'd appreciate a bite. Would you share?",
                            },
                        },
                        ["when"] = {
                            ["all"] = {
                                {
                                    ["op"] = "eq",
                                    ["path"] = "conversation.needType",
                                    ["value"] = "hunger",
                                },
                                {
                                    ["op"] = "in",
                                    ["path"] = "conversation.needUrgency",
                                    ["values"] = {
                                        "moderate",
                                        "severe",
                                        "emergency",
                                        "critical",
                                    },
                                },
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/offer.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["id"] = "semantic.question.activity",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "activity",
            ["sourceId"] = "semantic.question.activity",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_activity.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "semantic.question",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["metadata"] = {
                ["responsePoolID"] = "semantic.question.activity",
                ["sourceProfile"] = "conversation.source.project.hoomans.common.interaction.seed.7a0582ab2e",
            },
            ["response"] = {
                ["act"] = "ACTIVITY",
                ["variants"] = {
                    {
                        ["id"] = "semantic.question.activity.dataset.keep_moving",
                        ["metadata"] = {
                            ["fallback"] = "Just doing what I can to keep things moving.",
                            ["templateID"] = "semantic.question.activity.dataset.keep_moving",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Just doing what I can to keep things moving.",
                            },
                            ["TL"] = {
                                "Just doing what I can to keep things moving.",
                            },
                        },
                    },
                    {
                        ["id"] = "semantic.question.activity.dataset.bit_of_everything",
                        ["metadata"] = {
                            ["fallback"] = "A little bit of everything.",
                            ["templateID"] = "semantic.question.activity.dataset.bit_of_everything",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "A little bit of everything.",
                            },
                            ["TL"] = {
                                "A little bit of everything.",
                            },
                        },
                    },
                    {
                        ["id"] = "semantic.question.activity.dataset.taking_care",
                        ["metadata"] = {
                            ["fallback"] = "Just taking care of what needs doing.",
                            ["templateID"] = "semantic.question.activity.dataset.taking_care",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Just taking care of what needs doing.",
                            },
                            ["TL"] = {
                                "Just taking care of what needs doing.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_activity.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["id"] = "semantic.question.backstory.ambiguous",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "ambiguous",
            ["sourceId"] = "semantic.question.backstory.ambiguous",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_ambiguous.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "semantic.question.backstory",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["metadata"] = {
                ["responsePoolID"] = "semantic.question.backstory.ambiguous",
                ["sourceProfile"] = "conversation.source.project.hoomans.common.interaction.seed.7a0582ab2e",
            },
            ["response"] = {
                ["act"] = "AMBIGUOUS",
                ["variants"] = {
                    {
                        ["id"] = "semantic.question.backstory.ambiguous.authored",
                        ["metadata"] = {
                            ["fallback"] = "Which part of my past do you mean?",
                            ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryAmbiguous",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Which part of my past do you mean?",
                            },
                            ["TL"] = {
                                "Aling bahagi ng nakaraan ko ang ibig mong sabihin?",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_ambiguous.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["id"] = "semantic.question.backstory.follow_up.location",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "location",
            ["sourceId"] = "semantic.question.backstory.follow_up.location",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_follow_up_location.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "semantic.question.backstory.follow_up",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["metadata"] = {
                ["responsePoolID"] = "semantic.question.backstory.follow_up.location",
                ["sourceProfile"] = "conversation.source.project.hoomans.common.interaction.seed.7a0582ab2e",
            },
            ["response"] = {
                ["act"] = "LOCATION",
                ["variants"] = {
                    {
                        ["id"] = "semantic.question.backstory.follow_up.location.authored",
                        ["metadata"] = {
                            ["fallback"] = "I remember that part of my life, but I don't have more detail about where it was.",
                            ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryFollowUpLocation",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I remember that part of my life, but I don't have more detail about where it was.",
                            },
                            ["TL"] = {
                                "Naaalala ko ang bahaging iyon ng buhay ko, pero wala akong higit na detalye kung saan iyon.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_follow_up_location.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["id"] = "semantic.question.backstory.follow_up.miss",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "miss",
            ["sourceId"] = "semantic.question.backstory.follow_up.miss",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_follow_up_miss.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "semantic.question.backstory.follow_up",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["metadata"] = {
                ["responsePoolID"] = "semantic.question.backstory.follow_up.miss",
                ["sourceProfile"] = "conversation.source.project.hoomans.common.interaction.seed.7a0582ab2e",
            },
            ["response"] = {
                ["act"] = "MISS",
                ["variants"] = {
                    {
                        ["id"] = "semantic.question.backstory.follow_up.miss.authored",
                        ["metadata"] = {
                            ["fallback"] = "Sometimes. I still think about that part of my life.",
                            ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryFollowUpMiss",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Sometimes. I still think about that part of my life.",
                            },
                            ["TL"] = {
                                "Minsan. Naiisip ko pa rin ang bahaging iyon ng buhay ko.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_follow_up_miss.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["id"] = "semantic.question.backstory.known",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "known",
            ["sourceId"] = "semantic.question.backstory.known",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "semantic.question.backstory",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["metadata"] = {
                ["responsePoolID"] = "semantic.question.backstory.known",
                ["sourceProfile"] = "conversation.source.project.hoomans.common.interaction.seed.7a0582ab2e",
            },
            ["response"] = {
                ["act"] = "KNOWN",
                ["variants"] = {
                    {
                        ["id"] = "semantic.question.backstory.known.authored",
                        ["metadata"] = {
                            ["fallback"] = "Before all this, I was %1.",
                            ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryKnown",
                            ["translationArgs"] = {
                                ["content"] = "fact_content",
                            },
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Before all this, I was %1.",
                            },
                            ["TL"] = {
                                "Bago ang lahat ng ito, ako ay %1.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["id"] = "semantic.question.backstory.known.education",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "education",
            ["sourceId"] = "semantic.question.backstory.known.education",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known_education.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "semantic.question.backstory.known",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["metadata"] = {
                ["responsePoolID"] = "semantic.question.backstory.known.education",
                ["sourceProfile"] = "conversation.source.project.hoomans.common.interaction.seed.7a0582ab2e",
            },
            ["response"] = {
                ["act"] = "EDUCATION",
                ["variants"] = {
                    {
                        ["id"] = "semantic.question.backstory.known.education.authored",
                        ["metadata"] = {
                            ["fallback"] = "I studied %1.",
                            ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryEducation",
                            ["translationArgs"] = {
                                ["content"] = "fact_content",
                            },
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I studied %1.",
                            },
                            ["TL"] = {
                                "Nag-aral ako ng %1.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known_education.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["id"] = "semantic.question.backstory.known.family_background",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "family_background",
            ["sourceId"] = "semantic.question.backstory.known.family_background",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known_family_background.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "semantic.question.backstory.known",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["metadata"] = {
                ["responsePoolID"] = "semantic.question.backstory.known.family_background",
                ["sourceProfile"] = "conversation.source.project.hoomans.common.interaction.seed.7a0582ab2e",
            },
            ["response"] = {
                ["act"] = "FAMILY_BACKGROUND",
                ["variants"] = {
                    {
                        ["id"] = "semantic.question.backstory.known.family_background.authored",
                        ["metadata"] = {
                            ["fallback"] = "My family was %1.",
                            ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryFamily",
                            ["translationArgs"] = {
                                ["content"] = "fact_content",
                            },
                        },
                        ["text"] = {
                            ["EN"] = {
                                "My family was %1.",
                            },
                            ["TL"] = {
                                "Ang pamilya ko ay %1.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known_family_background.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["id"] = "semantic.question.backstory.known.fear",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "fear",
            ["sourceId"] = "semantic.question.backstory.known.fear",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known_fear.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "semantic.question.backstory.known",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["metadata"] = {
                ["responsePoolID"] = "semantic.question.backstory.known.fear",
                ["sourceProfile"] = "conversation.source.project.hoomans.common.interaction.seed.7a0582ab2e",
            },
            ["response"] = {
                ["act"] = "FEAR",
                ["variants"] = {
                    {
                        ["id"] = "semantic.question.backstory.known.fear.authored",
                        ["metadata"] = {
                            ["fallback"] = "I have always been afraid of %1.",
                            ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryFear",
                            ["translationArgs"] = {
                                ["content"] = "fact_content",
                            },
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I have always been afraid of %1.",
                            },
                            ["TL"] = {
                                "Palagi akong natatakot sa %1.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known_fear.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["id"] = "semantic.question.backstory.known.former_job",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "former_job",
            ["sourceId"] = "semantic.question.backstory.known.former_job",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known_former_job.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "semantic.question.backstory.known",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["metadata"] = {
                ["responsePoolID"] = "semantic.question.backstory.known.former_job",
                ["sourceProfile"] = "conversation.source.project.hoomans.common.interaction.seed.7a0582ab2e",
            },
            ["response"] = {
                ["act"] = "FORMER_JOB",
                ["variants"] = {
                    {
                        ["id"] = "semantic.question.backstory.known.former_job.authored",
                        ["metadata"] = {
                            ["fallback"] = "I worked as %1 before all this.",
                            ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryFormerJob",
                            ["translationArgs"] = {
                                ["content"] = "fact_content",
                            },
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I worked as %1 before all this.",
                            },
                            ["TL"] = {
                                "Nagtrabaho ako bilang %1 bago ang lahat ng ito.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known_former_job.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["id"] = "semantic.question.backstory.known.hobby",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "hobby",
            ["sourceId"] = "semantic.question.backstory.known.hobby",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known_hobby.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "semantic.question.backstory.known",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["metadata"] = {
                ["responsePoolID"] = "semantic.question.backstory.known.hobby",
                ["sourceProfile"] = "conversation.source.project.hoomans.common.interaction.seed.7a0582ab2e",
            },
            ["response"] = {
                ["act"] = "HOBBY",
                ["variants"] = {
                    {
                        ["id"] = "semantic.question.backstory.known.hobby.authored",
                        ["metadata"] = {
                            ["fallback"] = "I used to enjoy %1.",
                            ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryHobby",
                            ["translationArgs"] = {
                                ["content"] = "fact_content",
                            },
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I used to enjoy %1.",
                            },
                            ["TL"] = {
                                "Mahilig ako noon sa %1.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known_hobby.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["id"] = "semantic.question.backstory.known.hometown",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "hometown",
            ["sourceId"] = "semantic.question.backstory.known.hometown",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known_hometown.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "semantic.question.backstory.known",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["metadata"] = {
                ["responsePoolID"] = "semantic.question.backstory.known.hometown",
                ["sourceProfile"] = "conversation.source.project.hoomans.common.interaction.seed.7a0582ab2e",
            },
            ["response"] = {
                ["act"] = "HOMETOWN",
                ["variants"] = {
                    {
                        ["id"] = "semantic.question.backstory.known.hometown.authored",
                        ["metadata"] = {
                            ["fallback"] = "I grew up in %1.",
                            ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryHometown",
                            ["translationArgs"] = {
                                ["content"] = "fact_content",
                            },
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I grew up in %1.",
                            },
                            ["TL"] = {
                                "Lumaki ako sa %1.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known_hometown.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["id"] = "semantic.question.backstory.known.tragedy",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "tragedy",
            ["sourceId"] = "semantic.question.backstory.known.tragedy",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known_tragedy.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "semantic.question.backstory.known",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["metadata"] = {
                ["responsePoolID"] = "semantic.question.backstory.known.tragedy",
                ["sourceProfile"] = "conversation.source.project.hoomans.common.interaction.seed.7a0582ab2e",
            },
            ["response"] = {
                ["act"] = "TRAGEDY",
                ["variants"] = {
                    {
                        ["id"] = "semantic.question.backstory.known.tragedy.authored",
                        ["metadata"] = {
                            ["fallback"] = "Something happened: %1.",
                            ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryTragedy",
                            ["translationArgs"] = {
                                ["content"] = "fact_content",
                            },
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Something happened: %1.",
                            },
                            ["TL"] = {
                                "May nangyari: %1.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_known_tragedy.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["id"] = "semantic.question.backstory.refusal",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "refusal",
            ["sourceId"] = "semantic.question.backstory.refusal",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_refusal.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "semantic.question.backstory",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["metadata"] = {
                ["responsePoolID"] = "semantic.question.backstory.refusal",
                ["sourceProfile"] = "conversation.source.project.hoomans.common.interaction.seed.7a0582ab2e",
            },
            ["response"] = {
                ["act"] = "REFUSAL",
                ["variants"] = {
                    {
                        ["id"] = "semantic.question.backstory.refusal.authored",
                        ["metadata"] = {
                            ["fallback"] = "I'm not ready to talk about that yet.",
                            ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryRefusal",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm not ready to talk about that yet.",
                            },
                            ["TL"] = {
                                "Hindi pa ako handang pag-usapan iyan.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_refusal.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["id"] = "semantic.question.backstory.suspected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "suspected",
            ["sourceId"] = "semantic.question.backstory.suspected",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_suspected.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "semantic.question.backstory",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["metadata"] = {
                ["responsePoolID"] = "semantic.question.backstory.suspected",
                ["sourceProfile"] = "conversation.source.project.hoomans.common.interaction.seed.7a0582ab2e",
            },
            ["response"] = {
                ["act"] = "SUSPECTED",
                ["variants"] = {
                    {
                        ["id"] = "semantic.question.backstory.suspected.authored",
                        ["metadata"] = {
                            ["fallback"] = "I think it was %1, but I could be mistaken.",
                            ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstorySuspected",
                            ["translationArgs"] = {
                                ["content"] = "fact_content",
                            },
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I think it was %1, but I could be mistaken.",
                            },
                            ["TL"] = {
                                "Sa tingin ko ay %1 iyon, pero maaaring mali ako.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_backstory_suspected.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["id"] = "semantic.question.identity",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "identity",
            ["sourceId"] = "semantic.question.identity",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_identity.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "semantic.question",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["metadata"] = {
                ["responsePoolID"] = "semantic.question.identity",
                ["sourceProfile"] = "conversation.source.project.hoomans.common.interaction.seed.7a0582ab2e",
            },
            ["response"] = {
                ["act"] = "IDENTITY",
                ["variants"] = {
                    {
                        ["id"] = "semantic.question.identity.dataset.stranger_alt_1",
                        ["metadata"] = {
                            ["fallback"] = "I keep my name to myself until I know someone better. What should I call you?",
                            ["templateID"] = "semantic.question.identity.stranger_alt_1",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I keep my name to myself until I know someone better. What should I call you?",
                            },
                            ["TL"] = {
                                "I keep my name to myself until I know someone better. What should I call you?",
                            },
                        },
                    },
                    {
                        ["id"] = "semantic.question.identity.dataset.stranger_alt_2",
                        ["metadata"] = {
                            ["fallback"] = "Let's get to know each other first. What do people call you?",
                            ["templateID"] = "semantic.question.identity.stranger_alt_2",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Let's get to know each other first. What do people call you?",
                            },
                            ["TL"] = {
                                "Let's get to know each other first. What do people call you?",
                            },
                        },
                    },
                    {
                        ["id"] = "semantic.question.identity.dataset.wary_alt_1",
                        ["metadata"] = {
                            ["fallback"] = "I don't trust you enough to share my name. Who are you, really?",
                            ["priority"] = 2,
                            ["templateID"] = "semantic.question.identity.wary_alt_1",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I don't trust you enough to share my name. Who are you, really?",
                            },
                            ["TL"] = {
                                "I don't trust you enough to share my name. Who are you, really?",
                            },
                        },
                        ["when"] = {
                            ["op"] = "eq",
                            ["path"] = "conversation.identityTrust",
                            ["value"] = "untrustworthy",
                        },
                    },
                    {
                        ["id"] = "semantic.question.identity.dataset.wary_alt_2",
                        ["metadata"] = {
                            ["fallback"] = "After that lie, I'm not telling you my name. Tell me the truth about yours.",
                            ["priority"] = 2,
                            ["templateID"] = "semantic.question.identity.wary_alt_2",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "After that lie, I'm not telling you my name. Tell me the truth about yours.",
                            },
                            ["TL"] = {
                                "After that lie, I'm not telling you my name. Tell me the truth about yours.",
                            },
                        },
                        ["when"] = {
                            ["op"] = "eq",
                            ["path"] = "conversation.identityTrust",
                            ["value"] = "untrustworthy",
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_identity.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["id"] = "semantic.question.needs.proposal",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "proposal",
            ["sourceId"] = "semantic.question.needs.proposal",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_needs_proposal.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "semantic.question.needs",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["metadata"] = {
                ["responsePoolID"] = "semantic.question.needs.proposal",
                ["sourceProfile"] = "conversation.source.project.hoomans.common.interaction.seed.7a0582ab2e",
            },
            ["response"] = {
                ["act"] = "PROPOSAL",
                ["variants"] = {
                    {
                        ["id"] = "semantic.question.needs.proposal.dataset.thirst",
                        ["metadata"] = {
                            ["fallback"] = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                            ["plan"] = {
                                ["dialogueAct"] = "PROMISE_ACKNOWLEDGEMENT",
                                ["groundedFactRefs"] = {
                                    "npc.needs.thirst",
                                },
                                ["sourcePoolID"] = "semantic.question.needs.proposal",
                                ["tone"] = "direct",
                                ["topic"] = "NEEDS",
                                ["turns"] = {
                                    {
                                        ["continuation"] = "continue",
                                        ["id"] = "dataset_proposal_acknowledged",
                                        ["segments"] = {
                                            {
                                                ["fallback"] = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                                                ["kind"] = "translation",
                                                ["templateID"] = "UI_PNC_Conversation_Semantic_DatasetNeedsPromiseThirst",
                                                ["translations"] = {
                                                    ["EN"] = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                                                    ["TL"] = "Maaari ko iyong ituring na panukala, pero kailangan ko pa ang item at dami bago ako magtala ng pangako.",
                                                },
                                            },
                                        },
                                    },
                                },
                                ["uncertainty"] = "pending",
                            },
                            ["priority"] = 4,
                            ["reviewed"] = true,
                            ["sourceRefs"] = {
                                "MASSIVE",
                                "SGD",
                            },
                            ["templateID"] = "UI_PNC_Conversation_Semantic_DatasetNeedsPromiseThirst",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                            },
                            ["TL"] = {
                                "Maaari ko iyong ituring na panukala, pero kailangan ko pa ang item at dami bago ako magtala ng pangako.",
                            },
                        },
                        ["when"] = {
                            ["all"] = {
                                {
                                    ["op"] = "eq",
                                    ["path"] = "conversation.needType",
                                    ["value"] = "thirst",
                                },
                                {
                                    ["op"] = "in",
                                    ["path"] = "conversation.needUrgency",
                                    ["values"] = {
                                        "moderate",
                                        "severe",
                                        "emergency",
                                        "critical",
                                    },
                                },
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_needs_proposal.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["id"] = "semantic.question.needs.quantity",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "quantity",
            ["sourceId"] = "semantic.question.needs.quantity",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_needs_quantity.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "semantic.question.needs",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["metadata"] = {
                ["responsePoolID"] = "semantic.question.needs.quantity",
                ["sourceProfile"] = "conversation.source.project.hoomans.common.interaction.seed.7a0582ab2e",
            },
            ["response"] = {
                ["act"] = "QUANTITY",
                ["variants"] = {
                    {
                        ["id"] = "semantic.question.needs.quantity.dataset.clarify_thirst",
                        ["metadata"] = {
                            ["fallback"] = "I can confirm water is a need, but which item do you mean?",
                            ["plan"] = {
                                ["dialogueAct"] = "ASK_CLARIFICATION",
                                ["groundedFactRefs"] = {
                                    "npc.needs.thirst",
                                },
                                ["sourcePoolID"] = "semantic.question.needs.quantity",
                                ["tone"] = "clarifying",
                                ["topic"] = "NEEDS",
                                ["turns"] = {
                                    {
                                        ["continuation"] = "continue",
                                        ["id"] = "dataset_needs_clarification",
                                        ["segments"] = {
                                            {
                                                ["fallback"] = "I can confirm water is a need, but which item do you mean?",
                                                ["kind"] = "translation",
                                                ["templateID"] = "UI_PNC_Conversation_Semantic_DatasetNeedsClarifyThirst",
                                                ["translations"] = {
                                                    ["EN"] = "I can confirm water is a need, but which item do you mean?",
                                                    ["TL"] = "Makukumpirma kong kailangan ang tubig, pero aling item ang ibig mong sabihin?",
                                                },
                                            },
                                        },
                                    },
                                },
                                ["uncertainty"] = "ambiguous",
                            },
                            ["priority"] = 4,
                            ["reviewed"] = true,
                            ["sourceRefs"] = {
                                "MASSIVE",
                                "SGD",
                            },
                            ["templateID"] = "UI_PNC_Conversation_Semantic_DatasetNeedsClarifyThirst",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I can confirm water is a need, but which item do you mean?",
                            },
                            ["TL"] = {
                                "Makukumpirma kong kailangan ang tubig, pero aling item ang ibig mong sabihin?",
                            },
                        },
                        ["when"] = {
                            ["all"] = {
                                {
                                    ["op"] = "eq",
                                    ["path"] = "conversation.lastIntent",
                                    ["value"] = "CLARIFY",
                                },
                                {
                                    ["op"] = "eq",
                                    ["path"] = "conversation.needType",
                                    ["value"] = "thirst",
                                },
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_needs_quantity.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["id"] = "semantic.question.wellbeing",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "wellbeing",
            ["sourceId"] = "semantic.question.wellbeing",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_wellbeing.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "semantic.question",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["metadata"] = {
                ["responsePoolID"] = "semantic.question.wellbeing",
                ["sourceProfile"] = "conversation.source.project.hoomans.common.interaction.seed.7a0582ab2e",
            },
            ["response"] = {
                ["act"] = "WELLBEING",
                ["variants"] = {
                    {
                        ["id"] = "semantic.question.wellbeing.dataset.hanging_in",
                        ["metadata"] = {
                            ["fallback"] = "I'm hanging in there. Thanks for asking.",
                            ["templateID"] = "semantic.question.wellbeing.dataset.hanging_in",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm hanging in there. Thanks for asking.",
                            },
                            ["TL"] = {
                                "I'm hanging in there. Thanks for asking.",
                            },
                        },
                    },
                    {
                        ["id"] = "semantic.question.wellbeing.dataset.all_things_considered",
                        ["metadata"] = {
                            ["fallback"] = "Doing okay, all things considered.",
                            ["templateID"] = "semantic.question.wellbeing.dataset.all_things_considered",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Doing okay, all things considered.",
                            },
                            ["TL"] = {
                                "Doing okay, all things considered.",
                            },
                        },
                    },
                    {
                        ["id"] = "semantic.question.wellbeing.dataset.getting_by",
                        ["metadata"] = {
                            ["fallback"] = "I'm getting by, one day at a time. How about you?",
                            ["templateID"] = "semantic.question.wellbeing.dataset.getting_by",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm getting by, one day at a time. How about you?",
                            },
                            ["TL"] = {
                                "I'm getting by, one day at a time. How about you?",
                            },
                        },
                    },
                    {
                        ["id"] = "semantic.question.wellbeing.dataset.hungry",
                        ["metadata"] = {
                            ["fallback"] = "I'm hungry, but I'll manage. If you have food to spare, I'd appreciate it.",
                            ["priority"] = 2,
                            ["templateID"] = "semantic.question.wellbeing.dataset.hungry",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm hungry, but I'll manage. If you have food to spare, I'd appreciate it.",
                            },
                            ["TL"] = {
                                "I'm hungry, but I'll manage. If you have food to spare, I'd appreciate it.",
                            },
                        },
                        ["when"] = {
                            ["all"] = {
                                {
                                    ["op"] = "eq",
                                    ["path"] = "conversation.needType",
                                    ["value"] = "hunger",
                                },
                                {
                                    ["op"] = "in",
                                    ["path"] = "conversation.needUrgency",
                                    ["values"] = {
                                        "moderate",
                                        "severe",
                                        "emergency",
                                        "critical",
                                    },
                                },
                            },
                        },
                    },
                    {
                        ["id"] = "semantic.question.wellbeing.dataset.thirsty",
                        ["metadata"] = {
                            ["fallback"] = "I'm pretty thirsty. If you have water, could you spare some?",
                            ["priority"] = 3,
                            ["templateID"] = "semantic.question.wellbeing.dataset.thirsty",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm pretty thirsty. If you have water, could you spare some?",
                            },
                            ["TL"] = {
                                "I'm pretty thirsty. If you have water, could you spare some?",
                            },
                        },
                        ["when"] = {
                            ["all"] = {
                                {
                                    ["op"] = "eq",
                                    ["path"] = "conversation.needType",
                                    ["value"] = "thirst",
                                },
                                {
                                    ["op"] = "in",
                                    ["path"] = "conversation.needUrgency",
                                    ["values"] = {
                                        "moderate",
                                        "severe",
                                        "emergency",
                                        "critical",
                                    },
                                },
                            },
                        },
                    },
                    {
                        ["id"] = "semantic.question.wellbeing.dataset.tired",
                        ["metadata"] = {
                            ["fallback"] = "I'm tired, though I can manage for now.",
                            ["priority"] = 2,
                            ["templateID"] = "semantic.question.wellbeing.dataset.tired",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm tired, though I can manage for now.",
                            },
                            ["TL"] = {
                                "I'm tired, though I can manage for now.",
                            },
                        },
                        ["when"] = {
                            ["all"] = {
                                {
                                    ["op"] = "eq",
                                    ["path"] = "conversation.needType",
                                    ["value"] = "fatigue",
                                },
                                {
                                    ["op"] = "in",
                                    ["path"] = "conversation.needUrgency",
                                    ["values"] = {
                                        "moderate",
                                        "severe",
                                        "emergency",
                                        "critical",
                                    },
                                },
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_wellbeing.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["id"] = "semantic.question.wellbeing.unknown",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "unknown",
            ["sourceId"] = "semantic.question.wellbeing.unknown",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/question_wellbeing_unknown.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "semantic.question.wellbeing",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["metadata"] = {
                ["responsePoolID"] = "semantic.question.wellbeing.unknown",
                ["sourceProfile"] = "conversation.source.project.hoomans.common.interaction.seed.7a0582ab2e",
            },
            ["response"] = {
                ["act"] = "UNKNOWN",
                ["variants"] = {
                    {
                        ["id"] = "semantic.question.wellbeing.unknown.dataset.causal_followup",
                        ["metadata"] = {
                            ["fallback"] = "I can tell something is off, but I do not know what caused it yet.",
                            ["plan"] = {
                                ["dialogueAct"] = "ASK_CLARIFICATION",
                                ["groundedFactRefs"] = {
                                },
                                ["personalityStyle"] = "truthful",
                                ["sourcePoolID"] = "semantic.question.wellbeing.unknown",
                                ["tone"] = "clarifying",
                                ["topic"] = "WELLBEING",
                                ["turns"] = {
                                    {
                                        ["continuation"] = "continue",
                                        ["id"] = "dataset_causal_wellbeing_unknown",
                                        ["segments"] = {
                                            {
                                                ["fallback"] = "I can tell something is off, but I do not know what caused it yet.",
                                                ["kind"] = "translation",
                                                ["templateID"] = "UI_PNC_Conversation_Semantic_DatasetWellbeingCausalUnknown",
                                                ["translations"] = {
                                                    ["EN"] = "I can tell something is off, but I do not know what caused it yet.",
                                                    ["TL"] = "Alam kong may hindi tama, pero hindi ko pa alam kung ano ang sanhi nito.",
                                                },
                                            },
                                        },
                                    },
                                },
                                ["uncertainty"] = "unknown",
                            },
                            ["priority"] = 4,
                            ["reviewed"] = true,
                            ["sourceRefs"] = {
                                "MASSIVE",
                                "SGD",
                            },
                            ["templateID"] = "UI_PNC_Conversation_Semantic_DatasetWellbeingCausalUnknown",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I can tell something is off, but I do not know what caused it yet.",
                            },
                            ["TL"] = {
                                "Alam kong may hindi tama, pero hindi ko pa alam kung ano ang sanhi nito.",
                            },
                        },
                        ["when"] = {
                            ["all"] = {
                                {
                                    ["op"] = "eq",
                                    ["path"] = "conversation.healthState",
                                    ["value"] = "unknown",
                                },
                                {
                                    ["op"] = "eq",
                                    ["path"] = "conversation.pattern",
                                    ["value"] = "pnc.dataset.question.wellbeing.what_is_going_on_with_you",
                                },
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/question_wellbeing_unknown.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["id"] = "semantic.refuse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "refuse",
            ["sourceId"] = "semantic.refuse",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/refuse.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "semantic",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["metadata"] = {
                ["responsePoolID"] = "semantic.refuse",
                ["sourceProfile"] = "conversation.source.project.hoomans.common.interaction.seed.7a0582ab2e",
            },
            ["response"] = {
                ["act"] = "REFUSE",
                ["variants"] = {
                    {
                        ["id"] = "semantic.refuse.dataset.pending_unavailable",
                        ["metadata"] = {
                            ["fallback"] = "I can't take that on right now.",
                            ["priority"] = 1,
                            ["templateID"] = "semantic.refuse.dataset.pending_unavailable",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I can't take that on right now.",
                            },
                            ["TL"] = {
                                "I can't take that on right now.",
                            },
                        },
                        ["when"] = {
                            ["op"] = "eq",
                            ["path"] = "conversation.hasPendingRequest",
                            ["value"] = true,
                        },
                    },
                    {
                        ["id"] = "semantic.refuse.dataset.pending_enough",
                        ["metadata"] = {
                            ["fallback"] = "Not this time. I have enough to manage.",
                            ["priority"] = 1,
                            ["templateID"] = "semantic.refuse.dataset.pending_enough",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Not this time. I have enough to manage.",
                            },
                            ["TL"] = {
                                "Not this time. I have enough to manage.",
                            },
                        },
                        ["when"] = {
                            ["op"] = "eq",
                            ["path"] = "conversation.hasPendingRequest",
                            ["value"] = true,
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/refuse.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_semantic_responses",
        ["id"] = "semantic.thanks",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "thanks",
            ["sourceId"] = "semantic.thanks",
            ["sourcePath"] = "adopters/hoomans/dialogue/core_semantic_responses/thanks.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreSemanticResponses",
        ["namespace"] = "semantic",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["metadata"] = {
                ["responsePoolID"] = "semantic.thanks",
                ["sourceProfile"] = "conversation.source.project.hoomans.common.interaction.seed.7a0582ab2e",
            },
            ["response"] = {
                ["act"] = "THANKS",
                ["variants"] = {
                    {
                        ["id"] = "semantic.thanks.dataset.no_problem",
                        ["metadata"] = {
                            ["fallback"] = "No problem at all.",
                            ["templateID"] = "semantic.thanks.dataset.no_problem",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "No problem at all.",
                            },
                            ["TL"] = {
                                "No problem at all.",
                            },
                        },
                    },
                    {
                        ["id"] = "semantic.thanks.dataset.anytime",
                        ["metadata"] = {
                            ["fallback"] = "Anytime.",
                            ["templateID"] = "semantic.thanks.dataset.anytime",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Anytime.",
                            },
                            ["TL"] = {
                                "Anytime.",
                            },
                        },
                    },
                    {
                        ["id"] = "semantic.thanks.dataset.glady",
                        ["metadata"] = {
                            ["fallback"] = "Glad I could help.",
                            ["templateID"] = "semantic.thanks.dataset.glady",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Glad I could help.",
                            },
                            ["TL"] = {
                                "Glad I could help.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/core_semantic_responses/thanks.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
