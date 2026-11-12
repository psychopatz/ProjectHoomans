-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.conversation.acknowledged.default.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.conversation.acknowledged.default.guarded",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialEmotes/Catalog",
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
                ["responseTemplateID"] = "semantic.conversation.acknowledged.default",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/emotes/emotes_conversation.json",
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
                                "Heard. That's enough talk for now.",
                            },
                            ["TL"] = {
                                "Narinig ko. Sapat na ang usapan sa ngayon.",
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
                                "Got it. Let's keep our heads on our shoulders.",
                            },
                            ["TL"] = {
                                "Naintindihan. Mag-ingat na lang tayo sa paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "I heard what you said. Leaving it at that.",
                            },
                            ["TL"] = {
                                "Narinig ko ang sinabi mo. Iiwan ko na roon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "All right. Eyes open.",
                            },
                            ["TL"] = {
                                "Sige. Buksan ang mga mata.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "I take your point. Let's stay alert.",
                            },
                            ["TL"] = {
                                "Nakuha ko ang punto mo. Manatiling alisto.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Clear enough. No more discussion needed.",
                            },
                            ["TL"] = {
                                "Malinaw na. Hindi na kailangan ng karagdagang usapan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Keep sharp.",
                            },
                            ["TL"] = {
                                "Naintindihan. Maging alerto.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Noted. Back to watching the perimeter.",
                            },
                            ["TL"] = {
                                "Tala ko na. Balik sa pagbabantay.",
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
        ["sourceShard"] = "psdl/dialogue/social_emotes.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.conversation.acknowledged.default.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.conversation.acknowledged.default.neutral",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialEmotes/Catalog",
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
                ["responseTemplateID"] = "semantic.conversation.acknowledged.default",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/emotes/emotes_conversation.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "All right. Ask if you want to talk more.",
                            },
                            ["TL"] = {
                                "Sige. Magtanong ka kung gusto mo pang mag-usap.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Let me know if you need anything else.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Sabihan mo ako kung may kailangan ka pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Sounds good. We can pick this up later.",
                            },
                            ["TL"] = {
                                "Mabuti. Pwede nating ipagpatuloy ito mamaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Got it. Let's get back to what we were doing.",
                            },
                            ["TL"] = {
                                "Nakuha ko. Balik na tayo sa ginagawa natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Fair enough. Holler if something comes up.",
                            },
                            ["TL"] = {
                                "Makatwiran. Tawagin mo ako kapag may nangyari.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "All right. We're on the same page.",
                            },
                            ["TL"] = {
                                "Sige. Pareho tayo ng iniisip.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Take care.",
                            },
                            ["TL"] = {
                                "Naintindihan. Mag-ingat ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Clear. We'll talk again soon.",
                            },
                            ["TL"] = {
                                "Malinaw. Mag-uusap tayong muli mamaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Got it. I'm around if you need to talk.",
                            },
                            ["TL"] = {
                                "Nakuha ko. Narito lang ako kung kailangan mong makipag-usap.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Right. We'll leave it there for now.",
                            },
                            ["TL"] = {
                                "Sige. Dito muna tayo magtapos sa ngayon.",
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
        ["sourceShard"] = "psdl/dialogue/social_emotes.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.conversation.acknowledged.default.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.conversation.acknowledged.default.terse",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialEmotes/Catalog",
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
                ["responseTemplateID"] = "semantic.conversation.acknowledged.default",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/emotes/emotes_conversation.json",
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
                                "Right.",
                            },
                            ["TL"] = {
                                "Tama.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
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
                        ["id"] = "terse.07",
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
                                "Okay.",
                            },
                            ["TL"] = {
                                "Sige na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Noted.",
                            },
                            ["TL"] = {
                                "Tala ko na.",
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
        ["sourceShard"] = "psdl/dialogue/social_emotes.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.conversation.acknowledged.default.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.conversation.acknowledged.default.warm",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialEmotes/Catalog",
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
                ["responseTemplateID"] = "semantic.conversation.acknowledged.default",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/emotes/emotes_conversation.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "All right. I'm here if you want to talk more.",
                            },
                            ["TL"] = {
                                "Sige. Narito ako kung gusto mo pang mag-usap.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Glad we talked. Holler anytime you need to chat.",
                            },
                            ["TL"] = {
                                "Mabuti at nagkausap tayo. Tawagin mo lang ako kahit kailan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "I hear you loud and clear. Take care of yourself.",
                            },
                            ["TL"] = {
                                "Narinig kita nang malinaw. Ingatan mo ang sarili mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Good talking with you. We'll catch up again soon.",
                            },
                            ["TL"] = {
                                "Masarap kang makausap. Magkuwentuhan ulit tayo mamaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Always good to touch base with you.",
                            },
                            ["TL"] = {
                                "Naintindihan ko. Laging magandang makipag-ugnayan sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Anytime you want to talk, you know where to find me.",
                            },
                            ["TL"] = {
                                "Kahit kailan mo gustong mag-usap, alam mo kung nasaan ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Got it. Stay safe out there today.",
                            },
                            ["TL"] = {
                                "Nakuha ko. Mag-ingat ka sa labas ngayong araw.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "Always happy to listen. Take it easy.",
                            },
                            ["TL"] = {
                                "Lagi akong handang makinig. Dahan-dahan lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "All right. Glad we got that sorted out together.",
                            },
                            ["TL"] = {
                                "Sige. Mabuti at naayos natin 'yan nang magkasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Thanks for taking the time to talk. Catch you later.",
                            },
                            ["TL"] = {
                                "Salamat sa paglalaan ng oras para mag-usap. Kita tayo mamaya.",
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
        ["sourceShard"] = "psdl/dialogue/social_emotes.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.emote.player.clap.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.emote.player.clap.neutral",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialEmotes/Catalog",
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
                ["responseTemplateID"] = "semantic.emote.player.clap",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/emotes/emotes_player.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Well done, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Magaling, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "That's worth celebrating, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Karapat-dapat ipagdiwang iyan, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Nice work, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Mahusay na trabaho, {addressee.name}.",
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
        ["sourceShard"] = "psdl/dialogue/social_emotes.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.emote.player.insult.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.emote.player.insult.neutral",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[5]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialEmotes/Catalog",
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
                ["responseTemplateID"] = "semantic.emote.player.insult",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/emotes/emotes_player.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Back off, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Lumayo ka, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "You're asking for trouble, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Naghahanap ka ng gulo, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Keep your distance, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Panatilihin ang distansya, {addressee.name}.",
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
        ["sourceShard"] = "psdl/dialogue/social_emotes.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.emote.player.salute.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.emote.player.salute.neutral",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[6]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialEmotes/Catalog",
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
                ["responseTemplateID"] = "semantic.emote.player.salute",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/emotes/emotes_player.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Respect, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Paggalang, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I see you, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Nakikita kita, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Stay sharp, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Manatiling alerto, {addressee.name}.",
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
        ["sourceShard"] = "psdl/dialogue/social_emotes.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.emote.player.thankyou.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.emote.player.thankyou.neutral",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[7]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialEmotes/Catalog",
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
                ["responseTemplateID"] = "semantic.emote.player.thankyou",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/emotes/emotes_player.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Thanks, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Salamat, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I appreciate that, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Pinahahalagahan ko iyan, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "You have my thanks, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Salamat sa iyo, {addressee.name}.",
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
        ["sourceShard"] = "psdl/dialogue/social_emotes.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.emote.player.thumbsdown.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.emote.player.thumbsdown.neutral",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[8]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialEmotes/Catalog",
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
                ["responseTemplateID"] = "semantic.emote.player.thumbsdown",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/emotes/emotes_player.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "No. That's not good enough, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Hindi. Hindi sapat iyan, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I don't like that, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Hindi ko gusto iyan, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Try again, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Subukan muli, {addressee.name}.",
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
        ["sourceShard"] = "psdl/dialogue/social_emotes.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.emote.player.thumbsup.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.emote.player.thumbsup.neutral",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[9]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialEmotes/Catalog",
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
                ["responseTemplateID"] = "semantic.emote.player.thumbsup",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/emotes/emotes_player.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Good work, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Mahusay, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "That's what I like to see, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Iyan ang gusto kong makita, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Keep it up, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Ipagpatuloy mo, {addressee.name}.",
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
        ["sourceShard"] = "psdl/dialogue/social_emotes.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.emote.player.wavebye.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.emote.player.wavebye.neutral",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[10]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialEmotes/Catalog",
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
                ["responseTemplateID"] = "semantic.emote.player.wavebye",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/emotes/emotes_player.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Take care, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Mag-ingat, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "See you around, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Kita tayo, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Stay safe, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Manatiling ligtas, {addressee.name}.",
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
        ["sourceShard"] = "psdl/dialogue/social_emotes.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.emote.player.wavehi.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.emote.player.wavehi.neutral",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[11]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialEmotes/Catalog",
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
                ["responseTemplateID"] = "semantic.emote.player.wavehi",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/emotes/emotes_player.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Hey, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Uy, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Good to see you, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Mabuti at nakita kita, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Morning, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Magandang umaga, {addressee.name}.",
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
        ["sourceShard"] = "psdl/dialogue/social_emotes.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.emote.reply.clap.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.emote.reply.clap.neutral",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[12]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialEmotes/Catalog",
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
                ["responseTemplateID"] = "semantic.emote.reply.clap",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/emotes/reply.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Thanks.",
                            },
                            ["TL"] = {
                                "Salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Appreciate the applause.",
                            },
                            ["TL"] = {
                                "Salamat sa palakpak.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Just doing what had to be done.",
                            },
                            ["TL"] = {
                                "Ginawa lang ang kailangang gawin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Glad you liked it.",
                            },
                            ["TL"] = {
                                "Mabuti at nagustuhan mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Much appreciated.",
                            },
                            ["TL"] = {
                                "Maraming salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "All in a day's work.",
                            },
                            ["TL"] = {
                                "Bahagi lang 'yan ng araw-araw na trabaho.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Thanks. Good to know it landed well.",
                            },
                            ["TL"] = {
                                "Salamat. Mabuting malaman na maayos ang dating.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Appreciate it.",
                            },
                            ["TL"] = {
                                "Salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Thanks. Let's keep the momentum going.",
                            },
                            ["TL"] = {
                                "Salamat. Tuloy lang natin ang sigla.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Thank you for the encouragement.",
                            },
                            ["TL"] = {
                                "Salamat sa pampalakas ng loob.",
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
        ["sourceShard"] = "psdl/dialogue/social_emotes.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.emote.reply.clap.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.emote.reply.clap.warm",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[13]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialEmotes/Catalog",
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
                ["responseTemplateID"] = "semantic.emote.reply.clap",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/emotes/reply.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "You're too kind.",
                            },
                            ["TL"] = {
                                "Napakabait mo naman.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Thanks! That really puts a smile on my face.",
                            },
                            ["TL"] = {
                                "Salamat! Napangiti talaga ako roon.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Appreciate the cheer! We make a solid team.",
                            },
                            ["TL"] = {
                                "Salamat sa suporta! Matibay tayong grupo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Thank you! Couldn't have done it without good company.",
                            },
                            ["TL"] = {
                                "Salamat! Hindi ko magagawa 'yon nang walang maayos na kasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Haha, thanks! Glad to bring some light into the day.",
                            },
                            ["TL"] = {
                                "Haha, salamat! Mabuti at nakapagbigay ng sigla ngayong araw.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "That makes me feel good. Thank you!",
                            },
                            ["TL"] = {
                                "Napakasarap sa pakiramdam niyan. Salamat!",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "You're awesome. Thanks for the cheer.",
                            },
                            ["TL"] = {
                                "Ang galing mo. Salamat sa pagpalakpak.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "Appreciate the love! Let's keep winning.",
                            },
                            ["TL"] = {
                                "Salamat sa suporta! Tuloy lang tayo sa tagumpay.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Thanks a bunch! That means a lot to me.",
                            },
                            ["TL"] = {
                                "Maraming salamat! Malaking bagay 'yan sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Haha, bowing now! Thanks, friend.",
                            },
                            ["TL"] = {
                                "Haha, yumuyukod na ako! Salamat, kaibigan.",
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
        ["sourceShard"] = "psdl/dialogue/social_emotes.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.emote.reply.default.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.emote.reply.default.neutral",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[14]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialEmotes/Catalog",
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
                ["responseTemplateID"] = "semantic.emote.reply.default",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/emotes/reply.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I hear you.",
                            },
                            ["TL"] = {
                                "Narinig kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
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
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Understood.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Fair enough.",
                            },
                            ["TL"] = {
                                "May punto ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I see you.",
                            },
                            ["TL"] = {
                                "Nakikita kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Right back at you.",
                            },
                            ["TL"] = {
                                "Pabalik din sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Acknowledged.",
                            },
                            ["TL"] = {
                                "Kinikilala ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
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
                        ["id"] = "neutral.09",
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
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Message received.",
                            },
                            ["TL"] = {
                                "Mensahe nakuha.",
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
        ["sourceShard"] = "psdl/dialogue/social_emotes.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.emote.reply.insult.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.emote.reply.insult.neutral",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[15]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialEmotes/Catalog",
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
                ["responseTemplateID"] = "semantic.emote.reply.insult",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/emotes/reply.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Keep it respectful.",
                            },
                            ["TL"] = {
                                "Maging magalang ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Save that attitude for the dead.",
                            },
                            ["TL"] = {
                                "Itabi mo ang ugaling 'yan para sa mga patay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Not in the mood for that.",
                            },
                            ["TL"] = {
                                "Wala ako sa mood para diyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Watch yourself.",
                            },
                            ["TL"] = {
                                "Mag-ingat ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Keep your hands and words to yourself.",
                            },
                            ["TL"] = {
                                "Itago mo sa sarili mo ang mga salita mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Don't start something out here.",
                            },
                            ["TL"] = {
                                "Huwag kang magsimula ng gulo rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Grow up. We have real threats to worry about.",
                            },
                            ["TL"] = {
                                "Magpakatanda ka. May mga totoong panganib tayong kinakaharap.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Not amused.",
                            },
                            ["TL"] = {
                                "Hindi nakatutuwa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Check yourself before you cause trouble.",
                            },
                            ["TL"] = {
                                "Pagsabihan mo ang sarili mo bago ka makagawa ng gulo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I'm ignoring that for now. Don't push it.",
                            },
                            ["TL"] = {
                                "Pinalalampas ko muna 'yan. Huwag mong sagarin.",
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
        ["sourceShard"] = "psdl/dialogue/social_emotes.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.emote.reply.insult.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.emote.reply.insult.warm",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[16]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialEmotes/Catalog",
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
                ["responseTemplateID"] = "semantic.emote.reply.insult",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/emotes/reply.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "You're lucky I know you.",
                            },
                            ["TL"] = {
                                "Suwerte ka dahil kilala kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Very funny. Don't make a habit of it.",
                            },
                            ["TL"] = {
                                "Nakakatawa. Huwag mong gagawing bisyo 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'll let that slide because it's you.",
                            },
                            ["TL"] = {
                                "Palalampasin ko 'yan dahil ikaw 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Haha, watch it, or I might just get even.",
                            },
                            ["TL"] = {
                                "Haha, mag-ingat ka, baka gumanti ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Good thing we're friends, or we'd have words.",
                            },
                            ["TL"] = {
                                "Mabuti na lang magkaibigan tayo, kundi magkakatuusan tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "You always like testing my patience, don't you?",
                            },
                            ["TL"] = {
                                "Gusto mo talagang sinusubukan ang pasensya ko, 'no?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Play nice. I know you're just messing around.",
                            },
                            ["TL"] = {
                                "Mag-ayos ka. Alam kong nagbibiro ka lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "You're pushing your luck, but I'll allow it this once.",
                            },
                            ["TL"] = {
                                "Sinusugal mo ang suwerte mo, pero papayagan ko muna ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Only you could get away with saying that to me.",
                            },
                            ["TL"] = {
                                "Ikaw lang ang makalulusot sa pagsasabi niyan sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Haha, all right, point taken, smart-mouth.",
                            },
                            ["TL"] = {
                                "Haha, sige na, nakuha ko na, pilosopo.",
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
        ["sourceShard"] = "psdl/dialogue/social_emotes.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.emote.reply.salute.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.emote.reply.salute.neutral",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[17]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialEmotes/Catalog",
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
                ["responseTemplateID"] = "semantic.emote.reply.salute",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/emotes/reply.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Stay sharp.",
                            },
                            ["TL"] = {
                                "Manatiling alerto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Keep your guard up.",
                            },
                            ["TL"] = {
                                "Huwag ibaba ang bantay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Eyes forward.",
                            },
                            ["TL"] = {
                                "Tumingin sa unahan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "At ease.",
                            },
                            ["TL"] = {
                                "Magpahinga.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Stay safe out there.",
                            },
                            ["TL"] = {
                                "Mag-ingat ka sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Watch your six.",
                            },
                            ["TL"] = {
                                "Bantayan mo ang likod mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Salute returned.",
                            },
                            ["TL"] = {
                                "Ganti ang pagsaludo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Keep moving and stay vigilant.",
                            },
                            ["TL"] = {
                                "Patuloy na lumakad at maging mapagmatyag.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Stay ready.",
                            },
                            ["TL"] = {
                                "Naintindihan. Maging laging handa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Stand firm.",
                            },
                            ["TL"] = {
                                "Magpakatatag.",
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
        ["sourceShard"] = "psdl/dialogue/social_emotes.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.emote.reply.salute.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.emote.reply.salute.warm",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[18]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialEmotes/Catalog",
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
                ["responseTemplateID"] = "semantic.emote.reply.salute",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/emotes/reply.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "Always. Stay safe out there.",
                            },
                            ["TL"] = {
                                "Palagi. Mag-ingat ka sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Salute to you too, friend.",
                            },
                            ["TL"] = {
                                "Saludo rin sa 'yo, kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Right back at you. Let's make it back in one piece.",
                            },
                            ["TL"] = {
                                "Pabalik din sa 'yo. Tiyakin nating makababalik tayo nang buo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Honored to stand with you.",
                            },
                            ["TL"] = {
                                "Ikinararangal kong makatabi ka sa laban.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Keep your head down and stay alive for me.",
                            },
                            ["TL"] = {
                                "Yumuko ka sa panganib at manatiling buhay para sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Good to have you beside me out here.",
                            },
                            ["TL"] = {
                                "Mabuting kasama kita rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Salute returned with respect, partner.",
                            },
                            ["TL"] = {
                                "May kasamang respeto ang ganting saludo ko, kasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "We watch each other's backs. Always.",
                            },
                            ["TL"] = {
                                "Binabantayan natin ang likod ng isa't isa. Palagi.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Take care of yourself today. I mean it.",
                            },
                            ["TL"] = {
                                "Ingatan mo ang sarili mo ngayong araw. Seryoso ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Stay strong out there. We'll get through this.",
                            },
                            ["TL"] = {
                                "Magpakatatag ka sa labas. Malalampasan natin ito.",
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
        ["sourceShard"] = "psdl/dialogue/social_emotes.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.emote.reply.thankyou.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.emote.reply.thankyou.neutral",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[19]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialEmotes/Catalog",
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
                ["responseTemplateID"] = "semantic.emote.reply.thankyou",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/emotes/reply.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "You're welcome.",
                            },
                            ["TL"] = {
                                "Walang anuman.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "No problem.",
                            },
                            ["TL"] = {
                                "Walang problema.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Don't mention it.",
                            },
                            ["TL"] = {
                                "Huwag mo nang alalahanin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Glad to help.",
                            },
                            ["TL"] = {
                                "Masayang tumulong.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Anytime.",
                            },
                            ["TL"] = {
                                "Kahit kailan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Just doing my part.",
                            },
                            ["TL"] = {
                                "Ginagawa ko lang ang bahagi ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Happy to assist.",
                            },
                            ["TL"] = {
                                "Mabuti at nakatulong ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "No trouble at all.",
                            },
                            ["TL"] = {
                                "Walang anuman talaga.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "All part of surviving together.",
                            },
                            ["TL"] = {
                                "Bahagi lang 'yan ng sabay na pamumuhay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "You'd do the same for me.",
                            },
                            ["TL"] = {
                                "Gagawin mo rin 'yan para sa akin.",
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
        ["sourceShard"] = "psdl/dialogue/social_emotes.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.emote.reply.thankyou.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.emote.reply.thankyou.warm",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[20]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialEmotes/Catalog",
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
                ["responseTemplateID"] = "semantic.emote.reply.thankyou",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/emotes/reply.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "Anytime. We look after our own.",
                            },
                            ["TL"] = {
                                "Kahit kailan. Inaalagaan natin ang mga kasama natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "You're very welcome, friend.",
                            },
                            ["TL"] = {
                                "Walang anuman talaga, kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Always happy to lend a hand to you.",
                            },
                            ["TL"] = {
                                "Lagi akong handang tumulong sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Don't worry about it for a second. Glad to be here.",
                            },
                            ["TL"] = {
                                "Huwag mo nang isipin kahit sandali. Mabuti at narito ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "We've got each other's backs. That's what counts.",
                            },
                            ["TL"] = {
                                "Nagtitinginan tayo sa isa't isa. Iyon ang mahalaga.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "You deserve the help. Don't mention it.",
                            },
                            ["TL"] = {
                                "Karapat-dapat ka sa tulong. Huwag mo nang banggitin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Anytime! Seriously, just ask whenever.",
                            },
                            ["TL"] = {
                                "Kahit kailan! magsabi ka lang kapag may kailangan ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'm glad I could be there for you.",
                            },
                            ["TL"] = {
                                "Mabuti at nakatulong ako sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "No need to thank me. That's what partners do.",
                            },
                            ["TL"] = {
                                "Di mo kailangang magpasalamat. Ganyan talaga ang magkasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Happy to help. Always.",
                            },
                            ["TL"] = {
                                "Masayang tumulong. Palagi.",
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
        ["sourceShard"] = "psdl/dialogue/social_emotes.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.emote.reply.thumbsdown.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.emote.reply.thumbsdown.neutral",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[21]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialEmotes/Catalog",
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
                ["responseTemplateID"] = "semantic.emote.reply.thumbsdown",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/emotes/reply.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I got the message. Tell me what's wrong.",
                            },
                            ["TL"] = {
                                "Nakuha ko ang mensahe. Sabihin mo kung anong problema.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Not happy with that? What's your take?",
                            },
                            ["TL"] = {
                                "Hindi ka sang-ayon? Ano ang opinyon mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. You disagree.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Hindi ka sang-ayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Message received. We can rethink it.",
                            },
                            ["TL"] = {
                                "Nakuha ko ang pahiwatig. Pwede nating pag-isipan ulit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Got it. You don't like the look of this.",
                            },
                            ["TL"] = {
                                "Naintindihan. Hindi maganda ang kutob mo rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Fair enough. What's the alternative?",
                            },
                            ["TL"] = {
                                "Makatwiran. Ano ang alternatibo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I hear the disapproval. Let's adjust.",
                            },
                            ["TL"] = {
                                "Naririnig ko ang pagtutol mo. Mag-ayos tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Noted. We won't go that route then.",
                            },
                            ["TL"] = {
                                "Tala ko na. Hindi na natin dadaanan ang rutang 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Point taken.",
                            },
                            ["TL"] = {
                                "Naintindihan. Nakuha ko ang punto mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "All right, let's look for a better option.",
                            },
                            ["TL"] = {
                                "Sige, maghanap tayo ng mas magandang paraan.",
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
        ["sourceShard"] = "psdl/dialogue/social_emotes.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.emote.reply.thumbsup.active.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.emote.reply.thumbsup.active.neutral",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[24]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialEmotes/Catalog",
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
                ["responseTemplateID"] = "semantic.emote.reply.thumbsup.active",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/emotes/reply.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Good. Let's keep moving on this.",
                            },
                            ["TL"] = {
                                "Mabuti. Ipagpatuloy natin ang pagkilos dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Right. Back to work.",
                            },
                            ["TL"] = {
                                "Sige. Balik sa trabaho.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Stay on task.",
                            },
                            ["TL"] = {
                                "Naintindihan. Manatili sa gawain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Good. Let's get this finished up.",
                            },
                            ["TL"] = {
                                "Mabuti. Tapusin na natin ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Agreed. Pushing forward now.",
                            },
                            ["TL"] = {
                                "Sang-ayon. Umuusad na ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Moving along. Keep your eyes peeled.",
                            },
                            ["TL"] = {
                                "Tuloy ang lakad. Maging mapagmatyag.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Right. Making progress.",
                            },
                            ["TL"] = {
                                "Tama. May nararating na tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Good to know. Sticking to the objective.",
                            },
                            ["TL"] = {
                                "Mabuting malaman. Manatili sa layunin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. No slowing down now.",
                            },
                            ["TL"] = {
                                "Naintindihan. Walang magbabagal ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "On it. Keeping our momentum.",
                            },
                            ["TL"] = {
                                "Inaasikaso na. Tuloy ang bilis.",
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
        ["sourceShard"] = "psdl/dialogue/social_emotes.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.emote.reply.thumbsup.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.emote.reply.thumbsup.neutral",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[22]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialEmotes/Catalog",
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
                ["responseTemplateID"] = "semantic.emote.reply.thumbsup",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/emotes/reply.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
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
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Sounds like a plan.",
                            },
                            ["TL"] = {
                                "Magandang plano 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Glad we agree.",
                            },
                            ["TL"] = {
                                "Mabuti at nagkasundo tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Right on.",
                            },
                            ["TL"] = {
                                "Tama 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Let's make it happen.",
                            },
                            ["TL"] = {
                                "Naintindihan. Isakatuparan na natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Good to go.",
                            },
                            ["TL"] = {
                                "Handa na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Works for me.",
                            },
                            ["TL"] = {
                                "Ayos 'yan sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Agreed.",
                            },
                            ["TL"] = {
                                "Sang-ayon ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "All set then.",
                            },
                            ["TL"] = {
                                "Handa na ang lahat kung ganoon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Solid.",
                            },
                            ["TL"] = {
                                "Matibay.",
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
        ["sourceShard"] = "psdl/dialogue/social_emotes.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.emote.reply.thumbsup.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.emote.reply.thumbsup.warm",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[23]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialEmotes/Catalog",
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
                ["responseTemplateID"] = "semantic.emote.reply.thumbsup",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/emotes/reply.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "That's the spirit.",
                            },
                            ["TL"] = {
                                "Iyan ang magandang sigla.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Awesome. Let's knock it out.",
                            },
                            ["TL"] = {
                                "Napakaganda. Tapusin na natin ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Love the energy! Let's do this.",
                            },
                            ["TL"] = {
                                "Gusto ko ang sigla mo! Tara na.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Great minds think alike, friend.",
                            },
                            ["TL"] = {
                                "Pareho tayo ng magandang takbo ng isip, kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Hell yeah. We've got this.",
                            },
                            ["TL"] = {
                                "Oo naman. Kayang-kaya natin ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "That's what I like to see. Full speed ahead.",
                            },
                            ["TL"] = {
                                "Iyan ang gusto kong makita. Tuloy-tuloy lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Good deal. Glad you're on board.",
                            },
                            ["TL"] = {
                                "Magandang usapan. Mabuti at kasama ka rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "Right there with you! Let's get it done.",
                            },
                            ["TL"] = {
                                "Kasama mo ako riyan! Tapusin na natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "That puts wind in my sails. Thank you.",
                            },
                            ["TL"] = {
                                "Nagbigay 'yan ng lakas sa akin. Salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Perfect. We're in sync.",
                            },
                            ["TL"] = {
                                "Perpekto. Tugma ang takbo natin.",
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
        ["sourceShard"] = "psdl/dialogue/social_emotes.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.emote.reply.wavebye.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.emote.reply.wavebye.neutral",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[25]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialEmotes/Catalog",
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
                ["responseTemplateID"] = "semantic.emote.reply.wavebye",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/emotes/reply.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Take care.",
                            },
                            ["TL"] = {
                                "Mag-ingat ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "See you around.",
                            },
                            ["TL"] = {
                                "Magkita na lang tayo mamaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Watch your back out there.",
                            },
                            ["TL"] = {
                                "Bantayan mo ang likod mo sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Until next time.",
                            },
                            ["TL"] = {
                                "Hanggang sa muli.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Stay safe.",
                            },
                            ["TL"] = {
                                "Manatiling ligtas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Keep your guard up on the way.",
                            },
                            ["TL"] = {
                                "Huwag ibaba ang bantay habang naglalakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Catch you later.",
                            },
                            ["TL"] = {
                                "Usap na lang tayo mamaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Farewell for now.",
                            },
                            ["TL"] = {
                                "Paalam muna sa ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Keep your head down.",
                            },
                            ["TL"] = {
                                "Yumuko ka sa panganib.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "See you when you get back.",
                            },
                            ["TL"] = {
                                "Kita tayo pagbalik mo.",
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
        ["sourceShard"] = "psdl/dialogue/social_emotes.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.emote.reply.wavebye.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.emote.reply.wavebye.warm",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[26]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialEmotes/Catalog",
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
                ["responseTemplateID"] = "semantic.emote.reply.wavebye",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/emotes/reply.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "Goodbye. Come back in one piece.",
                            },
                            ["TL"] = {
                                "Paalam. Bumalik ka nang buo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Take good care of yourself, friend.",
                            },
                            ["TL"] = {
                                "Ingatan mo nang maayos ang sarili mo, kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "See you soon. Don't do anything reckless.",
                            },
                            ["TL"] = {
                                "Magkita tayo agad. Huwag kang gagawa ng padalos-dalos.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "I'll be waiting right here. Stay safe.",
                            },
                            ["TL"] = {
                                "Maghihintay ako rito. Mag-ingat ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Farewell for now. Looking forward to our next talk.",
                            },
                            ["TL"] = {
                                "Paalam muna. Inaasahan ko ang susunod nating usapan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Safe travels out there. Keep your wits about you.",
                            },
                            ["TL"] = {
                                "Ligtas na paglalakbay sa labas. Gamitin lagi ang isip.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Goodbye! Make sure you make it back.",
                            },
                            ["TL"] = {
                                "Paalam! Tiyakin mong makababalik ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "Catch you later, partner. Be careful.",
                            },
                            ["TL"] = {
                                "Kita tayo mamaya, kasama. Mag-iingat ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Take care. I'll keep the fire going.",
                            },
                            ["TL"] = {
                                "Mag-ingat ka. Pananatilihin kong may apoy rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "See you later. Stay alive out there.",
                            },
                            ["TL"] = {
                                "Kita tayo mamaya. Manatiling buhay sa labas.",
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
        ["sourceShard"] = "psdl/dialogue/social_emotes.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.emote.reply.wavehi.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.emote.reply.wavehi.neutral",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[27]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialEmotes/Catalog",
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
                ["responseTemplateID"] = "semantic.emote.reply.wavehi",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/emotes/reply.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Hey.",
                            },
                            ["TL"] = {
                                "Uy.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Hello there.",
                            },
                            ["TL"] = {
                                "Kumusta ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Good to see you.",
                            },
                            ["TL"] = {
                                "Mabuti at nakita kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Greetings.",
                            },
                            ["TL"] = {
                                "Pagbati sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Hey. What's the word?",
                            },
                            ["TL"] = {
                                "Uy. Anong balita?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Hello. Everything quiet?",
                            },
                            ["TL"] = {
                                "Kumusta. Tahimik ba ang lahat?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Morning or afternoon, good to see another survivor.",
                            },
                            ["TL"] = {
                                "Umaga man o hapon, mabuting makakita ng buhay na tao.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Hey. How are things looking?",
                            },
                            ["TL"] = {
                                "Uy. Kamusta ang kalagayan diyan?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Hello. Need something?",
                            },
                            ["TL"] = {
                                "Kumusta. May kailangan ka ba?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Hey there. Staying in one piece?",
                            },
                            ["TL"] = {
                                "Kumusta. Buo pa ba ang katawan mo?",
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
        ["sourceShard"] = "psdl/dialogue/social_emotes.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.emote.reply.wavehi.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.emote.reply.wavehi.terse",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[28]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialEmotes/Catalog",
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
                ["responseTemplateID"] = "semantic.emote.reply.wavehi",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/emotes/reply.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "There you are.",
                            },
                            ["TL"] = {
                                "Nandiyan ka pala.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Hey.",
                            },
                            ["TL"] = {
                                "Uy.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "What's up.",
                            },
                            ["TL"] = {
                                "Anong meron.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "You're back.",
                            },
                            ["TL"] = {
                                "Bumalik ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Morning.",
                            },
                            ["TL"] = {
                                "Magandang araw.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Evening.",
                            },
                            ["TL"] = {
                                "Magandang gabi.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "State your business.",
                            },
                            ["TL"] = {
                                "Sabihin ang pakay mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Saw you.",
                            },
                            ["TL"] = {
                                "Nakita kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Alive still.",
                            },
                            ["TL"] = {
                                "Buhay pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Speak up.",
                            },
                            ["TL"] = {
                                "Magsalita ka.",
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
        ["sourceShard"] = "psdl/dialogue/social_emotes.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_emotes",
        ["id"] = "semantic.emote.reply.wavehi.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.emote.reply.wavehi.warm",
            ["sourcePath"] = "psdl/dialogue/social_emotes.json#records[29]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialEmotes/Catalog",
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
                ["responseTemplateID"] = "semantic.emote.reply.wavehi",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/emotes/reply.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "Hey again. Good to see a friendly face.",
                            },
                            ["TL"] = {
                                "Uy muli. Mabuti at may nakitang kaibigang mukha.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Hello, friend! How's your day treating you?",
                            },
                            ["TL"] = {
                                "Kumusta, kaibigan! Kamusta ang araw mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Hey there! Always brightens things up when you come around.",
                            },
                            ["TL"] = {
                                "Kumusta! Laging sumasaya kapag dumadaan ka rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Great to see you again! Everything okay with you?",
                            },
                            ["TL"] = {
                                "Napakagandang makita ka muli! Maayos ba ang lagay mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Hey! I was just hoping you'd swing by.",
                            },
                            ["TL"] = {
                                "Uy! Umasa nga akong dadaan ka rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Welcome back! Good to have you around.",
                            },
                            ["TL"] = {
                                "Maligayang pagbabalik! Mabuting narito ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Hello! Glad to see you made it through safely.",
                            },
                            ["TL"] = {
                                "Kumusta! Mabuti at nakaligtas ka nang ligtas.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "Hey there! Come on over, take a seat.",
                            },
                            ["TL"] = {
                                "Kumusta! Halika rito, umupo ka muna.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Always a relief to see you walking up. Hey!",
                            },
                            ["TL"] = {
                                "Laging nakapagpapagaan ng loob na makita kang naglalakad papalapit. Uy!",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Hey, good to see you! How are you holding up?",
                            },
                            ["TL"] = {
                                "Uy, mabuting makita ka! Kumusta ang lagay mo?",
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
        ["sourceShard"] = "psdl/dialogue/social_emotes.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
