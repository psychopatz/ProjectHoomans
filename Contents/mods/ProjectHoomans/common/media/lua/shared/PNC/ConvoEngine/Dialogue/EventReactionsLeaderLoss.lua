-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "event_reactions_leader_loss",
        ["exchangeFamily"] = {
            ["familyID"] = "leader_loss.close",
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
                                ["fallback"] = "We lost someone close to us. We need to stay together.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.leader_loss.close.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "We lost someone close to us. We need to stay together.",
                                        "I can't believe they're gone... we have to hold each other up.",
                                        "They were family to us. Don't let our grief break us apart.",
                                        "It hurts so much, but we have to keep going for them.",
                                        "They protected us. Now we protect each other.",
                                        "Losing them leaves a hole in my heart. Stay close, everyone.",
                                        "We honor their memory by surviving. Stick together.",
                                        "I will miss them terribly. We can't scatter now.",
                                        "They gave everything for this group. We stay united.",
                                        "Rest in peace. We'll hold the line for you.",
                                    },
                                    ["TL"] = {
                                        "Nawalan tayo ng taong malapit sa atin. Kailangan nating magsama-sama.",
                                        "Hindi ako makapaniwalang wala na sila... kailangan nating magtulungan.",
                                        "Pamilya na ang turing natin sa kanila. Huwag nating hayaang wasakin tayo ng lungkot.",
                                        "Masakit sobra, pero kailangan nating magpatuloy para sa kanila.",
                                        "Pinrotektahan nila tayo. Ngayon tayo naman ang magpoprotekta sa isa't isa.",
                                        "Naiwang sugatan ang puso ko sa pagkawala nila. Magdikit-dikit tayo.",
                                        "Igalang natin ang alaala nila sa pamamagitan ng pamumuhay. Magsama tayo.",
                                        "Mamimiss ko sila nang husto. Hindi tayo dapat maghiwa-hiwalay ngayon.",
                                        "Ibinigay nila ang lahat para sa grupong 'to. Manatili tayong nagkakaisa.",
                                        "Mamahinga ka na. Hahawakan namin ang linya para sa'yo.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "leader_loss",
            ["textRoles"] = {
                {
                    ["fallback"] = "We lost someone close to us. We need to stay together.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.leader_loss.close.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "We lost someone close to us. We need to stay together.",
                            "I can't believe they're gone... we have to hold each other up.",
                            "They were family to us. Don't let our grief break us apart.",
                            "It hurts so much, but we have to keep going for them.",
                            "They protected us. Now we protect each other.",
                            "Losing them leaves a hole in my heart. Stay close, everyone.",
                            "We honor their memory by surviving. Stick together.",
                            "I will miss them terribly. We can't scatter now.",
                            "They gave everything for this group. We stay united.",
                            "Rest in peace. We'll hold the line for you.",
                        },
                        ["TL"] = {
                            "Nawalan tayo ng taong malapit sa atin. Kailangan nating magsama-sama.",
                            "Hindi ako makapaniwalang wala na sila... kailangan nating magtulungan.",
                            "Pamilya na ang turing natin sa kanila. Huwag nating hayaang wasakin tayo ng lungkot.",
                            "Masakit sobra, pero kailangan nating magpatuloy para sa kanila.",
                            "Pinrotektahan nila tayo. Ngayon tayo naman ang magpoprotekta sa isa't isa.",
                            "Naiwang sugatan ang puso ko sa pagkawala nila. Magdikit-dikit tayo.",
                            "Igalang natin ang alaala nila sa pamamagitan ng pamumuhay. Magsama tayo.",
                            "Mamimiss ko sila nang husto. Hindi tayo dapat maghiwa-hiwalay ngayon.",
                            "Ibinigay nila ang lahat para sa grupong 'to. Manatili tayong nagkakaisa.",
                            "Mamahinga ka na. Hahawakan namin ang linya para sa'yo.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "leader_loss.close",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "close",
            ["sourceId"] = "leader_loss.close",
            ["sourcePath"] = "adopters/hoomans/dialogue/event_reactions_leader_loss/leader_loss_close.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsLeaderLoss",
        ["namespace"] = "leader_loss",
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
                ["category"] = "projecthoomans:event_reactions",
                ["contentOwner"] = "projecthoomans.dialogue_content.events",
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
                                        "We lost someone close to us. We need to stay together.",
                                        "I can't believe they're gone... we have to hold each other up.",
                                        "They were family to us. Don't let our grief break us apart.",
                                        "It hurts so much, but we have to keep going for them.",
                                        "They protected us. Now we protect each other.",
                                        "Losing them leaves a hole in my heart. Stay close, everyone.",
                                        "We honor their memory by surviving. Stick together.",
                                        "I will miss them terribly. We can't scatter now.",
                                        "They gave everything for this group. We stay united.",
                                        "Rest in peace. We'll hold the line for you.",
                                    },
                                    ["TL"] = {
                                        "Nawalan tayo ng taong malapit sa atin. Kailangan nating magsama-sama.",
                                        "Hindi ako makapaniwalang wala na sila... kailangan nating magtulungan.",
                                        "Pamilya na ang turing natin sa kanila. Huwag nating hayaang wasakin tayo ng lungkot.",
                                        "Masakit sobra, pero kailangan nating magpatuloy para sa kanila.",
                                        "Pinrotektahan nila tayo. Ngayon tayo naman ang magpoprotekta sa isa't isa.",
                                        "Naiwang sugatan ang puso ko sa pagkawala nila. Magdikit-dikit tayo.",
                                        "Igalang natin ang alaala nila sa pamamagitan ng pamumuhay. Magsama tayo.",
                                        "Mamimiss ko sila nang husto. Hindi tayo dapat maghiwa-hiwalay ngayon.",
                                        "Ibinigay nila ang lahat para sa grupong 'to. Manatili tayong nagkakaisa.",
                                        "Mamahinga ka na. Hahawakan namin ang linya para sa'yo.",
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
            ["responsePlanID"] = "leader_loss.close",
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
                            ["fallback"] = "We lost someone close to us. We need to stay together.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.leader_loss.close.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/event_reactions_leader_loss/leader_loss_close.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "We lost someone close to us. We need to stay together.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.leader_loss.close.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "We lost someone close to us. We need to stay together.",
                        "I can't believe they're gone... we have to hold each other up.",
                        "They were family to us. Don't let our grief break us apart.",
                        "It hurts so much, but we have to keep going for them.",
                        "They protected us. Now we protect each other.",
                        "Losing them leaves a hole in my heart. Stay close, everyone.",
                        "We honor their memory by surviving. Stick together.",
                        "I will miss them terribly. We can't scatter now.",
                        "They gave everything for this group. We stay united.",
                        "Rest in peace. We'll hold the line for you.",
                    },
                    ["TL"] = {
                        "Nawalan tayo ng taong malapit sa atin. Kailangan nating magsama-sama.",
                        "Hindi ako makapaniwalang wala na sila... kailangan nating magtulungan.",
                        "Pamilya na ang turing natin sa kanila. Huwag nating hayaang wasakin tayo ng lungkot.",
                        "Masakit sobra, pero kailangan nating magpatuloy para sa kanila.",
                        "Pinrotektahan nila tayo. Ngayon tayo naman ang magpoprotekta sa isa't isa.",
                        "Naiwang sugatan ang puso ko sa pagkawala nila. Magdikit-dikit tayo.",
                        "Igalang natin ang alaala nila sa pamamagitan ng pamumuhay. Magsama tayo.",
                        "Mamimiss ko sila nang husto. Hindi tayo dapat maghiwa-hiwalay ngayon.",
                        "Ibinigay nila ang lahat para sa grupong 'to. Manatili tayong nagkakaisa.",
                        "Mamahinga ka na. Hahawakan namin ang linya para sa'yo.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "event_reactions_leader_loss",
        ["exchangeFamily"] = {
            ["familyID"] = "leader_loss.colonist",
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
                                ["fallback"] = "Our leader is gone. We keep the group together.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.leader_loss.colonist.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Our leader is gone. We keep the group together.",
                                        "The leader fell, but the colony endures.",
                                        "We must maintain order. The group cannot collapse.",
                                        "Our founder is dead, but our camp will survive.",
                                        "Stay organized. We carry on their work.",
                                        "A terrible loss, but our community must stand firm.",
                                        "Don't panic. We keep rations and duties moving.",
                                        "The colony needs everyone focused right now.",
                                        "We built this together. We keep it standing together.",
                                        "Leadership may change, but the settlement survives.",
                                    },
                                    ["TL"] = {
                                        "Wala na ang pinuno natin. Panatilihin nating buo ang grupo.",
                                        "Bumagsak ang pinuno, pero mananatili ang kolonya.",
                                        "Kailangan nating panatilihin ang kaayusan. Hindi dapat bumagsak ang grupo.",
                                        "Patay na ang nagtatag sa atin, pero mabubuhay ang kampo natin.",
                                        "Manatiling organisado. Ipagpatuloy natin ang nasimulan nila.",
                                        "Matinding kawalan, pero kailangang tumindig ang komunidad natin.",
                                        "Huwag mag-panic. Tuloy ang rasyon at mga tungkulin.",
                                        "Kailangan ng kolonya ang pokus ng lahat ngayon din.",
                                        "Sabay natin 'tong binuo. Sabay natin 'tong pananatilihing nakatayo.",
                                        "Maaaring magbago ang pamumuno, pero mabubuhay ang paninirahan.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "leader_loss",
            ["textRoles"] = {
                {
                    ["fallback"] = "Our leader is gone. We keep the group together.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.leader_loss.colonist.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Our leader is gone. We keep the group together.",
                            "The leader fell, but the colony endures.",
                            "We must maintain order. The group cannot collapse.",
                            "Our founder is dead, but our camp will survive.",
                            "Stay organized. We carry on their work.",
                            "A terrible loss, but our community must stand firm.",
                            "Don't panic. We keep rations and duties moving.",
                            "The colony needs everyone focused right now.",
                            "We built this together. We keep it standing together.",
                            "Leadership may change, but the settlement survives.",
                        },
                        ["TL"] = {
                            "Wala na ang pinuno natin. Panatilihin nating buo ang grupo.",
                            "Bumagsak ang pinuno, pero mananatili ang kolonya.",
                            "Kailangan nating panatilihin ang kaayusan. Hindi dapat bumagsak ang grupo.",
                            "Patay na ang nagtatag sa atin, pero mabubuhay ang kampo natin.",
                            "Manatiling organisado. Ipagpatuloy natin ang nasimulan nila.",
                            "Matinding kawalan, pero kailangang tumindig ang komunidad natin.",
                            "Huwag mag-panic. Tuloy ang rasyon at mga tungkulin.",
                            "Kailangan ng kolonya ang pokus ng lahat ngayon din.",
                            "Sabay natin 'tong binuo. Sabay natin 'tong pananatilihing nakatayo.",
                            "Maaaring magbago ang pamumuno, pero mabubuhay ang paninirahan.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "leader_loss.colonist",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "colonist",
            ["sourceId"] = "leader_loss.colonist",
            ["sourcePath"] = "adopters/hoomans/dialogue/event_reactions_leader_loss/leader_loss_colonist.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsLeaderLoss",
        ["namespace"] = "leader_loss",
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
                ["category"] = "projecthoomans:event_reactions",
                ["contentOwner"] = "projecthoomans.dialogue_content.events",
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
                                        "Our leader is gone. We keep the group together.",
                                        "The leader fell, but the colony endures.",
                                        "We must maintain order. The group cannot collapse.",
                                        "Our founder is dead, but our camp will survive.",
                                        "Stay organized. We carry on their work.",
                                        "A terrible loss, but our community must stand firm.",
                                        "Don't panic. We keep rations and duties moving.",
                                        "The colony needs everyone focused right now.",
                                        "We built this together. We keep it standing together.",
                                        "Leadership may change, but the settlement survives.",
                                    },
                                    ["TL"] = {
                                        "Wala na ang pinuno natin. Panatilihin nating buo ang grupo.",
                                        "Bumagsak ang pinuno, pero mananatili ang kolonya.",
                                        "Kailangan nating panatilihin ang kaayusan. Hindi dapat bumagsak ang grupo.",
                                        "Patay na ang nagtatag sa atin, pero mabubuhay ang kampo natin.",
                                        "Manatiling organisado. Ipagpatuloy natin ang nasimulan nila.",
                                        "Matinding kawalan, pero kailangang tumindig ang komunidad natin.",
                                        "Huwag mag-panic. Tuloy ang rasyon at mga tungkulin.",
                                        "Kailangan ng kolonya ang pokus ng lahat ngayon din.",
                                        "Sabay natin 'tong binuo. Sabay natin 'tong pananatilihing nakatayo.",
                                        "Maaaring magbago ang pamumuno, pero mabubuhay ang paninirahan.",
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
            ["responsePlanID"] = "leader_loss.colonist",
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
                            ["fallback"] = "Our leader is gone. We keep the group together.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.leader_loss.colonist.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/event_reactions_leader_loss/leader_loss_colonist.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Our leader is gone. We keep the group together.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.leader_loss.colonist.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Our leader is gone. We keep the group together.",
                        "The leader fell, but the colony endures.",
                        "We must maintain order. The group cannot collapse.",
                        "Our founder is dead, but our camp will survive.",
                        "Stay organized. We carry on their work.",
                        "A terrible loss, but our community must stand firm.",
                        "Don't panic. We keep rations and duties moving.",
                        "The colony needs everyone focused right now.",
                        "We built this together. We keep it standing together.",
                        "Leadership may change, but the settlement survives.",
                    },
                    ["TL"] = {
                        "Wala na ang pinuno natin. Panatilihin nating buo ang grupo.",
                        "Bumagsak ang pinuno, pero mananatili ang kolonya.",
                        "Kailangan nating panatilihin ang kaayusan. Hindi dapat bumagsak ang grupo.",
                        "Patay na ang nagtatag sa atin, pero mabubuhay ang kampo natin.",
                        "Manatiling organisado. Ipagpatuloy natin ang nasimulan nila.",
                        "Matinding kawalan, pero kailangang tumindig ang komunidad natin.",
                        "Huwag mag-panic. Tuloy ang rasyon at mga tungkulin.",
                        "Kailangan ng kolonya ang pokus ng lahat ngayon din.",
                        "Sabay natin 'tong binuo. Sabay natin 'tong pananatilihing nakatayo.",
                        "Maaaring magbago ang pamumuno, pero mabubuhay ang paninirahan.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "event_reactions_leader_loss",
        ["exchangeFamily"] = {
            ["familyID"] = "leader_loss.default",
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
                                ["fallback"] = "We lost our leader. We need to decide what comes next.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.leader_loss.default.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "We lost our leader. We need to decide what comes next.",
                                        "The boss is down. Who's taking charge?",
                                        "Without leadership, we need to regroup and plan.",
                                        "Our leader is dead. What do we do now?",
                                        "We need to talk about who leads us forward.",
                                        "The head is cut off. We need a new direction.",
                                        "Leader's gone. Let's not fall into chaos.",
                                        "Someone needs to step up and guide the crew.",
                                        "We're leaderless right now. Keep calm and talk.",
                                        "Terrible news. Let's figure out our next steps.",
                                    },
                                    ["TL"] = {
                                        "Nawalan tayo ng pinuno. Kailangan nating pagpasyahan ang susunod.",
                                        "Bagsak ang pinuno. Sino'ng hahawak ng pamumuno?",
                                        "Kung walang namumuno, kailangan nating magtipon at magplano.",
                                        "Patay na ang pinuno natin. Ano'ng gagawin natin ngayon?",
                                        "Kailangan nating pag-usapan kung sino ang mangunguna sa atin.",
                                        "Naputol ang ulo ng grupo. Kailangan natin ng bagong direksyon.",
                                        "Wala na ang lider. Huwag tayong mahulog sa kaguluhan.",
                                        "May kailangang tumindig at gumabay sa grupo.",
                                        "Wala tayong pinuno ngayon. Kumalma at mag-usap tayo.",
                                        "Masamang balita. Pag-isipan natin ang susunod nating hakbang.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "leader_loss",
            ["textRoles"] = {
                {
                    ["fallback"] = "We lost our leader. We need to decide what comes next.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.leader_loss.default.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "We lost our leader. We need to decide what comes next.",
                            "The boss is down. Who's taking charge?",
                            "Without leadership, we need to regroup and plan.",
                            "Our leader is dead. What do we do now?",
                            "We need to talk about who leads us forward.",
                            "The head is cut off. We need a new direction.",
                            "Leader's gone. Let's not fall into chaos.",
                            "Someone needs to step up and guide the crew.",
                            "We're leaderless right now. Keep calm and talk.",
                            "Terrible news. Let's figure out our next steps.",
                        },
                        ["TL"] = {
                            "Nawalan tayo ng pinuno. Kailangan nating pagpasyahan ang susunod.",
                            "Bagsak ang pinuno. Sino'ng hahawak ng pamumuno?",
                            "Kung walang namumuno, kailangan nating magtipon at magplano.",
                            "Patay na ang pinuno natin. Ano'ng gagawin natin ngayon?",
                            "Kailangan nating pag-usapan kung sino ang mangunguna sa atin.",
                            "Naputol ang ulo ng grupo. Kailangan natin ng bagong direksyon.",
                            "Wala na ang lider. Huwag tayong mahulog sa kaguluhan.",
                            "May kailangang tumindig at gumabay sa grupo.",
                            "Wala tayong pinuno ngayon. Kumalma at mag-usap tayo.",
                            "Masamang balita. Pag-isipan natin ang susunod nating hakbang.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "leader_loss.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "default",
            ["sourceId"] = "leader_loss.default",
            ["sourcePath"] = "adopters/hoomans/dialogue/event_reactions_leader_loss/leader_loss_default.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsLeaderLoss",
        ["namespace"] = "leader_loss",
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
                ["category"] = "projecthoomans:event_reactions",
                ["contentOwner"] = "projecthoomans.dialogue_content.events",
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
                                        "We lost our leader. We need to decide what comes next.",
                                        "The boss is down. Who's taking charge?",
                                        "Without leadership, we need to regroup and plan.",
                                        "Our leader is dead. What do we do now?",
                                        "We need to talk about who leads us forward.",
                                        "The head is cut off. We need a new direction.",
                                        "Leader's gone. Let's not fall into chaos.",
                                        "Someone needs to step up and guide the crew.",
                                        "We're leaderless right now. Keep calm and talk.",
                                        "Terrible news. Let's figure out our next steps.",
                                    },
                                    ["TL"] = {
                                        "Nawalan tayo ng pinuno. Kailangan nating pagpasyahan ang susunod.",
                                        "Bagsak ang pinuno. Sino'ng hahawak ng pamumuno?",
                                        "Kung walang namumuno, kailangan nating magtipon at magplano.",
                                        "Patay na ang pinuno natin. Ano'ng gagawin natin ngayon?",
                                        "Kailangan nating pag-usapan kung sino ang mangunguna sa atin.",
                                        "Naputol ang ulo ng grupo. Kailangan natin ng bagong direksyon.",
                                        "Wala na ang lider. Huwag tayong mahulog sa kaguluhan.",
                                        "May kailangang tumindig at gumabay sa grupo.",
                                        "Wala tayong pinuno ngayon. Kumalma at mag-usap tayo.",
                                        "Masamang balita. Pag-isipan natin ang susunod nating hakbang.",
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
            ["responsePlanID"] = "leader_loss.default",
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
                            ["fallback"] = "We lost our leader. We need to decide what comes next.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.leader_loss.default.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/event_reactions_leader_loss/leader_loss_default.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "We lost our leader. We need to decide what comes next.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.leader_loss.default.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "We lost our leader. We need to decide what comes next.",
                        "The boss is down. Who's taking charge?",
                        "Without leadership, we need to regroup and plan.",
                        "Our leader is dead. What do we do now?",
                        "We need to talk about who leads us forward.",
                        "The head is cut off. We need a new direction.",
                        "Leader's gone. Let's not fall into chaos.",
                        "Someone needs to step up and guide the crew.",
                        "We're leaderless right now. Keep calm and talk.",
                        "Terrible news. Let's figure out our next steps.",
                    },
                    ["TL"] = {
                        "Nawalan tayo ng pinuno. Kailangan nating pagpasyahan ang susunod.",
                        "Bagsak ang pinuno. Sino'ng hahawak ng pamumuno?",
                        "Kung walang namumuno, kailangan nating magtipon at magplano.",
                        "Patay na ang pinuno natin. Ano'ng gagawin natin ngayon?",
                        "Kailangan nating pag-usapan kung sino ang mangunguna sa atin.",
                        "Naputol ang ulo ng grupo. Kailangan natin ng bagong direksyon.",
                        "Wala na ang lider. Huwag tayong mahulog sa kaguluhan.",
                        "May kailangang tumindig at gumabay sa grupo.",
                        "Wala tayong pinuno ngayon. Kumalma at mag-usap tayo.",
                        "Masamang balita. Pag-isipan natin ang susunod nating hakbang.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "event_reactions_leader_loss",
        ["exchangeFamily"] = {
            ["familyID"] = "leader_loss.devoted",
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
                                ["fallback"] = "We lost someone important. We need to stay together.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.leader_loss.devoted.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "We lost someone important. We need to stay together.",
                                        "They were our guiding light. I don't know what to do without them.",
                                        "I gave my loyalty to them. I feel empty inside.",
                                        "They inspired all of us. We must uphold their ideals.",
                                        "Our beacon is extinguished. God help us.",
                                        "I would have followed them to the end. Rest well.",
                                        "They were everything to this cause. We cannot let it die.",
                                        "My faith is shaken, but I will stay with our people.",
                                        "A visionary has fallen. We must honor their sacrifice.",
                                        "They believed in us. We have to prove them right.",
                                    },
                                    ["TL"] = {
                                        "Nawalan tayo ng mahalagang tao. Kailangan nating magsama-sama.",
                                        "Sila ang tanglaw natin. Hindi ko alam ang gagawin nang wala sila.",
                                        "Ibinigay ko ang katapatan ko sa kanila. Parang walang laman ang puso ko.",
                                        "Binigyan nila tayo ng lakas. Dapat nating itaguyod ang simulain nila.",
                                        "Namatay na ang tanglaw natin. Diyos ko tulungan mo kami.",
                                        "Susundan ko sana sila hanggang dulo. Mamahinga ka na.",
                                        "Sila ang lahat para sa layuning 'to. Hindi natin hahayaang mamatay 'to.",
                                        "Nayanig ang pananampalataya ko, pero mananatili ako sa ating mga kasama.",
                                        "Bumagsak ang ating pinuno. Dapat nating igalang ang sakripisyo nila.",
                                        "Naniwala sila sa atin. Kailangan nating patunayan na tama sila.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "leader_loss",
            ["textRoles"] = {
                {
                    ["fallback"] = "We lost someone important. We need to stay together.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.leader_loss.devoted.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "We lost someone important. We need to stay together.",
                            "They were our guiding light. I don't know what to do without them.",
                            "I gave my loyalty to them. I feel empty inside.",
                            "They inspired all of us. We must uphold their ideals.",
                            "Our beacon is extinguished. God help us.",
                            "I would have followed them to the end. Rest well.",
                            "They were everything to this cause. We cannot let it die.",
                            "My faith is shaken, but I will stay with our people.",
                            "A visionary has fallen. We must honor their sacrifice.",
                            "They believed in us. We have to prove them right.",
                        },
                        ["TL"] = {
                            "Nawalan tayo ng mahalagang tao. Kailangan nating magsama-sama.",
                            "Sila ang tanglaw natin. Hindi ko alam ang gagawin nang wala sila.",
                            "Ibinigay ko ang katapatan ko sa kanila. Parang walang laman ang puso ko.",
                            "Binigyan nila tayo ng lakas. Dapat nating itaguyod ang simulain nila.",
                            "Namatay na ang tanglaw natin. Diyos ko tulungan mo kami.",
                            "Susundan ko sana sila hanggang dulo. Mamahinga ka na.",
                            "Sila ang lahat para sa layuning 'to. Hindi natin hahayaang mamatay 'to.",
                            "Nayanig ang pananampalataya ko, pero mananatili ako sa ating mga kasama.",
                            "Bumagsak ang ating pinuno. Dapat nating igalang ang sakripisyo nila.",
                            "Naniwala sila sa atin. Kailangan nating patunayan na tama sila.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "leader_loss.devoted",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "devoted",
            ["sourceId"] = "leader_loss.devoted",
            ["sourcePath"] = "adopters/hoomans/dialogue/event_reactions_leader_loss/leader_loss_devoted.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsLeaderLoss",
        ["namespace"] = "leader_loss",
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
                ["category"] = "projecthoomans:event_reactions",
                ["contentOwner"] = "projecthoomans.dialogue_content.events",
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
                                        "We lost someone important. We need to stay together.",
                                        "They were our guiding light. I don't know what to do without them.",
                                        "I gave my loyalty to them. I feel empty inside.",
                                        "They inspired all of us. We must uphold their ideals.",
                                        "Our beacon is extinguished. God help us.",
                                        "I would have followed them to the end. Rest well.",
                                        "They were everything to this cause. We cannot let it die.",
                                        "My faith is shaken, but I will stay with our people.",
                                        "A visionary has fallen. We must honor their sacrifice.",
                                        "They believed in us. We have to prove them right.",
                                    },
                                    ["TL"] = {
                                        "Nawalan tayo ng mahalagang tao. Kailangan nating magsama-sama.",
                                        "Sila ang tanglaw natin. Hindi ko alam ang gagawin nang wala sila.",
                                        "Ibinigay ko ang katapatan ko sa kanila. Parang walang laman ang puso ko.",
                                        "Binigyan nila tayo ng lakas. Dapat nating itaguyod ang simulain nila.",
                                        "Namatay na ang tanglaw natin. Diyos ko tulungan mo kami.",
                                        "Susundan ko sana sila hanggang dulo. Mamahinga ka na.",
                                        "Sila ang lahat para sa layuning 'to. Hindi natin hahayaang mamatay 'to.",
                                        "Nayanig ang pananampalataya ko, pero mananatili ako sa ating mga kasama.",
                                        "Bumagsak ang ating pinuno. Dapat nating igalang ang sakripisyo nila.",
                                        "Naniwala sila sa atin. Kailangan nating patunayan na tama sila.",
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
            ["responsePlanID"] = "leader_loss.devoted",
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
                            ["fallback"] = "We lost someone important. We need to stay together.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.leader_loss.devoted.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/event_reactions_leader_loss/leader_loss_devoted.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "We lost someone important. We need to stay together.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.leader_loss.devoted.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "We lost someone important. We need to stay together.",
                        "They were our guiding light. I don't know what to do without them.",
                        "I gave my loyalty to them. I feel empty inside.",
                        "They inspired all of us. We must uphold their ideals.",
                        "Our beacon is extinguished. God help us.",
                        "I would have followed them to the end. Rest well.",
                        "They were everything to this cause. We cannot let it die.",
                        "My faith is shaken, but I will stay with our people.",
                        "A visionary has fallen. We must honor their sacrifice.",
                        "They believed in us. We have to prove them right.",
                    },
                    ["TL"] = {
                        "Nawalan tayo ng mahalagang tao. Kailangan nating magsama-sama.",
                        "Sila ang tanglaw natin. Hindi ko alam ang gagawin nang wala sila.",
                        "Ibinigay ko ang katapatan ko sa kanila. Parang walang laman ang puso ko.",
                        "Binigyan nila tayo ng lakas. Dapat nating itaguyod ang simulain nila.",
                        "Namatay na ang tanglaw natin. Diyos ko tulungan mo kami.",
                        "Susundan ko sana sila hanggang dulo. Mamahinga ka na.",
                        "Sila ang lahat para sa layuning 'to. Hindi natin hahayaang mamatay 'to.",
                        "Nayanig ang pananampalataya ko, pero mananatili ako sa ating mga kasama.",
                        "Bumagsak ang ating pinuno. Dapat nating igalang ang sakripisyo nila.",
                        "Naniwala sila sa atin. Kailangan nating patunayan na tama sila.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "event_reactions_leader_loss",
        ["exchangeFamily"] = {
            ["familyID"] = "leader_loss.dissent",
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
                                ["fallback"] = "The old order is gone. What happens next is up to us.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.leader_loss.dissent.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "The old order is gone. What happens next is up to us.",
                                        "Their reign is over. Time for a better way.",
                                        "They made terrible choices and paid for it.",
                                        "No more taking orders from that fool.",
                                        "The tyrant is dead. Now we decide our own fate.",
                                        "I won't shed tears for them. Let's build something fair.",
                                        "Their leadership was leading us to the grave anyway.",
                                        "A slate wiped clean. We govern ourselves now.",
                                        "They're gone. Good riddance to bad orders.",
                                        "We're free to choose our own path now.",
                                    },
                                    ["TL"] = {
                                        "Wala na ang dating patakaran. Nasa atin na kung ano ang susunod.",
                                        "Tapos na ang pamumuno nila. Oras na para sa mas maayos na paraan.",
                                        "Maling desisyon ang ginawa nila at binayaran nila 'yon.",
                                        "Wala nang susunod sa mga utos ng hangal na 'yon.",
                                        "Patay na ang pinuno. Ngayon tayo na ang magpapasya sa sariling kapalaran.",
                                        "Hindi ako iiyak para sa kanila. Magtayo tayo ng makatarungang samahan.",
                                        "Dadalhin lang din naman tayo ng pamumuno nila sa libingan.",
                                        "Burado na ang nakaraan. Pamahalaan natin ang sarili natin.",
                                        "Wala na sila. Mabuti at tapos na ang maling pamamalakad.",
                                        "Malaya na tayong pumili ng sarili nating landas.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "leader_loss",
            ["textRoles"] = {
                {
                    ["fallback"] = "The old order is gone. What happens next is up to us.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.leader_loss.dissent.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "The old order is gone. What happens next is up to us.",
                            "Their reign is over. Time for a better way.",
                            "They made terrible choices and paid for it.",
                            "No more taking orders from that fool.",
                            "The tyrant is dead. Now we decide our own fate.",
                            "I won't shed tears for them. Let's build something fair.",
                            "Their leadership was leading us to the grave anyway.",
                            "A slate wiped clean. We govern ourselves now.",
                            "They're gone. Good riddance to bad orders.",
                            "We're free to choose our own path now.",
                        },
                        ["TL"] = {
                            "Wala na ang dating patakaran. Nasa atin na kung ano ang susunod.",
                            "Tapos na ang pamumuno nila. Oras na para sa mas maayos na paraan.",
                            "Maling desisyon ang ginawa nila at binayaran nila 'yon.",
                            "Wala nang susunod sa mga utos ng hangal na 'yon.",
                            "Patay na ang pinuno. Ngayon tayo na ang magpapasya sa sariling kapalaran.",
                            "Hindi ako iiyak para sa kanila. Magtayo tayo ng makatarungang samahan.",
                            "Dadalhin lang din naman tayo ng pamumuno nila sa libingan.",
                            "Burado na ang nakaraan. Pamahalaan natin ang sarili natin.",
                            "Wala na sila. Mabuti at tapos na ang maling pamamalakad.",
                            "Malaya na tayong pumili ng sarili nating landas.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "leader_loss.dissent",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "dissent",
            ["sourceId"] = "leader_loss.dissent",
            ["sourcePath"] = "adopters/hoomans/dialogue/event_reactions_leader_loss/leader_loss_dissent.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsLeaderLoss",
        ["namespace"] = "leader_loss",
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
                ["category"] = "projecthoomans:event_reactions",
                ["contentOwner"] = "projecthoomans.dialogue_content.events",
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
                                        "The old order is gone. What happens next is up to us.",
                                        "Their reign is over. Time for a better way.",
                                        "They made terrible choices and paid for it.",
                                        "No more taking orders from that fool.",
                                        "The tyrant is dead. Now we decide our own fate.",
                                        "I won't shed tears for them. Let's build something fair.",
                                        "Their leadership was leading us to the grave anyway.",
                                        "A slate wiped clean. We govern ourselves now.",
                                        "They're gone. Good riddance to bad orders.",
                                        "We're free to choose our own path now.",
                                    },
                                    ["TL"] = {
                                        "Wala na ang dating patakaran. Nasa atin na kung ano ang susunod.",
                                        "Tapos na ang pamumuno nila. Oras na para sa mas maayos na paraan.",
                                        "Maling desisyon ang ginawa nila at binayaran nila 'yon.",
                                        "Wala nang susunod sa mga utos ng hangal na 'yon.",
                                        "Patay na ang pinuno. Ngayon tayo na ang magpapasya sa sariling kapalaran.",
                                        "Hindi ako iiyak para sa kanila. Magtayo tayo ng makatarungang samahan.",
                                        "Dadalhin lang din naman tayo ng pamumuno nila sa libingan.",
                                        "Burado na ang nakaraan. Pamahalaan natin ang sarili natin.",
                                        "Wala na sila. Mabuti at tapos na ang maling pamamalakad.",
                                        "Malaya na tayong pumili ng sarili nating landas.",
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
            ["responsePlanID"] = "leader_loss.dissent",
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
                            ["fallback"] = "The old order is gone. What happens next is up to us.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.leader_loss.dissent.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/event_reactions_leader_loss/leader_loss_dissent.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "The old order is gone. What happens next is up to us.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.leader_loss.dissent.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "The old order is gone. What happens next is up to us.",
                        "Their reign is over. Time for a better way.",
                        "They made terrible choices and paid for it.",
                        "No more taking orders from that fool.",
                        "The tyrant is dead. Now we decide our own fate.",
                        "I won't shed tears for them. Let's build something fair.",
                        "Their leadership was leading us to the grave anyway.",
                        "A slate wiped clean. We govern ourselves now.",
                        "They're gone. Good riddance to bad orders.",
                        "We're free to choose our own path now.",
                    },
                    ["TL"] = {
                        "Wala na ang dating patakaran. Nasa atin na kung ano ang susunod.",
                        "Tapos na ang pamumuno nila. Oras na para sa mas maayos na paraan.",
                        "Maling desisyon ang ginawa nila at binayaran nila 'yon.",
                        "Wala nang susunod sa mga utos ng hangal na 'yon.",
                        "Patay na ang pinuno. Ngayon tayo na ang magpapasya sa sariling kapalaran.",
                        "Hindi ako iiyak para sa kanila. Magtayo tayo ng makatarungang samahan.",
                        "Dadalhin lang din naman tayo ng pamumuno nila sa libingan.",
                        "Burado na ang nakaraan. Pamahalaan natin ang sarili natin.",
                        "Wala na sila. Mabuti at tapos na ang maling pamamalakad.",
                        "Malaya na tayong pumili ng sarili nating landas.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "event_reactions_leader_loss",
        ["exchangeFamily"] = {
            ["familyID"] = "leader_loss.distant",
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
                                ["fallback"] = "The leader is gone. Someone needs to decide what comes next.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.leader_loss.distant.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "The leader is gone. Someone needs to decide what comes next.",
                                        "I barely knew them, but we still need structure.",
                                        "Leader died. Life goes on. Who's in charge?",
                                        "A casualty like any other. Let's elect someone new.",
                                        "They're gone. We still need food and guards.",
                                        "Another name scratched off. Let's sort out the command.",
                                        "Doesn't change my daily tasks. Who's giving orders now?",
                                        "Leader's expired. Pick a replacement and move forward.",
                                        "Death is common here. Let's figure out our routine.",
                                        "They're dead. What's the practical plan?",
                                    },
                                    ["TL"] = {
                                        "Wala na ang pinuno. May kailangang magpasya sa susunod.",
                                        "Halos hindi ko sila kilala, pero kailangan pa rin natin ng kaayusan.",
                                        "Namatay ang pinuno. Tuloy ang buhay. Sino'ng mamumuno?",
                                        "Biktima tulad ng iba. Pumili tayo ng bago.",
                                        "Wala na sila. Kailangan pa rin natin ng pagkain at bantay.",
                                        "Isa na namang pangalan ang nabura. Ayusin natin ang pamumuno.",
                                        "Hindi nababago ang gawain ko. Sino na ang mag-uutos ngayon?",
                                        "Pumanaw na ang lider. Pumili ng kapalit at magpatuloy.",
                                        "Pangkaraniwan ang kamatayan dito. Ayusin natin ang patakaran.",
                                        "Patay na sila. Ano ang praktikal na plano?",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "leader_loss",
            ["textRoles"] = {
                {
                    ["fallback"] = "The leader is gone. Someone needs to decide what comes next.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.leader_loss.distant.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "The leader is gone. Someone needs to decide what comes next.",
                            "I barely knew them, but we still need structure.",
                            "Leader died. Life goes on. Who's in charge?",
                            "A casualty like any other. Let's elect someone new.",
                            "They're gone. We still need food and guards.",
                            "Another name scratched off. Let's sort out the command.",
                            "Doesn't change my daily tasks. Who's giving orders now?",
                            "Leader's expired. Pick a replacement and move forward.",
                            "Death is common here. Let's figure out our routine.",
                            "They're dead. What's the practical plan?",
                        },
                        ["TL"] = {
                            "Wala na ang pinuno. May kailangang magpasya sa susunod.",
                            "Halos hindi ko sila kilala, pero kailangan pa rin natin ng kaayusan.",
                            "Namatay ang pinuno. Tuloy ang buhay. Sino'ng mamumuno?",
                            "Biktima tulad ng iba. Pumili tayo ng bago.",
                            "Wala na sila. Kailangan pa rin natin ng pagkain at bantay.",
                            "Isa na namang pangalan ang nabura. Ayusin natin ang pamumuno.",
                            "Hindi nababago ang gawain ko. Sino na ang mag-uutos ngayon?",
                            "Pumanaw na ang lider. Pumili ng kapalit at magpatuloy.",
                            "Pangkaraniwan ang kamatayan dito. Ayusin natin ang patakaran.",
                            "Patay na sila. Ano ang praktikal na plano?",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "leader_loss.distant",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "distant",
            ["sourceId"] = "leader_loss.distant",
            ["sourcePath"] = "adopters/hoomans/dialogue/event_reactions_leader_loss/leader_loss_distant.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsLeaderLoss",
        ["namespace"] = "leader_loss",
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
                ["category"] = "projecthoomans:event_reactions",
                ["contentOwner"] = "projecthoomans.dialogue_content.events",
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
                                        "The leader is gone. Someone needs to decide what comes next.",
                                        "I barely knew them, but we still need structure.",
                                        "Leader died. Life goes on. Who's in charge?",
                                        "A casualty like any other. Let's elect someone new.",
                                        "They're gone. We still need food and guards.",
                                        "Another name scratched off. Let's sort out the command.",
                                        "Doesn't change my daily tasks. Who's giving orders now?",
                                        "Leader's expired. Pick a replacement and move forward.",
                                        "Death is common here. Let's figure out our routine.",
                                        "They're dead. What's the practical plan?",
                                    },
                                    ["TL"] = {
                                        "Wala na ang pinuno. May kailangang magpasya sa susunod.",
                                        "Halos hindi ko sila kilala, pero kailangan pa rin natin ng kaayusan.",
                                        "Namatay ang pinuno. Tuloy ang buhay. Sino'ng mamumuno?",
                                        "Biktima tulad ng iba. Pumili tayo ng bago.",
                                        "Wala na sila. Kailangan pa rin natin ng pagkain at bantay.",
                                        "Isa na namang pangalan ang nabura. Ayusin natin ang pamumuno.",
                                        "Hindi nababago ang gawain ko. Sino na ang mag-uutos ngayon?",
                                        "Pumanaw na ang lider. Pumili ng kapalit at magpatuloy.",
                                        "Pangkaraniwan ang kamatayan dito. Ayusin natin ang patakaran.",
                                        "Patay na sila. Ano ang praktikal na plano?",
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
            ["responsePlanID"] = "leader_loss.distant",
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
                            ["fallback"] = "The leader is gone. Someone needs to decide what comes next.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.leader_loss.distant.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/event_reactions_leader_loss/leader_loss_distant.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "The leader is gone. Someone needs to decide what comes next.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.leader_loss.distant.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "The leader is gone. Someone needs to decide what comes next.",
                        "I barely knew them, but we still need structure.",
                        "Leader died. Life goes on. Who's in charge?",
                        "A casualty like any other. Let's elect someone new.",
                        "They're gone. We still need food and guards.",
                        "Another name scratched off. Let's sort out the command.",
                        "Doesn't change my daily tasks. Who's giving orders now?",
                        "Leader's expired. Pick a replacement and move forward.",
                        "Death is common here. Let's figure out our routine.",
                        "They're dead. What's the practical plan?",
                    },
                    ["TL"] = {
                        "Wala na ang pinuno. May kailangang magpasya sa susunod.",
                        "Halos hindi ko sila kilala, pero kailangan pa rin natin ng kaayusan.",
                        "Namatay ang pinuno. Tuloy ang buhay. Sino'ng mamumuno?",
                        "Biktima tulad ng iba. Pumili tayo ng bago.",
                        "Wala na sila. Kailangan pa rin natin ng pagkain at bantay.",
                        "Isa na namang pangalan ang nabura. Ayusin natin ang pamumuno.",
                        "Hindi nababago ang gawain ko. Sino na ang mag-uutos ngayon?",
                        "Pumanaw na ang lider. Pumili ng kapalit at magpatuloy.",
                        "Pangkaraniwan ang kamatayan dito. Ayusin natin ang patakaran.",
                        "Patay na sila. Ano ang praktikal na plano?",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
