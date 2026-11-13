-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "semantic",
        ["id"] = "pnc.lab.stay_with_you.flow",
        ["initial"] = "accepted",
        ["nodes"] = {
            ["accepted"] = {
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
