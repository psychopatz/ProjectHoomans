-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "wellbeing_content",
        ["id"] = "semantic.question.wellbeing.dataset.getting_by.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.wellbeing.dataset.getting_by.guarded",
            ["sourcePath"] = "psdl/dialogue/wellbeing_content.json#records[6]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/WellbeingContent/Catalog",
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
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseTemplateID"] = "semantic.question.wellbeing.dataset.getting_by",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/wellbeing/general.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm getting by. Leave it there.",
                            },
                            ["TL"] = {
                                "Kinakaya ko. Tama na iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Surviving. That's all you need to know.",
                            },
                            ["TL"] = {
                                "Nabubuhay pa. Iyon lang ang kailangan mong malaman.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "I manage on my own. Don't worry about it.",
                            },
                            ["TL"] = {
                                "Kaya ko ang sarili ko. Huwag mo nang alalahanin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Still upright. Let's keep it to business.",
                            },
                            ["TL"] = {
                                "Nakatayo pa rin. Manatili tayo sa pakay natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "I'm coping fine. No need to pry.",
                            },
                            ["TL"] = {
                                "Maayos ang lagay ko. Hindi kailangang mag-usisa.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Doing what I have to do. That's enough.",
                            },
                            ["TL"] = {
                                "Ginagawa ang dapat gawin. Sapat na 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Still breathing. Nothing more to say about it.",
                            },
                            ["TL"] = {
                                "Huminga pa. Wala nang iba pang sasabihin tungkol doon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'm alright on my own, thanks.",
                            },
                            ["TL"] = {
                                "Ayos lang ako sa sarili ko, salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Managing well enough without interference.",
                            },
                            ["TL"] = {
                                "Kinakaya nang maayos nang walang nangingialam.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Getting by just fine. Let's drop it.",
                            },
                            ["TL"] = {
                                "Kinakaya ko nang maayos. Hayaan na natin.",
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
        ["sourceShard"] = "psdl/dialogue/wellbeing_content.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "wellbeing_content",
        ["id"] = "semantic.question.wellbeing.dataset.getting_by.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.wellbeing.dataset.getting_by.neutral",
            ["sourcePath"] = "psdl/dialogue/wellbeing_content.json#records[7]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/WellbeingContent/Catalog",
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
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseTemplateID"] = "semantic.question.wellbeing.dataset.getting_by",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/wellbeing/general.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm getting by, one day at a time. How about you?",
                            },
                            ["TL"] = {
                                "Kinakaya ko, isang araw bawat pagkakataon. Ikaw?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Managing as best as anyone can out here. You?",
                            },
                            ["TL"] = {
                                "Kinakaya gaya ng sinuman dito sa labas. Ikaw?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Can't complain too much. Taking things as they come.",
                            },
                            ["TL"] = {
                                "Hindi naman masyadong makapagreklamo. Tinitiis bawat araw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Still on my feet. That's a win these days.",
                            },
                            ["TL"] = {
                                "Nakatayo pa rin. Malaking bagay na 'yon sa panahong ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Holding up okay. How are things on your side?",
                            },
                            ["TL"] = {
                                "Maayos naman. Kumusta ang lagay sa parte mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Getting through the hours. What about yourself?",
                            },
                            ["TL"] = {
                                "Nakakaraos sa bawat oras. Kumusta naman ikaw?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Doing alright, all things considered.",
                            },
                            ["TL"] = {
                                "Maayos naman, sa kabila ng lahat ng nangyayari.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Pushing forward. How's the road treating you?",
                            },
                            ["TL"] = {
                                "Sumusulong pa rin. Kumusta ang biyahe mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Hanging in there. Hopefully you are too.",
                            },
                            ["TL"] = {
                                "Kumakapit pa rin. Sana ikaw rin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Alive and kicking. What more can we ask for?",
                            },
                            ["TL"] = {
                                "Buhay at lumalaban. Ano pa bang mahihiling natin?",
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
        ["sourceShard"] = "psdl/dialogue/wellbeing_content.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "wellbeing_content",
        ["id"] = "semantic.question.wellbeing.dataset.getting_by.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.wellbeing.dataset.getting_by.terse",
            ["sourcePath"] = "psdl/dialogue/wellbeing_content.json#records[8]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/WellbeingContent/Catalog",
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
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseTemplateID"] = "semantic.question.wellbeing.dataset.getting_by",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/wellbeing/general.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "Getting by.",
                            },
                            ["TL"] = {
                                "Kinakaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Managing.",
                            },
                            ["TL"] = {
                                "Kinakaya pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Still standing.",
                            },
                            ["TL"] = {
                                "Nakatayo pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Holding.",
                            },
                            ["TL"] = {
                                "Matatag pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Surviving.",
                            },
                            ["TL"] = {
                                "Nabubuhay.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Fine for now.",
                            },
                            ["TL"] = {
                                "Ayos sa ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Still breathing.",
                            },
                            ["TL"] = {
                                "Huminga pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Could be worse.",
                            },
                            ["TL"] = {
                                "Puwede namang mas malala.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Doing fine.",
                            },
                            ["TL"] = {
                                "Maayos naman.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "One day at a time.",
                            },
                            ["TL"] = {
                                "Araw-araw lang.",
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
        ["sourceShard"] = "psdl/dialogue/wellbeing_content.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "wellbeing_content",
        ["id"] = "semantic.question.wellbeing.dataset.getting_by.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.wellbeing.dataset.getting_by.warm",
            ["sourcePath"] = "psdl/dialogue/wellbeing_content.json#records[9]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/WellbeingContent/Catalog",
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
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseTemplateID"] = "semantic.question.wellbeing.dataset.getting_by",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/wellbeing/general.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm getting by. Thanks for asking.",
                            },
                            ["TL"] = {
                                "Kinakaya ko. Salamat sa pagtatanong.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Doing okay, especially with good company around.",
                            },
                            ["TL"] = {
                                "Maayos naman ako, lalo na at may kasamang maaasahan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Managing well enough. Truly appreciate you checking in.",
                            },
                            ["TL"] = {
                                "Kinakaya naman. Salamat talaga sa pangangamusta.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Holding steady. Knowing people care makes it easier.",
                            },
                            ["TL"] = {
                                "Matatag pa rin. Mas madali kapag may nagmamalasakit.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Doing alright today. Hope you're feeling good too.",
                            },
                            ["TL"] = {
                                "Maayos ang araw ko. Sana maganda rin ang pakiramdam mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'm hanging in there. Thank you for thinking of me.",
                            },
                            ["TL"] = {
                                "Kumakapit pa rin. Salamat sa pag-alala sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Feeling decent today, thank you. How are you holding up?",
                            },
                            ["TL"] = {
                                "Medyo maayos ang pakiramdam ko ngayon, salamat. Ikaw?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "Getting through it together. That's what counts.",
                            },
                            ["TL"] = {
                                "Sama-sama nating nalalagpasan ito. Iyon ang mahalaga.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Still smiling through it all. Glad to see you around.",
                            },
                            ["TL"] = {
                                "Nakangiti pa rin sa kabila ng lahat. Masaya akong nandito ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "I'm doing well, friend. Thanks for taking the time to ask.",
                            },
                            ["TL"] = {
                                "Maayos ako, kaibigan. Salamat sa paglalaan ng oras magtanong.",
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
        ["sourceShard"] = "psdl/dialogue/wellbeing_content.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "wellbeing_content",
        ["id"] = "semantic.question.wellbeing.default.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.wellbeing.default.guarded",
            ["sourcePath"] = "psdl/dialogue/wellbeing_content.json#records[10]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/WellbeingContent/Catalog",
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
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseTemplateID"] = "semantic.question.wellbeing.default",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/wellbeing/general.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm managing. Don't press me.",
                            },
                            ["TL"] = {
                                "Kinakaya ko. Huwag mo nang ipilit.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "I'm fine. Keep your focus on your own work.",
                            },
                            ["TL"] = {
                                "Ayos lang ako. Ituon mo ang pansin sa sarili mong gawain.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "No problems here. That's all you get.",
                            },
                            ["TL"] = {
                                "Walang problema rito. Iyon lang ang masasabi ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "I can look after myself. No need to inquire.",
                            },
                            ["TL"] = {
                                "Kaya kong alagaan ang sarili ko. Huwag nang magtanong.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Doing what needs doing. Back off a bit.",
                            },
                            ["TL"] = {
                                "Ginagawa ang kailangang gawin. Lumayo ka nang kaunti.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "I don't discuss personal matters easily.",
                            },
                            ["TL"] = {
                                "Hindi ako basta-basta nagkukuwento tungkol sa sarili ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Healthy enough to defend myself. That's enough.",
                            },
                            ["TL"] = {
                                "Kaya ko pang ipagtanggol ang sarili ko. Sapat na 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Nothing to complain about to strangers.",
                            },
                            ["TL"] = {
                                "Walang dapat ireklamo sa mga hindi ko kakilala.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'm alright. Mind your own perimeter.",
                            },
                            ["TL"] = {
                                "Ayos lang ako. Bantayan mo ang sarili mong parte.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Alive and alert. Leave it at that.",
                            },
                            ["TL"] = {
                                "Buhay at alerto. Hanggang doon na lang.",
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
        ["sourceShard"] = "psdl/dialogue/wellbeing_content.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "wellbeing_content",
        ["id"] = "semantic.question.wellbeing.default.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.wellbeing.default.neutral",
            ["sourcePath"] = "psdl/dialogue/wellbeing_content.json#records[11]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/WellbeingContent/Catalog",
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
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseTemplateID"] = "semantic.question.wellbeing.default",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/wellbeing/general.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm okay. How about you?",
                            },
                            ["TL"] = {
                                "Okay naman ako. Ikaw, kumusta?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Doing alright. How are you holding up?",
                            },
                            ["TL"] = {
                                "Maayos naman. Paano mo nakakayanan?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Not bad at all. How's your day going?",
                            },
                            ["TL"] = {
                                "Hindi naman masama. Kumusta ang araw mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I'm doing fine. Hope things are quiet for you.",
                            },
                            ["TL"] = {
                                "Maayos naman ako. Sana payapa rin sa parte mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Pretty good, considering. You doing alright?",
                            },
                            ["TL"] = {
                                "Medyo maganda naman ang lagay. Maayos ka rin ba?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Still here and kicking. How about yourself?",
                            },
                            ["TL"] = {
                                "Nandito pa rin at lumalaban. Kumusta ka naman?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Things are stable enough on my end. You?",
                            },
                            ["TL"] = {
                                "Medyo maayos naman ang sitwasyon sa akin. Ikaw?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'm managing well. Hope you're staying safe.",
                            },
                            ["TL"] = {
                                "Maayos akong nakakaraos. Sana ligtas ka rin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Can't complain too much today. How're you?",
                            },
                            ["TL"] = {
                                "Hindi masyadong makapagreklamo ngayon. Kumusta ka?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Holding steady. How have you been holding up?",
                            },
                            ["TL"] = {
                                "Matatag pa rin. Kumusta ang pag-iingat mo?",
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
        ["sourceShard"] = "psdl/dialogue/wellbeing_content.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "wellbeing_content",
        ["id"] = "semantic.question.wellbeing.default.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.wellbeing.default.terse",
            ["sourcePath"] = "psdl/dialogue/wellbeing_content.json#records[12]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/WellbeingContent/Catalog",
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
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseTemplateID"] = "semantic.question.wellbeing.default",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/wellbeing/general.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm okay.",
                            },
                            ["TL"] = {
                                "Ayos lang ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Doing fine.",
                            },
                            ["TL"] = {
                                "Maayos naman.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "All good.",
                            },
                            ["TL"] = {
                                "Lahat maayos.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Holding up.",
                            },
                            ["TL"] = {
                                "Kinakaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "No issues.",
                            },
                            ["TL"] = {
                                "Walang problema.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Steady.",
                            },
                            ["TL"] = {
                                "Matatag.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Still on my feet.",
                            },
                            ["TL"] = {
                                "Nakatayo pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Fine.",
                            },
                            ["TL"] = {
                                "Ayos.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Alive.",
                            },
                            ["TL"] = {
                                "Buhay.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Managing fine.",
                            },
                            ["TL"] = {
                                "Maayos ang lagay.",
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
        ["sourceShard"] = "psdl/dialogue/wellbeing_content.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "wellbeing_content",
        ["id"] = "semantic.question.wellbeing.default.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.wellbeing.default.warm",
            ["sourcePath"] = "psdl/dialogue/wellbeing_content.json#records[13]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/WellbeingContent/Catalog",
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
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseTemplateID"] = "semantic.question.wellbeing.default",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/wellbeing/general.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm doing okay. Thanks for asking.",
                            },
                            ["TL"] = {
                                "Ayos lang ako. Salamat sa pagtatanong.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Doing well! It really warms my heart that you asked.",
                            },
                            ["TL"] = {
                                "Maayos ako! Nakakagaan ng loob na nagtanong ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Feeling pretty good today. How about yourself?",
                            },
                            ["TL"] = {
                                "Maganda ang pakiramdam ko ngayon. Kumusta ka naman?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "I'm hanging in there, friend. Glad to see you around.",
                            },
                            ["TL"] = {
                                "Kumakapit pa rin, kaibigan. Masayang makita ka rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Doing much better now that I see a friendly face.",
                            },
                            ["TL"] = {
                                "Mas gumaan ang pakiramdam ko ngayong nakakita ako ng kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "All is well on my side. Thank you for looking out for me.",
                            },
                            ["TL"] = {
                                "Maayos ang lahat sa akin. Salamat sa pag-alala mo sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Holding strong. Your support means a lot out here.",
                            },
                            ["TL"] = {
                                "Matatag pa rin. Malaking tulong ang suporta mo rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "Doing great today, thank you. Hope you are as well.",
                            },
                            ["TL"] = {
                                "Napakaganda ng araw ko, salamat. Sana ikaw rin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'm in good spirits today. It's lovely seeing you.",
                            },
                            ["TL"] = {
                                "Maganda ang disposisyon ko ngayon. Masarap kang makita.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Doing just fine. Let's make sure we both stay that way.",
                            },
                            ["TL"] = {
                                "Maayos naman ako. Siguraduhin nating pareho tayong ligtas.",
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
        ["sourceShard"] = "psdl/dialogue/wellbeing_content.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "wellbeing_content",
        ["id"] = "semantic.question.wellbeing.fatigue.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.wellbeing.fatigue.neutral",
            ["sourcePath"] = "psdl/dialogue/wellbeing_content.json#records[14]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/WellbeingContent/Catalog",
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
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseTemplateID"] = "semantic.question.wellbeing.fatigue",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/wellbeing/needs.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm worn out, but I can still manage.",
                            },
                            ["TL"] = {
                                "Pagod na pagod ako, pero kaya ko pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "My limbs feel heavy. I've been on my feet too long.",
                            },
                            ["TL"] = {
                                "Mabigat ang mga binti ko. Napakatagal ko nang nakatayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Could definitely use a breather soon.",
                            },
                            ["TL"] = {
                                "Kailangan ko na talagang makapagpahinga sandali.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Running on fumes right now, but I'll push through.",
                            },
                            ["TL"] = {
                                "Ubos na ang lakas ko, pero pipilitin kong magpatuloy.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Need to catch my breath before the next run.",
                            },
                            ["TL"] = {
                                "Kailangang makabawi ng hininga bago ang susunod na lakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Feeling exhausted, to be honest with you.",
                            },
                            ["TL"] = {
                                "Sobrang pagod na ako, sa totoo lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "My body is aching for some decent sleep.",
                            },
                            ["TL"] = {
                                "Sumasakit na ang buong katawan ko sa puyat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'm drained, but I won't drop my guard.",
                            },
                            ["TL"] = {
                                "Puyat at pagod ako, pero hindi ako magpapabaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "A quick sit-down would do wonders right now.",
                            },
                            ["TL"] = {
                                "Malaking tulong ang sandaling pag-upo ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Exhaustion is catching up with me today.",
                            },
                            ["TL"] = {
                                "Inaabutan na ako ng matinding pagod ngayon.",
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
        ["sourceShard"] = "psdl/dialogue/wellbeing_content.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "wellbeing_content",
        ["id"] = "semantic.question.wellbeing.fatigue_alt.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.wellbeing.fatigue_alt.neutral",
            ["sourcePath"] = "psdl/dialogue/wellbeing_content.json#records[15]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/WellbeingContent/Catalog",
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
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseTemplateID"] = "semantic.question.wellbeing.fatigue_alt",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/wellbeing/needs.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm tired. A little rest would help.",
                            },
                            ["TL"] = {
                                "Pagod ako. Makakatulong ang kaunting pahinga.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Hard to keep my eyes open right now.",
                            },
                            ["TL"] = {
                                "Hirap na akong idilat ang mga mata ko ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Been pushing hard all day. Need to rest soon.",
                            },
                            ["TL"] = {
                                "Masyadong napagod maghapon. Kailangang magpahinga maya-maya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Sleep would be a luxury right about now.",
                            },
                            ["TL"] = {
                                "Napakasarap sanang makatulog sa mga oras na ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Feeling slow and sluggish from lack of rest.",
                            },
                            ["TL"] = {
                                "Mabagal ang kilos ko dahil sa kakulangan sa pahinga.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "My reflexes aren't what they should be right now.",
                            },
                            ["TL"] = {
                                "Medyo mabagal ang reaksyon ko dahil sa pagod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Tired down to the bone, but still standing.",
                            },
                            ["TL"] = {
                                "Tagos sa buto ang pagod, pero nakatayo pa rin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "If we find a safe corner, I need a minute.",
                            },
                            ["TL"] = {
                                "Kapag nakahanap tayo ng ligtas na sulok, pahinga muna ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Could fall asleep right where I'm standing.",
                            },
                            ["TL"] = {
                                "Kaya kong makatulog kahit saan ako nakatayo ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Just need an hour of shut-eye to reset.",
                            },
                            ["TL"] = {
                                "Kailangan ko lang ng kahit isang oras na tulog para makabawi.",
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
        ["sourceShard"] = "psdl/dialogue/wellbeing_content.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "wellbeing_content",
        ["id"] = "semantic.question.wellbeing.hunger.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.wellbeing.hunger.neutral",
            ["sourcePath"] = "psdl/dialogue/wellbeing_content.json#records[16]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/WellbeingContent/Catalog",
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
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseTemplateID"] = "semantic.question.wellbeing.hunger",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/wellbeing/needs.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm pretty hungry, if I'm honest. Do you have anything to eat?",
                            },
                            ["TL"] = {
                                "Medyo gutom ako, kung tutuusin. May makakain ka ba?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "My stomach has been growling for hours. Got any food to spare?",
                            },
                            ["TL"] = {
                                "Kanina pa kumakalam ang sikmura ko. May maibibigay ka bang pagkain?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Really feeling the hunger right now. Could use a bite.",
                            },
                            ["TL"] = {
                                "Ramdam na ramdam ko ang gutom ngayon. Kailangan ko ng makakain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Haven't had a proper meal in a while. Any rations on you?",
                            },
                            ["TL"] = {
                                "Medyo matagal na mula noong huli akong kumain. May rasyon ka ba?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Need some calories before my strength fades. Got anything?",
                            },
                            ["TL"] = {
                                "Kailangan ko ng lakas bago ako manghina. Mayroon ka ba riyan?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'm starving out here. Even stale crackers would do.",
                            },
                            ["TL"] = {
                                "Gutom na gutom na ako rito. Kahit lumang biskwit tatanggapin ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Food is getting urgent for me. Anything in your pack?",
                            },
                            ["TL"] = {
                                "Kailangan ko na talagang kumain. May laman ba ang bag mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Hard to focus when your stomach is this empty. Spare any food?",
                            },
                            ["TL"] = {
                                "Mahirap mag-isip kapag walang laman ang tiyan. Penge namang makakain?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I could really use a snack or some canned goods right now.",
                            },
                            ["TL"] = {
                                "Kailangan ko talaga ng meryenda o de-lata ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Getting weak from hunger. Do you have any rations to share?",
                            },
                            ["TL"] = {
                                "Nanghihina na ako sa gutom. May maibabahagi ka bang rasyon?",
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
        ["sourceShard"] = "psdl/dialogue/wellbeing_content.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "wellbeing_content",
        ["id"] = "semantic.question.wellbeing.hunger_alt.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.wellbeing.hunger_alt.neutral",
            ["sourcePath"] = "psdl/dialogue/wellbeing_content.json#records[17]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/WellbeingContent/Catalog",
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
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseTemplateID"] = "semantic.question.wellbeing.hunger_alt",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/wellbeing/needs.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm getting hungry. Could you spare something to eat?",
                            },
                            ["TL"] = {
                                "Nagugutom na ako. Maaari ba akong makahingi ng makakain?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Could use some food soon. My energy is dipping low.",
                            },
                            ["TL"] = {
                                "Kailangan ko ng pagkain maya-maya. Bumababa na ang lakas ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Starting to feel hollow inside. Any food left?",
                            },
                            ["TL"] = {
                                "Parang hungkag na ang sikmura ko. May natira pa bang pagkain?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "A small bite would go a long way right now.",
                            },
                            ["TL"] = {
                                "Malaking tulong ang kahit kaunting subo ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Gotta find something to eat before too long.",
                            },
                            ["TL"] = {
                                "Kailangang makahanap ng makakain sa lalong madaling panahon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "My pack is empty of food. Got anything to share?",
                            },
                            ["TL"] = {
                                "Wala nang laman ang bag ko. May maibabahagi ka ba?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Thinking about food constantly. Need a meal soon.",
                            },
                            ["TL"] = {
                                "Pagkain lang ang nasa isip ko. Kailangang makakain agad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Even a crust of bread would help me keep going.",
                            },
                            ["TL"] = {
                                "Kahit balat ng tinapay makakatulong sa akin para magpatuloy.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Stomach's rumbling loud enough to draw attention. Got food?",
                            },
                            ["TL"] = {
                                "Baka marinig pa ng iba ang kulo ng tiyan ko. May pagkain ka?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Running low on fuel. Spare a bite if you've got extra?",
                            },
                            ["TL"] = {
                                "Nauubusan na ako ng enerhiya. Pahingi naman ng konting makakain kung sobra?",
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
        ["sourceShard"] = "psdl/dialogue/wellbeing_content.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "wellbeing_content",
        ["id"] = "semantic.question.wellbeing.injured.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.wellbeing.injured.guarded",
            ["sourcePath"] = "psdl/dialogue/wellbeing_content.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/WellbeingContent/Catalog",
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
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseTemplateID"] = "semantic.question.wellbeing.injured",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/wellbeing/emotional.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm hurt. That's all I can say.",
                            },
                            ["TL"] = {
                                "Nasaktan ako. Iyon lang ang masasabi ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Took some damage. I'll patch it myself, don't worry.",
                            },
                            ["TL"] = {
                                "Tinamaan ako. Ako na ang gagamot dito, huwag kang mag-alala.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Bleeding a little, but I can still defend myself.",
                            },
                            ["TL"] = {
                                "Dumudugo nang kaunti, pero kaya ko pa ring lumaban.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "It's just a flesh wound. Keep your distance.",
                            },
                            ["TL"] = {
                                "Daplis lang ito. Lumayo ka muna.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "I'm wounded, but I don't need charity.",
                            },
                            ["TL"] = {
                                "May sugat ako, pero hindi ko kailangan ng awa.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Hurts like hell, but I'm holding my ground.",
                            },
                            ["TL"] = {
                                "Sobrang sakit, pero hindi ako aatras.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Got scraped up. Mind your own injuries.",
                            },
                            ["TL"] = {
                                "Nagasgasan lang. Asikasuhin mo ang sarili mong sugat.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Don't stare at the bandages. I'm still functional.",
                            },
                            ["TL"] = {
                                "Huwag mong titigan ang benda ko. Kaya ko pang kumilos.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "A rough encounter, but I survived it. Back off.",
                            },
                            ["TL"] = {
                                "Medyo magulo ang engkuwentro, pero nakaligtas ako. Umatras ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "I'll manage the pain on my own, thanks.",
                            },
                            ["TL"] = {
                                "Kakayanin ko ang sakit mag-isa, salamat.",
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
        ["sourceShard"] = "psdl/dialogue/wellbeing_content.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "wellbeing_content",
        ["id"] = "semantic.question.wellbeing.injured.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.wellbeing.injured.neutral",
            ["sourcePath"] = "psdl/dialogue/wellbeing_content.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/WellbeingContent/Catalog",
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
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseTemplateID"] = "semantic.question.wellbeing.injured",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/wellbeing/emotional.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "A little banged up, but I'll manage.",
                            },
                            ["TL"] = {
                                "Medyo may tama ako, pero kakayanin ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Took a hit during the last scrap. Need to bandage up.",
                            },
                            ["TL"] = {
                                "Tinamaan ako noong huling laban. Kailangan kong bendahan ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'm nursing a couple wounds, but nothing fatal.",
                            },
                            ["TL"] = {
                                "May iniinda akong ilang sugat, pero hindi naman nakamamatay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Hurts to move quickly, but I can still walk.",
                            },
                            ["TL"] = {
                                "Masakit kumilos nang mabilis, pero nakakalakad pa ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Got tagged out there. Keeping an eye on the bleeding.",
                            },
                            ["TL"] = {
                                "Tinamaan ako sa labas. Binabantayan ko ang pagdurugo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Bruised and aching all over, but I'll pull through.",
                            },
                            ["TL"] = {
                                "Pasa-pasa at masakit ang buong katawan, pero makakaraos din.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Scraped up pretty bad, but still on two feet.",
                            },
                            ["TL"] = {
                                "Medyo malala ang gasgas ko, pero nakatayo pa rin sa dalawang paa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Need some clean bandages soon, but I'm holding together.",
                            },
                            ["TL"] = {
                                "Kailangan ko ng malinis na benda agad, pero maayos pa naman.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Took a rough fall earlier. Still feeling the sting.",
                            },
                            ["TL"] = {
                                "Medyo napasama ang bagsak ko kanina. Kumikirot pa rin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Not in peak shape right now, but I can carry on.",
                            },
                            ["TL"] = {
                                "Hindi ako nasa pinakamagandang kondisyon, pero kaya pang ituloy.",
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
        ["sourceShard"] = "psdl/dialogue/wellbeing_content.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "wellbeing_content",
        ["id"] = "semantic.question.wellbeing.injured.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.wellbeing.injured.terse",
            ["sourcePath"] = "psdl/dialogue/wellbeing_content.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/WellbeingContent/Catalog",
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
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseTemplateID"] = "semantic.question.wellbeing.injured",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/wellbeing/emotional.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm hurt. I can manage.",
                            },
                            ["TL"] = {
                                "Nasaktan ako. Kaya ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Bleeding.",
                            },
                            ["TL"] = {
                                "Dumudugo.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Took a hit.",
                            },
                            ["TL"] = {
                                "Tinamaan ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Bruised up.",
                            },
                            ["TL"] = {
                                "May pasa.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Hurts.",
                            },
                            ["TL"] = {
                                "Masakit.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Need bandages.",
                            },
                            ["TL"] = {
                                "Kailangan ng benda.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Still walking.",
                            },
                            ["TL"] = {
                                "Nakakalakad pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Minor wound.",
                            },
                            ["TL"] = {
                                "Maliit na sugat lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Stings like hell.",
                            },
                            ["TL"] = {
                                "Napakasakit.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Managing the pain.",
                            },
                            ["TL"] = {
                                "Tinitiis ang sakit.",
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
        ["sourceShard"] = "psdl/dialogue/wellbeing_content.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "wellbeing_content",
        ["id"] = "semantic.question.wellbeing.injured.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.wellbeing.injured.warm",
            ["sourcePath"] = "psdl/dialogue/wellbeing_content.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/WellbeingContent/Catalog",
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
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseTemplateID"] = "semantic.question.wellbeing.injured",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/wellbeing/emotional.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "I took a hit, but I'm steady enough to keep going.",
                            },
                            ["TL"] = {
                                "Nasaktan ako, pero kaya ko pang magpatuloy.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Appreciate you checking. It stings, but I'll be fine.",
                            },
                            ["TL"] = {
                                "Salamat sa pag-alala. Kumikirot, pero magiging maayos din ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Got banged up a bit. Having you around makes it easier.",
                            },
                            ["TL"] = {
                                "Medyo nasugatan ako. Mas gumaan ang loob ko dahil nandito ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Don't worry too much. I'll get this patched up in no time.",
                            },
                            ["TL"] = {
                                "Huwag kang masyadong mag-alala. Magagamot ko rin ito agad.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Took a knock, but seeing you safe helps take the edge off.",
                            },
                            ["TL"] = {
                                "Tinamaan ako nang bahagya, pero nakakabawas ng sakit na ligtas ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'll pull through, friend. Thanks for watching out for me.",
                            },
                            ["TL"] = {
                                "Kakayanin ko ito, kaibigan. Salamat sa pagbabantay sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Nothing we can't patch up together. Appreciate the concern.",
                            },
                            ["TL"] = {
                                "Kaya nating gamutin ito nang magkasama. Salamat sa malasakit.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "Just a bad scratch. I'll be back at full strength soon.",
                            },
                            ["TL"] = {
                                "Malalim na gasgas lang ito. Babalik din ang buong lakas ko agad.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "It hurts, but I know we've got each other's backs.",
                            },
                            ["TL"] = {
                                "Masakit, pero alam kong nagtutulungan tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "A bit bruised, but your concern means the world to me.",
                            },
                            ["TL"] = {
                                "Pasa-pasa ako, pero malaking bagay sa akin ang pag-aalala mo.",
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
        ["sourceShard"] = "psdl/dialogue/wellbeing_content.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "wellbeing_content",
        ["id"] = "semantic.question.wellbeing.panic.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.wellbeing.panic.neutral",
            ["sourcePath"] = "psdl/dialogue/wellbeing_content.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/WellbeingContent/Catalog",
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
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseTemplateID"] = "semantic.question.wellbeing.panic",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/wellbeing/emotional.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm pretty shaken up right now.",
                            },
                            ["TL"] = {
                                "Nanginginig pa rin ako ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "My heart is pounding out of my chest.",
                            },
                            ["TL"] = {
                                "Napakabilis ng tibok ng puso ko sa kaba.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "That was way too close. Need a minute to breathe.",
                            },
                            ["TL"] = {
                                "Muntik na 'yon. Kailangan ko ng sandali para kumalma.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Trying to keep my hands from shaking.",
                            },
                            ["TL"] = {
                                "Pinipigilan ko ang panginginig ng mga kamay ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Terrified, if I'm being honest with you.",
                            },
                            ["TL"] = {
                                "Natatakot ako, kung sasabihin ko ang totoo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Felt like my heart was going to stop back there.",
                            },
                            ["TL"] = {
                                "Pakiramdam ko hihinto na ang puso ko kanina.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Need to catch my breath and calm my nerves.",
                            },
                            ["TL"] = {
                                "Kailangang huminga nang malalim at pakalmahin ang sarili.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Adrenaline is surging. Hard to think straight.",
                            },
                            ["TL"] = {
                                "Mataas pa ang adrenaline ko. Hirap mag-isip nang tuwid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Still feeling the panic creeping up on me.",
                            },
                            ["TL"] = {
                                "Nararamdaman ko pa rin ang takot na gumagapang sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Give me a second to get my head together.",
                            },
                            ["TL"] = {
                                "Bigyan mo ako ng ilang sandali para makabawi ng katinuan.",
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
        ["sourceShard"] = "psdl/dialogue/wellbeing_content.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "wellbeing_content",
        ["id"] = "semantic.question.wellbeing.stress.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.wellbeing.stress.neutral",
            ["sourcePath"] = "psdl/dialogue/wellbeing_content.json#records[5]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/WellbeingContent/Catalog",
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
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseTemplateID"] = "semantic.question.wellbeing.stress",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/wellbeing/emotional.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm tense, but I can keep going.",
                            },
                            ["TL"] = {
                                "Tensiyonado ako, pero kaya ko pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Nerves are frayed. The tension is getting to me.",
                            },
                            ["TL"] = {
                                "Naiipit ang mga nerbyos ko. Ramdam ko ang tensiyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Feeling the pressure constantly out here.",
                            },
                            ["TL"] = {
                                "Laging mabigat ang pakiramdam dito sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "On edge, jumping at every shadow.",
                            },
                            ["TL"] = {
                                "Kabado ako, nabibigla sa bawat anino.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Stress is wearing me down faster than the walking.",
                            },
                            ["TL"] = {
                                "Mas nakakapagod ang stress kaysa sa mismong paglalakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Hard to unwind when danger could be anywhere.",
                            },
                            ["TL"] = {
                                "Mahirap magrelaks kapag may panganib kahit saan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "My shoulders are tight as iron from all this stress.",
                            },
                            ["TL"] = {
                                "Mabigat ang mga balikat ko sa sobrang stress.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Just trying to keep my sanity intact.",
                            },
                            ["TL"] = {
                                "Pinipilit ko lang mapanatili ang katinuan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Every little noise has me reaching for my weapon.",
                            },
                            ["TL"] = {
                                "Bawat kaluskos napapahawak ako agad sa armas ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "It's a lot to process, but I'm holding it in.",
                            },
                            ["TL"] = {
                                "Mabigat dalhin ang lahat, pero tinitiis ko.",
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
        ["sourceShard"] = "psdl/dialogue/wellbeing_content.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "wellbeing_content",
        ["id"] = "semantic.question.wellbeing.thirst.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.wellbeing.thirst.neutral",
            ["sourcePath"] = "psdl/dialogue/wellbeing_content.json#records[18]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/WellbeingContent/Catalog",
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
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseTemplateID"] = "semantic.question.wellbeing.thirst",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/wellbeing/needs.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm pretty thirsty. Could you spare some water?",
                            },
                            ["TL"] = {
                                "Uhaw na uhaw ako. Maaari ba akong makahingi ng tubig?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "My throat feels parched. Got any clean water?",
                            },
                            ["TL"] = {
                                "Tuyong-tuyo ang lalamunan ko. May malinis ka bang tubig?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Really need a drink soon. Starting to feel dehydrated.",
                            },
                            ["TL"] = {
                                "Kailangan ko na talagang uminom. Nauuhaw na ako nang husto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Could use a sip of water if you've got any to share.",
                            },
                            ["TL"] = {
                                "Kailangan ko ng kahit kaunting lagok ng tubig kung mayroon ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Thirst is really slowing me down today.",
                            },
                            ["TL"] = {
                                "Pinapabagal talaga ako ng uhaw ngayong araw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "My canteen ran dry a while back. Got any water?",
                            },
                            ["TL"] = {
                                "Natuyo na ang lalagyan ko kanina pa. May tubig ka ba?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Desperate for a drink of fresh water right now.",
                            },
                            ["TL"] = {
                                "Kailangang-kailangan ko ng maiinom na sariwang tubig ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "My mouth is bone dry. Can you spare a few drops?",
                            },
                            ["TL"] = {
                                "Tuyot na tuyot ang bibig ko. Makakahingi ba ng kaunting tubig?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Need water before my headache gets any worse.",
                            },
                            ["TL"] = {
                                "Kailangan ko ng tubig bago pa sumakit ang ulo ko sa uhaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Any spare water bottle on you? I'm drying up.",
                            },
                            ["TL"] = {
                                "May sobra ka bang botelya ng tubig? Uhaw na uhaw na ako.",
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
        ["sourceShard"] = "psdl/dialogue/wellbeing_content.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "wellbeing_content",
        ["id"] = "semantic.question.wellbeing.thirst_alt.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.wellbeing.thirst_alt.neutral",
            ["sourcePath"] = "psdl/dialogue/wellbeing_content.json#records[19]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/WellbeingContent/Catalog",
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
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseTemplateID"] = "semantic.question.wellbeing.thirst_alt",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/wellbeing/needs.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I could really use a drink. Do you have any water?",
                            },
                            ["TL"] = {
                                "Kailangan ko talaga ng maiinom. May tubig ka ba?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Dying for a drink of water out here.",
                            },
                            ["TL"] = {
                                "Gusto ko na talagang makainom ng tubig dito sa init.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Throat is scratching with thirst. Got a bottle?",
                            },
                            ["TL"] = {
                                "Makati na ang lalamunan ko sa uhaw. May botelya ka ba?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Would give almost anything for a cold sip right now.",
                            },
                            ["TL"] = {
                                "Kahit ano ibibigay ko para sa malamig na lagok ng tubig ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Looking for clean water everywhere. Got any to spare?",
                            },
                            ["TL"] = {
                                "Naghahanap ako ng malinis na tubig kung saan-saan. May sobra ka?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Dehydration is starting to set in. Water would help immensely.",
                            },
                            ["TL"] = {
                                "Inaabutan na ako ng dehydration. Malaking tulong ang tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Got a spare flask of water? My tongue feels like sandpaper.",
                            },
                            ["TL"] = {
                                "May sobra ka bang lalagyan ng tubig? Parang liha na ang dila ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Can't go much further without something to drink.",
                            },
                            ["TL"] = {
                                "Hindi na ako makakalayo kapag walang maiinom.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Just a small swallow of water would keep me going.",
                            },
                            ["TL"] = {
                                "Kahit isang lagok lang ng tubig makakatulong na sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "My lips are chapped from thirst. Spare any water?",
                            },
                            ["TL"] = {
                                "Bitak-bitak na ang labi ko sa uhaw. Pahingi naman ng tubig?",
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
        ["sourceShard"] = "psdl/dialogue/wellbeing_content.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
