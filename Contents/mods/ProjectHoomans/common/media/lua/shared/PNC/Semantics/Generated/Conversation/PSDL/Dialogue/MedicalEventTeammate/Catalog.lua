-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "medical_event_teammate",
        ["id"] = "semantic.medical.distress.teammate.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.teammate.default",
            ["sourcePath"] = "psdl/dialogue/medical_event_teammate.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/MedicalEventTeammate/Catalog",
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
                ["category"] = "projecthoomans:medical_event",
                ["responseTemplateID"] = "semantic.medical.distress.teammate.default",
                ["sourceSurface"] = "content/event/medical/teammate.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.default.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "They are hurt! Stay with them while I cover you.",
                            },
                            ["TL"] = {
                                "Nasaktan sila! Samahan mo sila habang binabantayan ko kayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.default.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Our companion is down! Tend to them, I've got guard.",
                            },
                            ["TL"] = {
                                "Bagsak ang kasama natin! Gamutin mo, babantayan ko kayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.default.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "They're injured! Get them patched up while I watch.",
                            },
                            ["TL"] = {
                                "Sugatan sila! Bendahan mo habang nagmamasid ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.default.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Check on them right now! I'll hold off the threats.",
                            },
                            ["TL"] = {
                                "Tignan mo sila ngayon din! Haharangin ko ang mga kalaban.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.default.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "They took a hit! See to their wounds, I'm watching.",
                            },
                            ["TL"] = {
                                "Tinamaan sila! Tingnan mo ang sugat nila, nakabantay ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.default.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Partner is wounded! Apply first aid, I've got your back.",
                            },
                            ["TL"] = {
                                "Sugatan ang kasama! Maglapat ng first aid, hawak ko likod niyo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.default.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "They're bleeding! Patch them while I keep perimeter.",
                            },
                            ["TL"] = {
                                "Dumurugo sila! Gamutin mo habang binabantayan ko ang paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.default.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Help them up! I'll keep the lane clear.",
                            },
                            ["TL"] = {
                                "Tulungan mo silang tumayo! Lilinisin ko ang daanan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.default.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "They need attention! Administer aid, I'll protect you both.",
                            },
                            ["TL"] = {
                                "Kailangan nila ng lunas! Gamutin mo, poprotektahan ko kayong dalawa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.default.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Our friend is hurt! Help them, I'm standing sentry.",
                            },
                            ["TL"] = {
                                "Nasaktan ang kaibigan natin! Tulungan mo sila, nakabantay ako.",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_teammate.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_teammate",
        ["id"] = "semantic.medical.distress.teammate.found",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.teammate.found",
            ["sourcePath"] = "psdl/dialogue/medical_event_teammate.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/MedicalEventTeammate/Catalog",
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
                ["category"] = "projecthoomans:medical_event",
                ["responseTemplateID"] = "semantic.medical.distress.teammate.found",
                ["sourceSurface"] = "content/event/medical/teammate.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.found.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I found a bandage for them. Hold still while I patch them up.",
                            },
                            ["TL"] = {
                                "Nakahanap ako ng benda para sa kanila. Huwag kang gagalaw habang ginagamot ko sila.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.found.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Got a dressing right here. Wrapping the wound now.",
                            },
                            ["TL"] = {
                                "May pambenda ako rito. Binabalot ko na ang sugat ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.found.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Found medical supplies! Hold on, I'm dressing the injury.",
                            },
                            ["TL"] = {
                                "Nakahanap ako ng gamot! Kapit lang, ginagamot ko na ang pinsala.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.found.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I've got clean cloth. Hold steady while I bind it.",
                            },
                            ["TL"] = {
                                "May malinis akong tela. Manatiling nakapirmi habang itinatali ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.found.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Located a bandage. Applying pressure to their cut now.",
                            },
                            ["TL"] = {
                                "May nahanap na benda. Dinidiinan ko na ang hiwa nila.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.found.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I've got medical wrap. Don't squirm, I'm securing it.",
                            },
                            ["TL"] = {
                                "May medical wrap ako. Huwag kang pumalag, inaayos ko na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.found.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Found supplies for them. Wrapping it up tightly now.",
                            },
                            ["TL"] = {
                                "May nahanap na gamit para sa kanila. Binabalot ko na nang mahigpit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.found.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Got the bandage ready. Applying it to the laceration.",
                            },
                            ["TL"] = {
                                "Handa na ang benda. Nilalapat ko na sa sugat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.found.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I have aid gear. Hold still, you'll be stable in a minute.",
                            },
                            ["TL"] = {
                                "May gamit ako rito. Huwag gagalaw, magiging maayos ka rin agad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.found.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Bandage in hand! Dressing their wounds right now.",
                            },
                            ["TL"] = {
                                "Hawak ko na ang benda! Ginagamot ko na ang mga sugat nila.",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_teammate.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_teammate",
        ["id"] = "semantic.medical.distress.teammate.missing",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.teammate.missing",
            ["sourcePath"] = "psdl/dialogue/medical_event_teammate.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/MedicalEventTeammate/Catalog",
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
                ["category"] = "projecthoomans:medical_event",
                ["responseTemplateID"] = "semantic.medical.distress.teammate.missing",
                ["sourceSurface"] = "content/event/medical/teammate.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.missing.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I am out of bandages! Can someone spare one for them?",
                            },
                            ["TL"] = {
                                "Naubusan ako ng benda! May makakapagbahagi ba ng isa para sa kanila?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.missing.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "No more medical cloth! Does anyone have a bandage?!",
                            },
                            ["TL"] = {
                                "Wala nang telang panggamot! May benda ba ang kahit sino sa inyo?!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.missing.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "My pack is empty of dressings! Help them, quick!",
                            },
                            ["TL"] = {
                                "Walang laman ang bag ko para sa benda! Tulungan niyo sila, bilis!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.missing.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I can't treat this wound without supplies! Check your packs!",
                            },
                            ["TL"] = {
                                "Hindi ko magagamot ang sugat na 'to nang walang gamit! Tignan ang mga bag niyo!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.missing.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "We're out of first aid! Who has a clean rag?!",
                            },
                            ["TL"] = {
                                "Wala na tayong first aid! Sino may malinis na basahan?!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.missing.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I don't have what I need to stop their bleeding! Find supplies!",
                            },
                            ["TL"] = {
                                "Wala sa akin ang kailangan para mapatigil ang dugo nila! Maghanap ng gamit!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.missing.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Zero bandages left! Someone hand me medical gear!",
                            },
                            ["TL"] = {
                                "Ubos na ang benda! May mag-abot sa akin ng panggamot!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.missing.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm empty-handed! We need bandages for our friend now!",
                            },
                            ["TL"] = {
                                "Wala akong hawak! Kailangan natin ng benda para sa kaibigan natin ngayon din!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.missing.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "No antiseptic, no bandages. Search the drawers, fast!",
                            },
                            ["TL"] = {
                                "Walang antiseptic, walang benda. Maghalughog sa mga drawer, bilis!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.teammate.missing.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I can't patch them up alone! Who has medical tools?!",
                            },
                            ["TL"] = {
                                "Hindi ko sila kayang gamutin mag-isa! Sino may kagamitang medikal?!",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_teammate.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
