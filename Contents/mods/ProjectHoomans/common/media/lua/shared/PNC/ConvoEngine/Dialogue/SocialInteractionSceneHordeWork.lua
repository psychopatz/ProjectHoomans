-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["id"] = "semantic.interaction.scene.horde_prompt.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "guarded",
            ["sourceId"] = "semantic.interaction.scene.horde_prompt.guarded",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_horde_prompt.json#records[3]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneHordeWork",
        ["namespace"] = "semantic.interaction.scene.horde_prompt",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.scene.horde_prompt",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/horde.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Big group ahead. We decide now: engage or avoid.",
                            },
                            ["TL"] = {
                                "Malaking grupo sa harap. Magpasya tayo ngayon: lumaban o umiwas.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "That horde will tear us apart if we hesitate. What's the move?",
                            },
                            ["TL"] = {
                                "Lalapain tayo ng kawang 'yan kapag nag-atubili tayo. Anong galaw?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Bad odds. We fight with discipline or we slip away right now.",
                            },
                            ["TL"] = {
                                "Masamang tsansa. Lumaban nang may disiplina o tumakas agad ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "I'm not dying here. Decide: cut through or fall back?",
                            },
                            ["TL"] = {
                                "Di ako mamamatay dito. Magpasya ka: basagin o umatras?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Check the numbers. Engage only if we have choke points.",
                            },
                            ["TL"] = {
                                "Tingnan mo ang dami. Lumaban lang kung may masisikipang daan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Horde is closing in. Make a choice before they surround us.",
                            },
                            ["TL"] = {
                                "Palapit na ang kawan. Pumili bago nila tayo mapaligiran.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "We can't afford mistakes against that herd. Stand or withdraw?",
                            },
                            ["TL"] = {
                                "Di tayo pwede magkamali sa kawang 'yan. Lalaban o aatras?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Watch the flanks. Do we fight or get the hell out?",
                            },
                            ["TL"] = {
                                "Bantayan ang tagiliran. Lalaban ba tayo o aalis na agad?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "They'll overwhelm an open position. Call it now.",
                            },
                            ["TL"] = {
                                "Tatalunin nila tayo sa bukas na lugar. Magpasya ka na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Huge pack. If we fight, nobody breaks formation.",
                            },
                            ["TL"] = {
                                "Malaking kawan. Kung lalaban, walang sisira sa pormasyon.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_horde_prompt.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["id"] = "semantic.interaction.scene.horde_prompt.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "neutral",
            ["sourceId"] = "semantic.interaction.scene.horde_prompt.neutral",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_horde_prompt.json#records[0]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneHordeWork",
        ["namespace"] = "semantic.interaction.scene.horde_prompt",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.scene.horde_prompt",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/horde.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "That's a horde. We fighting through or pulling back?",
                            },
                            ["TL"] = {
                                "Kawan iyan. Lalaban ba tayo o uurong?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Look at that crowd. Do we stand our ground or run?",
                            },
                            ["TL"] = {
                                "Tingnan mo ang dami nila. Maninindigan ba tayo o tatakbo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Huge pack ahead. What's the call: fight or retreat?",
                            },
                            ["TL"] = {
                                "Malaking kawan sa unahan. Anong pasya: lalaban o aatras?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "That is a serious horde. Do we engage or bypass?",
                            },
                            ["TL"] = {
                                "Matinding kawan 'yan. Lalabanan ba natin o iiwasan?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "They're swarming. Are we cutting through or falling back?",
                            },
                            ["TL"] = {
                                "Dumudumog sila. Babasagin ba natin o aatras tayo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Too many bodies out there. What do you want to do?",
                            },
                            ["TL"] = {
                                "Napakaraming patay sa labas. Ano ang gusto mong gawin?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Horde spotted. We taking them on or finding another route?",
                            },
                            ["TL"] = {
                                "May kawan sa unahan. Lalabanan ba natin o maghahanap ng ibang daan?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Massive group approaching. Engage or evacuate?",
                            },
                            ["TL"] = {
                                "Napakalaking grupo ang papalapit. Lalaban o lilikas?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "That's a swarm. Give the order: fight or retreat?",
                            },
                            ["TL"] = {
                                "Kawan 'yan. Mag-utos ka: laban o urong?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Look at that numbers disadvantage. Stand or withdraw?",
                            },
                            ["TL"] = {
                                "Tingnan mo ang dami nila laban sa atin. Tatayo o aatras?",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_horde_prompt.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["id"] = "semantic.interaction.scene.horde_prompt.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "terse",
            ["sourceId"] = "semantic.interaction.scene.horde_prompt.terse",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_horde_prompt.json#records[2]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneHordeWork",
        ["namespace"] = "semantic.interaction.scene.horde_prompt",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.scene.horde_prompt",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/horde.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "Horde. Fight or fall back?",
                            },
                            ["TL"] = {
                                "Kawan. Laban o urong?",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Too many. Call it: stand or run?",
                            },
                            ["TL"] = {
                                "Sobra sila. Magpasya: tayo o takbo?",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Swarm ahead. Fight or retreat?",
                            },
                            ["TL"] = {
                                "Kawan sa unahan. Laban o urong?",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Herd. What's the call?",
                            },
                            ["TL"] = {
                                "Kawan. Anong desisyon?",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Massive group. Push or pull?",
                            },
                            ["TL"] = {
                                "Malaking grupo. Sulong o urong?",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Numbers are bad. Engage?",
                            },
                            ["TL"] = {
                                "Masama ang bilang. Lalaban?",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Horde spotted. Decision now.",
                            },
                            ["TL"] = {
                                "Kawan nakita. Desisyon ngayon na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Dozens of them. Stand or flee?",
                            },
                            ["TL"] = {
                                "Dose-dosena sila. Lalaban o tatakas?",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Swarm incoming. Your call.",
                            },
                            ["TL"] = {
                                "Kawan parating. Pasya mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Crowd ahead. Fight or back off?",
                            },
                            ["TL"] = {
                                "Grupo sa harap. Laban o atras?",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_horde_prompt.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["id"] = "semantic.interaction.scene.horde_prompt.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "warm",
            ["sourceId"] = "semantic.interaction.scene.horde_prompt.warm",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_horde_prompt.json#records[1]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneHordeWork",
        ["namespace"] = "semantic.interaction.scene.horde_prompt",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.scene.horde_prompt",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/horde.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "That's a lot of them. Stay close—fight or fall back?",
                            },
                            ["TL"] = {
                                "Ang dami nila. Dumikit ka—lalaban o uurong?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Too many for comfort, friend. What's your gut say: fight or run?",
                            },
                            ["TL"] = {
                                "Masyadong marami para maging panatag, kaibigan. Anong kutob mo: laban o takbo?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Stay right next to me. Do we take them together or get out?",
                            },
                            ["TL"] = {
                                "Manatili ka sa tabi ko. Sabay ba nating lalabanan o aalis tayo?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "That swarm is dangerous. I want us alive—fight or retreat?",
                            },
                            ["TL"] = {
                                "Delikado ang kawang 'yan. Gusto kong mabuhay tayo—laban o urong?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "I'm with you whatever you decide. Are we pushing through or retreating?",
                            },
                            ["TL"] = {
                                "Kasama mo ako kahit anong desisyon mo. Susulong ba tayo o aatras?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Careful, partner. That's a massive pack. Call the play.",
                            },
                            ["TL"] = {
                                "Mag-ingat, kasama. Malaking kawan 'yan. Sabihin mo ang plano.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Look out, friend! Do we clear them or save our strength and run?",
                            },
                            ["TL"] = {
                                "Mag-ingat, kaibigan! Uubusin ba natin sila o magtitipid ng lakas at tatakbo?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "They're everywhere. Stick by me—fight or fall back?",
                            },
                            ["TL"] = {
                                "Nasa lahat sila ng sulok. Dumikit ka—laban o urong?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "I trust your call. Are we taking this swarm on or heading back?",
                            },
                            ["TL"] = {
                                "Tiwala ako sa pasya mo. Lalabanan ba natin ang kawang ito o babalik?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Big herd ahead. Don't worry, we're a team. What's the plan?",
                            },
                            ["TL"] = {
                                "Malaking kawan sa unahan. Huwag kang mag-alala, magkasama tayo. Anong plano?",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_horde_prompt.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["id"] = "semantic.interaction.scene.horde_reply_brave.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "guarded",
            ["sourceId"] = "semantic.interaction.scene.horde_reply_brave.guarded",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_horde_reply_brave.json#records[3]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneHordeWork",
        ["namespace"] = "semantic.interaction.scene.horde_reply_brave",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.scene.horde_reply_brave",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/horde.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "If we commit, we hit hard and stay together.",
                            },
                            ["TL"] = {
                                "Kung lalaban tayo, sabay at todo ang tira.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "No heroics. Funnel them into a choke point and execute.",
                            },
                            ["TL"] = {
                                "Walang magpapakabayani. Ipitin sila sa sikip at tapusin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Watch your stamina. Don't swing wild and get exhausted.",
                            },
                            ["TL"] = {
                                "Bantayan ang lakas. Huwag magwala para di kapusin ng hangin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Keep the line tight. If one falls, we both die.",
                            },
                            ["TL"] = {
                                "Higpitan ang pormasyon. Kapag may bumagsak, patay tayong dalawa.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Target the leaders first. Clear them systematically.",
                            },
                            ["TL"] = {
                                "Unahin ang mga nasa harap. Ubusin nang may sistema.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "We fight, but maintain an escape route behind us.",
                            },
                            ["TL"] = {
                                "Lalaban tayo, pero tiyaking may takasan sa likod natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Every strike must be lethal. No wasted energy.",
                            },
                            ["TL"] = {
                                "Bawat tama dapat nakamamatay. Walang sayang na lakas.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Don't let them surround us. Push when I push.",
                            },
                            ["TL"] = {
                                "Huwag magpapaligid sa kanila. Sumulong kapag sumulong ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "We can win this if we keep cool heads and steady hands.",
                            },
                            ["TL"] = {
                                "Mananalo tayo kung mananatiling malamig ang ulo at matatag ang kamay.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Agreed. Take out the front rank and hold the doorway.",
                            },
                            ["TL"] = {
                                "Sang-ayon. Patumbahin ang unahan at hawakan ang pinto.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_horde_reply_brave.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["id"] = "semantic.interaction.scene.horde_reply_brave.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "neutral",
            ["sourceId"] = "semantic.interaction.scene.horde_reply_brave.neutral",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_horde_reply_brave.json#records[0]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneHordeWork",
        ["namespace"] = "semantic.interaction.scene.horde_reply_brave",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.scene.horde_reply_brave",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/horde.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "We can take them.",
                            },
                            ["TL"] = {
                                "Kaya natin sila.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "We've handled worse. Let's clear them.",
                            },
                            ["TL"] = {
                                "Nakalusot na tayo sa mas malala. Ubusin natin sila.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Stand firm. We fight through.",
                            },
                            ["TL"] = {
                                "Tumayo nang matatag. Lalabanan natin sila.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "We have the weapons. Let's put them down.",
                            },
                            ["TL"] = {
                                "Nasa atin ang armas. Patumbahin natin sila.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Ready up. We're not running from this.",
                            },
                            ["TL"] = {
                                "Humanda ka. Hindi natin tatakbuhan ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "We take the fight to them. Stay sharp.",
                            },
                            ["TL"] = {
                                "Sasalubungin natin sila. Maging alerto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Line them up. We can win this.",
                            },
                            ["TL"] = {
                                "Pilahin sila. Kayang-kaya natin ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "No backing down. We push through.",
                            },
                            ["TL"] = {
                                "Walang atrasan. Babasagin natin 'to.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "We hold here and eliminate the threat.",
                            },
                            ["TL"] = {
                                "Dito tayo tatayo at aalisin ang banta.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I'm ready. Let's make every strike count.",
                            },
                            ["TL"] = {
                                "Handa na ako. Tiyaking may tama ang bawat palo.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_horde_reply_brave.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["id"] = "semantic.interaction.scene.horde_reply_brave.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "terse",
            ["sourceId"] = "semantic.interaction.scene.horde_reply_brave.terse",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_horde_reply_brave.json#records[2]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneHordeWork",
        ["namespace"] = "semantic.interaction.scene.horde_reply_brave",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.scene.horde_reply_brave",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/horde.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "Stand and fight.",
                            },
                            ["TL"] = {
                                "Tumayo at lumaban.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "We take them.",
                            },
                            ["TL"] = {
                                "Kaya natin sila.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "No retreat.",
                            },
                            ["TL"] = {
                                "Walang urungan.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Draw weapons.",
                            },
                            ["TL"] = {
                                "Bunot ng armas.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Kill them all.",
                            },
                            ["TL"] = {
                                "Ubusin sila.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Fight through.",
                            },
                            ["TL"] = {
                                "Lumaban pasulong.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Ready.",
                            },
                            ["TL"] = {
                                "Handa.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Holding ground.",
                            },
                            ["TL"] = {
                                "Hawak ang pwesto.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Let's do this.",
                            },
                            ["TL"] = {
                                "Gawin na natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Bring them on.",
                            },
                            ["TL"] = {
                                "Ilabas sila.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_horde_reply_brave.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["id"] = "semantic.interaction.scene.horde_reply_brave.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "warm",
            ["sourceId"] = "semantic.interaction.scene.horde_reply_brave.warm",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_horde_reply_brave.json#records[1]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneHordeWork",
        ["namespace"] = "semantic.interaction.scene.horde_reply_brave",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.scene.horde_reply_brave",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/horde.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm with you. We can take them.",
                            },
                            ["TL"] = {
                                "Kasama mo ako. Kaya natin sila.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Together, nothing can stop us! Let's do this.",
                            },
                            ["TL"] = {
                                "Kapag magkasama tayo, walang makapipigil sa atin! Tara na.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "I've got your back, friend. We fight as one.",
                            },
                            ["TL"] = {
                                "Hawak ko ang likod mo, kaibigan. Iisang laban tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "We survive together, we fight together. Let's clear them out!",
                            },
                            ["TL"] = {
                                "Sabay tayong nabubuhay, sabay tayong lalaban. Ubusin natin sila!",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "With you beside me, I'm not afraid. Let's take them down.",
                            },
                            ["TL"] = {
                                "Dahil katabi kita, hindi ako natatakot. Patumbahin natin sila.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Let's show them what real survivors are made of!",
                            },
                            ["TL"] = {
                                "Ipakita natin sa kanila kung ano ang tunay na nakaligtas!",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Right by your side, partner. We won't lose today.",
                            },
                            ["TL"] = {
                                "Nasa tabi mo lang ako, kasama. Hindi tayo matatalo ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "I trust us. Let's stand tall and fight.",
                            },
                            ["TL"] = {
                                "Tiwala ako sa atin. Tumindig tayo at lumaban.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "We've got this, friend. Watch my back and I'll watch yours.",
                            },
                            ["TL"] = {
                                "Kayang-kaya natin, kaibigan. Bantayan ang isa't isa.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Stay close and hit hard! We'll celebrate after.",
                            },
                            ["TL"] = {
                                "Manatiling dikit at humampas nang malakas! Magdiriwang tayo mamaya.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_horde_reply_brave.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["id"] = "semantic.interaction.scene.horde_reply_cautious.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "guarded",
            ["sourceId"] = "semantic.interaction.scene.horde_reply_cautious.guarded",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_horde_reply_cautious.json#records[3]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneHordeWork",
        ["namespace"] = "semantic.interaction.scene.horde_reply_cautious",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.scene.horde_reply_cautious",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/horde.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Bad odds. Give them space.",
                            },
                            ["TL"] = {
                                "Masama ang tsansa. Lumayo tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Fighting that pack is suicide. Withdraw in formation.",
                            },
                            ["TL"] = {
                                "Pagpapakamatay ang labanang 'yan. Umatras nang may pormasyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Step back quietly. Do not alert the rear flank.",
                            },
                            ["TL"] = {
                                "Umatras nang tahimik. Huwag gisingin ang nasa likod.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Keep your weapon raised, but reverse your footsteps.",
                            },
                            ["TL"] = {
                                "Itaas ang armas, pero ihakbang pabalik ang paa.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "We have zero tactical advantage. We fall back immediately.",
                            },
                            ["TL"] = {
                                "Wala tayong kalamangan sa posisyon. Aatras tayo agad.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Don't let adrenaline make you stupid. We withdraw.",
                            },
                            ["TL"] = {
                                "Huwag magpadala sa kaba at maging tanga. Aatras tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Back away into the shadows. Let them wander past.",
                            },
                            ["TL"] = {
                                "Umatras sa dilim. Hayaang lumampas sila.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "I refuse to be butchered in an open field. Retreat.",
                            },
                            ["TL"] = {
                                "Ayokong malapa sa bukas na damuhan. Umatras.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Keep low and retreat to the last secure building.",
                            },
                            ["TL"] = {
                                "Yumuko at umatras sa huling ligtas na gusali.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Orderly withdrawal. If anyone runs screaming, they're dead.",
                            },
                            ["TL"] = {
                                "Maayos na pag-atras. Kapag may nagpanic at sumigaw, patay 'yon.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_horde_reply_cautious.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["id"] = "semantic.interaction.scene.horde_reply_cautious.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "neutral",
            ["sourceId"] = "semantic.interaction.scene.horde_reply_cautious.neutral",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_horde_reply_cautious.json#records[0]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneHordeWork",
        ["namespace"] = "semantic.interaction.scene.horde_reply_cautious",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.scene.horde_reply_cautious",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/horde.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Too many. We should pull back.",
                            },
                            ["TL"] = {
                                "Sobra sila. Dapat umatras tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "The odds are terrible. Let's retreat and find another way.",
                            },
                            ["TL"] = {
                                "Napakasama ng tsansa. Umatras tayo at maghanap ng ibang daan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Fighting here is a death sentence. Fall back.",
                            },
                            ["TL"] = {
                                "Kamatayan ang lumaban dito. Umatras na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "We don't have the ammunition or stamina for this. Pull back.",
                            },
                            ["TL"] = {
                                "Kulang tayo sa bala at lakas para rito. Umatras.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Better to live and fight another day. Let's withdraw.",
                            },
                            ["TL"] = {
                                "Mas mabuting mabuhay para lumaban sa ibang araw. Umatras tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "We're completely outmatched. Retreat orderly.",
                            },
                            ["TL"] = {
                                "Lupig tayo sa dami nila. Umatras nang maayos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Back up slowly. Don't make sudden noises.",
                            },
                            ["TL"] = {
                                "Umatras nang dahan-dahan. Huwag gumawa ng ingay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Let's slip away while they haven't locked onto us.",
                            },
                            ["TL"] = {
                                "Tumakas na tayo habang hindi pa sila nakapokus sa atin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Too risky. We need to withdraw immediately.",
                            },
                            ["TL"] = {
                                "Masyadong mapanganib. Kailangan nating umatras agad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I agree with retreating. Turn around and move quietly.",
                            },
                            ["TL"] = {
                                "Sang-ayon akong umatras. Lumingon at lumakad nang tahimik.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_horde_reply_cautious.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["id"] = "semantic.interaction.scene.horde_reply_cautious.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "terse",
            ["sourceId"] = "semantic.interaction.scene.horde_reply_cautious.terse",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_horde_reply_cautious.json#records[2]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneHordeWork",
        ["namespace"] = "semantic.interaction.scene.horde_reply_cautious",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.scene.horde_reply_cautious",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/horde.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "Pull back.",
                            },
                            ["TL"] = {
                                "Umatras.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Too many. Run.",
                            },
                            ["TL"] = {
                                "Sobra sila. Takbo.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Retreat.",
                            },
                            ["TL"] = {
                                "Urong.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Fall back now.",
                            },
                            ["TL"] = {
                                "Atras na ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Bad odds. Leave.",
                            },
                            ["TL"] = {
                                "Masamang tsansa. Alis.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Out. Now.",
                            },
                            ["TL"] = {
                                "Labas. Ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Back up.",
                            },
                            ["TL"] = {
                                "Umatras.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Not here. Move.",
                            },
                            ["TL"] = {
                                "Huwag dito. Kilos.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Escape.",
                            },
                            ["TL"] = {
                                "Takas.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Away.",
                            },
                            ["TL"] = {
                                "Malayo.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_horde_reply_cautious.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["id"] = "semantic.interaction.scene.horde_reply_cautious.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "warm",
            ["sourceId"] = "semantic.interaction.scene.horde_reply_cautious.warm",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_horde_reply_cautious.json#records[1]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneHordeWork",
        ["namespace"] = "semantic.interaction.scene.horde_reply_cautious",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.scene.horde_reply_cautious",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/horde.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'd rather get us out of this alive. Pull back.",
                            },
                            ["TL"] = {
                                "Mas gusto kong makaalis tayong buhay. Umatras tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "I care too much about you to risk this. Let's retreat, friend.",
                            },
                            ["TL"] = {
                                "Masyado kitang pinahahalagahan para isugal ito. Umatras tayo, kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Please, let's fall back together. We don't have to die here.",
                            },
                            ["TL"] = {
                                "Pakiusap, sabay tayong umatras. Di natin kailangang mamatay rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "I need you alive, partner. Turn around, let's go.",
                            },
                            ["TL"] = {
                                "Kailangan kitang buhay, kasama. Lumingon ka, tara na.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Let's save our strength for our people back home. Retreat.",
                            },
                            ["TL"] = {
                                "Itabi natin ang lakas natin para sa kasama sa kampo. Umatras.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Take my hand if you need to, but we have to pull back now.",
                            },
                            ["TL"] = {
                                "Hawakan mo ang kamay ko kung kailangan, pero aatras na tayo ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "There's no shame in living to fight tomorrow. Fall back with me.",
                            },
                            ["TL"] = {
                                "Walang kahihiyan sa pananatiling buhay. Umatras ka kasama ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "Let's back away gently, together. I've got you.",
                            },
                            ["TL"] = {
                                "Umatras tayo nang marahan, nang magkasama. Hawak kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "We can find supplies elsewhere. Let's keep each other safe and run.",
                            },
                            ["TL"] = {
                                "Makakahanap tayo ng gamit sa iba. Manatiling ligtas at tumakbo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "I'm not leaving without you, so let's both back up right now.",
                            },
                            ["TL"] = {
                                "Di ako aalis nang wala ka, kaya umatras tayong pareho ngayon.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_horde_reply_cautious.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["id"] = "semantic.interaction.scene.horde_reply_steady.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "guarded",
            ["sourceId"] = "semantic.interaction.scene.horde_reply_steady.guarded",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_horde_reply_steady.json#records[3]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneHordeWork",
        ["namespace"] = "semantic.interaction.scene.horde_reply_steady",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.scene.horde_reply_steady",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/horde.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "No rush. Hold position and watch the pressure.",
                            },
                            ["TL"] = {
                                "Walang pagmamadali. Humawak at bantayan ang galaw nila.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Hold here. If you twitch, you draw the whole pack.",
                            },
                            ["TL"] = {
                                "Dito muna. Kapag kumilos ka, mahahatak mo ang buong kawan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Stay rooted. Wait until their lead walkers pass.",
                            },
                            ["TL"] = {
                                "Manatiling nakatuntong. Hintaying lumampas ang nauuna.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Maintain silence and hold the corner.",
                            },
                            ["TL"] = {
                                "Panatilihin ang katahimikan at hawakan ang kanto.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Do not engage prematurely. Let the herd scatter.",
                            },
                            ["TL"] = {
                                "Huwag aatake nang maaga. Hayaang maghiwa-hiwalay ang kawan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Hold your breath if you have to, but don't move.",
                            },
                            ["TL"] = {
                                "Pigilin ang hininga kung kailangan, pero huwag gagalaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "We wait for an exploitable mistake. Stay still.",
                            },
                            ["TL"] = {
                                "Hintayin natin ang pagkakamali nila. Huwag gumalaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Keep your weapon ready, but do not fire yet. Hold.",
                            },
                            ["TL"] = {
                                "Ihanda ang armas, pero huwag munang puputok. Hawak.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Hold tight against the wall. Let them walk past.",
                            },
                            ["TL"] = {
                                "Dumikit sa pader. Hayaang maglakad sila palampas.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Steady. Any sound will turn this into a slaughterhouse.",
                            },
                            ["TL"] = {
                                "Dahan-dahan. Anumang ingay ay gagawin itong katayan.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_horde_reply_steady.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["id"] = "semantic.interaction.scene.horde_reply_steady.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "neutral",
            ["sourceId"] = "semantic.interaction.scene.horde_reply_steady.neutral",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_horde_reply_steady.json#records[0]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneHordeWork",
        ["namespace"] = "semantic.interaction.scene.horde_reply_steady",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.scene.horde_reply_steady",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/horde.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Hold here. Don't rush it.",
                            },
                            ["TL"] = {
                                "Dito muna. Huwag padalos-dalos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Wait for them to thin out before making a move.",
                            },
                            ["TL"] = {
                                "Hintaying mabawasan sila bago gumalaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Stay in position. Let's see which way they drift.",
                            },
                            ["TL"] = {
                                "Manatili sa pwesto. Tingnan kung saan sila papunta.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Hold your ground and observe their path.",
                            },
                            ["TL"] = {
                                "Hawakan ang pwesto at bantayan ang ruta nila.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "No sudden movements. Let them pass if possible.",
                            },
                            ["TL"] = {
                                "Walang biglaang galaw. Hayaang lumampas kung maaari.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Keep calm and hold the line right here.",
                            },
                            ["TL"] = {
                                "Kumalma at hawakan ang linya dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Patience. Let's wait for the right opening.",
                            },
                            ["TL"] = {
                                "Pasensya muna. Hintayin ang tamang puwang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Hold steady. We decide when we have better information.",
                            },
                            ["TL"] = {
                                "Maging matatag. Magpapasya tayo kapag mas marami nang impormasyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Don't panic. Hold position behind cover.",
                            },
                            ["TL"] = {
                                "Huwag mag-panic. Manatili sa likod ng kublihan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Steady now. Let's assess before we commit.",
                            },
                            ["TL"] = {
                                "Dahan-dahan lang. Timbangin muna bago sumugod.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_horde_reply_steady.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["id"] = "semantic.interaction.scene.horde_reply_steady.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "terse",
            ["sourceId"] = "semantic.interaction.scene.horde_reply_steady.terse",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_horde_reply_steady.json#records[2]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneHordeWork",
        ["namespace"] = "semantic.interaction.scene.horde_reply_steady",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.scene.horde_reply_steady",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/horde.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "Hold. Watch them.",
                            },
                            ["TL"] = {
                                "Hawak. Bantayan sila.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Hold position.",
                            },
                            ["TL"] = {
                                "Hawakan ang pwesto.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Wait.",
                            },
                            ["TL"] = {
                                "Teka.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Stay low.",
                            },
                            ["TL"] = {
                                "Yumuko.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Steady.",
                            },
                            ["TL"] = {
                                "Magpakatatag.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Do not move.",
                            },
                            ["TL"] = {
                                "Huwag gagalaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Hold.",
                            },
                            ["TL"] = {
                                "Hawak.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Patience.",
                            },
                            ["TL"] = {
                                "Pasensya.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Freeze.",
                            },
                            ["TL"] = {
                                "Tigil.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Quiet. Watch.",
                            },
                            ["TL"] = {
                                "Tahimik. Magmasid.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_horde_reply_steady.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["id"] = "semantic.interaction.scene.horde_reply_steady.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "warm",
            ["sourceId"] = "semantic.interaction.scene.horde_reply_steady.warm",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_horde_reply_steady.json#records[1]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneHordeWork",
        ["namespace"] = "semantic.interaction.scene.horde_reply_steady",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.scene.horde_reply_steady",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/horde.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "Stay together. Let's hold before we commit.",
                            },
                            ["TL"] = {
                                "Magkakasama tayo. Humawak muna bago sumugod.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Breathe easy, friend. We hold right here by each other.",
                            },
                            ["TL"] = {
                                "Huminga ka nang maluwag, kaibigan. Hawak-kamay tayo rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'm right beside you. Let's wait for a safe moment.",
                            },
                            ["TL"] = {
                                "Nasa tabi mo lang ako. Hintayin natin ang ligtas na sandali.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Hold steady, partner. We don't have to rush into danger.",
                            },
                            ["TL"] = {
                                "Magpakatatag ka, kasama. Di natin kailangang magpadalos-dalos.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Stay low with me. Let's watch their movements together.",
                            },
                            ["TL"] = {
                                "Yumuko ka kasabay ko. Sabay nating bantayan ang galaw nila.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Keep calm. As long as we hold together, we'll be fine.",
                            },
                            ["TL"] = {
                                "Manatiling kalmado. Hangga't magkasama tayo, magiging maayos tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Just hold on for a minute. Let the worst of the herd pass.",
                            },
                            ["TL"] = {
                                "Sandali lang. Hayaang lumampas ang pinakamalaking kawan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "Steady, friend. I'm right here with you in the quiet.",
                            },
                            ["TL"] = {
                                "Dahan-dahan, kaibigan. Narito lang ako kasama mo sa katahimikan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Don't be scared. We hold this spot until we have a clean shot.",
                            },
                            ["TL"] = {
                                "Huwag kang matakot. Hawakan ang pwesto hanggang may malinaw na daan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Together and steady. Let's let them drift away.",
                            },
                            ["TL"] = {
                                "Sama-sama at matatag. Hayaan natin silang lumayo.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_horde_reply_steady.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["id"] = "semantic.interaction.scene.post_combat_clear.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "guarded",
            ["sourceId"] = "semantic.interaction.scene.post_combat_clear.guarded",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_post_combat_clear.json#records[3]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneHordeWork",
        ["namespace"] = "semantic.interaction.scene.post_combat_clear",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.scene.post_combat_clear",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/post_combat.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Don't relax yet. Scan for stragglers.",
                            },
                            ["TL"] = {
                                "Huwag munang magpakampante. Maghanap ng mga naiwan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Down, but keep your weapon ready. More could be coming.",
                            },
                            ["TL"] = {
                                "Tumba na, pero ihanda ang armas. Baka may paparating pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Check your perimeter before you start celebrating.",
                            },
                            ["TL"] = {
                                "Suriin ang paligid bago magdiwang.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Check every corpse. Make sure they stay down.",
                            },
                            ["TL"] = {
                                "Tingnan ang bawat bangkay. Tiyaking hindi na gagalaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Gunfire brings more of them. We need to be ready to move.",
                            },
                            ["TL"] = {
                                "Nakahahatak ng iba ang putok. Maging handa tayong umalis.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Wipe your blade and reload immediately.",
                            },
                            ["TL"] = {
                                "Punasan ang talim at magkarga agad ng bala.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Are you bitten? Answer me right now.",
                            },
                            ["TL"] = {
                                "Kinagat ka ba? Sagutin mo ako ngayon din.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Threat is dead, but noise travels fast out here.",
                            },
                            ["TL"] = {
                                "Patay ang banta, pero mabilis kumalat ang ingay dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Keep low. Don't silhouette yourself in the doorway.",
                            },
                            ["TL"] = {
                                "Yumuko ka. Huwag mong i-expose ang sarili mo sa pinto.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Clear for now. Expect a second wave.",
                            },
                            ["TL"] = {
                                "Malinis sa ngayon. Maghanda sa pangalawang bugso.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_post_combat_clear.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["id"] = "semantic.interaction.scene.post_combat_clear.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "neutral",
            ["sourceId"] = "semantic.interaction.scene.post_combat_clear.neutral",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_post_combat_clear.json#records[0]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneHordeWork",
        ["namespace"] = "semantic.interaction.scene.post_combat_clear",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.scene.post_combat_clear",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/post_combat.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Looks clear now. That got rough for a minute.",
                            },
                            ["TL"] = {
                                "Mukhang malinaw na. Naging delikado sandali.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Area is secure. Check yourselves for injuries.",
                            },
                            ["TL"] = {
                                "Ligtas na ang lugar. Tingnan niyo kung may mga sugat kayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "They're all down. Take a breath and reload.",
                            },
                            ["TL"] = {
                                "Tumba na silang lahat. Huminga at magkarga ng bala.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Fight's over. Good work holding the line.",
                            },
                            ["TL"] = {
                                "Tapos na ang laban. Magandang pagpigil sa linya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Looks like the immediate threat is dealt with.",
                            },
                            ["TL"] = {
                                "Mukhang naasikaso na ang agarang banta.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Clear. Everyone still in one piece?",
                            },
                            ["TL"] = {
                                "Malinaw. Buo pa ba ang lahat?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Threat neutralized. Let's recover our stamina.",
                            },
                            ["TL"] = {
                                "Nalipol ang banta. Bawiin natin ang lakas natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "It's quiet again. Stay alert for stragglers.",
                            },
                            ["TL"] = {
                                "Tahimik na ulit. Magbantay sa mga naiwan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Combat is finished. Reload and bandage up.",
                            },
                            ["TL"] = {
                                "Tapos na ang bakbakan. Magkarga at magbenda.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "We held them off. Area appears clear.",
                            },
                            ["TL"] = {
                                "Naitaboy natin sila. Mukhang malinis na ang lugar.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_post_combat_clear.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["id"] = "semantic.interaction.scene.post_combat_clear.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "terse",
            ["sourceId"] = "semantic.interaction.scene.post_combat_clear.terse",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_post_combat_clear.json#records[2]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneHordeWork",
        ["namespace"] = "semantic.interaction.scene.post_combat_clear",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.scene.post_combat_clear",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/post_combat.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "Clear.",
                            },
                            ["TL"] = {
                                "Malinaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "All down.",
                            },
                            ["TL"] = {
                                "Tumba lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Reload.",
                            },
                            ["TL"] = {
                                "Magkarga.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Check wounds.",
                            },
                            ["TL"] = {
                                "Tingnan ang sugat.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Secure.",
                            },
                            ["TL"] = {
                                "Ligtas.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Done.",
                            },
                            ["TL"] = {
                                "Tapos.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Quiet now.",
                            },
                            ["TL"] = {
                                "Tahimik na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Hold positions.",
                            },
                            ["TL"] = {
                                "Manatili sa pwesto.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Breathe.",
                            },
                            ["TL"] = {
                                "Huminga.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Threat gone.",
                            },
                            ["TL"] = {
                                "Wala nang banta.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_post_combat_clear.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["id"] = "semantic.interaction.scene.post_combat_clear.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "warm",
            ["sourceId"] = "semantic.interaction.scene.post_combat_clear.warm",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_post_combat_clear.json#records[1]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneHordeWork",
        ["namespace"] = "semantic.interaction.scene.post_combat_clear",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.scene.post_combat_clear",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/post_combat.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "We made it through! Is everyone okay?",
                            },
                            ["TL"] = {
                                "Nakalusot tayo! Ayos lang ba ang lahat?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Thank goodness you're alive. That was terrifying.",
                            },
                            ["TL"] = {
                                "Salamat sa Diyos at buhay ka. Napakatindi noon.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Great fighting, partner! I'm so glad we survived that.",
                            },
                            ["TL"] = {
                                "Napakagaling mong lumaban, kasama! Masayang-masaya ako't nakaligtas tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Come here, let me check you over for bites or scratches.",
                            },
                            ["TL"] = {
                                "Halika rito, titingnan ko kung may kagat o gasgas ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "We did it together. Nobody got left behind.",
                            },
                            ["TL"] = {
                                "Nagawa natin nang magkasama. Walang naiwan sa atin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Take a breath, friend. We held the line.",
                            },
                            ["TL"] = {
                                "Huminga ka muna, kaibigan. Naipagtanggol natin ang pwesto.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "I was worried for a second there, but you fought bravely.",
                            },
                            ["TL"] = {
                                "Nag-alala ako nang sandali, pero buong tapang kang lumaban.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "Proud to stand beside you in that fight. We're safe now.",
                            },
                            ["TL"] = {
                                "Ipinagmamalaki kong tumabi sa 'yo sa laban. Ligtas na tayo ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Rest for a minute. You earned it after that mess.",
                            },
                            ["TL"] = {
                                "Magpahinga ka muna. Karapat-dapat ka roon pagkatapos ng gulo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "All clear! Hugely relieved we're both standing.",
                            },
                            ["TL"] = {
                                "Malinis na! Napakalaking ginhawa na nakatayo pa tayong pareho.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_post_combat_clear.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["id"] = "semantic.interaction.scene.task_work_assigned.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "guarded",
            ["sourceId"] = "semantic.interaction.scene.task_work_assigned.guarded",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_task_work_assigned.json#records[3]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneHordeWork",
        ["namespace"] = "semantic.interaction.scene.task_work_assigned",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.scene.task_work_assigned",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/work.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'll do the work. Watch my back while I do.",
                            },
                            ["TL"] = {
                                "Gagawin ko ang trabaho. Bantayan mo ang likod ko habang ginagawa.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "I'll handle it, but keep an eye on our surroundings.",
                            },
                            ["TL"] = {
                                "Ako na ang bahala, pero magmasid ka sa paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Don't crowd me while I'm working.",
                            },
                            ["TL"] = {
                                "Naintindihan. Huwag mo akong dikitan habang nagtatrabaho.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "I'll do my share. Make sure you do yours.",
                            },
                            ["TL"] = {
                                "Gagawin ko ang bahagi ko. Tiyakin mong gagawin mo ang sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Getting on it. Stay alert for threats.",
                            },
                            ["TL"] = {
                                "Sisimulan na. Manatiling alisto sa mga banta.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'll get it done. Just make sure the perimeter is secure.",
                            },
                            ["TL"] = {
                                "Matatapos ko ito. Tiyakin mo lang na ligtas ang paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Task noted. I'll finish it without distraction.",
                            },
                            ["TL"] = {
                                "Tala ang gawain. Tatapusin ko nang walang abala.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Fine. I'll see to the task.",
                            },
                            ["TL"] = {
                                "Sige. Aasikasuhin ko ang gawain.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'll handle this. Keep your weapon ready.",
                            },
                            ["TL"] = {
                                "Hahawakan ko ito. Ihanda mo ang armas mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Don't let anything sneak up on me.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Huwag kang magpapapasok ng kahit ano sa likod ko.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_task_work_assigned.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["id"] = "semantic.interaction.scene.task_work_assigned.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "neutral",
            ["sourceId"] = "semantic.interaction.scene.task_work_assigned.neutral",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_task_work_assigned.json#records[0]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneHordeWork",
        ["namespace"] = "semantic.interaction.scene.task_work_assigned",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.scene.task_work_assigned",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/work.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I've got work to do. I'll get on it.",
                            },
                            ["TL"] = {
                                "May trabaho akong gagawin. Aasikasuhin ko na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Starting on the task now.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Sisimulan ko na ang gawain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Task received. I'll take care of this.",
                            },
                            ["TL"] = {
                                "Natanggap ang utos. Ako na ang bahala rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Right. Getting down to business.",
                            },
                            ["TL"] = {
                                "Sige. Sisimulan na ang trabaho.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I'm on it. Shouldn't take too long.",
                            },
                            ["TL"] = {
                                "Inaasikaso ko na. Hindi magtatagal ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. I will handle this duty.",
                            },
                            ["TL"] = {
                                "Naintindihan. Hahawakan ko ang tungkuling ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Got my assignment. Moving out to work.",
                            },
                            ["TL"] = {
                                "Nakuha ko ang atas ko. Kikilos na para magtrabaho.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Fair enough. Time to get my hands dirty.",
                            },
                            ["TL"] = {
                                "Makatwiran. Oras na para magbanat ng buto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'll see that this gets done properly.",
                            },
                            ["TL"] = {
                                "Titiyakin kong matatapos ito nang maayos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Acknowledged. Working on the assigned job.",
                            },
                            ["TL"] = {
                                "Kinikilala ko. Gagawin na ang iniatas na trabaho.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_task_work_assigned.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["id"] = "semantic.interaction.scene.task_work_assigned.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "terse",
            ["sourceId"] = "semantic.interaction.scene.task_work_assigned.terse",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_task_work_assigned.json#records[2]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneHordeWork",
        ["namespace"] = "semantic.interaction.scene.task_work_assigned",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.scene.task_work_assigned",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/work.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "On it.",
                            },
                            ["TL"] = {
                                "Inaasikaso na.",
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
                                "Nagtatrabaho na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Understood.",
                            },
                            ["TL"] = {
                                "Naintindihan.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Doing it.",
                            },
                            ["TL"] = {
                                "Ginagawa na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Got it.",
                            },
                            ["TL"] = {
                                "Nakuha ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Assigned.",
                            },
                            ["TL"] = {
                                "Iniatas.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Starting.",
                            },
                            ["TL"] = {
                                "Nagsisimula na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Handling it.",
                            },
                            ["TL"] = {
                                "Hinahawakan na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Right.",
                            },
                            ["TL"] = {
                                "Sige.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Moving.",
                            },
                            ["TL"] = {
                                "Kumikilos na.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_task_work_assigned.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["id"] = "semantic.interaction.scene.task_work_assigned.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "warm",
            ["sourceId"] = "semantic.interaction.scene.task_work_assigned.warm",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_task_work_assigned.json#records[1]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneHordeWork",
        ["namespace"] = "semantic.interaction.scene.task_work_assigned",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.scene.task_work_assigned",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/work.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "Happy to help with this! I'll get right on it.",
                            },
                            ["TL"] = {
                                "Masayang tumulong dito! Aasikasuhin ko agad.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Leave it to me, friend. I'll make sure it's done right.",
                            },
                            ["TL"] = {
                                "Ipaubaya mo sa akin, kaibigan. Titiyakin kong maayos ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Glad to contribute to our camp. Heading over now.",
                            },
                            ["TL"] = {
                                "Masayang makapag-ambag sa kampo natin. Pupunta na ako roon.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "You can count on me. I'll take good care of it.",
                            },
                            ["TL"] = {
                                "Makaaasa ka sa akin. Aalagaan ko itong mabuti.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "On it! Always happy to do my part for the team.",
                            },
                            ["TL"] = {
                                "Aasikasuhin na! Laging masayang gawin ang bahagi ko para sa grupo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Consider it handled, partner. Be back soon.",
                            },
                            ["TL"] = {
                                "Ituring mong ayos na, kasama. Babalik ako agad.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Happy to take this off your hands. Working on it now.",
                            },
                            ["TL"] = {
                                "Masayang alisin ang bigat na 'to sa 'yo. Gagawin ko na ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'll pour my best effort into this for all of us.",
                            },
                            ["TL"] = {
                                "Ibubuhos ko ang buong makakaya ko para sa ating lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Got the task! Thanks for trusting me with it.",
                            },
                            ["TL"] = {
                                "Nakuha ko ang atas! Salamat sa pagtitiwala sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Right away, friend! Let's keep our home running.",
                            },
                            ["TL"] = {
                                "Agad-agad, kaibigan! Panatilihin nating maayos ang tirahan natin.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_task_work_assigned.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["id"] = "semantic.interaction.scene.task_work_completed.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "guarded",
            ["sourceId"] = "semantic.interaction.scene.task_work_completed.guarded",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_task_work_completed.json#records[3]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneHordeWork",
        ["namespace"] = "semantic.interaction.scene.task_work_completed",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.scene.task_work_completed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/work.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Task is done. I'm taking a breather.",
                            },
                            ["TL"] = {
                                "Tapos na ang gawain. Magpapahinga muna ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Finished. Inspect it if you want to be sure.",
                            },
                            ["TL"] = {
                                "Tapos na. Suriin mo kung nais mong makatiyak.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "It's completed. Now keep your eyes open.",
                            },
                            ["TL"] = {
                                "Tapos na ito. Ngayon buksan mo ang mga mata mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "That job is handled. Back to guarding the perimeter.",
                            },
                            ["TL"] = {
                                "Naasikaso na ang trabaho. Balik sa pagbabantay ng paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Finished my duty. Nobody snuck up on us, right?",
                            },
                            ["TL"] = {
                                "Tapos na ang tungkulin ko. Walang nakalapit sa atin, di ba?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Done. Let's make sure it wasn't for nothing.",
                            },
                            ["TL"] = {
                                "Tapos na. Tiyakin nating hindi nasayang ang pagod.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Work is complete. Back on defensive watch.",
                            },
                            ["TL"] = {
                                "Tapos na ang trabaho. Balik sa pagbabantay.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "It's finished. Keep quiet and stay alert.",
                            },
                            ["TL"] = {
                                "Tapos na. Manatiling tahimik at alisto.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Task completed. Don't waste the resources I secured.",
                            },
                            ["TL"] = {
                                "Gawain natapos. Huwag mong sayangin ang naasikaso ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Done. What's the next threat we need to manage?",
                            },
                            ["TL"] = {
                                "Tapos na. Ano ang susunod na banta na dapat harapin?",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_task_work_completed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["id"] = "semantic.interaction.scene.task_work_completed.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "neutral",
            ["sourceId"] = "semantic.interaction.scene.task_work_completed.neutral",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_task_work_completed.json#records[0]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneHordeWork",
        ["namespace"] = "semantic.interaction.scene.task_work_completed",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.scene.task_work_completed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/work.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "That's done. One less thing to worry about.",
                            },
                            ["TL"] = {
                                "Tapos na. Isang alalahanin ang nabawas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Finished the task. All wrapped up.",
                            },
                            ["TL"] = {
                                "Tapos na ang gawain. Ayos na ang lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Job is complete. What's next?",
                            },
                            ["TL"] = {
                                "Tapos na ang trabaho. Ano ang susunod?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "That takes care of that assignment.",
                            },
                            ["TL"] = {
                                "Naasikaso na ang tungkuling iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "All done here. Everything looks in order.",
                            },
                            ["TL"] = {
                                "Tapos na ang lahat dito. Maayos ang kalagayan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Task is completed to the best of my ability.",
                            },
                            ["TL"] = {
                                "Natapos ang gawain sa abot ng aking makakaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Wrapped that up. Ready for the next priority.",
                            },
                            ["TL"] = {
                                "Tapos na iyon. Handa na para sa susunod na prayoridad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Done. That should hold up fine.",
                            },
                            ["TL"] = {
                                "Tapos na. Maayos ang magiging tibay niyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "The work is finished. Moving on.",
                            },
                            ["TL"] = {
                                "Tapos na ang trabaho. Magpatuloy na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Completed. Duty handled.",
                            },
                            ["TL"] = {
                                "Kumpleto na. Naasikaso ang tungkulin.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_task_work_completed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["id"] = "semantic.interaction.scene.task_work_completed.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "terse",
            ["sourceId"] = "semantic.interaction.scene.task_work_completed.terse",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_task_work_completed.json#records[2]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneHordeWork",
        ["namespace"] = "semantic.interaction.scene.task_work_completed",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.scene.task_work_completed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/work.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "Done.",
                            },
                            ["TL"] = {
                                "Tapos na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Finished.",
                            },
                            ["TL"] = {
                                "Tapos.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Completed.",
                            },
                            ["TL"] = {
                                "Kumpleto.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Handled.",
                            },
                            ["TL"] = {
                                "Naasikaso na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Sorted.",
                            },
                            ["TL"] = {
                                "Ayos na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "All set.",
                            },
                            ["TL"] = {
                                "Handa na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Wrapped up.",
                            },
                            ["TL"] = {
                                "Tapos na lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Next?",
                            },
                            ["TL"] = {
                                "Susunod?",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Cleared.",
                            },
                            ["TL"] = {
                                "Malinaw na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Ready.",
                            },
                            ["TL"] = {
                                "Handa na.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_task_work_completed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["id"] = "semantic.interaction.scene.task_work_completed.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "warm",
            ["sourceId"] = "semantic.interaction.scene.task_work_completed.warm",
            ["sourcePath"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_task_work_completed.json#records[1]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/SocialInteractionSceneHordeWork",
        ["namespace"] = "semantic.interaction.scene.task_work_completed",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.scene.task_work_completed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/work.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "All finished! Glad I could help get this done.",
                            },
                            ["TL"] = {
                                "Tapos na ang lahat! Mabuti at nakatulong akong tapusin ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "That's taken care of, friend. Turned out great!",
                            },
                            ["TL"] = {
                                "Naasikaso na 'yon, kaibigan. Naging napakaganda ng resulta!",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Proud to have this knocked out for the camp.",
                            },
                            ["TL"] = {
                                "Ipinagmamalaki kong natapos ito para sa kampo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Finished! We're making our home a little better every day.",
                            },
                            ["TL"] = {
                                "Tapos na! Pinapaganda natin ang tirahan natin araw-araw.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Done and dusted! Let me know if you need another hand.",
                            },
                            ["TL"] = {
                                "Tapos at malinis na! Sabihan mo lang ako kung kailangan mo pa ng tulong.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Completed with care. Hope it meets your expectations, partner.",
                            },
                            ["TL"] = {
                                "Tinapos nang buong puso. Sana pumasa sa pamantayan mo, kasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "That was tough, but we did it! All finished.",
                            },
                            ["TL"] = {
                                "Mabigat 'yon, pero kinaya natin! Tapos na ang lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "One more step toward surviving comfortably. All done!",
                            },
                            ["TL"] = {
                                "Isa na namang hakbang para maging maginhawa rito. Tapos na!",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Done! Happy to do my part for our people.",
                            },
                            ["TL"] = {
                                "Tapos na! Masayang gawin ang parte ko para sa kasamahan natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "All set! Feels good to get something productive accomplished.",
                            },
                            ["TL"] = {
                                "Handa na! Masarap sa pakiramdam na may natapos na kapaki-pakinabang.",
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
        ["sourceShard"] = "adopters/hoomans/dialogue/social_interaction_scene_horde_work/interaction_scene_task_work_completed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
