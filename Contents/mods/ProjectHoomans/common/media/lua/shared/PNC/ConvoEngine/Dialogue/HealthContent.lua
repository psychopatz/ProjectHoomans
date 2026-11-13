-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.health_state.healthy.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "guarded",
            ["sourceId"] = "semantic.question.health_state.healthy.guarded",
            ["sourcePath"] = "adopters/hoomans/dialogue/health_content/question_health_state_healthy.json#records[0]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/HealthContent",
        ["namespace"] = "semantic.question.health_state.healthy",
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
                ["category"] = "projecthoomans:health_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.health",
                ["responseTemplateID"] = "semantic.question.health_state.healthy",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/health/health_state.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm fine. Don't make a thing of it.",
                            },
                            ["TL"] = {
                                "Mabuti ako. Huwag mo nang palakihin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Nothing wrong with me. Keep your eyes on the road.",
                            },
                            ["TL"] = {
                                "Walang mali sa akin. Tumutok ka sa daan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "No injuries to report. Step back.",
                            },
                            ["TL"] = {
                                "Walang sugat na dapat sabihin. Umatras ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "I'm in fighting shape. Don't worry about me.",
                            },
                            ["TL"] = {
                                "Kaya ko pang lumaban. Huwag mo akong alalahanin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Not a scratch on me. That's all you get.",
                            },
                            ["TL"] = {
                                "Kahit gasgas wala ako. Iyon lang ang masasabi ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'm completely healthy. Leave it alone.",
                            },
                            ["TL"] = {
                                "Malusog ako. Huwag mo nang usisain.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Body's holding up just fine. Mind your own health.",
                            },
                            ["TL"] = {
                                "Maayos ang katawan ko. Asikasuhin mo ang sarili mong kalusugan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Clean bill of health. You don't need to inspect me.",
                            },
                            ["TL"] = {
                                "Ligtas ako sa anumang sakit. Hindi mo kailangang siyasatin ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'm intact and able-bodied. Let's move on.",
                            },
                            ["TL"] = {
                                "Buo ako at maayos ang katawan. Magpatuloy na tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "No wounds, no sickness. Keep your distance.",
                            },
                            ["TL"] = {
                                "Walang sugat, walang sakit. Lumayo ka.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/health_content/question_health_state_healthy.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.health_state.healthy.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "neutral",
            ["sourceId"] = "semantic.question.health_state.healthy.neutral",
            ["sourcePath"] = "adopters/hoomans/dialogue/health_content/question_health_state_healthy.json#records[1]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/HealthContent",
        ["namespace"] = "semantic.question.health_state.healthy",
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
                ["category"] = "projecthoomans:health_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.health",
                ["responseTemplateID"] = "semantic.question.health_state.healthy",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/health/health_state.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm doing okay.",
                            },
                            ["TL"] = {
                                "Ayos lang ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Healthy as can be expected out here.",
                            },
                            ["TL"] = {
                                "Malusog naman ayon sa inaasahan dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "No wounds or sickness bothering me right now.",
                            },
                            ["TL"] = {
                                "Walang sugat o sakit na gumugulo sa akin ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Feeling solid. No injuries to speak of.",
                            },
                            ["TL"] = {
                                "Maayos ang pakiramdam ko. Walang iniindang sugat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I'm in good health today, all things considered.",
                            },
                            ["TL"] = {
                                "Mabuti ang kalusugan ko ngayon, sa kabila ng lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Everything's working the way it should.",
                            },
                            ["TL"] = {
                                "Gumagana ang lahat nang maayos sa katawan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "No complaints on the physical side today.",
                            },
                            ["TL"] = {
                                "Walang reklamo sa pisikal kong kalagayan ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Feeling intact and steady. No wounds on me.",
                            },
                            ["TL"] = {
                                "Buo at matatag ang pakiramdam ko. Walang sugat sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Health is holding up fine. Ready for work.",
                            },
                            ["TL"] = {
                                "Maayos ang kalusugan ko. Handa na para sa gawain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Not carrying any injuries right now.",
                            },
                            ["TL"] = {
                                "Wala akong iniindang anumang sugat ngayon.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/health_content/question_health_state_healthy.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.health_state.healthy.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "terse",
            ["sourceId"] = "semantic.question.health_state.healthy.terse",
            ["sourcePath"] = "adopters/hoomans/dialogue/health_content/question_health_state_healthy.json#records[2]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/HealthContent",
        ["namespace"] = "semantic.question.health_state.healthy",
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
                ["category"] = "projecthoomans:health_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.health",
                ["responseTemplateID"] = "semantic.question.health_state.healthy",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/health/health_state.json",
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
                                "Ayos lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Healthy.",
                            },
                            ["TL"] = {
                                "Malusog.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "No injuries.",
                            },
                            ["TL"] = {
                                "Walang sugat.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "All clear.",
                            },
                            ["TL"] = {
                                "Ligtas.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
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
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Uninjured.",
                            },
                            ["TL"] = {
                                "Walang tama.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Doing fine.",
                            },
                            ["TL"] = {
                                "Maayos.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "No wounds.",
                            },
                            ["TL"] = {
                                "Walang sugat.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Good shape.",
                            },
                            ["TL"] = {
                                "Magandang kondisyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Solid.",
                            },
                            ["TL"] = {
                                "Matatag.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/health_content/question_health_state_healthy.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.health_state.healthy.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "warm",
            ["sourceId"] = "semantic.question.health_state.healthy.warm",
            ["sourcePath"] = "adopters/hoomans/dialogue/health_content/question_health_state_healthy.json#records[3]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/HealthContent",
        ["namespace"] = "semantic.question.health_state.healthy",
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
                ["category"] = "projecthoomans:health_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.health",
                ["responseTemplateID"] = "semantic.question.health_state.healthy",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/health/health_state.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm doing okay. Thanks for checking in.",
                            },
                            ["TL"] = {
                                "Ayos lang ako. Salamat sa pagsuri.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Healthy and feeling good today. Truly appreciate you asking.",
                            },
                            ["TL"] = {
                                "Malusog at maganda ang pakiramdam ko ngayon. Salamat sa pagtatanong.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Not a scratch on me. Glad you're keeping an eye out.",
                            },
                            ["TL"] = {
                                "Kahit gasgas wala ako. Salamat sa pagbabantay.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Feeling strong and healthy, friend. Hope you are too.",
                            },
                            ["TL"] = {
                                "Malakas at malusog ang pakiramdam ko, kaibigan. Sana ikaw rin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "All intact on my side. Thank you for looking after me.",
                            },
                            ["TL"] = {
                                "Buo ang lahat sa akin. Salamat sa pag-aalaga mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Doing wonderfully, thank you. It's comforting that you asked.",
                            },
                            ["TL"] = {
                                "Napakaganda ng kalagayan ko, salamat. Nakakapanatag na nagtanong ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "In great health today. Ready to face whatever comes our way.",
                            },
                            ["TL"] = {
                                "Napakalusog ko ngayon. Handa harapin ang anumang dumating.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "Feeling well rested and sound. Appreciate the kind check-in.",
                            },
                            ["TL"] = {
                                "Mabuti ang pahinga at kalagayan ko. Salamat sa magandang pangangamusta.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "No bumps or scrapes today. Thank you for caring.",
                            },
                            ["TL"] = {
                                "Walang pasa o gasgas ngayon. Salamat sa pagmamalasakit.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "I'm doing great, honestly. Let's make sure we both stay that way.",
                            },
                            ["TL"] = {
                                "Maayos talaga ako. Siguraduhin nating manatili tayong parehong ganito.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/health_content/question_health_state_healthy.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.health_state.injured.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "guarded",
            ["sourceId"] = "semantic.question.health_state.injured.guarded",
            ["sourcePath"] = "adopters/hoomans/dialogue/health_content/question_health_state_injured.json#records[0]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/HealthContent",
        ["namespace"] = "semantic.question.health_state.injured",
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
                ["category"] = "projecthoomans:health_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.health",
                ["responseTemplateID"] = "semantic.question.health_state.injured",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/health/health_state.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm hurt. Give me space.",
                            },
                            ["TL"] = {
                                "Nasaktan ako. Bigyan mo ako ng espasyo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Took some damage. I don't need your pity.",
                            },
                            ["TL"] = {
                                "May tama ako. Hindi ko kailangan ang awa mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Got injured, but I'm still dangerous. Step back.",
                            },
                            ["TL"] = {
                                "Nasugatan ako, pero mapanganib pa rin ako. Umatras ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Bleeding, but it's under control. Don't hover.",
                            },
                            ["TL"] = {
                                "Dumudugo, pero kontrolado ko. Huwag kang mag-aligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "I'm wounded. That doesn't mean I'm helpless.",
                            },
                            ["TL"] = {
                                "Sugatan ako. Hindi ibig sabihing wala na akong magagawa.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "I can bandage my own wounds, thank you.",
                            },
                            ["TL"] = {
                                "Kaya kong bendahan ang sarili kong sugat, salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "It hurts, but you don't need to pry into it.",
                            },
                            ["TL"] = {
                                "Masakit, pero hindi mo kailangang mag-usisa.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Just a bad cut. Keep your hands where I can see them.",
                            },
                            ["TL"] = {
                                "Malalim na sugat lang. Ipakita mo ang mga kamay mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'm dealing with the pain. Leave me be.",
                            },
                            ["TL"] = {
                                "Inaayos ko ang iniinda ko. Hayaan mo muna ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Injured, yes. Vulnerable, no. Back off.",
                            },
                            ["TL"] = {
                                "Sugatan, oo. Mahina, hindi. Lumayo ka.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/health_content/question_health_state_injured.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.health_state.injured.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "neutral",
            ["sourceId"] = "semantic.question.health_state.injured.neutral",
            ["sourcePath"] = "adopters/hoomans/dialogue/health_content/question_health_state_injured.json#records[1]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/HealthContent",
        ["namespace"] = "semantic.question.health_state.injured",
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
                ["category"] = "projecthoomans:health_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.health",
                ["responseTemplateID"] = "semantic.question.health_state.injured",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/health/health_state.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm hurt, but I'm managing.",
                            },
                            ["TL"] = {
                                "Nasaktan ako, pero kinakaya ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Took a beating earlier. Bandages are holding for now.",
                            },
                            ["TL"] = {
                                "Medyo napuruhan kanina. Hawak pa naman ng benda sa ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Nursing a wound here. Trying not to reopen it.",
                            },
                            ["TL"] = {
                                "Inaalagaan ko ang sugat na ito. Iniiwasang bumuka ulit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I've been injured, but nothing that'll take me down.",
                            },
                            ["TL"] = {
                                "Nasugatan ako, pero hindi 'to makakapagpatumba sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Got caught in a bad spot. Dealing with the damage.",
                            },
                            ["TL"] = {
                                "Naipit sa masamang sitwasyon. Tinitiis ang tinamong sugat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Bleeding is mostly stopped, but movement is painful.",
                            },
                            ["TL"] = {
                                "Karamihan sa dugo tumigil na, pero masakit kumilos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Stung pretty bad by an attack earlier.",
                            },
                            ["TL"] = {
                                "Kumikirot pa rin mula sa pag-atake kanina.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Injuries are slowing me down, but I can keep moving.",
                            },
                            ["TL"] = {
                                "Pinapabagal ako ng mga sugat, pero kaya pang lumakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Could use some medical supplies when we find them.",
                            },
                            ["TL"] = {
                                "Kailangan ko ng gamot kapag nakahanap tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I'm hurting right now, but taking it step by step.",
                            },
                            ["TL"] = {
                                "Masakit ang katawan ko ngayon, pero dahan-dahan lang.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/health_content/question_health_state_injured.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.health_state.injured.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "terse",
            ["sourceId"] = "semantic.question.health_state.injured.terse",
            ["sourcePath"] = "adopters/hoomans/dialogue/health_content/question_health_state_injured.json#records[2]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/HealthContent",
        ["namespace"] = "semantic.question.health_state.injured",
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
                ["category"] = "projecthoomans:health_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.health",
                ["responseTemplateID"] = "semantic.question.health_state.injured",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/health/health_state.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm hurt.",
                            },
                            ["TL"] = {
                                "Nasaktan ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Wounded.",
                            },
                            ["TL"] = {
                                "Sugatan.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Need stitches.",
                            },
                            ["TL"] = {
                                "Kailangan ng tahi.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
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
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Hurts bad.",
                            },
                            ["TL"] = {
                                "Sobrang sakit.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Bandaged up.",
                            },
                            ["TL"] = {
                                "May benda.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Still bleeding.",
                            },
                            ["TL"] = {
                                "Dumudugo pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Took damage.",
                            },
                            ["TL"] = {
                                "Tinamaan.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Slowed down.",
                            },
                            ["TL"] = {
                                "Bumagal.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Managing pain.",
                            },
                            ["TL"] = {
                                "Tinitiis.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/health_content/question_health_state_injured.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.health_state.injured.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "warm",
            ["sourceId"] = "semantic.question.health_state.injured.warm",
            ["sourcePath"] = "adopters/hoomans/dialogue/health_content/question_health_state_injured.json#records[3]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/HealthContent",
        ["namespace"] = "semantic.question.health_state.injured",
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
                ["category"] = "projecthoomans:health_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.health",
                ["responseTemplateID"] = "semantic.question.health_state.injured",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/health/health_state.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm hurt, but I'm managing. Thanks for asking.",
                            },
                            ["TL"] = {
                                "Nasaktan ako, pero kinakaya ko. Salamat sa pagtatanong.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Took a hit out there, but knowing you're here helps a lot.",
                            },
                            ["TL"] = {
                                "Tinamaan ako sa labas, pero malaking tulong na nandito ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "It hurts, friend, but I promise I'm holding together.",
                            },
                            ["TL"] = {
                                "Masakit, kaibigan, pero nangangako akong kakayanin ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Got banged up a little. Thank you for your care and concern.",
                            },
                            ["TL"] = {
                                "Medyo napuruhan ako. Salamat sa malasakit mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Nursing a wound, but seeing you safe gives me strength.",
                            },
                            ["TL"] = {
                                "May sugat ako, pero nagbibigay ng lakas na ligtas ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'll pull through with some rest. Thanks for checking on me.",
                            },
                            ["TL"] = {
                                "Makakaraos din ako kapag nakapagpahinga. Salamat sa pangangamusta.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "It's painful, but we'll patch it up together, right?",
                            },
                            ["TL"] = {
                                "Masakit, pero gagamutin natin ito nang magkasama, di ba?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "Appreciate the check-in. Don't worry too much about me.",
                            },
                            ["TL"] = {
                                "Salamat sa pagsuri. Huwag kang masyadong mag-alala sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Got scratched up bad, but I'm glad you're by my side.",
                            },
                            ["TL"] = {
                                "Malala ang gasgas ko, pero masaya akong nasa tabi kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Hurts like hell, but having good folks around keeps me going.",
                            },
                            ["TL"] = {
                                "Napakasakit, pero ang mabubuting kasama ang nagpapatuloy sa akin.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/health_content/question_health_state_injured.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.health_state.unknown.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "guarded",
            ["sourceId"] = "semantic.question.health_state.unknown.guarded",
            ["sourcePath"] = "adopters/hoomans/dialogue/health_content/question_health_state_unknown.json#records[0]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/HealthContent",
        ["namespace"] = "semantic.question.health_state.unknown",
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
                ["category"] = "projecthoomans:health_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.health",
                ["responseTemplateID"] = "semantic.question.health_state.unknown",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/health/health_state.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "I can't confirm that.",
                            },
                            ["TL"] = {
                                "Hindi ko makumpirma iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Haven't checked properly yet. Mind your own business.",
                            },
                            ["TL"] = {
                                "Hindi ko pa nasusuri nang maayos. Asikasuhin mo ang sarili mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Can't tell right now, and I'm not stripping down to check.",
                            },
                            ["TL"] = {
                                "Hindi ko masabi ngayon, at hindi ako maghuhubad para magpakita.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Unsure. I'll evaluate my own condition later.",
                            },
                            ["TL"] = {
                                "Hindi sigurado. Susuriin ko ang sarili ko mamaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "No idea. Too chaotic out here to be certain.",
                            },
                            ["TL"] = {
                                "Walang ideya. Masyadong magulo rito para makasiguro.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "I don't have that information right now. Stand back.",
                            },
                            ["TL"] = {
                                "Wala akong impormasyon diyan ngayon. Umatras ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Hard to tell through the layers. Let it go.",
                            },
                            ["TL"] = {
                                "Mahirap malaman dahil sa kapal ng damit. Hayaan mo na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Can't be certain. Focus on your own status.",
                            },
                            ["TL"] = {
                                "Hindi makasiguro. Ituon ang pansin sa sarili mong kalagayan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Not clear yet. Don't crowd me.",
                            },
                            ["TL"] = {
                                "Hindi pa malinaw. Huwag mo akong pagkumpulan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Status unknown. I'll deal with it when I'm safe.",
                            },
                            ["TL"] = {
                                "Hindi tiyak ang kalagayan. Aayusin ko 'to kapag ligtas na.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/health_content/question_health_state_unknown.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.health_state.unknown.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "neutral",
            ["sourceId"] = "semantic.question.health_state.unknown.neutral",
            ["sourcePath"] = "adopters/hoomans/dialogue/health_content/question_health_state_unknown.json#records[1]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/HealthContent",
        ["namespace"] = "semantic.question.health_state.unknown",
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
                ["category"] = "projecthoomans:health_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.health",
                ["responseTemplateID"] = "semantic.question.health_state.unknown",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/health/health_state.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I can't confirm my health status right now.",
                            },
                            ["TL"] = {
                                "Hindi ko makumpirma ang kalagayan ko ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Haven't had a chance to inspect myself thoroughly.",
                            },
                            ["TL"] = {
                                "Hindi pa ako nagkakaroon ng pagkakataong suriin ang sarili ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Not entirely sure how bad it is under the gear.",
                            },
                            ["TL"] = {
                                "Hindi ako sigurado kung gaano kalala sa ilalim ng suot ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Could be bleeding, could just be a bruise. Hard to tell.",
                            },
                            ["TL"] = {
                                "Pwedeng dumudugo, pwedeng pasa lang. Mahirap masabi.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Need a quiet moment to check over my condition.",
                            },
                            ["TL"] = {
                                "Kailangan ko ng tahimik na sandali para masuri ang katawan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Uncertain right now. Adrenaline is masking the pain.",
                            },
                            ["TL"] = {
                                "Hindi sigurado ngayon. Natatakpan ng adrenaline ang sakit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Hard to tell without a mirror or better light.",
                            },
                            ["TL"] = {
                                "Mahirap malaman kung walang salamin o mas maayos na ilaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I feel sore all over, but can't verify the specifics.",
                            },
                            ["TL"] = {
                                "Masakit ang buong katawan ko, pero hindi ko matukoy ang dahilan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Can't confirm if anything is broken or sprained yet.",
                            },
                            ["TL"] = {
                                "Hindi pa makumpirma kung may bali o pilay ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "My condition is uncertain at the moment.",
                            },
                            ["TL"] = {
                                "Hindi tiyak ang kalagayan ko sa mga sandaling ito.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/health_content/question_health_state_unknown.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.health_state.unknown.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "terse",
            ["sourceId"] = "semantic.question.health_state.unknown.terse",
            ["sourcePath"] = "adopters/hoomans/dialogue/health_content/question_health_state_unknown.json#records[2]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/HealthContent",
        ["namespace"] = "semantic.question.health_state.unknown",
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
                ["category"] = "projecthoomans:health_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.health",
                ["responseTemplateID"] = "semantic.question.health_state.unknown",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/health/health_state.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "Can't confirm.",
                            },
                            ["TL"] = {
                                "Hindi makumpirma.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Unsure.",
                            },
                            ["TL"] = {
                                "Hindi sigurado.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Not sure yet.",
                            },
                            ["TL"] = {
                                "Hindi pa tiyak.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Need to check.",
                            },
                            ["TL"] = {
                                "Kailangang suriin.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Unknown.",
                            },
                            ["TL"] = {
                                "Hindi alam.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Hard to say.",
                            },
                            ["TL"] = {
                                "Mahirap sabihin.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Can't tell.",
                            },
                            ["TL"] = {
                                "Hindi masabi.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Need a look.",
                            },
                            ["TL"] = {
                                "Kailangang tingnan.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Unchecked.",
                            },
                            ["TL"] = {
                                "Hindi pa nasusuri.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Too early to tell.",
                            },
                            ["TL"] = {
                                "Masyadong maaga pa.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/health_content/question_health_state_unknown.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.health_state.unknown.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "warm",
            ["sourceId"] = "semantic.question.health_state.unknown.warm",
            ["sourcePath"] = "adopters/hoomans/dialogue/health_content/question_health_state_unknown.json#records[3]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/HealthContent",
        ["namespace"] = "semantic.question.health_state.unknown",
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
                ["category"] = "projecthoomans:health_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.health",
                ["responseTemplateID"] = "semantic.question.health_state.unknown",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/health/health_state.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "I can't confirm it right now, but thanks for asking.",
                            },
                            ["TL"] = {
                                "Hindi ko makumpirma ngayon, pero salamat sa pagtatanong.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Not sure how bad it is yet, but I appreciate your concern.",
                            },
                            ["TL"] = {
                                "Hindi pa sigurado kung gaano kalala, pero salamat sa pag-alala.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Haven't checked properly, but I'll let you know once I do.",
                            },
                            ["TL"] = {
                                "Hindi pa nasusuri nang maayos, pero sasabihin ko sa 'yo kapag nasuri ko na.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Hard to tell right now, friend. Thanks for watching over me.",
                            },
                            ["TL"] = {
                                "Mahirap masabi ngayon, kaibigan. Salamat sa pagbabantay sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "I need to check under the bandages, but I'm grateful you asked.",
                            },
                            ["TL"] = {
                                "Kailangan kong tingnan sa ilalim ng benda, pero salamat sa pagtanong.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Uncertain for now, but your support means everything to me.",
                            },
                            ["TL"] = {
                                "Hindi sigurado sa ngayon, pero mahalaga ang suporta mo sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Could be fine, could be bruised. Thanks for caring enough to check.",
                            },
                            ["TL"] = {
                                "Pwedeng ayos lang, pwedeng may pasa. Salamat sa pagmamalasakit.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'll do a proper check when we're safe. Thank you, truly.",
                            },
                            ["TL"] = {
                                "Magsusuri ako kapag ligtas na tayo. Maraming salamat talaga.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Can't say for sure, but I feel safer with you here.",
                            },
                            ["TL"] = {
                                "Hindi masabi nang tiyak, pero mas panatag ako at nandito ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Not sure yet, but don't worry yourself sick over me.",
                            },
                            ["TL"] = {
                                "Hindi pa sigurado, pero huwag kang magpakapagod mag-alala.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/health_content/question_health_state_unknown.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.medical_bite.negative.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "guarded",
            ["sourceId"] = "semantic.question.medical_bite.negative.guarded",
            ["sourcePath"] = "adopters/hoomans/dialogue/health_content/question_medical_bite_negative.json#records[0]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/HealthContent",
        ["namespace"] = "semantic.question.medical_bite.negative",
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
                ["category"] = "projecthoomans:health_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.health",
                ["responseTemplateID"] = "semantic.question.medical_bite.negative",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/health/medical_bite.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "No bite. Leave it there.",
                            },
                            ["TL"] = {
                                "Walang kagat. Tama na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "I'm clean. Don't look at me like that.",
                            },
                            ["TL"] = {
                                "Malinis ako. Huwag mo akong tingnan nang ganyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Not bitten. Stop inspecting me.",
                            },
                            ["TL"] = {
                                "Hindi nakagat. Itigil mo ang pagsusuri sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "No teeth touched my skin. Back off.",
                            },
                            ["TL"] = {
                                "Walang ngiping tumama sa balat ko. Lumayo ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "I checked thoroughly. I am not infected.",
                            },
                            ["TL"] = {
                                "Sinuri ko nang maayos. Hindi ako infected.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "No bite marks anywhere. Put your weapon down.",
                            },
                            ["TL"] = {
                                "Walang bakas ng kagat kahit saan. Ibaba mo ang armas mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "I know the protocol. I don't have a bite.",
                            },
                            ["TL"] = {
                                "Alam ko ang patakaran. Wala akong kagat.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Clean skin. Don't jump to conclusions.",
                            },
                            ["TL"] = {
                                "Malinis ang balat ko. Huwag kang magbintang agad.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Not a single bite mark. Keep your distance regardless.",
                            },
                            ["TL"] = {
                                "Kahit isang bakas ng kagat wala. Lumayo ka pa rin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "I am not turning. Drop the interrogation.",
                            },
                            ["TL"] = {
                                "Hindi ako magiging isa sa kanila. Itigil ang pagtatanong.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/health_content/question_medical_bite_negative.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.medical_bite.negative.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "neutral",
            ["sourceId"] = "semantic.question.medical_bite.negative.neutral",
            ["sourcePath"] = "adopters/hoomans/dialogue/health_content/question_medical_bite_negative.json#records[1]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/HealthContent",
        ["namespace"] = "semantic.question.medical_bite.negative",
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
                ["category"] = "projecthoomans:health_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.health",
                ["responseTemplateID"] = "semantic.question.medical_bite.negative",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/health/medical_bite.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "No, I don't have a recorded bite.",
                            },
                            ["TL"] = {
                                "Hindi, wala akong naitalang kagat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Checked myself over. No bites anywhere.",
                            },
                            ["TL"] = {
                                "Sinuri ko ang sarili ko. Walang kagat kahit saan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'm clean. None of them got their teeth in me.",
                            },
                            ["TL"] = {
                                "Malinis ako. Walang nakakagat sa akin sa kanila.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "No bite marks at all, thankfully.",
                            },
                            ["TL"] = {
                                "Walang anumang bakas ng kagat, salamat sa Diyos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Skin's intact. No bites from the dead.",
                            },
                            ["TL"] = {
                                "Buo ang balat ko. Walang kagat mula sa mga patay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I made sure to inspect every scratch. No bites.",
                            },
                            ["TL"] = {
                                "Tiningnan ko bawat gasgas. Walang kagat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Free and clear of any bite wounds.",
                            },
                            ["TL"] = {
                                "Ligtas at malinis ako sa anumang sugat ng kagat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Didn't get bitten. The armor held up.",
                            },
                            ["TL"] = {
                                "Hindi nakagat. Nakatulong ang proteksyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "No bites on me, I can assure you.",
                            },
                            ["TL"] = {
                                "Walang kagat sa akin, makakasiguro ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I checked carefully. No bites, just scratches.",
                            },
                            ["TL"] = {
                                "Sinuri kong mabuti. Walang kagat, gasgas lang.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/health_content/question_medical_bite_negative.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.medical_bite.negative.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "terse",
            ["sourceId"] = "semantic.question.medical_bite.negative.terse",
            ["sourcePath"] = "adopters/hoomans/dialogue/health_content/question_medical_bite_negative.json#records[2]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/HealthContent",
        ["namespace"] = "semantic.question.medical_bite.negative",
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
                ["category"] = "projecthoomans:health_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.health",
                ["responseTemplateID"] = "semantic.question.medical_bite.negative",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/health/medical_bite.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "No bite.",
                            },
                            ["TL"] = {
                                "Walang kagat.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Clean.",
                            },
                            ["TL"] = {
                                "Malinis.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Not bitten.",
                            },
                            ["TL"] = {
                                "Hindi nakagat.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "No teeth marks.",
                            },
                            ["TL"] = {
                                "Walang bakas.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Skin intact.",
                            },
                            ["TL"] = {
                                "Buo ang balat.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'm clear.",
                            },
                            ["TL"] = {
                                "Ligtas ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Negative.",
                            },
                            ["TL"] = {
                                "Negatibo.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "All clear.",
                            },
                            ["TL"] = {
                                "Lahat malinis.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "No infection.",
                            },
                            ["TL"] = {
                                "Walang impeksyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Not turning.",
                            },
                            ["TL"] = {
                                "Hindi magbabago.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/health_content/question_medical_bite_negative.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.medical_bite.negative.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "warm",
            ["sourceId"] = "semantic.question.medical_bite.negative.warm",
            ["sourcePath"] = "adopters/hoomans/dialogue/health_content/question_medical_bite_negative.json#records[3]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/HealthContent",
        ["namespace"] = "semantic.question.medical_bite.negative",
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
                ["category"] = "projecthoomans:health_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.health",
                ["responseTemplateID"] = "semantic.question.medical_bite.negative",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/health/medical_bite.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "No, I don't have a recorded bite. Thanks for checking.",
                            },
                            ["TL"] = {
                                "Hindi, wala akong naitalang kagat. Salamat sa pagsuri.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "I'm clean, friend. None of them got through my guard.",
                            },
                            ["TL"] = {
                                "Malinis ako, kaibigan. Walang nakalusot sa depensa ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "No bite marks on me. Good to know you're looking out for camp.",
                            },
                            ["TL"] = {
                                "Walang kagat sa akin. Mabuti at nagbabantay ka para sa kampo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Completely free of bites, thank God. Appreciate the check.",
                            },
                            ["TL"] = {
                                "Ligtas sa anumang kagat, salamat sa Diyos. Salamat sa pagsuri.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "I checked thoroughly, nothing to fear. We're safe.",
                            },
                            ["TL"] = {
                                "Sinuri ko nang maayos, walang dapat ikatakot. Ligtas tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "No bites! Relieved to tell you I'm completely in the clear.",
                            },
                            ["TL"] = {
                                "Walang kagat! Masaya akong sabihing ligtas na ligtas ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Skin is clean. Thank you for doing the hard safety checks.",
                            },
                            ["TL"] = {
                                "Malinis ang balat ko. Salamat sa pagsasagawa ng mahigpit na pagsusuri.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "You can breathe easy, no bites on me.",
                            },
                            ["TL"] = {
                                "Makakahinga ka nang maluwag, walang kagat sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "All clear on the bite front. Thank you for your care.",
                            },
                            ["TL"] = {
                                "Walang anumang kagat. Salamat sa pag-aalala mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Not bitten at all, friend. I'm staying right here with you.",
                            },
                            ["TL"] = {
                                "Hinding-hindi nakagat, kaibigan. Mananatili ako rito kasama mo.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/health_content/question_medical_bite_negative.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.medical_bite.positive.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "guarded",
            ["sourceId"] = "semantic.question.medical_bite.positive.guarded",
            ["sourcePath"] = "adopters/hoomans/dialogue/health_content/question_medical_bite_positive.json#records[0]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/HealthContent",
        ["namespace"] = "semantic.question.medical_bite.positive",
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
                ["category"] = "projecthoomans:health_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.health",
                ["responseTemplateID"] = "semantic.question.medical_bite.positive",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/health/medical_bite.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Yes. I've been bitten. That's all.",
                            },
                            ["TL"] = {
                                "Oo. Nakagat ako. Tama na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "They got me. Don't make a scene.",
                            },
                            ["TL"] = {
                                "Nakuha nila ako. Huwag kang magsisigaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "I was bitten. Keep your gun ready if you must.",
                            },
                            ["TL"] = {
                                "Nakagat ako. Ihanda mo ang baril mo kung kinakailangan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Yes, it happened. Stay back from me.",
                            },
                            ["TL"] = {
                                "Oo, nangyari. Lumayo ka sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Got teeth in my arm. I know what that means.",
                            },
                            ["TL"] = {
                                "May kagat sa braso ko. Alam ko ang ibig sabihin niyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Bitten. Don't touch me.",
                            },
                            ["TL"] = {
                                "Nakagat. Huwag mo akong hawakan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "It's true. I don't want your sympathy.",
                            },
                            ["TL"] = {
                                "Totoo. Hindi ko kailangan ang awa mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "One of them bit me. Step away.",
                            },
                            ["TL"] = {
                                "Kinagat ako ng isa sa kanila. Umatras ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'm marked. Do what you have to do.",
                            },
                            ["TL"] = {
                                "May marka na ako. Gawin mo ang dapat mong gawin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Yes. I won't let myself become a danger to you.",
                            },
                            ["TL"] = {
                                "Oo. Hindi ko hahayaang maging panganib ako sa 'yo.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/health_content/question_medical_bite_positive.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.medical_bite.positive.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "neutral",
            ["sourceId"] = "semantic.question.medical_bite.positive.neutral",
            ["sourcePath"] = "adopters/hoomans/dialogue/health_content/question_medical_bite_positive.json#records[1]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/HealthContent",
        ["namespace"] = "semantic.question.medical_bite.positive",
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
                ["category"] = "projecthoomans:health_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.health",
                ["responseTemplateID"] = "semantic.question.medical_bite.positive",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/health/medical_bite.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Yes, I've been bitten.",
                            },
                            ["TL"] = {
                                "Oo, nakagat ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "One of them got their teeth in me. It's bad.",
                            },
                            ["TL"] = {
                                "Nabaon ng isa sa kanila ang ngipin sa akin. Masama ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I got bitten during the struggle. No denying it.",
                            },
                            ["TL"] = {
                                "Nakagat ako habang nagpupumiglas. Hindi maikakaila.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "There's a bite mark on my shoulder. I'm infected.",
                            },
                            ["TL"] = {
                                "May bakas ng kagat sa balikat ko. Nahawaan ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "It broke the skin. I know what's coming.",
                            },
                            ["TL"] = {
                                "Bumaon sa balat. Alam ko kung ano ang kahihinatnan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Yes, unfortunately. I was bitten.",
                            },
                            ["TL"] = {
                                "Oo, sa kasamaang-palad. Nakagat ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "They got through my sleeve. It's a bite.",
                            },
                            ["TL"] = {
                                "Lumusot sa manggas ko. Kagat nga.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I've been bitten. We need to plan for what comes next.",
                            },
                            ["TL"] = {
                                "Nakagat ako. Kailangan nating pag-isipan ang susunod na gagawin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Found the mark earlier. I was bitten.",
                            },
                            ["TL"] = {
                                "Nakita ko ang marka kanina. Nakagat talaga ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I'm infected. A walker bit me.",
                            },
                            ["TL"] = {
                                "Nahawaan na ako. Kinagat ako ng patay.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/health_content/question_medical_bite_positive.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.medical_bite.positive.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "terse",
            ["sourceId"] = "semantic.question.medical_bite.positive.terse",
            ["sourcePath"] = "adopters/hoomans/dialogue/health_content/question_medical_bite_positive.json#records[2]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/HealthContent",
        ["namespace"] = "semantic.question.medical_bite.positive",
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
                ["category"] = "projecthoomans:health_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.health",
                ["responseTemplateID"] = "semantic.question.medical_bite.positive",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/health/medical_bite.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "Yes. I've been bitten.",
                            },
                            ["TL"] = {
                                "Oo. Nakagat ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Bitten.",
                            },
                            ["TL"] = {
                                "Nakagat.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "They got me.",
                            },
                            ["TL"] = {
                                "Nakuha ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "It's a bite.",
                            },
                            ["TL"] = {
                                "Kagat ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Infected.",
                            },
                            ["TL"] = {
                                "Nahawaan.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'm turned.",
                            },
                            ["TL"] = {
                                "Mamamatay ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Bite mark.",
                            },
                            ["TL"] = {
                                "Bakas ng kagat.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Yes.",
                            },
                            ["TL"] = {
                                "Oo.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Skin broke.",
                            },
                            ["TL"] = {
                                "Bumaon.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "It's over.",
                            },
                            ["TL"] = {
                                "Tapos na.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/health_content/question_medical_bite_positive.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.medical_bite.positive.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "warm",
            ["sourceId"] = "semantic.question.medical_bite.positive.warm",
            ["sourcePath"] = "adopters/hoomans/dialogue/health_content/question_medical_bite_positive.json#records[3]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/HealthContent",
        ["namespace"] = "semantic.question.medical_bite.positive",
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
                ["category"] = "projecthoomans:health_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.health",
                ["responseTemplateID"] = "semantic.question.medical_bite.positive",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/health/medical_bite.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "Yes. I've been bitten, and I appreciate you checking.",
                            },
                            ["TL"] = {
                                "Oo. Nakagat ako, at salamat sa pagsuri.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "They got me, friend. I'm sorry to bring you this news.",
                            },
                            ["TL"] = {
                                "Nakuha nila ako, kaibigan. Pasensya na sa masamang balita.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "I was bitten. Thank you for caring enough to ask me directly.",
                            },
                            ["TL"] = {
                                "Nakagat ako. Salamat sa pagtatanong nang diretso sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "It happened. I'm just glad I got to know you before the end.",
                            },
                            ["TL"] = {
                                "Nangyari na. Masaya akong nakilala kita bago ang lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "I've been bitten. Please, keep yourself safe when the time comes.",
                            },
                            ["TL"] = {
                                "Nakagat ako. Pakiusap, protektahan mo ang sarili mo pagdating ng oras.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Yes, they got their teeth in me. Thank you for standing by me.",
                            },
                            ["TL"] = {
                                "Oo, kinagat nila ako. Salamat sa pananatili sa tabi ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "I won't hide it from you. I was bitten. Take care of yourself.",
                            },
                            ["TL"] = {
                                "Hindi ko itatago sa 'yo. Nakagat ako. Alagaan mo ang sarili mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "It's a bite, friend. I appreciate all the times we shared.",
                            },
                            ["TL"] = {
                                "Kagat nga, kaibigan. Salamat sa lahat ng pinagsamahan natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'm infected. Thank you for treating me like a human being.",
                            },
                            ["TL"] = {
                                "Nahawaan na ako. Salamat sa pagtrato sa akin bilang kapwa tao.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "They bit me. Don't be sad; we fought as hard as we could.",
                            },
                            ["TL"] = {
                                "Kinagat nila ako. Huwag kang malungkot; lumaban tayo nang buong husay.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/health_content/question_medical_bite_positive.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.medical_bite.unknown.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "guarded",
            ["sourceId"] = "semantic.question.medical_bite.unknown.guarded",
            ["sourcePath"] = "adopters/hoomans/dialogue/health_content/question_medical_bite_unknown.json#records[0]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/HealthContent",
        ["namespace"] = "semantic.question.medical_bite.unknown",
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
                ["category"] = "projecthoomans:health_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.health",
                ["responseTemplateID"] = "semantic.question.medical_bite.unknown",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/health/medical_bite.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "I can't confirm that. Don't press me.",
                            },
                            ["TL"] = {
                                "Hindi ko makumpirma. Huwag mo nang ipilit.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Haven't checked yet. Keep your distance until I do.",
                            },
                            ["TL"] = {
                                "Hindi pa ako nakakatingin. Lumayo ka muna hangga't hindi pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "I don't know for sure. Back off and let me look.",
                            },
                            ["TL"] = {
                                "Hindi ako sigurado. Umatras ka at hayaan mo akong tingnan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Can't tell through this armor. Don't jump to conclusions.",
                            },
                            ["TL"] = {
                                "Hindi masabi dahil sa suot ko. Huwag kang magbintang.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Too much blood to tell whose it is. Back away.",
                            },
                            ["TL"] = {
                                "Masyadong maraming dugo para malaman kung kanino. Umatras ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "I need a mirror first. Stop staring at me.",
                            },
                            ["TL"] = {
                                "Kailangan ko ng salamin muna. Huwag mo akong titigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Unsure. I'll inspect myself in private.",
                            },
                            ["TL"] = {
                                "Hindi sigurado. Magsusuri ako nang mag-isa.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Can't confirm. Keep your weapon holstered.",
                            },
                            ["TL"] = {
                                "Hindi makumpirma. Huwag mong ilabas ang armas mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "I don't know yet. Don't treat me like an infected.",
                            },
                            ["TL"] = {
                                "Hindi ko pa alam. Huwag mo akong itrato na parang infected.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Unknown. Stay where you are until I know.",
                            },
                            ["TL"] = {
                                "Hindi alam. Diyan ka lang hangga't hindi ko nasisiguro.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/health_content/question_medical_bite_unknown.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.medical_bite.unknown.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "neutral",
            ["sourceId"] = "semantic.question.medical_bite.unknown.neutral",
            ["sourcePath"] = "adopters/hoomans/dialogue/health_content/question_medical_bite_unknown.json#records[1]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/HealthContent",
        ["namespace"] = "semantic.question.medical_bite.unknown",
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
                ["category"] = "projecthoomans:health_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.health",
                ["responseTemplateID"] = "semantic.question.medical_bite.unknown",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/health/medical_bite.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I can't confirm whether I've been bitten.",
                            },
                            ["TL"] = {
                                "Hindi ko makumpirma kung nakagat ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Haven't had a chance to strip down and check properly.",
                            },
                            ["TL"] = {
                                "Hindi pa ako nagkakaroon ng oras para maghubad at suriin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "There were too many hands grabbing at me to be certain.",
                            },
                            ["TL"] = {
                                "Masyadong maraming humawak sa akin para makasiguro.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Felt teeth scrape, but can't see if it broke the skin.",
                            },
                            ["TL"] = {
                                "Naramdaman ko ang ngipin, pero hindi kita kung bumaon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Need someone with good light to inspect my back.",
                            },
                            ["TL"] = {
                                "Kailangan ng may maayos na ilaw para tingnan ang likod ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Not sure yet. The wound is covered in dirt and blood.",
                            },
                            ["TL"] = {
                                "Hindi pa sigurado. Balot ng dumi at dugo ang sugat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Could be a scratch, could be teeth. Can't tell yet.",
                            },
                            ["TL"] = {
                                "Pwedeng gasgas, pwedeng ngipin. Hindi pa masabi.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I haven't checked every spot yet. Need a minute.",
                            },
                            ["TL"] = {
                                "Hindi ko pa nasusuri ang bawat parte. Bigyan mo ako ng sandali.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Cloth is torn, but not sure if the skin is punctured.",
                            },
                            ["TL"] = {
                                "Punit ang damit, pero hindi sigurado kung bumaon sa balat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Bite status is unknown right now. Waiting to check.",
                            },
                            ["TL"] = {
                                "Hindi pa alam kung nakagat. Naghihintay masuri.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/health_content/question_medical_bite_unknown.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.medical_bite.unknown.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "terse",
            ["sourceId"] = "semantic.question.medical_bite.unknown.terse",
            ["sourcePath"] = "adopters/hoomans/dialogue/health_content/question_medical_bite_unknown.json#records[2]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/HealthContent",
        ["namespace"] = "semantic.question.medical_bite.unknown",
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
                ["category"] = "projecthoomans:health_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.health",
                ["responseTemplateID"] = "semantic.question.medical_bite.unknown",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/health/medical_bite.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "Can't confirm.",
                            },
                            ["TL"] = {
                                "Hindi makumpirma.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Not sure.",
                            },
                            ["TL"] = {
                                "Hindi sigurado.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Haven't checked.",
                            },
                            ["TL"] = {
                                "Hindi pa nasusuri.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Unknown.",
                            },
                            ["TL"] = {
                                "Hindi alam.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Need to look.",
                            },
                            ["TL"] = {
                                "Kailangang tingnan.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Hard to tell.",
                            },
                            ["TL"] = {
                                "Mahirap sabihin.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Torn cloth.",
                            },
                            ["TL"] = {
                                "Punit na damit.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Uncertain.",
                            },
                            ["TL"] = {
                                "Hindi tiyak.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Can't see it.",
                            },
                            ["TL"] = {
                                "Hindi ko makita.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Waiting to check.",
                            },
                            ["TL"] = {
                                "Titingnan pa.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/health_content/question_medical_bite_unknown.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "health_content",
        ["id"] = "semantic.question.medical_bite.unknown.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "warm",
            ["sourceId"] = "semantic.question.medical_bite.unknown.warm",
            ["sourcePath"] = "adopters/hoomans/dialogue/health_content/question_medical_bite_unknown.json#records[3]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/HealthContent",
        ["namespace"] = "semantic.question.medical_bite.unknown",
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
                ["category"] = "projecthoomans:health_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.health",
                ["responseTemplateID"] = "semantic.question.medical_bite.unknown",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/health/medical_bite.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "I can't confirm it, but thanks for checking.",
                            },
                            ["TL"] = {
                                "Hindi ko makumpirma, pero salamat sa pagsuri.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "I'm not sure yet, friend. I'll check carefully in a safe spot.",
                            },
                            ["TL"] = {
                                "Hindi pa ako sigurado, kaibigan. Titingnan ko nang maayos sa ligtas na lugar.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Haven't had a proper look, but thank you for looking out for me.",
                            },
                            ["TL"] = {
                                "Hindi ko pa natingnan nang maigi, pero salamat sa pagbabantay sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Hard to see back there. Mind helping me take a look soon?",
                            },
                            ["TL"] = {
                                "Mahirap makita sa likod. Pwede mo ba akong tulungang tingnan mamaya?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Unsure right now, but I promise I'll be honest with you.",
                            },
                            ["TL"] = {
                                "Hindi sigurado ngayon, pero nangangako akong magiging tapat ako sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "I pray it's just a tear in my jacket. Thanks for asking gently.",
                            },
                            ["TL"] = {
                                "Sana punit lang sa jacket. Salamat sa maingat na pagtatanong.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Not certain yet, but let's find shelter before we inspect.",
                            },
                            ["TL"] = {
                                "Hindi pa tiyak, pero maghanap muna tayo ng masisilungan bago sumuri.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "Could be nothing, could be bad. Thank you for staying calm.",
                            },
                            ["TL"] = {
                                "Pwedeng wala lang, pwedeng masama. Salamat sa pananatiling kalmado.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "I haven't checked every scratch, but your concern warms my heart.",
                            },
                            ["TL"] = {
                                "Hindi ko pa nasusuri ang bawat gasgas, pero nagpapasalamat ako sa pag-alala mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "I'll let you know the moment I check. Thank you for your care.",
                            },
                            ["TL"] = {
                                "Sasabihin ko agad pagkatapos kong masuri. Salamat sa malasakit mo.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/health_content/question_medical_bite_unknown.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
