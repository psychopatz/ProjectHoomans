-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.acknowledged.bond_guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.acknowledged.bond_guarded",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialReactionsAckDispute/Catalog",
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
                ["responseTemplateID"] = "semantic.social.acknowledged",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/acknowledgement.json",
                ["style"] = "bond_guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "bond_guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "%s, understood. We'll leave it there.",
                            },
                            ["TL"] = {
                                "%s, naiintindihan ko. Tama na iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "%s, I hear you. Let's keep our heads on.",
                            },
                            ["TL"] = {
                                "%s, narinig kita. Mag-ingat na lang tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "%s, message received. Eyes open.",
                            },
                            ["TL"] = {
                                "%s, nakuha ko ang mensahe. Buksan ang mga mata.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "%s, got it. No need to push further.",
                            },
                            ["TL"] = {
                                "%s, nakuha ko. Hindi na kailangang magpumilit.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "%s, all right. Let's watch the perimeter.",
                            },
                            ["TL"] = {
                                "%s, sige. Bantayan natin ang paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "%s, acknowledged. We keep our guard up.",
                            },
                            ["TL"] = {
                                "%s, naintindihan. Huwag nating ibaba ang bantay.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "%s, I take your point. Let's be smart about this.",
                            },
                            ["TL"] = {
                                "%s, nakuha ko ang punto mo. Maging maingat tayo rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "%s, clear enough. Leaving it at that.",
                            },
                            ["TL"] = {
                                "%s, sapat ang linaw. Iwan na natin doon.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "%s, noted. We stay sharp.",
                            },
                            ["TL"] = {
                                "%s, tala ko na. Manatili tayong alerto.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "%s, fair enough. Let's move carefully.",
                            },
                            ["TL"] = {
                                "%s, makatwiran. Kumilos tayo nang maingat.",
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
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.acknowledged.bond_neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.acknowledged.bond_neutral",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialReactionsAckDispute/Catalog",
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
                ["responseTemplateID"] = "semantic.social.acknowledged",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/acknowledgement.json",
                ["style"] = "bond_neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "bond_neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "%s, all right.",
                            },
                            ["TL"] = {
                                "%s, sige.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "%s, understood.",
                            },
                            ["TL"] = {
                                "%s, naiintindihan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "%s, I hear what you're saying.",
                            },
                            ["TL"] = {
                                "%s, naririnig ko ang sinasabi mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "%s, got it. Makes sense.",
                            },
                            ["TL"] = {
                                "%s, nakuha ko. May katuturan.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "%s, sounds reasonable.",
                            },
                            ["TL"] = {
                                "%s, mukhang makatwiran.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "%s, message received.",
                            },
                            ["TL"] = {
                                "%s, natanggap ang mensahe.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "%s, fair enough. We'll roll with that.",
                            },
                            ["TL"] = {
                                "%s, may punto ka. Susundin natin 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "%s, acknowledged. Let's get to work.",
                            },
                            ["TL"] = {
                                "%s, naintindihan. Simulan na natin ang trabaho.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "%s, point taken.",
                            },
                            ["TL"] = {
                                "%s, nakuha ko ang punto mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "%s, right with you on that.",
                            },
                            ["TL"] = {
                                "%s, sang-ayon ako sa 'yo riyan.",
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
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.acknowledged.bond_terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.acknowledged.bond_terse",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialReactionsAckDispute/Catalog",
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
                ["responseTemplateID"] = "semantic.social.acknowledged",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/acknowledgement.json",
                ["style"] = "bond_terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "bond_terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "%s, all right.",
                            },
                            ["TL"] = {
                                "%s, sige.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "%s, understood.",
                            },
                            ["TL"] = {
                                "%s, naintindihan.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "%s, got it.",
                            },
                            ["TL"] = {
                                "%s, nakuha ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "%s, heard.",
                            },
                            ["TL"] = {
                                "%s, narinig ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "%s, clear.",
                            },
                            ["TL"] = {
                                "%s, malinaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "%s, right.",
                            },
                            ["TL"] = {
                                "%s, tama.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "%s, noted.",
                            },
                            ["TL"] = {
                                "%s, tala ko na.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "%s, good.",
                            },
                            ["TL"] = {
                                "%s, mabuti.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "%s, agreed.",
                            },
                            ["TL"] = {
                                "%s, sang-ayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "%s, done.",
                            },
                            ["TL"] = {
                                "%s, tapos.",
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
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.acknowledged.bond_warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.acknowledged.bond_warm",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialReactionsAckDispute/Catalog",
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
                ["responseTemplateID"] = "semantic.social.acknowledged",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/acknowledgement.json",
                ["style"] = "bond_warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "bond_warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "%s, all right. I hear you.",
                            },
                            ["TL"] = {
                                "%s, sige. Narinig kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "%s, got it. Always good to talk with you.",
                            },
                            ["TL"] = {
                                "%s, nakuha ko. Laging magandang makausap ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "%s, understood completely. I'm with you on this.",
                            },
                            ["TL"] = {
                                "%s, lubos kong naiintindihan. Kasama mo ako rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "%s, sounds like a solid plan, partner.",
                            },
                            ["TL"] = {
                                "%s, magandang plano 'yan, kasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "%s, I hear you loud and clear. Take care.",
                            },
                            ["TL"] = {
                                "%s, narinig kita nang malakas at malinaw. Mag-ingat ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "%s, you've got my support. Let's do it.",
                            },
                            ["TL"] = {
                                "%s, nasa sa 'yo ang suporta ko. Gawin natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "%s, glad we're in agreement. Stay safe.",
                            },
                            ["TL"] = {
                                "%s, mabuti at nagkasundo tayo. Manatiling ligtas.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "%s, noted with thanks. Good thinking.",
                            },
                            ["TL"] = {
                                "%s, salamat sa pagbabahagi. Magandang kaisipan.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "%s, clear as day. Glad you're on my side.",
                            },
                            ["TL"] = {
                                "%s, kasing-linaw ng araw. Mabuti at kakampi kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "%s, got your back. Let's make it count.",
                            },
                            ["TL"] = {
                                "%s, hawak ko ang likod mo. Sulitin natin ito.",
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
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.acknowledged.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.acknowledged.guarded",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialReactionsAckDispute/Catalog",
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
                ["responseTemplateID"] = "semantic.social.acknowledged",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/acknowledgement.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. We'll leave it there.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Tama na iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "I hear you. Don't press it any further.",
                            },
                            ["TL"] = {
                                "Narinig kita. Huwag mo nang ipagpilitan pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Message received. Keep your distance.",
                            },
                            ["TL"] = {
                                "Nakuha ko. Manatili ka sa puwesto mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Got it. Let's stay alert.",
                            },
                            ["TL"] = {
                                "Naintindihan. Maging alerto tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. No need for more words.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Hindi na kailangan ng salita.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "All right. Watching my back, you watch yours.",
                            },
                            ["TL"] = {
                                "Sige. Babantayan ko ang likod ko, bantayan mo ang sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Noted. Keep your eyes on the road.",
                            },
                            ["TL"] = {
                                "Tala ko na. Iwan mo ang paningin mo sa daan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Heard. Leaving it at that.",
                            },
                            ["TL"] = {
                                "Narinig ko. Iiwan ko na roon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Clear enough. Let's focus on surviving.",
                            },
                            ["TL"] = {
                                "Malinaw na. Magpokus na lang tayo sa pananatiling buhay.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Fair enough. Step back a bit.",
                            },
                            ["TL"] = {
                                "Makatwiran. Umatras ka nang kaunti.",
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
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.acknowledged.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.acknowledged.neutral",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[5]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialReactionsAckDispute/Catalog",
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
                ["responseTemplateID"] = "semantic.social.acknowledged",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/acknowledgement.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "All right. Understood.",
                            },
                            ["TL"] = {
                                "Sige. Naiintindihan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I hear you. Makes sense.",
                            },
                            ["TL"] = {
                                "Narinig kita. May katuturan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Got it. We can work with that.",
                            },
                            ["TL"] = {
                                "Nakuha ko. Pwede nating gamitin 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Message received. Moving forward.",
                            },
                            ["TL"] = {
                                "Natanggap ang mensahe. Magpapatuloy na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Sounds fair to me.",
                            },
                            ["TL"] = {
                                "Mukhang makatwiran para sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Point taken.",
                            },
                            ["TL"] = {
                                "Nakuha ko ang punto mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Let's proceed.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Magpatuloy na tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "All right. We're on the same page.",
                            },
                            ["TL"] = {
                                "Sige. Pareho tayo ng takbo ng isip.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Fair enough. Good to know.",
                            },
                            ["TL"] = {
                                "Makatwiran. Mabuting malaman.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Acknowledged. Let's get it done.",
                            },
                            ["TL"] = {
                                "Kinikilala ko. Tapusin na natin.",
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
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.acknowledged.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.acknowledged.terse",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[6]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialReactionsAckDispute/Catalog",
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
                ["responseTemplateID"] = "semantic.social.acknowledged",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/acknowledgement.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "All right.",
                            },
                            ["TL"] = {
                                "Sige.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Understood.",
                            },
                            ["TL"] = {
                                "Naintindihan.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Heard.",
                            },
                            ["TL"] = {
                                "Narinig ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Got it.",
                            },
                            ["TL"] = {
                                "Nakuha ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Clear.",
                            },
                            ["TL"] = {
                                "Malinaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Right.",
                            },
                            ["TL"] = {
                                "Tama.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Noted.",
                            },
                            ["TL"] = {
                                "Tala ko na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Good.",
                            },
                            ["TL"] = {
                                "Mabuti.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Done.",
                            },
                            ["TL"] = {
                                "Tapos.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Agreed.",
                            },
                            ["TL"] = {
                                "Sang-ayon.",
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
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.acknowledged.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.acknowledged.warm",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[7]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialReactionsAckDispute/Catalog",
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
                ["responseTemplateID"] = "semantic.social.acknowledged",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/acknowledgement.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "All right. I hear you.",
                            },
                            ["TL"] = {
                                "Sige. Narinig kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Got it, friend. Glad we talked.",
                            },
                            ["TL"] = {
                                "Nakuha ko, kaibigan. Mabuti at nagkausap tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "I completely understand. Thanks for explaining.",
                            },
                            ["TL"] = {
                                "Lubos kong nauunawaan. Salamat sa pagpapaliwanag.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Sounds great. Glad we're in this together.",
                            },
                            ["TL"] = {
                                "Napakaganda. Mabuti at magkasama tayo rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Take care of yourself out there.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Ingatan mo ang sarili mo sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'm with you on that. Good call.",
                            },
                            ["TL"] = {
                                "Kasama mo ako riyan. Magandang desisyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Heard and appreciated. We've got this.",
                            },
                            ["TL"] = {
                                "Narinig at pinahahalagahan. Kayang-kaya natin ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "Clear as crystal. Happy to follow your lead.",
                            },
                            ["TL"] = {
                                "Napakalinaw. Masayang sumunod sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Got it. Always a pleasure working with you.",
                            },
                            ["TL"] = {
                                "Nakuha ko. Laging masarap kang makatrabaho.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "All right. Let's look out for each other.",
                            },
                            ["TL"] = {
                                "Sige. Magtulungan tayo sa isa't isa.",
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
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.dispute_friendly.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.dispute_friendly.guarded",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[8]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialReactionsAckDispute/Catalog",
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
                ["responseTemplateID"] = "semantic.social.dispute_friendly",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/disputes.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "I disagree. Leave it there.",
                            },
                            ["TL"] = {
                                "Hindi ako sang-ayon. Tama na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "I see it differently. Don't push it.",
                            },
                            ["TL"] = {
                                "Iba ang tingin ko. Huwag mo nang ipilit.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "We don't agree on this. Drop it.",
                            },
                            ["TL"] = {
                                "Hindi tayo nagtutugma rito. Iwan mo na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Not buying that. Let's move on.",
                            },
                            ["TL"] = {
                                "Hindi ako kumbinsido. Lumipat na tayo ng usapan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "I'm not on board with that idea.",
                            },
                            ["TL"] = {
                                "Hindi ako sang-ayon sa kaisipang 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "I disagree, and I'm not budging.",
                            },
                            ["TL"] = {
                                "Hindi ako sang-ayon, at hindi ako uusad.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "That won't work for me. End of story.",
                            },
                            ["TL"] = {
                                "Hindi uubra sa akin 'yan. Diyan nagtatapos 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "You have your view, I have mine. Back off.",
                            },
                            ["TL"] = {
                                "May pananaw ka, mayroon din ako. Umatras ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "I dispute that. We leave it alone.",
                            },
                            ["TL"] = {
                                "Pinasisinungalingan ko 'yan. Hayaan na natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "No. I don't see it that way at all.",
                            },
                            ["TL"] = {
                                "Hindi. Hindi ko talaga tinitingnan nang ganyan.",
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
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.dispute_friendly.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.dispute_friendly.neutral",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[9]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialReactionsAckDispute/Catalog",
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
                ["responseTemplateID"] = "semantic.social.dispute_friendly",
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
                                "I disagree, but I hear what you're saying.",
                            },
                            ["TL"] = {
                                "Hindi ako sang-ayon, pero naririnig ko ang punto mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I see things differently on this one.",
                            },
                            ["TL"] = {
                                "Iba ang pananaw ko sa bagay na ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "We'll have to agree to disagree here.",
                            },
                            ["TL"] = {
                                "Kailangan na lang nating tanggaping magkaiba tayo rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I don't think that's the best way forward.",
                            },
                            ["TL"] = {
                                "Sa tingin ko hindi 'yan ang pinakamagandang hakbang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I have reservations about that plan.",
                            },
                            ["TL"] = {
                                "May pag-aalinlangan ako sa planong 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Fair point, but I still see a problem with it.",
                            },
                            ["TL"] = {
                                "May punto ka, pero may nakikita pa rin akong aberya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I respectfully disagree with your take.",
                            },
                            ["TL"] = {
                                "May galang akong hindi sumasang-ayon sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "That's not how I read the situation.",
                            },
                            ["TL"] = {
                                "Hindi ganyan ang pagbasa ko sa sitwasyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I don't see it that way, honestly.",
                            },
                            ["TL"] = {
                                "Sa totoo lang, hindi ganoon ang tingin ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "We have different opinions on this. That's fine.",
                            },
                            ["TL"] = {
                                "Magkaiba tayo ng opinyon dito. Ayos lang 'yon.",
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
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.dispute_friendly.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.dispute_friendly.terse",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[10]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialReactionsAckDispute/Catalog",
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
                ["responseTemplateID"] = "semantic.social.dispute_friendly",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/disputes.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "Disagree.",
                            },
                            ["TL"] = {
                                "Di sang-ayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "No.",
                            },
                            ["TL"] = {
                                "Hindi.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Not how I see it.",
                            },
                            ["TL"] = {
                                "Di ganyan ang tingin ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Don't agree.",
                            },
                            ["TL"] = {
                                "Di ako sang-ayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Doubtful.",
                            },
                            ["TL"] = {
                                "Malamang hindi.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Not buying it.",
                            },
                            ["TL"] = {
                                "Di ako kumbinsido.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Different take.",
                            },
                            ["TL"] = {
                                "Ibang pananaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Negative.",
                            },
                            ["TL"] = {
                                "Hindi pwede.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Pass on that.",
                            },
                            ["TL"] = {
                                "Lalampasan ko 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Nope.",
                            },
                            ["TL"] = {
                                "Hindi.",
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
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.dispute_friendly.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.dispute_friendly.warm",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[11]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialReactionsAckDispute/Catalog",
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
                ["responseTemplateID"] = "semantic.social.dispute_friendly",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/disputes.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "I disagree, friend, but I respect your perspective.",
                            },
                            ["TL"] = {
                                "Hindi ako sang-ayon, kaibigan, pero iginagalang ko ang opinyon mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "We don't see eye to eye on this, but we're still good.",
                            },
                            ["TL"] = {
                                "Hindi tayo pareho ng paningin dito, pero maayos pa rin tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "I see where you're coming from, but I look at it differently.",
                            },
                            ["TL"] = {
                                "Nauunawaan ko ang pinanggagalingan mo, pero iba ang tingin ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "No hard feelings, but I'd handle it another way.",
                            },
                            ["TL"] = {
                                "Walang samaan ng loob, pero iba ang gagawin kong paraan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "I value your thoughts, even when we don't agree.",
                            },
                            ["TL"] = {
                                "Pinahahalagahan ko ang isip mo, kahit di tayo magkasundo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "We're allowed to differ. We still have each other's backs.",
                            },
                            ["TL"] = {
                                "Pwede tayong magkaiba. Hawak pa rin natin ang likod ng bawat isa.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "I don't agree with the plan, but I trust you as a comrade.",
                            },
                            ["TL"] = {
                                "Di ako sang-ayon sa plano, pero may tiwala ako sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "Let's talk through it without getting worked up.",
                            },
                            ["TL"] = {
                                "Pag-usapan natin ito nang hindi nagkakainitan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "I disagree, but I'm glad you felt comfortable saying it.",
                            },
                            ["TL"] = {
                                "Hindi ako sang-ayon, pero mabuti't malaya mong nasabi.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "We can disagree and still keep each other alive.",
                            },
                            ["TL"] = {
                                "Pwede tayong magkaiba at manatili pa ring buhay magkasama.",
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
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.dispute_stressed.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.dispute_stressed.guarded",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[12]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialReactionsAckDispute/Catalog",
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
                ["responseTemplateID"] = "semantic.social.dispute_stressed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/disputes.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "I hear you. Not now.",
                            },
                            ["TL"] = {
                                "Naririnig kita. Hindi ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "We don't have time to fight. Stand down.",
                            },
                            ["TL"] = {
                                "Wala tayong oras para mag-away. Tumigil ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Too much on the line to argue. Shut it down.",
                            },
                            ["TL"] = {
                                "Masyadong malaki ang nakataya para magtalo. Itigil mo na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "I'm stressed, you're stressed. Drop it.",
                            },
                            ["TL"] = {
                                "Pagod ako, pagod ka. Hayaan mo na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Don't push an argument while we're in danger.",
                            },
                            ["TL"] = {
                                "Huwag kang magpumilit makipagtalo habang delikado.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "One more word about this and I walk away.",
                            },
                            ["TL"] = {
                                "Isa pang salita tungkol dito at aalis ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Save the bickering before it gets us killed.",
                            },
                            ["TL"] = {
                                "Itabi ang bangayan bago tayo mapatay nito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Not the time. Eyes forward.",
                            },
                            ["TL"] = {
                                "Hindi ito ang tamang oras. Tumingin sa unahan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'm done debating under pressure.",
                            },
                            ["TL"] = {
                                "Tapos na akong makipagtalo sa gitna ng tensiyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Cut the argument right now.",
                            },
                            ["TL"] = {
                                "Putulin mo ang pagtatalo ngayon din.",
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
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.dispute_stressed.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.dispute_stressed.neutral",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[13]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialReactionsAckDispute/Catalog",
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
                ["responseTemplateID"] = "semantic.social.dispute_stressed",
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
                                "Tensions are high. Let's table this for later.",
                            },
                            ["TL"] = {
                                "Mataas ang tensiyon. Ipagpaliban muna natin mamaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "We're both stressed. Let's not make bad calls right now.",
                            },
                            ["TL"] = {
                                "Pareho tayong pagod. Huwag tayong gumawa ng maling desisyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Now isn't the moment to hash this out.",
                            },
                            ["TL"] = {
                                "Hindi ngayon ang oras para pagtalunan ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Let's catch our breath before we argue further.",
                            },
                            ["TL"] = {
                                "Huminga muna tayo bago magpatuloy sa pagtatalo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "We need clear heads right now, not arguments.",
                            },
                            ["TL"] = {
                                "Kailangan natin ng malinaw na isip, hindi bangayan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I understand you're upset, but we need to survive first.",
                            },
                            ["TL"] = {
                                "Naiintindihan kong galit ka, pero kaligtasan muna.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Let's put a pin in this until we're safe.",
                            },
                            ["TL"] = {
                                "Iwan muna natin ito hanggang sa maging ligtas tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Arguing right now only helps the dead.",
                            },
                            ["TL"] = {
                                "Ang pagtatalo ngayon ay pabor lang sa mga patay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I hear the frustration. Let's focus on the threat.",
                            },
                            ["TL"] = {
                                "Naririnig ko ang inis mo. Magpokus tayo sa banta.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "We can settle this once we're behind walls.",
                            },
                            ["TL"] = {
                                "Maaayos natin ito kapag nasa loob na tayo ng pader.",
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
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.dispute_stressed.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.dispute_stressed.terse",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[14]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialReactionsAckDispute/Catalog",
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
                ["responseTemplateID"] = "semantic.social.dispute_stressed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/disputes.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "Not now.",
                            },
                            ["TL"] = {
                                "Hindi ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Stop.",
                            },
                            ["TL"] = {
                                "Tigil.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Cool it.",
                            },
                            ["TL"] = {
                                "Kumalma ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Later.",
                            },
                            ["TL"] = {
                                "Mamaya na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Drop it.",
                            },
                            ["TL"] = {
                                "Hayaan mo na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Too tense.",
                            },
                            ["TL"] = {
                                "Masyadong delikado.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Hold your tongue.",
                            },
                            ["TL"] = {
                                "Pigilin ang dila.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Focus.",
                            },
                            ["TL"] = {
                                "Magpokus.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Enough.",
                            },
                            ["TL"] = {
                                "Sapat na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Quiet.",
                            },
                            ["TL"] = {
                                "Tahimik.",
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
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.dispute_stressed.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.dispute_stressed.warm",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[15]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialReactionsAckDispute/Catalog",
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
                ["responseTemplateID"] = "semantic.social.dispute_stressed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/disputes.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "Hey, we're both frayed right now. Let's take a breath.",
                            },
                            ["TL"] = {
                                "Huy, pagod tayong pareho ngayon. Huminga muna tayo nang malalim.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "I know you're hurting and tense. I'm right here. Let's pause.",
                            },
                            ["TL"] = {
                                "Alam kong nahihirapan ka at tensiyonado. Narito lang ako. Huminto muna tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Don't let the stress tear us apart. We're partners.",
                            },
                            ["TL"] = {
                                "Huwag nating hayaang paglayuin tayo ng pagod. Magkasama tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "I hear your worry, but let's get somewhere safe first.",
                            },
                            ["TL"] = {
                                "Naririnig ko ang kaba mo, pero lumipat muna tayo sa ligtas.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "I care about what you think, just not while we're in danger.",
                            },
                            ["TL"] = {
                                "Mahalaga sa akin ang opinyon mo, pero huwag habang nasa panganib.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Let's take a second to reset. We're on the same side.",
                            },
                            ["TL"] = {
                                "Maglaan tayo ng sandali para kumalma. Magkakampi tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Breathe with me. We'll work through this disagreement later.",
                            },
                            ["TL"] = {
                                "Sumabay kang huminga sa akin. Aayusin natin ito mamaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'm not fighting you. Let's keep each other alive.",
                            },
                            ["TL"] = {
                                "Hindi kita kalaban. Panatilihin nating buhay ang isa't isa.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Stress is talking right now. Let's be gentle on each other.",
                            },
                            ["TL"] = {
                                "Pagod lang ang nagsasalita ngayon. Maging mahinahon tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "We'll talk this through when the dust settles, I promise.",
                            },
                            ["TL"] = {
                                "Pag-uusapan natin ito kapag humupa na ang gulo, pangako.",
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
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.dispute_trusted.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.dispute_trusted.guarded",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[16]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialReactionsAckDispute/Catalog",
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
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "I still don't agree. Leave it there.",
                            },
                            ["TL"] = {
                                "Hindi pa rin ako sang-ayon. Tama na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Even between us, I draw the line here.",
                            },
                            ["TL"] = {
                                "Kahit sa ating dalawa, may hangganan ako rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "I trust you, but I won't back this decision.",
                            },
                            ["TL"] = {
                                "Tiwala ako sa 'yo, pero di ko susuportahan ang desisyong ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "We've been through a lot, but I disagree on this.",
                            },
                            ["TL"] = {
                                "Marami na tayong pinagdaanan, pero di ako sang-ayon dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Don't lean on our history to push a bad idea.",
                            },
                            ["TL"] = {
                                "Huwag mong gamitin ang samahan natin para ipilit ang maling plano.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "I trust your survival skills, not this specific take.",
                            },
                            ["TL"] = {
                                "Tiwala ako sa galing mo, pero hindi sa opinyong ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Stand down on this. I won't follow blindly.",
                            },
                            ["TL"] = {
                                "Bumitiw ka rito. Hindi ako susunod nang pikit-mata.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Trust goes both ways. Hear my disagreement.",
                            },
                            ["TL"] = {
                                "May dalawang panig ang tiwala. Pakinggan mo ang pagtutol ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "I won't let friendship blind me to a bad risk.",
                            },
                            ["TL"] = {
                                "Hindi ko hahayaang bulagin ng samahan ang maling sugal.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "We're close, but on this, you're dead wrong.",
                            },
                            ["TL"] = {
                                "Malapit tayo, pero rito, maling-mali ka.",
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
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.dispute_trusted.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.dispute_trusted.neutral",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[17]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialReactionsAckDispute/Catalog",
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
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.dispute_trusted.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.dispute_trusted.terse",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[18]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialReactionsAckDispute/Catalog",
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
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "Not this time.",
                            },
                            ["TL"] = {
                                "Hindi sa pagkakataong ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Trust you, but no.",
                            },
                            ["TL"] = {
                                "Tiwala ako sa 'yo, pero hindi.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Bad call.",
                            },
                            ["TL"] = {
                                "Maling pasya.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Disagree, partner.",
                            },
                            ["TL"] = {
                                "Di ako sang-ayon, kasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Can't back it.",
                            },
                            ["TL"] = {
                                "Di ko masusuportahan.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Wrong move.",
                            },
                            ["TL"] = {
                                "Maling galaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Reconsider.",
                            },
                            ["TL"] = {
                                "Pag-isipan mo ulit.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'm out on that.",
                            },
                            ["TL"] = {
                                "Labas ako riyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "No dice.",
                            },
                            ["TL"] = {
                                "Hindi uubra.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Think again.",
                            },
                            ["TL"] = {
                                "Mag-isip ka ulit.",
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
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.dispute_trusted.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.dispute_trusted.warm",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[19]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialReactionsAckDispute/Catalog",
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
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "You know I'd follow you through hell, but not into this.",
                            },
                            ["TL"] = {
                                "Alam mong sasamahan kita kahit saan, pero hindi sa bagay na ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "I love how bold you are, but this risk is too steep.",
                            },
                            ["TL"] = {
                                "Hanga ako sa tapang mo, pero masyadong mataas ang sugal na ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Because I care about you, I have to say no to this.",
                            },
                            ["TL"] = {
                                "Dahil nagmamalasakit ako sa 'yo, kailangan kong tumanggi rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "We've kept each other alive this long. Trust me on this disagreement.",
                            },
                            ["TL"] = {
                                "Matagal na nating binubuhay ang isa't isa. Magtiwala ka sa pagtutol ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "You're my closest ally, so listen to my gut on this one.",
                            },
                            ["TL"] = {
                                "Pinakamalapit kitang kasama, kaya pakinggan mo ang kutob ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'm telling you this because I want us both to live to see tomorrow.",
                            },
                            ["TL"] = {
                                "Sinasabi ko ito dahil gusto kong mabuhay tayong pareho bukas.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "No matter what happens, we're solid. But I disagree here.",
                            },
                            ["TL"] = {
                                "Kahit anong mangyari, matibay tayo. Pero di ako sang-ayon dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "Let's find a compromise that keeps both of us safe.",
                            },
                            ["TL"] = {
                                "Humanap tayo ng paraan na magpapanatiling ligtas sa ating dalawa.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "I value our bond above any single disagreement.",
                            },
                            ["TL"] = {
                                "Mas mahalaga ang samahan natin kaysa sa anumang pagtatalo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "We'll work it out together like we always do.",
                            },
                            ["TL"] = {
                                "Aayusin natin ito nang magkasama gaya ng dati.",
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
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.dispute_withdrawn.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.dispute_withdrawn.guarded",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[20]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialReactionsAckDispute/Catalog",
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
                ["responseTemplateID"] = "semantic.social.dispute_withdrawn",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/disputes.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Let's leave it there.",
                            },
                            ["TL"] = {
                                "Tama na iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "I'm not arguing with you anymore.",
                            },
                            ["TL"] = {
                                "Hindi na ako makikipagtalo sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Done talking about this.",
                            },
                            ["TL"] = {
                                "Tapos na akong pag-usapan ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Subject is closed. Back off.",
                            },
                            ["TL"] = {
                                "Sarado na ang paksa. Umatras ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "I've said my piece. Leave it alone.",
                            },
                            ["TL"] = {
                                "Nasabi ko na ang parte ko. Hayaan mo na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Drop it before I get angry.",
                            },
                            ["TL"] = {
                                "Itigil mo 'yan bago pa ako magalit.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Nothing more to say.",
                            },
                            ["TL"] = {
                                "Wala nang dapat sabihin pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "We're done here.",
                            },
                            ["TL"] = {
                                "Tapos na tayo rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Walk away.",
                            },
                            ["TL"] = {
                                "Umalis ka na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "I'm finished with this conversation.",
                            },
                            ["TL"] = {
                                "Tapos na ako sa usapang ito.",
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
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.dispute_withdrawn.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.dispute_withdrawn.neutral",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[21]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialReactionsAckDispute/Catalog",
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
                ["responseTemplateID"] = "semantic.social.dispute_withdrawn",
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
                                "All right. Let's step back from this.",
                            },
                            ["TL"] = {
                                "Sige. Umatras muna tayo sa usapang ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "We're not getting anywhere. Let's move on.",
                            },
                            ["TL"] = {
                                "Wala tayong mararating. Magpatuloy na tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I think we've said enough on the matter.",
                            },
                            ["TL"] = {
                                "Sa tingin ko sapat na ang nasabi natin sa usapin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Let's take a break from this topic.",
                            },
                            ["TL"] = {
                                "Magpahinga muna tayo sa paksang ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Fair enough. Let's focus on other priorities.",
                            },
                            ["TL"] = {
                                "Makatwiran. Magpokus na lang tayo sa ibang gawain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "No point spinning our wheels. Let's work.",
                            },
                            ["TL"] = {
                                "Walang silbing magpaulit-ulit. Magtrabaho na tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. We'll leave it at that.",
                            },
                            ["TL"] = {
                                "Naintindihan. Diyan na muna natin iiwan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Agreed. Moving past it now.",
                            },
                            ["TL"] = {
                                "Sang-ayon. Lumilipas na tayo roon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "We can revisit this when things settle down.",
                            },
                            ["TL"] = {
                                "Mababalikan natin ito kapag maayos na ang lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "All right. Let's put our energy elsewhere.",
                            },
                            ["TL"] = {
                                "Sige. Dalhin na lang natin ang lakas sa iba.",
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
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.dispute_withdrawn.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.dispute_withdrawn.terse",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[22]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialReactionsAckDispute/Catalog",
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
                ["responseTemplateID"] = "semantic.social.dispute_withdrawn",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/disputes.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "Drop it.",
                            },
                            ["TL"] = {
                                "Hayaan mo na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Done.",
                            },
                            ["TL"] = {
                                "Tapos na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Enough.",
                            },
                            ["TL"] = {
                                "Sapat na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "No more.",
                            },
                            ["TL"] = {
                                "Wala na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Moving on.",
                            },
                            ["TL"] = {
                                "Tuloy na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Leave it.",
                            },
                            ["TL"] = {
                                "Tama na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Finished.",
                            },
                            ["TL"] = {
                                "Tapos.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Closed.",
                            },
                            ["TL"] = {
                                "Sarado.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "End of it.",
                            },
                            ["TL"] = {
                                "Diyan nagtatapos.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Drop the topic.",
                            },
                            ["TL"] = {
                                "Iwan ang paksa.",
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
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.dispute_withdrawn.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.dispute_withdrawn.warm",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[23]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialReactionsAckDispute/Catalog",
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
                ["responseTemplateID"] = "semantic.social.dispute_withdrawn",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/disputes.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "Let's leave it there for now, friend. We're still good.",
                            },
                            ["TL"] = {
                                "Tama na muna iyon, kaibigan. Maayos pa rin tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "I don't want this to come between us. Let's rest on it.",
                            },
                            ["TL"] = {
                                "Ayokong masira tayo dahil dito. Ipahinga na muna natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "We've said what we needed to say. All love here.",
                            },
                            ["TL"] = {
                                "Nasabi na natin ang kailangan. Maayos ang kalooban dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Let's pause this. You're more important to me than this argument.",
                            },
                            ["TL"] = {
                                "Tigil muna. Mas mahalaga ka sa akin kaysa sa pagtatalong ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "All good. Let's go grab a drink and clear our heads.",
                            },
                            ["TL"] = {
                                "Ayos lang. Uminom muna tayo para mahimasmasan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "I hear you, and I respect you. Let's let the dust settle.",
                            },
                            ["TL"] = {
                                "Narinig kita, at iginagalang kita. Hayaang lumipas ang alikabok.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "We don't need to fight. We're on the same team.",
                            },
                            ["TL"] = {
                                "Di natin kailangang mag-away. Nasa iisang koponan tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "It's all right. We can let this one slide.",
                            },
                            ["TL"] = {
                                "Ayos lang. Pwede nating palampasin ang isang 'to.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "I value our partnership too much to push this.",
                            },
                            ["TL"] = {
                                "Masyadong mahalaga ang samahan natin para ipagpilitan ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "We'll be okay. Let's take a breather.",
                            },
                            ["TL"] = {
                                "Magiging maayos tayo. Huminga muna tayo nang malalim.",
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
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.hostile_boundary.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.hostile_boundary.guarded",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[24]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialReactionsAckDispute/Catalog",
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
                ["responseTemplateID"] = "semantic.social.hostile_boundary",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/hostile.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Don't talk to me like that.",
                            },
                            ["TL"] = {
                                "Huwag mo akong kausapin nang ganyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Check yourself before you speak to me again.",
                            },
                            ["TL"] = {
                                "Pagsabihan mo ang sarili mo bago ka makipag-usap sa 'kin ulit.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "You're stepping way out of line.",
                            },
                            ["TL"] = {
                                "Sumusobra ka na sa linya.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Mind your mouth around me.",
                            },
                            ["TL"] = {
                                "Bantayan mo ang bibig mo sa harap ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "I don't take disrespect from anyone.",
                            },
                            ["TL"] = {
                                "Hindi ako pumapayag na bastusin ng kahit sino.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "You cross that boundary again and see what happens.",
                            },
                            ["TL"] = {
                                "Tawirin mo ulit ang hangganang 'yan at tingnan natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Watch how you address me.",
                            },
                            ["TL"] = {
                                "Bantayan mo kung paano mo ako kausapin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Keep your tone in check.",
                            },
                            ["TL"] = {
                                "Ayusin mo ang tono mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "You are playing with a short fuse.",
                            },
                            ["TL"] = {
                                "Naglalaro ka sa maikling mitsa.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Back off that attitude.",
                            },
                            ["TL"] = {
                                "Alisin mo ang ganyang ugali.",
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
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.hostile_boundary.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.hostile_boundary.neutral",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[25]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialReactionsAckDispute/Catalog",
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
                ["responseTemplateID"] = "semantic.social.hostile_boundary",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/hostile.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "That tone isn't acceptable.",
                            },
                            ["TL"] = {
                                "Hindi katanggap-tanggap ang ganyang tono.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Speak to me with respect or don't speak to me at all.",
                            },
                            ["TL"] = {
                                "Kausapin mo ako nang may galang o huwag na lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "We need to keep this professional and decent.",
                            },
                            ["TL"] = {
                                "Kailangan nating panatilihing maayos at magalang ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "There's no call for hostility here.",
                            },
                            ["TL"] = {
                                "Walang dahilan para maging marahas dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I won't be spoken to that way.",
                            },
                            ["TL"] = {
                                "Hindi ako papayag na ganyanin ang pananalita sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Keep your hostility out of this conversation.",
                            },
                            ["TL"] = {
                                "Alisin mo ang galit sa usapang ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "We have boundaries here. Respect them.",
                            },
                            ["TL"] = {
                                "May mga hangganan tayo rito. Igalang mo ang mga 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "That kind of talk isn't going to get you anywhere.",
                            },
                            ["TL"] = {
                                "Walang patutunguhan ang ganyang pananalita.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Lower your voice and adjust your attitude.",
                            },
                            ["TL"] = {
                                "Hinaan mo ang boses mo at ayusin ang asal mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I expect basic decency from the people around me.",
                            },
                            ["TL"] = {
                                "Umaasa ako sa simpleng respeto mula sa mga kasama ko.",
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
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.hostile_boundary.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.hostile_boundary.terse",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[26]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialReactionsAckDispute/Catalog",
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
                ["responseTemplateID"] = "semantic.social.hostile_boundary",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/hostile.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "Watch it.",
                            },
                            ["TL"] = {
                                "Mag-ingat ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Out of line.",
                            },
                            ["TL"] = {
                                "Sobra na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Stop.",
                            },
                            ["TL"] = {
                                "Tigil.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Tone it down.",
                            },
                            ["TL"] = {
                                "Hinaan mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Respect.",
                            },
                            ["TL"] = {
                                "Respeto.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Check yourself.",
                            },
                            ["TL"] = {
                                "Ayusin mo sarili mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Enough.",
                            },
                            ["TL"] = {
                                "Sapat na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Not with me.",
                            },
                            ["TL"] = {
                                "Huwag sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Line crossed.",
                            },
                            ["TL"] = {
                                "Lumagpas ka na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Back off.",
                            },
                            ["TL"] = {
                                "Umatras ka.",
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
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.hostile_boundary.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.hostile_boundary.warm",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[27]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialReactionsAckDispute/Catalog",
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
                ["responseTemplateID"] = "semantic.social.hostile_boundary",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/hostile.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "Hey, where is this hostility coming from? We're allies.",
                            },
                            ["TL"] = {
                                "Huy, saan nanggagaling ang galit na 'yan? Magkakampi tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Don't snap at me like that. I've only ever helped you.",
                            },
                            ["TL"] = {
                                "Huwag mo akong sigawan nang ganyan. Tumulong lang ako sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "I care about you, but that doesn't mean you can disrespect me.",
                            },
                            ["TL"] = {
                                "Nagmamalasakit ako sa 'yo, pero di ibig sabihing pwede mo akong bastusin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Please, let's treat each other better than this.",
                            },
                            ["TL"] = {
                                "Pakiusap, magtrato tayo nang mas maayos kaysa rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "That hurt, coming from you. Let's dial it back.",
                            },
                            ["TL"] = {
                                "Masakit marinig galing sa 'yo. Bawiin mo 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "We've got enough enemies out there without turning on each other.",
                            },
                            ["TL"] = {
                                "Marami na tayong kaaway sa labas, huwag na tayong mag-away.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Take a breath. I'm not your enemy.",
                            },
                            ["TL"] = {
                                "Huminga ka muna. Hindi mo ako kalaban.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "I don't deserve that kind of anger from you.",
                            },
                            ["TL"] = {
                                "Hindi ako karapat-dapat sa ganyang galit mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Let's remember who we are to each other.",
                            },
                            ["TL"] = {
                                "Tandaan natin kung sino tayo sa isa't isa.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Don't burn this bridge over a bad temper.",
                            },
                            ["TL"] = {
                                "Huwag mong sirain ang samahan natin dahil sa init ng ulo.",
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
