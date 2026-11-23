-- Generated; do not edit by hand.
return {
    {
        ["dialogueAct"] = "INFORM",
        ["domain"] = "general",
        ["id"] = "construction.en.combat_injury.dressing",
        ["owner"] = "ProjectHoomans",
        ["strategy"] = "INJURY_DRESSING",
        ["tokens"] = {
            {
                ["kind"] = "literal",
                ["value"] = "my ",
            },
            {
                ["kind"] = "lexeme",
                ["slot"] = "wound_part",
            },
            {
                ["kind"] = "literal",
                ["value"] = " is bandaged",
            },
        },
        ["translationKey"] = "convo.construction.combat_injury.dressing",
        ["type"] = "construction",
    },
    {
        ["dialogueAct"] = "INFORM",
        ["domain"] = "general",
        ["id"] = "construction.en.combat_injury.dressing_dressing_dirty",
        ["owner"] = "ProjectHoomans",
        ["strategy"] = "INJURY_DRESSING_DRESSING_DIRTY",
        ["tokens"] = {
            {
                ["kind"] = "literal",
                ["value"] = "the bandage on my ",
            },
            {
                ["kind"] = "lexeme",
                ["slot"] = "wound_part",
            },
            {
                ["kind"] = "literal",
                ["value"] = " is dirty",
            },
        },
        ["translationKey"] = "convo.construction.combat_injury.dressing_dressing_dirty",
        ["type"] = "construction",
    },
    {
        ["dialogueAct"] = "INFORM",
        ["domain"] = "general",
        ["id"] = "construction.en.combat_injury.mobility_explicit",
        ["owner"] = "ProjectHoomans",
        ["strategy"] = "INJURY_MOBILITY_EXPLICIT",
        ["tokens"] = {
            {
                ["kind"] = "literal",
                ["value"] = "the injury on my ",
            },
            {
                ["kind"] = "lexeme",
                ["slot"] = "wound_part",
            },
            {
                ["kind"] = "literal",
                ["value"] = " is slowing me down",
            },
        },
        ["translationKey"] = "convo.construction.combat_injury.mobility_explicit",
        ["type"] = "construction",
    },
    {
        ["dialogueAct"] = "INFORM",
        ["domain"] = "general",
        ["id"] = "construction.en.combat_injury.mobility_reference",
        ["owner"] = "ProjectHoomans",
        ["strategy"] = "INJURY_MOBILITY_REFERENCE",
        ["tokens"] = {
            {
                ["kind"] = "literal",
                ["value"] = "it's slowing me down",
            },
        },
        ["translationKey"] = "convo.construction.combat_injury.mobility_reference",
        ["type"] = "construction",
    },
    {
        ["concept"] = "COMBAT_INJURY_FOOT",
        ["domain"] = "general",
        ["fallback"] = "foot",
        ["id"] = "lexeme.combat_injury.foot",
        ["owner"] = "ProjectHoomans",
        ["translationKey"] = "convo.lexeme.combat_injury.foot",
        ["type"] = "lexeme",
    },
    {
        ["concept"] = "COMBAT_INJURY_GROIN",
        ["domain"] = "general",
        ["fallback"] = "groin",
        ["id"] = "lexeme.combat_injury.groin",
        ["owner"] = "ProjectHoomans",
        ["translationKey"] = "convo.lexeme.combat_injury.groin",
        ["type"] = "lexeme",
    },
    {
        ["concept"] = "COMBAT_INJURY_SHIN",
        ["domain"] = "general",
        ["fallback"] = "shin",
        ["id"] = "lexeme.combat_injury.shin",
        ["owner"] = "ProjectHoomans",
        ["translationKey"] = "convo.lexeme.combat_injury.shin",
        ["type"] = "lexeme",
    },
    {
        ["concept"] = "COMBAT_INJURY_THIGH",
        ["domain"] = "general",
        ["fallback"] = "thigh",
        ["id"] = "lexeme.combat_injury.thigh",
        ["owner"] = "ProjectHoomans",
        ["translationKey"] = "convo.lexeme.combat_injury.thigh",
        ["type"] = "lexeme",
    },
}
