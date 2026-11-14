-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "task.wait_at.admitted",
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
                                ["fallback"] = "Okay, I'll wait there.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.task.wait_at.admitted.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Okay, I'll wait there.",
                                        "Understood. Moving to the waiting spot.",
                                        "I'll go stand by over there.",
                                        "All right, I'll wait at that position.",
                                        "Heading to the waypoint to wait.",
                                        "Understood. I will hold that ground.",
                                        "Right. Setting up to wait there.",
                                        "I'll wait at the assigned marker.",
                                        "Moving to wait as ordered.",
                                        "Sounds good. Going to wait there.",
                                    },
                                    ["TL"] = {
                                        "Sige, maghihintay ako roon.",
                                        "Naintindihan. Papatungo sa pwesto ng paghihintay.",
                                        "Pupunta ako roon para maghintay.",
                                        "Sige, maghihintay ako sa posisyong iyon.",
                                        "Papatungo sa marka para maghintay.",
                                        "Naiintindihan ko. Hahawakan ko ang lupang iyon.",
                                        "Sige. Mag-aayos para maghintay doon.",
                                        "Maghihintay ako sa iniatas na marka.",
                                        "Kikilos para maghintay ayon sa utos.",
                                        "Maganda 'yan. Pupunta para maghintay doon.",
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
                    ["fallback"] = "Okay, I'll wait there.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.task.wait_at.admitted.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Okay, I'll wait there.",
                            "Understood. Moving to the waiting spot.",
                            "I'll go stand by over there.",
                            "All right, I'll wait at that position.",
                            "Heading to the waypoint to wait.",
                            "Understood. I will hold that ground.",
                            "Right. Setting up to wait there.",
                            "I'll wait at the assigned marker.",
                            "Moving to wait as ordered.",
                            "Sounds good. Going to wait there.",
                        },
                        ["TL"] = {
                            "Sige, maghihintay ako roon.",
                            "Naintindihan. Papatungo sa pwesto ng paghihintay.",
                            "Pupunta ako roon para maghintay.",
                            "Sige, maghihintay ako sa posisyong iyon.",
                            "Papatungo sa marka para maghintay.",
                            "Naiintindihan ko. Hahawakan ko ang lupang iyon.",
                            "Sige. Mag-aayos para maghintay doon.",
                            "Maghihintay ako sa iniatas na marka.",
                            "Kikilos para maghintay ayon sa utos.",
                            "Maganda 'yan. Pupunta para maghintay doon.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "task.wait_at.admitted",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "admitted",
            ["sourceId"] = "task.wait_at.admitted",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_wait_at_admitted.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle__2b27b80d",
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
                                        "Okay, I'll wait there.",
                                        "Understood. Moving to the waiting spot.",
                                        "I'll go stand by over there.",
                                        "All right, I'll wait at that position.",
                                        "Heading to the waypoint to wait.",
                                        "Understood. I will hold that ground.",
                                        "Right. Setting up to wait there.",
                                        "I'll wait at the assigned marker.",
                                        "Moving to wait as ordered.",
                                        "Sounds good. Going to wait there.",
                                    },
                                    ["TL"] = {
                                        "Sige, maghihintay ako roon.",
                                        "Naintindihan. Papatungo sa pwesto ng paghihintay.",
                                        "Pupunta ako roon para maghintay.",
                                        "Sige, maghihintay ako sa posisyong iyon.",
                                        "Papatungo sa marka para maghintay.",
                                        "Naiintindihan ko. Hahawakan ko ang lupang iyon.",
                                        "Sige. Mag-aayos para maghintay doon.",
                                        "Maghihintay ako sa iniatas na marka.",
                                        "Kikilos para maghintay ayon sa utos.",
                                        "Maganda 'yan. Pupunta para maghintay doon.",
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
            ["responsePlanID"] = "task.wait_at.admitted",
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
                            ["fallback"] = "Okay, I'll wait there.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.task.wait_at.admitted.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_wait_at_admitted.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Okay, I'll wait there.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.task.wait_at.admitted.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Okay, I'll wait there.",
                        "Understood. Moving to the waiting spot.",
                        "I'll go stand by over there.",
                        "All right, I'll wait at that position.",
                        "Heading to the waypoint to wait.",
                        "Understood. I will hold that ground.",
                        "Right. Setting up to wait there.",
                        "I'll wait at the assigned marker.",
                        "Moving to wait as ordered.",
                        "Sounds good. Going to wait there.",
                    },
                    ["TL"] = {
                        "Sige, maghihintay ako roon.",
                        "Naintindihan. Papatungo sa pwesto ng paghihintay.",
                        "Pupunta ako roon para maghintay.",
                        "Sige, maghihintay ako sa posisyong iyon.",
                        "Papatungo sa marka para maghintay.",
                        "Naiintindihan ko. Hahawakan ko ang lupang iyon.",
                        "Sige. Mag-aayos para maghintay doon.",
                        "Maghihintay ako sa iniatas na marka.",
                        "Kikilos para maghintay ayon sa utos.",
                        "Maganda 'yan. Pupunta para maghintay doon.",
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
            ["familyID"] = "task.wait_at.completed",
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
                                ["fallback"] = "Finished waiting.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.task.wait_at.completed.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Finished waiting.",
                                        "Done waiting. What's the next move?",
                                        "Wait time concluded. Ready for orders.",
                                        "Held the spot. Standing down now.",
                                        "Waiting task complete.",
                                        "Done holding this ground.",
                                        "Time is up. Finished waiting here.",
                                        "Rejoining you. Wait is over.",
                                        "Held the post as long as needed.",
                                        "Completed the wait order.",
                                    },
                                    ["TL"] = {
                                        "Tapos na ang paghihintay.",
                                        "Tapos nang maghintay. Ano ang susunod na galaw?",
                                        "Tapos na ang oras ng paghihintay. Handa sa utos.",
                                        "Nahawakan ang pwesto. Uurong na ngayon.",
                                        "Tapos na ang gawaing maghintay.",
                                        "Tapos na sa paghawak ng lupang ito.",
                                        "Tapos na ang oras. Tapos nang maghintay dito.",
                                        "Sasama muli sa 'yo. Tapos na ang paghihintay.",
                                        "Nabantayan ang poste hangga't kinakailangan.",
                                        "Natapos ang utos na maghintay.",
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
                    ["fallback"] = "Finished waiting.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.task.wait_at.completed.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Finished waiting.",
                            "Done waiting. What's the next move?",
                            "Wait time concluded. Ready for orders.",
                            "Held the spot. Standing down now.",
                            "Waiting task complete.",
                            "Done holding this ground.",
                            "Time is up. Finished waiting here.",
                            "Rejoining you. Wait is over.",
                            "Held the post as long as needed.",
                            "Completed the wait order.",
                        },
                        ["TL"] = {
                            "Tapos na ang paghihintay.",
                            "Tapos nang maghintay. Ano ang susunod na galaw?",
                            "Tapos na ang oras ng paghihintay. Handa sa utos.",
                            "Nahawakan ang pwesto. Uurong na ngayon.",
                            "Tapos na ang gawaing maghintay.",
                            "Tapos na sa paghawak ng lupang ito.",
                            "Tapos na ang oras. Tapos nang maghintay dito.",
                            "Sasama muli sa 'yo. Tapos na ang paghihintay.",
                            "Nabantayan ang poste hangga't kinakailangan.",
                            "Natapos ang utos na maghintay.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "task.wait_at.completed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "completed",
            ["sourceId"] = "task.wait_at.completed",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_wait_at_completed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle__2b27b80d",
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
                                        "Finished waiting.",
                                        "Done waiting. What's the next move?",
                                        "Wait time concluded. Ready for orders.",
                                        "Held the spot. Standing down now.",
                                        "Waiting task complete.",
                                        "Done holding this ground.",
                                        "Time is up. Finished waiting here.",
                                        "Rejoining you. Wait is over.",
                                        "Held the post as long as needed.",
                                        "Completed the wait order.",
                                    },
                                    ["TL"] = {
                                        "Tapos na ang paghihintay.",
                                        "Tapos nang maghintay. Ano ang susunod na galaw?",
                                        "Tapos na ang oras ng paghihintay. Handa sa utos.",
                                        "Nahawakan ang pwesto. Uurong na ngayon.",
                                        "Tapos na ang gawaing maghintay.",
                                        "Tapos na sa paghawak ng lupang ito.",
                                        "Tapos na ang oras. Tapos nang maghintay dito.",
                                        "Sasama muli sa 'yo. Tapos na ang paghihintay.",
                                        "Nabantayan ang poste hangga't kinakailangan.",
                                        "Natapos ang utos na maghintay.",
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
            ["responsePlanID"] = "task.wait_at.completed",
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
                            ["fallback"] = "Finished waiting.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.task.wait_at.completed.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_wait_at_completed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Finished waiting.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.task.wait_at.completed.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Finished waiting.",
                        "Done waiting. What's the next move?",
                        "Wait time concluded. Ready for orders.",
                        "Held the spot. Standing down now.",
                        "Waiting task complete.",
                        "Done holding this ground.",
                        "Time is up. Finished waiting here.",
                        "Rejoining you. Wait is over.",
                        "Held the post as long as needed.",
                        "Completed the wait order.",
                    },
                    ["TL"] = {
                        "Tapos na ang paghihintay.",
                        "Tapos nang maghintay. Ano ang susunod na galaw?",
                        "Tapos na ang oras ng paghihintay. Handa sa utos.",
                        "Nahawakan ang pwesto. Uurong na ngayon.",
                        "Tapos na ang gawaing maghintay.",
                        "Tapos na sa paghawak ng lupang ito.",
                        "Tapos na ang oras. Tapos nang maghintay dito.",
                        "Sasama muli sa 'yo. Tapos na ang paghihintay.",
                        "Nabantayan ang poste hangga't kinakailangan.",
                        "Natapos ang utos na maghintay.",
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
            ["familyID"] = "task.wait_at.failed",
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
                                ["fallback"] = "I couldn't wait there.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.task.wait_at.failed.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I couldn't wait there.",
                                        "Position was overrun. Couldn't keep waiting.",
                                        "Enemies forced me out of the waiting spot.",
                                        "Couldn't reach the designated waiting location.",
                                        "Unable to hold ground there. Too dangerous.",
                                        "Waiting failed. Had to relocate for safety.",
                                        "Aborted waiting. Sector became hostile.",
                                        "I had to abandon the post.",
                                        "Could not remain stationary there.",
                                        "Failed to hold the wait point.",
                                    },
                                    ["TL"] = {
                                        "Hindi ako nakapaghintay roon.",
                                        "Pinamugaran ang pwesto. Di nakapagpatuloy maghintay.",
                                        "Itinaboy ako ng kalaban mula sa pwesto ng paghihintay.",
                                        "Di narating ang itinalagang lugar ng paghihintay.",
                                        "Di mahawakan ang lupa roon. Masyadong mapanganib.",
                                        "Pumalpak ang paghihintay. Kinailangang lumipat para sa kaligtasan.",
                                        "Itinigil ang paghihintay. Naging delikado ang lugar.",
                                        "Kinailangan kong iwan ang poste.",
                                        "Hindi nakapanatiling nakatigil doon.",
                                        "Bigo sa paghawak ng pwesto ng paghihintay.",
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
                    ["fallback"] = "I couldn't wait there.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.task.wait_at.failed.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I couldn't wait there.",
                            "Position was overrun. Couldn't keep waiting.",
                            "Enemies forced me out of the waiting spot.",
                            "Couldn't reach the designated waiting location.",
                            "Unable to hold ground there. Too dangerous.",
                            "Waiting failed. Had to relocate for safety.",
                            "Aborted waiting. Sector became hostile.",
                            "I had to abandon the post.",
                            "Could not remain stationary there.",
                            "Failed to hold the wait point.",
                        },
                        ["TL"] = {
                            "Hindi ako nakapaghintay roon.",
                            "Pinamugaran ang pwesto. Di nakapagpatuloy maghintay.",
                            "Itinaboy ako ng kalaban mula sa pwesto ng paghihintay.",
                            "Di narating ang itinalagang lugar ng paghihintay.",
                            "Di mahawakan ang lupa roon. Masyadong mapanganib.",
                            "Pumalpak ang paghihintay. Kinailangang lumipat para sa kaligtasan.",
                            "Itinigil ang paghihintay. Naging delikado ang lugar.",
                            "Kinailangan kong iwan ang poste.",
                            "Hindi nakapanatiling nakatigil doon.",
                            "Bigo sa paghawak ng pwesto ng paghihintay.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "task.wait_at.failed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "failed",
            ["sourceId"] = "task.wait_at.failed",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_wait_at_failed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle__2b27b80d",
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
                                        "I couldn't wait there.",
                                        "Position was overrun. Couldn't keep waiting.",
                                        "Enemies forced me out of the waiting spot.",
                                        "Couldn't reach the designated waiting location.",
                                        "Unable to hold ground there. Too dangerous.",
                                        "Waiting failed. Had to relocate for safety.",
                                        "Aborted waiting. Sector became hostile.",
                                        "I had to abandon the post.",
                                        "Could not remain stationary there.",
                                        "Failed to hold the wait point.",
                                    },
                                    ["TL"] = {
                                        "Hindi ako nakapaghintay roon.",
                                        "Pinamugaran ang pwesto. Di nakapagpatuloy maghintay.",
                                        "Itinaboy ako ng kalaban mula sa pwesto ng paghihintay.",
                                        "Di narating ang itinalagang lugar ng paghihintay.",
                                        "Di mahawakan ang lupa roon. Masyadong mapanganib.",
                                        "Pumalpak ang paghihintay. Kinailangang lumipat para sa kaligtasan.",
                                        "Itinigil ang paghihintay. Naging delikado ang lugar.",
                                        "Kinailangan kong iwan ang poste.",
                                        "Hindi nakapanatiling nakatigil doon.",
                                        "Bigo sa paghawak ng pwesto ng paghihintay.",
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
            ["responsePlanID"] = "task.wait_at.failed",
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
                            ["fallback"] = "I couldn't wait there.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.task.wait_at.failed.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_wait_at_failed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I couldn't wait there.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.task.wait_at.failed.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I couldn't wait there.",
                        "Position was overrun. Couldn't keep waiting.",
                        "Enemies forced me out of the waiting spot.",
                        "Couldn't reach the designated waiting location.",
                        "Unable to hold ground there. Too dangerous.",
                        "Waiting failed. Had to relocate for safety.",
                        "Aborted waiting. Sector became hostile.",
                        "I had to abandon the post.",
                        "Could not remain stationary there.",
                        "Failed to hold the wait point.",
                    },
                    ["TL"] = {
                        "Hindi ako nakapaghintay roon.",
                        "Pinamugaran ang pwesto. Di nakapagpatuloy maghintay.",
                        "Itinaboy ako ng kalaban mula sa pwesto ng paghihintay.",
                        "Di narating ang itinalagang lugar ng paghihintay.",
                        "Di mahawakan ang lupa roon. Masyadong mapanganib.",
                        "Pumalpak ang paghihintay. Kinailangang lumipat para sa kaligtasan.",
                        "Itinigil ang paghihintay. Naging delikado ang lugar.",
                        "Kinailangan kong iwan ang poste.",
                        "Hindi nakapanatiling nakatigil doon.",
                        "Bigo sa paghawak ng pwesto ng paghihintay.",
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
            ["familyID"] = "task.wait_at.rejected",
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
                                ["fallback"] = "I can't wait there right now.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.task.wait_at.rejected.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I can't wait there right now.",
                                        "That spot is in the line of fire. I won't wait there.",
                                        "Standing out in the open like that is suicide.",
                                        "Refusing to wait in an unsecured position.",
                                        "Too many hostiles nearby to just stand around.",
                                        "I need to stay on the move. Can't wait there.",
                                        "Wait order rejected. Find a safer spot.",
                                        "I won't wait in a compromised sector.",
                                        "Unable to comply. That location has zero cover.",
                                        "I can't wait at that position.",
                                    },
                                    ["TL"] = {
                                        "Hindi ako makapaghintay roon ngayon.",
                                        "Nasa linya ng putukan ang pwestong 'yon. Di ako maghihintay doon.",
                                        "Pagpapakamatay ang tumayo sa bukas na lugar nang ganoon.",
                                        "Tumatangging maghintay sa di-ligtas na posisyon.",
                                        "Masyadong maraming kalaban sa paligid para tumayo-tayo lang.",
                                        "Kailangan kong gumalaw. Di makapaghihintay doon.",
                                        "Tinatanggihan ang paghihintay. Maghanap ng mas ligtas na lugar.",
                                        "Di ako maghihintay sa delikadong lugar.",
                                        "Di makasusunod. Walang silong ang lugar na 'yan.",
                                        "Di ako makapaghihintay sa posisyong 'yon.",
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
                    ["fallback"] = "I can't wait there right now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.task.wait_at.rejected.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I can't wait there right now.",
                            "That spot is in the line of fire. I won't wait there.",
                            "Standing out in the open like that is suicide.",
                            "Refusing to wait in an unsecured position.",
                            "Too many hostiles nearby to just stand around.",
                            "I need to stay on the move. Can't wait there.",
                            "Wait order rejected. Find a safer spot.",
                            "I won't wait in a compromised sector.",
                            "Unable to comply. That location has zero cover.",
                            "I can't wait at that position.",
                        },
                        ["TL"] = {
                            "Hindi ako makapaghintay roon ngayon.",
                            "Nasa linya ng putukan ang pwestong 'yon. Di ako maghihintay doon.",
                            "Pagpapakamatay ang tumayo sa bukas na lugar nang ganoon.",
                            "Tumatangging maghintay sa di-ligtas na posisyon.",
                            "Masyadong maraming kalaban sa paligid para tumayo-tayo lang.",
                            "Kailangan kong gumalaw. Di makapaghihintay doon.",
                            "Tinatanggihan ang paghihintay. Maghanap ng mas ligtas na lugar.",
                            "Di ako maghihintay sa delikadong lugar.",
                            "Di makasusunod. Walang silong ang lugar na 'yan.",
                            "Di ako makapaghihintay sa posisyong 'yon.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "task.wait_at.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "rejected",
            ["sourceId"] = "task.wait_at.rejected",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_wait_at_rejected.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle__2b27b80d",
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
                                        "I can't wait there right now.",
                                        "That spot is in the line of fire. I won't wait there.",
                                        "Standing out in the open like that is suicide.",
                                        "Refusing to wait in an unsecured position.",
                                        "Too many hostiles nearby to just stand around.",
                                        "I need to stay on the move. Can't wait there.",
                                        "Wait order rejected. Find a safer spot.",
                                        "I won't wait in a compromised sector.",
                                        "Unable to comply. That location has zero cover.",
                                        "I can't wait at that position.",
                                    },
                                    ["TL"] = {
                                        "Hindi ako makapaghintay roon ngayon.",
                                        "Nasa linya ng putukan ang pwestong 'yon. Di ako maghihintay doon.",
                                        "Pagpapakamatay ang tumayo sa bukas na lugar nang ganoon.",
                                        "Tumatangging maghintay sa di-ligtas na posisyon.",
                                        "Masyadong maraming kalaban sa paligid para tumayo-tayo lang.",
                                        "Kailangan kong gumalaw. Di makapaghihintay doon.",
                                        "Tinatanggihan ang paghihintay. Maghanap ng mas ligtas na lugar.",
                                        "Di ako maghihintay sa delikadong lugar.",
                                        "Di makasusunod. Walang silong ang lugar na 'yan.",
                                        "Di ako makapaghihintay sa posisyong 'yon.",
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
            ["responsePlanID"] = "task.wait_at.rejected",
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
                            ["fallback"] = "I can't wait there right now.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.task.wait_at.rejected.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_wait_at_rejected.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I can't wait there right now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.task.wait_at.rejected.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I can't wait there right now.",
                        "That spot is in the line of fire. I won't wait there.",
                        "Standing out in the open like that is suicide.",
                        "Refusing to wait in an unsecured position.",
                        "Too many hostiles nearby to just stand around.",
                        "I need to stay on the move. Can't wait there.",
                        "Wait order rejected. Find a safer spot.",
                        "I won't wait in a compromised sector.",
                        "Unable to comply. That location has zero cover.",
                        "I can't wait at that position.",
                    },
                    ["TL"] = {
                        "Hindi ako makapaghintay roon ngayon.",
                        "Nasa linya ng putukan ang pwestong 'yon. Di ako maghihintay doon.",
                        "Pagpapakamatay ang tumayo sa bukas na lugar nang ganoon.",
                        "Tumatangging maghintay sa di-ligtas na posisyon.",
                        "Masyadong maraming kalaban sa paligid para tumayo-tayo lang.",
                        "Kailangan kong gumalaw. Di makapaghihintay doon.",
                        "Tinatanggihan ang paghihintay. Maghanap ng mas ligtas na lugar.",
                        "Di ako maghihintay sa delikadong lugar.",
                        "Di makasusunod. Walang silong ang lugar na 'yan.",
                        "Di ako makapaghihintay sa posisyong 'yon.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
