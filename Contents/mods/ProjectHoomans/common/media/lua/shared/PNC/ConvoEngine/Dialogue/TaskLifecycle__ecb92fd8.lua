-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.refill.completed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "completed",
            ["sourceId"] = "semantic.task.refill.completed",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_refill_completed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle__ecb92fd8",
        ["namespace"] = "semantic.task.refill",
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
                ["responseTemplateID"] = "semantic.task.refill.completed",
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
                                "All topped off. Container is full.",
                            },
                            ["TL"] = {
                                "Puno na lahat. Punong-puno ang lalagyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Refill complete. Ready for the road.",
                            },
                            ["TL"] = {
                                "Tapos na ang pagpuno. Handa na sa paglakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Finished refilling with clean water.",
                            },
                            ["TL"] = {
                                "Tapos nang lagyan ng malinis na tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Bottles are full again.",
                            },
                            ["TL"] = {
                                "Puno na muli ang mga bote.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Task done. Plenty of water now.",
                            },
                            ["TL"] = {
                                "Tapos na ang gawain. Marami nang tubig ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Refilled and secured.",
                            },
                            ["TL"] = {
                                "Napuno na at naselyuhan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Canteens are full. Good work.",
                            },
                            ["TL"] = {
                                "Puno na ang mga sisidlan. Magaling.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "All filled up.",
                            },
                            ["TL"] = {
                                "Puno na ang lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Water refilled successfully.",
                            },
                            ["TL"] = {
                                "Matagumpay na nalagyan ng tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Completed refilling the supply.",
                            },
                            ["TL"] = {
                                "Natapos ang pagpuno sa supply.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_refill_completed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.refill.failed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "failed",
            ["sourceId"] = "semantic.task.refill.failed",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_refill_failed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle__ecb92fd8",
        ["namespace"] = "semantic.task.refill",
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
                ["responseTemplateID"] = "semantic.task.refill.failed",
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
                                "I couldn't refill that.",
                            },
                            ["TL"] = {
                                "Hindi ko nalagyan ng laman iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "The water source was dry or cut off.",
                            },
                            ["TL"] = {
                                "Tuyot o putol ang pinagkukunan ng tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Failed to refill. Water was contaminated.",
                            },
                            ["TL"] = {
                                "Bigo sa pagpuno. Kontaminado ang tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I was interrupted while trying to gather water.",
                            },
                            ["TL"] = {
                                "Naabala ako habang sumusubok kumuha ng tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to find a functional water tap.",
                            },
                            ["TL"] = {
                                "Walang makitang gumaganang gripo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Container is damaged or cracked. Refill failed.",
                            },
                            ["TL"] = {
                                "May basag ang lalagyan. Pumalpak ang pagpuno.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Couldn't reach the source safely.",
                            },
                            ["TL"] = {
                                "Di maabot ang pinagkukunan nang ligtas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Hostiles near the water source. Refill aborted.",
                            },
                            ["TL"] = {
                                "May kalaban malapit sa tubig. Itinigil ang pagpuno.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Action failed. Bottle still empty.",
                            },
                            ["TL"] = {
                                "Bigo ang kilos. Walang laman pa rin ang bote.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Could not refill container.",
                            },
                            ["TL"] = {
                                "Hindi napuno ang lalagyan.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_refill_failed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.refill.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "rejected",
            ["sourceId"] = "semantic.task.refill.rejected",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_refill_rejected.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle__ecb92fd8",
        ["namespace"] = "semantic.task.refill",
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
                ["responseTemplateID"] = "semantic.task.refill.rejected",
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
                                "I can't refill that right now.",
                            },
                            ["TL"] = {
                                "Hindi ko malalagyan ng laman iyon ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "There is no known clean water source nearby.",
                            },
                            ["TL"] = {
                                "Walang kilalang malinis na tubig sa malapit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "The container is already completely full.",
                            },
                            ["TL"] = {
                                "Puno na ang lalagyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Too exposed to stand around pumping water.",
                            },
                            ["TL"] = {
                                "Masyadong lantad para magbomba ng tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I won't approach that water source. It's a death trap.",
                            },
                            ["TL"] = {
                                "Di ako lalapit sa tubig na 'yan. Bitag 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Can't refill. No suitable vessel available.",
                            },
                            ["TL"] = {
                                "Di makapagpuno. Walang angkop na sisidlan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Refill order rejected. Bad timing.",
                            },
                            ["TL"] = {
                                "Tinatanggihan ang pagpuno. Maling oras.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Water is tainted there. I refuse to collect it.",
                            },
                            ["TL"] = {
                                "Marumi ang tubig doon. Tumatanggi akong kumuha.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "We need to deal with threats before refilling.",
                            },
                            ["TL"] = {
                                "Harapin muna natin ang banta bago magpuno.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I can't refill that under current danger.",
                            },
                            ["TL"] = {
                                "Di ko malalagyan 'yan sa gitna ng panganib.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_refill_rejected.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.wait_at.active",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "active",
            ["sourceId"] = "semantic.task.wait_at.active",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_wait_at_active.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle__ecb92fd8",
        ["namespace"] = "semantic.task.wait_at",
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
                ["responseTemplateID"] = "semantic.task.wait_at.active",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/wait_at.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Waiting here now.",
                            },
                            ["TL"] = {
                                "Naghihintay na ako rito ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Currently holding position and waiting.",
                            },
                            ["TL"] = {
                                "Kasalukuyang nakapwesto at naghihintay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Standing by at the designated spot.",
                            },
                            ["TL"] = {
                                "Nakahanda sa itinalagang pwesto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Waiting at this location as ordered.",
                            },
                            ["TL"] = {
                                "Naghihintay sa lugar na ito ayon sa utos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Keeping watch while waiting right here.",
                            },
                            ["TL"] = {
                                "Nagbabantay habang naghihintay dito mismo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Holding at the marker.",
                            },
                            ["TL"] = {
                                "Hawak ang pwesto sa marka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Waiting quietly. Eyes open.",
                            },
                            ["TL"] = {
                                "Naghihintay nang tahimik. Bukas ang mga mata.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "In position and waiting.",
                            },
                            ["TL"] = {
                                "Nasa pwesto at naghihintay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Stationary at the post.",
                            },
                            ["TL"] = {
                                "Nakatigil sa posteng ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Waiting here. Take your time.",
                            },
                            ["TL"] = {
                                "Naghihintay rito. Huwag magmadali.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_wait_at_active.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.wait_at.admitted",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "admitted",
            ["sourceId"] = "semantic.task.wait_at.admitted",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_wait_at_admitted.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle__ecb92fd8",
        ["namespace"] = "semantic.task.wait_at",
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
                ["responseTemplateID"] = "semantic.task.wait_at.admitted",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/wait_at.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Okay, I'll wait there.",
                            },
                            ["TL"] = {
                                "Sige, maghihintay ako roon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Moving to the waiting spot.",
                            },
                            ["TL"] = {
                                "Naintindihan. Papatungo sa pwesto ng paghihintay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'll go stand by over there.",
                            },
                            ["TL"] = {
                                "Pupunta ako roon para maghintay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "All right, I'll wait at that position.",
                            },
                            ["TL"] = {
                                "Sige, maghihintay ako sa posisyong iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Heading to the waypoint to wait.",
                            },
                            ["TL"] = {
                                "Papatungo sa marka para maghintay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. I will hold that ground.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Hahawakan ko ang lupang iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Right. Setting up to wait there.",
                            },
                            ["TL"] = {
                                "Sige. Mag-aayos para maghintay doon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'll wait at the assigned marker.",
                            },
                            ["TL"] = {
                                "Maghihintay ako sa iniatas na marka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Moving to wait as ordered.",
                            },
                            ["TL"] = {
                                "Kikilos para maghintay ayon sa utos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Sounds good. Going to wait there.",
                            },
                            ["TL"] = {
                                "Maganda 'yan. Pupunta para maghintay doon.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_wait_at_admitted.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.wait_at.completed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "completed",
            ["sourceId"] = "semantic.task.wait_at.completed",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_wait_at_completed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle__ecb92fd8",
        ["namespace"] = "semantic.task.wait_at",
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
                ["responseTemplateID"] = "semantic.task.wait_at.completed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/wait_at.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Finished waiting.",
                            },
                            ["TL"] = {
                                "Tapos na ang paghihintay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Done waiting. What's the next move?",
                            },
                            ["TL"] = {
                                "Tapos nang maghintay. Ano ang susunod na galaw?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Wait time concluded. Ready for orders.",
                            },
                            ["TL"] = {
                                "Tapos na ang oras ng paghihintay. Handa sa utos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Held the spot. Standing down now.",
                            },
                            ["TL"] = {
                                "Nahawakan ang pwesto. Uurong na ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Waiting task complete.",
                            },
                            ["TL"] = {
                                "Tapos na ang gawaing maghintay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Done holding this ground.",
                            },
                            ["TL"] = {
                                "Tapos na sa paghawak ng lupang ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Time is up. Finished waiting here.",
                            },
                            ["TL"] = {
                                "Tapos na ang oras. Tapos nang maghintay dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Rejoining you. Wait is over.",
                            },
                            ["TL"] = {
                                "Sasama muli sa 'yo. Tapos na ang paghihintay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Held the post as long as needed.",
                            },
                            ["TL"] = {
                                "Nabantayan ang poste hangga't kinakailangan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Completed the wait order.",
                            },
                            ["TL"] = {
                                "Natapos ang utos na maghintay.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_wait_at_completed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.wait_at.failed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "failed",
            ["sourceId"] = "semantic.task.wait_at.failed",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_wait_at_failed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle__ecb92fd8",
        ["namespace"] = "semantic.task.wait_at",
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
                ["responseTemplateID"] = "semantic.task.wait_at.failed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/wait_at.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I couldn't wait there.",
                            },
                            ["TL"] = {
                                "Hindi ako nakapaghintay roon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Position was overrun. Couldn't keep waiting.",
                            },
                            ["TL"] = {
                                "Pinamugaran ang pwesto. Di nakapagpatuloy maghintay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Enemies forced me out of the waiting spot.",
                            },
                            ["TL"] = {
                                "Itinaboy ako ng kalaban mula sa pwesto ng paghihintay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Couldn't reach the designated waiting location.",
                            },
                            ["TL"] = {
                                "Di narating ang itinalagang lugar ng paghihintay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to hold ground there. Too dangerous.",
                            },
                            ["TL"] = {
                                "Di mahawakan ang lupa roon. Masyadong mapanganib.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Waiting failed. Had to relocate for safety.",
                            },
                            ["TL"] = {
                                "Pumalpak ang paghihintay. Kinailangang lumipat para sa kaligtasan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Aborted waiting. Sector became hostile.",
                            },
                            ["TL"] = {
                                "Itinigil ang paghihintay. Naging delikado ang lugar.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I had to abandon the post.",
                            },
                            ["TL"] = {
                                "Kinailangan kong iwan ang poste.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Could not remain stationary there.",
                            },
                            ["TL"] = {
                                "Hindi nakapanatiling nakatigil doon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Failed to hold the wait point.",
                            },
                            ["TL"] = {
                                "Bigo sa paghawak ng pwesto ng paghihintay.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_wait_at_failed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.wait_at.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "rejected",
            ["sourceId"] = "semantic.task.wait_at.rejected",
            ["sourcePath"] = "adopters/hoomans/dialogue/task_lifecycle/task_wait_at_rejected.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/TaskLifecycle__ecb92fd8",
        ["namespace"] = "semantic.task.wait_at",
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
                ["responseTemplateID"] = "semantic.task.wait_at.rejected",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/wait_at.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I can't wait there right now.",
                            },
                            ["TL"] = {
                                "Hindi ako makapaghintay roon ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "That spot is in the line of fire. I won't wait there.",
                            },
                            ["TL"] = {
                                "Nasa linya ng putukan ang pwestong 'yon. Di ako maghihintay doon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Standing out in the open like that is suicide.",
                            },
                            ["TL"] = {
                                "Pagpapakamatay ang tumayo sa bukas na lugar nang ganoon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Refusing to wait in an unsecured position.",
                            },
                            ["TL"] = {
                                "Tumatangging maghintay sa di-ligtas na posisyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Too many hostiles nearby to just stand around.",
                            },
                            ["TL"] = {
                                "Masyadong maraming kalaban sa paligid para tumayo-tayo lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I need to stay on the move. Can't wait there.",
                            },
                            ["TL"] = {
                                "Kailangan kong gumalaw. Di makapaghihintay doon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Wait order rejected. Find a safer spot.",
                            },
                            ["TL"] = {
                                "Tinatanggihan ang paghihintay. Maghanap ng mas ligtas na lugar.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I won't wait in a compromised sector.",
                            },
                            ["TL"] = {
                                "Di ako maghihintay sa delikadong lugar.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to comply. That location has zero cover.",
                            },
                            ["TL"] = {
                                "Di makasusunod. Walang silong ang lugar na 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I can't wait at that position.",
                            },
                            ["TL"] = {
                                "Di ako makapaghihintay sa posisyong 'yon.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/task_lifecycle/task_wait_at_rejected.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
