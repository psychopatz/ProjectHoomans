-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "medical_event_overview",
        ["id"] = "semantic.medical.distress.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.default",
            ["sourcePath"] = "psdl/dialogue/medical_event_overview.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/MedicalEventOverview/Catalog",
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
                ["responseTemplateID"] = "semantic.medical.distress.default",
                ["sourceSurface"] = "content/event/medical/overview.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.default.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I need help with this wound.",
                            },
                            ["TL"] = {
                                "Kailangan ko ng tulong sa sugat na 'to.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.default.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Hurting pretty badly here. Need aid.",
                            },
                            ["TL"] = {
                                "Medyo malala ang tama ko rito. Kailangan ng gamot.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.default.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Got injured. Can someone look at this?",
                            },
                            ["TL"] = {
                                "Nasugatan ako. May makakatingin ba nito?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.default.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Need medical attention before this gets worse.",
                            },
                            ["TL"] = {
                                "Kailangan ng panggagamot bago lumala 'to.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.default.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Wound is throbbing. I need a hand.",
                            },
                            ["TL"] = {
                                "Pumipintig ang sugat. Kailangan ko ng saklolo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.default.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Took some damage. Could use first aid.",
                            },
                            ["TL"] = {
                                "Nasaktan ako. Kailangan ko ng first aid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.default.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "This cut is nasty. Help me clean it.",
                            },
                            ["TL"] = {
                                "Marumi ang hiwa na 'to. Tulungan mo akong linisin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.default.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm in pain here. Need medical supplies.",
                            },
                            ["TL"] = {
                                "Nasasaktan ako rito. Kailangan ko ng gamot.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.default.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Injured and slowing down. Need treatment.",
                            },
                            ["TL"] = {
                                "Sugatan at bumabagal na. Kailangan ng lunas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.default.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Got banged up pretty good. Help me patch up.",
                            },
                            ["TL"] = {
                                "Nabugbog ako nang husto. Tulungan mo akong magbenda.",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_overview.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_overview",
        ["id"] = "semantic.medical.distress.mercy",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.mercy",
            ["sourcePath"] = "psdl/dialogue/medical_event_overview.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/MedicalEventOverview/Catalog",
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
                ["responseTemplateID"] = "semantic.medical.distress.mercy",
                ["sourceSurface"] = "content/event/medical/overview.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.mercy.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Please. I need help with this wound, don't let me die.",
                            },
                            ["TL"] = {
                                "Pakiusap. Tulungan mo ako sa sugat na 'to, huwag mo akong hayaang mamatay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.mercy.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Have mercy on me... patch me up, please.",
                            },
                            ["TL"] = {
                                "Maawa ka sa akin... bendahan mo ako, pakiusap.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.mercy.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I won't survive this cut without your mercy.",
                            },
                            ["TL"] = {
                                "Hindi ako mabubuhay sa hiwang 'to kung wala ang awa mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.mercy.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Please help... I'm begging for aid.",
                            },
                            ["TL"] = {
                                "Pakiusap tulungan mo ako... nagmamakaawa ako sa lunas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.mercy.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't leave me to bleed out like an animal.",
                            },
                            ["TL"] = {
                                "Huwag mo akong iwang maubusan ng dugo na parang hayop.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.mercy.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Show some kindness. This wound is killing me.",
                            },
                            ["TL"] = {
                                "Magpakita ka ng kabutihan. Pinapatay ako ng sugat na 'to.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.mercy.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Please, just dress the wound. That's all I ask.",
                            },
                            ["TL"] = {
                                "Pakiusap, gamutin lang ang sugat. 'Yon lang ang hinihiling ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.mercy.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm at your mercy. Help stop this pain.",
                            },
                            ["TL"] = {
                                "Nasa awa mo ako. Tulungan mong matigil ang sakit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.mercy.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Spare my life and treat this injury, please.",
                            },
                            ["TL"] = {
                                "Iligtas mo ang buhay ko at gamutin 'tong pinsala, pakiusap.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.mercy.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I have so much to live for... please help me.",
                            },
                            ["TL"] = {
                                "Marami pa akong dahilan para mabuhay... tulungan mo ako.",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_overview.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_overview",
        ["id"] = "semantic.medical.distress.urgent",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.urgent",
            ["sourcePath"] = "psdl/dialogue/medical_event_overview.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/MedicalEventOverview/Catalog",
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
                ["responseTemplateID"] = "semantic.medical.distress.urgent",
                ["sourceSurface"] = "content/event/medical/overview.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.urgent.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I am hurt! I need help now!",
                            },
                            ["TL"] = {
                                "Sugatan ako! Kailangan ko ng tulong ngayon na!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.urgent.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Emergency! I need immediate medical attention!",
                            },
                            ["TL"] = {
                                "Kagipitan! Kailangan ko ng agarang gamot ngayon din!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.urgent.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Hit bad! Come over here right now!",
                            },
                            ["TL"] = {
                                "Grabe ang tama ko! Halika rito ngayon din!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.urgent.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Urgent! I'm bleeding and falling down!",
                            },
                            ["TL"] = {
                                "Apurahan! Dumurugo ako at bumabagsak!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.urgent.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I need aid this second! Hurry!",
                            },
                            ["TL"] = {
                                "Kailangan ko ng gamot sa segundong ito! Bilis!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.urgent.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Severe injury! Drop what you're doing and help me!",
                            },
                            ["TL"] = {
                                "Malubhang pinsala! Bitawan ang ginagawa mo at tulungan mo ako!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.urgent.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I won't last long without treatment! Now!",
                            },
                            ["TL"] = {
                                "Hindi ako magtatagal nang walang gamot! Ngayon na!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.urgent.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Critical wound! Bandage me now!",
                            },
                            ["TL"] = {
                                "Kritikal na sugat! Bendahan mo ako ngayon din!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.urgent.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm going down hard! Medic, help me!",
                            },
                            ["TL"] = {
                                "Bumabagsak na ako! Saklolo, tulungan mo ako!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.urgent.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Urgent distress! Someone patch me up right now!",
                            },
                            ["TL"] = {
                                "Apurahang saklolo! May magbenda sa akin ngayon din!",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_overview.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
