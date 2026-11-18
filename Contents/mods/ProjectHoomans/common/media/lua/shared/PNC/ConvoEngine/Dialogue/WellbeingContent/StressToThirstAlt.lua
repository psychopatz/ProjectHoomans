-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "wellbeing_content",
        ["domainPath"] = "wellbeing_content",
        ["exchangeFamily"] = {
            ["familyID"] = "question.wellbeing.stress",
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
                                ["fallback"] = "I'm tense, but I can keep going.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.question.wellbeing.stress.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'm tense, but I can keep going.",
                                        "Nerves are frayed. The tension is getting to me.",
                                        "Feeling the pressure constantly out here.",
                                        "On edge, jumping at every shadow.",
                                        "Stress is wearing me down faster than the walking.",
                                        "Hard to unwind when danger could be anywhere.",
                                        "My shoulders are tight as iron from all this stress.",
                                        "Just trying to keep my sanity intact.",
                                        "Every little noise has me reaching for my weapon.",
                                        "It's a lot to process, but I'm holding it in.",
                                    },
                                    ["TL"] = {
                                        "Tensiyonado ako, pero kaya ko pa.",
                                        "Naiipit ang mga nerbyos ko. Ramdam ko ang tensiyon.",
                                        "Laging mabigat ang pakiramdam dito sa labas.",
                                        "Kabado ako, nabibigla sa bawat anino.",
                                        "Mas nakakapagod ang stress kaysa sa mismong paglalakad.",
                                        "Mahirap magrelaks kapag may panganib kahit saan.",
                                        "Mabigat ang mga balikat ko sa sobrang stress.",
                                        "Pinipilit ko lang mapanatili ang katinuan ko.",
                                        "Bawat kaluskos napapahawak ako agad sa armas ko.",
                                        "Mabigat dalhin ang lahat, pero tinitiis ko.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.wellbeing",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'm tense, but I can keep going.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.stress.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I'm tense, but I can keep going.",
                            "Nerves are frayed. The tension is getting to me.",
                            "Feeling the pressure constantly out here.",
                            "On edge, jumping at every shadow.",
                            "Stress is wearing me down faster than the walking.",
                            "Hard to unwind when danger could be anywhere.",
                            "My shoulders are tight as iron from all this stress.",
                            "Just trying to keep my sanity intact.",
                            "Every little noise has me reaching for my weapon.",
                            "It's a lot to process, but I'm holding it in.",
                        },
                        ["TL"] = {
                            "Tensiyonado ako, pero kaya ko pa.",
                            "Naiipit ang mga nerbyos ko. Ramdam ko ang tensiyon.",
                            "Laging mabigat ang pakiramdam dito sa labas.",
                            "Kabado ako, nabibigla sa bawat anino.",
                            "Mas nakakapagod ang stress kaysa sa mismong paglalakad.",
                            "Mahirap magrelaks kapag may panganib kahit saan.",
                            "Mabigat ang mga balikat ko sa sobrang stress.",
                            "Pinipilit ko lang mapanatili ang katinuan ko.",
                            "Bawat kaluskos napapahawak ako agad sa armas ko.",
                            "Mabigat dalhin ang lahat, pero tinitiis ko.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "question.wellbeing.stress",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "stress",
            ["sourceId"] = "question.wellbeing.stress",
            ["sourcePath"] = "dialogue/wellbeing_content/question_wellbeing_stress.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/WellbeingContent/StressToThirstAlt",
        ["namespace"] = "question.wellbeing",
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
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseAct"] = "REACT",
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
                                        "I'm tense, but I can keep going.",
                                        "Nerves are frayed. The tension is getting to me.",
                                        "Feeling the pressure constantly out here.",
                                        "On edge, jumping at every shadow.",
                                        "Stress is wearing me down faster than the walking.",
                                        "Hard to unwind when danger could be anywhere.",
                                        "My shoulders are tight as iron from all this stress.",
                                        "Just trying to keep my sanity intact.",
                                        "Every little noise has me reaching for my weapon.",
                                        "It's a lot to process, but I'm holding it in.",
                                    },
                                    ["TL"] = {
                                        "Tensiyonado ako, pero kaya ko pa.",
                                        "Naiipit ang mga nerbyos ko. Ramdam ko ang tensiyon.",
                                        "Laging mabigat ang pakiramdam dito sa labas.",
                                        "Kabado ako, nabibigla sa bawat anino.",
                                        "Mas nakakapagod ang stress kaysa sa mismong paglalakad.",
                                        "Mahirap magrelaks kapag may panganib kahit saan.",
                                        "Mabigat ang mga balikat ko sa sobrang stress.",
                                        "Pinipilit ko lang mapanatili ang katinuan ko.",
                                        "Bawat kaluskos napapahawak ako agad sa armas ko.",
                                        "Mabigat dalhin ang lahat, pero tinitiis ko.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "social_interaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.wellbeing.stress",
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
                            ["fallback"] = "I'm tense, but I can keep going.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.wellbeing.stress.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/wellbeing_content/question_wellbeing_stress.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'm tense, but I can keep going.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.stress.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I'm tense, but I can keep going.",
                        "Nerves are frayed. The tension is getting to me.",
                        "Feeling the pressure constantly out here.",
                        "On edge, jumping at every shadow.",
                        "Stress is wearing me down faster than the walking.",
                        "Hard to unwind when danger could be anywhere.",
                        "My shoulders are tight as iron from all this stress.",
                        "Just trying to keep my sanity intact.",
                        "Every little noise has me reaching for my weapon.",
                        "It's a lot to process, but I'm holding it in.",
                    },
                    ["TL"] = {
                        "Tensiyonado ako, pero kaya ko pa.",
                        "Naiipit ang mga nerbyos ko. Ramdam ko ang tensiyon.",
                        "Laging mabigat ang pakiramdam dito sa labas.",
                        "Kabado ako, nabibigla sa bawat anino.",
                        "Mas nakakapagod ang stress kaysa sa mismong paglalakad.",
                        "Mahirap magrelaks kapag may panganib kahit saan.",
                        "Mabigat ang mga balikat ko sa sobrang stress.",
                        "Pinipilit ko lang mapanatili ang katinuan ko.",
                        "Bawat kaluskos napapahawak ako agad sa armas ko.",
                        "Mabigat dalhin ang lahat, pero tinitiis ko.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "wellbeing_content",
        ["domainPath"] = "wellbeing_content",
        ["exchangeFamily"] = {
            ["familyID"] = "question.wellbeing.thirst",
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
                                ["fallback"] = "I'm pretty thirsty. Could you spare some water?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.question.wellbeing.thirst.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'm pretty thirsty. Could you spare some water?",
                                        "My throat feels parched. Got any clean water?",
                                        "Really need a drink soon. Starting to feel dehydrated.",
                                        "Could use a sip of water if you've got any to share.",
                                        "Thirst is really slowing me down today.",
                                        "My canteen ran dry a while back. Got any water?",
                                        "Desperate for a drink of fresh water right now.",
                                        "My mouth is bone dry. Can you spare a few drops?",
                                        "Need water before my headache gets any worse.",
                                        "Any spare water bottle on you? I'm drying up.",
                                    },
                                    ["TL"] = {
                                        "Uhaw na uhaw ako. Maaari ba akong makahingi ng tubig?",
                                        "Tuyong-tuyo ang lalamunan ko. May malinis ka bang tubig?",
                                        "Kailangan ko na talagang uminom. Nauuhaw na ako nang husto.",
                                        "Kailangan ko ng kahit kaunting lagok ng tubig kung mayroon ka.",
                                        "Pinapabagal talaga ako ng uhaw ngayong araw.",
                                        "Natuyo na ang lalagyan ko kanina pa. May tubig ka ba?",
                                        "Kailangang-kailangan ko ng maiinom na sariwang tubig ngayon.",
                                        "Tuyot na tuyot ang bibig ko. Makakahingi ba ng kaunting tubig?",
                                        "Kailangan ko ng tubig bago pa sumakit ang ulo ko sa uhaw.",
                                        "May sobra ka bang botelya ng tubig? Uhaw na uhaw na ako.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.wellbeing",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'm pretty thirsty. Could you spare some water?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.thirst.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I'm pretty thirsty. Could you spare some water?",
                            "My throat feels parched. Got any clean water?",
                            "Really need a drink soon. Starting to feel dehydrated.",
                            "Could use a sip of water if you've got any to share.",
                            "Thirst is really slowing me down today.",
                            "My canteen ran dry a while back. Got any water?",
                            "Desperate for a drink of fresh water right now.",
                            "My mouth is bone dry. Can you spare a few drops?",
                            "Need water before my headache gets any worse.",
                            "Any spare water bottle on you? I'm drying up.",
                        },
                        ["TL"] = {
                            "Uhaw na uhaw ako. Maaari ba akong makahingi ng tubig?",
                            "Tuyong-tuyo ang lalamunan ko. May malinis ka bang tubig?",
                            "Kailangan ko na talagang uminom. Nauuhaw na ako nang husto.",
                            "Kailangan ko ng kahit kaunting lagok ng tubig kung mayroon ka.",
                            "Pinapabagal talaga ako ng uhaw ngayong araw.",
                            "Natuyo na ang lalagyan ko kanina pa. May tubig ka ba?",
                            "Kailangang-kailangan ko ng maiinom na sariwang tubig ngayon.",
                            "Tuyot na tuyot ang bibig ko. Makakahingi ba ng kaunting tubig?",
                            "Kailangan ko ng tubig bago pa sumakit ang ulo ko sa uhaw.",
                            "May sobra ka bang botelya ng tubig? Uhaw na uhaw na ako.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "question.wellbeing.thirst",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "thirst",
            ["sourceId"] = "question.wellbeing.thirst",
            ["sourcePath"] = "dialogue/wellbeing_content/question_wellbeing_thirst.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/WellbeingContent/StressToThirstAlt",
        ["namespace"] = "question.wellbeing",
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
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseAct"] = "REACT",
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
                                        "I'm pretty thirsty. Could you spare some water?",
                                        "My throat feels parched. Got any clean water?",
                                        "Really need a drink soon. Starting to feel dehydrated.",
                                        "Could use a sip of water if you've got any to share.",
                                        "Thirst is really slowing me down today.",
                                        "My canteen ran dry a while back. Got any water?",
                                        "Desperate for a drink of fresh water right now.",
                                        "My mouth is bone dry. Can you spare a few drops?",
                                        "Need water before my headache gets any worse.",
                                        "Any spare water bottle on you? I'm drying up.",
                                    },
                                    ["TL"] = {
                                        "Uhaw na uhaw ako. Maaari ba akong makahingi ng tubig?",
                                        "Tuyong-tuyo ang lalamunan ko. May malinis ka bang tubig?",
                                        "Kailangan ko na talagang uminom. Nauuhaw na ako nang husto.",
                                        "Kailangan ko ng kahit kaunting lagok ng tubig kung mayroon ka.",
                                        "Pinapabagal talaga ako ng uhaw ngayong araw.",
                                        "Natuyo na ang lalagyan ko kanina pa. May tubig ka ba?",
                                        "Kailangang-kailangan ko ng maiinom na sariwang tubig ngayon.",
                                        "Tuyot na tuyot ang bibig ko. Makakahingi ba ng kaunting tubig?",
                                        "Kailangan ko ng tubig bago pa sumakit ang ulo ko sa uhaw.",
                                        "May sobra ka bang botelya ng tubig? Uhaw na uhaw na ako.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "social_interaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.wellbeing.thirst",
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
                            ["fallback"] = "I'm pretty thirsty. Could you spare some water?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.wellbeing.thirst.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/wellbeing_content/question_wellbeing_thirst.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'm pretty thirsty. Could you spare some water?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.thirst.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I'm pretty thirsty. Could you spare some water?",
                        "My throat feels parched. Got any clean water?",
                        "Really need a drink soon. Starting to feel dehydrated.",
                        "Could use a sip of water if you've got any to share.",
                        "Thirst is really slowing me down today.",
                        "My canteen ran dry a while back. Got any water?",
                        "Desperate for a drink of fresh water right now.",
                        "My mouth is bone dry. Can you spare a few drops?",
                        "Need water before my headache gets any worse.",
                        "Any spare water bottle on you? I'm drying up.",
                    },
                    ["TL"] = {
                        "Uhaw na uhaw ako. Maaari ba akong makahingi ng tubig?",
                        "Tuyong-tuyo ang lalamunan ko. May malinis ka bang tubig?",
                        "Kailangan ko na talagang uminom. Nauuhaw na ako nang husto.",
                        "Kailangan ko ng kahit kaunting lagok ng tubig kung mayroon ka.",
                        "Pinapabagal talaga ako ng uhaw ngayong araw.",
                        "Natuyo na ang lalagyan ko kanina pa. May tubig ka ba?",
                        "Kailangang-kailangan ko ng maiinom na sariwang tubig ngayon.",
                        "Tuyot na tuyot ang bibig ko. Makakahingi ba ng kaunting tubig?",
                        "Kailangan ko ng tubig bago pa sumakit ang ulo ko sa uhaw.",
                        "May sobra ka bang botelya ng tubig? Uhaw na uhaw na ako.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "wellbeing_content",
        ["domainPath"] = "wellbeing_content",
        ["exchangeFamily"] = {
            ["familyID"] = "question.wellbeing.thirst_alt",
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
                                ["fallback"] = "I could really use a drink. Do you have any water?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.question.wellbeing.thirst_alt.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I could really use a drink. Do you have any water?",
                                        "Dying for a drink of water out here.",
                                        "Throat is scratching with thirst. Got a bottle?",
                                        "Would give almost anything for a cold sip right now.",
                                        "Looking for clean water everywhere. Got any to spare?",
                                        "Dehydration is starting to set in. Water would help immensely.",
                                        "Got a spare flask of water? My tongue feels like sandpaper.",
                                        "Can't go much further without something to drink.",
                                        "Just a small swallow of water would keep me going.",
                                        "My lips are chapped from thirst. Spare any water?",
                                    },
                                    ["TL"] = {
                                        "Kailangan ko talaga ng maiinom. May tubig ka ba?",
                                        "Gusto ko na talagang makainom ng tubig dito sa init.",
                                        "Makati na ang lalamunan ko sa uhaw. May botelya ka ba?",
                                        "Kahit ano ibibigay ko para sa malamig na lagok ng tubig ngayon.",
                                        "Naghahanap ako ng malinis na tubig kung saan-saan. May sobra ka?",
                                        "Inaabutan na ako ng dehydration. Malaking tulong ang tubig.",
                                        "May sobra ka bang lalagyan ng tubig? Parang liha na ang dila ko.",
                                        "Hindi na ako makakalayo kapag walang maiinom.",
                                        "Kahit isang lagok lang ng tubig makakatulong na sa akin.",
                                        "Bitak-bitak na ang labi ko sa uhaw. Pahingi naman ng tubig?",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.wellbeing",
            ["textRoles"] = {
                {
                    ["fallback"] = "I could really use a drink. Do you have any water?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing.thirst_alt.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I could really use a drink. Do you have any water?",
                            "Dying for a drink of water out here.",
                            "Throat is scratching with thirst. Got a bottle?",
                            "Would give almost anything for a cold sip right now.",
                            "Looking for clean water everywhere. Got any to spare?",
                            "Dehydration is starting to set in. Water would help immensely.",
                            "Got a spare flask of water? My tongue feels like sandpaper.",
                            "Can't go much further without something to drink.",
                            "Just a small swallow of water would keep me going.",
                            "My lips are chapped from thirst. Spare any water?",
                        },
                        ["TL"] = {
                            "Kailangan ko talaga ng maiinom. May tubig ka ba?",
                            "Gusto ko na talagang makainom ng tubig dito sa init.",
                            "Makati na ang lalamunan ko sa uhaw. May botelya ka ba?",
                            "Kahit ano ibibigay ko para sa malamig na lagok ng tubig ngayon.",
                            "Naghahanap ako ng malinis na tubig kung saan-saan. May sobra ka?",
                            "Inaabutan na ako ng dehydration. Malaking tulong ang tubig.",
                            "May sobra ka bang lalagyan ng tubig? Parang liha na ang dila ko.",
                            "Hindi na ako makakalayo kapag walang maiinom.",
                            "Kahit isang lagok lang ng tubig makakatulong na sa akin.",
                            "Bitak-bitak na ang labi ko sa uhaw. Pahingi naman ng tubig?",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "question.wellbeing.thirst_alt",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "thirst_alt",
            ["sourceId"] = "question.wellbeing.thirst_alt",
            ["sourcePath"] = "dialogue/wellbeing_content/question_wellbeing_thirst_alt.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/WellbeingContent/StressToThirstAlt",
        ["namespace"] = "question.wellbeing",
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
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseAct"] = "REACT",
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
                                        "I could really use a drink. Do you have any water?",
                                        "Dying for a drink of water out here.",
                                        "Throat is scratching with thirst. Got a bottle?",
                                        "Would give almost anything for a cold sip right now.",
                                        "Looking for clean water everywhere. Got any to spare?",
                                        "Dehydration is starting to set in. Water would help immensely.",
                                        "Got a spare flask of water? My tongue feels like sandpaper.",
                                        "Can't go much further without something to drink.",
                                        "Just a small swallow of water would keep me going.",
                                        "My lips are chapped from thirst. Spare any water?",
                                    },
                                    ["TL"] = {
                                        "Kailangan ko talaga ng maiinom. May tubig ka ba?",
                                        "Gusto ko na talagang makainom ng tubig dito sa init.",
                                        "Makati na ang lalamunan ko sa uhaw. May botelya ka ba?",
                                        "Kahit ano ibibigay ko para sa malamig na lagok ng tubig ngayon.",
                                        "Naghahanap ako ng malinis na tubig kung saan-saan. May sobra ka?",
                                        "Inaabutan na ako ng dehydration. Malaking tulong ang tubig.",
                                        "May sobra ka bang lalagyan ng tubig? Parang liha na ang dila ko.",
                                        "Hindi na ako makakalayo kapag walang maiinom.",
                                        "Kahit isang lagok lang ng tubig makakatulong na sa akin.",
                                        "Bitak-bitak na ang labi ko sa uhaw. Pahingi naman ng tubig?",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "social_interaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.wellbeing.thirst_alt",
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
                            ["fallback"] = "I could really use a drink. Do you have any water?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.wellbeing.thirst_alt.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/wellbeing_content/question_wellbeing_thirst_alt.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I could really use a drink. Do you have any water?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing.thirst_alt.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I could really use a drink. Do you have any water?",
                        "Dying for a drink of water out here.",
                        "Throat is scratching with thirst. Got a bottle?",
                        "Would give almost anything for a cold sip right now.",
                        "Looking for clean water everywhere. Got any to spare?",
                        "Dehydration is starting to set in. Water would help immensely.",
                        "Got a spare flask of water? My tongue feels like sandpaper.",
                        "Can't go much further without something to drink.",
                        "Just a small swallow of water would keep me going.",
                        "My lips are chapped from thirst. Spare any water?",
                    },
                    ["TL"] = {
                        "Kailangan ko talaga ng maiinom. May tubig ka ba?",
                        "Gusto ko na talagang makainom ng tubig dito sa init.",
                        "Makati na ang lalamunan ko sa uhaw. May botelya ka ba?",
                        "Kahit ano ibibigay ko para sa malamig na lagok ng tubig ngayon.",
                        "Naghahanap ako ng malinis na tubig kung saan-saan. May sobra ka?",
                        "Inaabutan na ako ng dehydration. Malaking tulong ang tubig.",
                        "May sobra ka bang lalagyan ng tubig? Parang liha na ang dila ko.",
                        "Hindi na ako makakalayo kapag walang maiinom.",
                        "Kahit isang lagok lang ng tubig makakatulong na sa akin.",
                        "Bitak-bitak na ang labi ko sa uhaw. Pahingi naman ng tubig?",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
