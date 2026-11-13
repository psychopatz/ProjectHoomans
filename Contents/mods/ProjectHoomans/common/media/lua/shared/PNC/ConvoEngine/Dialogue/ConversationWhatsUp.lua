-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_whats_up",
        ["id"] = "semantic.question.whats_up.busy.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "guarded",
            ["sourceId"] = "semantic.question.whats_up.busy.guarded",
            ["sourcePath"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_busy.json#records[0]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ConversationWhatsUp",
        ["namespace"] = "semantic.question.whats_up.busy",
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
                ["category"] = "projecthoomans:conversation_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.conversation",
                ["responseTemplateID"] = "semantic.question.whats_up.busy",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/conversation.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Keeping busy. Don't distract me.",
                            },
                            ["TL"] = {
                                "Abala ako. Huwag mo akong gambalain.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "I've got work to do. Keep moving.",
                            },
                            ["TL"] = {
                                "May trabaho pa ako. Magpatuloy ka na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Hands are full right now. Leave me to it.",
                            },
                            ["TL"] = {
                                "Marami akong ginagawa ngayon. Hayaan mo muna ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Occupied. Don't crowd my workspace.",
                            },
                            ["TL"] = {
                                "May ginagawa ako. Huwag kang humarang dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Too much to do to stand around chatting.",
                            },
                            ["TL"] = {
                                "Masyadong maraming gagawin para tumambay at makipag-usap.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'm busy with survival. You should be too.",
                            },
                            ["TL"] = {
                                "Abala ako sa pagpapatuloy. Dapat ikaw rin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Focusing on my duties. Step back.",
                            },
                            ["TL"] = {
                                "Nakatutok ako sa tungkulin ko. Umatras ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Work doesn't stop because you want to talk.",
                            },
                            ["TL"] = {
                                "Hindi hihinto ang trabaho dahil lang gusto mong makipag-usap.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Busy here. Come back when I'm done.",
                            },
                            ["TL"] = {
                                "Abala ako rito. Bumalik ka kapag tapos na ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Got critical tasks to finish. Don't get in the way.",
                            },
                            ["TL"] = {
                                "May mahalagang gawain akong tatapusin. Huwag kang humarang.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_busy.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "conversation_whats_up",
        ["id"] = "semantic.question.whats_up.busy.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "neutral",
            ["sourceId"] = "semantic.question.whats_up.busy.neutral",
            ["sourcePath"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_busy.json#records[1]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ConversationWhatsUp",
        ["namespace"] = "semantic.question.whats_up.busy",
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
                ["category"] = "projecthoomans:conversation_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.conversation",
                ["responseTemplateID"] = "semantic.question.whats_up.busy",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/conversation.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm keeping busy and trying to stay useful.",
                            },
                            ["TL"] = {
                                "Abala ako at sinusubukan kong maging kapaki-pakinabang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Just working through my checklist for the day.",
                            },
                            ["TL"] = {
                                "Inaayos ko lang ang mga kailangan kong gawin ngayong araw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Plenty of chores to keep my mind off the dead.",
                            },
                            ["TL"] = {
                                "Maraming gawain para hindi maisip ang mga patay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Taking care of camp business. Always something to fix.",
                            },
                            ["TL"] = {
                                "Inaasikaso ang mga kailangan sa kampo. Laging may aayusin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Putting in work so we all stay safe.",
                            },
                            ["TL"] = {
                                "Nagtatrabaho para manatiling ligtas tayong lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Staying occupied. It helps pass the hours.",
                            },
                            ["TL"] = {
                                "Pinananatiling abala ang sarili. Nakatutulong magpalipas ng oras.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Tending to tasks. What about you?",
                            },
                            ["TL"] = {
                                "Gumagawa ng mga gawain. Kumusta naman ikaw?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Got a few projects on my plate today.",
                            },
                            ["TL"] = {
                                "May ilang proyekto akong inaasikaso ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Just getting things organized around here.",
                            },
                            ["TL"] = {
                                "Inaayos lang ang mga gamit dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Keeping my hands moving. Idleness gets people killed.",
                            },
                            ["TL"] = {
                                "Gumagalaw palagi. Ang kawalan ng gawa ang nagpapahamak sa tao.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_busy.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "conversation_whats_up",
        ["id"] = "semantic.question.whats_up.busy.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "terse",
            ["sourceId"] = "semantic.question.whats_up.busy.terse",
            ["sourcePath"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_busy.json#records[2]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ConversationWhatsUp",
        ["namespace"] = "semantic.question.whats_up.busy",
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
                ["category"] = "projecthoomans:conversation_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.conversation",
                ["responseTemplateID"] = "semantic.question.whats_up.busy",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/conversation.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "Keeping busy.",
                            },
                            ["TL"] = {
                                "Abala ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Working.",
                            },
                            ["TL"] = {
                                "Nagtatrabaho.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Busy.",
                            },
                            ["TL"] = {
                                "Abala.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Tasks.",
                            },
                            ["TL"] = {
                                "Mga gawain.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Hands full.",
                            },
                            ["TL"] = {
                                "Maraming hawak.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Occupied.",
                            },
                            ["TL"] = {
                                "May ginagawa.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Still on it.",
                            },
                            ["TL"] = {
                                "Ginagawa pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "No slack.",
                            },
                            ["TL"] = {
                                "Walang tigil.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Chores.",
                            },
                            ["TL"] = {
                                "Gawain sa kampo.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Getting it done.",
                            },
                            ["TL"] = {
                                "Tinatapos ito.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_busy.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "conversation_whats_up",
        ["id"] = "semantic.question.whats_up.busy.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "warm",
            ["sourceId"] = "semantic.question.whats_up.busy.warm",
            ["sourcePath"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_busy.json#records[3]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ConversationWhatsUp",
        ["namespace"] = "semantic.question.whats_up.busy",
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
                ["category"] = "projecthoomans:conversation_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.conversation",
                ["responseTemplateID"] = "semantic.question.whats_up.busy",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/conversation.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm keeping busy and trying to stay useful. There's always something to do.",
                            },
                            ["TL"] = {
                                "Abala ako at sinusubukan kong maging kapaki-pakinabang. Laging may kailangang gawin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Working hard so our camp stays strong. Glad you stopped by!",
                            },
                            ["TL"] = {
                                "Nagsusumikap para sa kampo. Masayang dumaan ka!",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Keeping active, but never too busy for a good word with you.",
                            },
                            ["TL"] = {
                                "Abala man, hindi mawawalan ng oras para kumustahin ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Tending to some chores. Nice to take a quick breather with a friend.",
                            },
                            ["TL"] = {
                                "Gumagawa ng gawain. Masarap magpahinga sandali kasama ang kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Just doing my part for our little community. How are you doing?",
                            },
                            ["TL"] = {
                                "Ginagawa lang ang parte ko sa komunidad. Kumusta ka naman?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Keeping busy helps keep the worry away. Always good to see you.",
                            },
                            ["TL"] = {
                                "Nawawala ang kaba kapag may ginagawa. Laging magandang makita ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Working away! Let me know if you need any help with your own tasks.",
                            },
                            ["TL"] = {
                                "Nagtatrabaho lang! Sabihan mo ako kung kailangan mo ng tulong sa gawain mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "Plenty of work, but having good folks around makes it easy.",
                            },
                            ["TL"] = {
                                "Maraming trabaho, pero gumagaan kapag may mabubuting kasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Just finishing up a few things. It's lovely seeing you today.",
                            },
                            ["TL"] = {
                                "Tinatapos lang ang ilang bagay. Masarap kang makita ngayong araw.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Doing what I can to pitch in. Thank you for checking in on me.",
                            },
                            ["TL"] = {
                                "Tumutulong sa abot ng makakaya. Salamat sa pangangamusta mo.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_busy.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "conversation_whats_up",
        ["id"] = "semantic.question.whats_up.default.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "guarded",
            ["sourceId"] = "semantic.question.whats_up.default.guarded",
            ["sourcePath"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_default.json#records[0]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ConversationWhatsUp",
        ["namespace"] = "semantic.question.whats_up.default",
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
                ["category"] = "projecthoomans:conversation_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.conversation",
                ["responseTemplateID"] = "semantic.question.whats_up.default",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/conversation.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Nothing worth discussing. Stay alert.",
                            },
                            ["TL"] = {
                                "Walang mahalagang pag-usapan. Manatiling alerto.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Same old story. Don't let your guard down.",
                            },
                            ["TL"] = {
                                "Ganoon pa rin. Huwag kang magpapabaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Just watching the perimeter. You should do the same.",
                            },
                            ["TL"] = {
                                "Binabantayan lang ang paligid. Dapat ganoon ka rin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Nothing new, and quiet usually means trouble is brewing.",
                            },
                            ["TL"] = {
                                "Walang bago, at ang katahimikan ay kadalasang may dalang gulo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Nothing to share. Keep moving along.",
                            },
                            ["TL"] = {
                                "Walang dapat ibahagi. Magpatuloy ka lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Surviving another day. That's about it.",
                            },
                            ["TL"] = {
                                "Nabubuhay pa ng isa pang araw. Iyon lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "I keep my thoughts to myself out here.",
                            },
                            ["TL"] = {
                                "Itinatago ko ang iniisip ko sa sarili ko rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "All quiet on my watch. Keep your distance.",
                            },
                            ["TL"] = {
                                "Tahimik sa bantay ko. Lumayo ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Not much, and I'd like to keep it that way.",
                            },
                            ["TL"] = {
                                "Wala naman, at gusto kong manatiling ganoon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Nothing you need to concern yourself with.",
                            },
                            ["TL"] = {
                                "Walang dapat mong alalahanin.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_default.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "conversation_whats_up",
        ["id"] = "semantic.question.whats_up.default.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "neutral",
            ["sourceId"] = "semantic.question.whats_up.default.neutral",
            ["sourcePath"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_default.json#records[1]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ConversationWhatsUp",
        ["namespace"] = "semantic.question.whats_up.default",
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
                ["category"] = "projecthoomans:conversation_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.conversation",
                ["responseTemplateID"] = "semantic.question.whats_up.default",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/conversation.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Not much. I'm just trying to keep things together.",
                            },
                            ["TL"] = {
                                "Wala naman. Sinusubukan ko lang na panatilihing maayos ang lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Just another day trying to stay alive and in one piece.",
                            },
                            ["TL"] = {
                                "Isa na namang araw sa pagsubok na manatiling buhay at buo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Taking things as they come. Anything interesting happening?",
                            },
                            ["TL"] = {
                                "Tinatanggap ang bawat araw. May bago ba o kawili-wili?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Not a whole lot. Keeping an eye on the surroundings.",
                            },
                            ["TL"] = {
                                "Wala masyado. Binabantayan lang ang kapaligiran.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Just waiting to see what the afternoon brings.",
                            },
                            ["TL"] = {
                                "Nagmamasid lang kung anong mangyayari ngayong hapon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Ordinary day out here, if you can call this ordinary.",
                            },
                            ["TL"] = {
                                "Karaniwang araw dito, kung matatawag mong karaniwan ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Just trying to make it to sundown without issues.",
                            },
                            ["TL"] = {
                                "Sinusubukang umabot sa takip-silim nang walang aberya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Holding down the fort. How are things with you?",
                            },
                            ["TL"] = {
                                "Binabantayan ang pwesto. Kumusta naman sa iyo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Quiet so far. That's usually a blessing.",
                            },
                            ["TL"] = {
                                "Tahimik sa ngayon. Biyaya na ang ganoon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Not much news. Just staying out of harm's way.",
                            },
                            ["TL"] = {
                                "Walang masyadong balita. Umiiwas lang sa kapahamakan.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_default.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "conversation_whats_up",
        ["id"] = "semantic.question.whats_up.default.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "terse",
            ["sourceId"] = "semantic.question.whats_up.default.terse",
            ["sourcePath"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_default.json#records[2]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ConversationWhatsUp",
        ["namespace"] = "semantic.question.whats_up.default",
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
                ["category"] = "projecthoomans:conversation_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.conversation",
                ["responseTemplateID"] = "semantic.question.whats_up.default",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/conversation.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "Just getting by.",
                            },
                            ["TL"] = {
                                "Kinakaya lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Not much.",
                            },
                            ["TL"] = {
                                "Wala naman.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Quiet.",
                            },
                            ["TL"] = {
                                "Tahimik.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Same as ever.",
                            },
                            ["TL"] = {
                                "Gaya ng dati.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Still here.",
                            },
                            ["TL"] = {
                                "Nandito pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Nothing new.",
                            },
                            ["TL"] = {
                                "Walang bago.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "All calm.",
                            },
                            ["TL"] = {
                                "Payapa.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
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
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Holding on.",
                            },
                            ["TL"] = {
                                "Kumakapit.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Taking it slow.",
                            },
                            ["TL"] = {
                                "Dahan-dahan lang.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_default.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "conversation_whats_up",
        ["id"] = "semantic.question.whats_up.default.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "warm",
            ["sourceId"] = "semantic.question.whats_up.default.warm",
            ["sourcePath"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_default.json#records[3]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ConversationWhatsUp",
        ["namespace"] = "semantic.question.whats_up.default",
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
                ["category"] = "projecthoomans:conversation_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.conversation",
                ["responseTemplateID"] = "semantic.question.whats_up.default",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/conversation.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "Not much. I'm just trying to keep things together. Good to see you, though.",
                            },
                            ["TL"] = {
                                "Wala naman. Sinusubukan ko lang na panatilihing maayos ang lahat. Mabuti at nakita kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Just grateful to see another sunrise. It's lovely having you here.",
                            },
                            ["TL"] = {
                                "Nagpapasalamat lang sa panibagong bukang-liwayway. Masayang nandito ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Not much happening, but having good folks around brightens the day.",
                            },
                            ["TL"] = {
                                "Walang gaanong kaganapan, pero gumaganda ang araw kapag may mabubuting kasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Just taking it easy for a moment. Really glad you stopped to talk.",
                            },
                            ["TL"] = {
                                "Nagpapahinga lang sandali. Masaya talaga akong huminto ka para makipag-usap.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Things are calm today, thank goodness. How has your day been going?",
                            },
                            ["TL"] = {
                                "Payapa ang araw ngayon, salamat sa Diyos. Kumusta naman ang araw mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Nothing out of the ordinary, but seeing you always lifts my spirits.",
                            },
                            ["TL"] = {
                                "Walang kakaiba, pero laging nakakapagpagaan ng loob ang makita ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Holding steady with a smile. Hope everything is smooth on your side.",
                            },
                            ["TL"] = {
                                "Matatag pa rin at nakangiti. Sana maayos ang lahat sa panig mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "Just soaking in the peace while it lasts. Good to see you, friend.",
                            },
                            ["TL"] = {
                                "Nilalasap ang kapayapaan habang nariyan pa. Mabuti at nakita kita, kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Counting my blessings out here. Having reliable people is number one.",
                            },
                            ["TL"] = {
                                "Nagbibilang ng mga biyaya. Ang magkaroon ng maaasahang kasama ang una roon.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Nothing major, just glad we're both standing. How's everything with you?",
                            },
                            ["TL"] = {
                                "Wala namang malaki, masaya lang akong pareho tayong nakatayo. Kumusta ka?",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_default.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "conversation_whats_up",
        ["id"] = "semantic.question.whats_up.default_alt.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "guarded",
            ["sourceId"] = "semantic.question.whats_up.default_alt.guarded",
            ["sourcePath"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_default_alt.json#records[0]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ConversationWhatsUp",
        ["namespace"] = "semantic.question.whats_up.default_alt",
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
                ["category"] = "projecthoomans:conversation_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.conversation",
                ["responseTemplateID"] = "semantic.question.whats_up.default_alt",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/conversation.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Staying alive. Keep your eyes open.",
                            },
                            ["TL"] = {
                                "Basta buhay. Maging mapagmatyag.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Watching the road. Don't stand in my line of sight.",
                            },
                            ["TL"] = {
                                "Binabantayan ang daan. Huwag kang humarang sa tingin ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Alive, but cautious. You should be too.",
                            },
                            ["TL"] = {
                                "Buhay, pero maingat. Dapat ganoon ka rin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Just staying on high alert. Danger doesn't take days off.",
                            },
                            ["TL"] = {
                                "Laging alerto. Walang bakasyon ang panganib.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Focusing on staying off the radar. Step aside.",
                            },
                            ["TL"] = {
                                "Nakatutok sa pananatiling tago. Tabi muna.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Watching the fence lines. Nothing for you here.",
                            },
                            ["TL"] = {
                                "Binabantayan ang bakod. Walang kailangan dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Alive, and keeping it that way by not gossiping.",
                            },
                            ["TL"] = {
                                "Buhay, at mananatiling ganito kung hindi makikipagtsismisan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Eyes on the horizon. Don't make unnecessary noise.",
                            },
                            ["TL"] = {
                                "Nakatitig sa abot-tanaw. Huwag gumawa ng ingay.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Surviving. That requires vigilance, not conversation.",
                            },
                            ["TL"] = {
                                "Buhay pa. Kailangan 'yan ng pag-iingat, hindi ng daldalan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Just keeping myself safe. You do the same.",
                            },
                            ["TL"] = {
                                "Pinoprotektahan lang ang sarili ko. Gawin mo rin 'yan.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_default_alt.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "conversation_whats_up",
        ["id"] = "semantic.question.whats_up.default_alt.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "neutral",
            ["sourceId"] = "semantic.question.whats_up.default_alt.neutral",
            ["sourcePath"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_default_alt.json#records[1]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ConversationWhatsUp",
        ["namespace"] = "semantic.question.whats_up.default_alt",
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
                ["category"] = "projecthoomans:conversation_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.conversation",
                ["responseTemplateID"] = "semantic.question.whats_up.default_alt",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/conversation.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Same as ever. Staying alive and watching the road.",
                            },
                            ["TL"] = {
                                "Gaya ng dati. Nanatiling buhay at binabantayan ang daan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Doing what needs to be done to see tomorrow.",
                            },
                            ["TL"] = {
                                "Ginagawa kung anong kailangan para makita ang bukas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "One foot in front of the other. Road's quiet so far.",
                            },
                            ["TL"] = {
                                "Dahan-dahang naglalakad. Tahimik naman ang kalsada.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Keeping a low profile and taking care of business.",
                            },
                            ["TL"] = {
                                "Umiiwas sa gulo at inaasikaso ang mga kailangan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Just staying alert out here. How have you been?",
                            },
                            ["TL"] = {
                                "Laging nagmamasid dito sa labas. Kumusta ka na?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Watching the tree lines. Routine stuff.",
                            },
                            ["TL"] = {
                                "Binabantayan ang kakahuyan. Karaniwang gawain lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Still on the right side of the dirt. That's plenty.",
                            },
                            ["TL"] = {
                                "Nasa ibabaw pa rin ng lupa. Sapat na 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Taking each hour as it comes. How about yourself?",
                            },
                            ["TL"] = {
                                "Bawat oras kinakaya. Ikaw, kumusta ka?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Alive and alert. Hoping the peace lasts.",
                            },
                            ["TL"] = {
                                "Buhay at gising. Sana magtagal ang katahimikan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Watching the perimeter, making sure we're unbothered.",
                            },
                            ["TL"] = {
                                "Binabantayan ang paligid para masigurong ligtas tayo.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_default_alt.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "conversation_whats_up",
        ["id"] = "semantic.question.whats_up.default_alt.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "terse",
            ["sourceId"] = "semantic.question.whats_up.default_alt.terse",
            ["sourcePath"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_default_alt.json#records[2]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ConversationWhatsUp",
        ["namespace"] = "semantic.question.whats_up.default_alt",
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
                ["category"] = "projecthoomans:conversation_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.conversation",
                ["responseTemplateID"] = "semantic.question.whats_up.default_alt",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/conversation.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "Staying alive.",
                            },
                            ["TL"] = {
                                "Basta buhay.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Watching the road.",
                            },
                            ["TL"] = {
                                "Bantay sa daan.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Same old.",
                            },
                            ["TL"] = {
                                "Ganoon pa rin.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Alert.",
                            },
                            ["TL"] = {
                                "Alerto.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "On watch.",
                            },
                            ["TL"] = {
                                "Naka-duty.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Still upright.",
                            },
                            ["TL"] = {
                                "Nakatayo pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Road's clear.",
                            },
                            ["TL"] = {
                                "Ligtas ang daan.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Keeping sharp.",
                            },
                            ["TL"] = {
                                "Matalas pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Nothing to report.",
                            },
                            ["TL"] = {
                                "Walang bago.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Breathing.",
                            },
                            ["TL"] = {
                                "Huminga pa.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_default_alt.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "conversation_whats_up",
        ["id"] = "semantic.question.whats_up.default_alt.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "warm",
            ["sourceId"] = "semantic.question.whats_up.default_alt.warm",
            ["sourcePath"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_default_alt.json#records[3]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ConversationWhatsUp",
        ["namespace"] = "semantic.question.whats_up.default_alt",
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
                ["category"] = "projecthoomans:conversation_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.conversation",
                ["responseTemplateID"] = "semantic.question.whats_up.default_alt",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/conversation.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "Same as ever. Staying alive and watching the road. What about you?",
                            },
                            ["TL"] = {
                                "Gaya ng dati. Nanatiling buhay at binabantayan ang daan. Ikaw, kumusta?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Still here, still kicking. Seeing you makes the watch feel shorter.",
                            },
                            ["TL"] = {
                                "Nandito pa rin, lumalaban pa. Gumagaan ang bantay kapag nakikita kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Watching the perimeter, but always glad to share a few words with you.",
                            },
                            ["TL"] = {
                                "Nagbabantay sa paligid, pero laging masayang makausap ka kahit saglit.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Making sure the road stays safe for all of us. Hope you're doing well.",
                            },
                            ["TL"] = {
                                "Sinisigurong ligtas ang daan para sa ating lahat. Sana maayos ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Alive and well, friend. Truly good to run into you today.",
                            },
                            ["TL"] = {
                                "Buhay at maayos, kaibigan. Masaya talaga akong nakasalubong kita ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Taking in the daylight while we can. Glad you're walking safe.",
                            },
                            ["TL"] = {
                                "Nilalasap ang liwanag ng araw. Masaya akong naglalakad kang ligtas.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Another day on our feet together. What could be better than that?",
                            },
                            ["TL"] = {
                                "Isa pang araw na magkasama tayong nakatayo. Ano pa bang mas maganda roon?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "Just keeping an eye out for our people. Thanks for checking in.",
                            },
                            ["TL"] = {
                                "Nagmamasid lang para sa kapakanan ng lahat. Salamat sa pangangamusta.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Holding the line with a glad heart today. How are things on your end?",
                            },
                            ["TL"] = {
                                "Nagbabantay nang may magaan na loob ngayon. Kumusta sa parte mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Still here, thankful for good companions like you. Stay safe.",
                            },
                            ["TL"] = {
                                "Nandito pa rin, nagpapasalamat sa mabubuting kasama tulad mo. Mag-ingat ka.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_default_alt.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "conversation_whats_up",
        ["id"] = "semantic.question.whats_up.traveling.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "guarded",
            ["sourceId"] = "semantic.question.whats_up.traveling.guarded",
            ["sourcePath"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_traveling.json#records[0]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ConversationWhatsUp",
        ["namespace"] = "semantic.question.whats_up.traveling",
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
                ["category"] = "projecthoomans:conversation_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.conversation",
                ["responseTemplateID"] = "semantic.question.whats_up.traveling",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/conversation.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Keeping moving. Don't slow me down.",
                            },
                            ["TL"] = {
                                "Patuloy lang sa paggalaw. Huwag mo akong pabagalin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "On the move. Don't block my path.",
                            },
                            ["TL"] = {
                                "Naglalakbay ako. Huwag kang humarang sa daan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Travel's dangerous right now. Step aside.",
                            },
                            ["TL"] = {
                                "Mapanganib ang daan ngayon. Tabi muna.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Covering ground. I don't stay in one spot too long.",
                            },
                            ["TL"] = {
                                "Tuloy-tuloy ang lakad ko. Hindi ako tumatambay nang matagal.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Moving fast, staying light. No time to chat.",
                            },
                            ["TL"] = {
                                "Mabilis ang lakad, magaan ang dala. Walang oras makipag-usap.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Don't follow too closely. I walk alone.",
                            },
                            ["TL"] = {
                                "Huwag kang masyadong lumapit. Nag-iisa akong naglalakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Just passing through. Mind your own road.",
                            },
                            ["TL"] = {
                                "Dumadaan lang. Asikasuhin mo ang sarili mong daan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Got places to be before dark. Move along.",
                            },
                            ["TL"] = {
                                "May pupuntahan ako bago magdilim. Lumakad ka na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Traveling light and watching behind me. Stand clear.",
                            },
                            ["TL"] = {
                                "Magaan ang dala at laging tumitingin sa likod. Tabi ka riyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Moving between points. Don't compromise my route.",
                            },
                            ["TL"] = {
                                "Lumilipat ng pwesto. Huwag mong sirain ang ruta ko.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_traveling.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "conversation_whats_up",
        ["id"] = "semantic.question.whats_up.traveling.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "neutral",
            ["sourceId"] = "semantic.question.whats_up.traveling.neutral",
            ["sourcePath"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_traveling.json#records[1]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ConversationWhatsUp",
        ["namespace"] = "semantic.question.whats_up.traveling",
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
                ["category"] = "projecthoomans:conversation_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.conversation",
                ["responseTemplateID"] = "semantic.question.whats_up.traveling",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/conversation.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm keeping moving and watching what is ahead.",
                            },
                            ["TL"] = {
                                "Patuloy akong gumagalaw at binabantayan ang nasa unahan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Just trekking from point to point. Road's fairly calm.",
                            },
                            ["TL"] = {
                                "Naglalakad lang mula pwesto hanggang pwesto. Medyo kalmado ang kalsada.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Making headway before the sun starts dropping.",
                            },
                            ["TL"] = {
                                "Bumabaybay habang mataas pa ang araw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Covering some ground today. How's the path behind you?",
                            },
                            ["TL"] = {
                                "Marami-rami na ring nalakad ngayon. Kumusta ang daan sa pinanggalingan mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "On the road again. Gotta keep moving to find supplies.",
                            },
                            ["TL"] = {
                                "Nasa kalsada na naman. Kailangang gumalaw para maghanap ng gamit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Heading out on a scouting loop. Everything looks quiet.",
                            },
                            ["TL"] = {
                                "Nag-iikot para magmanman. Mukhang tahimik naman ang lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Putting miles under my boots. Helps clear my head.",
                            },
                            ["TL"] = {
                                "Tuloy lang sa paghakbang. Nakakatulong magpalinaw ng isip.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Just moving between shelters. Don't want to linger anywhere too long.",
                            },
                            ["TL"] = {
                                "Lumilipat lang ng silungan. Ayokong tumambay nang matagal sa iisang lugar.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Traveling down the lane. Hoping to avoid any hordes.",
                            },
                            ["TL"] = {
                                "Naglalakad sa kalsada. Sana walang makasalubong na kumpol ng patay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "On my way across the sector. How are things looking your way?",
                            },
                            ["TL"] = {
                                "Patawid ako sa kabilang bahagi. Kumusta ang kalagayan sa direksyon mo?",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_traveling.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "conversation_whats_up",
        ["id"] = "semantic.question.whats_up.traveling.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "terse",
            ["sourceId"] = "semantic.question.whats_up.traveling.terse",
            ["sourcePath"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_traveling.json#records[2]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ConversationWhatsUp",
        ["namespace"] = "semantic.question.whats_up.traveling",
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
                ["category"] = "projecthoomans:conversation_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.conversation",
                ["responseTemplateID"] = "semantic.question.whats_up.traveling",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/conversation.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "Keeping moving.",
                            },
                            ["TL"] = {
                                "Patuloy lang sa paggalaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "On the road.",
                            },
                            ["TL"] = {
                                "Nasa daan.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Traveling.",
                            },
                            ["TL"] = {
                                "Naglalakbay.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Moving out.",
                            },
                            ["TL"] = {
                                "Umaalis.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Passing through.",
                            },
                            ["TL"] = {
                                "Dumadaan lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Covering ground.",
                            },
                            ["TL"] = {
                                "Naglalakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "On the move.",
                            },
                            ["TL"] = {
                                "Kumikilos.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Headed out.",
                            },
                            ["TL"] = {
                                "Papunta na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "In transit.",
                            },
                            ["TL"] = {
                                "Bumabyahe.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Pushing ahead.",
                            },
                            ["TL"] = {
                                "Pasulong.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_traveling.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "conversation_whats_up",
        ["id"] = "semantic.question.whats_up.traveling.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "warm",
            ["sourceId"] = "semantic.question.whats_up.traveling.warm",
            ["sourcePath"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_traveling.json#records[3]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ConversationWhatsUp",
        ["namespace"] = "semantic.question.whats_up.traveling",
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
                ["category"] = "projecthoomans:conversation_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.conversation",
                ["responseTemplateID"] = "semantic.question.whats_up.traveling",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/conversation.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm keeping moving and watching what is ahead. Come along if you want.",
                            },
                            ["TL"] = {
                                "Patuloy akong gumagalaw at binabantayan ang nasa unahan. Sumama ka kung gusto mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "On the trail today! It's always safer and nicer walking together.",
                            },
                            ["TL"] = {
                                "Nasa daan ngayon! Laging mas ligtas at masaya kapag may kasamang maglakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Traveling light. Feel free to tag along if you're headed that way.",
                            },
                            ["TL"] = {
                                "Magaan ang dala. Sumabay ka kung papunta ka rin doon.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Making my way down the road. Glad I crossed paths with you today.",
                            },
                            ["TL"] = {
                                "Bumabagtas sa daan. Masaya akong nakasalubong kita ngayong araw.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Covering ground, but always happy to pause and say hello to a friend.",
                            },
                            ["TL"] = {
                                "Nagmamadali man, masaya pa ring huminto para kumustahin ang kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Walking between camps. Safe travels on your end, my friend.",
                            },
                            ["TL"] = {
                                "Naglalakad patungo sa kabilang kampo. Ingat sa biyahe mo, kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Heading out for a bit. Watch your step, and maybe we'll meet again soon.",
                            },
                            ["TL"] = {
                                "Aalis lang sandali. Mag-ingat sa paghakbang, at magkikita rin tayo mamaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "The road feels a lot less lonely whenever I see you around.",
                            },
                            ["TL"] = {
                                "Hindi nakakalungkot ang daan kapag nakakasalubong kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Moving along, but I'm glad our paths crossed. Stay safe out there.",
                            },
                            ["TL"] = {
                                "Lumalakad, pero masayang nagkasalubong tayo. Mag-ingat ka palagi sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Traveling to check on our boundaries. Good to see you in high spirits.",
                            },
                            ["TL"] = {
                                "Tinitingnan ang hangganan ng kampo. Masarap kang makitang nasa maayos na lagay.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_traveling.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "conversation_whats_up",
        ["id"] = "semantic.question.whats_up.weather.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "guarded",
            ["sourceId"] = "semantic.question.whats_up.weather.guarded",
            ["sourcePath"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_weather.json#records[0]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ConversationWhatsUp",
        ["namespace"] = "semantic.question.whats_up.weather",
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
                ["category"] = "projecthoomans:conversation_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.conversation",
                ["responseTemplateID"] = "semantic.question.whats_up.weather",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/conversation.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Watching the weather. Stay focused.",
                            },
                            ["TL"] = {
                                "Binabantayan ko ang panahon. Manatiling nakatutok.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Storms bring trouble. Don't linger out in the open.",
                            },
                            ["TL"] = {
                                "Bagyo ang nagdadala ng gulo. Huwag kang tumambay sa bukas na lugar.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Sky looks nasty. Get your head in the game.",
                            },
                            ["TL"] = {
                                "Madilim ang langit. Maghanda ka sa anumang darating.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Bad weather makes it easy for them to sneak up. Stay alert.",
                            },
                            ["TL"] = {
                                "Mas madali silang makalapit kapag masama ang panahon. Maging alerto.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Wind is masking noises. Keep your ears open and back off.",
                            },
                            ["TL"] = {
                                "Tinatabunan ng hangin ang mga ingay. Maging mapagmatyag at umatras ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Clouds are gathering. I don't plan on getting caught out here.",
                            },
                            ["TL"] = {
                                "Makulimlim na. Wala akong balak abutan ng ulan dito sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Weather is turning. Stop wasting time chatting.",
                            },
                            ["TL"] = {
                                "Papasama ang panahon. Huwag magsayang ng oras sa pakikipag-usap.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Fog or rain will blind us. Keep your weapon ready.",
                            },
                            ["TL"] = {
                                "Mabubulag tayo sa hamog o ulan. Ihanda ang armas mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Eyeing the clouds. You'd better find cover too.",
                            },
                            ["TL"] = {
                                "Tinitingnan ko ang mga ulap. Mabuti pang maghanap ka na rin ng masisilungan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "A storm is brewing. I'm focusing on shelter.",
                            },
                            ["TL"] = {
                                "May paparating na bagyo. Naghahanap ako ng masisilungan.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_weather.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "conversation_whats_up",
        ["id"] = "semantic.question.whats_up.weather.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "neutral",
            ["sourceId"] = "semantic.question.whats_up.weather.neutral",
            ["sourcePath"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_weather.json#records[1]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ConversationWhatsUp",
        ["namespace"] = "semantic.question.whats_up.weather",
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
                ["category"] = "projecthoomans:conversation_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.conversation",
                ["responseTemplateID"] = "semantic.question.whats_up.weather",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/conversation.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "The weather is the main thing on my mind right now.",
                            },
                            ["TL"] = {
                                "Ang panahon ang pangunahing iniisip ko ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Looks like the skies might turn on us soon.",
                            },
                            ["TL"] = {
                                "Mukhang sasama ang lagay ng panahon maya-maya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Watching the clouds roll in. Hope we stay dry.",
                            },
                            ["TL"] = {
                                "Tinitingnan ang pagdating ng mga ulap. Sana manatiling tuyo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Cold wind's picking up today. Harder to stay warm.",
                            },
                            ["TL"] = {
                                "Lumalakas ang malamig na hangin ngayon. Mahirap magpainit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Can't afford to get soaked out here without a fire.",
                            },
                            ["TL"] = {
                                "Hindi puwedeng mabasa rito kung walang apoy.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Hoping the rain holds off until we finish our runs.",
                            },
                            ["TL"] = {
                                "Sana huwag munang umulan hanggang sa matapos ang mga lakad natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Weather's unpredictable lately. Keeping an eye on the sky.",
                            },
                            ["TL"] = {
                                "Pabago-bago ang panahon kamakailan. Laging nakatingin sa langit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Temperature is dropping fast. Gonna be a cold night.",
                            },
                            ["TL"] = {
                                "Bumababa nang mabilis ang temperatura. Magiging malamig ang gabi.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Just thinking about finding a roof before the weather hits.",
                            },
                            ["TL"] = {
                                "Iniisip ko lang makahanap ng bubong bago dumating ang ulan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Clear skies for now, but you never know when it'll shift.",
                            },
                            ["TL"] = {
                                "Maliwanag pa naman ngayon, pero hindi mo masasabi kung kailan magbabago.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_weather.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "conversation_whats_up",
        ["id"] = "semantic.question.whats_up.weather.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "terse",
            ["sourceId"] = "semantic.question.whats_up.weather.terse",
            ["sourcePath"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_weather.json#records[2]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ConversationWhatsUp",
        ["namespace"] = "semantic.question.whats_up.weather",
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
                ["category"] = "projecthoomans:conversation_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.conversation",
                ["responseTemplateID"] = "semantic.question.whats_up.weather",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/conversation.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "Watching the weather.",
                            },
                            ["TL"] = {
                                "Binabantayan ang panahon.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Rain coming.",
                            },
                            ["TL"] = {
                                "Uulan na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Cold wind.",
                            },
                            ["TL"] = {
                                "Malamig ang hangin.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Dark clouds.",
                            },
                            ["TL"] = {
                                "Makulimlim.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Weather's turning.",
                            },
                            ["TL"] = {
                                "Papasama ang panahon.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Storm brewing.",
                            },
                            ["TL"] = {
                                "May bagyo.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Need shelter.",
                            },
                            ["TL"] = {
                                "Kailangan ng masisilungan.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Stay dry.",
                            },
                            ["TL"] = {
                                "Manatiling tuyo.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Freezing out.",
                            },
                            ["TL"] = {
                                "Napakalamig.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Windy.",
                            },
                            ["TL"] = {
                                "Mahangin.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_weather.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "conversation_whats_up",
        ["id"] = "semantic.question.whats_up.weather.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "warm",
            ["sourceId"] = "semantic.question.whats_up.weather.warm",
            ["sourcePath"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_weather.json#records[3]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ConversationWhatsUp",
        ["namespace"] = "semantic.question.whats_up.weather",
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
                ["category"] = "projecthoomans:conversation_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.conversation",
                ["responseTemplateID"] = "semantic.question.whats_up.weather",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/conversation.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "The weather is the main thing on my mind right now. How are you holding up?",
                            },
                            ["TL"] = {
                                "Ang panahon ang pangunahing iniisip ko ngayon. Kumusta ka naman?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Chilly out here today. Make sure you bundle up and stay warm, alright?",
                            },
                            ["TL"] = {
                                "Malamig dito ngayon. Magsuot ka ng makapal at magpainit, ha?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Looks like rain might fall. Let's make sure our dry clothes stay safe.",
                            },
                            ["TL"] = {
                                "Mukhang uulan. Siguraduhin nating ligtas ang mga tuyo nating damit.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "I was just watching the clouds. Hope you've got a warm fire waiting for you.",
                            },
                            ["TL"] = {
                                "Pinagmamasdan ko ang mga ulap. Sana may mainit kang masisilungan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Cold wind today, but seeing your face makes it feel a bit warmer.",
                            },
                            ["TL"] = {
                                "Malamig ang hangin, pero nakakabawas ng ginaw na makita ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Hoping the bad weather passes over us without trouble. Stay dry out there.",
                            },
                            ["TL"] = {
                                "Sana lumampas ang masamang panahon nang walang gulo. Manatiling tuyo sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Weather's rough, but we'll weather any storm together, my friend.",
                            },
                            ["TL"] = {
                                "Mabigat ang panahon, pero kakayanin natin anumang bagyo, kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "If it starts pouring, come share some shelter with us.",
                            },
                            ["TL"] = {
                                "Kapag nagsimulang bumuhos ang ulan, sumilong ka kasama namin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Just keeping an eye on the sky so none of our people get caught in the wet.",
                            },
                            ["TL"] = {
                                "Binabantayan ang langit para walang mabasa sa mga kasamahan natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Gloomy day outside, but good company makes all the difference.",
                            },
                            ["TL"] = {
                                "Madilim ang araw sa labas, pero iba talaga kapag may magandang kasama.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/conversation_whats_up/question_whats_up_weather.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
