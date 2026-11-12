-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "medical_event_update",
        ["id"] = "semantic.medical.distress.update.bandage",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.update.bandage",
            ["sourcePath"] = "psdl/dialogue/medical_event_update.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/MedicalEventUpdate/Catalog",
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
                ["responseTemplateID"] = "semantic.medical.distress.update.bandage",
                ["sourceSurface"] = "content/event/medical/update.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.bandage.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I am still down and waiting for a patch.",
                            },
                            ["TL"] = {
                                "Nasa sahig pa rin ako at naghihintay ng benda.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.bandage.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still on the floor. Where is that bandage?",
                            },
                            ["TL"] = {
                                "Nasa sahig pa rin. Nasaan na 'yung benda?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.bandage.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Wound is still unbandaged. Need it wrapped soon.",
                            },
                            ["TL"] = {
                                "Wala pa ring benda ang sugat. Kailangang balutin na agad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.bandage.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still waiting for someone to bind this cut.",
                            },
                            ["TL"] = {
                                "Naghihintay pa rin ng magtatali sa hiwang 'to.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.bandage.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Blood is still seeping through. Need that wrap.",
                            },
                            ["TL"] = {
                                "Tumutulo pa rin ang dugo. Kailangan ko ng pambalot.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.bandage.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still grounded until these wounds get dressed.",
                            },
                            ["TL"] = {
                                "Bagsak pa rin hangga't hindi nagagamot ang mga sugat na 'to.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.bandage.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Waiting on clean cloth. Can't stand like this.",
                            },
                            ["TL"] = {
                                "Naghihintay ng malinis na tela. Hindi makatayo nang ganito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.bandage.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still down here waiting for first aid.",
                            },
                            ["TL"] = {
                                "Nandito pa rin sa sahig at naghihintay ng first aid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.bandage.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Unpatched and bleeding. Please hurry.",
                            },
                            ["TL"] = {
                                "Walang benda at dumurugo. Pakiusap bilisan mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.bandage.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still need that dressing applied. Don't delay.",
                            },
                            ["TL"] = {
                                "Kailangan pa ring ilapat ang pambenda. Huwag patagalin.",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_update.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_update",
        ["id"] = "semantic.medical.distress.update.bleedout",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.update.bleedout",
            ["sourcePath"] = "psdl/dialogue/medical_event_update.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/MedicalEventUpdate/Catalog",
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
                ["responseTemplateID"] = "semantic.medical.distress.update.bleedout",
                ["sourceSurface"] = "content/event/medical/update.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.bleedout.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The bleeding has not stopped. I still need a bandage.",
                            },
                            ["TL"] = {
                                "Hindi pa tumitigil ang dugo. Kailangan ko pa rin ng benda.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.bleedout.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still hemorrhaging. I need pressure and a wrap immediately.",
                            },
                            ["TL"] = {
                                "Patuloy pa ring umaagos ang dugo. Kailangan ng diin at benda agad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.bleedout.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Bleeding is continuing. I'm getting lightheaded.",
                            },
                            ["TL"] = {
                                "Dumurugo pa rin. Nahihilo na ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.bleedout.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Blood is still flowing. Please get that bandage on me.",
                            },
                            ["TL"] = {
                                "Umaagos pa rin ang dugo. Pakiusap lagyan mo na ako ng benda.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.bleedout.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Hasn't stopped bleeding yet. Running out of time.",
                            },
                            ["TL"] = {
                                "Hindi pa rin humihinto ang pagdurugo. Nauubusan na ako ng oras.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.bleedout.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still losing red. My clothes are soaked.",
                            },
                            ["TL"] = {
                                "Nauubusan pa rin ng dugo. Babad na ang damit ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.bleedout.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The wound won't seal itself. Need a dressing now.",
                            },
                            ["TL"] = {
                                "Hindi kusang magsasara ang sugat. Kailangan ng benda ngayon din.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.bleedout.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still bleeding steadily. Hurry up with the aid.",
                            },
                            ["TL"] = {
                                "Tuloy-tuloy pa rin ang pagdurugo. Bilisan mo ang tulong.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.bleedout.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Losing blood by the second. Please hurry.",
                            },
                            ["TL"] = {
                                "Bawat segundo nauubusan ako ng dugo. Pakiusap magmadali ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.bleedout.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The cut won't stop bleeding. Wrap it, please.",
                            },
                            ["TL"] = {
                                "Ayaw tumigil ng pagdurugo ng hiwa. Balutin mo na, pakiusap.",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_update.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_update",
        ["id"] = "semantic.medical.distress.update.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.update.default",
            ["sourcePath"] = "psdl/dialogue/medical_event_update.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/MedicalEventUpdate/Catalog",
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
                ["responseTemplateID"] = "semantic.medical.distress.update.default",
                ["sourceSurface"] = "content/event/medical/update.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.default.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I am still down. I still need help.",
                            },
                            ["TL"] = {
                                "Bagsak pa rin ako. Kailangan ko pa rin ng tulong.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.default.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still incapacitated on the ground. Please assist.",
                            },
                            ["TL"] = {
                                "Hindi pa rin makakilos sa lupa. Pakiusap tulungan mo ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.default.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Haven't recovered yet. Still need a hand.",
                            },
                            ["TL"] = {
                                "Hindi pa nakakabawi. Kailangan pa rin ng saklolo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.default.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still down here. Don't leave me alone.",
                            },
                            ["TL"] = {
                                "Nandito pa rin sa sahig. Huwag mo akong iwang mag-isa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.default.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Status unchanged: still injured and waiting.",
                            },
                            ["TL"] = {
                                "Walang pagbabago: sugatan pa rin at naghihintay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.default.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still grounded. I need someone to help me up.",
                            },
                            ["TL"] = {
                                "Bagsak pa rin. Kailangan ko ng tutulong sa akin makatayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.default.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Can't move on my own yet. Still need aid.",
                            },
                            ["TL"] = {
                                "Hindi pa makagalaw mag-isa. Kailangan pa rin ng lunas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.default.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still unable to stand. Waiting for help.",
                            },
                            ["TL"] = {
                                "Hindi pa rin makatayo. Naghihintay ng tulong.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.default.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm still down in the dirt. Please assist me.",
                            },
                            ["TL"] = {
                                "Nasa lupa pa rin ako. Pakiusap saklolohan mo ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.default.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still waiting for support. Don't forget me.",
                            },
                            ["TL"] = {
                                "Naghihintay pa rin ng suporta. Huwag mo akong kalimutan.",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_update.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_update",
        ["id"] = "semantic.medical.distress.update.dehydration",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.update.dehydration",
            ["sourcePath"] = "psdl/dialogue/medical_event_update.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/MedicalEventUpdate/Catalog",
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
                ["responseTemplateID"] = "semantic.medical.distress.update.dehydration",
                ["sourceSurface"] = "content/event/medical/update.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.dehydration.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I still need water before I can move.",
                            },
                            ["TL"] = {
                                "Kailangan ko pa rin ng tubig bago makakilos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.dehydration.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Thirst is still crippling me. Bring hydration.",
                            },
                            ["TL"] = {
                                "Pinapahirapan pa rin ako ng uhaw. Magdala ka ng tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.dehydration.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Can't stand until I drink something clean.",
                            },
                            ["TL"] = {
                                "Hindi makakatayo hangga't hindi umiinom ng malinis.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.dehydration.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still parched and dizzy. Where is the water?",
                            },
                            ["TL"] = {
                                "Tuyot at nahihilo pa rin. Nasaan na ang tubig?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.dehydration.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Dehydration hasn't improved. I need fluids now.",
                            },
                            ["TL"] = {
                                "Hindi pa gumagaling ang dehydration. Kailangan ko ng inumin ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.dehydration.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still desperately thirsty. Bring a bottle over.",
                            },
                            ["TL"] = {
                                "Uhaw na uhaw pa rin ako. Dalhin mo ang bote rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.dehydration.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Throat is still locked up dry. Need water.",
                            },
                            ["TL"] = {
                                "Nakatuyot pa rin ang lalamunan ko. Kailangan ng tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.dehydration.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Can't make progress without hydration. Help me.",
                            },
                            ["TL"] = {
                                "Hindi makakausad nang walang tubig. Tulungan mo ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.dehydration.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still waiting on that drink. Feeling very weak.",
                            },
                            ["TL"] = {
                                "Naghihintay pa rin sa inumin. Sobrang nanghihina na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.dehydration.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Need fluids before my legs will work again.",
                            },
                            ["TL"] = {
                                "Kailangan ng inumin bago gumana ulit ang mga binti ko.",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_update.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_update",
        ["id"] = "semantic.medical.distress.update.exhaustion",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.update.exhaustion",
            ["sourcePath"] = "psdl/dialogue/medical_event_update.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/MedicalEventUpdate/Catalog",
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
                ["responseTemplateID"] = "semantic.medical.distress.update.exhaustion",
                ["sourceSurface"] = "content/event/medical/update.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.exhaustion.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I still need time to recover my strength.",
                            },
                            ["TL"] = {
                                "Kailangan ko pa ng oras para manumbalik ang lakas ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.exhaustion.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Stamina is still drained. Catching my breath.",
                            },
                            ["TL"] = {
                                "Ubos pa rin ang stamina. Humihinga pa rin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.exhaustion.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still exhausted. Give me a little more time.",
                            },
                            ["TL"] = {
                                "Pagod na pagod pa rin. Bigyan mo pa ako ng kaunting oras.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.exhaustion.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Muscles are still aching. Recovering slowly.",
                            },
                            ["TL"] = {
                                "Kumikirot pa rin ang kalamnan. Dahan-dahang nagpapagaling.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.exhaustion.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Lungs still burning from running. Give me a moment.",
                            },
                            ["TL"] = {
                                "Nasusunog pa rin ang baga sa pagtakbo. Bigyan mo ako ng saglit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.exhaustion.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Fatigue hasn't cleared yet. Still resting here.",
                            },
                            ["TL"] = {
                                "Hindi pa humuhupa ang pagod. Nagpapahinga pa rin dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.exhaustion.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Energy is very low. Still need a few breaths.",
                            },
                            ["TL"] = {
                                "Napakababa pa ng lakas. Kailangan pa ng ilang malalalim na hininga.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.exhaustion.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Legs are still shaking from exhaustion. Give me time.",
                            },
                            ["TL"] = {
                                "Nanginginig pa rin ang mga binti sa pagod. Bigyan mo ako ng oras.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.exhaustion.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still spent. Don't rush me to run again.",
                            },
                            ["TL"] = {
                                "Ubos pa rin. Huwag mo akong apurahin tumakbo ulit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.exhaustion.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Recharging my stamina. Just a little longer.",
                            },
                            ["TL"] = {
                                "Nagpapalakas ulit. Kaunti na lang.",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_update.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_update",
        ["id"] = "semantic.medical.distress.update.mercy",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.update.mercy",
            ["sourcePath"] = "psdl/dialogue/medical_event_update.json#records[5]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/MedicalEventUpdate/Catalog",
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
                ["responseTemplateID"] = "semantic.medical.distress.update.mercy",
                ["sourceSurface"] = "content/event/medical/update.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.mercy.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I am still down. Please do not finish me.",
                            },
                            ["TL"] = {
                                "Bagsak pa rin ako. Pakiusap huwag mo akong tapusin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.mercy.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still helpless here. Spare my life, please.",
                            },
                            ["TL"] = {
                                "Walang laban pa rin dito. Buhayin mo ako, pakiusap.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.mercy.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm still no threat to you. Please have mercy.",
                            },
                            ["TL"] = {
                                "Wala pa rin akong banta sa'yo. Pakiusap maawa ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.mercy.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still begging for survival. Don't hurt me.",
                            },
                            ["TL"] = {
                                "Nagmamakaawa pa rin para mabuhay. Huwag mo akong saktan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.mercy.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Plea remains: spare me and let me crawl away.",
                            },
                            ["TL"] = {
                                "Hiling ko pa rin: buhayin mo ako at hayaang gumapang palayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.mercy.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I surrender completely. Please do not execute me.",
                            },
                            ["TL"] = {
                                "Sumusuko ako nang buo. Pakiusap huwag mo akong patayin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.mercy.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still at your mercy. Please keep that weapon away.",
                            },
                            ["TL"] = {
                                "Nasa awa mo pa rin ako. Pakiusap ilayo mo ang sandata na 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.mercy.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I have surrendered. Don't strike a downed person.",
                            },
                            ["TL"] = {
                                "Sumuko na ako. Huwag kang manakit ng taong nakahandusay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.mercy.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Please honor your mercy. Don't kill me.",
                            },
                            ["TL"] = {
                                "Pakiusap tuparin mo ang awa mo. Huwag mo akong patayin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.mercy.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still alive, still pleading. Let me survive this.",
                            },
                            ["TL"] = {
                                "Buhay pa, nagmamakaawa pa rin. Hayaan mo akong makaraos dito.",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_update.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_update",
        ["id"] = "semantic.medical.distress.update.rescue",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.update.rescue",
            ["sourcePath"] = "psdl/dialogue/medical_event_update.json#records[6]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/MedicalEventUpdate/Catalog",
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
                ["responseTemplateID"] = "semantic.medical.distress.update.rescue",
                ["sourceSurface"] = "content/event/medical/update.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.rescue.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I am still here. Please come back for me.",
                            },
                            ["TL"] = {
                                "Nandito pa rin ako. Pakiusap balikan mo ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.rescue.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still trapped in place. Waiting for your rescue.",
                            },
                            ["TL"] = {
                                "Naipit pa rin sa pwesto. Naghihintay sa saklolo mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.rescue.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't leave me stranded! I'm still where you left me.",
                            },
                            ["TL"] = {
                                "Huwag mo akong iwang nastranded! Nandito pa rin ako sa iniwanan mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.rescue.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still cannot walk out alone. Come help me.",
                            },
                            ["TL"] = {
                                "Hindi pa rin makalabas nang mag-isa. Halika tulungan mo ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.rescue.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Waiting on rescue here. Hurry before dead arrive.",
                            },
                            ["TL"] = {
                                "Naghihintay ng saklolo rito. Bilisan mo bago dumating ang mga patay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.rescue.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still pinned down. Please extract me.",
                            },
                            ["TL"] = {
                                "Naiipit pa rin. Pakiusap hilahin mo ako palabas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.rescue.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't forget me here! Still need someone to pull me out.",
                            },
                            ["TL"] = {
                                "Huwag mo akong kalimutan dito! Kailangan pa rin ng maghihila sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.rescue.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Status unchanged: trapped and waiting for assistance.",
                            },
                            ["TL"] = {
                                "Walang pagbabago: naipit at naghihintay ng saklolo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.rescue.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still waiting for someone to drag me to safety.",
                            },
                            ["TL"] = {
                                "Naghihintay pa rin ng hihila sa akin sa ligtas na lugar.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.rescue.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm still right here. Please don't leave me behind.",
                            },
                            ["TL"] = {
                                "Nandito lang ako. Pakiusap huwag mo akong iwan.",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_update.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "medical_event_update",
        ["id"] = "semantic.medical.distress.update.starvation",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.medical.distress.update.starvation",
            ["sourcePath"] = "psdl/dialogue/medical_event_update.json#records[7]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/MedicalEventUpdate/Catalog",
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
                ["responseTemplateID"] = "semantic.medical.distress.update.starvation",
                ["sourceSurface"] = "content/event/medical/update.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "MEDICAL_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.starvation.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I still need food before I can get up.",
                            },
                            ["TL"] = {
                                "Kailangan ko pa rin ng pagkain bago makatayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.starvation.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Starvation is worsening. Did you find anything edible?",
                            },
                            ["TL"] = {
                                "Lumalala ang gutom ko. May nahanap ka bang makakain?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.starvation.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still too weak from hunger to stand.",
                            },
                            ["TL"] = {
                                "Nanghihina pa rin sa gutom para makatayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.starvation.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Can't move on an empty stomach. Bring food.",
                            },
                            ["TL"] = {
                                "Hindi makakilos nang walang laman ang tiyan. Dalhan mo ako ng pagkain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.starvation.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still starving on the floor. Please bring a ration.",
                            },
                            ["TL"] = {
                                "Nagugutom pa rin sa sahig. Pakiusap dalhan mo ako ng rasyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.starvation.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Body needs calories right now. I'm fading.",
                            },
                            ["TL"] = {
                                "Kailangan ng katawan ng pagkain ngayon din. Nanghihina na ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.starvation.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still waiting for a meal. Stomach cramps are brutal.",
                            },
                            ["TL"] = {
                                "Naghihintay pa rin ng pagkain. Matindi ang pulikat ng tiyan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.starvation.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Can't regain strength without food. Help me.",
                            },
                            ["TL"] = {
                                "Hindi maibabalik ang lakas nang walang pagkain. Tulungan mo ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.starvation.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still starving here. Any can of beans or soup?",
                            },
                            ["TL"] = {
                                "Gutom pa rin ako rito. May de-latang beans ba o sabaw?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.medical.distress.update.starvation.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Need nourishment before I can take a step.",
                            },
                            ["TL"] = {
                                "Kailangan ko ng makakain bago ako makahakbang.",
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
        ["sourceShard"] = "psdl/dialogue/medical_event_update.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
