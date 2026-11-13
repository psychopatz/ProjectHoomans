-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_memory",
        ["id"] = "semantic.interaction.memory.acknowledge.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.interaction.memory.acknowledge.guarded",
            ["sourcePath"] = "psdl/dialogue/social_interaction_memory.json#records[3]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionMemory",
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
                ["responseTemplateID"] = "semantic.interaction.memory.acknowledge",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/memory/acknowledge.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "All right. I heard you.",
                            },
                            ["TL"] = {
                                "Sige. Narinig kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "I remember, but let's not dwell on the past.",
                            },
                            ["TL"] = {
                                "Naaalala ko, pero huwag na nating balik-balikan ang nakaraan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Past is past. Keep your focus here.",
                            },
                            ["TL"] = {
                                "Nakalipas na. Magpokus ka sa kasalukuyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "I know what happened. No need to rehash it.",
                            },
                            ["TL"] = {
                                "Alam ko ang nangyari. Di na kailangang ulitin pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Noted. But don't expect me to get sentimental.",
                            },
                            ["TL"] = {
                                "Tala ko na. Pero huwag kang umasang magiging madrama ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Yeah, I remember. Why bring it up now?",
                            },
                            ["TL"] = {
                                "Oo, tanda ko. Bakit mo binubuksan ngayon?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "I haven't forgotten. I never forget.",
                            },
                            ["TL"] = {
                                "Hindi ko kinalimutan. Hindi ako kailanman nakalilimot.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Heard. Let's move on.",
                            },
                            ["TL"] = {
                                "Narinig ko. Lumipat na tayo ng usapan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "I remember the lesson it taught us.",
                            },
                            ["TL"] = {
                                "Naaalala ko ang aral na itinuro niyan sa atin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "All right. Keep that to yourself moving forward.",
                            },
                            ["TL"] = {
                                "Sige. Itago mo na lang sa sarili mo sa susunod.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_memory.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_memory",
        ["id"] = "semantic.interaction.memory.acknowledge.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.interaction.memory.acknowledge.neutral",
            ["sourcePath"] = "psdl/dialogue/social_interaction_memory.json#records[0]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionMemory",
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
                ["responseTemplateID"] = "semantic.interaction.memory.acknowledge",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/memory/acknowledge.json",
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
                                "Naririnig kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I remember that.",
                            },
                            ["TL"] = {
                                "Naaalala ko iyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Sounds familiar.",
                            },
                            ["TL"] = {
                                "Pamilyar ang dating.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Makes sense given what happened.",
                            },
                            ["TL"] = {
                                "May katuturan base sa nangyari.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I recall that well.",
                            },
                            ["TL"] = {
                                "Maliwanag kong naaalala 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Yes, that was quite an event.",
                            },
                            ["TL"] = {
                                "Oo, matinding pangyayari 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I understand why you bring that up.",
                            },
                            ["TL"] = {
                                "Nauunawaan ko kung bakit mo binuksan 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Right. That was a significant moment.",
                            },
                            ["TL"] = {
                                "Tama. Mahalagang sandali 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I hear what you're saying about that.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko ang sinasabi mo tungkol doon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Fair enough. That memory tracks.",
                            },
                            ["TL"] = {
                                "Makatwiran. Tugma ang alaalang 'yan.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_memory.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_memory",
        ["id"] = "semantic.interaction.memory.acknowledge.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.interaction.memory.acknowledge.terse",
            ["sourcePath"] = "psdl/dialogue/social_interaction_memory.json#records[2]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionMemory",
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
                ["responseTemplateID"] = "semantic.interaction.memory.acknowledge",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/memory/acknowledge.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "Mm.",
                            },
                            ["TL"] = {
                                "Mm.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Remember.",
                            },
                            ["TL"] = {
                                "Tanda ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Recall it.",
                            },
                            ["TL"] = {
                                "Naalala ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Yeah.",
                            },
                            ["TL"] = {
                                "Oo.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Heard.",
                            },
                            ["TL"] = {
                                "Narinig.",
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
                                "Got it.",
                            },
                            ["TL"] = {
                                "Nakuha ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "True.",
                            },
                            ["TL"] = {
                                "Totoo.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Yep.",
                            },
                            ["TL"] = {
                                "Oo nga.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Understood.",
                            },
                            ["TL"] = {
                                "Naintindihan.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_memory.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_memory",
        ["id"] = "semantic.interaction.memory.acknowledge.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.interaction.memory.acknowledge.warm",
            ["sourcePath"] = "psdl/dialogue/social_interaction_memory.json#records[1]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionMemory",
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
                ["responseTemplateID"] = "semantic.interaction.memory.acknowledge",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/memory/acknowledge.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "Yeah. I can see why that stayed with you.",
                            },
                            ["TL"] = {
                                "Oo. Naiintindihan ko kung bakit hindi mo iyon makalimutan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "I remember that too. It meant a lot to me.",
                            },
                            ["TL"] = {
                                "Naaalala ko rin 'yon. Malaking bagay 'yon para sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "That was a special moment between us. Glad you remember.",
                            },
                            ["TL"] = {
                                "Espesyal na sandali 'yon sa atin. Mabuti at naaalala mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "It stayed in my heart as well, friend.",
                            },
                            ["TL"] = {
                                "Nanatili rin 'yon sa puso ko, kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Thanks for reminding me of that. Good times.",
                            },
                            ["TL"] = {
                                "Salamat sa pagpapaalala niyan. Magandang alaala.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Those memories keep us human out here.",
                            },
                            ["TL"] = {
                                "Ang mga alaalang 'yan ang nagpapanatiling tao sa atin dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "I smile every time I think back on that day.",
                            },
                            ["TL"] = {
                                "Napapangiti ako tuwing naaalala ko ang araw na 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "We made it through that together. I won't forget it.",
                            },
                            ["TL"] = {
                                "Nalusutan natin 'yon nang magkasama. Di ko 'yon malilimutan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'm glad we share that memory.",
                            },
                            ["TL"] = {
                                "Masaya ako at pinagsaluhan natin ang alaalang 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "That really stuck with both of us, didn't it?",
                            },
                            ["TL"] = {
                                "Talagang tumatak sa ating dalawa 'yon, 'di ba?",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_memory.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_memory",
        ["id"] = "semantic.interaction.memory.acknowledge_flavor.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.interaction.memory.acknowledge_flavor.guarded",
            ["sourcePath"] = "psdl/dialogue/social_interaction_memory.json#records[7]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionMemory",
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
                ["responseTemplateID"] = "semantic.interaction.memory.acknowledge_flavor",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/memory/acknowledge_flavor.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "The listener gives a guarded nod.",
                            },
                            ["TL"] = {
                                "Maingat na tumango ang nakikinig.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "The listener watches closely without revealing their thoughts.",
                            },
                            ["TL"] = {
                                "Masusing nagmasid ang nakikinig nang walang inilalantad na iniisip.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "A cautious look crosses the listener's eyes.",
                            },
                            ["TL"] = {
                                "Isang maingat na tingin ang dumaan sa mga mata ng nakikinig.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "The listener stiffens slightly as the past is mentioned.",
                            },
                            ["TL"] = {
                                "Bahagyang nanigas ang nakikinig nang mabanggit ang nakaraan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "A slow, guarded nod shows the words were registered.",
                            },
                            ["TL"] = {
                                "Isang mabagal at maingat na tango ang nagpahiwatig na narinig ang sinabi.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "The listener's hand rests near their belt during the pause.",
                            },
                            ["TL"] = {
                                "Nakalapag ang kamay ng nakikinig malapit sa sinturon sa sandaling iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "The listener narrows their eyes, weighing the intent behind the words.",
                            },
                            ["TL"] = {
                                "Nanliit ang mga mata ng nakikinig, tinitimbang ang layunin sa likod ng salita.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "A tight, reserved expression settles on the listener's face.",
                            },
                            ["TL"] = {
                                "Isang mahigpit at maramdamang ekspresyon ang namutawi sa mukha ng nakikinig.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "The listener gives nothing away, nodding once carefully.",
                            },
                            ["TL"] = {
                                "Walang ipinakitang emosyon ang nakikinig, isang maingat na tango lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "The listener keeps their guard up while acknowledging the memory.",
                            },
                            ["TL"] = {
                                "Nanatiling alerto ang nakikinig habang kinikilala ang alaala.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_memory.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_memory",
        ["id"] = "semantic.interaction.memory.acknowledge_flavor.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.interaction.memory.acknowledge_flavor.neutral",
            ["sourcePath"] = "psdl/dialogue/social_interaction_memory.json#records[4]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionMemory",
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
                ["responseTemplateID"] = "semantic.interaction.memory.acknowledge_flavor",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/memory/acknowledge_flavor.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "The listener gives a small acknowledging nod.",
                            },
                            ["TL"] = {
                                "Bahagyang tumango ang nakikinig bilang pagkilala.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "The listener listens thoughtfully and nods.",
                            },
                            ["TL"] = {
                                "Matiyagang nakikinig ang kausap at tumatango.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "A steady nod shows the listener remembers.",
                            },
                            ["TL"] = {
                                "Isang matatag na tango ang nagpapakitang naaalala niya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "The listener absorbs the words and dips their head.",
                            },
                            ["TL"] = {
                                "Inintindi ng nakikinig ang mga salita at bahagyang yumukod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "The listener acknowledges the shared recollection quietly.",
                            },
                            ["TL"] = {
                                "Tahimik na kinilala ng nakikinig ang pinagsaluhang alaala.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "A quiet look of recognition passes over the listener's face.",
                            },
                            ["TL"] = {
                                "Isang tahimik na anyo ng pagkilala ang dumaan sa mukha ng nakikinig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "The listener blinks slowly, recalling the moment.",
                            },
                            ["TL"] = {
                                "Mabagal na kumurap ang nakikinig, inaalala ang sandali.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "The listener gives a calm, measured gesture of understanding.",
                            },
                            ["TL"] = {
                                "Nagbigay ang nakikinig ng kalmado at maingat na senyas ng pagkaunawa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "A brief pause precedes an acknowledging nod.",
                            },
                            ["TL"] = {
                                "Isang maikling paghinto ang nauna bago tumango bilang pagkilala.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "The listener tilts their head in silent agreement.",
                            },
                            ["TL"] = {
                                "Itinagilid ng nakikinig ang ulo bilang tahimik na pagsang-ayon.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_memory.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_memory",
        ["id"] = "semantic.interaction.memory.acknowledge_flavor.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.interaction.memory.acknowledge_flavor.terse",
            ["sourcePath"] = "psdl/dialogue/social_interaction_memory.json#records[6]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionMemory",
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
                ["responseTemplateID"] = "semantic.interaction.memory.acknowledge_flavor",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/memory/acknowledge_flavor.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "A brief nod follows.",
                            },
                            ["TL"] = {
                                "Isang maikling tango ang sumunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "A curt dip of the chin confirms it.",
                            },
                            ["TL"] = {
                                "Maikling pagyuko ng baba ang kumumpirma.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "The listener grunts in assent.",
                            },
                            ["TL"] = {
                                "Umungol ang nakikinig bilang pagsang-ayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "A sharp single nod.",
                            },
                            ["TL"] = {
                                "Isang mabilis at iisang tango.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "The listener barely shifts.",
                            },
                            ["TL"] = {
                                "Halos hindi gumalaw ang nakikinig.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Eyes narrow briefly in recognition.",
                            },
                            ["TL"] = {
                                "Sandaling nanliit ang mga mata sa pagkilala.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "A quick jerk of the head acknowledges it.",
                            },
                            ["TL"] = {
                                "Mabilis na paggalaw ng ulo ang kumilala roon.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "The listener's jaw sets firmly.",
                            },
                            ["TL"] = {
                                "Nadiin ang panga ng nakikinig.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "A momentary pause, nothing more.",
                            },
                            ["TL"] = {
                                "Isang saglit na paghinto, wala nang iba.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "A flat nod ends the topic.",
                            },
                            ["TL"] = {
                                "Isang malamig na tango ang nagtapos sa paksa.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_memory.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_memory",
        ["id"] = "semantic.interaction.memory.acknowledge_flavor.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.interaction.memory.acknowledge_flavor.warm",
            ["sourcePath"] = "psdl/dialogue/social_interaction_memory.json#records[5]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionMemory",
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
                ["responseTemplateID"] = "semantic.interaction.memory.acknowledge_flavor",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/memory/acknowledge_flavor.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "The listener softens and nods with quiet understanding.",
                            },
                            ["TL"] = {
                                "Lumambot ang ekspresyon ng nakikinig at tahimik na tumango.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "A faint, gentle smile touches the listener's lips.",
                            },
                            ["TL"] = {
                                "Isang banayad na ngiti ang lumitaw sa labi ng nakikinig.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "The listener's eyes warm as the memory settles in.",
                            },
                            ["TL"] = {
                                "Uminit ang mga mata ng nakikinig habang lumalalim ang alaala.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "The listener gives a warm, reassuring nod.",
                            },
                            ["TL"] = {
                                "Nagbigay ang nakikinig ng mainit at nakapagpapanatag na tango.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "A fond look washes over the listener's tired features.",
                            },
                            ["TL"] = {
                                "Isang masuyong tingin ang dumaloy sa pagod na mukha ng nakikinig.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "The listener reaches out slightly, comforted by the recollection.",
                            },
                            ["TL"] = {
                                "Bahagyang iniabot ng nakikinig ang kamay, gumaan ang loob sa alaala.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "A soft breath escapes the listener as they remember.",
                            },
                            ["TL"] = {
                                "Isang marahang buntong-hininga ang pinakawalan ng nakikinig habang nagugunita.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "The listener's shoulders relax with affectionate recognition.",
                            },
                            ["TL"] = {
                                "Lumuwag ang balikat ng nakikinig kalakip ang magiliw na pagkilala.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "The listener nods warmly, visibly moved by the memory.",
                            },
                            ["TL"] = {
                                "Mainit na tumango ang nakikinig, halatang naantig sa alaala.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "A quiet sense of camaraderie passes between them.",
                            },
                            ["TL"] = {
                                "Isang tahimik na damdamin ng pagkakaibigan ang namagitan sa kanila.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_memory.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_memory",
        ["id"] = "semantic.interaction.memory.followup.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.interaction.memory.followup.guarded",
            ["sourcePath"] = "psdl/dialogue/social_interaction_memory.json#records[11]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionMemory",
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
                ["responseTemplateID"] = "semantic.interaction.memory.followup",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/memory/followup.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Why are you telling me that?",
                            },
                            ["TL"] = {
                                "Bakit mo sinasabi sa akin iyan?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "What's the point of bringing that up now?",
                            },
                            ["TL"] = {
                                "Anong layunin sa pagbubukas niyan ngayon?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Are you testing my reaction?",
                            },
                            ["TL"] = {
                                "Sinusubukan mo ba ang magiging reaksyon ko?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Who else knows about that story?",
                            },
                            ["TL"] = {
                                "Sino pa ang nakakaalam ng kuwentong 'yan?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Why share something so personal with me?",
                            },
                            ["TL"] = {
                                "Bakit mo ibinabahagi ang ganyang personal na bagay sa akin?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Sounds like an angle. What do you really want?",
                            },
                            ["TL"] = {
                                "Mukhang may pakay ka. Ano ba talaga ang gusto mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Does that story have anything to do with our safety here?",
                            },
                            ["TL"] = {
                                "May kinalaman ba ang kuwentong 'yan sa kaligtasan natin dito?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Be careful what details you hand out to people.",
                            },
                            ["TL"] = {
                                "Mag-ingat ka sa mga detalyeng ipinamamahagi mo sa iba.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Are you trying to gauge where my loyalties lie?",
                            },
                            ["TL"] = {
                                "Sinusubukan mo bang alamin kung kanino ako tapat?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Keep your personal history to yourself.",
                            },
                            ["TL"] = {
                                "Itago mo na lang sa sarili mo ang sarili mong nakaraan.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_memory.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_memory",
        ["id"] = "semantic.interaction.memory.followup.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.interaction.memory.followup.neutral",
            ["sourcePath"] = "psdl/dialogue/social_interaction_memory.json#records[8]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionMemory",
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
                ["responseTemplateID"] = "semantic.interaction.memory.followup",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/memory/followup.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "You did? What happened after that?",
                            },
                            ["TL"] = {
                                "Talaga? Ano ang nangyari pagkatapos noon?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "How did you manage to get through it?",
                            },
                            ["TL"] = {
                                "Paano mo nagawang malusutan iyon?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Did anyone else make it out with you?",
                            },
                            ["TL"] = {
                                "May iba pa bang nakaligtas kasama mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Where did you go once that went down?",
                            },
                            ["TL"] = {
                                "Saan ka pumunta nang mangyari iyon?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "What made you think of that just now?",
                            },
                            ["TL"] = {
                                "Bakit mo biglang naisip iyon ngayon?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "How long ago was that?",
                            },
                            ["TL"] = {
                                "Gaano na katagal mula noon?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Were there many casualties back then?",
                            },
                            ["TL"] = {
                                "Marami bang nasawi noong panahong iyon?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "What did you end up doing about it?",
                            },
                            ["TL"] = {
                                "Ano ang naging aksyon mo tungkol doon?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "That sounds intense. What came next?",
                            },
                            ["TL"] = {
                                "Matindi 'yon. Ano ang sumunod?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Did you ever go back to that place?",
                            },
                            ["TL"] = {
                                "Bumalik ka pa ba sa lugar na iyon kailanman?",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_memory.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_memory",
        ["id"] = "semantic.interaction.memory.followup.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.interaction.memory.followup.terse",
            ["sourcePath"] = "psdl/dialogue/social_interaction_memory.json#records[10]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionMemory",
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
                ["responseTemplateID"] = "semantic.interaction.memory.followup",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/memory/followup.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "And then?",
                            },
                            ["TL"] = {
                                "Tapos?",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "What happened?",
                            },
                            ["TL"] = {
                                "Anong nangyari?",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "After that?",
                            },
                            ["TL"] = {
                                "Pagkatapos?",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "How so?",
                            },
                            ["TL"] = {
                                "Paano?",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Who survived?",
                            },
                            ["TL"] = {
                                "Sinong nakaligtas?",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "When?",
                            },
                            ["TL"] = {
                                "Kailan?",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Outcome?",
                            },
                            ["TL"] = {
                                "Kinahinatnan?",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Next?",
                            },
                            ["TL"] = {
                                "Kasunod?",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Details?",
                            },
                            ["TL"] = {
                                "Mga detalye?",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "End result?",
                            },
                            ["TL"] = {
                                "Huling resulta?",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_memory.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_memory",
        ["id"] = "semantic.interaction.memory.followup.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.interaction.memory.followup.warm",
            ["sourcePath"] = "psdl/dialogue/social_interaction_memory.json#records[9]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionMemory",
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
                ["responseTemplateID"] = "semantic.interaction.memory.followup",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/memory/followup.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "Really? Tell me more about that.",
                            },
                            ["TL"] = {
                                "Talaga? Kuwento mo pa sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "That sounds like quite a memory. How did it feel?",
                            },
                            ["TL"] = {
                                "Mukhang napakagandang alaala. Anong naramdaman mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'd love to hear the rest of that story if you want to share.",
                            },
                            ["TL"] = {
                                "Gusto kong marinig ang karugtong ng kuwento kung nais mong ibahagi.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "It must have taken real courage. How did you hold up?",
                            },
                            ["TL"] = {
                                "Kailangan ng tunay na tapang doon. Paano mo kinaya?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "You went through so much. I'm glad you're here to talk about it.",
                            },
                            ["TL"] = {
                                "Napakalaki ng pinagdaanan mo. Mabuti at narito ka para ikuwento.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Were you able to save anything from back then?",
                            },
                            ["TL"] = {
                                "May naisalba ka ba mula noong panahong iyon?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "I'm listening, friend. Take all the time you need.",
                            },
                            ["TL"] = {
                                "Nakikinig ako, kaibigan. Huwag kang magmadali.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "That sounds like someone who mattered deeply to you.",
                            },
                            ["TL"] = {
                                "Mukhang may taong napakahalaga sa 'yo sa kuwentong 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "What a journey. What kept you holding on?",
                            },
                            ["TL"] = {
                                "Napakalaking paglalakbay. Ano ang nagpatatag sa 'yo?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Thank you for trusting me with that memory. What happened next?",
                            },
                            ["TL"] = {
                                "Salamat sa pagtitiwala sa akin ng alaalang 'yan. Ano sumunod?",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_memory.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
