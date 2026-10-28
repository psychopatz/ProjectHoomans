-- Generated; do not edit by hand.
return {
    {
        ["confidence"] = 0.99,
        ["domain"] = "question",
        ["emit"] = {
            ["extensions"] = {
                ["disclosure"] = "server_authorized",
                ["factProvider"] = "npc_backstory",
                ["topicID"] = "backstory.fear",
            },
            ["intent"] = "QUESTION",
            ["slots"] = {
                ["backstoryKind"] = "fear",
            },
            ["speechAct"] = "QUESTION",
            ["subject"] = "NPC_BACKSTORY",
        },
        ["id"] = "pnc.backstory.question.fear.private",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "what",
            },
            {
                ["kind"] = "literal",
                ["value"] = "are",
            },
            {
                ["kind"] = "literal",
                ["value"] = "you",
            },
            {
                ["kind"] = "literal",
                ["value"] = "afraid",
            },
            {
                ["kind"] = "literal",
                ["value"] = "of",
            },
        },
        ["metadata"] = {
            ["mapping"] = {
                ["canonicalConcept"] = "NPC_BACKSTORY",
                ["dialogueState"] = "BACKSTORY_QUESTION",
                ["sourceRefs"] = {
                    "Project Hoomans Authoring Review",
                },
            },
            ["reviewed"] = true,
            ["sourceRefs"] = {
                "Project Hoomans Authoring Review",
            },
        },
        ["priority"] = 150,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "question",
        ["emit"] = {
            ["extensions"] = {
                ["disclosure"] = "server_authorized",
                ["factProvider"] = "npc_backstory",
                ["topicID"] = "backstory.former_job",
            },
            ["intent"] = "QUESTION",
            ["slots"] = {
                ["backstoryKind"] = "former_job",
            },
            ["speechAct"] = "QUESTION",
            ["subject"] = "NPC_BACKSTORY",
        },
        ["id"] = "pnc.backstory.question.former_job.before_all_this",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "what",
            },
            {
                ["kind"] = "literal",
                ["value"] = "did",
            },
            {
                ["kind"] = "literal",
                ["value"] = "you",
            },
            {
                ["kind"] = "literal",
                ["value"] = "do",
            },
            {
                ["kind"] = "literal",
                ["value"] = "before",
            },
        },
        ["metadata"] = {
            ["mapping"] = {
                ["canonicalConcept"] = "NPC_BACKSTORY",
                ["dialogueState"] = "BACKSTORY_QUESTION",
                ["sourceRefs"] = {
                    "Project Hoomans Authoring Review",
                },
            },
            ["reviewed"] = true,
            ["sourceRefs"] = {
                "Project Hoomans Authoring Review",
            },
        },
        ["priority"] = 150,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "question",
        ["emit"] = {
            ["extensions"] = {
                ["disclosure"] = "server_authorized",
                ["factProvider"] = "npc_backstory",
                ["topicID"] = "backstory.former_job",
            },
            ["intent"] = "QUESTION",
            ["slots"] = {
                ["backstoryKind"] = "former_job",
            },
            ["speechAct"] = "QUESTION",
            ["subject"] = "NPC_BACKSTORY",
        },
        ["id"] = "pnc.backstory.question.former_job.old_job",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "what",
            },
            {
                ["kind"] = "literal",
                ["value"] = "was",
            },
            {
                ["kind"] = "literal",
                ["value"] = "your",
            },
            {
                ["kind"] = "literal",
                ["value"] = "old",
            },
            {
                ["kind"] = "literal",
                ["value"] = "job",
            },
        },
        ["metadata"] = {
            ["mapping"] = {
                ["canonicalConcept"] = "NPC_BACKSTORY",
                ["dialogueState"] = "BACKSTORY_QUESTION",
                ["sourceRefs"] = {
                    "Project Hoomans Authoring Review",
                },
            },
            ["reviewed"] = true,
            ["sourceRefs"] = {
                "Project Hoomans Authoring Review",
            },
        },
        ["priority"] = 151,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "question",
        ["emit"] = {
            ["extensions"] = {
                ["disclosure"] = "server_authorized",
                ["factProvider"] = "npc_backstory",
                ["topicID"] = "backstory.hobby",
            },
            ["intent"] = "QUESTION",
            ["slots"] = {
                ["backstoryKind"] = "hobby",
            },
            ["speechAct"] = "QUESTION",
            ["subject"] = "NPC_BACKSTORY",
        },
        ["id"] = "pnc.backstory.question.hobby.interest",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "what",
            },
            {
                ["kind"] = "literal",
                ["value"] = "is",
            },
            {
                ["kind"] = "literal",
                ["value"] = "your",
            },
            {
                ["kind"] = "literal",
                ["value"] = "hobby",
            },
        },
        ["metadata"] = {
            ["mapping"] = {
                ["canonicalConcept"] = "NPC_BACKSTORY",
                ["dialogueState"] = "BACKSTORY_QUESTION",
                ["sourceRefs"] = {
                    "Project Hoomans Authoring Review",
                },
            },
            ["reviewed"] = true,
            ["sourceRefs"] = {
                "Project Hoomans Authoring Review",
            },
        },
        ["priority"] = 150,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "question",
        ["emit"] = {
            ["extensions"] = {
                ["disclosure"] = "server_authorized",
                ["factProvider"] = "npc_backstory",
                ["topicID"] = "backstory.hometown",
            },
            ["intent"] = "QUESTION",
            ["slots"] = {
                ["backstoryKind"] = "hometown",
            },
            ["speechAct"] = "QUESTION",
            ["subject"] = "NPC_BACKSTORY",
        },
        ["id"] = "pnc.backstory.question.hometown.grew_up",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "where",
            },
            {
                ["kind"] = "literal",
                ["value"] = "did",
            },
            {
                ["kind"] = "literal",
                ["value"] = "you",
            },
            {
                ["kind"] = "literal",
                ["value"] = "grow",
            },
            {
                ["kind"] = "literal",
                ["value"] = "up",
            },
        },
        ["metadata"] = {
            ["mapping"] = {
                ["canonicalConcept"] = "NPC_BACKSTORY",
                ["dialogueState"] = "BACKSTORY_QUESTION",
                ["sourceRefs"] = {
                    "Project Hoomans Authoring Review",
                },
            },
            ["reviewed"] = true,
            ["sourceRefs"] = {
                "Project Hoomans Authoring Review",
            },
        },
        ["priority"] = 150,
    },
    {
        ["confidence"] = 0.97,
        ["domain"] = "question",
        ["emit"] = {
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "ACTIVITY",
        },
        ["id"] = "pnc.dataset.question.activity.what_are_you_focused_on",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "what",
            },
            {
                ["kind"] = "literal",
                ["value"] = "are",
            },
            {
                ["kind"] = "literal",
                ["value"] = "you",
            },
            {
                ["kind"] = "literal",
                ["value"] = "focused",
            },
            {
                ["kind"] = "literal",
                ["value"] = "on",
            },
        },
        ["priority"] = 120,
    },
    {
        ["confidence"] = 0.98,
        ["domain"] = "question",
        ["emit"] = {
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "ACTIVITY",
        },
        ["id"] = "pnc.dataset.question.activity.what_are_you_working_on",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "what",
            },
            {
                ["kind"] = "literal",
                ["value"] = "are",
            },
            {
                ["kind"] = "literal",
                ["value"] = "you",
            },
            {
                ["kind"] = "literal",
                ["value"] = "working",
            },
            {
                ["kind"] = "literal",
                ["value"] = "on",
            },
        },
        ["priority"] = 120,
    },
    {
        ["confidence"] = 0.98,
        ["domain"] = "question",
        ["emit"] = {
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "ACTIVITY",
        },
        ["id"] = "pnc.dataset.question.activity.what_have_you_been_doing_today",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "what",
            },
            {
                ["kind"] = "literal",
                ["value"] = "have",
            },
            {
                ["kind"] = "literal",
                ["value"] = "you",
            },
            {
                ["kind"] = "literal",
                ["value"] = "been",
            },
            {
                ["kind"] = "literal",
                ["value"] = "doing",
            },
            {
                ["kind"] = "literal",
                ["value"] = "today",
            },
        },
        ["priority"] = 120,
    },
    {
        ["confidence"] = 0.98,
        ["domain"] = "question",
        ["emit"] = {
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "ACTIVITY",
        },
        ["id"] = "pnc.dataset.question.activity.what_have_you_been_up_to_lately",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "what",
            },
            {
                ["kind"] = "literal",
                ["value"] = "have",
            },
            {
                ["kind"] = "literal",
                ["value"] = "you",
            },
            {
                ["kind"] = "literal",
                ["value"] = "been",
            },
            {
                ["kind"] = "literal",
                ["value"] = "up",
            },
            {
                ["kind"] = "literal",
                ["value"] = "to",
            },
            {
                ["kind"] = "literal",
                ["value"] = "lately",
            },
        },
        ["priority"] = 120,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "question",
        ["emit"] = {
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "IDENTITY",
        },
        ["id"] = "pnc.dataset.question.identity.can_i_ask_your_name",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "can",
            },
            {
                ["kind"] = "literal",
                ["value"] = "i",
            },
            {
                ["kind"] = "literal",
                ["value"] = "ask",
            },
            {
                ["kind"] = "literal",
                ["value"] = "your",
            },
            {
                ["kind"] = "literal",
                ["value"] = "name",
            },
        },
        ["priority"] = 120,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "question",
        ["emit"] = {
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "IDENTITY",
        },
        ["id"] = "pnc.dataset.question.identity.can_you_tell_me_your_name",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "can",
            },
            {
                ["kind"] = "literal",
                ["value"] = "you",
            },
            {
                ["kind"] = "literal",
                ["value"] = "tell",
            },
            {
                ["kind"] = "literal",
                ["value"] = "me",
            },
            {
                ["kind"] = "literal",
                ["value"] = "your",
            },
            {
                ["kind"] = "literal",
                ["value"] = "name",
            },
        },
        ["priority"] = 120,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "question",
        ["emit"] = {
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "IDENTITY",
        },
        ["id"] = "pnc.dataset.question.identity.may_i_ask_your_name",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "may",
            },
            {
                ["kind"] = "literal",
                ["value"] = "i",
            },
            {
                ["kind"] = "literal",
                ["value"] = "ask",
            },
            {
                ["kind"] = "literal",
                ["value"] = "your",
            },
            {
                ["kind"] = "literal",
                ["value"] = "name",
            },
        },
        ["priority"] = 120,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "question",
        ["emit"] = {
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "IDENTITY",
        },
        ["id"] = "pnc.dataset.question.identity.may_i_know_your_name",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "may",
            },
            {
                ["kind"] = "literal",
                ["value"] = "i",
            },
            {
                ["kind"] = "literal",
                ["value"] = "know",
            },
            {
                ["kind"] = "literal",
                ["value"] = "your",
            },
            {
                ["kind"] = "literal",
                ["value"] = "name",
            },
        },
        ["priority"] = 120,
    },
    {
        ["confidence"] = 0.98,
        ["domain"] = "question",
        ["emit"] = {
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "IDENTITY",
        },
        ["id"] = "pnc.dataset.question.identity.mind_telling_me_your_name",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "mind",
            },
            {
                ["kind"] = "literal",
                ["value"] = "telling",
            },
            {
                ["kind"] = "literal",
                ["value"] = "me",
            },
            {
                ["kind"] = "literal",
                ["value"] = "your",
            },
            {
                ["kind"] = "literal",
                ["value"] = "name",
            },
        },
        ["priority"] = 120,
    },
    {
        ["confidence"] = 0.98,
        ["domain"] = "question",
        ["emit"] = {
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "IDENTITY",
        },
        ["id"] = "pnc.dataset.question.identity.what_do_people_call_you",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "what",
            },
            {
                ["kind"] = "literal",
                ["value"] = "do",
            },
            {
                ["kind"] = "literal",
                ["value"] = "people",
            },
            {
                ["kind"] = "literal",
                ["value"] = "call",
            },
            {
                ["kind"] = "literal",
                ["value"] = "you",
            },
        },
        ["priority"] = 120,
    },
    {
        ["confidence"] = 0.98,
        ["domain"] = "question",
        ["emit"] = {
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "IDENTITY",
        },
        ["id"] = "pnc.dataset.question.identity.what_do_you_go_by",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "what",
            },
            {
                ["kind"] = "literal",
                ["value"] = "do",
            },
            {
                ["kind"] = "literal",
                ["value"] = "you",
            },
            {
                ["kind"] = "literal",
                ["value"] = "go",
            },
            {
                ["kind"] = "literal",
                ["value"] = "by",
            },
        },
        ["priority"] = 120,
    },
    {
        ["confidence"] = 0.98,
        ["domain"] = "question",
        ["emit"] = {
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "IDENTITY",
        },
        ["id"] = "pnc.dataset.question.identity.what_should_i_call_you",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "what",
            },
            {
                ["kind"] = "literal",
                ["value"] = "should",
            },
            {
                ["kind"] = "literal",
                ["value"] = "i",
            },
            {
                ["kind"] = "literal",
                ["value"] = "call",
            },
            {
                ["kind"] = "literal",
                ["value"] = "you",
            },
        },
        ["priority"] = 120,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "question",
        ["emit"] = {
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "IDENTITY",
        },
        ["id"] = "pnc.dataset.question.identity.who_am_i_speaking_with",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "who",
            },
            {
                ["kind"] = "literal",
                ["value"] = "am",
            },
            {
                ["kind"] = "literal",
                ["value"] = "i",
            },
            {
                ["kind"] = "literal",
                ["value"] = "speaking",
            },
            {
                ["kind"] = "literal",
                ["value"] = "with",
            },
        },
        ["priority"] = 120,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "question",
        ["emit"] = {
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "IDENTITY",
        },
        ["id"] = "pnc.dataset.question.identity.who_am_i_talking_to",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "who",
            },
            {
                ["kind"] = "literal",
                ["value"] = "am",
            },
            {
                ["kind"] = "literal",
                ["value"] = "i",
            },
            {
                ["kind"] = "literal",
                ["value"] = "talking",
            },
            {
                ["kind"] = "literal",
                ["value"] = "to",
            },
        },
        ["priority"] = 120,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "question",
        ["emit"] = {
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "WEATHER",
        },
        ["id"] = "pnc.dataset.question.weather.can_we_talk_about_the_weather",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "can",
            },
            {
                ["kind"] = "literal",
                ["value"] = "we",
            },
            {
                ["kind"] = "literal",
                ["value"] = "talk",
            },
            {
                ["kind"] = "literal",
                ["value"] = "about",
            },
            {
                ["kind"] = "literal",
                ["value"] = "the",
            },
            {
                ["kind"] = "literal",
                ["value"] = "weather",
            },
        },
        ["metadata"] = {
            ["mapping"] = {
                ["canonicalConcept"] = "WEATHER",
                ["dialogueState"] = "WEATHER_TOPIC",
                ["sourceRefs"] = {
                    "MASSIVE",
                    "SGD",
                },
            },
            ["reviewed"] = true,
            ["sourceRefs"] = {
                "MASSIVE",
                "SGD",
            },
        },
        ["priority"] = 165,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "question",
        ["emit"] = {
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "WELLBEING",
        },
        ["id"] = "pnc.dataset.question.wellbeing.are_you_holding_up_okay",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "are",
            },
            {
                ["kind"] = "literal",
                ["value"] = "you",
            },
            {
                ["kind"] = "literal",
                ["value"] = "holding",
            },
            {
                ["kind"] = "literal",
                ["value"] = "up",
            },
            {
                ["kind"] = "literal",
                ["value"] = "okay",
            },
        },
        ["priority"] = 120,
    },
    {
        ["confidence"] = 0.98,
        ["domain"] = "question",
        ["emit"] = {
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "WELLBEING",
        },
        ["id"] = "pnc.dataset.question.wellbeing.how_are_things_going",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "how",
            },
            {
                ["kind"] = "literal",
                ["value"] = "are",
            },
            {
                ["kind"] = "literal",
                ["value"] = "things",
            },
            {
                ["kind"] = "literal",
                ["value"] = "going",
            },
        },
        ["priority"] = 120,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "question",
        ["emit"] = {
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "WELLBEING",
        },
        ["id"] = "pnc.dataset.question.wellbeing.how_are_you_doing",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "how",
            },
            {
                ["kind"] = "literal",
                ["value"] = "are",
            },
            {
                ["kind"] = "literal",
                ["value"] = "you",
            },
            {
                ["kind"] = "literal",
                ["value"] = "doing",
            },
        },
        ["priority"] = 120,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "question",
        ["emit"] = {
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "WELLBEING",
        },
        ["id"] = "pnc.dataset.question.wellbeing.how_are_you_holding_up",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "how",
            },
            {
                ["kind"] = "literal",
                ["value"] = "are",
            },
            {
                ["kind"] = "literal",
                ["value"] = "you",
            },
            {
                ["kind"] = "literal",
                ["value"] = "holding",
            },
            {
                ["kind"] = "literal",
                ["value"] = "up",
            },
        },
        ["priority"] = 120,
    },
    {
        ["confidence"] = 0.97,
        ["domain"] = "question",
        ["emit"] = {
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "WELLBEING",
        },
        ["id"] = "pnc.dataset.question.wellbeing.how_are_you_managing",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "how",
            },
            {
                ["kind"] = "literal",
                ["value"] = "are",
            },
            {
                ["kind"] = "literal",
                ["value"] = "you",
            },
            {
                ["kind"] = "literal",
                ["value"] = "managing",
            },
        },
        ["priority"] = 120,
    },
    {
        ["confidence"] = 0.97,
        ["domain"] = "question",
        ["emit"] = {
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "WELLBEING",
        },
        ["id"] = "pnc.dataset.question.wellbeing.how_has_your_day_been",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "how",
            },
            {
                ["kind"] = "literal",
                ["value"] = "has",
            },
            {
                ["kind"] = "literal",
                ["value"] = "your",
            },
            {
                ["kind"] = "literal",
                ["value"] = "day",
            },
            {
                ["kind"] = "literal",
                ["value"] = "been",
            },
        },
        ["priority"] = 120,
    },
    {
        ["confidence"] = 0.98,
        ["domain"] = "question",
        ["emit"] = {
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "WELLBEING",
        },
        ["id"] = "pnc.dataset.question.wellbeing.how_is_everything_going",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "how",
            },
            {
                ["kind"] = "literal",
                ["value"] = "is",
            },
            {
                ["kind"] = "literal",
                ["value"] = "everything",
            },
            {
                ["kind"] = "literal",
                ["value"] = "going",
            },
        },
        ["priority"] = 120,
    },
    {
        ["confidence"] = 0.98,
        ["domain"] = "question",
        ["emit"] = {
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "WELLBEING",
        },
        ["id"] = "pnc.dataset.question.wellbeing.hows_everything_going",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "how's",
            },
            {
                ["kind"] = "literal",
                ["value"] = "everything",
            },
            {
                ["kind"] = "literal",
                ["value"] = "going",
            },
        },
        ["priority"] = 120,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "question",
        ["emit"] = {
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "WELLBEING",
        },
        ["id"] = "pnc.dataset.question.wellbeing.what_is_going_on_with_you",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "what",
            },
            {
                ["kind"] = "literal",
                ["value"] = "is",
            },
            {
                ["kind"] = "literal",
                ["value"] = "going",
            },
            {
                ["kind"] = "literal",
                ["value"] = "on",
            },
            {
                ["kind"] = "literal",
                ["value"] = "with",
            },
            {
                ["kind"] = "literal",
                ["value"] = "you",
            },
        },
        ["metadata"] = {
            ["mapping"] = {
                ["canonicalConcept"] = "WELLBEING",
                ["dialogueState"] = "WELLBEING_FOLLOW_UP",
                ["sourceRefs"] = {
                    "MASSIVE",
                    "SGD",
                },
            },
            ["reviewed"] = true,
            ["sourceRefs"] = {
                "MASSIVE",
                "SGD",
            },
        },
        ["priority"] = 164,
    },
    {
        ["confidence"] = 0.97,
        ["domain"] = "question",
        ["emit"] = {
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "WELLBEING",
        },
        ["id"] = "pnc.dataset.question.wellbeing.you_doing_all_right",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "you",
            },
            {
                ["kind"] = "literal",
                ["value"] = "doing",
            },
            {
                ["kind"] = "literal",
                ["value"] = "all",
            },
            {
                ["kind"] = "literal",
                ["value"] = "right",
            },
        },
        ["priority"] = 120,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "question",
        ["emit"] = {
            ["extensions"] = {
                ["hubID"] = "whats_up",
                ["route"] = "semantic_hub",
                ["topic"] = "whats_up",
            },
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "CONVERSATION_TOPIC",
        },
        ["id"] = "pnc.dataset.question.whats_up.anything_going_on",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "anything",
            },
            {
                ["kind"] = "literal",
                ["value"] = "going",
            },
            {
                ["kind"] = "literal",
                ["value"] = "on",
            },
        },
        ["metadata"] = {
            ["mapping"] = {
                ["canonicalConcept"] = "WHATS_UP",
                ["dialogueState"] = "WHATS_UP_HUB",
                ["sourceRefs"] = {
                    "DailyDialog",
                    "EmpatheticDialogues",
                },
            },
            ["reviewed"] = true,
            ["sourceRefs"] = {
                "DailyDialog",
                "EmpatheticDialogues",
            },
        },
        ["priority"] = 155,
    },
}
