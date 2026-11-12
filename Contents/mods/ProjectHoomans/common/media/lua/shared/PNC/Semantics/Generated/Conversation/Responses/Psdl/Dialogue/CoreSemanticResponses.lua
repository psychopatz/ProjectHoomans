-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "accept",
        ["id"] = "semantic.accept",
        ["variants"] = {
            {
                ["dialogueAct"] = "ACCEPT",
                ["fallback"] = "Okay, I'll get started.",
                ["id"] = "semantic.accept.dataset.pending_started",
                ["priority"] = 1,
                ["templateID"] = "semantic.accept.dataset.pending_started",
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
                ["id"] = "semantic.accept.dataset.pending_care",
                ["priority"] = 1,
                ["templateID"] = "semantic.accept.dataset.pending_care",
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
        ["domain"] = "compliment",
        ["id"] = "semantic.compliment",
        ["variants"] = {
            {
                ["dialogueAct"] = "COMPLIMENT",
                ["fallback"] = "That's kind of you. I appreciate it.",
                ["id"] = "semantic.compliment.dataset.kind_of_you",
                ["templateID"] = "semantic.compliment.dataset.kind_of_you",
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
                ["id"] = "semantic.compliment.dataset.means_a_lot",
                ["templateID"] = "semantic.compliment.dataset.means_a_lot",
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
        ["domain"] = "flow",
        ["id"] = "semantic.flow.weather.raining",
        ["variants"] = {
            {
                ["dialogueAct"] = "RAINING",
                ["fallback"] = "It is raining right now. We can return to that proposal when you are ready.",
                ["id"] = "semantic.flow.weather.raining.dataset.contextual_switch",
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
        ["domain"] = "greeting",
        ["id"] = "semantic.greeting",
        ["variants"] = {
            {
                ["dialogueAct"] = "GREETING",
                ["fallback"] = "Hey. How are you holding up?",
                ["id"] = "semantic.greeting.dataset.holding_up",
                ["templateID"] = "semantic.greeting.dataset.holding_up",
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
                ["id"] = "semantic.greeting.dataset.good_to_see",
                ["templateID"] = "semantic.greeting.dataset.good_to_see",
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
                ["id"] = "semantic.greeting.dataset.how_things",
                ["templateID"] = "semantic.greeting.dataset.how_things",
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
        ["domain"] = "offer",
        ["id"] = "semantic.offer",
        ["variants"] = {
            {
                ["dialogueAct"] = "OFFER",
                ["fallback"] = "That would help a lot. Could I have some?",
                ["id"] = "semantic.offer.dataset.hungry_share",
                ["priority"] = 2,
                ["templateID"] = "semantic.offer.dataset.hungry_share",
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
                ["id"] = "semantic.offer.dataset.hungry_appreciate",
                ["priority"] = 2,
                ["templateID"] = "semantic.offer.dataset.hungry_appreciate",
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
        ["domain"] = "question",
        ["id"] = "semantic.question.activity",
        ["variants"] = {
            {
                ["dialogueAct"] = "ACTIVITY",
                ["fallback"] = "Just doing what I can to keep things moving.",
                ["id"] = "semantic.question.activity.dataset.keep_moving",
                ["templateID"] = "semantic.question.activity.dataset.keep_moving",
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
                ["id"] = "semantic.question.activity.dataset.bit_of_everything",
                ["templateID"] = "semantic.question.activity.dataset.bit_of_everything",
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
                ["id"] = "semantic.question.activity.dataset.taking_care",
                ["templateID"] = "semantic.question.activity.dataset.taking_care",
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
        ["domain"] = "question",
        ["id"] = "semantic.question.backstory.ambiguous",
        ["variants"] = {
            {
                ["dialogueAct"] = "AMBIGUOUS",
                ["fallback"] = "Which part of my past do you mean?",
                ["id"] = "semantic.question.backstory.ambiguous.authored",
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
        ["domain"] = "question",
        ["id"] = "semantic.question.backstory.follow_up.location",
        ["variants"] = {
            {
                ["dialogueAct"] = "LOCATION",
                ["fallback"] = "I remember that part of my life, but I don't have more detail about where it was.",
                ["id"] = "semantic.question.backstory.follow_up.location.authored",
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
        ["domain"] = "question",
        ["id"] = "semantic.question.backstory.follow_up.miss",
        ["variants"] = {
            {
                ["dialogueAct"] = "MISS",
                ["fallback"] = "Sometimes. I still think about that part of my life.",
                ["id"] = "semantic.question.backstory.follow_up.miss.authored",
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
        ["domain"] = "question",
        ["id"] = "semantic.question.backstory.known",
        ["variants"] = {
            {
                ["dialogueAct"] = "KNOWN",
                ["fallback"] = "Before all this, I was %1.",
                ["id"] = "semantic.question.backstory.known.authored",
                ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryKnown",
                ["translationArgs"] = {
                    ["content"] = "fact_content",
                },
                ["translations"] = {
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
    {
        ["domain"] = "question",
        ["id"] = "semantic.question.backstory.known.education",
        ["variants"] = {
            {
                ["dialogueAct"] = "EDUCATION",
                ["fallback"] = "I studied %1.",
                ["id"] = "semantic.question.backstory.known.education.authored",
                ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryEducation",
                ["translationArgs"] = {
                    ["content"] = "fact_content",
                },
                ["translations"] = {
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
    {
        ["domain"] = "question",
        ["id"] = "semantic.question.backstory.known.family_background",
        ["variants"] = {
            {
                ["dialogueAct"] = "FAMILY_BACKGROUND",
                ["fallback"] = "My family was %1.",
                ["id"] = "semantic.question.backstory.known.family_background.authored",
                ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryFamily",
                ["translationArgs"] = {
                    ["content"] = "fact_content",
                },
                ["translations"] = {
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
    {
        ["domain"] = "question",
        ["id"] = "semantic.question.backstory.known.fear",
        ["variants"] = {
            {
                ["dialogueAct"] = "FEAR",
                ["fallback"] = "I have always been afraid of %1.",
                ["id"] = "semantic.question.backstory.known.fear.authored",
                ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryFear",
                ["translationArgs"] = {
                    ["content"] = "fact_content",
                },
                ["translations"] = {
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
    {
        ["domain"] = "question",
        ["id"] = "semantic.question.backstory.known.former_job",
        ["variants"] = {
            {
                ["dialogueAct"] = "FORMER_JOB",
                ["fallback"] = "I worked as %1 before all this.",
                ["id"] = "semantic.question.backstory.known.former_job.authored",
                ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryFormerJob",
                ["translationArgs"] = {
                    ["content"] = "fact_content",
                },
                ["translations"] = {
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
    {
        ["domain"] = "question",
        ["id"] = "semantic.question.backstory.known.hobby",
        ["variants"] = {
            {
                ["dialogueAct"] = "HOBBY",
                ["fallback"] = "I used to enjoy %1.",
                ["id"] = "semantic.question.backstory.known.hobby.authored",
                ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryHobby",
                ["translationArgs"] = {
                    ["content"] = "fact_content",
                },
                ["translations"] = {
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
    {
        ["domain"] = "question",
        ["id"] = "semantic.question.backstory.known.hometown",
        ["variants"] = {
            {
                ["dialogueAct"] = "HOMETOWN",
                ["fallback"] = "I grew up in %1.",
                ["id"] = "semantic.question.backstory.known.hometown.authored",
                ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryHometown",
                ["translationArgs"] = {
                    ["content"] = "fact_content",
                },
                ["translations"] = {
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
    {
        ["domain"] = "question",
        ["id"] = "semantic.question.backstory.known.tragedy",
        ["variants"] = {
            {
                ["dialogueAct"] = "TRAGEDY",
                ["fallback"] = "Something happened: %1.",
                ["id"] = "semantic.question.backstory.known.tragedy.authored",
                ["templateID"] = "UI_PNC_Conversation_Semantic_QuestionBackstoryTragedy",
                ["translationArgs"] = {
                    ["content"] = "fact_content",
                },
                ["translations"] = {
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
    {
        ["domain"] = "question",
        ["id"] = "semantic.question.backstory.refusal",
        ["variants"] = {
            {
                ["dialogueAct"] = "REFUSAL",
                ["fallback"] = "I'm not ready to talk about that yet.",
                ["id"] = "semantic.question.backstory.refusal.authored",
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
        ["domain"] = "question",
        ["id"] = "semantic.question.backstory.suspected",
        ["variants"] = {
            {
                ["dialogueAct"] = "SUSPECTED",
                ["fallback"] = "I think it was %1, but I could be mistaken.",
                ["id"] = "semantic.question.backstory.suspected.authored",
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
        ["domain"] = "question",
        ["id"] = "semantic.question.identity",
        ["variants"] = {
            {
                ["dialogueAct"] = "IDENTITY",
                ["fallback"] = "I keep my name to myself until I know someone better. What should I call you?",
                ["id"] = "semantic.question.identity.dataset.stranger_alt_1",
                ["templateID"] = "semantic.question.identity.stranger_alt_1",
                ["translations"] = {
                    ["EN"] = {
                        "I keep my name to myself until I know someone better. What should I call you?",
                    },
                    ["TL"] = {
                        "I keep my name to myself until I know someone better. What should I call you?",
                    },
                },
            },
            {
                ["dialogueAct"] = "IDENTITY",
                ["fallback"] = "Let's get to know each other first. What do people call you?",
                ["id"] = "semantic.question.identity.dataset.stranger_alt_2",
                ["templateID"] = "semantic.question.identity.stranger_alt_2",
                ["translations"] = {
                    ["EN"] = {
                        "Let's get to know each other first. What do people call you?",
                    },
                    ["TL"] = {
                        "Let's get to know each other first. What do people call you?",
                    },
                },
            },
            {
                ["dialogueAct"] = "IDENTITY",
                ["fallback"] = "I don't trust you enough to share my name. Who are you, really?",
                ["id"] = "semantic.question.identity.dataset.wary_alt_1",
                ["priority"] = 2,
                ["templateID"] = "semantic.question.identity.wary_alt_1",
                ["translations"] = {
                    ["EN"] = {
                        "I don't trust you enough to share my name. Who are you, really?",
                    },
                    ["TL"] = {
                        "I don't trust you enough to share my name. Who are you, really?",
                    },
                },
                ["when"] = {
                    ["identityTrust"] = "untrustworthy",
                },
            },
            {
                ["dialogueAct"] = "IDENTITY",
                ["fallback"] = "After that lie, I'm not telling you my name. Tell me the truth about yours.",
                ["id"] = "semantic.question.identity.dataset.wary_alt_2",
                ["priority"] = 2,
                ["templateID"] = "semantic.question.identity.wary_alt_2",
                ["translations"] = {
                    ["EN"] = {
                        "After that lie, I'm not telling you my name. Tell me the truth about yours.",
                    },
                    ["TL"] = {
                        "After that lie, I'm not telling you my name. Tell me the truth about yours.",
                    },
                },
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
                ["dialogueAct"] = "PROPOSAL",
                ["fallback"] = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                ["id"] = "semantic.question.needs.proposal.dataset.thirst",
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
                ["translations"] = {
                    ["EN"] = {
                        "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                    },
                    ["TL"] = {
                        "Maaari ko iyong ituring na panukala, pero kailangan ko pa ang item at dami bago ako magtala ng pangako.",
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
        },
    },
    {
        ["domain"] = "question",
        ["id"] = "semantic.question.needs.quantity",
        ["variants"] = {
            {
                ["dialogueAct"] = "QUANTITY",
                ["fallback"] = "I can confirm water is a need, but which item do you mean?",
                ["id"] = "semantic.question.needs.quantity.dataset.clarify_thirst",
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
                ["translations"] = {
                    ["EN"] = {
                        "I can confirm water is a need, but which item do you mean?",
                    },
                    ["TL"] = {
                        "Makukumpirma kong kailangan ang tubig, pero aling item ang ibig mong sabihin?",
                    },
                },
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
                ["dialogueAct"] = "WELLBEING",
                ["fallback"] = "I'm hanging in there. Thanks for asking.",
                ["id"] = "semantic.question.wellbeing.dataset.hanging_in",
                ["templateID"] = "semantic.question.wellbeing.dataset.hanging_in",
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
                ["id"] = "semantic.question.wellbeing.dataset.all_things_considered",
                ["templateID"] = "semantic.question.wellbeing.dataset.all_things_considered",
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
                ["id"] = "semantic.question.wellbeing.dataset.getting_by",
                ["templateID"] = "semantic.question.wellbeing.dataset.getting_by",
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
                ["id"] = "semantic.question.wellbeing.dataset.hungry",
                ["priority"] = 2,
                ["templateID"] = "semantic.question.wellbeing.dataset.hungry",
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
                ["id"] = "semantic.question.wellbeing.dataset.thirsty",
                ["priority"] = 3,
                ["templateID"] = "semantic.question.wellbeing.dataset.thirsty",
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
                ["id"] = "semantic.question.wellbeing.dataset.tired",
                ["priority"] = 2,
                ["templateID"] = "semantic.question.wellbeing.dataset.tired",
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
        ["domain"] = "question",
        ["id"] = "semantic.question.wellbeing.unknown",
        ["variants"] = {
            {
                ["dialogueAct"] = "UNKNOWN",
                ["fallback"] = "I can tell something is off, but I do not know what caused it yet.",
                ["id"] = "semantic.question.wellbeing.unknown.dataset.causal_followup",
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
        ["domain"] = "refuse",
        ["id"] = "semantic.refuse",
        ["variants"] = {
            {
                ["dialogueAct"] = "REFUSE",
                ["fallback"] = "I can't take that on right now.",
                ["id"] = "semantic.refuse.dataset.pending_unavailable",
                ["priority"] = 1,
                ["templateID"] = "semantic.refuse.dataset.pending_unavailable",
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
                ["id"] = "semantic.refuse.dataset.pending_enough",
                ["priority"] = 1,
                ["templateID"] = "semantic.refuse.dataset.pending_enough",
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
        ["domain"] = "thanks",
        ["id"] = "semantic.thanks",
        ["variants"] = {
            {
                ["dialogueAct"] = "THANKS",
                ["fallback"] = "No problem at all.",
                ["id"] = "semantic.thanks.dataset.no_problem",
                ["templateID"] = "semantic.thanks.dataset.no_problem",
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
                ["id"] = "semantic.thanks.dataset.anytime",
                ["templateID"] = "semantic.thanks.dataset.anytime",
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
                ["id"] = "semantic.thanks.dataset.glady",
                ["templateID"] = "semantic.thanks.dataset.glady",
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
