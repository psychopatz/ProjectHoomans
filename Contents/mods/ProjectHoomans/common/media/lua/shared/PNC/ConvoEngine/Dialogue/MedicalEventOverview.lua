-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "medical_event_overview",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.default",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "I need help with this wound.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.medical.distress.default.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I need help with this wound.",
                                        "Hurting pretty badly here. Need aid.",
                                        "Got injured. Can someone look at this?",
                                        "Need medical attention before this gets worse.",
                                        "Wound is throbbing. I need a hand.",
                                        "Took some damage. Could use first aid.",
                                        "This cut is nasty. Help me clean it.",
                                        "I'm in pain here. Need medical supplies.",
                                        "Injured and slowing down. Need treatment.",
                                        "Got banged up pretty good. Help me patch up.",
                                    },
                                    ["TL"] = {
                                        "Kailangan ko ng tulong sa sugat na 'to.",
                                        "Medyo malala ang tama ko rito. Kailangan ng gamot.",
                                        "Nasugatan ako. May makakatingin ba nito?",
                                        "Kailangan ng panggagamot bago lumala 'to.",
                                        "Pumipintig ang sugat. Kailangan ko ng saklolo.",
                                        "Nasaktan ako. Kailangan ko ng first aid.",
                                        "Marumi ang hiwa na 'to. Tulungan mo akong linisin.",
                                        "Nasasaktan ako rito. Kailangan ko ng gamot.",
                                        "Sugatan at bumabagal na. Kailangan ng lunas.",
                                        "Nabugbog ako nang husto. Tulungan mo akong magbenda.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.distress",
            ["textRoles"] = {
                {
                    ["fallback"] = "I need help with this wound.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.default.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I need help with this wound.",
                            "Hurting pretty badly here. Need aid.",
                            "Got injured. Can someone look at this?",
                            "Need medical attention before this gets worse.",
                            "Wound is throbbing. I need a hand.",
                            "Took some damage. Could use first aid.",
                            "This cut is nasty. Help me clean it.",
                            "I'm in pain here. Need medical supplies.",
                            "Injured and slowing down. Need treatment.",
                            "Got banged up pretty good. Help me patch up.",
                        },
                        ["TL"] = {
                            "Kailangan ko ng tulong sa sugat na 'to.",
                            "Medyo malala ang tama ko rito. Kailangan ng gamot.",
                            "Nasugatan ako. May makakatingin ba nito?",
                            "Kailangan ng panggagamot bago lumala 'to.",
                            "Pumipintig ang sugat. Kailangan ko ng saklolo.",
                            "Nasaktan ako. Kailangan ko ng first aid.",
                            "Marumi ang hiwa na 'to. Tulungan mo akong linisin.",
                            "Nasasaktan ako rito. Kailangan ko ng gamot.",
                            "Sugatan at bumabagal na. Kailangan ng lunas.",
                            "Nabugbog ako nang husto. Tulungan mo akong magbenda.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "medical.distress.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "default",
            ["sourceId"] = "medical.distress.default",
            ["sourcePath"] = "adopters/hoomans/dialogue/medical_event_overview/medical_distress_default.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalEventOverview",
        ["namespace"] = "medical.distress",
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
                ["responseAct"] = "MEDICAL_RESPONSE",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "I need help with this wound.",
                                        "Hurting pretty badly here. Need aid.",
                                        "Got injured. Can someone look at this?",
                                        "Need medical attention before this gets worse.",
                                        "Wound is throbbing. I need a hand.",
                                        "Took some damage. Could use first aid.",
                                        "This cut is nasty. Help me clean it.",
                                        "I'm in pain here. Need medical supplies.",
                                        "Injured and slowing down. Need treatment.",
                                        "Got banged up pretty good. Help me patch up.",
                                    },
                                    ["TL"] = {
                                        "Kailangan ko ng tulong sa sugat na 'to.",
                                        "Medyo malala ang tama ko rito. Kailangan ng gamot.",
                                        "Nasugatan ako. May makakatingin ba nito?",
                                        "Kailangan ng panggagamot bago lumala 'to.",
                                        "Pumipintig ang sugat. Kailangan ko ng saklolo.",
                                        "Nasaktan ako. Kailangan ko ng first aid.",
                                        "Marumi ang hiwa na 'to. Tulungan mo akong linisin.",
                                        "Nasasaktan ako rito. Kailangan ko ng gamot.",
                                        "Sugatan at bumabagal na. Kailangan ng lunas.",
                                        "Nabugbog ako nang husto. Tulungan mo akong magbenda.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "MEDICAL_RESPONSE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "medical.distress.default",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I need help with this wound.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.medical.distress.default.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/medical_event_overview/medical_distress_default.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I need help with this wound.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.default.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I need help with this wound.",
                        "Hurting pretty badly here. Need aid.",
                        "Got injured. Can someone look at this?",
                        "Need medical attention before this gets worse.",
                        "Wound is throbbing. I need a hand.",
                        "Took some damage. Could use first aid.",
                        "This cut is nasty. Help me clean it.",
                        "I'm in pain here. Need medical supplies.",
                        "Injured and slowing down. Need treatment.",
                        "Got banged up pretty good. Help me patch up.",
                    },
                    ["TL"] = {
                        "Kailangan ko ng tulong sa sugat na 'to.",
                        "Medyo malala ang tama ko rito. Kailangan ng gamot.",
                        "Nasugatan ako. May makakatingin ba nito?",
                        "Kailangan ng panggagamot bago lumala 'to.",
                        "Pumipintig ang sugat. Kailangan ko ng saklolo.",
                        "Nasaktan ako. Kailangan ko ng first aid.",
                        "Marumi ang hiwa na 'to. Tulungan mo akong linisin.",
                        "Nasasaktan ako rito. Kailangan ko ng gamot.",
                        "Sugatan at bumabagal na. Kailangan ng lunas.",
                        "Nabugbog ako nang husto. Tulungan mo akong magbenda.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_overview",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.mercy",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "Please. I need help with this wound, don't let me die.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.medical.distress.mercy.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Please. I need help with this wound, don't let me die.",
                                        "Have mercy on me... patch me up, please.",
                                        "I won't survive this cut without your mercy.",
                                        "Please help... I'm begging for aid.",
                                        "Don't leave me to bleed out like an animal.",
                                        "Show some kindness. This wound is killing me.",
                                        "Please, just dress the wound. That's all I ask.",
                                        "I'm at your mercy. Help stop this pain.",
                                        "Spare my life and treat this injury, please.",
                                        "I have so much to live for... please help me.",
                                    },
                                    ["TL"] = {
                                        "Pakiusap. Tulungan mo ako sa sugat na 'to, huwag mo akong hayaang mamatay.",
                                        "Maawa ka sa akin... bendahan mo ako, pakiusap.",
                                        "Hindi ako mabubuhay sa hiwang 'to kung wala ang awa mo.",
                                        "Pakiusap tulungan mo ako... nagmamakaawa ako sa lunas.",
                                        "Huwag mo akong iwang maubusan ng dugo na parang hayop.",
                                        "Magpakita ka ng kabutihan. Pinapatay ako ng sugat na 'to.",
                                        "Pakiusap, gamutin lang ang sugat. 'Yon lang ang hinihiling ko.",
                                        "Nasa awa mo ako. Tulungan mong matigil ang sakit.",
                                        "Iligtas mo ang buhay ko at gamutin 'tong pinsala, pakiusap.",
                                        "Marami pa akong dahilan para mabuhay... tulungan mo ako.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.distress",
            ["textRoles"] = {
                {
                    ["fallback"] = "Please. I need help with this wound, don't let me die.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.mercy.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Please. I need help with this wound, don't let me die.",
                            "Have mercy on me... patch me up, please.",
                            "I won't survive this cut without your mercy.",
                            "Please help... I'm begging for aid.",
                            "Don't leave me to bleed out like an animal.",
                            "Show some kindness. This wound is killing me.",
                            "Please, just dress the wound. That's all I ask.",
                            "I'm at your mercy. Help stop this pain.",
                            "Spare my life and treat this injury, please.",
                            "I have so much to live for... please help me.",
                        },
                        ["TL"] = {
                            "Pakiusap. Tulungan mo ako sa sugat na 'to, huwag mo akong hayaang mamatay.",
                            "Maawa ka sa akin... bendahan mo ako, pakiusap.",
                            "Hindi ako mabubuhay sa hiwang 'to kung wala ang awa mo.",
                            "Pakiusap tulungan mo ako... nagmamakaawa ako sa lunas.",
                            "Huwag mo akong iwang maubusan ng dugo na parang hayop.",
                            "Magpakita ka ng kabutihan. Pinapatay ako ng sugat na 'to.",
                            "Pakiusap, gamutin lang ang sugat. 'Yon lang ang hinihiling ko.",
                            "Nasa awa mo ako. Tulungan mong matigil ang sakit.",
                            "Iligtas mo ang buhay ko at gamutin 'tong pinsala, pakiusap.",
                            "Marami pa akong dahilan para mabuhay... tulungan mo ako.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "medical.distress.mercy",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "mercy",
            ["sourceId"] = "medical.distress.mercy",
            ["sourcePath"] = "adopters/hoomans/dialogue/medical_event_overview/medical_distress_mercy.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalEventOverview",
        ["namespace"] = "medical.distress",
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
                ["responseAct"] = "MEDICAL_RESPONSE",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Please. I need help with this wound, don't let me die.",
                                        "Have mercy on me... patch me up, please.",
                                        "I won't survive this cut without your mercy.",
                                        "Please help... I'm begging for aid.",
                                        "Don't leave me to bleed out like an animal.",
                                        "Show some kindness. This wound is killing me.",
                                        "Please, just dress the wound. That's all I ask.",
                                        "I'm at your mercy. Help stop this pain.",
                                        "Spare my life and treat this injury, please.",
                                        "I have so much to live for... please help me.",
                                    },
                                    ["TL"] = {
                                        "Pakiusap. Tulungan mo ako sa sugat na 'to, huwag mo akong hayaang mamatay.",
                                        "Maawa ka sa akin... bendahan mo ako, pakiusap.",
                                        "Hindi ako mabubuhay sa hiwang 'to kung wala ang awa mo.",
                                        "Pakiusap tulungan mo ako... nagmamakaawa ako sa lunas.",
                                        "Huwag mo akong iwang maubusan ng dugo na parang hayop.",
                                        "Magpakita ka ng kabutihan. Pinapatay ako ng sugat na 'to.",
                                        "Pakiusap, gamutin lang ang sugat. 'Yon lang ang hinihiling ko.",
                                        "Nasa awa mo ako. Tulungan mong matigil ang sakit.",
                                        "Iligtas mo ang buhay ko at gamutin 'tong pinsala, pakiusap.",
                                        "Marami pa akong dahilan para mabuhay... tulungan mo ako.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "MEDICAL_RESPONSE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "medical.distress.mercy",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Please. I need help with this wound, don't let me die.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.medical.distress.mercy.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/medical_event_overview/medical_distress_mercy.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Please. I need help with this wound, don't let me die.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.mercy.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Please. I need help with this wound, don't let me die.",
                        "Have mercy on me... patch me up, please.",
                        "I won't survive this cut without your mercy.",
                        "Please help... I'm begging for aid.",
                        "Don't leave me to bleed out like an animal.",
                        "Show some kindness. This wound is killing me.",
                        "Please, just dress the wound. That's all I ask.",
                        "I'm at your mercy. Help stop this pain.",
                        "Spare my life and treat this injury, please.",
                        "I have so much to live for... please help me.",
                    },
                    ["TL"] = {
                        "Pakiusap. Tulungan mo ako sa sugat na 'to, huwag mo akong hayaang mamatay.",
                        "Maawa ka sa akin... bendahan mo ako, pakiusap.",
                        "Hindi ako mabubuhay sa hiwang 'to kung wala ang awa mo.",
                        "Pakiusap tulungan mo ako... nagmamakaawa ako sa lunas.",
                        "Huwag mo akong iwang maubusan ng dugo na parang hayop.",
                        "Magpakita ka ng kabutihan. Pinapatay ako ng sugat na 'to.",
                        "Pakiusap, gamutin lang ang sugat. 'Yon lang ang hinihiling ko.",
                        "Nasa awa mo ako. Tulungan mong matigil ang sakit.",
                        "Iligtas mo ang buhay ko at gamutin 'tong pinsala, pakiusap.",
                        "Marami pa akong dahilan para mabuhay... tulungan mo ako.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_overview",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.urgent",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "I am hurt! I need help now!",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.medical.distress.urgent.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I am hurt! I need help now!",
                                        "Emergency! I need immediate medical attention!",
                                        "Hit bad! Come over here right now!",
                                        "Urgent! I'm bleeding and falling down!",
                                        "I need aid this second! Hurry!",
                                        "Severe injury! Drop what you're doing and help me!",
                                        "I won't last long without treatment! Now!",
                                        "Critical wound! Bandage me now!",
                                        "I'm going down hard! Medic, help me!",
                                        "Urgent distress! Someone patch me up right now!",
                                    },
                                    ["TL"] = {
                                        "Sugatan ako! Kailangan ko ng tulong ngayon na!",
                                        "Kagipitan! Kailangan ko ng agarang gamot ngayon din!",
                                        "Grabe ang tama ko! Halika rito ngayon din!",
                                        "Apurahan! Dumurugo ako at bumabagsak!",
                                        "Kailangan ko ng gamot sa segundong ito! Bilis!",
                                        "Malubhang pinsala! Bitawan ang ginagawa mo at tulungan mo ako!",
                                        "Hindi ako magtatagal nang walang gamot! Ngayon na!",
                                        "Kritikal na sugat! Bendahan mo ako ngayon din!",
                                        "Bumabagsak na ako! Saklolo, tulungan mo ako!",
                                        "Apurahang saklolo! May magbenda sa akin ngayon din!",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.distress",
            ["textRoles"] = {
                {
                    ["fallback"] = "I am hurt! I need help now!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.urgent.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I am hurt! I need help now!",
                            "Emergency! I need immediate medical attention!",
                            "Hit bad! Come over here right now!",
                            "Urgent! I'm bleeding and falling down!",
                            "I need aid this second! Hurry!",
                            "Severe injury! Drop what you're doing and help me!",
                            "I won't last long without treatment! Now!",
                            "Critical wound! Bandage me now!",
                            "I'm going down hard! Medic, help me!",
                            "Urgent distress! Someone patch me up right now!",
                        },
                        ["TL"] = {
                            "Sugatan ako! Kailangan ko ng tulong ngayon na!",
                            "Kagipitan! Kailangan ko ng agarang gamot ngayon din!",
                            "Grabe ang tama ko! Halika rito ngayon din!",
                            "Apurahan! Dumurugo ako at bumabagsak!",
                            "Kailangan ko ng gamot sa segundong ito! Bilis!",
                            "Malubhang pinsala! Bitawan ang ginagawa mo at tulungan mo ako!",
                            "Hindi ako magtatagal nang walang gamot! Ngayon na!",
                            "Kritikal na sugat! Bendahan mo ako ngayon din!",
                            "Bumabagsak na ako! Saklolo, tulungan mo ako!",
                            "Apurahang saklolo! May magbenda sa akin ngayon din!",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "medical.distress.urgent",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "urgent",
            ["sourceId"] = "medical.distress.urgent",
            ["sourcePath"] = "adopters/hoomans/dialogue/medical_event_overview/medical_distress_urgent.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalEventOverview",
        ["namespace"] = "medical.distress",
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
                ["responseAct"] = "MEDICAL_RESPONSE",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "I am hurt! I need help now!",
                                        "Emergency! I need immediate medical attention!",
                                        "Hit bad! Come over here right now!",
                                        "Urgent! I'm bleeding and falling down!",
                                        "I need aid this second! Hurry!",
                                        "Severe injury! Drop what you're doing and help me!",
                                        "I won't last long without treatment! Now!",
                                        "Critical wound! Bandage me now!",
                                        "I'm going down hard! Medic, help me!",
                                        "Urgent distress! Someone patch me up right now!",
                                    },
                                    ["TL"] = {
                                        "Sugatan ako! Kailangan ko ng tulong ngayon na!",
                                        "Kagipitan! Kailangan ko ng agarang gamot ngayon din!",
                                        "Grabe ang tama ko! Halika rito ngayon din!",
                                        "Apurahan! Dumurugo ako at bumabagsak!",
                                        "Kailangan ko ng gamot sa segundong ito! Bilis!",
                                        "Malubhang pinsala! Bitawan ang ginagawa mo at tulungan mo ako!",
                                        "Hindi ako magtatagal nang walang gamot! Ngayon na!",
                                        "Kritikal na sugat! Bendahan mo ako ngayon din!",
                                        "Bumabagsak na ako! Saklolo, tulungan mo ako!",
                                        "Apurahang saklolo! May magbenda sa akin ngayon din!",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "MEDICAL_RESPONSE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "medical.distress.urgent",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I am hurt! I need help now!",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.medical.distress.urgent.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/medical_event_overview/medical_distress_urgent.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I am hurt! I need help now!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.urgent.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I am hurt! I need help now!",
                        "Emergency! I need immediate medical attention!",
                        "Hit bad! Come over here right now!",
                        "Urgent! I'm bleeding and falling down!",
                        "I need aid this second! Hurry!",
                        "Severe injury! Drop what you're doing and help me!",
                        "I won't last long without treatment! Now!",
                        "Critical wound! Bandage me now!",
                        "I'm going down hard! Medic, help me!",
                        "Urgent distress! Someone patch me up right now!",
                    },
                    ["TL"] = {
                        "Sugatan ako! Kailangan ko ng tulong ngayon na!",
                        "Kagipitan! Kailangan ko ng agarang gamot ngayon din!",
                        "Grabe ang tama ko! Halika rito ngayon din!",
                        "Apurahan! Dumurugo ako at bumabagsak!",
                        "Kailangan ko ng gamot sa segundong ito! Bilis!",
                        "Malubhang pinsala! Bitawan ang ginagawa mo at tulungan mo ako!",
                        "Hindi ako magtatagal nang walang gamot! Ngayon na!",
                        "Kritikal na sugat! Bendahan mo ako ngayon din!",
                        "Bumabagsak na ako! Saklolo, tulungan mo ako!",
                        "Apurahang saklolo! May magbenda sa akin ngayon din!",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
