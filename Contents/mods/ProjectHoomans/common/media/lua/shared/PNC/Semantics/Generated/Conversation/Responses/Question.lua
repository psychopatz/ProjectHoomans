-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "question",
        ["id"] = "semantic.question.activity",
        ["variants"] = {
            {
                ["fallback"] = "Just doing what I can to keep things moving.",
                ["id"] = "semantic.question.activity.dataset.keep_moving",
                ["templateID"] = "semantic.question.activity.dataset.keep_moving",
            },
            {
                ["fallback"] = "A little bit of everything.",
                ["id"] = "semantic.question.activity.dataset.bit_of_everything",
                ["templateID"] = "semantic.question.activity.dataset.bit_of_everything",
            },
            {
                ["fallback"] = "Just taking care of what needs doing.",
                ["id"] = "semantic.question.activity.dataset.taking_care",
                ["templateID"] = "semantic.question.activity.dataset.taking_care",
            },
        },
    },
    {
        ["domain"] = "question",
        ["id"] = "semantic.question.backstory.ambiguous",
        ["variants"] = {
            {
                ["fallback"] = "Which part of my past do you mean?",
                ["id"] = "semantic.question.backstory.ambiguous.generated",
                ["metadata"] = {
                    ["translationKey"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryAmbiguous",
                },
                ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryAmbiguous",
            },
        },
    },
    {
        ["domain"] = "question",
        ["id"] = "semantic.question.backstory.follow_up.location",
        ["variants"] = {
            {
                ["fallback"] = "I remember that part of my life, but I don't have more detail about where it was.",
                ["id"] = "semantic.question.backstory.follow_up.location.generated",
                ["metadata"] = {
                    ["translationKey"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryFollowUpLocation",
                },
                ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryFollowUpLocation",
            },
        },
    },
    {
        ["domain"] = "question",
        ["id"] = "semantic.question.backstory.follow_up.miss",
        ["variants"] = {
            {
                ["fallback"] = "Sometimes. I still think about that part of my life.",
                ["id"] = "semantic.question.backstory.follow_up.miss.generated",
                ["metadata"] = {
                    ["translationKey"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryFollowUpMiss",
                },
                ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryFollowUpMiss",
            },
        },
    },
    {
        ["domain"] = "question",
        ["id"] = "semantic.question.backstory.known",
        ["variants"] = {
            {
                ["fallback"] = "Before all this, I was %1.",
                ["id"] = "semantic.question.backstory.known.generated",
                ["metadata"] = {
                    ["translationKey"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryKnown",
                },
                ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryKnown",
                ["translationArgs"] = {
                    ["content"] = "fact_content",
                },
            },
        },
    },
    {
        ["domain"] = "question",
        ["id"] = "semantic.question.backstory.known.education",
        ["variants"] = {
            {
                ["fallback"] = "I studied %1.",
                ["id"] = "semantic.question.backstory.known.education.generated",
                ["metadata"] = {
                    ["translationKey"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryEducation",
                },
                ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryEducation",
                ["translationArgs"] = {
                    ["content"] = "fact_content",
                },
            },
        },
    },
    {
        ["domain"] = "question",
        ["id"] = "semantic.question.backstory.known.family_background",
        ["variants"] = {
            {
                ["fallback"] = "My family was %1.",
                ["id"] = "semantic.question.backstory.known.family_background.generated",
                ["metadata"] = {
                    ["translationKey"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryFamily",
                },
                ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryFamily",
                ["translationArgs"] = {
                    ["content"] = "fact_content",
                },
            },
        },
    },
    {
        ["domain"] = "question",
        ["id"] = "semantic.question.backstory.known.fear",
        ["variants"] = {
            {
                ["fallback"] = "I have always been afraid of %1.",
                ["id"] = "semantic.question.backstory.known.fear.generated",
                ["metadata"] = {
                    ["translationKey"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryFear",
                },
                ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryFear",
                ["translationArgs"] = {
                    ["content"] = "fact_content",
                },
            },
        },
    },
    {
        ["domain"] = "question",
        ["id"] = "semantic.question.backstory.known.former_job",
        ["variants"] = {
            {
                ["fallback"] = "I worked as %1 before all this.",
                ["id"] = "semantic.question.backstory.known.former_job.generated",
                ["metadata"] = {
                    ["translationKey"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryFormerJob",
                },
                ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryFormerJob",
                ["translationArgs"] = {
                    ["content"] = "fact_content",
                },
            },
        },
    },
    {
        ["domain"] = "question",
        ["id"] = "semantic.question.backstory.known.hobby",
        ["variants"] = {
            {
                ["fallback"] = "I used to enjoy %1.",
                ["id"] = "semantic.question.backstory.known.hobby.generated",
                ["metadata"] = {
                    ["translationKey"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryHobby",
                },
                ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryHobby",
                ["translationArgs"] = {
                    ["content"] = "fact_content",
                },
            },
        },
    },
    {
        ["domain"] = "question",
        ["id"] = "semantic.question.backstory.known.hometown",
        ["variants"] = {
            {
                ["fallback"] = "I grew up in %1.",
                ["id"] = "semantic.question.backstory.known.hometown.generated",
                ["metadata"] = {
                    ["translationKey"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryHometown",
                },
                ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryHometown",
                ["translationArgs"] = {
                    ["content"] = "fact_content",
                },
            },
        },
    },
    {
        ["domain"] = "question",
        ["id"] = "semantic.question.backstory.known.tragedy",
        ["variants"] = {
            {
                ["fallback"] = "Something happened: %1.",
                ["id"] = "semantic.question.backstory.known.tragedy.generated",
                ["metadata"] = {
                    ["translationKey"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryTragedy",
                },
                ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryTragedy",
                ["translationArgs"] = {
                    ["content"] = "fact_content",
                },
            },
        },
    },
    {
        ["domain"] = "question",
        ["id"] = "semantic.question.backstory.refusal",
        ["variants"] = {
            {
                ["fallback"] = "I'm not ready to talk about that yet.",
                ["id"] = "semantic.question.backstory.refusal.generated",
                ["metadata"] = {
                    ["translationKey"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryRefusal",
                },
                ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryRefusal",
            },
        },
    },
    {
        ["domain"] = "question",
        ["id"] = "semantic.question.backstory.suspected",
        ["variants"] = {
            {
                ["fallback"] = "I think it was %1, but I could be mistaken.",
                ["id"] = "semantic.question.backstory.suspected.generated",
                ["metadata"] = {
                    ["translationKey"] = "UI_PNC_Conversation_Semantic_QuestionBackstorySuspected",
                },
                ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstorySuspected",
                ["translationArgs"] = {
                    ["content"] = "fact_content",
                },
            },
        },
    },
    {
        ["domain"] = "question",
        ["id"] = "semantic.question.identity",
        ["variants"] = {
            {
                ["fallback"] = "I keep my name to myself until I know someone better. What should I call you?",
                ["id"] = "semantic.question.identity.dataset.stranger_alt_1",
                ["templateID"] = "semantic.question.identity.stranger_alt_1",
            },
            {
                ["fallback"] = "Let's get to know each other first. What do people call you?",
                ["id"] = "semantic.question.identity.dataset.stranger_alt_2",
                ["templateID"] = "semantic.question.identity.stranger_alt_2",
            },
            {
                ["fallback"] = "I don't trust you enough to share my name. Who are you, really?",
                ["id"] = "semantic.question.identity.dataset.wary_alt_1",
                ["priority"] = 2,
                ["templateID"] = "semantic.question.identity.wary_alt_1",
                ["when"] = {
                    ["identityTrust"] = "untrustworthy",
                },
            },
            {
                ["fallback"] = "After that lie, I'm not telling you my name. Tell me the truth about yours.",
                ["id"] = "semantic.question.identity.dataset.wary_alt_2",
                ["priority"] = 2,
                ["templateID"] = "semantic.question.identity.wary_alt_2",
                ["when"] = {
                    ["identityTrust"] = "untrustworthy",
                },
            },
        },
    },
    {
        ["domain"] = "question",
        ["id"] = "semantic.question.needs.proposal",
        ["variants"] = {
            {
                ["fallback"] = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                ["id"] = "semantic.question.needs.proposal.dataset.thirst",
                ["metadata"] = {
                    ["reviewed"] = true,
                    ["sourceRefs"] = {
                        "MASSIVE",
                        "SGD",
                    },
                    ["translationKey"] = "UI_PNC_Conversation_Semantic_DatasetNeedsPromiseThirst",
                },
                ["plan"] = {
                    ["dialogueAct"] = "PROMISE_ACKNOWLEDGEMENT",
                    ["groundedFactRefs"] = {
                        "npc.needs.thirst",
                    },
                    ["personalityStyle"] = nil,
                    ["referenceSubject"] = nil,
                    ["referenceTopic"] = nil,
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
                                    ["translationArgs"] = {
                                    },
                                },
                            },
                        },
                    },
                    ["uncertainty"] = "pending",
                },
                ["priority"] = 4,
                ["templateID"] = "UI_PNC_Conversation_Semantic_DatasetNeedsPromiseThirst",
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
        },
    },
    {
        ["domain"] = "question",
        ["id"] = "semantic.question.needs.quantity",
        ["variants"] = {
            {
                ["fallback"] = "I can confirm water is a need, but which item do you mean?",
                ["id"] = "semantic.question.needs.quantity.dataset.clarify_thirst",
                ["metadata"] = {
                    ["reviewed"] = true,
                    ["sourceRefs"] = {
                        "MASSIVE",
                        "SGD",
                    },
                    ["translationKey"] = "UI_PNC_Conversation_Semantic_DatasetNeedsClarifyThirst",
                },
                ["plan"] = {
                    ["dialogueAct"] = "ASK_CLARIFICATION",
                    ["groundedFactRefs"] = {
                        "npc.needs.thirst",
                    },
                    ["personalityStyle"] = nil,
                    ["referenceSubject"] = nil,
                    ["referenceTopic"] = nil,
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
                                    ["translationArgs"] = {
                                    },
                                },
                            },
                        },
                    },
                    ["uncertainty"] = "ambiguous",
                },
                ["priority"] = 4,
                ["templateID"] = "UI_PNC_Conversation_Semantic_DatasetNeedsClarifyThirst",
                ["when"] = {
                    ["lastIntent"] = "CLARIFY",
                    ["needType"] = "thirst",
                },
            },
        },
    },
    {
        ["domain"] = "question",
        ["id"] = "semantic.question.wellbeing",
        ["variants"] = {
            {
                ["fallback"] = "I'm hanging in there. Thanks for asking.",
                ["id"] = "semantic.question.wellbeing.dataset.hanging_in",
                ["templateID"] = "semantic.question.wellbeing.dataset.hanging_in",
            },
            {
                ["fallback"] = "Doing okay, all things considered.",
                ["id"] = "semantic.question.wellbeing.dataset.all_things_considered",
                ["templateID"] = "semantic.question.wellbeing.dataset.all_things_considered",
            },
            {
                ["fallback"] = "I'm getting by, one day at a time. How about you?",
                ["id"] = "semantic.question.wellbeing.dataset.getting_by",
                ["templateID"] = "semantic.question.wellbeing.dataset.getting_by",
            },
            {
                ["fallback"] = "I'm hungry, but I'll manage. If you have food to spare, I'd appreciate it.",
                ["id"] = "semantic.question.wellbeing.dataset.hungry",
                ["priority"] = 2,
                ["templateID"] = "semantic.question.wellbeing.dataset.hungry",
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
                ["fallback"] = "I'm pretty thirsty. If you have water, could you spare some?",
                ["id"] = "semantic.question.wellbeing.dataset.thirsty",
                ["priority"] = 3,
                ["templateID"] = "semantic.question.wellbeing.dataset.thirsty",
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
                ["fallback"] = "I'm tired, though I can manage for now.",
                ["id"] = "semantic.question.wellbeing.dataset.tired",
                ["priority"] = 2,
                ["templateID"] = "semantic.question.wellbeing.dataset.tired",
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
        ["domain"] = "question",
        ["id"] = "semantic.question.wellbeing.unknown",
        ["variants"] = {
            {
                ["fallback"] = "I can tell something is off, but I do not know what caused it yet.",
                ["id"] = "semantic.question.wellbeing.unknown.dataset.causal_followup",
                ["metadata"] = {
                    ["reviewed"] = true,
                    ["sourceRefs"] = {
                        "MASSIVE",
                        "SGD",
                    },
                    ["translationKey"] = "UI_PNC_Conversation_Semantic_DatasetWellbeingCausalUnknown",
                },
                ["plan"] = {
                    ["dialogueAct"] = "ASK_CLARIFICATION",
                    ["groundedFactRefs"] = {
                    },
                    ["personalityStyle"] = "truthful",
                    ["referenceSubject"] = nil,
                    ["referenceTopic"] = nil,
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
                                    ["translationArgs"] = {
                                    },
                                },
                            },
                        },
                    },
                    ["uncertainty"] = "unknown",
                },
                ["priority"] = 4,
                ["templateID"] = "UI_PNC_Conversation_Semantic_DatasetWellbeingCausalUnknown",
                ["when"] = {
                    ["healthState"] = "unknown",
                    ["pattern"] = "pnc.dataset.question.wellbeing.what_is_going_on_with_you",
                },
            },
        },
    },
}
