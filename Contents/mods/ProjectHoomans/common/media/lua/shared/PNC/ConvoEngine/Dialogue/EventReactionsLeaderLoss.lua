-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "event_reactions_leader_loss",
        ["id"] = "semantic.leader_loss.close",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.leader_loss.close",
            ["sourcePath"] = "psdl/dialogue/event_reactions_leader_loss.json#records[0]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsLeaderLoss",
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
                ["responseTemplateID"] = "semantic.leader_loss.close",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/reactions/leader_loss.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "We lost someone close to us. We need to stay together.",
                            },
                            ["TL"] = {
                                "Nawalan tayo ng taong malapit sa atin. Kailangan nating magsama-sama.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I can't believe they're gone... we have to hold each other up.",
                            },
                            ["TL"] = {
                                "Hindi ako makapaniwalang wala na sila... kailangan nating magtulungan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "They were family to us. Don't let our grief break us apart.",
                            },
                            ["TL"] = {
                                "Pamilya na ang turing natin sa kanila. Huwag nating hayaang wasakin tayo ng lungkot.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "It hurts so much, but we have to keep going for them.",
                            },
                            ["TL"] = {
                                "Masakit sobra, pero kailangan nating magpatuloy para sa kanila.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "They protected us. Now we protect each other.",
                            },
                            ["TL"] = {
                                "Pinrotektahan nila tayo. Ngayon tayo naman ang magpoprotekta sa isa't isa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Losing them leaves a hole in my heart. Stay close, everyone.",
                            },
                            ["TL"] = {
                                "Naiwang sugatan ang puso ko sa pagkawala nila. Magdikit-dikit tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "We honor their memory by surviving. Stick together.",
                            },
                            ["TL"] = {
                                "Igalang natin ang alaala nila sa pamamagitan ng pamumuhay. Magsama tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I will miss them terribly. We can't scatter now.",
                            },
                            ["TL"] = {
                                "Mamimiss ko sila nang husto. Hindi tayo dapat maghiwa-hiwalay ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "They gave everything for this group. We stay united.",
                            },
                            ["TL"] = {
                                "Ibinigay nila ang lahat para sa grupong 'to. Manatili tayong nagkakaisa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Rest in peace. We'll hold the line for you.",
                            },
                            ["TL"] = {
                                "Mamahinga ka na. Hahawakan namin ang linya para sa'yo.",
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
        ["sourceShard"] = "psdl/dialogue/event_reactions_leader_loss.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "event_reactions_leader_loss",
        ["id"] = "semantic.leader_loss.colonist",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.leader_loss.colonist",
            ["sourcePath"] = "psdl/dialogue/event_reactions_leader_loss.json#records[1]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsLeaderLoss",
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
                ["responseTemplateID"] = "semantic.leader_loss.colonist",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/reactions/leader_loss.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Our leader is gone. We keep the group together.",
                            },
                            ["TL"] = {
                                "Wala na ang pinuno natin. Panatilihin nating buo ang grupo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "The leader fell, but the colony endures.",
                            },
                            ["TL"] = {
                                "Bumagsak ang pinuno, pero mananatili ang kolonya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "We must maintain order. The group cannot collapse.",
                            },
                            ["TL"] = {
                                "Kailangan nating panatilihin ang kaayusan. Hindi dapat bumagsak ang grupo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Our founder is dead, but our camp will survive.",
                            },
                            ["TL"] = {
                                "Patay na ang nagtatag sa atin, pero mabubuhay ang kampo natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Stay organized. We carry on their work.",
                            },
                            ["TL"] = {
                                "Manatiling organisado. Ipagpatuloy natin ang nasimulan nila.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "A terrible loss, but our community must stand firm.",
                            },
                            ["TL"] = {
                                "Matinding kawalan, pero kailangang tumindig ang komunidad natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Don't panic. We keep rations and duties moving.",
                            },
                            ["TL"] = {
                                "Huwag mag-panic. Tuloy ang rasyon at mga tungkulin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "The colony needs everyone focused right now.",
                            },
                            ["TL"] = {
                                "Kailangan ng kolonya ang pokus ng lahat ngayon din.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "We built this together. We keep it standing together.",
                            },
                            ["TL"] = {
                                "Sabay natin 'tong binuo. Sabay natin 'tong pananatilihing nakatayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Leadership may change, but the settlement survives.",
                            },
                            ["TL"] = {
                                "Maaaring magbago ang pamumuno, pero mabubuhay ang paninirahan.",
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
        ["sourceShard"] = "psdl/dialogue/event_reactions_leader_loss.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "event_reactions_leader_loss",
        ["id"] = "semantic.leader_loss.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.leader_loss.default",
            ["sourcePath"] = "psdl/dialogue/event_reactions_leader_loss.json#records[2]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsLeaderLoss",
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
                ["responseTemplateID"] = "semantic.leader_loss.default",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/reactions/leader_loss.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "We lost our leader. We need to decide what comes next.",
                            },
                            ["TL"] = {
                                "Nawalan tayo ng pinuno. Kailangan nating pagpasyahan ang susunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "The boss is down. Who's taking charge?",
                            },
                            ["TL"] = {
                                "Bagsak ang pinuno. Sino'ng hahawak ng pamumuno?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Without leadership, we need to regroup and plan.",
                            },
                            ["TL"] = {
                                "Kung walang namumuno, kailangan nating magtipon at magplano.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Our leader is dead. What do we do now?",
                            },
                            ["TL"] = {
                                "Patay na ang pinuno natin. Ano'ng gagawin natin ngayon?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "We need to talk about who leads us forward.",
                            },
                            ["TL"] = {
                                "Kailangan nating pag-usapan kung sino ang mangunguna sa atin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "The head is cut off. We need a new direction.",
                            },
                            ["TL"] = {
                                "Naputol ang ulo ng grupo. Kailangan natin ng bagong direksyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Leader's gone. Let's not fall into chaos.",
                            },
                            ["TL"] = {
                                "Wala na ang lider. Huwag tayong mahulog sa kaguluhan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Someone needs to step up and guide the crew.",
                            },
                            ["TL"] = {
                                "May kailangang tumindig at gumabay sa grupo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "We're leaderless right now. Keep calm and talk.",
                            },
                            ["TL"] = {
                                "Wala tayong pinuno ngayon. Kumalma at mag-usap tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Terrible news. Let's figure out our next steps.",
                            },
                            ["TL"] = {
                                "Masamang balita. Pag-isipan natin ang susunod nating hakbang.",
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
        ["sourceShard"] = "psdl/dialogue/event_reactions_leader_loss.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "event_reactions_leader_loss",
        ["id"] = "semantic.leader_loss.devoted",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.leader_loss.devoted",
            ["sourcePath"] = "psdl/dialogue/event_reactions_leader_loss.json#records[3]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsLeaderLoss",
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
                ["responseTemplateID"] = "semantic.leader_loss.devoted",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/reactions/leader_loss.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "We lost someone important. We need to stay together.",
                            },
                            ["TL"] = {
                                "Nawalan tayo ng mahalagang tao. Kailangan nating magsama-sama.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "They were our guiding light. I don't know what to do without them.",
                            },
                            ["TL"] = {
                                "Sila ang tanglaw natin. Hindi ko alam ang gagawin nang wala sila.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I gave my loyalty to them. I feel empty inside.",
                            },
                            ["TL"] = {
                                "Ibinigay ko ang katapatan ko sa kanila. Parang walang laman ang puso ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "They inspired all of us. We must uphold their ideals.",
                            },
                            ["TL"] = {
                                "Binigyan nila tayo ng lakas. Dapat nating itaguyod ang simulain nila.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Our beacon is extinguished. God help us.",
                            },
                            ["TL"] = {
                                "Namatay na ang tanglaw natin. Diyos ko tulungan mo kami.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I would have followed them to the end. Rest well.",
                            },
                            ["TL"] = {
                                "Susundan ko sana sila hanggang dulo. Mamahinga ka na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "They were everything to this cause. We cannot let it die.",
                            },
                            ["TL"] = {
                                "Sila ang lahat para sa layuning 'to. Hindi natin hahayaang mamatay 'to.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "My faith is shaken, but I will stay with our people.",
                            },
                            ["TL"] = {
                                "Nayanig ang pananampalataya ko, pero mananatili ako sa ating mga kasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "A visionary has fallen. We must honor their sacrifice.",
                            },
                            ["TL"] = {
                                "Bumagsak ang ating pinuno. Dapat nating igalang ang sakripisyo nila.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "They believed in us. We have to prove them right.",
                            },
                            ["TL"] = {
                                "Naniwala sila sa atin. Kailangan nating patunayan na tama sila.",
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
        ["sourceShard"] = "psdl/dialogue/event_reactions_leader_loss.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "event_reactions_leader_loss",
        ["id"] = "semantic.leader_loss.dissent",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.leader_loss.dissent",
            ["sourcePath"] = "psdl/dialogue/event_reactions_leader_loss.json#records[4]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsLeaderLoss",
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
                ["responseTemplateID"] = "semantic.leader_loss.dissent",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/reactions/leader_loss.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "The old order is gone. What happens next is up to us.",
                            },
                            ["TL"] = {
                                "Wala na ang dating patakaran. Nasa atin na kung ano ang susunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Their reign is over. Time for a better way.",
                            },
                            ["TL"] = {
                                "Tapos na ang pamumuno nila. Oras na para sa mas maayos na paraan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "They made terrible choices and paid for it.",
                            },
                            ["TL"] = {
                                "Maling desisyon ang ginawa nila at binayaran nila 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "No more taking orders from that fool.",
                            },
                            ["TL"] = {
                                "Wala nang susunod sa mga utos ng hangal na 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "The tyrant is dead. Now we decide our own fate.",
                            },
                            ["TL"] = {
                                "Patay na ang pinuno. Ngayon tayo na ang magpapasya sa sariling kapalaran.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I won't shed tears for them. Let's build something fair.",
                            },
                            ["TL"] = {
                                "Hindi ako iiyak para sa kanila. Magtayo tayo ng makatarungang samahan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Their leadership was leading us to the grave anyway.",
                            },
                            ["TL"] = {
                                "Dadalhin lang din naman tayo ng pamumuno nila sa libingan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "A slate wiped clean. We govern ourselves now.",
                            },
                            ["TL"] = {
                                "Burado na ang nakaraan. Pamahalaan natin ang sarili natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "They're gone. Good riddance to bad orders.",
                            },
                            ["TL"] = {
                                "Wala na sila. Mabuti at tapos na ang maling pamamalakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "We're free to choose our own path now.",
                            },
                            ["TL"] = {
                                "Malaya na tayong pumili ng sarili nating landas.",
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
        ["sourceShard"] = "psdl/dialogue/event_reactions_leader_loss.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "event_reactions_leader_loss",
        ["id"] = "semantic.leader_loss.distant",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.leader_loss.distant",
            ["sourcePath"] = "psdl/dialogue/event_reactions_leader_loss.json#records[5]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsLeaderLoss",
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
                ["responseTemplateID"] = "semantic.leader_loss.distant",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/reactions/leader_loss.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "The leader is gone. Someone needs to decide what comes next.",
                            },
                            ["TL"] = {
                                "Wala na ang pinuno. May kailangang magpasya sa susunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I barely knew them, but we still need structure.",
                            },
                            ["TL"] = {
                                "Halos hindi ko sila kilala, pero kailangan pa rin natin ng kaayusan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Leader died. Life goes on. Who's in charge?",
                            },
                            ["TL"] = {
                                "Namatay ang pinuno. Tuloy ang buhay. Sino'ng mamumuno?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "A casualty like any other. Let's elect someone new.",
                            },
                            ["TL"] = {
                                "Biktima tulad ng iba. Pumili tayo ng bago.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "They're gone. We still need food and guards.",
                            },
                            ["TL"] = {
                                "Wala na sila. Kailangan pa rin natin ng pagkain at bantay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Another name scratched off. Let's sort out the command.",
                            },
                            ["TL"] = {
                                "Isa na namang pangalan ang nabura. Ayusin natin ang pamumuno.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Doesn't change my daily tasks. Who's giving orders now?",
                            },
                            ["TL"] = {
                                "Hindi nababago ang gawain ko. Sino na ang mag-uutos ngayon?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Leader's expired. Pick a replacement and move forward.",
                            },
                            ["TL"] = {
                                "Pumanaw na ang lider. Pumili ng kapalit at magpatuloy.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Death is common here. Let's figure out our routine.",
                            },
                            ["TL"] = {
                                "Pangkaraniwan ang kamatayan dito. Ayusin natin ang patakaran.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "They're dead. What's the practical plan?",
                            },
                            ["TL"] = {
                                "Patay na sila. Ano ang praktikal na plano?",
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
        ["sourceShard"] = "psdl/dialogue/event_reactions_leader_loss.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
