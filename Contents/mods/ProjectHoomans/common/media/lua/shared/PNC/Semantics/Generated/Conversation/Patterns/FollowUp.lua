-- Generated; do not edit by hand.
return {
    {
        ["confidence"] = 0.99,
        ["domain"] = "follow_up",
        ["emit"] = {
            ["extensions"] = {
                ["contextQuestion"] = "BACKSTORY_MISS",
                ["dialogueFollowUp"] = "CONTEXT_REFERENCE",
                ["topic"] = "conversation",
            },
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "CONTEXT_REFERENCE",
            ["target"] = "$capture.reference",
        },
        ["id"] = "pnc.backstory.follow_up.do_you_miss_it",
        ["match"] = {
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
                ["value"] = "miss",
            },
            {
                ["capture"] = "reference",
                ["kind"] = "literal",
                ["value"] = "it",
            },
        },
        ["metadata"] = {
            ["mapping"] = {
                ["canonicalConcept"] = "CONTEXT_REFERENCE",
                ["dialogueState"] = "BACKSTORY_FOLLOW_UP",
                ["sourceRefs"] = {
                    "Project Hoomans Authoring Review",
                },
            },
            ["reviewed"] = true,
            ["sourceRefs"] = {
                "Project Hoomans Authoring Review",
            },
        },
        ["priority"] = 129,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "follow_up",
        ["emit"] = {
            ["extensions"] = {
                ["contextQuestion"] = "BACKSTORY_LOCATION",
                ["dialogueFollowUp"] = "CONTEXT_REFERENCE",
                ["topic"] = "conversation",
            },
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "CONTEXT_REFERENCE",
            ["target"] = "$capture.reference",
        },
        ["id"] = "pnc.backstory.follow_up.where",
        ["match"] = {
            {
                ["capture"] = "reference",
                ["kind"] = "literal",
                ["value"] = "where",
            },
        },
        ["metadata"] = {
            ["mapping"] = {
                ["canonicalConcept"] = "CONTEXT_REFERENCE",
                ["dialogueState"] = "BACKSTORY_FOLLOW_UP",
                ["sourceRefs"] = {
                    "Project Hoomans Authoring Review",
                },
            },
            ["reviewed"] = true,
            ["sourceRefs"] = {
                "Project Hoomans Authoring Review",
            },
        },
        ["priority"] = 129,
    },
}
