-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.stop_following.queued.repeated",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "repeated",
            ["sourceId"] = "semantic.command.stop_following.queued.repeated",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_lifecycle/command_stop_following_queued_repeated.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsLifecycle__1516cee7",
        ["namespace"] = "semantic.command.stop_following.queued",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.stop_following.queued.repeated",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/stop_following.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I've already stopped following.",
                            },
                            ["TL"] = {
                                "Tumigil na ako sa pagsunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I'm already standing still. Not following you.",
                            },
                            ["TL"] = {
                                "Nakatayo na nga ako. Di na kita sinusundan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Already halted. Look, I'm not moving.",
                            },
                            ["TL"] = {
                                "Huminto na. Tingnan mo, di ako gumagalaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I stopped following after the first command.",
                            },
                            ["TL"] = {
                                "Huminto na ako sa pagsunod pagkatapos ng unang utos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Still not following you. I'm right here.",
                            },
                            ["TL"] = {
                                "Di pa rin kita sinusundan. Narito lang ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Already stopped. Go ahead without me.",
                            },
                            ["TL"] = {
                                "Huminto na. Sige na, mauna ka nang wala ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I'm not following anymore, I promise.",
                            },
                            ["TL"] = {
                                "Di na kita sinusundan, pangako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Already stationary. No need to tell me again.",
                            },
                            ["TL"] = {
                                "Nakatigil na ako. Di na kailangang sabihin ulit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I've been stopped for a while now.",
                            },
                            ["TL"] = {
                                "Kanina pa ako huminto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Still halted. Move along freely.",
                            },
                            ["TL"] = {
                                "Nakatigil pa rin. Lumakad ka na nang malaya.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_lifecycle/command_stop_following_queued_repeated.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.stop_following.queued.trusted",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "trusted",
            ["sourceId"] = "semantic.command.stop_following.queued.trusted",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_lifecycle/command_stop_following_queued_trusted.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsLifecycle__1516cee7",
        ["namespace"] = "semantic.command.stop_following.queued",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.stop_following.queued.trusted",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/stop_following.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Understood, I'll stop. I trust your solo judgment.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko, titigil ako. Tiwala ako sa sarili mong desisyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I'll hold here, partner. Come back safe.",
                            },
                            ["TL"] = {
                                "Dito muna ako, kasama. Bumalik kang ligtas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Stopping follow. I know you can handle what's ahead.",
                            },
                            ["TL"] = {
                                "Hihinto sa pagsunod. Alam kong kaya mo ang nasa unahan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. I'll secure this spot while you work.",
                            },
                            ["TL"] = {
                                "Naintindihan. Seselyuhan ko ang pwestong ito habang nagtatrabaho ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I'll let you move alone, friend. Shout if you need backup.",
                            },
                            ["TL"] = {
                                "Hahayaan kitang mag-isang lumakad, kaibigan. Sumigaw kapag kailangan mo ng saklolo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Stopping here. You've earned my complete trust.",
                            },
                            ["TL"] = {
                                "Hihinto rito. Nakuha mo na ang buo kong tiwala.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Halting follow. Watch your corners out there.",
                            },
                            ["TL"] = {
                                "Hihinto sa pagsunod. Bantayan ang mga kanto sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'll hold this ground for you until you return, partner.",
                            },
                            ["TL"] = {
                                "Hahawakan ko ang pwestong ito para sa 'yo hanggang sa bumalik ka, kasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Stopping here and maintaining watch.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Hihinto rito at magbabantay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I trust you know what you're doing. Standing down.",
                            },
                            ["TL"] = {
                                "Tiwala akong alam mo ang ginagawa mo. Uurong sa pwesto.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_lifecycle/command_stop_following_queued_trusted.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.stop_following.queued.withdrawn",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "withdrawn",
            ["sourceId"] = "semantic.command.stop_following.queued.withdrawn",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_lifecycle/command_stop_following_queued_withdrawn.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsLifecycle__1516cee7",
        ["namespace"] = "semantic.command.stop_following.queued",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.stop_following.queued.withdrawn",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/stop_following.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Okay, I'll stop.",
                            },
                            ["TL"] = {
                                "Sige, titigil ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Fine. Not following.",
                            },
                            ["TL"] = {
                                "Sige. Di susunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Stopping here.",
                            },
                            ["TL"] = {
                                "Hihinto rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Halting.",
                            },
                            ["TL"] = {
                                "Naintindihan. Hihinto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I'll stay behind.",
                            },
                            ["TL"] = {
                                "Maiiwan ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Ceasing follow.",
                            },
                            ["TL"] = {
                                "Ititigil ang pagsunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Fine. Go on.",
                            },
                            ["TL"] = {
                                "Sige. Mauna ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Stopped.",
                            },
                            ["TL"] = {
                                "Huminto na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "All right. Done following.",
                            },
                            ["TL"] = {
                                "Sige. Tapos na ang pagsunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Halting.",
                            },
                            ["TL"] = {
                                "Humihinto.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_lifecycle/command_stop_following_queued_withdrawn.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.stop_following.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "rejected",
            ["sourceId"] = "semantic.command.stop_following.rejected",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_lifecycle/command_stop_following_rejected.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsLifecycle__1516cee7",
        ["namespace"] = "semantic.command.stop_following",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.stop_following.rejected",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/stop_following.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I can't stop following right now.",
                            },
                            ["TL"] = {
                                "Hindi ako makapaghinto sa pagsunod ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "It's too dangerous to split up. I'm staying with you.",
                            },
                            ["TL"] = {
                                "Masyadong mapanganib maghiwalay. Sasama ako sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I won't leave you alone against that swarm.",
                            },
                            ["TL"] = {
                                "Di kita iiwan mag-isa laban sa kawang 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "We need to stay together to survive this. Refusing to halt.",
                            },
                            ["TL"] = {
                                "Kailangan nating magsama para mabuhay. Tumatangging huminto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "If I stop following here, I'll be completely cut off.",
                            },
                            ["TL"] = {
                                "Kapag huminto ako rito, ganap akong mahihiwalay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Cannot halt here. Too many dead around us.",
                            },
                            ["TL"] = {
                                "Di makahinto rito. Napakaraming patay sa paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I'm sticking with you until we reach actual cover.",
                            },
                            ["TL"] = {
                                "Didikit ako sa 'yo hanggang makarating sa tunay na silong.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Splitting up now will get us killed. I'm following.",
                            },
                            ["TL"] = {
                                "Ikinamamatay ang paghihiwalay ngayon. Susunod ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to break follow in active combat.",
                            },
                            ["TL"] = {
                                "Di makatigil sa pagsunod habang may bakbakan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Order rejected. We survive together or not at all.",
                            },
                            ["TL"] = {
                                "Tinatanggihan ang utos. Sabay tayong mabubuhay o mamamatay.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_lifecycle/command_stop_following_rejected.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
