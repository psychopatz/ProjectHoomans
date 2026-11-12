-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "medical_event_call",
        ["id"] = "semantic.medical.distress.call.bandage",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.call.bandage",
            ["sourcePath"] = "psdl/dialogue/medical_event_call.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/MedicalEventCall/Catalog",
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
                ["responseTemplateID"] = "semantic.medical.distress.call.bandage",
                ["sourceSurface"] = "content/event/medical/call.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.bandage.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm hurt and down! Need a bandage over here!",
                            },
                            ["TL"] = {
                                "Sugatan ako at nakahandusay! Kailangan ko ng benda rito!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.bandage.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Deep cut... I need a bandage now!",
                            },
                            ["TL"] = {
                                "Malalim ang sugat... kailangan ko ng benda ngayon din!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.bandage.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I can't stop this wound alone! Bring a bandage!",
                            },
                            ["TL"] = {
                                "Hindi ko mapatigil ang sugat nang mag-isa! Magdala ka ng benda!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.bandage.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Patch me up, please! I'm losing blood!",
                            },
                            ["TL"] = {
                                "Bendahan mo ako, pakiusap! Nauubusan ako ng dugo!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.bandage.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm down! Does anyone have a clean rag or bandage?!",
                            },
                            ["TL"] = {
                                "Bagsak ako! May malinis ba kayong basahan o benda?!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.bandage.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Gash on my leg... need wrapping right now!",
                            },
                            ["TL"] = {
                                "May hiwa sa binti ko... kailangang balutin ngayon din!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.bandage.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Help! I need these wounds dressed!",
                            },
                            ["TL"] = {
                                "Tulong! Kailangang gamutin ang mga sugat na 'to!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.bandage.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm on the floor, bleeding! Get a bandage over here!",
                            },
                            ["TL"] = {
                                "Nasa sahig ako, dumurugo! Dalhan mo ako ng benda rito!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.bandage.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Need a patch immediately! I'm grounded!",
                            },
                            ["TL"] = {
                                "Kailangan ng panapal agad! Hindi ako makatayo!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.bandage.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Bandage, quick! I can't get up without one!",
                            },
                            ["TL"] = {
                                "Benda, bilis! Hindi ako makakabangon kung wala 'yan!",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_call.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_call",
        ["id"] = "semantic.medical.distress.call.bleedout",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.call.bleedout",
            ["sourcePath"] = "psdl/dialogue/medical_event_call.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/MedicalEventCall/Catalog",
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
                ["responseTemplateID"] = "semantic.medical.distress.call.bleedout",
                ["sourceSurface"] = "content/event/medical/call.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.bleedout.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm bleeding out! I need a tourniquet or bandage now!",
                            },
                            ["TL"] = {
                                "Nauubusan ako ng dugo! Kailangan ko ng benda ngayon din!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.bleedout.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Dying here! The blood won't stop flowing!",
                            },
                            ["TL"] = {
                                "Nalalagutan ako ng hininga! Ayaw tumigil ng agos ng dugo!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.bleedout.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm losing too much blood... getting cold!",
                            },
                            ["TL"] = {
                                "Masyadong maraming dugo ang nawawala... nilalamig na ako!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.bleedout.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Hit an artery! Put pressure on this right now!",
                            },
                            ["TL"] = {
                                "Tinamaan ang ugat! Diinan mo 'to ngayon din!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.bleedout.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Everything's going dark... stop the bleeding, please!",
                            },
                            ["TL"] = {
                                "Dumidilim ang paningin ko... patigilin mo ang dugo, pakiusap!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.bleedout.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm bleeding through my clothes! Help me!",
                            },
                            ["TL"] = {
                                "Bumabaon ang dugo sa damit ko! Tulungan mo ako!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.bleedout.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Blood everywhere... please, I don't want to die here!",
                            },
                            ["TL"] = {
                                "Nagkalat ang dugo... pakiusap, ayaw kong mamatay rito!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.bleedout.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Losing consciousness... plug this wound!",
                            },
                            ["TL"] = {
                                "Nawawalan ako ng malay... tapalan mo ang sugat na 'to!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.bleedout.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Hurry! I'm bleeding out on the dirt!",
                            },
                            ["TL"] = {
                                "Bilis! Nauubusan ako ng dugo sa lupa!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.bleedout.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Can't feel my fingers... stop the blood!",
                            },
                            ["TL"] = {
                                "Hindi ko na maramdaman ang daliri ko... patigilin ang dugo!",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_call.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_call",
        ["id"] = "semantic.medical.distress.call.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.call.default",
            ["sourcePath"] = "psdl/dialogue/medical_event_call.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/MedicalEventCall/Catalog",
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
                ["responseTemplateID"] = "semantic.medical.distress.call.default",
                ["sourceSurface"] = "content/event/medical/call.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.default.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm down! I need help over here!",
                            },
                            ["TL"] = {
                                "Bagsak ako! Kailangan ko ng tulong dito!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.default.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Can't stand! Someone help me up!",
                            },
                            ["TL"] = {
                                "Hindi ako makatayo! Tulungan niyo akong makatayo!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.default.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm hit! Get over here!",
                            },
                            ["TL"] = {
                                "Tinamaan ako! Halika rito!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.default.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Need medical attention immediately!",
                            },
                            ["TL"] = {
                                "Kailangan ko ng agarang panggagamot!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.default.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Down and helpless! Don't leave me!",
                            },
                            ["TL"] = {
                                "Bagsak at walang laban! Huwag niyo akong iwan!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.default.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I took a bad fall! Help me!",
                            },
                            ["TL"] = {
                                "Napasama ang bagsak ko! Tulungan mo ako!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.default.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Can't get back on my feet! Help!",
                            },
                            ["TL"] = {
                                "Hindi ako makabangon! Tulong!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.default.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Hurt bad! Over here, please!",
                            },
                            ["TL"] = {
                                "Malubha ang tama ko! Dito, pakiusap!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.default.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm down on the ground! Need a hand!",
                            },
                            ["TL"] = {
                                "Nasa sahig ako! Pasaklolo naman!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.default.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Injured and stranded! Come help!",
                            },
                            ["TL"] = {
                                "Sugatan at nastranded! Tulungan niyo ako!",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_call.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_call",
        ["id"] = "semantic.medical.distress.call.dehydration",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.call.dehydration",
            ["sourcePath"] = "psdl/dialogue/medical_event_call.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/MedicalEventCall/Catalog",
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
                ["responseTemplateID"] = "semantic.medical.distress.call.dehydration",
                ["sourceSurface"] = "content/event/medical/call.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.dehydration.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "So thirsty... I need water before I pass out.",
                            },
                            ["TL"] = {
                                "Uhaw na uhaw na ako... kailangan ko ng tubig bago ako mahimatay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.dehydration.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Throat is completely parched... please, any water?",
                            },
                            ["TL"] = {
                                "Tuyong-tuyo na ang lalamunan ko... pakiusap, may tubig ba?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.dehydration.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Drying out... can barely swallow. Water, please.",
                            },
                            ["TL"] = {
                                "Nanghihina sa uhaw... halos hindi makalunok. Tubig, pakiusap.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.dehydration.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm too dehydrated to move my legs. Water...",
                            },
                            ["TL"] = {
                                "Masyado akong dehydrated para maigalaw ang binti ko. Tubig...",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.dehydration.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Give me a sip of water... dying of thirst.",
                            },
                            ["TL"] = {
                                "Pahingi ng kahit kaunting tubig... mamamatay na ako sa uhaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.dehydration.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Lips are cracked and bleeding... need clean water.",
                            },
                            ["TL"] = {
                                "Nangangapal at nagdurugo ang labi ko... kailangan ng malinis na tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.dehydration.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Can't walk anymore... please bring a water bottle.",
                            },
                            ["TL"] = {
                                "Hindi na makalakad... pakiusap dalhan mo ako ng tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.dehydration.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Head is pounding from dehydration... need a drink.",
                            },
                            ["TL"] = {
                                "Pumipintig ang ulo ko sa uhaw... kailangang uminom.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.dehydration.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm collapsing... just a few drops of water.",
                            },
                            ["TL"] = {
                                "Bumabagsak na ako... kahit ilang patak lang ng tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.dehydration.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Water... please, someone hand me water.",
                            },
                            ["TL"] = {
                                "Tubig... pakiusap, bigyan niyo ako ng tubig.",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_call.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_call",
        ["id"] = "semantic.medical.distress.call.exhaustion",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.call.exhaustion",
            ["sourcePath"] = "psdl/dialogue/medical_event_call.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/MedicalEventCall/Catalog",
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
                ["responseTemplateID"] = "semantic.medical.distress.call.exhaustion",
                ["sourceSurface"] = "content/event/medical/call.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.exhaustion.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Pushed too far. I can't lift my arms.",
                            },
                            ["TL"] = {
                                "Nasobrahan ako. Hindi ko na maitaas ang mga braso ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.exhaustion.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Completely spent... give me a moment to recover.",
                            },
                            ["TL"] = {
                                "Ubos na ubos na ang lakas ko... bigyan mo ako ng saglit para makabawi.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.exhaustion.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Legs gave out beneath me. Need to sit.",
                            },
                            ["TL"] = {
                                "Bumigay ang mga binti ko. Kailangan kong umupo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.exhaustion.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Can't move another step. Total exhaustion.",
                            },
                            ["TL"] = {
                                "Hindi na makakahakbang pa. Sagad na pagod na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.exhaustion.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Breathing hurts. I need rest right now.",
                            },
                            ["TL"] = {
                                "Masakit huminga. Kailangan ko ng pahinga ngayon din.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.exhaustion.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Collapsed from fatigue... give me five minutes.",
                            },
                            ["TL"] = {
                                "Bumagsak sa matinding pagod... bigyan mo ako ng limang minuto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.exhaustion.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Muscles are locking up. Can't stand.",
                            },
                            ["TL"] = {
                                "Naninigas na ang kalamnan ko. Hindi makatayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.exhaustion.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I have nothing left in the tank. Need a break.",
                            },
                            ["TL"] = {
                                "Wala nang natitirang lakas. Kailangan ng pahinga.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.exhaustion.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Vision is swimming from exhaustion. Give me time.",
                            },
                            ["TL"] = {
                                "Umiikot ang paningin ko sa pagod. Bigyan mo ako ng oras.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.exhaustion.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Body won't respond... let me rest a second.",
                            },
                            ["TL"] = {
                                "Ayaw nang gumalaw ng katawan ko... pahingahin mo muna ako.",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_call.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_call",
        ["id"] = "semantic.medical.distress.call.mercy",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.call.mercy",
            ["sourcePath"] = "psdl/dialogue/medical_event_call.json#records[5]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/MedicalEventCall/Catalog",
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
                ["responseTemplateID"] = "semantic.medical.distress.call.mercy",
                ["sourceSurface"] = "content/event/medical/call.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.mercy.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm down! Please, don't kill me!",
                            },
                            ["TL"] = {
                                "Bagsak na ako! Pakiusap, huwag mo akong patayin!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.mercy.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Mercy, please! I'm completely unarmed!",
                            },
                            ["TL"] = {
                                "Maawa ka, pakiusap! Wala akong sandata!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.mercy.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't shoot! I'm already defeated!",
                            },
                            ["TL"] = {
                                "Huwag kang puputok! Talo na ako!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.mercy.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Please let me live! I surrender!",
                            },
                            ["TL"] = {
                                "Pakiusap buhayin mo ako! Sumusuko na ako!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.mercy.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Spare me, please! I have nothing left!",
                            },
                            ["TL"] = {
                                "Patawarin mo ako, pakiusap! Wala nang natira sa akin!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.mercy.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I beg you... don't finish me off!",
                            },
                            ["TL"] = {
                                "Nagmamakaawa ako sa'yo... huwag mo akong tapusin!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.mercy.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I yield! Don't strike again!",
                            },
                            ["TL"] = {
                                "Suko na ako! Huwag ka nang humataw ulit!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.mercy.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Show mercy! I'm bleeding out on the floor!",
                            },
                            ["TL"] = {
                                "Maawa ka! Nauubusan na ako ng dugo sa sahig!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.mercy.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't hurt me anymore, please!",
                            },
                            ["TL"] = {
                                "Huwag mo na akong saktan pa, pakiusap!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.mercy.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Have a heart... let me survive this.",
                            },
                            ["TL"] = {
                                "Maawa ka naman... hayaan mo akong mabuhay.",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_call.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_call",
        ["id"] = "semantic.medical.distress.call.rescue",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.call.rescue",
            ["sourcePath"] = "psdl/dialogue/medical_event_call.json#records[6]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/MedicalEventCall/Catalog",
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
                ["responseTemplateID"] = "semantic.medical.distress.call.rescue",
                ["sourceSurface"] = "content/event/medical/call.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.rescue.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm trapped here! I need help over here!",
                            },
                            ["TL"] = {
                                "Naipit ako rito! Kailangan ko ng tulong dito!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.rescue.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Can't move on my own! Pull me out!",
                            },
                            ["TL"] = {
                                "Hindi ako makagalaw mag-isa! Hilahin mo ako palabas!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.rescue.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Pinned down and injured! Come get me!",
                            },
                            ["TL"] = {
                                "Naiipit at sugatan! Halika kunin mo ako!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.rescue.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Over here! Don't leave me stranded!",
                            },
                            ["TL"] = {
                                "Dito! Huwag niyo akong iwang nastranded!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.rescue.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm stuck behind rubble! Need someone to clear it!",
                            },
                            ["TL"] = {
                                "Naipit ako sa likod ng guho! May kailangang mag-alis nito!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.rescue.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Can't crawl any further! Help me!",
                            },
                            ["TL"] = {
                                "Hindi na ako makagapang pa! Tulungan mo ako!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.rescue.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm over here, behind cover! Pull me back!",
                            },
                            ["TL"] = {
                                "Nandito ako sa kublihan! Hilahin mo ako pabalik!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.rescue.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Rescue me, please! They're getting closer!",
                            },
                            ["TL"] = {
                                "Saklolohan mo ako, pakiusap! Papalapit na sila!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.rescue.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I need extraction! Can't walk out of here!",
                            },
                            ["TL"] = {
                                "Kailangan ko ng tulong makalabas! Hindi ako makakalakad!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.rescue.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Help me get out! My leg is broken!",
                            },
                            ["TL"] = {
                                "Tulungan mo akong makalabas! Bali ang binti ko!",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_call.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_call",
        ["id"] = "semantic.medical.distress.call.starvation",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.call.starvation",
            ["sourcePath"] = "psdl/dialogue/medical_event_call.json#records[7]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/MedicalEventCall/Catalog",
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
                ["responseTemplateID"] = "semantic.medical.distress.call.starvation",
                ["sourceSurface"] = "content/event/medical/call.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.starvation.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Haven't eaten in days... I'm starving to death.",
                            },
                            ["TL"] = {
                                "Ilang araw nang hindi kumakain... namamatay na ako sa gutom.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.starvation.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Too weak from hunger to stand up. Food, please.",
                            },
                            ["TL"] = {
                                "Masyadong nanghihina sa gutom para makatayo. Pagkain, pakiusap.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.starvation.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Stomach is eating itself... any crumbs left?",
                            },
                            ["TL"] = {
                                "Kumakalam na ang sikmura ko... may natira pa bang mumo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.starvation.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Starving... can't even hold my weapon.",
                            },
                            ["TL"] = {
                                "Gutom na gutom... hindi ko man lang mahawakan ang sandata ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.starvation.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Please, just a bite of anything edible.",
                            },
                            ["TL"] = {
                                "Pakiusap, kahit isang kagat lang ng anumang makakain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.starvation.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Fainting from lack of calories. I need food.",
                            },
                            ["TL"] = {
                                "Nahihiya sa kawalan ng pagkain. Kailangan ko ng makakain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.starvation.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Hunger cramps are tearing me apart. Help me.",
                            },
                            ["TL"] = {
                                "Pinupulikat ang tiyan ko sa gutom. Tulungan mo ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.starvation.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I can't go on like this without food in my belly.",
                            },
                            ["TL"] = {
                                "Hindi ko na kayang magpatuloy nang walang laman ang tiyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.starvation.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Empty for days... please bring me something to eat.",
                            },
                            ["TL"] = {
                                "Ilang araw nang walang laman... dalhan mo ako ng makakain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.call.starvation.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Starving on the floor... spare a ration, please.",
                            },
                            ["TL"] = {
                                "Nagugutom sa sahig... magbahagi naman ng rasyon, pakiusap.",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_call.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
