-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "event_reactions_combat",
        ["id"] = "semantic.combat.reaction.retreat",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.reaction.retreat",
            ["sourcePath"] = "psdl/dialogue/event_reactions_combat.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_reaction_retreat",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["metadata"] = {
                ["category"] = "projecthoomans:event_reactions",
                ["contentOwner"] = "projecthoomans.dialogue_content.events",
                ["responseTemplateID"] = "semantic.combat.reaction.retreat",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/reactions/combat.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I need a moment before I can swing again.",
                            },
                            ["TL"] = {
                                "Kailangan ko muna ng saglit bago makahataw ulit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Arms are heavy. Give me a second.",
                            },
                            ["TL"] = {
                                "Mabigat ang mga braso ko. Bigyan mo ako ng saglit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Falling back! Need to recover stamina.",
                            },
                            ["TL"] = {
                                "Aatras muna! Kailangang makabawi ng lakas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Out of breath! Step back a bit.",
                            },
                            ["TL"] = {
                                "Hinihingal ako! Umatras muna nang kaunti.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Can't keep swinging like this. Backing up.",
                            },
                            ["TL"] = {
                                "Hindi ko kayang tuloy-tuloy ang hataw. Aatras muna.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Give me space to breathe and reset.",
                            },
                            ["TL"] = {
                                "Bigyan mo ako ng puwang para makahinga.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Too exhausted to strike. Pulling back.",
                            },
                            ["TL"] = {
                                "Masyado akong pagod para humampas. Umuurong muna.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Need ten seconds to shake out my arms.",
                            },
                            ["TL"] = {
                                "Kailangan ko ng sampung segundo para ipagpag ang braso ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Step back! I'm completely winded.",
                            },
                            ["TL"] = {
                                "Atras! Sagad na ang hingal ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Back up! Let me catch my breath.",
                            },
                            ["TL"] = {
                                "Umatras! Pahingahin mo muna ako.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/event_reactions_combat.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
