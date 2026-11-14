-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.eat.failed",
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
                                ["fallback"] = "I couldn't eat that.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.task.eat.failed.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I couldn't eat that.",
                                        "Failed to eat. The food was rotten or spoiled.",
                                        "Couldn't eat that. It smelled dangerous.",
                                        "I was interrupted while trying to eat.",
                                        "Unable to eat right now. Area under threat.",
                                        "Eating failed. Food was ruined.",
                                        "Couldn't stomach that item.",
                                        "Dropped or lost the food before eating.",
                                        "Action failed. Still starving.",
                                        "Failed to consume meal.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko nakain iyon.",
                                        "Bigo sa pagkain. Bulok o panis ang pagkain.",
                                        "Di makain 'yon. Amoy delikado.",
                                        "Naabala ako habang sumusubok kumain.",
                                        "Di makakain ngayon. May banta sa lugar.",
                                        "Pumalpak ang pagkain. Nasira ang pagkain.",
                                        "Di matunawan sa bagay na 'yan.",
                                        "Nahulog o nawala ang pagkain bago nakain.",
                                        "Bigo ang kilos. Gutom pa rin.",
                                        "Bigo sa pagtapos ng pagkain.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "task.eat",
            ["textRoles"] = {
                {
                    ["fallback"] = "I couldn't eat that.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.task.eat.failed.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I couldn't eat that.",
                            "Failed to eat. The food was rotten or spoiled.",
                            "Couldn't eat that. It smelled dangerous.",
                            "I was interrupted while trying to eat.",
                            "Unable to eat right now. Area under threat.",
                            "Eating failed. Food was ruined.",
                            "Couldn't stomach that item.",
                            "Dropped or lost the food before eating.",
                            "Action failed. Still starving.",
                            "Failed to consume meal.",
                        },
                        ["TL"] = {
                            "Hindi ko nakain iyon.",
                            "Bigo sa pagkain. Bulok o panis ang pagkain.",
                            "Di makain 'yon. Amoy delikado.",
                            "Naabala ako habang sumusubok kumain.",
                            "Di makakain ngayon. May banta sa lugar.",
                            "Pumalpak ang pagkain. Nasira ang pagkain.",
                            "Di matunawan sa bagay na 'yan.",
                            "Nahulog o nawala ang pagkain bago nakain.",
                            "Bigo ang kilos. Gutom pa rin.",
                            "Bigo sa pagtapos ng pagkain.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "task.eat.failed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "failed",
            ["sourceId"] = "task.eat.failed",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_eat_failed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle__b4a76fdc",
        ["namespace"] = "task.eat",
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
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/eat.json",
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
                                        "I couldn't eat that.",
                                        "Failed to eat. The food was rotten or spoiled.",
                                        "Couldn't eat that. It smelled dangerous.",
                                        "I was interrupted while trying to eat.",
                                        "Unable to eat right now. Area under threat.",
                                        "Eating failed. Food was ruined.",
                                        "Couldn't stomach that item.",
                                        "Dropped or lost the food before eating.",
                                        "Action failed. Still starving.",
                                        "Failed to consume meal.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko nakain iyon.",
                                        "Bigo sa pagkain. Bulok o panis ang pagkain.",
                                        "Di makain 'yon. Amoy delikado.",
                                        "Naabala ako habang sumusubok kumain.",
                                        "Di makakain ngayon. May banta sa lugar.",
                                        "Pumalpak ang pagkain. Nasira ang pagkain.",
                                        "Di matunawan sa bagay na 'yan.",
                                        "Nahulog o nawala ang pagkain bago nakain.",
                                        "Bigo ang kilos. Gutom pa rin.",
                                        "Bigo sa pagtapos ng pagkain.",
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
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "task.eat.failed",
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
                            ["fallback"] = "I couldn't eat that.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.task.eat.failed.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_eat_failed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I couldn't eat that.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.task.eat.failed.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I couldn't eat that.",
                        "Failed to eat. The food was rotten or spoiled.",
                        "Couldn't eat that. It smelled dangerous.",
                        "I was interrupted while trying to eat.",
                        "Unable to eat right now. Area under threat.",
                        "Eating failed. Food was ruined.",
                        "Couldn't stomach that item.",
                        "Dropped or lost the food before eating.",
                        "Action failed. Still starving.",
                        "Failed to consume meal.",
                    },
                    ["TL"] = {
                        "Hindi ko nakain iyon.",
                        "Bigo sa pagkain. Bulok o panis ang pagkain.",
                        "Di makain 'yon. Amoy delikado.",
                        "Naabala ako habang sumusubok kumain.",
                        "Di makakain ngayon. May banta sa lugar.",
                        "Pumalpak ang pagkain. Nasira ang pagkain.",
                        "Di matunawan sa bagay na 'yan.",
                        "Nahulog o nawala ang pagkain bago nakain.",
                        "Bigo ang kilos. Gutom pa rin.",
                        "Bigo sa pagtapos ng pagkain.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.eat.rejected",
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
                                ["fallback"] = "I'm not hungry right now.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.task.eat.rejected.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'm not hungry right now.",
                                        "I don't need food at the moment.",
                                        "I'm already completely full.",
                                        "Save the food. I don't need to eat yet.",
                                        "Refusing to eat that. Looks unwholesome.",
                                        "Can't eat right now. Too tense.",
                                        "I have enough energy. Keeping rations safe.",
                                        "No need for a meal yet.",
                                        "Eat order rejected. Stomach is satisfied.",
                                        "I can't eat that right now.",
                                    },
                                    ["TL"] = {
                                        "Hindi ako nagugutom ngayon.",
                                        "Di ko kailangan ng pagkain sa sandaling ito.",
                                        "Busog na busog pa ako.",
                                        "Itabi ang pagkain. Di ko pa kailangang kumain.",
                                        "Tumatangging kainin 'yan. Mukhang marumi.",
                                        "Di makakain ngayon. Masyadong tensiyonado.",
                                        "May sapat pa akong lakas. Itatabi ang rasyon.",
                                        "Wala pang pangangailangan sa pagkain.",
                                        "Tinatanggihan ang utos na kumain. Busog ang tiyan.",
                                        "Di ko makakain 'yan ngayon.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "task.eat",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'm not hungry right now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.task.eat.rejected.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I'm not hungry right now.",
                            "I don't need food at the moment.",
                            "I'm already completely full.",
                            "Save the food. I don't need to eat yet.",
                            "Refusing to eat that. Looks unwholesome.",
                            "Can't eat right now. Too tense.",
                            "I have enough energy. Keeping rations safe.",
                            "No need for a meal yet.",
                            "Eat order rejected. Stomach is satisfied.",
                            "I can't eat that right now.",
                        },
                        ["TL"] = {
                            "Hindi ako nagugutom ngayon.",
                            "Di ko kailangan ng pagkain sa sandaling ito.",
                            "Busog na busog pa ako.",
                            "Itabi ang pagkain. Di ko pa kailangang kumain.",
                            "Tumatangging kainin 'yan. Mukhang marumi.",
                            "Di makakain ngayon. Masyadong tensiyonado.",
                            "May sapat pa akong lakas. Itatabi ang rasyon.",
                            "Wala pang pangangailangan sa pagkain.",
                            "Tinatanggihan ang utos na kumain. Busog ang tiyan.",
                            "Di ko makakain 'yan ngayon.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "task.eat.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "rejected",
            ["sourceId"] = "task.eat.rejected",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_eat_rejected.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle__b4a76fdc",
        ["namespace"] = "task.eat",
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
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/eat.json",
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
                                        "I'm not hungry right now.",
                                        "I don't need food at the moment.",
                                        "I'm already completely full.",
                                        "Save the food. I don't need to eat yet.",
                                        "Refusing to eat that. Looks unwholesome.",
                                        "Can't eat right now. Too tense.",
                                        "I have enough energy. Keeping rations safe.",
                                        "No need for a meal yet.",
                                        "Eat order rejected. Stomach is satisfied.",
                                        "I can't eat that right now.",
                                    },
                                    ["TL"] = {
                                        "Hindi ako nagugutom ngayon.",
                                        "Di ko kailangan ng pagkain sa sandaling ito.",
                                        "Busog na busog pa ako.",
                                        "Itabi ang pagkain. Di ko pa kailangang kumain.",
                                        "Tumatangging kainin 'yan. Mukhang marumi.",
                                        "Di makakain ngayon. Masyadong tensiyonado.",
                                        "May sapat pa akong lakas. Itatabi ang rasyon.",
                                        "Wala pang pangangailangan sa pagkain.",
                                        "Tinatanggihan ang utos na kumain. Busog ang tiyan.",
                                        "Di ko makakain 'yan ngayon.",
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
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "task.eat.rejected",
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
                            ["fallback"] = "I'm not hungry right now.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.task.eat.rejected.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_eat_rejected.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'm not hungry right now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.task.eat.rejected.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I'm not hungry right now.",
                        "I don't need food at the moment.",
                        "I'm already completely full.",
                        "Save the food. I don't need to eat yet.",
                        "Refusing to eat that. Looks unwholesome.",
                        "Can't eat right now. Too tense.",
                        "I have enough energy. Keeping rations safe.",
                        "No need for a meal yet.",
                        "Eat order rejected. Stomach is satisfied.",
                        "I can't eat that right now.",
                    },
                    ["TL"] = {
                        "Hindi ako nagugutom ngayon.",
                        "Di ko kailangan ng pagkain sa sandaling ito.",
                        "Busog na busog pa ako.",
                        "Itabi ang pagkain. Di ko pa kailangang kumain.",
                        "Tumatangging kainin 'yan. Mukhang marumi.",
                        "Di makakain ngayon. Masyadong tensiyonado.",
                        "May sapat pa akong lakas. Itatabi ang rasyon.",
                        "Wala pang pangangailangan sa pagkain.",
                        "Tinatanggihan ang utos na kumain. Busog ang tiyan.",
                        "Di ko makakain 'yan ngayon.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.fetch.active",
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
                                ["fallback"] = "I'm working on that now.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.task.fetch.active.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'm working on that now.",
                                        "Retrieving the item now.",
                                        "On my way to pick that up.",
                                        "Currently fetching the supplies.",
                                        "Moving toward the item.",
                                        "Grabbing it now. Won't take long.",
                                        "Fetching as ordered.",
                                        "I'm searching for and grabbing that item.",
                                        "In transit to fetch the goods.",
                                        "Retrieval in progress.",
                                    },
                                    ["TL"] = {
                                        "Inaayos ko na iyon ngayon.",
                                        "Kinukuha na ang gamit ngayon.",
                                        "Papunta na para pulutin iyon.",
                                        "Kasalukuyang kinukuha ang mga gamit.",
                                        "Papatungo sa kinaroroonan ng bagay.",
                                        "Kukunin na ngayon. Mabilis lang ito.",
                                        "Kinukuha ayon sa utos.",
                                        "Hinahanap at kinukuha ko ang bagay na 'yan.",
                                        "Kasalukuyang naglalakad para kunin ang gamit.",
                                        "Kasalukuyang kinukuha.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "task.fetch",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'm working on that now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.task.fetch.active.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I'm working on that now.",
                            "Retrieving the item now.",
                            "On my way to pick that up.",
                            "Currently fetching the supplies.",
                            "Moving toward the item.",
                            "Grabbing it now. Won't take long.",
                            "Fetching as ordered.",
                            "I'm searching for and grabbing that item.",
                            "In transit to fetch the goods.",
                            "Retrieval in progress.",
                        },
                        ["TL"] = {
                            "Inaayos ko na iyon ngayon.",
                            "Kinukuha na ang gamit ngayon.",
                            "Papunta na para pulutin iyon.",
                            "Kasalukuyang kinukuha ang mga gamit.",
                            "Papatungo sa kinaroroonan ng bagay.",
                            "Kukunin na ngayon. Mabilis lang ito.",
                            "Kinukuha ayon sa utos.",
                            "Hinahanap at kinukuha ko ang bagay na 'yan.",
                            "Kasalukuyang naglalakad para kunin ang gamit.",
                            "Kasalukuyang kinukuha.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "task.fetch.active",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "active",
            ["sourceId"] = "task.fetch.active",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_fetch_active.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle__b4a76fdc",
        ["namespace"] = "task.fetch",
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
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/fetch.json",
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
                                        "I'm working on that now.",
                                        "Retrieving the item now.",
                                        "On my way to pick that up.",
                                        "Currently fetching the supplies.",
                                        "Moving toward the item.",
                                        "Grabbing it now. Won't take long.",
                                        "Fetching as ordered.",
                                        "I'm searching for and grabbing that item.",
                                        "In transit to fetch the goods.",
                                        "Retrieval in progress.",
                                    },
                                    ["TL"] = {
                                        "Inaayos ko na iyon ngayon.",
                                        "Kinukuha na ang gamit ngayon.",
                                        "Papunta na para pulutin iyon.",
                                        "Kasalukuyang kinukuha ang mga gamit.",
                                        "Papatungo sa kinaroroonan ng bagay.",
                                        "Kukunin na ngayon. Mabilis lang ito.",
                                        "Kinukuha ayon sa utos.",
                                        "Hinahanap at kinukuha ko ang bagay na 'yan.",
                                        "Kasalukuyang naglalakad para kunin ang gamit.",
                                        "Kasalukuyang kinukuha.",
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
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "task.fetch.active",
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
                            ["fallback"] = "I'm working on that now.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.task.fetch.active.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_fetch_active.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'm working on that now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.task.fetch.active.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I'm working on that now.",
                        "Retrieving the item now.",
                        "On my way to pick that up.",
                        "Currently fetching the supplies.",
                        "Moving toward the item.",
                        "Grabbing it now. Won't take long.",
                        "Fetching as ordered.",
                        "I'm searching for and grabbing that item.",
                        "In transit to fetch the goods.",
                        "Retrieval in progress.",
                    },
                    ["TL"] = {
                        "Inaayos ko na iyon ngayon.",
                        "Kinukuha na ang gamit ngayon.",
                        "Papunta na para pulutin iyon.",
                        "Kasalukuyang kinukuha ang mga gamit.",
                        "Papatungo sa kinaroroonan ng bagay.",
                        "Kukunin na ngayon. Mabilis lang ito.",
                        "Kinukuha ayon sa utos.",
                        "Hinahanap at kinukuha ko ang bagay na 'yan.",
                        "Kasalukuyang naglalakad para kunin ang gamit.",
                        "Kasalukuyang kinukuha.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.fetch.admitted",
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
                                ["fallback"] = "I'll fetch that.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.task.fetch.admitted.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'll fetch that.",
                                        "Understood. I will retrieve the item.",
                                        "I'll go grab that for you.",
                                        "On it. Fetching the supplies.",
                                        "Right away. Going to pick it up.",
                                        "Understood. I'll bring it back.",
                                        "I'll secure that item.",
                                        "Heading out to fetch it.",
                                        "Got the order. Fetching.",
                                        "Sounds good. Retrieving it now.",
                                    },
                                    ["TL"] = {
                                        "Kukunin ko iyon.",
                                        "Naintindihan. Kukunin ko ang gamit.",
                                        "Pupuntahan ko para kunin 'yan para sa 'yo.",
                                        "Inaasikaso na. Kukunin ang mga kagamitan.",
                                        "Agad-agad. Pupulutin ko 'yon.",
                                        "Naiintindihan ko. Ibabalik ko rito.",
                                        "Kukunin ko ang gamit na 'yan.",
                                        "Lalabas para kunin iyon.",
                                        "Nakuha ang utos. Kukunin na.",
                                        "Maganda 'yan. Kukunin na ngayon.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "task.fetch",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'll fetch that.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.task.fetch.admitted.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I'll fetch that.",
                            "Understood. I will retrieve the item.",
                            "I'll go grab that for you.",
                            "On it. Fetching the supplies.",
                            "Right away. Going to pick it up.",
                            "Understood. I'll bring it back.",
                            "I'll secure that item.",
                            "Heading out to fetch it.",
                            "Got the order. Fetching.",
                            "Sounds good. Retrieving it now.",
                        },
                        ["TL"] = {
                            "Kukunin ko iyon.",
                            "Naintindihan. Kukunin ko ang gamit.",
                            "Pupuntahan ko para kunin 'yan para sa 'yo.",
                            "Inaasikaso na. Kukunin ang mga kagamitan.",
                            "Agad-agad. Pupulutin ko 'yon.",
                            "Naiintindihan ko. Ibabalik ko rito.",
                            "Kukunin ko ang gamit na 'yan.",
                            "Lalabas para kunin iyon.",
                            "Nakuha ang utos. Kukunin na.",
                            "Maganda 'yan. Kukunin na ngayon.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "task.fetch.admitted",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "admitted",
            ["sourceId"] = "task.fetch.admitted",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_fetch_admitted.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle__b4a76fdc",
        ["namespace"] = "task.fetch",
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
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/fetch.json",
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
                                        "I'll fetch that.",
                                        "Understood. I will retrieve the item.",
                                        "I'll go grab that for you.",
                                        "On it. Fetching the supplies.",
                                        "Right away. Going to pick it up.",
                                        "Understood. I'll bring it back.",
                                        "I'll secure that item.",
                                        "Heading out to fetch it.",
                                        "Got the order. Fetching.",
                                        "Sounds good. Retrieving it now.",
                                    },
                                    ["TL"] = {
                                        "Kukunin ko iyon.",
                                        "Naintindihan. Kukunin ko ang gamit.",
                                        "Pupuntahan ko para kunin 'yan para sa 'yo.",
                                        "Inaasikaso na. Kukunin ang mga kagamitan.",
                                        "Agad-agad. Pupulutin ko 'yon.",
                                        "Naiintindihan ko. Ibabalik ko rito.",
                                        "Kukunin ko ang gamit na 'yan.",
                                        "Lalabas para kunin iyon.",
                                        "Nakuha ang utos. Kukunin na.",
                                        "Maganda 'yan. Kukunin na ngayon.",
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
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "task.fetch.admitted",
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
                            ["fallback"] = "I'll fetch that.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.task.fetch.admitted.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_fetch_admitted.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'll fetch that.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.task.fetch.admitted.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I'll fetch that.",
                        "Understood. I will retrieve the item.",
                        "I'll go grab that for you.",
                        "On it. Fetching the supplies.",
                        "Right away. Going to pick it up.",
                        "Understood. I'll bring it back.",
                        "I'll secure that item.",
                        "Heading out to fetch it.",
                        "Got the order. Fetching.",
                        "Sounds good. Retrieving it now.",
                    },
                    ["TL"] = {
                        "Kukunin ko iyon.",
                        "Naintindihan. Kukunin ko ang gamit.",
                        "Pupuntahan ko para kunin 'yan para sa 'yo.",
                        "Inaasikaso na. Kukunin ang mga kagamitan.",
                        "Agad-agad. Pupulutin ko 'yon.",
                        "Naiintindihan ko. Ibabalik ko rito.",
                        "Kukunin ko ang gamit na 'yan.",
                        "Lalabas para kunin iyon.",
                        "Nakuha ang utos. Kukunin na.",
                        "Maganda 'yan. Kukunin na ngayon.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.fetch.completed",
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
                                ["fallback"] = "Here you go.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.task.fetch.completed.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Here you go.",
                                        "Retrieved the item. Here it is.",
                                        "Got what you asked for.",
                                        "Fetched and delivered.",
                                        "Here are the goods.",
                                        "Task completed. Item secured.",
                                        "All fetched. Safe in hand.",
                                        "Here it is. One piece.",
                                        "Delivery made. What's next?",
                                        "Retrieved as requested.",
                                    },
                                    ["TL"] = {
                                        "Heto na.",
                                        "Nakuha na ang gamit. Heto na.",
                                        "Nakuha ko ang hiningi mo.",
                                        "Nakuha at naihatid na.",
                                        "Heto ang mga kagamitan.",
                                        "Tapos na ang gawain. Nakuha ang gamit.",
                                        "Nakuha na lahat. Hawak ko na nang ligtas.",
                                        "Heto na. Buo pa.",
                                        "Naihatid na. Ano ang susunod?",
                                        "Nakuha ayon sa hiling.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "task.fetch",
            ["textRoles"] = {
                {
                    ["fallback"] = "Here you go.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.task.fetch.completed.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Here you go.",
                            "Retrieved the item. Here it is.",
                            "Got what you asked for.",
                            "Fetched and delivered.",
                            "Here are the goods.",
                            "Task completed. Item secured.",
                            "All fetched. Safe in hand.",
                            "Here it is. One piece.",
                            "Delivery made. What's next?",
                            "Retrieved as requested.",
                        },
                        ["TL"] = {
                            "Heto na.",
                            "Nakuha na ang gamit. Heto na.",
                            "Nakuha ko ang hiningi mo.",
                            "Nakuha at naihatid na.",
                            "Heto ang mga kagamitan.",
                            "Tapos na ang gawain. Nakuha ang gamit.",
                            "Nakuha na lahat. Hawak ko na nang ligtas.",
                            "Heto na. Buo pa.",
                            "Naihatid na. Ano ang susunod?",
                            "Nakuha ayon sa hiling.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "task.fetch.completed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "completed",
            ["sourceId"] = "task.fetch.completed",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_fetch_completed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle__b4a76fdc",
        ["namespace"] = "task.fetch",
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
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/fetch.json",
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
                                        "Here you go.",
                                        "Retrieved the item. Here it is.",
                                        "Got what you asked for.",
                                        "Fetched and delivered.",
                                        "Here are the goods.",
                                        "Task completed. Item secured.",
                                        "All fetched. Safe in hand.",
                                        "Here it is. One piece.",
                                        "Delivery made. What's next?",
                                        "Retrieved as requested.",
                                    },
                                    ["TL"] = {
                                        "Heto na.",
                                        "Nakuha na ang gamit. Heto na.",
                                        "Nakuha ko ang hiningi mo.",
                                        "Nakuha at naihatid na.",
                                        "Heto ang mga kagamitan.",
                                        "Tapos na ang gawain. Nakuha ang gamit.",
                                        "Nakuha na lahat. Hawak ko na nang ligtas.",
                                        "Heto na. Buo pa.",
                                        "Naihatid na. Ano ang susunod?",
                                        "Nakuha ayon sa hiling.",
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
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "task.fetch.completed",
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
                            ["fallback"] = "Here you go.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.task.fetch.completed.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_fetch_completed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Here you go.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.task.fetch.completed.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Here you go.",
                        "Retrieved the item. Here it is.",
                        "Got what you asked for.",
                        "Fetched and delivered.",
                        "Here are the goods.",
                        "Task completed. Item secured.",
                        "All fetched. Safe in hand.",
                        "Here it is. One piece.",
                        "Delivery made. What's next?",
                        "Retrieved as requested.",
                    },
                    ["TL"] = {
                        "Heto na.",
                        "Nakuha na ang gamit. Heto na.",
                        "Nakuha ko ang hiningi mo.",
                        "Nakuha at naihatid na.",
                        "Heto ang mga kagamitan.",
                        "Tapos na ang gawain. Nakuha ang gamit.",
                        "Nakuha na lahat. Hawak ko na nang ligtas.",
                        "Heto na. Buo pa.",
                        "Naihatid na. Ano ang susunod?",
                        "Nakuha ayon sa hiling.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.fetch.failed",
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
                                ["fallback"] = "I couldn't fetch that.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.task.fetch.failed.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I couldn't fetch that.",
                                        "Failed to retrieve the item.",
                                        "The item wasn't there or was destroyed.",
                                        "Way was blocked. Couldn't reach it.",
                                        "Hostiles prevented me from grabbing it.",
                                        "Unable to fetch that from that container.",
                                        "Lost access to the item. Fetch failed.",
                                        "I couldn't find what you were pointing to.",
                                        "Inventory full or path obstructed. Failed.",
                                        "Couldn't get to the target item.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko nakuha iyon.",
                                        "Bigo sa pagkuha ng gamit.",
                                        "Wala roon ang gamit o kaya'y nasira na.",
                                        "May harang sa daan. Di ko naabot.",
                                        "Pumigil ang mga kalaban sa pagkuha ko.",
                                        "Di makuha 'yon mula sa lalagyan.",
                                        "Nawalan ng daan sa gamit. Bigo ang pagkuha.",
                                        "Di ko nahanap ang itinuturo mo.",
                                        "Puno ang bag o may harang sa daan. Bigo.",
                                        "Di makarating sa puntiryang gamit.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "task.fetch",
            ["textRoles"] = {
                {
                    ["fallback"] = "I couldn't fetch that.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.task.fetch.failed.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I couldn't fetch that.",
                            "Failed to retrieve the item.",
                            "The item wasn't there or was destroyed.",
                            "Way was blocked. Couldn't reach it.",
                            "Hostiles prevented me from grabbing it.",
                            "Unable to fetch that from that container.",
                            "Lost access to the item. Fetch failed.",
                            "I couldn't find what you were pointing to.",
                            "Inventory full or path obstructed. Failed.",
                            "Couldn't get to the target item.",
                        },
                        ["TL"] = {
                            "Hindi ko nakuha iyon.",
                            "Bigo sa pagkuha ng gamit.",
                            "Wala roon ang gamit o kaya'y nasira na.",
                            "May harang sa daan. Di ko naabot.",
                            "Pumigil ang mga kalaban sa pagkuha ko.",
                            "Di makuha 'yon mula sa lalagyan.",
                            "Nawalan ng daan sa gamit. Bigo ang pagkuha.",
                            "Di ko nahanap ang itinuturo mo.",
                            "Puno ang bag o may harang sa daan. Bigo.",
                            "Di makarating sa puntiryang gamit.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "task.fetch.failed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "failed",
            ["sourceId"] = "task.fetch.failed",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_fetch_failed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle__b4a76fdc",
        ["namespace"] = "task.fetch",
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
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/fetch.json",
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
                                        "I couldn't fetch that.",
                                        "Failed to retrieve the item.",
                                        "The item wasn't there or was destroyed.",
                                        "Way was blocked. Couldn't reach it.",
                                        "Hostiles prevented me from grabbing it.",
                                        "Unable to fetch that from that container.",
                                        "Lost access to the item. Fetch failed.",
                                        "I couldn't find what you were pointing to.",
                                        "Inventory full or path obstructed. Failed.",
                                        "Couldn't get to the target item.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko nakuha iyon.",
                                        "Bigo sa pagkuha ng gamit.",
                                        "Wala roon ang gamit o kaya'y nasira na.",
                                        "May harang sa daan. Di ko naabot.",
                                        "Pumigil ang mga kalaban sa pagkuha ko.",
                                        "Di makuha 'yon mula sa lalagyan.",
                                        "Nawalan ng daan sa gamit. Bigo ang pagkuha.",
                                        "Di ko nahanap ang itinuturo mo.",
                                        "Puno ang bag o may harang sa daan. Bigo.",
                                        "Di makarating sa puntiryang gamit.",
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
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "task.fetch.failed",
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
                            ["fallback"] = "I couldn't fetch that.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.task.fetch.failed.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_fetch_failed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I couldn't fetch that.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.task.fetch.failed.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I couldn't fetch that.",
                        "Failed to retrieve the item.",
                        "The item wasn't there or was destroyed.",
                        "Way was blocked. Couldn't reach it.",
                        "Hostiles prevented me from grabbing it.",
                        "Unable to fetch that from that container.",
                        "Lost access to the item. Fetch failed.",
                        "I couldn't find what you were pointing to.",
                        "Inventory full or path obstructed. Failed.",
                        "Couldn't get to the target item.",
                    },
                    ["TL"] = {
                        "Hindi ko nakuha iyon.",
                        "Bigo sa pagkuha ng gamit.",
                        "Wala roon ang gamit o kaya'y nasira na.",
                        "May harang sa daan. Di ko naabot.",
                        "Pumigil ang mga kalaban sa pagkuha ko.",
                        "Di makuha 'yon mula sa lalagyan.",
                        "Nawalan ng daan sa gamit. Bigo ang pagkuha.",
                        "Di ko nahanap ang itinuturo mo.",
                        "Puno ang bag o may harang sa daan. Bigo.",
                        "Di makarating sa puntiryang gamit.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.fetch.rejected",
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
                                ["fallback"] = "I can't fetch that right now.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.task.fetch.rejected.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I can't fetch that right now.",
                                        "That's in a death trap. I'm not fetching it.",
                                        "Too far or too dangerous. Refusing to fetch.",
                                        "My hands and pack are completely full.",
                                        "I won't risk my neck for that junk.",
                                        "Can't retrieve that under current conditions.",
                                        "I don't have the carrying capacity right now.",
                                        "Fetch order rejected. Pick it up yourself.",
                                        "Unable to comply. Item is out of bounds.",
                                        "I can't fetch that for you.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko makuha iyon ngayon.",
                                        "Nasa bitag ng kamatayan 'yan. Di ko kukunin.",
                                        "Masyadong malayo o mapanganib. Tumatangging kunin.",
                                        "Puno na ang kamay at bag ko.",
                                        "Di ko isusugal ang buhay ko para sa basurang 'yan.",
                                        "Di makukuha 'yan sa kasalukuyang kalagayan.",
                                        "Wala na akong espasyong paglalagyan ngayon.",
                                        "Tinatanggihan ang pagkuha. Pulutin mo nang kusa.",
                                        "Di makasusunod. Di abot ang bagay na 'yan.",
                                        "Di ko makukuha 'yan para sa 'yo.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "task.fetch",
            ["textRoles"] = {
                {
                    ["fallback"] = "I can't fetch that right now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.task.fetch.rejected.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I can't fetch that right now.",
                            "That's in a death trap. I'm not fetching it.",
                            "Too far or too dangerous. Refusing to fetch.",
                            "My hands and pack are completely full.",
                            "I won't risk my neck for that junk.",
                            "Can't retrieve that under current conditions.",
                            "I don't have the carrying capacity right now.",
                            "Fetch order rejected. Pick it up yourself.",
                            "Unable to comply. Item is out of bounds.",
                            "I can't fetch that for you.",
                        },
                        ["TL"] = {
                            "Hindi ko makuha iyon ngayon.",
                            "Nasa bitag ng kamatayan 'yan. Di ko kukunin.",
                            "Masyadong malayo o mapanganib. Tumatangging kunin.",
                            "Puno na ang kamay at bag ko.",
                            "Di ko isusugal ang buhay ko para sa basurang 'yan.",
                            "Di makukuha 'yan sa kasalukuyang kalagayan.",
                            "Wala na akong espasyong paglalagyan ngayon.",
                            "Tinatanggihan ang pagkuha. Pulutin mo nang kusa.",
                            "Di makasusunod. Di abot ang bagay na 'yan.",
                            "Di ko makukuha 'yan para sa 'yo.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "task.fetch.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "rejected",
            ["sourceId"] = "task.fetch.rejected",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_fetch_rejected.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle__b4a76fdc",
        ["namespace"] = "task.fetch",
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
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/fetch.json",
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
                                        "I can't fetch that right now.",
                                        "That's in a death trap. I'm not fetching it.",
                                        "Too far or too dangerous. Refusing to fetch.",
                                        "My hands and pack are completely full.",
                                        "I won't risk my neck for that junk.",
                                        "Can't retrieve that under current conditions.",
                                        "I don't have the carrying capacity right now.",
                                        "Fetch order rejected. Pick it up yourself.",
                                        "Unable to comply. Item is out of bounds.",
                                        "I can't fetch that for you.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko makuha iyon ngayon.",
                                        "Nasa bitag ng kamatayan 'yan. Di ko kukunin.",
                                        "Masyadong malayo o mapanganib. Tumatangging kunin.",
                                        "Puno na ang kamay at bag ko.",
                                        "Di ko isusugal ang buhay ko para sa basurang 'yan.",
                                        "Di makukuha 'yan sa kasalukuyang kalagayan.",
                                        "Wala na akong espasyong paglalagyan ngayon.",
                                        "Tinatanggihan ang pagkuha. Pulutin mo nang kusa.",
                                        "Di makasusunod. Di abot ang bagay na 'yan.",
                                        "Di ko makukuha 'yan para sa 'yo.",
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
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "task.fetch.rejected",
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
                            ["fallback"] = "I can't fetch that right now.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.task.fetch.rejected.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_fetch_rejected.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I can't fetch that right now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.task.fetch.rejected.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I can't fetch that right now.",
                        "That's in a death trap. I'm not fetching it.",
                        "Too far or too dangerous. Refusing to fetch.",
                        "My hands and pack are completely full.",
                        "I won't risk my neck for that junk.",
                        "Can't retrieve that under current conditions.",
                        "I don't have the carrying capacity right now.",
                        "Fetch order rejected. Pick it up yourself.",
                        "Unable to comply. Item is out of bounds.",
                        "I can't fetch that for you.",
                    },
                    ["TL"] = {
                        "Hindi ko makuha iyon ngayon.",
                        "Nasa bitag ng kamatayan 'yan. Di ko kukunin.",
                        "Masyadong malayo o mapanganib. Tumatangging kunin.",
                        "Puno na ang kamay at bag ko.",
                        "Di ko isusugal ang buhay ko para sa basurang 'yan.",
                        "Di makukuha 'yan sa kasalukuyang kalagayan.",
                        "Wala na akong espasyong paglalagyan ngayon.",
                        "Tinatanggihan ang pagkuha. Pulutin mo nang kusa.",
                        "Di makasusunod. Di abot ang bagay na 'yan.",
                        "Di ko makukuha 'yan para sa 'yo.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.give.active",
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
                                ["fallback"] = "Handing that over now.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.task.give.active.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Handing that over now.",
                                        "Passing the item to you right now.",
                                        "Transferring the supplies.",
                                        "Giving this to you now.",
                                        "Currently handing it over.",
                                        "Reaching out to give you the item.",
                                        "Giving you what was asked.",
                                        "In the middle of the handoff.",
                                        "Handing it off now. Take hold.",
                                        "Giving it as ordered.",
                                    },
                                    ["TL"] = {
                                        "Iniaabot ko na ngayon.",
                                        "Ipinapasa ko na ang gamit sa 'yo ngayon.",
                                        "Inililipat na ang mga kagamitan.",
                                        "Ibinibigay ko na ito sa 'yo ngayon.",
                                        "Kasalukuyang iniaabot.",
                                        "Inaabot para ibigay sa 'yo ang gamit.",
                                        "Ibinibigay sa 'yo ang hiningi.",
                                        "Kasalukuyang nag-aabot.",
                                        "Iniaabot na. Hawakan mo.",
                                        "Ibinibigay ayon sa utos.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "task.give",
            ["textRoles"] = {
                {
                    ["fallback"] = "Handing that over now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.task.give.active.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Handing that over now.",
                            "Passing the item to you right now.",
                            "Transferring the supplies.",
                            "Giving this to you now.",
                            "Currently handing it over.",
                            "Reaching out to give you the item.",
                            "Giving you what was asked.",
                            "In the middle of the handoff.",
                            "Handing it off now. Take hold.",
                            "Giving it as ordered.",
                        },
                        ["TL"] = {
                            "Iniaabot ko na ngayon.",
                            "Ipinapasa ko na ang gamit sa 'yo ngayon.",
                            "Inililipat na ang mga kagamitan.",
                            "Ibinibigay ko na ito sa 'yo ngayon.",
                            "Kasalukuyang iniaabot.",
                            "Inaabot para ibigay sa 'yo ang gamit.",
                            "Ibinibigay sa 'yo ang hiningi.",
                            "Kasalukuyang nag-aabot.",
                            "Iniaabot na. Hawakan mo.",
                            "Ibinibigay ayon sa utos.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "task.give.active",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "active",
            ["sourceId"] = "task.give.active",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_give_active.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle__b4a76fdc",
        ["namespace"] = "task.give",
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
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/give.json",
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
                                        "Handing that over now.",
                                        "Passing the item to you right now.",
                                        "Transferring the supplies.",
                                        "Giving this to you now.",
                                        "Currently handing it over.",
                                        "Reaching out to give you the item.",
                                        "Giving you what was asked.",
                                        "In the middle of the handoff.",
                                        "Handing it off now. Take hold.",
                                        "Giving it as ordered.",
                                    },
                                    ["TL"] = {
                                        "Iniaabot ko na ngayon.",
                                        "Ipinapasa ko na ang gamit sa 'yo ngayon.",
                                        "Inililipat na ang mga kagamitan.",
                                        "Ibinibigay ko na ito sa 'yo ngayon.",
                                        "Kasalukuyang iniaabot.",
                                        "Inaabot para ibigay sa 'yo ang gamit.",
                                        "Ibinibigay sa 'yo ang hiningi.",
                                        "Kasalukuyang nag-aabot.",
                                        "Iniaabot na. Hawakan mo.",
                                        "Ibinibigay ayon sa utos.",
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
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "task.give.active",
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
                            ["fallback"] = "Handing that over now.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.task.give.active.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_give_active.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Handing that over now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.task.give.active.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Handing that over now.",
                        "Passing the item to you right now.",
                        "Transferring the supplies.",
                        "Giving this to you now.",
                        "Currently handing it over.",
                        "Reaching out to give you the item.",
                        "Giving you what was asked.",
                        "In the middle of the handoff.",
                        "Handing it off now. Take hold.",
                        "Giving it as ordered.",
                    },
                    ["TL"] = {
                        "Iniaabot ko na ngayon.",
                        "Ipinapasa ko na ang gamit sa 'yo ngayon.",
                        "Inililipat na ang mga kagamitan.",
                        "Ibinibigay ko na ito sa 'yo ngayon.",
                        "Kasalukuyang iniaabot.",
                        "Inaabot para ibigay sa 'yo ang gamit.",
                        "Ibinibigay sa 'yo ang hiningi.",
                        "Kasalukuyang nag-aabot.",
                        "Iniaabot na. Hawakan mo.",
                        "Ibinibigay ayon sa utos.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.give.admitted",
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
                                ["fallback"] = "I'll give that to you.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.task.give.admitted.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'll give that to you.",
                                        "Understood. Handing it over.",
                                        "Here, I'll pass that to you.",
                                        "All right. I'll give you the item.",
                                        "Sure thing. Passing it over.",
                                        "Understood. You can have it.",
                                        "I'll transfer that to your pack.",
                                        "Right. Handing it over.",
                                        "I'll give you what you requested.",
                                        "Sounds good. Giving it now.",
                                    },
                                    ["TL"] = {
                                        "Ibibigay ko iyon sa iyo.",
                                        "Naintindihan. Iniaabot na.",
                                        "Heto, ipapasa ko 'yan sa 'yo.",
                                        "Sige. Ibibigay ko sa 'yo ang gamit.",
                                        "Walang anuman. Ipinapasa na.",
                                        "Naiintindihan ko. Pwede mong kunin.",
                                        "Ililipat ko 'yan sa bag mo.",
                                        "Sige. Iniaabot na.",
                                        "Ibibigay ko ang hiniling mo.",
                                        "Maganda 'yan. Ibibigay na ngayon.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "task.give",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'll give that to you.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.task.give.admitted.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I'll give that to you.",
                            "Understood. Handing it over.",
                            "Here, I'll pass that to you.",
                            "All right. I'll give you the item.",
                            "Sure thing. Passing it over.",
                            "Understood. You can have it.",
                            "I'll transfer that to your pack.",
                            "Right. Handing it over.",
                            "I'll give you what you requested.",
                            "Sounds good. Giving it now.",
                        },
                        ["TL"] = {
                            "Ibibigay ko iyon sa iyo.",
                            "Naintindihan. Iniaabot na.",
                            "Heto, ipapasa ko 'yan sa 'yo.",
                            "Sige. Ibibigay ko sa 'yo ang gamit.",
                            "Walang anuman. Ipinapasa na.",
                            "Naiintindihan ko. Pwede mong kunin.",
                            "Ililipat ko 'yan sa bag mo.",
                            "Sige. Iniaabot na.",
                            "Ibibigay ko ang hiniling mo.",
                            "Maganda 'yan. Ibibigay na ngayon.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "task.give.admitted",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "admitted",
            ["sourceId"] = "task.give.admitted",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_give_admitted.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle__b4a76fdc",
        ["namespace"] = "task.give",
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
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/give.json",
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
                                        "I'll give that to you.",
                                        "Understood. Handing it over.",
                                        "Here, I'll pass that to you.",
                                        "All right. I'll give you the item.",
                                        "Sure thing. Passing it over.",
                                        "Understood. You can have it.",
                                        "I'll transfer that to your pack.",
                                        "Right. Handing it over.",
                                        "I'll give you what you requested.",
                                        "Sounds good. Giving it now.",
                                    },
                                    ["TL"] = {
                                        "Ibibigay ko iyon sa iyo.",
                                        "Naintindihan. Iniaabot na.",
                                        "Heto, ipapasa ko 'yan sa 'yo.",
                                        "Sige. Ibibigay ko sa 'yo ang gamit.",
                                        "Walang anuman. Ipinapasa na.",
                                        "Naiintindihan ko. Pwede mong kunin.",
                                        "Ililipat ko 'yan sa bag mo.",
                                        "Sige. Iniaabot na.",
                                        "Ibibigay ko ang hiniling mo.",
                                        "Maganda 'yan. Ibibigay na ngayon.",
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
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "task.give.admitted",
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
                            ["fallback"] = "I'll give that to you.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.task.give.admitted.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_give_admitted.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'll give that to you.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.task.give.admitted.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I'll give that to you.",
                        "Understood. Handing it over.",
                        "Here, I'll pass that to you.",
                        "All right. I'll give you the item.",
                        "Sure thing. Passing it over.",
                        "Understood. You can have it.",
                        "I'll transfer that to your pack.",
                        "Right. Handing it over.",
                        "I'll give you what you requested.",
                        "Sounds good. Giving it now.",
                    },
                    ["TL"] = {
                        "Ibibigay ko iyon sa iyo.",
                        "Naintindihan. Iniaabot na.",
                        "Heto, ipapasa ko 'yan sa 'yo.",
                        "Sige. Ibibigay ko sa 'yo ang gamit.",
                        "Walang anuman. Ipinapasa na.",
                        "Naiintindihan ko. Pwede mong kunin.",
                        "Ililipat ko 'yan sa bag mo.",
                        "Sige. Iniaabot na.",
                        "Ibibigay ko ang hiniling mo.",
                        "Maganda 'yan. Ibibigay na ngayon.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.give.completed",
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
                                ["fallback"] = "There you go.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.task.give.completed.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "There you go.",
                                        "Handed over safely.",
                                        "It's yours now.",
                                        "Transfer complete.",
                                        "All given. Take good care of it.",
                                        "Done. It's in your hands.",
                                        "Handoff finished.",
                                        "Given as requested.",
                                        "Item is officially yours.",
                                        "Completed the handoff.",
                                    },
                                    ["TL"] = {
                                        "Heto na.",
                                        "Naibigay na nang ligtas.",
                                        "Nasa sa 'yo na ngayon.",
                                        "Tapos na ang paglipat.",
                                        "Naibigay na lahat. Ingatan mo 'yan.",
                                        "Tapos na. Nasa mga kamay mo na.",
                                        "Tapos na ang pag-aabot.",
                                        "Naibigay ayon sa hiling.",
                                        "Sa 'yo na ang gamit opisyal.",
                                        "Natapos ang pag-aabot.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "task.give",
            ["textRoles"] = {
                {
                    ["fallback"] = "There you go.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.task.give.completed.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "There you go.",
                            "Handed over safely.",
                            "It's yours now.",
                            "Transfer complete.",
                            "All given. Take good care of it.",
                            "Done. It's in your hands.",
                            "Handoff finished.",
                            "Given as requested.",
                            "Item is officially yours.",
                            "Completed the handoff.",
                        },
                        ["TL"] = {
                            "Heto na.",
                            "Naibigay na nang ligtas.",
                            "Nasa sa 'yo na ngayon.",
                            "Tapos na ang paglipat.",
                            "Naibigay na lahat. Ingatan mo 'yan.",
                            "Tapos na. Nasa mga kamay mo na.",
                            "Tapos na ang pag-aabot.",
                            "Naibigay ayon sa hiling.",
                            "Sa 'yo na ang gamit opisyal.",
                            "Natapos ang pag-aabot.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "task.give.completed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "completed",
            ["sourceId"] = "task.give.completed",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_give_completed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle__b4a76fdc",
        ["namespace"] = "task.give",
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
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/give.json",
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
                                        "There you go.",
                                        "Handed over safely.",
                                        "It's yours now.",
                                        "Transfer complete.",
                                        "All given. Take good care of it.",
                                        "Done. It's in your hands.",
                                        "Handoff finished.",
                                        "Given as requested.",
                                        "Item is officially yours.",
                                        "Completed the handoff.",
                                    },
                                    ["TL"] = {
                                        "Heto na.",
                                        "Naibigay na nang ligtas.",
                                        "Nasa sa 'yo na ngayon.",
                                        "Tapos na ang paglipat.",
                                        "Naibigay na lahat. Ingatan mo 'yan.",
                                        "Tapos na. Nasa mga kamay mo na.",
                                        "Tapos na ang pag-aabot.",
                                        "Naibigay ayon sa hiling.",
                                        "Sa 'yo na ang gamit opisyal.",
                                        "Natapos ang pag-aabot.",
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
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "task.give.completed",
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
                            ["fallback"] = "There you go.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.task.give.completed.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_give_completed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "There you go.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.task.give.completed.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "There you go.",
                        "Handed over safely.",
                        "It's yours now.",
                        "Transfer complete.",
                        "All given. Take good care of it.",
                        "Done. It's in your hands.",
                        "Handoff finished.",
                        "Given as requested.",
                        "Item is officially yours.",
                        "Completed the handoff.",
                    },
                    ["TL"] = {
                        "Heto na.",
                        "Naibigay na nang ligtas.",
                        "Nasa sa 'yo na ngayon.",
                        "Tapos na ang paglipat.",
                        "Naibigay na lahat. Ingatan mo 'yan.",
                        "Tapos na. Nasa mga kamay mo na.",
                        "Tapos na ang pag-aabot.",
                        "Naibigay ayon sa hiling.",
                        "Sa 'yo na ang gamit opisyal.",
                        "Natapos ang pag-aabot.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.give.failed",
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
                                ["fallback"] = "I couldn't give that to you.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.task.give.failed.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I couldn't give that to you.",
                                        "Handoff failed. You were out of reach.",
                                        "Your hands or pack were full. Couldn't give it.",
                                        "Action interrupted. Item not given.",
                                        "Unable to transfer the item to you.",
                                        "Failed to hand it over. Something got in the way.",
                                        "I couldn't complete the give action.",
                                        "Dropped it during the exchange.",
                                        "Give task failed.",
                                        "Could not give that item.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko naibigay iyon sa iyo.",
                                        "Pumalpak ang pag-aabot. Masyado kang malayo.",
                                        "Puno ang kamay o bag mo. Di maibigay.",
                                        "Naabala ang kilos. Di naibigay ang gamit.",
                                        "Di mailipat ang gamit sa 'yo.",
                                        "Bigo sa pag-aabot. May humarang sa pagitan.",
                                        "Di ko natapos ang pagbibigay.",
                                        "Nahulog habang nagpapalitan.",
                                        "Bigo ang gawaing magbigay.",
                                        "Hindi naibigay ang bagay na 'yan.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "task.give",
            ["textRoles"] = {
                {
                    ["fallback"] = "I couldn't give that to you.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.task.give.failed.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I couldn't give that to you.",
                            "Handoff failed. You were out of reach.",
                            "Your hands or pack were full. Couldn't give it.",
                            "Action interrupted. Item not given.",
                            "Unable to transfer the item to you.",
                            "Failed to hand it over. Something got in the way.",
                            "I couldn't complete the give action.",
                            "Dropped it during the exchange.",
                            "Give task failed.",
                            "Could not give that item.",
                        },
                        ["TL"] = {
                            "Hindi ko naibigay iyon sa iyo.",
                            "Pumalpak ang pag-aabot. Masyado kang malayo.",
                            "Puno ang kamay o bag mo. Di maibigay.",
                            "Naabala ang kilos. Di naibigay ang gamit.",
                            "Di mailipat ang gamit sa 'yo.",
                            "Bigo sa pag-aabot. May humarang sa pagitan.",
                            "Di ko natapos ang pagbibigay.",
                            "Nahulog habang nagpapalitan.",
                            "Bigo ang gawaing magbigay.",
                            "Hindi naibigay ang bagay na 'yan.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "task.give.failed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "failed",
            ["sourceId"] = "task.give.failed",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_give_failed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle__b4a76fdc",
        ["namespace"] = "task.give",
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
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/give.json",
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
                                        "I couldn't give that to you.",
                                        "Handoff failed. You were out of reach.",
                                        "Your hands or pack were full. Couldn't give it.",
                                        "Action interrupted. Item not given.",
                                        "Unable to transfer the item to you.",
                                        "Failed to hand it over. Something got in the way.",
                                        "I couldn't complete the give action.",
                                        "Dropped it during the exchange.",
                                        "Give task failed.",
                                        "Could not give that item.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko naibigay iyon sa iyo.",
                                        "Pumalpak ang pag-aabot. Masyado kang malayo.",
                                        "Puno ang kamay o bag mo. Di maibigay.",
                                        "Naabala ang kilos. Di naibigay ang gamit.",
                                        "Di mailipat ang gamit sa 'yo.",
                                        "Bigo sa pag-aabot. May humarang sa pagitan.",
                                        "Di ko natapos ang pagbibigay.",
                                        "Nahulog habang nagpapalitan.",
                                        "Bigo ang gawaing magbigay.",
                                        "Hindi naibigay ang bagay na 'yan.",
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
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "task.give.failed",
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
                            ["fallback"] = "I couldn't give that to you.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.task.give.failed.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_give_failed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I couldn't give that to you.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.task.give.failed.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I couldn't give that to you.",
                        "Handoff failed. You were out of reach.",
                        "Your hands or pack were full. Couldn't give it.",
                        "Action interrupted. Item not given.",
                        "Unable to transfer the item to you.",
                        "Failed to hand it over. Something got in the way.",
                        "I couldn't complete the give action.",
                        "Dropped it during the exchange.",
                        "Give task failed.",
                        "Could not give that item.",
                    },
                    ["TL"] = {
                        "Hindi ko naibigay iyon sa iyo.",
                        "Pumalpak ang pag-aabot. Masyado kang malayo.",
                        "Puno ang kamay o bag mo. Di maibigay.",
                        "Naabala ang kilos. Di naibigay ang gamit.",
                        "Di mailipat ang gamit sa 'yo.",
                        "Bigo sa pag-aabot. May humarang sa pagitan.",
                        "Di ko natapos ang pagbibigay.",
                        "Nahulog habang nagpapalitan.",
                        "Bigo ang gawaing magbigay.",
                        "Hindi naibigay ang bagay na 'yan.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.give.rejected",
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
                                ["fallback"] = "I can't give that to you right now.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.task.give.rejected.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I can't give that to you right now.",
                                        "I need that item to survive. Can't spare it.",
                                        "That is vital to my loadout. I won't give it away.",
                                        "Refusing to hand that over.",
                                        "I don't have that item to give.",
                                        "Can't give that up under these circumstances.",
                                        "That's not something I can part with.",
                                        "Give order rejected. I'm keeping this.",
                                        "I won't give that item away.",
                                        "Not giving that. Ask for something else.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko maibibigay iyon sa iyo ngayon.",
                                        "Kailangan ko 'yan para mabuhay. Di ko maipamimigay.",
                                        "Mahalaga 'yan sa gamit ko. Di ko ipamimigay.",
                                        "Tumatangging iabot 'yan.",
                                        "Wala sa akin ang gamit na 'yan para ibigay.",
                                        "Di ko maibibigay 'yan sa ganitong kalagayan.",
                                        "Hindi bagay 'yan na kaya kong bitiwan.",
                                        "Tinatanggihan ang pagbibigay. Itatabi ko ito.",
                                        "Di ko ipamimigay ang bagay na 'yan.",
                                        "Di ibibigay 'yan. Humingi ka ng iba.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "task.give",
            ["textRoles"] = {
                {
                    ["fallback"] = "I can't give that to you right now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.task.give.rejected.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I can't give that to you right now.",
                            "I need that item to survive. Can't spare it.",
                            "That is vital to my loadout. I won't give it away.",
                            "Refusing to hand that over.",
                            "I don't have that item to give.",
                            "Can't give that up under these circumstances.",
                            "That's not something I can part with.",
                            "Give order rejected. I'm keeping this.",
                            "I won't give that item away.",
                            "Not giving that. Ask for something else.",
                        },
                        ["TL"] = {
                            "Hindi ko maibibigay iyon sa iyo ngayon.",
                            "Kailangan ko 'yan para mabuhay. Di ko maipamimigay.",
                            "Mahalaga 'yan sa gamit ko. Di ko ipamimigay.",
                            "Tumatangging iabot 'yan.",
                            "Wala sa akin ang gamit na 'yan para ibigay.",
                            "Di ko maibibigay 'yan sa ganitong kalagayan.",
                            "Hindi bagay 'yan na kaya kong bitiwan.",
                            "Tinatanggihan ang pagbibigay. Itatabi ko ito.",
                            "Di ko ipamimigay ang bagay na 'yan.",
                            "Di ibibigay 'yan. Humingi ka ng iba.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "task.give.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "rejected",
            ["sourceId"] = "task.give.rejected",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_give_rejected.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle__b4a76fdc",
        ["namespace"] = "task.give",
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
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/give.json",
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
                                        "I can't give that to you right now.",
                                        "I need that item to survive. Can't spare it.",
                                        "That is vital to my loadout. I won't give it away.",
                                        "Refusing to hand that over.",
                                        "I don't have that item to give.",
                                        "Can't give that up under these circumstances.",
                                        "That's not something I can part with.",
                                        "Give order rejected. I'm keeping this.",
                                        "I won't give that item away.",
                                        "Not giving that. Ask for something else.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko maibibigay iyon sa iyo ngayon.",
                                        "Kailangan ko 'yan para mabuhay. Di ko maipamimigay.",
                                        "Mahalaga 'yan sa gamit ko. Di ko ipamimigay.",
                                        "Tumatangging iabot 'yan.",
                                        "Wala sa akin ang gamit na 'yan para ibigay.",
                                        "Di ko maibibigay 'yan sa ganitong kalagayan.",
                                        "Hindi bagay 'yan na kaya kong bitiwan.",
                                        "Tinatanggihan ang pagbibigay. Itatabi ko ito.",
                                        "Di ko ipamimigay ang bagay na 'yan.",
                                        "Di ibibigay 'yan. Humingi ka ng iba.",
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
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "task.give.rejected",
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
                            ["fallback"] = "I can't give that to you right now.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.task.give.rejected.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_give_rejected.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I can't give that to you right now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.task.give.rejected.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I can't give that to you right now.",
                        "I need that item to survive. Can't spare it.",
                        "That is vital to my loadout. I won't give it away.",
                        "Refusing to hand that over.",
                        "I don't have that item to give.",
                        "Can't give that up under these circumstances.",
                        "That's not something I can part with.",
                        "Give order rejected. I'm keeping this.",
                        "I won't give that item away.",
                        "Not giving that. Ask for something else.",
                    },
                    ["TL"] = {
                        "Hindi ko maibibigay iyon sa iyo ngayon.",
                        "Kailangan ko 'yan para mabuhay. Di ko maipamimigay.",
                        "Mahalaga 'yan sa gamit ko. Di ko ipamimigay.",
                        "Tumatangging iabot 'yan.",
                        "Wala sa akin ang gamit na 'yan para ibigay.",
                        "Di ko maibibigay 'yan sa ganitong kalagayan.",
                        "Hindi bagay 'yan na kaya kong bitiwan.",
                        "Tinatanggihan ang pagbibigay. Itatabi ko ito.",
                        "Di ko ipamimigay ang bagay na 'yan.",
                        "Di ibibigay 'yan. Humingi ka ng iba.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.refill.active",
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
                                ["fallback"] = "Refilling the container now.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.task.refill.active.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Refilling the container now.",
                                        "Currently filling up on water.",
                                        "Topping off the fluids right now.",
                                        "Working on refilling the bottle.",
                                        "Gathering water into the container.",
                                        "In the middle of refilling.",
                                        "Refilling as instructed.",
                                        "Collecting clean water now.",
                                        "Topping it up. Give me a moment.",
                                        "Refill in progress.",
                                    },
                                    ["TL"] = {
                                        "Nilalagyan ng laman ang lalagyan ngayon.",
                                        "Kasalukuyang nagpapasok ng tubig.",
                                        "Pinupuno ang inumin ngayon.",
                                        "Pinupuno ang bote.",
                                        "Kumukuha ng tubig sa lalagyan.",
                                        "Kasalukuyang nagpupuno.",
                                        "Nagpupuno ayon sa utos.",
                                        "Kumukuha ng malinis na tubig ngayon.",
                                        "Pinupuno ito. Sandali lang.",
                                        "Kasalukuyang nagpupuno.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "task.refill",
            ["textRoles"] = {
                {
                    ["fallback"] = "Refilling the container now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.task.refill.active.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Refilling the container now.",
                            "Currently filling up on water.",
                            "Topping off the fluids right now.",
                            "Working on refilling the bottle.",
                            "Gathering water into the container.",
                            "In the middle of refilling.",
                            "Refilling as instructed.",
                            "Collecting clean water now.",
                            "Topping it up. Give me a moment.",
                            "Refill in progress.",
                        },
                        ["TL"] = {
                            "Nilalagyan ng laman ang lalagyan ngayon.",
                            "Kasalukuyang nagpapasok ng tubig.",
                            "Pinupuno ang inumin ngayon.",
                            "Pinupuno ang bote.",
                            "Kumukuha ng tubig sa lalagyan.",
                            "Kasalukuyang nagpupuno.",
                            "Nagpupuno ayon sa utos.",
                            "Kumukuha ng malinis na tubig ngayon.",
                            "Pinupuno ito. Sandali lang.",
                            "Kasalukuyang nagpupuno.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "task.refill.active",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "active",
            ["sourceId"] = "task.refill.active",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_refill_active.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle__b4a76fdc",
        ["namespace"] = "task.refill",
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
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/refill.json",
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
                                        "Refilling the container now.",
                                        "Currently filling up on water.",
                                        "Topping off the fluids right now.",
                                        "Working on refilling the bottle.",
                                        "Gathering water into the container.",
                                        "In the middle of refilling.",
                                        "Refilling as instructed.",
                                        "Collecting clean water now.",
                                        "Topping it up. Give me a moment.",
                                        "Refill in progress.",
                                    },
                                    ["TL"] = {
                                        "Nilalagyan ng laman ang lalagyan ngayon.",
                                        "Kasalukuyang nagpapasok ng tubig.",
                                        "Pinupuno ang inumin ngayon.",
                                        "Pinupuno ang bote.",
                                        "Kumukuha ng tubig sa lalagyan.",
                                        "Kasalukuyang nagpupuno.",
                                        "Nagpupuno ayon sa utos.",
                                        "Kumukuha ng malinis na tubig ngayon.",
                                        "Pinupuno ito. Sandali lang.",
                                        "Kasalukuyang nagpupuno.",
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
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "task.refill.active",
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
                            ["fallback"] = "Refilling the container now.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.task.refill.active.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_refill_active.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Refilling the container now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.task.refill.active.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Refilling the container now.",
                        "Currently filling up on water.",
                        "Topping off the fluids right now.",
                        "Working on refilling the bottle.",
                        "Gathering water into the container.",
                        "In the middle of refilling.",
                        "Refilling as instructed.",
                        "Collecting clean water now.",
                        "Topping it up. Give me a moment.",
                        "Refill in progress.",
                    },
                    ["TL"] = {
                        "Nilalagyan ng laman ang lalagyan ngayon.",
                        "Kasalukuyang nagpapasok ng tubig.",
                        "Pinupuno ang inumin ngayon.",
                        "Pinupuno ang bote.",
                        "Kumukuha ng tubig sa lalagyan.",
                        "Kasalukuyang nagpupuno.",
                        "Nagpupuno ayon sa utos.",
                        "Kumukuha ng malinis na tubig ngayon.",
                        "Pinupuno ito. Sandali lang.",
                        "Kasalukuyang nagpupuno.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.refill.admitted",
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
                                ["fallback"] = "I'll refill that.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.task.refill.admitted.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'll refill that.",
                                        "Understood. Topping up the water supply.",
                                        "I'll go get the bottles filled.",
                                        "All right, refilling the containers.",
                                        "Good call. We need full canteens.",
                                        "I'll take it to the water source.",
                                        "Understood. Refilling immediately.",
                                        "Right. Getting fresh water.",
                                        "I'll refill what's empty.",
                                        "Sounds good. Heading to refill.",
                                    },
                                    ["TL"] = {
                                        "Lalagyan ko ng laman iyon.",
                                        "Naintindihan. Pupunuin ang supply ng tubig.",
                                        "Pupunta ako para punuin ang mga bote.",
                                        "Sige, pupunuin ang mga lalagyan.",
                                        "Magandang paalala. Kailangan natin ng punong sisidlan.",
                                        "Dadalhin ko sa pinagkukunan ng tubig.",
                                        "Naiintindihan ko. Pupunuin agad.",
                                        "Sige. Kukuha ng sariwang tubig.",
                                        "Pupunuin ko ang walang laman.",
                                        "Maganda 'yan. Pupunta para magpuno.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "task.refill",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'll refill that.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.task.refill.admitted.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I'll refill that.",
                            "Understood. Topping up the water supply.",
                            "I'll go get the bottles filled.",
                            "All right, refilling the containers.",
                            "Good call. We need full canteens.",
                            "I'll take it to the water source.",
                            "Understood. Refilling immediately.",
                            "Right. Getting fresh water.",
                            "I'll refill what's empty.",
                            "Sounds good. Heading to refill.",
                        },
                        ["TL"] = {
                            "Lalagyan ko ng laman iyon.",
                            "Naintindihan. Pupunuin ang supply ng tubig.",
                            "Pupunta ako para punuin ang mga bote.",
                            "Sige, pupunuin ang mga lalagyan.",
                            "Magandang paalala. Kailangan natin ng punong sisidlan.",
                            "Dadalhin ko sa pinagkukunan ng tubig.",
                            "Naiintindihan ko. Pupunuin agad.",
                            "Sige. Kukuha ng sariwang tubig.",
                            "Pupunuin ko ang walang laman.",
                            "Maganda 'yan. Pupunta para magpuno.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "task.refill.admitted",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "admitted",
            ["sourceId"] = "task.refill.admitted",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_refill_admitted.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle__b4a76fdc",
        ["namespace"] = "task.refill",
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
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/refill.json",
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
                                        "I'll refill that.",
                                        "Understood. Topping up the water supply.",
                                        "I'll go get the bottles filled.",
                                        "All right, refilling the containers.",
                                        "Good call. We need full canteens.",
                                        "I'll take it to the water source.",
                                        "Understood. Refilling immediately.",
                                        "Right. Getting fresh water.",
                                        "I'll refill what's empty.",
                                        "Sounds good. Heading to refill.",
                                    },
                                    ["TL"] = {
                                        "Lalagyan ko ng laman iyon.",
                                        "Naintindihan. Pupunuin ang supply ng tubig.",
                                        "Pupunta ako para punuin ang mga bote.",
                                        "Sige, pupunuin ang mga lalagyan.",
                                        "Magandang paalala. Kailangan natin ng punong sisidlan.",
                                        "Dadalhin ko sa pinagkukunan ng tubig.",
                                        "Naiintindihan ko. Pupunuin agad.",
                                        "Sige. Kukuha ng sariwang tubig.",
                                        "Pupunuin ko ang walang laman.",
                                        "Maganda 'yan. Pupunta para magpuno.",
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
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "task.refill.admitted",
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
                            ["fallback"] = "I'll refill that.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.task.refill.admitted.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_refill_admitted.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'll refill that.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.task.refill.admitted.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I'll refill that.",
                        "Understood. Topping up the water supply.",
                        "I'll go get the bottles filled.",
                        "All right, refilling the containers.",
                        "Good call. We need full canteens.",
                        "I'll take it to the water source.",
                        "Understood. Refilling immediately.",
                        "Right. Getting fresh water.",
                        "I'll refill what's empty.",
                        "Sounds good. Heading to refill.",
                    },
                    ["TL"] = {
                        "Lalagyan ko ng laman iyon.",
                        "Naintindihan. Pupunuin ang supply ng tubig.",
                        "Pupunta ako para punuin ang mga bote.",
                        "Sige, pupunuin ang mga lalagyan.",
                        "Magandang paalala. Kailangan natin ng punong sisidlan.",
                        "Dadalhin ko sa pinagkukunan ng tubig.",
                        "Naiintindihan ko. Pupunuin agad.",
                        "Sige. Kukuha ng sariwang tubig.",
                        "Pupunuin ko ang walang laman.",
                        "Maganda 'yan. Pupunta para magpuno.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.refill.completed",
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
                                ["fallback"] = "All topped off. Container is full.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.task.refill.completed.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "All topped off. Container is full.",
                                        "Refill complete. Ready for the road.",
                                        "Finished refilling with clean water.",
                                        "Bottles are full again.",
                                        "Task done. Plenty of water now.",
                                        "Refilled and secured.",
                                        "Canteens are full. Good work.",
                                        "All filled up.",
                                        "Water refilled successfully.",
                                        "Completed refilling the supply.",
                                    },
                                    ["TL"] = {
                                        "Puno na lahat. Punong-puno ang lalagyan.",
                                        "Tapos na ang pagpuno. Handa na sa paglakad.",
                                        "Tapos nang lagyan ng malinis na tubig.",
                                        "Puno na muli ang mga bote.",
                                        "Tapos na ang gawain. Marami nang tubig ngayon.",
                                        "Napuno na at naselyuhan.",
                                        "Puno na ang mga sisidlan. Magaling.",
                                        "Puno na ang lahat.",
                                        "Matagumpay na nalagyan ng tubig.",
                                        "Natapos ang pagpuno sa supply.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "task.refill",
            ["textRoles"] = {
                {
                    ["fallback"] = "All topped off. Container is full.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.task.refill.completed.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "All topped off. Container is full.",
                            "Refill complete. Ready for the road.",
                            "Finished refilling with clean water.",
                            "Bottles are full again.",
                            "Task done. Plenty of water now.",
                            "Refilled and secured.",
                            "Canteens are full. Good work.",
                            "All filled up.",
                            "Water refilled successfully.",
                            "Completed refilling the supply.",
                        },
                        ["TL"] = {
                            "Puno na lahat. Punong-puno ang lalagyan.",
                            "Tapos na ang pagpuno. Handa na sa paglakad.",
                            "Tapos nang lagyan ng malinis na tubig.",
                            "Puno na muli ang mga bote.",
                            "Tapos na ang gawain. Marami nang tubig ngayon.",
                            "Napuno na at naselyuhan.",
                            "Puno na ang mga sisidlan. Magaling.",
                            "Puno na ang lahat.",
                            "Matagumpay na nalagyan ng tubig.",
                            "Natapos ang pagpuno sa supply.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "task.refill.completed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "completed",
            ["sourceId"] = "task.refill.completed",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_refill_completed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle__b4a76fdc",
        ["namespace"] = "task.refill",
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
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/refill.json",
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
                                        "All topped off. Container is full.",
                                        "Refill complete. Ready for the road.",
                                        "Finished refilling with clean water.",
                                        "Bottles are full again.",
                                        "Task done. Plenty of water now.",
                                        "Refilled and secured.",
                                        "Canteens are full. Good work.",
                                        "All filled up.",
                                        "Water refilled successfully.",
                                        "Completed refilling the supply.",
                                    },
                                    ["TL"] = {
                                        "Puno na lahat. Punong-puno ang lalagyan.",
                                        "Tapos na ang pagpuno. Handa na sa paglakad.",
                                        "Tapos nang lagyan ng malinis na tubig.",
                                        "Puno na muli ang mga bote.",
                                        "Tapos na ang gawain. Marami nang tubig ngayon.",
                                        "Napuno na at naselyuhan.",
                                        "Puno na ang mga sisidlan. Magaling.",
                                        "Puno na ang lahat.",
                                        "Matagumpay na nalagyan ng tubig.",
                                        "Natapos ang pagpuno sa supply.",
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
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "task.refill.completed",
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
                            ["fallback"] = "All topped off. Container is full.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.task.refill.completed.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_refill_completed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "All topped off. Container is full.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.task.refill.completed.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "All topped off. Container is full.",
                        "Refill complete. Ready for the road.",
                        "Finished refilling with clean water.",
                        "Bottles are full again.",
                        "Task done. Plenty of water now.",
                        "Refilled and secured.",
                        "Canteens are full. Good work.",
                        "All filled up.",
                        "Water refilled successfully.",
                        "Completed refilling the supply.",
                    },
                    ["TL"] = {
                        "Puno na lahat. Punong-puno ang lalagyan.",
                        "Tapos na ang pagpuno. Handa na sa paglakad.",
                        "Tapos nang lagyan ng malinis na tubig.",
                        "Puno na muli ang mga bote.",
                        "Tapos na ang gawain. Marami nang tubig ngayon.",
                        "Napuno na at naselyuhan.",
                        "Puno na ang mga sisidlan. Magaling.",
                        "Puno na ang lahat.",
                        "Matagumpay na nalagyan ng tubig.",
                        "Natapos ang pagpuno sa supply.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.refill.failed",
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
                                ["fallback"] = "I couldn't refill that.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.task.refill.failed.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I couldn't refill that.",
                                        "The water source was dry or cut off.",
                                        "Failed to refill. Water was contaminated.",
                                        "I was interrupted while trying to gather water.",
                                        "Unable to find a functional water tap.",
                                        "Container is damaged or cracked. Refill failed.",
                                        "Couldn't reach the source safely.",
                                        "Hostiles near the water source. Refill aborted.",
                                        "Action failed. Bottle still empty.",
                                        "Could not refill container.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko nalagyan ng laman iyon.",
                                        "Tuyot o putol ang pinagkukunan ng tubig.",
                                        "Bigo sa pagpuno. Kontaminado ang tubig.",
                                        "Naabala ako habang sumusubok kumuha ng tubig.",
                                        "Walang makitang gumaganang gripo.",
                                        "May basag ang lalagyan. Pumalpak ang pagpuno.",
                                        "Di maabot ang pinagkukunan nang ligtas.",
                                        "May kalaban malapit sa tubig. Itinigil ang pagpuno.",
                                        "Bigo ang kilos. Walang laman pa rin ang bote.",
                                        "Hindi napuno ang lalagyan.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "task.refill",
            ["textRoles"] = {
                {
                    ["fallback"] = "I couldn't refill that.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.task.refill.failed.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I couldn't refill that.",
                            "The water source was dry or cut off.",
                            "Failed to refill. Water was contaminated.",
                            "I was interrupted while trying to gather water.",
                            "Unable to find a functional water tap.",
                            "Container is damaged or cracked. Refill failed.",
                            "Couldn't reach the source safely.",
                            "Hostiles near the water source. Refill aborted.",
                            "Action failed. Bottle still empty.",
                            "Could not refill container.",
                        },
                        ["TL"] = {
                            "Hindi ko nalagyan ng laman iyon.",
                            "Tuyot o putol ang pinagkukunan ng tubig.",
                            "Bigo sa pagpuno. Kontaminado ang tubig.",
                            "Naabala ako habang sumusubok kumuha ng tubig.",
                            "Walang makitang gumaganang gripo.",
                            "May basag ang lalagyan. Pumalpak ang pagpuno.",
                            "Di maabot ang pinagkukunan nang ligtas.",
                            "May kalaban malapit sa tubig. Itinigil ang pagpuno.",
                            "Bigo ang kilos. Walang laman pa rin ang bote.",
                            "Hindi napuno ang lalagyan.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "task.refill.failed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "failed",
            ["sourceId"] = "task.refill.failed",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_refill_failed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle__b4a76fdc",
        ["namespace"] = "task.refill",
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
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/refill.json",
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
                                        "I couldn't refill that.",
                                        "The water source was dry or cut off.",
                                        "Failed to refill. Water was contaminated.",
                                        "I was interrupted while trying to gather water.",
                                        "Unable to find a functional water tap.",
                                        "Container is damaged or cracked. Refill failed.",
                                        "Couldn't reach the source safely.",
                                        "Hostiles near the water source. Refill aborted.",
                                        "Action failed. Bottle still empty.",
                                        "Could not refill container.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko nalagyan ng laman iyon.",
                                        "Tuyot o putol ang pinagkukunan ng tubig.",
                                        "Bigo sa pagpuno. Kontaminado ang tubig.",
                                        "Naabala ako habang sumusubok kumuha ng tubig.",
                                        "Walang makitang gumaganang gripo.",
                                        "May basag ang lalagyan. Pumalpak ang pagpuno.",
                                        "Di maabot ang pinagkukunan nang ligtas.",
                                        "May kalaban malapit sa tubig. Itinigil ang pagpuno.",
                                        "Bigo ang kilos. Walang laman pa rin ang bote.",
                                        "Hindi napuno ang lalagyan.",
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
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "task.refill.failed",
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
                            ["fallback"] = "I couldn't refill that.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.task.refill.failed.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_refill_failed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I couldn't refill that.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.task.refill.failed.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I couldn't refill that.",
                        "The water source was dry or cut off.",
                        "Failed to refill. Water was contaminated.",
                        "I was interrupted while trying to gather water.",
                        "Unable to find a functional water tap.",
                        "Container is damaged or cracked. Refill failed.",
                        "Couldn't reach the source safely.",
                        "Hostiles near the water source. Refill aborted.",
                        "Action failed. Bottle still empty.",
                        "Could not refill container.",
                    },
                    ["TL"] = {
                        "Hindi ko nalagyan ng laman iyon.",
                        "Tuyot o putol ang pinagkukunan ng tubig.",
                        "Bigo sa pagpuno. Kontaminado ang tubig.",
                        "Naabala ako habang sumusubok kumuha ng tubig.",
                        "Walang makitang gumaganang gripo.",
                        "May basag ang lalagyan. Pumalpak ang pagpuno.",
                        "Di maabot ang pinagkukunan nang ligtas.",
                        "May kalaban malapit sa tubig. Itinigil ang pagpuno.",
                        "Bigo ang kilos. Walang laman pa rin ang bote.",
                        "Hindi napuno ang lalagyan.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.refill.rejected",
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
                                ["fallback"] = "I can't refill that right now.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.task.refill.rejected.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I can't refill that right now.",
                                        "There is no known clean water source nearby.",
                                        "The container is already completely full.",
                                        "Too exposed to stand around pumping water.",
                                        "I won't approach that water source. It's a death trap.",
                                        "Can't refill. No suitable vessel available.",
                                        "Refill order rejected. Bad timing.",
                                        "Water is tainted there. I refuse to collect it.",
                                        "We need to deal with threats before refilling.",
                                        "I can't refill that under current danger.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko malalagyan ng laman iyon ngayon.",
                                        "Walang kilalang malinis na tubig sa malapit.",
                                        "Puno na ang lalagyan.",
                                        "Masyadong lantad para magbomba ng tubig.",
                                        "Di ako lalapit sa tubig na 'yan. Bitag 'yan.",
                                        "Di makapagpuno. Walang angkop na sisidlan.",
                                        "Tinatanggihan ang pagpuno. Maling oras.",
                                        "Marumi ang tubig doon. Tumatanggi akong kumuha.",
                                        "Harapin muna natin ang banta bago magpuno.",
                                        "Di ko malalagyan 'yan sa gitna ng panganib.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "task.refill",
            ["textRoles"] = {
                {
                    ["fallback"] = "I can't refill that right now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.task.refill.rejected.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I can't refill that right now.",
                            "There is no known clean water source nearby.",
                            "The container is already completely full.",
                            "Too exposed to stand around pumping water.",
                            "I won't approach that water source. It's a death trap.",
                            "Can't refill. No suitable vessel available.",
                            "Refill order rejected. Bad timing.",
                            "Water is tainted there. I refuse to collect it.",
                            "We need to deal with threats before refilling.",
                            "I can't refill that under current danger.",
                        },
                        ["TL"] = {
                            "Hindi ko malalagyan ng laman iyon ngayon.",
                            "Walang kilalang malinis na tubig sa malapit.",
                            "Puno na ang lalagyan.",
                            "Masyadong lantad para magbomba ng tubig.",
                            "Di ako lalapit sa tubig na 'yan. Bitag 'yan.",
                            "Di makapagpuno. Walang angkop na sisidlan.",
                            "Tinatanggihan ang pagpuno. Maling oras.",
                            "Marumi ang tubig doon. Tumatanggi akong kumuha.",
                            "Harapin muna natin ang banta bago magpuno.",
                            "Di ko malalagyan 'yan sa gitna ng panganib.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "task.refill.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "rejected",
            ["sourceId"] = "task.refill.rejected",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_refill_rejected.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle__b4a76fdc",
        ["namespace"] = "task.refill",
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
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/refill.json",
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
                                        "I can't refill that right now.",
                                        "There is no known clean water source nearby.",
                                        "The container is already completely full.",
                                        "Too exposed to stand around pumping water.",
                                        "I won't approach that water source. It's a death trap.",
                                        "Can't refill. No suitable vessel available.",
                                        "Refill order rejected. Bad timing.",
                                        "Water is tainted there. I refuse to collect it.",
                                        "We need to deal with threats before refilling.",
                                        "I can't refill that under current danger.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko malalagyan ng laman iyon ngayon.",
                                        "Walang kilalang malinis na tubig sa malapit.",
                                        "Puno na ang lalagyan.",
                                        "Masyadong lantad para magbomba ng tubig.",
                                        "Di ako lalapit sa tubig na 'yan. Bitag 'yan.",
                                        "Di makapagpuno. Walang angkop na sisidlan.",
                                        "Tinatanggihan ang pagpuno. Maling oras.",
                                        "Marumi ang tubig doon. Tumatanggi akong kumuha.",
                                        "Harapin muna natin ang banta bago magpuno.",
                                        "Di ko malalagyan 'yan sa gitna ng panganib.",
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
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "task.refill.rejected",
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
                            ["fallback"] = "I can't refill that right now.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.task.refill.rejected.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_refill_rejected.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I can't refill that right now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.task.refill.rejected.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I can't refill that right now.",
                        "There is no known clean water source nearby.",
                        "The container is already completely full.",
                        "Too exposed to stand around pumping water.",
                        "I won't approach that water source. It's a death trap.",
                        "Can't refill. No suitable vessel available.",
                        "Refill order rejected. Bad timing.",
                        "Water is tainted there. I refuse to collect it.",
                        "We need to deal with threats before refilling.",
                        "I can't refill that under current danger.",
                    },
                    ["TL"] = {
                        "Hindi ko malalagyan ng laman iyon ngayon.",
                        "Walang kilalang malinis na tubig sa malapit.",
                        "Puno na ang lalagyan.",
                        "Masyadong lantad para magbomba ng tubig.",
                        "Di ako lalapit sa tubig na 'yan. Bitag 'yan.",
                        "Di makapagpuno. Walang angkop na sisidlan.",
                        "Tinatanggihan ang pagpuno. Maling oras.",
                        "Marumi ang tubig doon. Tumatanggi akong kumuha.",
                        "Harapin muna natin ang banta bago magpuno.",
                        "Di ko malalagyan 'yan sa gitna ng panganib.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.wait_at.active",
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
                                ["fallback"] = "Waiting here now.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.task.wait_at.active.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Waiting here now.",
                                        "Currently holding position and waiting.",
                                        "Standing by at the designated spot.",
                                        "Waiting at this location as ordered.",
                                        "Keeping watch while waiting right here.",
                                        "Holding at the marker.",
                                        "Waiting quietly. Eyes open.",
                                        "In position and waiting.",
                                        "Stationary at the post.",
                                        "Waiting here. Take your time.",
                                    },
                                    ["TL"] = {
                                        "Naghihintay na ako rito ngayon.",
                                        "Kasalukuyang nakapwesto at naghihintay.",
                                        "Nakahanda sa itinalagang pwesto.",
                                        "Naghihintay sa lugar na ito ayon sa utos.",
                                        "Nagbabantay habang naghihintay dito mismo.",
                                        "Hawak ang pwesto sa marka.",
                                        "Naghihintay nang tahimik. Bukas ang mga mata.",
                                        "Nasa pwesto at naghihintay.",
                                        "Nakatigil sa posteng ito.",
                                        "Naghihintay rito. Huwag magmadali.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "task.wait_at",
            ["textRoles"] = {
                {
                    ["fallback"] = "Waiting here now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.task.wait_at.active.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Waiting here now.",
                            "Currently holding position and waiting.",
                            "Standing by at the designated spot.",
                            "Waiting at this location as ordered.",
                            "Keeping watch while waiting right here.",
                            "Holding at the marker.",
                            "Waiting quietly. Eyes open.",
                            "In position and waiting.",
                            "Stationary at the post.",
                            "Waiting here. Take your time.",
                        },
                        ["TL"] = {
                            "Naghihintay na ako rito ngayon.",
                            "Kasalukuyang nakapwesto at naghihintay.",
                            "Nakahanda sa itinalagang pwesto.",
                            "Naghihintay sa lugar na ito ayon sa utos.",
                            "Nagbabantay habang naghihintay dito mismo.",
                            "Hawak ang pwesto sa marka.",
                            "Naghihintay nang tahimik. Bukas ang mga mata.",
                            "Nasa pwesto at naghihintay.",
                            "Nakatigil sa posteng ito.",
                            "Naghihintay rito. Huwag magmadali.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "task.wait_at.active",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "active",
            ["sourceId"] = "task.wait_at.active",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_wait_at_active.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle__b4a76fdc",
        ["namespace"] = "task.wait_at",
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
                ["responseAct"] = "REACT",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/wait_at.json",
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
                                        "Waiting here now.",
                                        "Currently holding position and waiting.",
                                        "Standing by at the designated spot.",
                                        "Waiting at this location as ordered.",
                                        "Keeping watch while waiting right here.",
                                        "Holding at the marker.",
                                        "Waiting quietly. Eyes open.",
                                        "In position and waiting.",
                                        "Stationary at the post.",
                                        "Waiting here. Take your time.",
                                    },
                                    ["TL"] = {
                                        "Naghihintay na ako rito ngayon.",
                                        "Kasalukuyang nakapwesto at naghihintay.",
                                        "Nakahanda sa itinalagang pwesto.",
                                        "Naghihintay sa lugar na ito ayon sa utos.",
                                        "Nagbabantay habang naghihintay dito mismo.",
                                        "Hawak ang pwesto sa marka.",
                                        "Naghihintay nang tahimik. Bukas ang mga mata.",
                                        "Nasa pwesto at naghihintay.",
                                        "Nakatigil sa posteng ito.",
                                        "Naghihintay rito. Huwag magmadali.",
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
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "task.wait_at.active",
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
                            ["fallback"] = "Waiting here now.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.task.wait_at.active.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_wait_at_active.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Waiting here now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.task.wait_at.active.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Waiting here now.",
                        "Currently holding position and waiting.",
                        "Standing by at the designated spot.",
                        "Waiting at this location as ordered.",
                        "Keeping watch while waiting right here.",
                        "Holding at the marker.",
                        "Waiting quietly. Eyes open.",
                        "In position and waiting.",
                        "Stationary at the post.",
                        "Waiting here. Take your time.",
                    },
                    ["TL"] = {
                        "Naghihintay na ako rito ngayon.",
                        "Kasalukuyang nakapwesto at naghihintay.",
                        "Nakahanda sa itinalagang pwesto.",
                        "Naghihintay sa lugar na ito ayon sa utos.",
                        "Nagbabantay habang naghihintay dito mismo.",
                        "Hawak ang pwesto sa marka.",
                        "Naghihintay nang tahimik. Bukas ang mga mata.",
                        "Nasa pwesto at naghihintay.",
                        "Nakatigil sa posteng ito.",
                        "Naghihintay rito. Huwag magmadali.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
