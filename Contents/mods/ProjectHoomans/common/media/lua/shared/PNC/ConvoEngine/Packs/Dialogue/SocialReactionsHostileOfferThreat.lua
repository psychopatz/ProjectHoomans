-- Generated; do not edit by hand.
return {
    {
        ["concepts"] = {
            {
                ["aliases"] = {
                    "fuck",
                    "f*ck",
                    "f**k",
                    "f***",
                    "f***k",
                    "f*****",
                    "fuckin",
                    "fucking",
                    "fucked",
                    "shit",
                    "sh*t",
                    "s**t",
                    "shitty",
                    "bullshit",
                    "bullsh*t",
                    "horseshit",
                    "damn",
                    "dammit",
                    "goddamn",
                    "hell",
                    "crap",
                    "ass",
                    "arse",
                    "piss",
                    "pissed",
                    "pissing",
                    "cock",
                },
                ["id"] = "profanity",
            },
        },
        ["id"] = "pack.projecthoomans.social_profanity",
        ["ownerModID"] = "ProjectHoomans",
        ["patterns"] = {
            {
                ["confidence"] = 0.92,
                ["emit"] = {
                    ["severity"] = "moderate",
                    ["speechAct"] = "HOSTILE_REMARK",
                },
                ["id"] = "pnc.social.profanity",
                ["match"] = {
                    "@PROFANITY",
                },
                ["priority"] = 80,
            },
            {
                ["confidence"] = 0.94,
                ["emit"] = {
                    ["severity"] = "moderate",
                    ["speechAct"] = "HOSTILE_REMARK",
                },
                ["id"] = "pnc.social.profanity_prefixed",
                ["match"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "hey",
                    },
                    {
                        ["id"] = "PROFANITY",
                        ["kind"] = "concept",
                    },
                },
                ["priority"] = 70,
            },
            {
                ["confidence"] = 0.94,
                ["emit"] = {
                    ["severity"] = "moderate",
                    ["speechAct"] = "HOSTILE_REMARK",
                },
                ["id"] = "pnc.social.profanity_you",
                ["match"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "you",
                    },
                    {
                        ["kind"] = "literal",
                        ["optional"] = true,
                        ["value"] = "are",
                    },
                    {
                        ["kind"] = "literal",
                        ["optional"] = true,
                        ["value"] = "a",
                    },
                    {
                        ["kind"] = "literal",
                        ["optional"] = true,
                        ["value"] = "an",
                    },
                    {
                        ["id"] = "PROFANITY",
                        ["kind"] = "concept",
                    },
                },
                ["priority"] = 85,
            },
        },
        ["speechActs"] = {
            {
                ["id"] = "hostile_remark",
                ["intent"] = "HOSTILE_REMARK",
                ["polarity"] = "negative",
                ["tone"] = "hostile",
            },
        },
        ["version"] = 1,
    },
}
