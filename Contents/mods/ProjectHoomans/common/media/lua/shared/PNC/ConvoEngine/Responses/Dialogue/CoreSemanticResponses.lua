-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "general",
        ["id"] = "accept",
        ["owner"] = "ProjectHoomans",
        ["variants"] = {
            {
                ["dialogueAct"] = "ACCEPT",
                ["fallback"] = "Okay, I'll get started.",
                ["id"] = "accept.dataset.pending_started",
                ["priority"] = 1,
                ["templateID"] = "accept.dataset.pending_started",
                ["translations"] = {
                    ["EN"] = {
                        "Okay, I'll get started.",
                    },
                    ["TL"] = {
                        "Okay, I'll get started.",
                    },
                },
                ["when"] = {
                    ["hasPendingRequest"] = true,
                },
            },
            {
                ["dialogueAct"] = "ACCEPT",
                ["fallback"] = "All right. I can take care of that.",
                ["id"] = "accept.dataset.pending_care",
                ["priority"] = 1,
                ["templateID"] = "accept.dataset.pending_care",
                ["translations"] = {
                    ["EN"] = {
                        "All right. I can take care of that.",
                    },
                    ["TL"] = {
                        "All right. I can take care of that.",
                    },
                },
                ["when"] = {
                    ["hasPendingRequest"] = true,
                },
            },
        },
    },
    {
        ["domain"] = "general",
        ["id"] = "compliment",
        ["owner"] = "ProjectHoomans",
        ["variants"] = {
            {
                ["dialogueAct"] = "COMPLIMENT",
                ["fallback"] = "That's kind of you. I appreciate it.",
                ["id"] = "compliment.dataset.kind_of_you",
                ["templateID"] = "compliment.dataset.kind_of_you",
                ["translations"] = {
                    ["EN"] = {
                        "That's kind of you. I appreciate it.",
                    },
                    ["TL"] = {
                        "That's kind of you. I appreciate it.",
                    },
                },
            },
            {
                ["dialogueAct"] = "COMPLIMENT",
                ["fallback"] = "Aw, thank you. That means a lot.",
                ["id"] = "compliment.dataset.means_a_lot",
                ["templateID"] = "compliment.dataset.means_a_lot",
                ["translations"] = {
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
    {
        ["domain"] = "weather",
        ["id"] = "flow.weather.raining",
        ["owner"] = "ProjectHoomans",
        ["variants"] = {
            {
                ["dialogueAct"] = "RAINING",
                ["fallback"] = "It is raining right now. We can return to that proposal when you are ready.",
                ["id"] = "flow.weather.raining.dataset.contextual_switch",
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
                ["translations"] = {
                    ["EN"] = {
                        "It is raining right now. We can return to that proposal when you are ready.",
                    },
                    ["TL"] = {
                        "Umuulan ngayon. Maaari tayong bumalik sa panukalang iyon kapag handa ka na.",
                    },
                },
                ["when"] = {
                    ["pattern"] = "pnc.dataset.question.weather.can_we_talk_about_the_weather",
                },
            },
        },
    },
    {
        ["domain"] = "general",
        ["id"] = "greeting",
        ["owner"] = "ProjectHoomans",
        ["variants"] = {
            {
                ["dialogueAct"] = "GREETING",
                ["fallback"] = "Hey. How are you holding up?",
                ["id"] = "greeting.dataset.holding_up",
                ["templateID"] = "greeting.dataset.holding_up",
                ["translations"] = {
                    ["EN"] = {
                        "Hey. How are you holding up?",
                    },
                    ["TL"] = {
                        "Hey. How are you holding up?",
                    },
                },
            },
            {
                ["dialogueAct"] = "GREETING",
                ["fallback"] = "Good to see you again.",
                ["id"] = "greeting.dataset.good_to_see",
                ["templateID"] = "greeting.dataset.good_to_see",
                ["translations"] = {
                    ["EN"] = {
                        "Good to see you again.",
                    },
                    ["TL"] = {
                        "Good to see you again.",
                    },
                },
            },
            {
                ["dialogueAct"] = "GREETING",
                ["fallback"] = "Hey. How are things going?",
                ["id"] = "greeting.dataset.how_things",
                ["templateID"] = "greeting.dataset.how_things",
                ["translations"] = {
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
    {
        ["domain"] = "general",
        ["id"] = "offer",
        ["owner"] = "ProjectHoomans",
        ["variants"] = {
            {
                ["dialogueAct"] = "OFFER",
                ["fallback"] = "That would help a lot. Could I have some?",
                ["id"] = "offer.dataset.hungry_share",
                ["priority"] = 2,
                ["templateID"] = "offer.dataset.hungry_share",
                ["translations"] = {
                    ["EN"] = {
                        "That would help a lot. Could I have some?",
                    },
                    ["TL"] = {
                        "That would help a lot. Could I have some?",
                    },
                },
                ["when"] = {
                    ["needType"] = "hunger",
                    ["needUrgency"] = {
                        "moderate",
                        "severe",
                        "emergency",
                        "critical",
                    },
                },
            },
            {
                ["dialogueAct"] = "OFFER",
                ["fallback"] = "I'd appreciate a bite. Would you share?",
                ["id"] = "offer.dataset.hungry_appreciate",
                ["priority"] = 2,
                ["templateID"] = "offer.dataset.hungry_appreciate",
                ["translations"] = {
                    ["EN"] = {
                        "I'd appreciate a bite. Would you share?",
                    },
                    ["TL"] = {
                        "I'd appreciate a bite. Would you share?",
                    },
                },
                ["when"] = {
                    ["needType"] = "hunger",
                    ["needUrgency"] = {
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
        ["domain"] = "activity",
        ["id"] = "question.activity",
        ["owner"] = "ProjectHoomans",
        ["variants"] = {
            {
                ["dialogueAct"] = "ACTIVITY",
                ["fallback"] = "Just doing what I can to keep things moving.",
                ["id"] = "question.activity.dataset.keep_moving",
                ["templateID"] = "question.activity.dataset.keep_moving",
                ["translations"] = {
                    ["EN"] = {
                        "Just doing what I can to keep things moving.",
                    },
                    ["TL"] = {
                        "Just doing what I can to keep things moving.",
                    },
                },
            },
            {
                ["dialogueAct"] = "ACTIVITY",
                ["fallback"] = "A little bit of everything.",
                ["id"] = "question.activity.dataset.bit_of_everything",
                ["templateID"] = "question.activity.dataset.bit_of_everything",
                ["translations"] = {
                    ["EN"] = {
                        "A little bit of everything.",
                    },
                    ["TL"] = {
                        "A little bit of everything.",
                    },
                },
            },
            {
                ["dialogueAct"] = "ACTIVITY",
                ["fallback"] = "Just taking care of what needs doing.",
                ["id"] = "question.activity.dataset.taking_care",
                ["templateID"] = "question.activity.dataset.taking_care",
                ["translations"] = {
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
    {
        ["domain"] = "backstory",
        ["id"] = "question.backstory.ambiguous",
        ["owner"] = "ProjectHoomans",
        ["variants"] = {
            {
                ["dialogueAct"] = "AMBIGUOUS",
                ["fallback"] = "Which part of my past do you mean?",
                ["id"] = "question.backstory.ambiguous.authored",
                ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryAmbiguous",
                ["translations"] = {
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
    {
        ["domain"] = "backstory",
        ["id"] = "question.backstory.follow_up.location",
        ["owner"] = "ProjectHoomans",
        ["variants"] = {
            {
                ["dialogueAct"] = "LOCATION",
                ["fallback"] = "I remember that part of my life, but I don't have more detail about where it was.",
                ["id"] = "question.backstory.follow_up.location.authored",
                ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryFollowUpLocation",
                ["translations"] = {
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
    {
        ["domain"] = "backstory",
        ["id"] = "question.backstory.follow_up.miss",
        ["owner"] = "ProjectHoomans",
        ["variants"] = {
            {
                ["dialogueAct"] = "MISS",
                ["fallback"] = "Sometimes. I still think about that part of my life.",
                ["id"] = "question.backstory.follow_up.miss.authored",
                ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryFollowUpMiss",
                ["translations"] = {
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
    {
        ["domain"] = "backstory",
        ["id"] = "question.backstory.refusal",
        ["owner"] = "ProjectHoomans",
        ["variants"] = {
            {
                ["dialogueAct"] = "REFUSAL",
                ["fallback"] = "I'm not ready to talk about that yet.",
                ["id"] = "question.backstory.refusal.authored",
                ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryRefusal",
                ["translations"] = {
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
    {
        ["domain"] = "backstory",
        ["id"] = "question.backstory.suspected",
        ["owner"] = "ProjectHoomans",
        ["variants"] = {
            {
                ["dialogueAct"] = "SUSPECTED",
                ["fallback"] = "I think it was %1, but I could be mistaken.",
                ["id"] = "question.backstory.suspected.authored",
                ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstorySuspected",
                ["translationArgs"] = {
                    ["content"] = "fact_content",
                },
                ["translations"] = {
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
    {
        ["domain"] = "wellbeing",
        ["id"] = "question.wellbeing",
        ["owner"] = "ProjectHoomans",
        ["variants"] = {
            {
                ["dialogueAct"] = "WELLBEING",
                ["fallback"] = "I'm hanging in there. Thanks for asking.",
                ["id"] = "question.wellbeing.dataset.hanging_in",
                ["templateID"] = "question.wellbeing.dataset.hanging_in",
                ["translations"] = {
                    ["EN"] = {
                        "I'm hanging in there. Thanks for asking.",
                    },
                    ["TL"] = {
                        "I'm hanging in there. Thanks for asking.",
                    },
                },
            },
            {
                ["dialogueAct"] = "WELLBEING",
                ["fallback"] = "Doing okay, all things considered.",
                ["id"] = "question.wellbeing.dataset.all_things_considered",
                ["templateID"] = "question.wellbeing.dataset.all_things_considered",
                ["translations"] = {
                    ["EN"] = {
                        "Doing okay, all things considered.",
                    },
                    ["TL"] = {
                        "Doing okay, all things considered.",
                    },
                },
            },
            {
                ["dialogueAct"] = "WELLBEING",
                ["fallback"] = "I'm getting by, one day at a time. How about you?",
                ["id"] = "question.wellbeing.dataset.getting_by",
                ["templateID"] = "question.wellbeing.dataset.getting_by",
                ["translations"] = {
                    ["EN"] = {
                        "I'm getting by, one day at a time. How about you?",
                    },
                    ["TL"] = {
                        "I'm getting by, one day at a time. How about you?",
                    },
                },
            },
            {
                ["dialogueAct"] = "WELLBEING",
                ["fallback"] = "I'm hungry, but I'll manage. If you have food to spare, I'd appreciate it.",
                ["id"] = "question.wellbeing.dataset.hungry",
                ["priority"] = 2,
                ["templateID"] = "question.wellbeing.dataset.hungry",
                ["translations"] = {
                    ["EN"] = {
                        "I'm hungry, but I'll manage. If you have food to spare, I'd appreciate it.",
                    },
                    ["TL"] = {
                        "I'm hungry, but I'll manage. If you have food to spare, I'd appreciate it.",
                    },
                },
                ["when"] = {
                    ["needType"] = "hunger",
                    ["needUrgency"] = {
                        "moderate",
                        "severe",
                        "emergency",
                        "critical",
                    },
                },
            },
            {
                ["dialogueAct"] = "WELLBEING",
                ["fallback"] = "I'm pretty thirsty. If you have water, could you spare some?",
                ["id"] = "question.wellbeing.dataset.thirsty",
                ["priority"] = 3,
                ["templateID"] = "question.wellbeing.dataset.thirsty",
                ["translations"] = {
                    ["EN"] = {
                        "I'm pretty thirsty. If you have water, could you spare some?",
                    },
                    ["TL"] = {
                        "I'm pretty thirsty. If you have water, could you spare some?",
                    },
                },
                ["when"] = {
                    ["needType"] = "thirst",
                    ["needUrgency"] = {
                        "moderate",
                        "severe",
                        "emergency",
                        "critical",
                    },
                },
            },
            {
                ["dialogueAct"] = "WELLBEING",
                ["fallback"] = "I'm tired, though I can manage for now.",
                ["id"] = "question.wellbeing.dataset.tired",
                ["priority"] = 2,
                ["templateID"] = "question.wellbeing.dataset.tired",
                ["translations"] = {
                    ["EN"] = {
                        "I'm tired, though I can manage for now.",
                    },
                    ["TL"] = {
                        "I'm tired, though I can manage for now.",
                    },
                },
                ["when"] = {
                    ["needType"] = "fatigue",
                    ["needUrgency"] = {
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
        ["domain"] = "wellbeing",
        ["id"] = "question.wellbeing.unknown",
        ["owner"] = "ProjectHoomans",
        ["variants"] = {
            {
                ["dialogueAct"] = "UNKNOWN",
                ["fallback"] = "I can tell something is off, but I do not know what caused it yet.",
                ["id"] = "question.wellbeing.unknown.dataset.causal_followup",
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
                ["translations"] = {
                    ["EN"] = {
                        "I can tell something is off, but I do not know what caused it yet.",
                    },
                    ["TL"] = {
                        "Alam kong may hindi tama, pero hindi ko pa alam kung ano ang sanhi nito.",
                    },
                },
                ["when"] = {
                    ["healthState"] = "unknown",
                    ["pattern"] = "pnc.dataset.question.wellbeing.what_is_going_on_with_you",
                },
            },
        },
    },
    {
        ["domain"] = "general",
        ["id"] = "refuse",
        ["owner"] = "ProjectHoomans",
        ["variants"] = {
            {
                ["dialogueAct"] = "REFUSE",
                ["fallback"] = "I can't take that on right now.",
                ["id"] = "refuse.dataset.pending_unavailable",
                ["priority"] = 1,
                ["templateID"] = "refuse.dataset.pending_unavailable",
                ["translations"] = {
                    ["EN"] = {
                        "I can't take that on right now.",
                    },
                    ["TL"] = {
                        "I can't take that on right now.",
                    },
                },
                ["when"] = {
                    ["hasPendingRequest"] = true,
                },
            },
            {
                ["dialogueAct"] = "REFUSE",
                ["fallback"] = "Not this time. I have enough to manage.",
                ["id"] = "refuse.dataset.pending_enough",
                ["priority"] = 1,
                ["templateID"] = "refuse.dataset.pending_enough",
                ["translations"] = {
                    ["EN"] = {
                        "Not this time. I have enough to manage.",
                    },
                    ["TL"] = {
                        "Not this time. I have enough to manage.",
                    },
                },
                ["when"] = {
                    ["hasPendingRequest"] = true,
                },
            },
        },
    },
    {
        ["domain"] = "general",
        ["id"] = "thanks",
        ["owner"] = "ProjectHoomans",
        ["variants"] = {
            {
                ["dialogueAct"] = "THANKS",
                ["fallback"] = "No problem at all.",
                ["id"] = "thanks.dataset.no_problem",
                ["templateID"] = "thanks.dataset.no_problem",
                ["translations"] = {
                    ["EN"] = {
                        "No problem at all.",
                    },
                    ["TL"] = {
                        "No problem at all.",
                    },
                },
            },
            {
                ["dialogueAct"] = "THANKS",
                ["fallback"] = "Anytime.",
                ["id"] = "thanks.dataset.anytime",
                ["templateID"] = "thanks.dataset.anytime",
                ["translations"] = {
                    ["EN"] = {
                        "Anytime.",
                    },
                    ["TL"] = {
                        "Anytime.",
                    },
                },
            },
            {
                ["dialogueAct"] = "THANKS",
                ["fallback"] = "Glad I could help.",
                ["id"] = "thanks.dataset.glady",
                ["templateID"] = "thanks.dataset.glady",
                ["translations"] = {
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
}
