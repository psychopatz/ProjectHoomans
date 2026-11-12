-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.dispute_trusted.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.dispute_trusted.neutral",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[17]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_dispute_trusted_neutral",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.social.dispute_trusted",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/disputes.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I trust your judgment usually, but not on this.",
                            },
                            ["TL"] = {
                                "Kadalasan may tiwala ako sa desisyon mo, pero hindi ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "We've earned the right to speak plainly: I disagree.",
                            },
                            ["TL"] = {
                                "Karapatan nating maging tapat: hindi ako sang-ayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Because I trust you, I'm telling you this is a mistake.",
                            },
                            ["TL"] = {
                                "Dahil may tiwala ako sa 'yo, sasabihin kong pagkakamali ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I value our track record, but I have to push back here.",
                            },
                            ["TL"] = {
                                "Mahalaga ang pinagsamahan natin, pero kailangan kong tumutol.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "You're one of the best survivors I know, but I disagree.",
                            },
                            ["TL"] = {
                                "Isa ka sa pinakamagaling na nakilala ko, pero di ako sang-ayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Let's examine the facts together. Something doesn't add up.",
                            },
                            ["TL"] = {
                                "Suriin nating mabuti ang katotohanan. May hindi tama.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I respect you too much to nod along when you're wrong.",
                            },
                            ["TL"] = {
                                "Masyado kitang iginagalang para tumango kapag mali ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "We see this from two different angles.",
                            },
                            ["TL"] = {
                                "Nakikita natin ito mula sa dalawang magkaibang anggulo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Hear me out before you lock in your stance.",
                            },
                            ["TL"] = {
                                "Pakinggan mo muna ako bago mo isara ang isip mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "We have solid trust, so let's weigh the risks properly.",
                            },
                            ["TL"] = {
                                "Matibay ang tiwala natin, kaya timbangin natin ang panganib.",
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
        ["sourceShard"] = "psdl/dialogue/social_reactions_ack_dispute.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
