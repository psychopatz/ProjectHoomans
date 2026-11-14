-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "medical_event_call",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.call.bandage",
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
                                ["fallback"] = "I'm hurt and down! Need a bandage over here!",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.medical.distress.call.bandage.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'm hurt and down! Need a bandage over here!",
                                        "Deep cut... I need a bandage now!",
                                        "I can't stop this wound alone! Bring a bandage!",
                                        "Patch me up, please! I'm losing blood!",
                                        "I'm down! Does anyone have a clean rag or bandage?!",
                                        "Gash on my leg... need wrapping right now!",
                                        "Help! I need these wounds dressed!",
                                        "I'm on the floor, bleeding! Get a bandage over here!",
                                        "Need a patch immediately! I'm grounded!",
                                        "Bandage, quick! I can't get up without one!",
                                    },
                                    ["TL"] = {
                                        "Sugatan ako at nakahandusay! Kailangan ko ng benda rito!",
                                        "Malalim ang sugat... kailangan ko ng benda ngayon din!",
                                        "Hindi ko mapatigil ang sugat nang mag-isa! Magdala ka ng benda!",
                                        "Bendahan mo ako, pakiusap! Nauubusan ako ng dugo!",
                                        "Bagsak ako! May malinis ba kayong basahan o benda?!",
                                        "May hiwa sa binti ko... kailangang balutin ngayon din!",
                                        "Tulong! Kailangang gamutin ang mga sugat na 'to!",
                                        "Nasa sahig ako, dumurugo! Dalhan mo ako ng benda rito!",
                                        "Kailangan ng panapal agad! Hindi ako makatayo!",
                                        "Benda, bilis! Hindi ako makakabangon kung wala 'yan!",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.distress.call",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'm hurt and down! Need a bandage over here!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.call.bandage.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I'm hurt and down! Need a bandage over here!",
                            "Deep cut... I need a bandage now!",
                            "I can't stop this wound alone! Bring a bandage!",
                            "Patch me up, please! I'm losing blood!",
                            "I'm down! Does anyone have a clean rag or bandage?!",
                            "Gash on my leg... need wrapping right now!",
                            "Help! I need these wounds dressed!",
                            "I'm on the floor, bleeding! Get a bandage over here!",
                            "Need a patch immediately! I'm grounded!",
                            "Bandage, quick! I can't get up without one!",
                        },
                        ["TL"] = {
                            "Sugatan ako at nakahandusay! Kailangan ko ng benda rito!",
                            "Malalim ang sugat... kailangan ko ng benda ngayon din!",
                            "Hindi ko mapatigil ang sugat nang mag-isa! Magdala ka ng benda!",
                            "Bendahan mo ako, pakiusap! Nauubusan ako ng dugo!",
                            "Bagsak ako! May malinis ba kayong basahan o benda?!",
                            "May hiwa sa binti ko... kailangang balutin ngayon din!",
                            "Tulong! Kailangang gamutin ang mga sugat na 'to!",
                            "Nasa sahig ako, dumurugo! Dalhan mo ako ng benda rito!",
                            "Kailangan ng panapal agad! Hindi ako makatayo!",
                            "Benda, bilis! Hindi ako makakabangon kung wala 'yan!",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "medical.distress.call.bandage",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "bandage",
            ["sourceId"] = "medical.distress.call.bandage",
            ["sourcePath"] = "adopters/hoomans/dialogue/medical_event_call/medical_distress_call_bandage.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalEventCall",
        ["namespace"] = "medical.distress.call",
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
                ["sourceSurface"] = "content/event/medical/call.json",
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
                                        "I'm hurt and down! Need a bandage over here!",
                                        "Deep cut... I need a bandage now!",
                                        "I can't stop this wound alone! Bring a bandage!",
                                        "Patch me up, please! I'm losing blood!",
                                        "I'm down! Does anyone have a clean rag or bandage?!",
                                        "Gash on my leg... need wrapping right now!",
                                        "Help! I need these wounds dressed!",
                                        "I'm on the floor, bleeding! Get a bandage over here!",
                                        "Need a patch immediately! I'm grounded!",
                                        "Bandage, quick! I can't get up without one!",
                                    },
                                    ["TL"] = {
                                        "Sugatan ako at nakahandusay! Kailangan ko ng benda rito!",
                                        "Malalim ang sugat... kailangan ko ng benda ngayon din!",
                                        "Hindi ko mapatigil ang sugat nang mag-isa! Magdala ka ng benda!",
                                        "Bendahan mo ako, pakiusap! Nauubusan ako ng dugo!",
                                        "Bagsak ako! May malinis ba kayong basahan o benda?!",
                                        "May hiwa sa binti ko... kailangang balutin ngayon din!",
                                        "Tulong! Kailangang gamutin ang mga sugat na 'to!",
                                        "Nasa sahig ako, dumurugo! Dalhan mo ako ng benda rito!",
                                        "Kailangan ng panapal agad! Hindi ako makatayo!",
                                        "Benda, bilis! Hindi ako makakabangon kung wala 'yan!",
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
            ["responsePlanID"] = "medical.distress.call.bandage",
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
                            ["fallback"] = "I'm hurt and down! Need a bandage over here!",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.medical.distress.call.bandage.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/medical_event_call/medical_distress_call_bandage.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'm hurt and down! Need a bandage over here!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.call.bandage.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I'm hurt and down! Need a bandage over here!",
                        "Deep cut... I need a bandage now!",
                        "I can't stop this wound alone! Bring a bandage!",
                        "Patch me up, please! I'm losing blood!",
                        "I'm down! Does anyone have a clean rag or bandage?!",
                        "Gash on my leg... need wrapping right now!",
                        "Help! I need these wounds dressed!",
                        "I'm on the floor, bleeding! Get a bandage over here!",
                        "Need a patch immediately! I'm grounded!",
                        "Bandage, quick! I can't get up without one!",
                    },
                    ["TL"] = {
                        "Sugatan ako at nakahandusay! Kailangan ko ng benda rito!",
                        "Malalim ang sugat... kailangan ko ng benda ngayon din!",
                        "Hindi ko mapatigil ang sugat nang mag-isa! Magdala ka ng benda!",
                        "Bendahan mo ako, pakiusap! Nauubusan ako ng dugo!",
                        "Bagsak ako! May malinis ba kayong basahan o benda?!",
                        "May hiwa sa binti ko... kailangang balutin ngayon din!",
                        "Tulong! Kailangang gamutin ang mga sugat na 'to!",
                        "Nasa sahig ako, dumurugo! Dalhan mo ako ng benda rito!",
                        "Kailangan ng panapal agad! Hindi ako makatayo!",
                        "Benda, bilis! Hindi ako makakabangon kung wala 'yan!",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_call",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.call.bleedout",
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
                                ["fallback"] = "I'm bleeding out! I need a tourniquet or bandage now!",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.medical.distress.call.bleedout.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'm bleeding out! I need a tourniquet or bandage now!",
                                        "Dying here! The blood won't stop flowing!",
                                        "I'm losing too much blood... getting cold!",
                                        "Hit an artery! Put pressure on this right now!",
                                        "Everything's going dark... stop the bleeding, please!",
                                        "I'm bleeding through my clothes! Help me!",
                                        "Blood everywhere... please, I don't want to die here!",
                                        "Losing consciousness... plug this wound!",
                                        "Hurry! I'm bleeding out on the dirt!",
                                        "Can't feel my fingers... stop the blood!",
                                    },
                                    ["TL"] = {
                                        "Nauubusan ako ng dugo! Kailangan ko ng benda ngayon din!",
                                        "Nalalagutan ako ng hininga! Ayaw tumigil ng agos ng dugo!",
                                        "Masyadong maraming dugo ang nawawala... nilalamig na ako!",
                                        "Tinamaan ang ugat! Diinan mo 'to ngayon din!",
                                        "Dumidilim ang paningin ko... patigilin mo ang dugo, pakiusap!",
                                        "Bumabaon ang dugo sa damit ko! Tulungan mo ako!",
                                        "Nagkalat ang dugo... pakiusap, ayaw kong mamatay rito!",
                                        "Nawawalan ako ng malay... tapalan mo ang sugat na 'to!",
                                        "Bilis! Nauubusan ako ng dugo sa lupa!",
                                        "Hindi ko na maramdaman ang daliri ko... patigilin ang dugo!",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.distress.call",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'm bleeding out! I need a tourniquet or bandage now!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.call.bleedout.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I'm bleeding out! I need a tourniquet or bandage now!",
                            "Dying here! The blood won't stop flowing!",
                            "I'm losing too much blood... getting cold!",
                            "Hit an artery! Put pressure on this right now!",
                            "Everything's going dark... stop the bleeding, please!",
                            "I'm bleeding through my clothes! Help me!",
                            "Blood everywhere... please, I don't want to die here!",
                            "Losing consciousness... plug this wound!",
                            "Hurry! I'm bleeding out on the dirt!",
                            "Can't feel my fingers... stop the blood!",
                        },
                        ["TL"] = {
                            "Nauubusan ako ng dugo! Kailangan ko ng benda ngayon din!",
                            "Nalalagutan ako ng hininga! Ayaw tumigil ng agos ng dugo!",
                            "Masyadong maraming dugo ang nawawala... nilalamig na ako!",
                            "Tinamaan ang ugat! Diinan mo 'to ngayon din!",
                            "Dumidilim ang paningin ko... patigilin mo ang dugo, pakiusap!",
                            "Bumabaon ang dugo sa damit ko! Tulungan mo ako!",
                            "Nagkalat ang dugo... pakiusap, ayaw kong mamatay rito!",
                            "Nawawalan ako ng malay... tapalan mo ang sugat na 'to!",
                            "Bilis! Nauubusan ako ng dugo sa lupa!",
                            "Hindi ko na maramdaman ang daliri ko... patigilin ang dugo!",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "medical.distress.call.bleedout",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "bleedout",
            ["sourceId"] = "medical.distress.call.bleedout",
            ["sourcePath"] = "adopters/hoomans/dialogue/medical_event_call/medical_distress_call_bleedout.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalEventCall",
        ["namespace"] = "medical.distress.call",
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
                ["sourceSurface"] = "content/event/medical/call.json",
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
                                        "I'm bleeding out! I need a tourniquet or bandage now!",
                                        "Dying here! The blood won't stop flowing!",
                                        "I'm losing too much blood... getting cold!",
                                        "Hit an artery! Put pressure on this right now!",
                                        "Everything's going dark... stop the bleeding, please!",
                                        "I'm bleeding through my clothes! Help me!",
                                        "Blood everywhere... please, I don't want to die here!",
                                        "Losing consciousness... plug this wound!",
                                        "Hurry! I'm bleeding out on the dirt!",
                                        "Can't feel my fingers... stop the blood!",
                                    },
                                    ["TL"] = {
                                        "Nauubusan ako ng dugo! Kailangan ko ng benda ngayon din!",
                                        "Nalalagutan ako ng hininga! Ayaw tumigil ng agos ng dugo!",
                                        "Masyadong maraming dugo ang nawawala... nilalamig na ako!",
                                        "Tinamaan ang ugat! Diinan mo 'to ngayon din!",
                                        "Dumidilim ang paningin ko... patigilin mo ang dugo, pakiusap!",
                                        "Bumabaon ang dugo sa damit ko! Tulungan mo ako!",
                                        "Nagkalat ang dugo... pakiusap, ayaw kong mamatay rito!",
                                        "Nawawalan ako ng malay... tapalan mo ang sugat na 'to!",
                                        "Bilis! Nauubusan ako ng dugo sa lupa!",
                                        "Hindi ko na maramdaman ang daliri ko... patigilin ang dugo!",
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
            ["responsePlanID"] = "medical.distress.call.bleedout",
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
                            ["fallback"] = "I'm bleeding out! I need a tourniquet or bandage now!",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.medical.distress.call.bleedout.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/medical_event_call/medical_distress_call_bleedout.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'm bleeding out! I need a tourniquet or bandage now!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.call.bleedout.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I'm bleeding out! I need a tourniquet or bandage now!",
                        "Dying here! The blood won't stop flowing!",
                        "I'm losing too much blood... getting cold!",
                        "Hit an artery! Put pressure on this right now!",
                        "Everything's going dark... stop the bleeding, please!",
                        "I'm bleeding through my clothes! Help me!",
                        "Blood everywhere... please, I don't want to die here!",
                        "Losing consciousness... plug this wound!",
                        "Hurry! I'm bleeding out on the dirt!",
                        "Can't feel my fingers... stop the blood!",
                    },
                    ["TL"] = {
                        "Nauubusan ako ng dugo! Kailangan ko ng benda ngayon din!",
                        "Nalalagutan ako ng hininga! Ayaw tumigil ng agos ng dugo!",
                        "Masyadong maraming dugo ang nawawala... nilalamig na ako!",
                        "Tinamaan ang ugat! Diinan mo 'to ngayon din!",
                        "Dumidilim ang paningin ko... patigilin mo ang dugo, pakiusap!",
                        "Bumabaon ang dugo sa damit ko! Tulungan mo ako!",
                        "Nagkalat ang dugo... pakiusap, ayaw kong mamatay rito!",
                        "Nawawalan ako ng malay... tapalan mo ang sugat na 'to!",
                        "Bilis! Nauubusan ako ng dugo sa lupa!",
                        "Hindi ko na maramdaman ang daliri ko... patigilin ang dugo!",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_call",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.call.default",
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
                                ["fallback"] = "I'm down! I need help over here!",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.medical.distress.call.default.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'm down! I need help over here!",
                                        "Can't stand! Someone help me up!",
                                        "I'm hit! Get over here!",
                                        "Need medical attention immediately!",
                                        "Down and helpless! Don't leave me!",
                                        "I took a bad fall! Help me!",
                                        "Can't get back on my feet! Help!",
                                        "Hurt bad! Over here, please!",
                                        "I'm down on the ground! Need a hand!",
                                        "Injured and stranded! Come help!",
                                    },
                                    ["TL"] = {
                                        "Bagsak ako! Kailangan ko ng tulong dito!",
                                        "Hindi ako makatayo! Tulungan niyo akong makatayo!",
                                        "Tinamaan ako! Halika rito!",
                                        "Kailangan ko ng agarang panggagamot!",
                                        "Bagsak at walang laban! Huwag niyo akong iwan!",
                                        "Napasama ang bagsak ko! Tulungan mo ako!",
                                        "Hindi ako makabangon! Tulong!",
                                        "Malubha ang tama ko! Dito, pakiusap!",
                                        "Nasa sahig ako! Pasaklolo naman!",
                                        "Sugatan at nastranded! Tulungan niyo ako!",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.distress.call",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'm down! I need help over here!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.call.default.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I'm down! I need help over here!",
                            "Can't stand! Someone help me up!",
                            "I'm hit! Get over here!",
                            "Need medical attention immediately!",
                            "Down and helpless! Don't leave me!",
                            "I took a bad fall! Help me!",
                            "Can't get back on my feet! Help!",
                            "Hurt bad! Over here, please!",
                            "I'm down on the ground! Need a hand!",
                            "Injured and stranded! Come help!",
                        },
                        ["TL"] = {
                            "Bagsak ako! Kailangan ko ng tulong dito!",
                            "Hindi ako makatayo! Tulungan niyo akong makatayo!",
                            "Tinamaan ako! Halika rito!",
                            "Kailangan ko ng agarang panggagamot!",
                            "Bagsak at walang laban! Huwag niyo akong iwan!",
                            "Napasama ang bagsak ko! Tulungan mo ako!",
                            "Hindi ako makabangon! Tulong!",
                            "Malubha ang tama ko! Dito, pakiusap!",
                            "Nasa sahig ako! Pasaklolo naman!",
                            "Sugatan at nastranded! Tulungan niyo ako!",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "medical.distress.call.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "default",
            ["sourceId"] = "medical.distress.call.default",
            ["sourcePath"] = "adopters/hoomans/dialogue/medical_event_call/medical_distress_call_default.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalEventCall",
        ["namespace"] = "medical.distress.call",
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
                ["sourceSurface"] = "content/event/medical/call.json",
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
                                        "I'm down! I need help over here!",
                                        "Can't stand! Someone help me up!",
                                        "I'm hit! Get over here!",
                                        "Need medical attention immediately!",
                                        "Down and helpless! Don't leave me!",
                                        "I took a bad fall! Help me!",
                                        "Can't get back on my feet! Help!",
                                        "Hurt bad! Over here, please!",
                                        "I'm down on the ground! Need a hand!",
                                        "Injured and stranded! Come help!",
                                    },
                                    ["TL"] = {
                                        "Bagsak ako! Kailangan ko ng tulong dito!",
                                        "Hindi ako makatayo! Tulungan niyo akong makatayo!",
                                        "Tinamaan ako! Halika rito!",
                                        "Kailangan ko ng agarang panggagamot!",
                                        "Bagsak at walang laban! Huwag niyo akong iwan!",
                                        "Napasama ang bagsak ko! Tulungan mo ako!",
                                        "Hindi ako makabangon! Tulong!",
                                        "Malubha ang tama ko! Dito, pakiusap!",
                                        "Nasa sahig ako! Pasaklolo naman!",
                                        "Sugatan at nastranded! Tulungan niyo ako!",
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
            ["responsePlanID"] = "medical.distress.call.default",
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
                            ["fallback"] = "I'm down! I need help over here!",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.medical.distress.call.default.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/medical_event_call/medical_distress_call_default.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'm down! I need help over here!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.call.default.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I'm down! I need help over here!",
                        "Can't stand! Someone help me up!",
                        "I'm hit! Get over here!",
                        "Need medical attention immediately!",
                        "Down and helpless! Don't leave me!",
                        "I took a bad fall! Help me!",
                        "Can't get back on my feet! Help!",
                        "Hurt bad! Over here, please!",
                        "I'm down on the ground! Need a hand!",
                        "Injured and stranded! Come help!",
                    },
                    ["TL"] = {
                        "Bagsak ako! Kailangan ko ng tulong dito!",
                        "Hindi ako makatayo! Tulungan niyo akong makatayo!",
                        "Tinamaan ako! Halika rito!",
                        "Kailangan ko ng agarang panggagamot!",
                        "Bagsak at walang laban! Huwag niyo akong iwan!",
                        "Napasama ang bagsak ko! Tulungan mo ako!",
                        "Hindi ako makabangon! Tulong!",
                        "Malubha ang tama ko! Dito, pakiusap!",
                        "Nasa sahig ako! Pasaklolo naman!",
                        "Sugatan at nastranded! Tulungan niyo ako!",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_call",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.call.dehydration",
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
                                ["fallback"] = "So thirsty... I need water before I pass out.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.medical.distress.call.dehydration.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "So thirsty... I need water before I pass out.",
                                        "Throat is completely parched... please, any water?",
                                        "Drying out... can barely swallow. Water, please.",
                                        "I'm too dehydrated to move my legs. Water...",
                                        "Give me a sip of water... dying of thirst.",
                                        "Lips are cracked and bleeding... need clean water.",
                                        "Can't walk anymore... please bring a water bottle.",
                                        "Head is pounding from dehydration... need a drink.",
                                        "I'm collapsing... just a few drops of water.",
                                        "Water... please, someone hand me water.",
                                    },
                                    ["TL"] = {
                                        "Uhaw na uhaw na ako... kailangan ko ng tubig bago ako mahimatay.",
                                        "Tuyong-tuyo na ang lalamunan ko... pakiusap, may tubig ba?",
                                        "Nanghihina sa uhaw... halos hindi makalunok. Tubig, pakiusap.",
                                        "Masyado akong dehydrated para maigalaw ang binti ko. Tubig...",
                                        "Pahingi ng kahit kaunting tubig... mamamatay na ako sa uhaw.",
                                        "Nangangapal at nagdurugo ang labi ko... kailangan ng malinis na tubig.",
                                        "Hindi na makalakad... pakiusap dalhan mo ako ng tubig.",
                                        "Pumipintig ang ulo ko sa uhaw... kailangang uminom.",
                                        "Bumabagsak na ako... kahit ilang patak lang ng tubig.",
                                        "Tubig... pakiusap, bigyan niyo ako ng tubig.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.distress.call",
            ["textRoles"] = {
                {
                    ["fallback"] = "So thirsty... I need water before I pass out.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.call.dehydration.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "So thirsty... I need water before I pass out.",
                            "Throat is completely parched... please, any water?",
                            "Drying out... can barely swallow. Water, please.",
                            "I'm too dehydrated to move my legs. Water...",
                            "Give me a sip of water... dying of thirst.",
                            "Lips are cracked and bleeding... need clean water.",
                            "Can't walk anymore... please bring a water bottle.",
                            "Head is pounding from dehydration... need a drink.",
                            "I'm collapsing... just a few drops of water.",
                            "Water... please, someone hand me water.",
                        },
                        ["TL"] = {
                            "Uhaw na uhaw na ako... kailangan ko ng tubig bago ako mahimatay.",
                            "Tuyong-tuyo na ang lalamunan ko... pakiusap, may tubig ba?",
                            "Nanghihina sa uhaw... halos hindi makalunok. Tubig, pakiusap.",
                            "Masyado akong dehydrated para maigalaw ang binti ko. Tubig...",
                            "Pahingi ng kahit kaunting tubig... mamamatay na ako sa uhaw.",
                            "Nangangapal at nagdurugo ang labi ko... kailangan ng malinis na tubig.",
                            "Hindi na makalakad... pakiusap dalhan mo ako ng tubig.",
                            "Pumipintig ang ulo ko sa uhaw... kailangang uminom.",
                            "Bumabagsak na ako... kahit ilang patak lang ng tubig.",
                            "Tubig... pakiusap, bigyan niyo ako ng tubig.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "medical.distress.call.dehydration",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "dehydration",
            ["sourceId"] = "medical.distress.call.dehydration",
            ["sourcePath"] = "adopters/hoomans/dialogue/medical_event_call/medical_distress_call_dehydration.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalEventCall",
        ["namespace"] = "medical.distress.call",
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
                ["sourceSurface"] = "content/event/medical/call.json",
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
                                        "So thirsty... I need water before I pass out.",
                                        "Throat is completely parched... please, any water?",
                                        "Drying out... can barely swallow. Water, please.",
                                        "I'm too dehydrated to move my legs. Water...",
                                        "Give me a sip of water... dying of thirst.",
                                        "Lips are cracked and bleeding... need clean water.",
                                        "Can't walk anymore... please bring a water bottle.",
                                        "Head is pounding from dehydration... need a drink.",
                                        "I'm collapsing... just a few drops of water.",
                                        "Water... please, someone hand me water.",
                                    },
                                    ["TL"] = {
                                        "Uhaw na uhaw na ako... kailangan ko ng tubig bago ako mahimatay.",
                                        "Tuyong-tuyo na ang lalamunan ko... pakiusap, may tubig ba?",
                                        "Nanghihina sa uhaw... halos hindi makalunok. Tubig, pakiusap.",
                                        "Masyado akong dehydrated para maigalaw ang binti ko. Tubig...",
                                        "Pahingi ng kahit kaunting tubig... mamamatay na ako sa uhaw.",
                                        "Nangangapal at nagdurugo ang labi ko... kailangan ng malinis na tubig.",
                                        "Hindi na makalakad... pakiusap dalhan mo ako ng tubig.",
                                        "Pumipintig ang ulo ko sa uhaw... kailangang uminom.",
                                        "Bumabagsak na ako... kahit ilang patak lang ng tubig.",
                                        "Tubig... pakiusap, bigyan niyo ako ng tubig.",
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
            ["responsePlanID"] = "medical.distress.call.dehydration",
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
                            ["fallback"] = "So thirsty... I need water before I pass out.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.medical.distress.call.dehydration.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/medical_event_call/medical_distress_call_dehydration.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "So thirsty... I need water before I pass out.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.call.dehydration.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "So thirsty... I need water before I pass out.",
                        "Throat is completely parched... please, any water?",
                        "Drying out... can barely swallow. Water, please.",
                        "I'm too dehydrated to move my legs. Water...",
                        "Give me a sip of water... dying of thirst.",
                        "Lips are cracked and bleeding... need clean water.",
                        "Can't walk anymore... please bring a water bottle.",
                        "Head is pounding from dehydration... need a drink.",
                        "I'm collapsing... just a few drops of water.",
                        "Water... please, someone hand me water.",
                    },
                    ["TL"] = {
                        "Uhaw na uhaw na ako... kailangan ko ng tubig bago ako mahimatay.",
                        "Tuyong-tuyo na ang lalamunan ko... pakiusap, may tubig ba?",
                        "Nanghihina sa uhaw... halos hindi makalunok. Tubig, pakiusap.",
                        "Masyado akong dehydrated para maigalaw ang binti ko. Tubig...",
                        "Pahingi ng kahit kaunting tubig... mamamatay na ako sa uhaw.",
                        "Nangangapal at nagdurugo ang labi ko... kailangan ng malinis na tubig.",
                        "Hindi na makalakad... pakiusap dalhan mo ako ng tubig.",
                        "Pumipintig ang ulo ko sa uhaw... kailangang uminom.",
                        "Bumabagsak na ako... kahit ilang patak lang ng tubig.",
                        "Tubig... pakiusap, bigyan niyo ako ng tubig.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_call",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.call.exhaustion",
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
                                ["fallback"] = "Pushed too far. I can't lift my arms.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.medical.distress.call.exhaustion.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Pushed too far. I can't lift my arms.",
                                        "Completely spent... give me a moment to recover.",
                                        "Legs gave out beneath me. Need to sit.",
                                        "Can't move another step. Total exhaustion.",
                                        "Breathing hurts. I need rest right now.",
                                        "Collapsed from fatigue... give me five minutes.",
                                        "Muscles are locking up. Can't stand.",
                                        "I have nothing left in the tank. Need a break.",
                                        "Vision is swimming from exhaustion. Give me time.",
                                        "Body won't respond... let me rest a second.",
                                    },
                                    ["TL"] = {
                                        "Nasobrahan ako. Hindi ko na maitaas ang mga braso ko.",
                                        "Ubos na ubos na ang lakas ko... bigyan mo ako ng saglit para makabawi.",
                                        "Bumigay ang mga binti ko. Kailangan kong umupo.",
                                        "Hindi na makakahakbang pa. Sagad na pagod na.",
                                        "Masakit huminga. Kailangan ko ng pahinga ngayon din.",
                                        "Bumagsak sa matinding pagod... bigyan mo ako ng limang minuto.",
                                        "Naninigas na ang kalamnan ko. Hindi makatayo.",
                                        "Wala nang natitirang lakas. Kailangan ng pahinga.",
                                        "Umiikot ang paningin ko sa pagod. Bigyan mo ako ng oras.",
                                        "Ayaw nang gumalaw ng katawan ko... pahingahin mo muna ako.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.distress.call",
            ["textRoles"] = {
                {
                    ["fallback"] = "Pushed too far. I can't lift my arms.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.call.exhaustion.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Pushed too far. I can't lift my arms.",
                            "Completely spent... give me a moment to recover.",
                            "Legs gave out beneath me. Need to sit.",
                            "Can't move another step. Total exhaustion.",
                            "Breathing hurts. I need rest right now.",
                            "Collapsed from fatigue... give me five minutes.",
                            "Muscles are locking up. Can't stand.",
                            "I have nothing left in the tank. Need a break.",
                            "Vision is swimming from exhaustion. Give me time.",
                            "Body won't respond... let me rest a second.",
                        },
                        ["TL"] = {
                            "Nasobrahan ako. Hindi ko na maitaas ang mga braso ko.",
                            "Ubos na ubos na ang lakas ko... bigyan mo ako ng saglit para makabawi.",
                            "Bumigay ang mga binti ko. Kailangan kong umupo.",
                            "Hindi na makakahakbang pa. Sagad na pagod na.",
                            "Masakit huminga. Kailangan ko ng pahinga ngayon din.",
                            "Bumagsak sa matinding pagod... bigyan mo ako ng limang minuto.",
                            "Naninigas na ang kalamnan ko. Hindi makatayo.",
                            "Wala nang natitirang lakas. Kailangan ng pahinga.",
                            "Umiikot ang paningin ko sa pagod. Bigyan mo ako ng oras.",
                            "Ayaw nang gumalaw ng katawan ko... pahingahin mo muna ako.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "medical.distress.call.exhaustion",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "exhaustion",
            ["sourceId"] = "medical.distress.call.exhaustion",
            ["sourcePath"] = "adopters/hoomans/dialogue/medical_event_call/medical_distress_call_exhaustion.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalEventCall",
        ["namespace"] = "medical.distress.call",
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
                ["sourceSurface"] = "content/event/medical/call.json",
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
                                        "Pushed too far. I can't lift my arms.",
                                        "Completely spent... give me a moment to recover.",
                                        "Legs gave out beneath me. Need to sit.",
                                        "Can't move another step. Total exhaustion.",
                                        "Breathing hurts. I need rest right now.",
                                        "Collapsed from fatigue... give me five minutes.",
                                        "Muscles are locking up. Can't stand.",
                                        "I have nothing left in the tank. Need a break.",
                                        "Vision is swimming from exhaustion. Give me time.",
                                        "Body won't respond... let me rest a second.",
                                    },
                                    ["TL"] = {
                                        "Nasobrahan ako. Hindi ko na maitaas ang mga braso ko.",
                                        "Ubos na ubos na ang lakas ko... bigyan mo ako ng saglit para makabawi.",
                                        "Bumigay ang mga binti ko. Kailangan kong umupo.",
                                        "Hindi na makakahakbang pa. Sagad na pagod na.",
                                        "Masakit huminga. Kailangan ko ng pahinga ngayon din.",
                                        "Bumagsak sa matinding pagod... bigyan mo ako ng limang minuto.",
                                        "Naninigas na ang kalamnan ko. Hindi makatayo.",
                                        "Wala nang natitirang lakas. Kailangan ng pahinga.",
                                        "Umiikot ang paningin ko sa pagod. Bigyan mo ako ng oras.",
                                        "Ayaw nang gumalaw ng katawan ko... pahingahin mo muna ako.",
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
            ["responsePlanID"] = "medical.distress.call.exhaustion",
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
                            ["fallback"] = "Pushed too far. I can't lift my arms.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.medical.distress.call.exhaustion.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/medical_event_call/medical_distress_call_exhaustion.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Pushed too far. I can't lift my arms.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.call.exhaustion.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Pushed too far. I can't lift my arms.",
                        "Completely spent... give me a moment to recover.",
                        "Legs gave out beneath me. Need to sit.",
                        "Can't move another step. Total exhaustion.",
                        "Breathing hurts. I need rest right now.",
                        "Collapsed from fatigue... give me five minutes.",
                        "Muscles are locking up. Can't stand.",
                        "I have nothing left in the tank. Need a break.",
                        "Vision is swimming from exhaustion. Give me time.",
                        "Body won't respond... let me rest a second.",
                    },
                    ["TL"] = {
                        "Nasobrahan ako. Hindi ko na maitaas ang mga braso ko.",
                        "Ubos na ubos na ang lakas ko... bigyan mo ako ng saglit para makabawi.",
                        "Bumigay ang mga binti ko. Kailangan kong umupo.",
                        "Hindi na makakahakbang pa. Sagad na pagod na.",
                        "Masakit huminga. Kailangan ko ng pahinga ngayon din.",
                        "Bumagsak sa matinding pagod... bigyan mo ako ng limang minuto.",
                        "Naninigas na ang kalamnan ko. Hindi makatayo.",
                        "Wala nang natitirang lakas. Kailangan ng pahinga.",
                        "Umiikot ang paningin ko sa pagod. Bigyan mo ako ng oras.",
                        "Ayaw nang gumalaw ng katawan ko... pahingahin mo muna ako.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_call",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.call.mercy",
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
                                ["fallback"] = "I'm down! Please, don't kill me!",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.medical.distress.call.mercy.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'm down! Please, don't kill me!",
                                        "Mercy, please! I'm completely unarmed!",
                                        "Don't shoot! I'm already defeated!",
                                        "Please let me live! I surrender!",
                                        "Spare me, please! I have nothing left!",
                                        "I beg you... don't finish me off!",
                                        "I yield! Don't strike again!",
                                        "Show mercy! I'm bleeding out on the floor!",
                                        "Don't hurt me anymore, please!",
                                        "Have a heart... let me survive this.",
                                    },
                                    ["TL"] = {
                                        "Bagsak na ako! Pakiusap, huwag mo akong patayin!",
                                        "Maawa ka, pakiusap! Wala akong sandata!",
                                        "Huwag kang puputok! Talo na ako!",
                                        "Pakiusap buhayin mo ako! Sumusuko na ako!",
                                        "Patawarin mo ako, pakiusap! Wala nang natira sa akin!",
                                        "Nagmamakaawa ako sa'yo... huwag mo akong tapusin!",
                                        "Suko na ako! Huwag ka nang humataw ulit!",
                                        "Maawa ka! Nauubusan na ako ng dugo sa sahig!",
                                        "Huwag mo na akong saktan pa, pakiusap!",
                                        "Maawa ka naman... hayaan mo akong mabuhay.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.distress.call",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'm down! Please, don't kill me!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.call.mercy.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I'm down! Please, don't kill me!",
                            "Mercy, please! I'm completely unarmed!",
                            "Don't shoot! I'm already defeated!",
                            "Please let me live! I surrender!",
                            "Spare me, please! I have nothing left!",
                            "I beg you... don't finish me off!",
                            "I yield! Don't strike again!",
                            "Show mercy! I'm bleeding out on the floor!",
                            "Don't hurt me anymore, please!",
                            "Have a heart... let me survive this.",
                        },
                        ["TL"] = {
                            "Bagsak na ako! Pakiusap, huwag mo akong patayin!",
                            "Maawa ka, pakiusap! Wala akong sandata!",
                            "Huwag kang puputok! Talo na ako!",
                            "Pakiusap buhayin mo ako! Sumusuko na ako!",
                            "Patawarin mo ako, pakiusap! Wala nang natira sa akin!",
                            "Nagmamakaawa ako sa'yo... huwag mo akong tapusin!",
                            "Suko na ako! Huwag ka nang humataw ulit!",
                            "Maawa ka! Nauubusan na ako ng dugo sa sahig!",
                            "Huwag mo na akong saktan pa, pakiusap!",
                            "Maawa ka naman... hayaan mo akong mabuhay.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "medical.distress.call.mercy",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "mercy",
            ["sourceId"] = "medical.distress.call.mercy",
            ["sourcePath"] = "adopters/hoomans/dialogue/medical_event_call/medical_distress_call_mercy.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalEventCall",
        ["namespace"] = "medical.distress.call",
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
                ["sourceSurface"] = "content/event/medical/call.json",
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
                                        "I'm down! Please, don't kill me!",
                                        "Mercy, please! I'm completely unarmed!",
                                        "Don't shoot! I'm already defeated!",
                                        "Please let me live! I surrender!",
                                        "Spare me, please! I have nothing left!",
                                        "I beg you... don't finish me off!",
                                        "I yield! Don't strike again!",
                                        "Show mercy! I'm bleeding out on the floor!",
                                        "Don't hurt me anymore, please!",
                                        "Have a heart... let me survive this.",
                                    },
                                    ["TL"] = {
                                        "Bagsak na ako! Pakiusap, huwag mo akong patayin!",
                                        "Maawa ka, pakiusap! Wala akong sandata!",
                                        "Huwag kang puputok! Talo na ako!",
                                        "Pakiusap buhayin mo ako! Sumusuko na ako!",
                                        "Patawarin mo ako, pakiusap! Wala nang natira sa akin!",
                                        "Nagmamakaawa ako sa'yo... huwag mo akong tapusin!",
                                        "Suko na ako! Huwag ka nang humataw ulit!",
                                        "Maawa ka! Nauubusan na ako ng dugo sa sahig!",
                                        "Huwag mo na akong saktan pa, pakiusap!",
                                        "Maawa ka naman... hayaan mo akong mabuhay.",
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
            ["responsePlanID"] = "medical.distress.call.mercy",
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
                            ["fallback"] = "I'm down! Please, don't kill me!",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.medical.distress.call.mercy.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/medical_event_call/medical_distress_call_mercy.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'm down! Please, don't kill me!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.call.mercy.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I'm down! Please, don't kill me!",
                        "Mercy, please! I'm completely unarmed!",
                        "Don't shoot! I'm already defeated!",
                        "Please let me live! I surrender!",
                        "Spare me, please! I have nothing left!",
                        "I beg you... don't finish me off!",
                        "I yield! Don't strike again!",
                        "Show mercy! I'm bleeding out on the floor!",
                        "Don't hurt me anymore, please!",
                        "Have a heart... let me survive this.",
                    },
                    ["TL"] = {
                        "Bagsak na ako! Pakiusap, huwag mo akong patayin!",
                        "Maawa ka, pakiusap! Wala akong sandata!",
                        "Huwag kang puputok! Talo na ako!",
                        "Pakiusap buhayin mo ako! Sumusuko na ako!",
                        "Patawarin mo ako, pakiusap! Wala nang natira sa akin!",
                        "Nagmamakaawa ako sa'yo... huwag mo akong tapusin!",
                        "Suko na ako! Huwag ka nang humataw ulit!",
                        "Maawa ka! Nauubusan na ako ng dugo sa sahig!",
                        "Huwag mo na akong saktan pa, pakiusap!",
                        "Maawa ka naman... hayaan mo akong mabuhay.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_call",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.call.rescue",
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
                                ["fallback"] = "I'm trapped here! I need help over here!",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.medical.distress.call.rescue.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'm trapped here! I need help over here!",
                                        "Can't move on my own! Pull me out!",
                                        "Pinned down and injured! Come get me!",
                                        "Over here! Don't leave me stranded!",
                                        "I'm stuck behind rubble! Need someone to clear it!",
                                        "Can't crawl any further! Help me!",
                                        "I'm over here, behind cover! Pull me back!",
                                        "Rescue me, please! They're getting closer!",
                                        "I need extraction! Can't walk out of here!",
                                        "Help me get out! My leg is broken!",
                                    },
                                    ["TL"] = {
                                        "Naipit ako rito! Kailangan ko ng tulong dito!",
                                        "Hindi ako makagalaw mag-isa! Hilahin mo ako palabas!",
                                        "Naiipit at sugatan! Halika kunin mo ako!",
                                        "Dito! Huwag niyo akong iwang nastranded!",
                                        "Naipit ako sa likod ng guho! May kailangang mag-alis nito!",
                                        "Hindi na ako makagapang pa! Tulungan mo ako!",
                                        "Nandito ako sa kublihan! Hilahin mo ako pabalik!",
                                        "Saklolohan mo ako, pakiusap! Papalapit na sila!",
                                        "Kailangan ko ng tulong makalabas! Hindi ako makakalakad!",
                                        "Tulungan mo akong makalabas! Bali ang binti ko!",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.distress.call",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'm trapped here! I need help over here!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.call.rescue.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I'm trapped here! I need help over here!",
                            "Can't move on my own! Pull me out!",
                            "Pinned down and injured! Come get me!",
                            "Over here! Don't leave me stranded!",
                            "I'm stuck behind rubble! Need someone to clear it!",
                            "Can't crawl any further! Help me!",
                            "I'm over here, behind cover! Pull me back!",
                            "Rescue me, please! They're getting closer!",
                            "I need extraction! Can't walk out of here!",
                            "Help me get out! My leg is broken!",
                        },
                        ["TL"] = {
                            "Naipit ako rito! Kailangan ko ng tulong dito!",
                            "Hindi ako makagalaw mag-isa! Hilahin mo ako palabas!",
                            "Naiipit at sugatan! Halika kunin mo ako!",
                            "Dito! Huwag niyo akong iwang nastranded!",
                            "Naipit ako sa likod ng guho! May kailangang mag-alis nito!",
                            "Hindi na ako makagapang pa! Tulungan mo ako!",
                            "Nandito ako sa kublihan! Hilahin mo ako pabalik!",
                            "Saklolohan mo ako, pakiusap! Papalapit na sila!",
                            "Kailangan ko ng tulong makalabas! Hindi ako makakalakad!",
                            "Tulungan mo akong makalabas! Bali ang binti ko!",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "medical.distress.call.rescue",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "rescue",
            ["sourceId"] = "medical.distress.call.rescue",
            ["sourcePath"] = "adopters/hoomans/dialogue/medical_event_call/medical_distress_call_rescue.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalEventCall",
        ["namespace"] = "medical.distress.call",
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
                ["sourceSurface"] = "content/event/medical/call.json",
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
                                        "I'm trapped here! I need help over here!",
                                        "Can't move on my own! Pull me out!",
                                        "Pinned down and injured! Come get me!",
                                        "Over here! Don't leave me stranded!",
                                        "I'm stuck behind rubble! Need someone to clear it!",
                                        "Can't crawl any further! Help me!",
                                        "I'm over here, behind cover! Pull me back!",
                                        "Rescue me, please! They're getting closer!",
                                        "I need extraction! Can't walk out of here!",
                                        "Help me get out! My leg is broken!",
                                    },
                                    ["TL"] = {
                                        "Naipit ako rito! Kailangan ko ng tulong dito!",
                                        "Hindi ako makagalaw mag-isa! Hilahin mo ako palabas!",
                                        "Naiipit at sugatan! Halika kunin mo ako!",
                                        "Dito! Huwag niyo akong iwang nastranded!",
                                        "Naipit ako sa likod ng guho! May kailangang mag-alis nito!",
                                        "Hindi na ako makagapang pa! Tulungan mo ako!",
                                        "Nandito ako sa kublihan! Hilahin mo ako pabalik!",
                                        "Saklolohan mo ako, pakiusap! Papalapit na sila!",
                                        "Kailangan ko ng tulong makalabas! Hindi ako makakalakad!",
                                        "Tulungan mo akong makalabas! Bali ang binti ko!",
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
            ["responsePlanID"] = "medical.distress.call.rescue",
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
                            ["fallback"] = "I'm trapped here! I need help over here!",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.medical.distress.call.rescue.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/medical_event_call/medical_distress_call_rescue.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'm trapped here! I need help over here!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.call.rescue.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I'm trapped here! I need help over here!",
                        "Can't move on my own! Pull me out!",
                        "Pinned down and injured! Come get me!",
                        "Over here! Don't leave me stranded!",
                        "I'm stuck behind rubble! Need someone to clear it!",
                        "Can't crawl any further! Help me!",
                        "I'm over here, behind cover! Pull me back!",
                        "Rescue me, please! They're getting closer!",
                        "I need extraction! Can't walk out of here!",
                        "Help me get out! My leg is broken!",
                    },
                    ["TL"] = {
                        "Naipit ako rito! Kailangan ko ng tulong dito!",
                        "Hindi ako makagalaw mag-isa! Hilahin mo ako palabas!",
                        "Naiipit at sugatan! Halika kunin mo ako!",
                        "Dito! Huwag niyo akong iwang nastranded!",
                        "Naipit ako sa likod ng guho! May kailangang mag-alis nito!",
                        "Hindi na ako makagapang pa! Tulungan mo ako!",
                        "Nandito ako sa kublihan! Hilahin mo ako pabalik!",
                        "Saklolohan mo ako, pakiusap! Papalapit na sila!",
                        "Kailangan ko ng tulong makalabas! Hindi ako makakalakad!",
                        "Tulungan mo akong makalabas! Bali ang binti ko!",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_call",
        ["exchangeFamily"] = {
            ["familyID"] = "medical.distress.call.starvation",
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
                                ["fallback"] = "Haven't eaten in days... I'm starving to death.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.medical.distress.call.starvation.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Haven't eaten in days... I'm starving to death.",
                                        "Too weak from hunger to stand up. Food, please.",
                                        "Stomach is eating itself... any crumbs left?",
                                        "Starving... can't even hold my weapon.",
                                        "Please, just a bite of anything edible.",
                                        "Fainting from lack of calories. I need food.",
                                        "Hunger cramps are tearing me apart. Help me.",
                                        "I can't go on like this without food in my belly.",
                                        "Empty for days... please bring me something to eat.",
                                        "Starving on the floor... spare a ration, please.",
                                    },
                                    ["TL"] = {
                                        "Ilang araw nang hindi kumakain... namamatay na ako sa gutom.",
                                        "Masyadong nanghihina sa gutom para makatayo. Pagkain, pakiusap.",
                                        "Kumakalam na ang sikmura ko... may natira pa bang mumo?",
                                        "Gutom na gutom... hindi ko man lang mahawakan ang sandata ko.",
                                        "Pakiusap, kahit isang kagat lang ng anumang makakain.",
                                        "Nahihiya sa kawalan ng pagkain. Kailangan ko ng makakain.",
                                        "Pinupulikat ang tiyan ko sa gutom. Tulungan mo ako.",
                                        "Hindi ko na kayang magpatuloy nang walang laman ang tiyan.",
                                        "Ilang araw nang walang laman... dalhan mo ako ng makakain.",
                                        "Nagugutom sa sahig... magbahagi naman ng rasyon, pakiusap.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "medical.distress.call",
            ["textRoles"] = {
                {
                    ["fallback"] = "Haven't eaten in days... I'm starving to death.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.medical.distress.call.starvation.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Haven't eaten in days... I'm starving to death.",
                            "Too weak from hunger to stand up. Food, please.",
                            "Stomach is eating itself... any crumbs left?",
                            "Starving... can't even hold my weapon.",
                            "Please, just a bite of anything edible.",
                            "Fainting from lack of calories. I need food.",
                            "Hunger cramps are tearing me apart. Help me.",
                            "I can't go on like this without food in my belly.",
                            "Empty for days... please bring me something to eat.",
                            "Starving on the floor... spare a ration, please.",
                        },
                        ["TL"] = {
                            "Ilang araw nang hindi kumakain... namamatay na ako sa gutom.",
                            "Masyadong nanghihina sa gutom para makatayo. Pagkain, pakiusap.",
                            "Kumakalam na ang sikmura ko... may natira pa bang mumo?",
                            "Gutom na gutom... hindi ko man lang mahawakan ang sandata ko.",
                            "Pakiusap, kahit isang kagat lang ng anumang makakain.",
                            "Nahihiya sa kawalan ng pagkain. Kailangan ko ng makakain.",
                            "Pinupulikat ang tiyan ko sa gutom. Tulungan mo ako.",
                            "Hindi ko na kayang magpatuloy nang walang laman ang tiyan.",
                            "Ilang araw nang walang laman... dalhan mo ako ng makakain.",
                            "Nagugutom sa sahig... magbahagi naman ng rasyon, pakiusap.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "medical.distress.call.starvation",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "starvation",
            ["sourceId"] = "medical.distress.call.starvation",
            ["sourcePath"] = "adopters/hoomans/dialogue/medical_event_call/medical_distress_call_starvation.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/MedicalEventCall",
        ["namespace"] = "medical.distress.call",
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
                ["sourceSurface"] = "content/event/medical/call.json",
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
                                        "Haven't eaten in days... I'm starving to death.",
                                        "Too weak from hunger to stand up. Food, please.",
                                        "Stomach is eating itself... any crumbs left?",
                                        "Starving... can't even hold my weapon.",
                                        "Please, just a bite of anything edible.",
                                        "Fainting from lack of calories. I need food.",
                                        "Hunger cramps are tearing me apart. Help me.",
                                        "I can't go on like this without food in my belly.",
                                        "Empty for days... please bring me something to eat.",
                                        "Starving on the floor... spare a ration, please.",
                                    },
                                    ["TL"] = {
                                        "Ilang araw nang hindi kumakain... namamatay na ako sa gutom.",
                                        "Masyadong nanghihina sa gutom para makatayo. Pagkain, pakiusap.",
                                        "Kumakalam na ang sikmura ko... may natira pa bang mumo?",
                                        "Gutom na gutom... hindi ko man lang mahawakan ang sandata ko.",
                                        "Pakiusap, kahit isang kagat lang ng anumang makakain.",
                                        "Nahihiya sa kawalan ng pagkain. Kailangan ko ng makakain.",
                                        "Pinupulikat ang tiyan ko sa gutom. Tulungan mo ako.",
                                        "Hindi ko na kayang magpatuloy nang walang laman ang tiyan.",
                                        "Ilang araw nang walang laman... dalhan mo ako ng makakain.",
                                        "Nagugutom sa sahig... magbahagi naman ng rasyon, pakiusap.",
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
            ["responsePlanID"] = "medical.distress.call.starvation",
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
                            ["fallback"] = "Haven't eaten in days... I'm starving to death.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.medical.distress.call.starvation.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/medical_event_call/medical_distress_call_starvation.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Haven't eaten in days... I'm starving to death.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.medical.distress.call.starvation.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Haven't eaten in days... I'm starving to death.",
                        "Too weak from hunger to stand up. Food, please.",
                        "Stomach is eating itself... any crumbs left?",
                        "Starving... can't even hold my weapon.",
                        "Please, just a bite of anything edible.",
                        "Fainting from lack of calories. I need food.",
                        "Hunger cramps are tearing me apart. Help me.",
                        "I can't go on like this without food in my belly.",
                        "Empty for days... please bring me something to eat.",
                        "Starving on the floor... spare a ration, please.",
                    },
                    ["TL"] = {
                        "Ilang araw nang hindi kumakain... namamatay na ako sa gutom.",
                        "Masyadong nanghihina sa gutom para makatayo. Pagkain, pakiusap.",
                        "Kumakalam na ang sikmura ko... may natira pa bang mumo?",
                        "Gutom na gutom... hindi ko man lang mahawakan ang sandata ko.",
                        "Pakiusap, kahit isang kagat lang ng anumang makakain.",
                        "Nahihiya sa kawalan ng pagkain. Kailangan ko ng makakain.",
                        "Pinupulikat ang tiyan ko sa gutom. Tulungan mo ako.",
                        "Hindi ko na kayang magpatuloy nang walang laman ang tiyan.",
                        "Ilang araw nang walang laman... dalhan mo ako ng makakain.",
                        "Nagugutom sa sahig... magbahagi naman ng rasyon, pakiusap.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
