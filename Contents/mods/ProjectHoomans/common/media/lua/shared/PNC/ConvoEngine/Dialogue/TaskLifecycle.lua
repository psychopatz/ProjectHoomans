-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.gift.completed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.gift.completed",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[20]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.gift.completed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/gift.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Thank you for the gift.",
                            },
                            ["TL"] = {
                                "Salamat sa regalo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I appreciate this gesture. Thank you.",
                            },
                            ["TL"] = {
                                "Salamat sa magandang kalooban. Maraming salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "That's generous of you. Thanks.",
                            },
                            ["TL"] = {
                                "Bukas-palad ka. Salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Thank you! This will be put to good use.",
                            },
                            ["TL"] = {
                                "Salamat! Magagamit ito nang maayos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "A welcome surprise. Thank you, friend.",
                            },
                            ["TL"] = {
                                "Magandang sorpresa. Salamat, kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Much obliged for the gift.",
                            },
                            ["TL"] = {
                                "Maraming salamat sa regalo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I'm grateful for this. Thank you.",
                            },
                            ["TL"] = {
                                "Nagpapasalamat ako rito. Salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "You didn't have to, but thanks a lot.",
                            },
                            ["TL"] = {
                                "Di mo kailangang gawin, pero maraming salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Received with gratitude. Thank you.",
                            },
                            ["TL"] = {
                                "Tinatanggap kalakip ang pasasalamat. Salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Thanks for thinking of me with this gift.",
                            },
                            ["TL"] = {
                                "Salamat sa pag-alala sa akin sa regalong ito.",
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
        ["sourceShard"] = "psdl/dialogue/task_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.gift.failed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.gift.failed",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[21]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.gift.failed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/gift.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I couldn't accept that gift.",
                            },
                            ["TL"] = {
                                "Hindi ko matanggap ang regalong iyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Something went wrong while transferring the gift.",
                            },
                            ["TL"] = {
                                "May nangyaring mali habang ipinapasa ang regalo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Gift transfer failed. My hands were full.",
                            },
                            ["TL"] = {
                                "Bigo ang paglipat ng regalo. Puno ang kamay ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Couldn't receive that right now.",
                            },
                            ["TL"] = {
                                "Di matanggap 'yan sa ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to take the gift into my inventory.",
                            },
                            ["TL"] = {
                                "Di mailagay ang regalo sa lalagyan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Transaction interrupted. Gift not taken.",
                            },
                            ["TL"] = {
                                "Naabala ang pagbibigay. Di nakuha ang regalo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Failed to receive the offering.",
                            },
                            ["TL"] = {
                                "Bigo sa pagtanggap ng alay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I dropped it or couldn't hold it.",
                            },
                            ["TL"] = {
                                "Nahulog ko o di nahawakan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Gift transfer could not be completed.",
                            },
                            ["TL"] = {
                                "Di natapos ang paglipat ng regalo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Couldn't take that from you.",
                            },
                            ["TL"] = {
                                "Di ko nakuha 'yan mula sa 'yo.",
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
        ["sourceShard"] = "psdl/dialogue/task_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.gift.pending",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.gift.pending",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[22]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.gift.pending",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/gift.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'll take a look at that gift.",
                            },
                            ["TL"] = {
                                "Titingnan ko ang regalong iyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Let's see what you brought.",
                            },
                            ["TL"] = {
                                "Tingnan natin kung ano ang dala mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Considering the gift now.",
                            },
                            ["TL"] = {
                                "Tinitingnan ang regalo ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Inspecting what you have for me.",
                            },
                            ["TL"] = {
                                "Sinusuri ang handog mo para sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Hold on, looking at the offering.",
                            },
                            ["TL"] = {
                                "Teka, tinitingnan ang iniaalok.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'll review the item you offered.",
                            },
                            ["TL"] = {
                                "Susuriin ko ang bagay na inialok mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Checking out the gift.",
                            },
                            ["TL"] = {
                                "Tinitingnan ang regalo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Let me examine what this is.",
                            },
                            ["TL"] = {
                                "Hayaan mong tingnan ko kung ano ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Looking over your gift.",
                            },
                            ["TL"] = {
                                "Sinusuri ang regalo mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Give me a second to check this item.",
                            },
                            ["TL"] = {
                                "Bigyan mo ako ng sandali para tingnan ang gamit na ito.",
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
        ["sourceShard"] = "psdl/dialogue/task_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.gift.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.gift.rejected",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[23]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.gift.rejected",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/gift.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I can't accept that gift right now.",
                            },
                            ["TL"] = {
                                "Hindi ko matanggap ang regalong iyan ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Keep it. You need it more than I do.",
                            },
                            ["TL"] = {
                                "Itabi mo. Mas kailangan mo 'yan kaysa sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I have no room for gifts in my pack.",
                            },
                            ["TL"] = {
                                "Wala nang espasyo sa bag ko para sa mga regalo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I don't feel comfortable taking this from you.",
                            },
                            ["TL"] = {
                                "Hindi magaan sa loob ko na tanggapin ito sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Refusing this gift. We're not there yet.",
                            },
                            ["TL"] = {
                                "Tinatanggihan ang regalo. Di pa tayo ganoon kalapit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Save your supplies. Don't waste them on me.",
                            },
                            ["TL"] = {
                                "Itabi ang gamit mo. Huwag mong sayangin sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I cannot take that offering.",
                            },
                            ["TL"] = {
                                "Di ko matatanggap ang alay na 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "No thanks. I carry my own weight.",
                            },
                            ["TL"] = {
                                "Hindi salamat. Kaya kong dalhin ang sarili ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Gift rejected. Keep your belongings.",
                            },
                            ["TL"] = {
                                "Tinatanggihan ang regalo. Itago ang pag-aari mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I won't accept that from you today.",
                            },
                            ["TL"] = {
                                "Di ko tatanggapin 'yan mula sa 'yo ngayong araw.",
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
        ["sourceShard"] = "psdl/dialogue/task_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.gift.selection_required",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.gift.selection_required",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[24]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.gift.selection_required",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/gift.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I need to see what you brought me first.",
                            },
                            ["TL"] = {
                                "Kailangan ko munang makita ang dala mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "What exactly are you offering me?",
                            },
                            ["TL"] = {
                                "Ano nga ba ang iniaalok mo sa akin?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Select an item to gift before I decide.",
                            },
                            ["TL"] = {
                                "Pumili ng bagay na ireregalo bago ako magpasya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Show me what you want to give.",
                            },
                            ["TL"] = {
                                "Ipakita mo kung ano ang nais mong ibigay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Which item are you trying to hand over?",
                            },
                            ["TL"] = {
                                "Aling gamit ba ang sinusubukan mong iabot?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Pick the specific item first.",
                            },
                            ["TL"] = {
                                "Piliin muna ang partikular na gamit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I can't take anything until you select it.",
                            },
                            ["TL"] = {
                                "Wala akong matatanggap hangga't di mo pinipili.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Show me what's in your hands.",
                            },
                            ["TL"] = {
                                "Ipakita mo ang nasa mga kamay mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "What gift are we talking about? Choose one.",
                            },
                            ["TL"] = {
                                "Anong regalo ba ang pinag-uusapan natin? Pumili ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Specify the gift from your inventory.",
                            },
                            ["TL"] = {
                                "Tukuyin ang regalo mula sa bag mo.",
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
        ["sourceShard"] = "psdl/dialogue/task_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.consume.active",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.task.consume.active",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[0]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.task.consume.active",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/consume.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm using that now.",
                            },
                            ["TL"] = {
                                "Ginagamit ko na iyon ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Currently using the item.",
                            },
                            ["TL"] = {
                                "Kasalukuyang ginagamit ang gamit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Applying it right now.",
                            },
                            ["TL"] = {
                                "Inilalapat na ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "In the middle of consuming that.",
                            },
                            ["TL"] = {
                                "Kasalukuyang ginagamit iyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Working through this item.",
                            },
                            ["TL"] = {
                                "Ginagamit ang bagay na ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Taking this now. Give me a second.",
                            },
                            ["TL"] = {
                                "Ginagamit ko na ito. Bigyan mo ako ng sandali.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Using the supplies as requested.",
                            },
                            ["TL"] = {
                                "Ginagamit ang mga kagamitan ayon sa hiling.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Consuming it right now.",
                            },
                            ["TL"] = {
                                "Ginagamit ko na ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Holding still to use this.",
                            },
                            ["TL"] = {
                                "Nakahinto para gamitin ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Using it. Almost done.",
                            },
                            ["TL"] = {
                                "Ginagamit na. Halos tapos na.",
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
        ["sourceShard"] = "psdl/dialogue/task_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.consume.admitted",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.task.consume.admitted",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[1]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.task.consume.admitted",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/consume.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'll use that.",
                            },
                            ["TL"] = {
                                "Gagamitin ko iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. I will consume that item.",
                            },
                            ["TL"] = {
                                "Naintindihan. Gagamitin ko ang bagay na iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "All right, I'll take that.",
                            },
                            ["TL"] = {
                                "Sige, gagamitin ko iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Good idea. I'll use it.",
                            },
                            ["TL"] = {
                                "Magandang ideya. Gagamitin ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Got it. Taking that now.",
                            },
                            ["TL"] = {
                                "Nakuha ko. Gagamitin na ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'll go ahead and apply that.",
                            },
                            ["TL"] = {
                                "Sige, ilalapat ko iyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. That will help.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Makatutulong iyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Right. Using that item.",
                            },
                            ["TL"] = {
                                "Sige. Gagamitin ang gamit na 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'll use what you specified.",
                            },
                            ["TL"] = {
                                "Gagamitin ko ang tinukoy mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Sounds good. Consuming it.",
                            },
                            ["TL"] = {
                                "Maganda 'yan. Gagamitin na.",
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
        ["sourceShard"] = "psdl/dialogue/task_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.consume.completed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.task.consume.completed",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[2]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.task.consume.completed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/consume.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "That's done.",
                            },
                            ["TL"] = {
                                "Tapos na iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Finished using that.",
                            },
                            ["TL"] = {
                                "Tapos nang gamitin iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "All used up. Feeling better.",
                            },
                            ["TL"] = {
                                "Naubos na. Mas maayos na ang pakiramdam.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Done. That helped out.",
                            },
                            ["TL"] = {
                                "Tapos na. Nakatulong iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Finished consuming the item.",
                            },
                            ["TL"] = {
                                "Natapos nang gamitin ang bagay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "That's taken care of.",
                            },
                            ["TL"] = {
                                "Naasikaso na iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "All done with that supply.",
                            },
                            ["TL"] = {
                                "Tapos na sa gamit na 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Consumed. Ready to move on.",
                            },
                            ["TL"] = {
                                "Nagamit na. Handa nang magpatuloy.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Finished. Much needed.",
                            },
                            ["TL"] = {
                                "Tapos na. Kailangan ko talaga 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Done. Put to good use.",
                            },
                            ["TL"] = {
                                "Tapos na. Nagamit nang maayos.",
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
        ["sourceShard"] = "psdl/dialogue/task_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.consume.failed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.task.consume.failed",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[3]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.task.consume.failed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/consume.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I couldn't use that.",
                            },
                            ["TL"] = {
                                "Hindi ko nagamit iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Failed to consume that item.",
                            },
                            ["TL"] = {
                                "Bigo sa paggamit ng bagay na iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Something interrupted me while trying to use that.",
                            },
                            ["TL"] = {
                                "May umabala sa akin habang sinusubukang gamitin iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Couldn't finish using it.",
                            },
                            ["TL"] = {
                                "Di natapos gamitin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to apply that right now.",
                            },
                            ["TL"] = {
                                "Di mailapat iyan sa ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Using that failed. Something went wrong.",
                            },
                            ["TL"] = {
                                "Pumalpak ang paggamit. May nangyaring mali.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I lost hold of it or couldn't use it.",
                            },
                            ["TL"] = {
                                "Nabitawan ko o di nagamit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Couldn't consume it. Area wasn't secure.",
                            },
                            ["TL"] = {
                                "Di nagamit. Di ligtas ang paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Action interrupted. Item not consumed.",
                            },
                            ["TL"] = {
                                "Naabala ang kilos. Di nagamit ang bagay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Failed to take that.",
                            },
                            ["TL"] = {
                                "Bigo sa paggamit niyan.",
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
        ["sourceShard"] = "psdl/dialogue/task_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.consume.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.task.consume.rejected",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[4]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.task.consume.rejected",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/consume.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I can't use that right now.",
                            },
                            ["TL"] = {
                                "Hindi ko magamit iyon ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I don't need to use that at the moment.",
                            },
                            ["TL"] = {
                                "Di ko kailangang gamitin iyan sa sandaling ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "That's not suitable for me right now.",
                            },
                            ["TL"] = {
                                "Di angkop sa akin 'yan ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to consume that. Not needed.",
                            },
                            ["TL"] = {
                                "Di magagamit 'yan. Di kailangan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I can't use that under these conditions.",
                            },
                            ["TL"] = {
                                "Di ko magagamit 'yan sa ganitong kalagayan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Save it for later. I don't need it now.",
                            },
                            ["TL"] = {
                                "Itabi mo muna. Di ko kailangan ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Refusing to consume that. Not appropriate.",
                            },
                            ["TL"] = {
                                "Tumatangging gamitin 'yan. Di nararapat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I don't have a use for that right now.",
                            },
                            ["TL"] = {
                                "Wala akong paggagamitan niyan ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Can't use that. Not the right time.",
                            },
                            ["TL"] = {
                                "Di magagamit 'yan. Maling oras.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Consume order rejected.",
                            },
                            ["TL"] = {
                                "Tinatanggihan ang utos na gamitin.",
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
        ["sourceShard"] = "psdl/dialogue/task_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.drink.active",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.task.drink.active",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[5]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.task.drink.active",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/drink.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Taking a drink now.",
                            },
                            ["TL"] = {
                                "Umiinom na ako ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Drinking some water right now.",
                            },
                            ["TL"] = {
                                "Umiinom ng kaunting tubig ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Quenching my thirst. Give me a second.",
                            },
                            ["TL"] = {
                                "Pinapawi ang uhaw. Sandali lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Currently having a drink.",
                            },
                            ["TL"] = {
                                "Kasalukuyang umiinom.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Taking some fluids now.",
                            },
                            ["TL"] = {
                                "Umiinom na ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Drinking. Needed this badly.",
                            },
                            ["TL"] = {
                                "Umiinom. Kailangang-kailangan ko ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Getting some water in me.",
                            },
                            ["TL"] = {
                                "Nagpapasok ng tubig sa katawan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Taking a quick drink.",
                            },
                            ["TL"] = {
                                "Umiinom nang mabilisan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Drinking now. Won't take long.",
                            },
                            ["TL"] = {
                                "Umiinom na. Di magtatagal.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Having a drink as ordered.",
                            },
                            ["TL"] = {
                                "Umiinom ayon sa utos.",
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
        ["sourceShard"] = "psdl/dialogue/task_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.drink.admitted",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.task.drink.admitted",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[6]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.task.drink.admitted",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/drink.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'll have a drink.",
                            },
                            ["TL"] = {
                                "Iinom ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Getting some water.",
                            },
                            ["TL"] = {
                                "Naintindihan. Kukuha ng tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I could use some water. Drinking now.",
                            },
                            ["TL"] = {
                                "Kailangan ko nga ng tubig. Iinom na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "All right, I'll hydrate.",
                            },
                            ["TL"] = {
                                "Sige, magpapatubig ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Good call. I was getting thirsty.",
                            },
                            ["TL"] = {
                                "Magandang paalala. Nauuhaw na nga ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'll take a drink from my supply.",
                            },
                            ["TL"] = {
                                "Iinom ako mula sa baon ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Hydrating immediately.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Iinom agad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Right. Taking a sip.",
                            },
                            ["TL"] = {
                                "Sige. Iinom nang kaunti.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'll drink that now.",
                            },
                            ["TL"] = {
                                "Iinumin ko na iyan ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Sounds good. Drinking.",
                            },
                            ["TL"] = {
                                "Maganda 'yan. Iinom na.",
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
        ["sourceShard"] = "psdl/dialogue/task_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.drink.completed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.task.drink.completed",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[7]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.task.drink.completed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/drink.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Much better. Thirst is gone.",
                            },
                            ["TL"] = {
                                "Mas maayos na. Wala na ang uhaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Finished drinking. Feeling refreshed.",
                            },
                            ["TL"] = {
                                "Tapos nang uminom. Maginhawa na ang pakiramdam.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "That hit the spot. Done drinking.",
                            },
                            ["TL"] = {
                                "Eksakto 'yon. Tapos nang uminom.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Hydrated and ready to move.",
                            },
                            ["TL"] = {
                                "May sapat nang tubig at handang kumilos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Finished that drink.",
                            },
                            ["TL"] = {
                                "Naubos na ang inumin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Done. Throat isn't parched anymore.",
                            },
                            ["TL"] = {
                                "Tapos na. Di na tuyo ang lalamunan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "All drank. Ready for action.",
                            },
                            ["TL"] = {
                                "Nainom na lahat. Handa na sa aksyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Finished having a drink.",
                            },
                            ["TL"] = {
                                "Natapos nang uminom.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Done drinking. Let's keep going.",
                            },
                            ["TL"] = {
                                "Tapos nang uminom. Tuloy na tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Hydration complete.",
                            },
                            ["TL"] = {
                                "Kumpleto na ang pag-inom.",
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
        ["sourceShard"] = "psdl/dialogue/task_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.drink.failed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.task.drink.failed",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[8]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.task.drink.failed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/drink.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I couldn't get a drink.",
                            },
                            ["TL"] = {
                                "Hindi ako nakainom.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Failed to drink. Container was empty or tainted.",
                            },
                            ["TL"] = {
                                "Bigo sa pag-inom. Walang laman o marumi ang lalagyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Couldn't drink that. It wasn't clean water.",
                            },
                            ["TL"] = {
                                "Di mainom 'yon. Di malinis na tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I was interrupted before I could drink.",
                            },
                            ["TL"] = {
                                "Naabala ako bago ako nakainom.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to have a drink right now.",
                            },
                            ["TL"] = {
                                "Di makainom sa ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Spilled it or couldn't reach it. Drinking failed.",
                            },
                            ["TL"] = {
                                "Natapon o di naabot. Pumalpak ang pag-inom.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Water container is dry.",
                            },
                            ["TL"] = {
                                "Tuyot ang lalagyan ng tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Couldn't drink. Threat forced me to stop.",
                            },
                            ["TL"] = {
                                "Di nakainom. Napilitang huminto dahil sa banta.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Action failed. Still thirsty.",
                            },
                            ["TL"] = {
                                "Bigo ang kilos. Nauuhaw pa rin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Failed to take a drink.",
                            },
                            ["TL"] = {
                                "Bigo sa pag-inom.",
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
        ["sourceShard"] = "psdl/dialogue/task_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.drink.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.task.drink.rejected",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[9]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.task.drink.rejected",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/drink.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm not thirsty right now.",
                            },
                            ["TL"] = {
                                "Hindi ako nauuhaw ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I don't need to drink at the moment.",
                            },
                            ["TL"] = {
                                "Di ko kailangang uminom sa sandaling ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'm fully hydrated. Saving the water.",
                            },
                            ["TL"] = {
                                "Busog pa ako sa tubig. Itatabi ang inumin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Can't drink right now. Too dangerous to pause.",
                            },
                            ["TL"] = {
                                "Di pwedeng uminom ngayon. Masyadong mapanganib huminto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Refusing to drink that water. It looks tainted.",
                            },
                            ["TL"] = {
                                "Tumatangging inumin ang tubig na 'yan. Mukhang kontaminado.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I have plenty of fluids. Don't need to drink.",
                            },
                            ["TL"] = {
                                "Marami pa akong tubig sa katawan. Di kailangang uminom.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "No need for a drink yet.",
                            },
                            ["TL"] = {
                                "Wala pang pangangailangan sa inumin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'll save our clean water for later.",
                            },
                            ["TL"] = {
                                "Itatabi ko ang malinis na tubig mamaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Drink order rejected. Not parched.",
                            },
                            ["TL"] = {
                                "Tinatanggihan ang pag-inom. Di ako uhaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Can't drink that right now.",
                            },
                            ["TL"] = {
                                "Di ko maiinom 'yan ngayon.",
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
        ["sourceShard"] = "psdl/dialogue/task_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.eat.active",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.task.eat.active",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[10]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.task.eat.active",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/eat.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Eating now.",
                            },
                            ["TL"] = {
                                "Kumakain na ako ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Having a bite right now.",
                            },
                            ["TL"] = {
                                "Kumakain ng kaunti ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Chewing through some food. Give me a moment.",
                            },
                            ["TL"] = {
                                "Kumakain ng pagkain. Sandali lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Currently eating.",
                            },
                            ["TL"] = {
                                "Kasalukuyang kumakain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Getting some calories in me.",
                            },
                            ["TL"] = {
                                "Nagpapasok ng lakas sa katawan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Eating my rations now.",
                            },
                            ["TL"] = {
                                "Kinakain ang baong pagkain ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Taking a meal break as instructed.",
                            },
                            ["TL"] = {
                                "Kumakain ayon sa utos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Eating. Needed the energy.",
                            },
                            ["TL"] = {
                                "Kumakain. Kailangan ko ng lakas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Having some food now.",
                            },
                            ["TL"] = {
                                "Kumakain na ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Eating quietly. Won't be long.",
                            },
                            ["TL"] = {
                                "Kumakain nang tahimik. Saglit lang ito.",
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
        ["sourceShard"] = "psdl/dialogue/task_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.eat.admitted",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.task.eat.admitted",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[11]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.task.eat.admitted",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/eat.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'll eat that.",
                            },
                            ["TL"] = {
                                "Kakainin ko iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Getting something to eat.",
                            },
                            ["TL"] = {
                                "Naintindihan. Kukuha ng makakain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Good call. My stomach was growling.",
                            },
                            ["TL"] = {
                                "Magandang paalala. Kumakalam na ang tiyan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "All right, I'll eat some food.",
                            },
                            ["TL"] = {
                                "Sige, kakain ako ng pagkain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Taking a bite to keep my strength up.",
                            },
                            ["TL"] = {
                                "Kakain para mapanatili ang lakas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Eating now.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Kakain na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I'll consume those rations.",
                            },
                            ["TL"] = {
                                "Kakainin ko ang mga rasyong 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Right. Time for a meal.",
                            },
                            ["TL"] = {
                                "Sige. Oras na para kumain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'll eat what you designated.",
                            },
                            ["TL"] = {
                                "Kakainin ko ang tinukoy mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Sounds good. Grabbing food.",
                            },
                            ["TL"] = {
                                "Maganda 'yan. Kukuha ng pagkain.",
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
        ["sourceShard"] = "psdl/dialogue/task_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.eat.completed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.task.eat.completed",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[12]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.task.eat.completed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/eat.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Finished eating. Feeling much better.",
                            },
                            ["TL"] = {
                                "Tapos nang kumain. Mas maayos na ang pakiramdam.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "That food helped a lot. Done.",
                            },
                            ["TL"] = {
                                "Nakatulong nang malaki ang pagkain. Tapos na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Done eating. Energy restored.",
                            },
                            ["TL"] = {
                                "Tapos nang kumain. Bumalik na ang lakas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Stomach is full. Ready to move.",
                            },
                            ["TL"] = {
                                "Busog na ang tiyan. Handa nang kumilos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Finished that meal.",
                            },
                            ["TL"] = {
                                "Natapos na ang pagkain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "All eaten. Good to keep going.",
                            },
                            ["TL"] = {
                                "Naubos na. Maayos na para magpatuloy.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Done. That tasted better than expected.",
                            },
                            ["TL"] = {
                                "Tapos na. Mas masarap kaysa inasahan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Meal completed.",
                            },
                            ["TL"] = {
                                "Kumpleto na ang pagkain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Finished eating. Back on task.",
                            },
                            ["TL"] = {
                                "Tapos nang kumain. Balik sa trabaho.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Rations finished. Strength is back.",
                            },
                            ["TL"] = {
                                "Naubos ang rasyon. Nagbalik ang lakas.",
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
        ["sourceShard"] = "psdl/dialogue/task_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.eat.failed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.task.eat.failed",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[13]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.task.eat.failed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/eat.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I couldn't eat that.",
                            },
                            ["TL"] = {
                                "Hindi ko nakain iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Failed to eat. The food was rotten or spoiled.",
                            },
                            ["TL"] = {
                                "Bigo sa pagkain. Bulok o panis ang pagkain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Couldn't eat that. It smelled dangerous.",
                            },
                            ["TL"] = {
                                "Di makain 'yon. Amoy delikado.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I was interrupted while trying to eat.",
                            },
                            ["TL"] = {
                                "Naabala ako habang sumusubok kumain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to eat right now. Area under threat.",
                            },
                            ["TL"] = {
                                "Di makakain ngayon. May banta sa lugar.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Eating failed. Food was ruined.",
                            },
                            ["TL"] = {
                                "Pumalpak ang pagkain. Nasira ang pagkain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Couldn't stomach that item.",
                            },
                            ["TL"] = {
                                "Di matunawan sa bagay na 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Dropped or lost the food before eating.",
                            },
                            ["TL"] = {
                                "Nahulog o nawala ang pagkain bago nakain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Action failed. Still starving.",
                            },
                            ["TL"] = {
                                "Bigo ang kilos. Gutom pa rin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Failed to consume meal.",
                            },
                            ["TL"] = {
                                "Bigo sa pagtapos ng pagkain.",
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
        ["sourceShard"] = "psdl/dialogue/task_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.eat.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.task.eat.rejected",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[14]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.task.eat.rejected",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/eat.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm not hungry right now.",
                            },
                            ["TL"] = {
                                "Hindi ako nagugutom ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I don't need food at the moment.",
                            },
                            ["TL"] = {
                                "Di ko kailangan ng pagkain sa sandaling ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'm already completely full.",
                            },
                            ["TL"] = {
                                "Busog na busog pa ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Save the food. I don't need to eat yet.",
                            },
                            ["TL"] = {
                                "Itabi ang pagkain. Di ko pa kailangang kumain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Refusing to eat that. Looks unwholesome.",
                            },
                            ["TL"] = {
                                "Tumatangging kainin 'yan. Mukhang marumi.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Can't eat right now. Too tense.",
                            },
                            ["TL"] = {
                                "Di makakain ngayon. Masyadong tensiyonado.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I have enough energy. Keeping rations safe.",
                            },
                            ["TL"] = {
                                "May sapat pa akong lakas. Itatabi ang rasyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "No need for a meal yet.",
                            },
                            ["TL"] = {
                                "Wala pang pangangailangan sa pagkain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Eat order rejected. Stomach is satisfied.",
                            },
                            ["TL"] = {
                                "Tinatanggihan ang utos na kumain. Busog ang tiyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I can't eat that right now.",
                            },
                            ["TL"] = {
                                "Di ko makakain 'yan ngayon.",
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
        ["sourceShard"] = "psdl/dialogue/task_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.fetch.active",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.task.fetch.active",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[15]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.task.fetch.active",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/fetch.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm working on that now.",
                            },
                            ["TL"] = {
                                "Inaayos ko na iyon ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Retrieving the item now.",
                            },
                            ["TL"] = {
                                "Kinukuha na ang gamit ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "On my way to pick that up.",
                            },
                            ["TL"] = {
                                "Papunta na para pulutin iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Currently fetching the supplies.",
                            },
                            ["TL"] = {
                                "Kasalukuyang kinukuha ang mga gamit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Moving toward the item.",
                            },
                            ["TL"] = {
                                "Papatungo sa kinaroroonan ng bagay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Grabbing it now. Won't take long.",
                            },
                            ["TL"] = {
                                "Kukunin na ngayon. Mabilis lang ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Fetching as ordered.",
                            },
                            ["TL"] = {
                                "Kinukuha ayon sa utos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'm searching for and grabbing that item.",
                            },
                            ["TL"] = {
                                "Hinahanap at kinukuha ko ang bagay na 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "In transit to fetch the goods.",
                            },
                            ["TL"] = {
                                "Kasalukuyang naglalakad para kunin ang gamit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Retrieval in progress.",
                            },
                            ["TL"] = {
                                "Kasalukuyang kinukuha.",
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
        ["sourceShard"] = "psdl/dialogue/task_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.fetch.admitted",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.task.fetch.admitted",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[16]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.task.fetch.admitted",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/fetch.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'll fetch that.",
                            },
                            ["TL"] = {
                                "Kukunin ko iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. I will retrieve the item.",
                            },
                            ["TL"] = {
                                "Naintindihan. Kukunin ko ang gamit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'll go grab that for you.",
                            },
                            ["TL"] = {
                                "Pupuntahan ko para kunin 'yan para sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "On it. Fetching the supplies.",
                            },
                            ["TL"] = {
                                "Inaasikaso na. Kukunin ang mga kagamitan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Right away. Going to pick it up.",
                            },
                            ["TL"] = {
                                "Agad-agad. Pupulutin ko 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. I'll bring it back.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Ibabalik ko rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I'll secure that item.",
                            },
                            ["TL"] = {
                                "Kukunin ko ang gamit na 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Heading out to fetch it.",
                            },
                            ["TL"] = {
                                "Lalabas para kunin iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Got the order. Fetching.",
                            },
                            ["TL"] = {
                                "Nakuha ang utos. Kukunin na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Sounds good. Retrieving it now.",
                            },
                            ["TL"] = {
                                "Maganda 'yan. Kukunin na ngayon.",
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
        ["sourceShard"] = "psdl/dialogue/task_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.fetch.completed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.task.fetch.completed",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[17]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.task.fetch.completed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/fetch.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Here you go.",
                            },
                            ["TL"] = {
                                "Heto na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Retrieved the item. Here it is.",
                            },
                            ["TL"] = {
                                "Nakuha na ang gamit. Heto na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Got what you asked for.",
                            },
                            ["TL"] = {
                                "Nakuha ko ang hiningi mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Fetched and delivered.",
                            },
                            ["TL"] = {
                                "Nakuha at naihatid na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Here are the goods.",
                            },
                            ["TL"] = {
                                "Heto ang mga kagamitan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Task completed. Item secured.",
                            },
                            ["TL"] = {
                                "Tapos na ang gawain. Nakuha ang gamit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "All fetched. Safe in hand.",
                            },
                            ["TL"] = {
                                "Nakuha na lahat. Hawak ko na nang ligtas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Here it is. One piece.",
                            },
                            ["TL"] = {
                                "Heto na. Buo pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Delivery made. What's next?",
                            },
                            ["TL"] = {
                                "Naihatid na. Ano ang susunod?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Retrieved as requested.",
                            },
                            ["TL"] = {
                                "Nakuha ayon sa hiling.",
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
        ["sourceShard"] = "psdl/dialogue/task_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.fetch.failed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.task.fetch.failed",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[18]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.task.fetch.failed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/fetch.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I couldn't fetch that.",
                            },
                            ["TL"] = {
                                "Hindi ko nakuha iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Failed to retrieve the item.",
                            },
                            ["TL"] = {
                                "Bigo sa pagkuha ng gamit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "The item wasn't there or was destroyed.",
                            },
                            ["TL"] = {
                                "Wala roon ang gamit o kaya'y nasira na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Way was blocked. Couldn't reach it.",
                            },
                            ["TL"] = {
                                "May harang sa daan. Di ko naabot.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Hostiles prevented me from grabbing it.",
                            },
                            ["TL"] = {
                                "Pumigil ang mga kalaban sa pagkuha ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to fetch that from that container.",
                            },
                            ["TL"] = {
                                "Di makuha 'yon mula sa lalagyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Lost access to the item. Fetch failed.",
                            },
                            ["TL"] = {
                                "Nawalan ng daan sa gamit. Bigo ang pagkuha.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I couldn't find what you were pointing to.",
                            },
                            ["TL"] = {
                                "Di ko nahanap ang itinuturo mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Inventory full or path obstructed. Failed.",
                            },
                            ["TL"] = {
                                "Puno ang bag o may harang sa daan. Bigo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Couldn't get to the target item.",
                            },
                            ["TL"] = {
                                "Di makarating sa puntiryang gamit.",
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
        ["sourceShard"] = "psdl/dialogue/task_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.fetch.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.task.fetch.rejected",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[19]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.task.fetch.rejected",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/fetch.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I can't fetch that right now.",
                            },
                            ["TL"] = {
                                "Hindi ko makuha iyon ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "That's in a death trap. I'm not fetching it.",
                            },
                            ["TL"] = {
                                "Nasa bitag ng kamatayan 'yan. Di ko kukunin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Too far or too dangerous. Refusing to fetch.",
                            },
                            ["TL"] = {
                                "Masyadong malayo o mapanganib. Tumatangging kunin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "My hands and pack are completely full.",
                            },
                            ["TL"] = {
                                "Puno na ang kamay at bag ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I won't risk my neck for that junk.",
                            },
                            ["TL"] = {
                                "Di ko isusugal ang buhay ko para sa basurang 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Can't retrieve that under current conditions.",
                            },
                            ["TL"] = {
                                "Di makukuha 'yan sa kasalukuyang kalagayan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I don't have the carrying capacity right now.",
                            },
                            ["TL"] = {
                                "Wala na akong espasyong paglalagyan ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Fetch order rejected. Pick it up yourself.",
                            },
                            ["TL"] = {
                                "Tinatanggihan ang pagkuha. Pulutin mo nang kusa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to comply. Item is out of bounds.",
                            },
                            ["TL"] = {
                                "Di makasusunod. Di abot ang bagay na 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I can't fetch that for you.",
                            },
                            ["TL"] = {
                                "Di ko makukuha 'yan para sa 'yo.",
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
        ["sourceShard"] = "psdl/dialogue/task_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.give.active",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.task.give.active",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[25]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.task.give.active",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/give.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Handing that over now.",
                            },
                            ["TL"] = {
                                "Iniaabot ko na ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Passing the item to you right now.",
                            },
                            ["TL"] = {
                                "Ipinapasa ko na ang gamit sa 'yo ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Transferring the supplies.",
                            },
                            ["TL"] = {
                                "Inililipat na ang mga kagamitan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Giving this to you now.",
                            },
                            ["TL"] = {
                                "Ibinibigay ko na ito sa 'yo ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Currently handing it over.",
                            },
                            ["TL"] = {
                                "Kasalukuyang iniaabot.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Reaching out to give you the item.",
                            },
                            ["TL"] = {
                                "Inaabot para ibigay sa 'yo ang gamit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Giving you what was asked.",
                            },
                            ["TL"] = {
                                "Ibinibigay sa 'yo ang hiningi.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "In the middle of the handoff.",
                            },
                            ["TL"] = {
                                "Kasalukuyang nag-aabot.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Handing it off now. Take hold.",
                            },
                            ["TL"] = {
                                "Iniaabot na. Hawakan mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Giving it as ordered.",
                            },
                            ["TL"] = {
                                "Ibinibigay ayon sa utos.",
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
        ["sourceShard"] = "psdl/dialogue/task_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.give.admitted",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.task.give.admitted",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[26]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.task.give.admitted",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/give.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'll give that to you.",
                            },
                            ["TL"] = {
                                "Ibibigay ko iyon sa iyo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Handing it over.",
                            },
                            ["TL"] = {
                                "Naintindihan. Iniaabot na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Here, I'll pass that to you.",
                            },
                            ["TL"] = {
                                "Heto, ipapasa ko 'yan sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "All right. I'll give you the item.",
                            },
                            ["TL"] = {
                                "Sige. Ibibigay ko sa 'yo ang gamit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Sure thing. Passing it over.",
                            },
                            ["TL"] = {
                                "Walang anuman. Ipinapasa na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. You can have it.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Pwede mong kunin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I'll transfer that to your pack.",
                            },
                            ["TL"] = {
                                "Ililipat ko 'yan sa bag mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Right. Handing it over.",
                            },
                            ["TL"] = {
                                "Sige. Iniaabot na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'll give you what you requested.",
                            },
                            ["TL"] = {
                                "Ibibigay ko ang hiniling mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Sounds good. Giving it now.",
                            },
                            ["TL"] = {
                                "Maganda 'yan. Ibibigay na ngayon.",
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
        ["sourceShard"] = "psdl/dialogue/task_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.give.completed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.task.give.completed",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[27]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.task.give.completed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/give.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "There you go.",
                            },
                            ["TL"] = {
                                "Heto na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Handed over safely.",
                            },
                            ["TL"] = {
                                "Naibigay na nang ligtas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "It's yours now.",
                            },
                            ["TL"] = {
                                "Nasa sa 'yo na ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Transfer complete.",
                            },
                            ["TL"] = {
                                "Tapos na ang paglipat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "All given. Take good care of it.",
                            },
                            ["TL"] = {
                                "Naibigay na lahat. Ingatan mo 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Done. It's in your hands.",
                            },
                            ["TL"] = {
                                "Tapos na. Nasa mga kamay mo na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Handoff finished.",
                            },
                            ["TL"] = {
                                "Tapos na ang pag-aabot.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Given as requested.",
                            },
                            ["TL"] = {
                                "Naibigay ayon sa hiling.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Item is officially yours.",
                            },
                            ["TL"] = {
                                "Sa 'yo na ang gamit opisyal.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Completed the handoff.",
                            },
                            ["TL"] = {
                                "Natapos ang pag-aabot.",
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
        ["sourceShard"] = "psdl/dialogue/task_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.give.failed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.task.give.failed",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[28]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.task.give.failed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/give.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I couldn't give that to you.",
                            },
                            ["TL"] = {
                                "Hindi ko naibigay iyon sa iyo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Handoff failed. You were out of reach.",
                            },
                            ["TL"] = {
                                "Pumalpak ang pag-aabot. Masyado kang malayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Your hands or pack were full. Couldn't give it.",
                            },
                            ["TL"] = {
                                "Puno ang kamay o bag mo. Di maibigay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Action interrupted. Item not given.",
                            },
                            ["TL"] = {
                                "Naabala ang kilos. Di naibigay ang gamit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to transfer the item to you.",
                            },
                            ["TL"] = {
                                "Di mailipat ang gamit sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Failed to hand it over. Something got in the way.",
                            },
                            ["TL"] = {
                                "Bigo sa pag-aabot. May humarang sa pagitan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I couldn't complete the give action.",
                            },
                            ["TL"] = {
                                "Di ko natapos ang pagbibigay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Dropped it during the exchange.",
                            },
                            ["TL"] = {
                                "Nahulog habang nagpapalitan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Give task failed.",
                            },
                            ["TL"] = {
                                "Bigo ang gawaing magbigay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Could not give that item.",
                            },
                            ["TL"] = {
                                "Hindi naibigay ang bagay na 'yan.",
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
        ["sourceShard"] = "psdl/dialogue/task_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.give.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.task.give.rejected",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[29]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.task.give.rejected",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/give.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I can't give that to you right now.",
                            },
                            ["TL"] = {
                                "Hindi ko maibibigay iyon sa iyo ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I need that item to survive. Can't spare it.",
                            },
                            ["TL"] = {
                                "Kailangan ko 'yan para mabuhay. Di ko maipamimigay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "That is vital to my loadout. I won't give it away.",
                            },
                            ["TL"] = {
                                "Mahalaga 'yan sa gamit ko. Di ko ipamimigay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Refusing to hand that over.",
                            },
                            ["TL"] = {
                                "Tumatangging iabot 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I don't have that item to give.",
                            },
                            ["TL"] = {
                                "Wala sa akin ang gamit na 'yan para ibigay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Can't give that up under these circumstances.",
                            },
                            ["TL"] = {
                                "Di ko maibibigay 'yan sa ganitong kalagayan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "That's not something I can part with.",
                            },
                            ["TL"] = {
                                "Hindi bagay 'yan na kaya kong bitiwan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Give order rejected. I'm keeping this.",
                            },
                            ["TL"] = {
                                "Tinatanggihan ang pagbibigay. Itatabi ko ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I won't give that item away.",
                            },
                            ["TL"] = {
                                "Di ko ipamimigay ang bagay na 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Not giving that. Ask for something else.",
                            },
                            ["TL"] = {
                                "Di ibibigay 'yan. Humingi ka ng iba.",
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
        ["sourceShard"] = "psdl/dialogue/task_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.refill.active",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.task.refill.active",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[30]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.task.refill.active",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/refill.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Refilling the container now.",
                            },
                            ["TL"] = {
                                "Nilalagyan ng laman ang lalagyan ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Currently filling up on water.",
                            },
                            ["TL"] = {
                                "Kasalukuyang nagpapasok ng tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Topping off the fluids right now.",
                            },
                            ["TL"] = {
                                "Pinupuno ang inumin ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Working on refilling the bottle.",
                            },
                            ["TL"] = {
                                "Pinupuno ang bote.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Gathering water into the container.",
                            },
                            ["TL"] = {
                                "Kumukuha ng tubig sa lalagyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "In the middle of refilling.",
                            },
                            ["TL"] = {
                                "Kasalukuyang nagpupuno.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Refilling as instructed.",
                            },
                            ["TL"] = {
                                "Nagpupuno ayon sa utos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Collecting clean water now.",
                            },
                            ["TL"] = {
                                "Kumukuha ng malinis na tubig ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Topping it up. Give me a moment.",
                            },
                            ["TL"] = {
                                "Pinupuno ito. Sandali lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Refill in progress.",
                            },
                            ["TL"] = {
                                "Kasalukuyang nagpupuno.",
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
        ["sourceShard"] = "psdl/dialogue/task_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.refill.admitted",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.task.refill.admitted",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[31]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.task.refill.admitted",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/refill.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'll refill that.",
                            },
                            ["TL"] = {
                                "Lalagyan ko ng laman iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Topping up the water supply.",
                            },
                            ["TL"] = {
                                "Naintindihan. Pupunuin ang supply ng tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'll go get the bottles filled.",
                            },
                            ["TL"] = {
                                "Pupunta ako para punuin ang mga bote.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "All right, refilling the containers.",
                            },
                            ["TL"] = {
                                "Sige, pupunuin ang mga lalagyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Good call. We need full canteens.",
                            },
                            ["TL"] = {
                                "Magandang paalala. Kailangan natin ng punong sisidlan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'll take it to the water source.",
                            },
                            ["TL"] = {
                                "Dadalhin ko sa pinagkukunan ng tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Refilling immediately.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Pupunuin agad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Right. Getting fresh water.",
                            },
                            ["TL"] = {
                                "Sige. Kukuha ng sariwang tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'll refill what's empty.",
                            },
                            ["TL"] = {
                                "Pupunuin ko ang walang laman.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Sounds good. Heading to refill.",
                            },
                            ["TL"] = {
                                "Maganda 'yan. Pupunta para magpuno.",
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
        ["sourceShard"] = "psdl/dialogue/task_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
