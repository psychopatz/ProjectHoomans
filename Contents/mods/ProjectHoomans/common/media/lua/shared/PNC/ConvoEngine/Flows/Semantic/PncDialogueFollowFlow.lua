-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "semantic",
        ["id"] = "pnc.dialogue.follow.flow",
        ["initial"] = "accepted",
        ["nodes"] = {
            ["accepted"] = {
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
}
