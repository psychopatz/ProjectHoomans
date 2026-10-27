-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "semantic",
        ["id"] = "pnc.dialogue.follow.flow",
        ["initial"] = "accepted",
        ["nodes"] = {
            ["accepted"] = {
                ["accepts"] = {
                },
                ["id"] = "accepted",
                ["responsePool"] = "semantic.authored.follow",
                ["terminal"] = true,
            },
        },
        ["owner"] = "ProjectHoomans",
        ["triggers"] = {
            {
                ["action"] = "FOLLOW",
                ["intent"] = "REQUEST",
                ["pattern"] = "pnc.dialogue.follow.keep_close_behind_me",
                ["speechAct"] = "REQUEST",
            },
            {
                ["action"] = "FOLLOW",
                ["intent"] = "REQUEST",
                ["pattern"] = "pnc.dialogue.follow.please_keep_close_behind_me",
                ["speechAct"] = "REQUEST",
            },
        },
        ["version"] = 1,
    },
    {
        ["domain"] = "semantic",
        ["id"] = "pnc.lab.stay_with_you.flow",
        ["initial"] = "accepted",
        ["nodes"] = {
            ["accepted"] = {
                ["accepts"] = {
                },
                ["id"] = "accepted",
                ["responsePool"] = "semantic.lab.stay.with.you",
                ["terminal"] = true,
            },
        },
        ["owner"] = "SemanticLab",
        ["triggers"] = {
            {
                ["action"] = "STAY",
                ["intent"] = "REQUEST",
                ["pattern"] = "pnc.lab.stay_with_you.stay_with_you",
                ["speechAct"] = "REQUEST",
            },
        },
        ["version"] = 1,
    },
}
