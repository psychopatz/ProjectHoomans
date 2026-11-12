-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.excursion_departing.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.excursion_departing.guarded",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[7]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionSceneTravelNews/Catalog",
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
                ["responseTemplateID"] = "semantic.interaction.scene.excursion_departing",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/excursion.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "We're outbound. Keep the group tight.",
                            },
                            ["TL"] = {
                                "Papunta na tayo. Panatilihing dikit ang grupo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Crossing outside. Weapons ready, safety off.",
                            },
                            ["TL"] = {
                                "Lalabas na. Handa ang armas, alisin ang safety.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "No talking from here on out. Hand signals only.",
                            },
                            ["TL"] = {
                                "Walang magsasalita simula rito. Senyas-kamay lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Keep low and match my speed. Don't wander off.",
                            },
                            ["TL"] = {
                                "Yumuko at sumabay sa bilis ko. Huwag lalayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Scan your sectors continuously as we move.",
                            },
                            ["TL"] = {
                                "Bantayan ang pwesto niyo habang lumalakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Outbound. If we take fire, dive for immediate cover.",
                            },
                            ["TL"] = {
                                "Palabas na. Kapag may nagpaputok, dapa agad sa kublihan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Watch the tree line and rooftops. Moving out.",
                            },
                            ["TL"] = {
                                "Bantayan ang mga puno at bubong. Lakad na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Stay alert. The outside world is completely hostile.",
                            },
                            ["TL"] = {
                                "Maging alisto. Mapanganib ang buong mundo sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "We're moving. Anyone who strays gets left behind.",
                            },
                            ["TL"] = {
                                "Kumikilos na. Ang lumihis maiiwan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Formation tight. Moving into enemy territory.",
                            },
                            ["TL"] = {
                                "Mahigpit na pormasyon. Papatungo sa teritoryo ng kalaban.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_scene_travel_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.excursion_departing.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.excursion_departing.neutral",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionSceneTravelNews/Catalog",
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
                ["responseTemplateID"] = "semantic.interaction.scene.excursion_departing",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/excursion.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "We're moving out. Keep close.",
                            },
                            ["TL"] = {
                                "Aalis na tayo. Dumikit ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Heading out now. Stay sharp.",
                            },
                            ["TL"] = {
                                "Lalabas na tayo ngayon. Maging alerto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Departure time. Keep your eyes peeled.",
                            },
                            ["TL"] = {
                                "Oras na ng pag-alis. Buksan ang mga mata.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Stepping outside the wire. Watch your surroundings.",
                            },
                            ["TL"] = {
                                "Lalabas na sa bakod. Bantayan ang paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "We're on the move. Maintain distance and formation.",
                            },
                            ["TL"] = {
                                "Kumikilos na tayo. Panatilihin ang pormasyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Moving out. Quiet footsteps.",
                            },
                            ["TL"] = {
                                "Lumalabas na. Tahimik na mga hakbang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Time to go. Stick to the planned route.",
                            },
                            ["TL"] = {
                                "Oras na para umalis. Manatili sa pinlanong ruta.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Excursion begins now. Stay focused.",
                            },
                            ["TL"] = {
                                "Nagsisimula na ang lakad. Magpokus.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Here we go. Eyes front and watch your flanks.",
                            },
                            ["TL"] = {
                                "Ito na tayo. Tumingin sa unahan at tagiliran.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Moving outbound. Keep noise to a minimum.",
                            },
                            ["TL"] = {
                                "Papalabas na. Huwag gagawa ng ingay.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_scene_travel_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.excursion_departing.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.excursion_departing.terse",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[6]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionSceneTravelNews/Catalog",
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
                ["responseTemplateID"] = "semantic.interaction.scene.excursion_departing",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/excursion.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "Moving out. Stay close.",
                            },
                            ["TL"] = {
                                "Aalis na. Dumikit.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Moving out.",
                            },
                            ["TL"] = {
                                "Lalakad na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Let's move.",
                            },
                            ["TL"] = {
                                "Kilos na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Heading out.",
                            },
                            ["TL"] = {
                                "Lalabas na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Outbound.",
                            },
                            ["TL"] = {
                                "Palabas.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "On the move.",
                            },
                            ["TL"] = {
                                "Kumikilos na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Stay tight.",
                            },
                            ["TL"] = {
                                "Dumikit.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Quiet steps.",
                            },
                            ["TL"] = {
                                "Tahimik na hakbang.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Marching.",
                            },
                            ["TL"] = {
                                "Lumalakad na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Go.",
                            },
                            ["TL"] = {
                                "Tara.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_scene_travel_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.excursion_departing.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.excursion_departing.warm",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[5]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionSceneTravelNews/Catalog",
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
                ["responseTemplateID"] = "semantic.interaction.scene.excursion_departing",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/excursion.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "We're heading out. Stay close and we'll get through it.",
                            },
                            ["TL"] = {
                                "Aalis na tayo. Dumikit ka at malalampasan natin ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Off we go, friend! Right beside you all the way.",
                            },
                            ["TL"] = {
                                "Lalakad na tayo, kaibigan! Katabi mo ako sa buong daan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Stay close to me, partner. We watch out for each other.",
                            },
                            ["TL"] = {
                                "Dumikit ka sa akin, kasama. Bantayan natin ang isa't isa.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Moving out together. Let's make it a safe trip.",
                            },
                            ["TL"] = {
                                "Sabay tayong aalis. Gawin nating ligtas ang biyahe.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Here we go! Keep your chin up and stay close.",
                            },
                            ["TL"] = {
                                "Ito na! Itaas ang noo at dumikit.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Heading out. Don't worry, we've got this covered.",
                            },
                            ["TL"] = {
                                "Lalabas na. Huwag mag-alala, hawak natin ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Step together, friend. We'll be back before you know it.",
                            },
                            ["TL"] = {
                                "Sabay-sabay sa hakbang, kaibigan. Makababalik tayo agad.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "On our way! Stay safe and keep smiling.",
                            },
                            ["TL"] = {
                                "Papunta na tayo! Manatiling ligtas at masigla.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Moving out. I'm right behind you if you need a hand.",
                            },
                            ["TL"] = {
                                "Lumalabas na. Nasa likod mo lang ako kung kailangan mo ng tulong.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Let's bring back good loot and all our limbs! Moving out.",
                            },
                            ["TL"] = {
                                "Mag-uwi tayo ng magagandang gamit nang buo ang katawan! Lakad na.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_scene_travel_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.excursion_failed.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.excursion_failed.guarded",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[19]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionSceneTravelNews/Catalog",
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
                ["responseTemplateID"] = "semantic.interaction.scene.excursion_failed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/excursion.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Excursion failed. We regroup here.",
                            },
                            ["TL"] = {
                                "Bigo ang paglalakbay. Magtipon ulit tayo rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Something compromised the operation. Pull back immediately.",
                            },
                            ["TL"] = {
                                "May sumira sa operasyon. Umatras agad-agad.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Forcing this run will get us slaughtered. Abort.",
                            },
                            ["TL"] = {
                                "Kamatayan kapag pinilit ang lakad na 'to. Ihinto.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Fall back and figure out what went wrong behind closed doors.",
                            },
                            ["TL"] = {
                                "Umatras at alamin kung anong pumalpak sa loob ng pinto.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "The route is burned. We're retreating right now.",
                            },
                            ["TL"] = {
                                "Nasira ang ruta. Aatras tayo ngayon din.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Trip canceled. Watch your back as we return to the gates.",
                            },
                            ["TL"] = {
                                "Kanselado ang lakad. Bantayan ang likod habang bumabalik.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Bad intel or bad luck. Either way, we pull the plug.",
                            },
                            ["TL"] = {
                                "Maling balita o malas. Alinman doon, itigil na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Do not push forward into an ambush. Abort the mission.",
                            },
                            ["TL"] = {
                                "Huwag lumusob sa tambang. Itigil ang misyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Abort. Secure the entrance and debrief.",
                            },
                            ["TL"] = {
                                "Tigil. I-secure ang lagusan at mag-usap.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Failed attempt. Fall back and secure your weapons.",
                            },
                            ["TL"] = {
                                "Bigong pagtatangka. Umatras at i-secure ang armas.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_scene_travel_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.excursion_failed.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.excursion_failed.neutral",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[16]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionSceneTravelNews/Catalog",
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
                ["responseTemplateID"] = "semantic.interaction.scene.excursion_failed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/excursion.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Trip's off. Something went wrong.",
                            },
                            ["TL"] = {
                                "Kanselado ang biyahe. May nangyaring mali.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "We have to cancel the run. It's not safe.",
                            },
                            ["TL"] = {
                                "Kailangang kanselahin ang lakad. Hindi ligtas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Plan fell apart. We're aborting the trip.",
                            },
                            ["TL"] = {
                                "Pumalpak ang plano. Ititigil natin ang paglabas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Call it off. Conditions are too hazardous.",
                            },
                            ["TL"] = {
                                "Kanselahin na. Masyadong mapanganib ang kalagayan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "We're aborting the mission. Regroup back inside.",
                            },
                            ["TL"] = {
                                "Ititigil ang misyon. Magtipon pabalik sa loob.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Trip canceled. Something compromised our route.",
                            },
                            ["TL"] = {
                                "Kanselado ang biyahe. May sumira sa ruta natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Not happening today. Pull back to base.",
                            },
                            ["TL"] = {
                                "Hindi matutuloy ngayon. Umatras pabalik sa base.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Mission failed. Better to abort than lose lives.",
                            },
                            ["TL"] = {
                                "Bigo ang misyon. Mas mabuting ihinto kaysa may mamatay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "The run is scrubbed. Head back inside.",
                            },
                            ["TL"] = {
                                "Kanselado ang paglabas. Bumalik sa loob.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Aborting the excursion. We'll rethink the plan.",
                            },
                            ["TL"] = {
                                "Ititigil ang lakad. Pag-iisipan natin muli ang plano.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_scene_travel_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.excursion_failed.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.excursion_failed.terse",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[18]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionSceneTravelNews/Catalog",
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
                ["responseTemplateID"] = "semantic.interaction.scene.excursion_failed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/excursion.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "Trip's off.",
                            },
                            ["TL"] = {
                                "Kanselado ang biyahe.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Aborted.",
                            },
                            ["TL"] = {
                                "Ihinto.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Scrubbed.",
                            },
                            ["TL"] = {
                                "Kanselado.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Back inside.",
                            },
                            ["TL"] = {
                                "Balik sa loob.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Cancel it.",
                            },
                            ["TL"] = {
                                "Kanselahin.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Failed. Fall back.",
                            },
                            ["TL"] = {
                                "Bigo. Umatras.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Not today.",
                            },
                            ["TL"] = {
                                "Hindi ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Abort.",
                            },
                            ["TL"] = {
                                "Tigil.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Off.",
                            },
                            ["TL"] = {
                                "Wala na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Regroup.",
                            },
                            ["TL"] = {
                                "Magtipon ulit.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_scene_travel_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.excursion_failed.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.excursion_failed.warm",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[17]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionSceneTravelNews/Catalog",
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
                ["responseTemplateID"] = "semantic.interaction.scene.excursion_failed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/excursion.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "We're calling it off. Better safe than forcing it.",
                            },
                            ["TL"] = {
                                "Ititigil muna natin. Mas mabuting ligtas kaysa pilitin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Don't be discouraged, friend. We'll try again another day.",
                            },
                            ["TL"] = {
                                "Huwag kang panghinaan ng loob, kaibigan. Susubukan natin ulit sa ibang araw.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'd rather have you alive than whatever supplies are out there.",
                            },
                            ["TL"] = {
                                "Mas gusto kitang buhay kaysa sa anumang gamit sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "It's okay, partner. We made the right call to abort.",
                            },
                            ["TL"] = {
                                "Ayos lang, kasama. Tama ang desisyon nating huminto.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Safety comes first. Come on, let's head back together.",
                            },
                            ["TL"] = {
                                "Kaligtasan ang una sa lahat. Halika, sabay tayong bumalik.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Don't beat yourself up over this. We did what we could.",
                            },
                            ["TL"] = {
                                "Huwag mong sisihin sarili mo. Ginawa natin ang makakaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "We live to fight another day. That's the real victory, friend.",
                            },
                            ["TL"] = {
                                "Mabubuhay tayo para lumaban muli. Iyon ang tunay na panalo, kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "Calling it off was smart. I'm glad you're safe beside me.",
                            },
                            ["TL"] = {
                                "Matalinong desisyon ang huminto. Masaya akong ligtas ka sa tabi ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Take a breath. We'll rest up and plan better next time.",
                            },
                            ["TL"] = {
                                "Huminga ka muna. Magpapahinga tayo at magpaplano nang mas maayos.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "We'll get 'em next time, partner. Let's head inside.",
                            },
                            ["TL"] = {
                                "Makakabawi tayo sa susunod, kasama. Pumasok na tayo.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_scene_travel_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.excursion_home.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.excursion_home.guarded",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[15]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionSceneTravelNews/Catalog",
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
                ["responseTemplateID"] = "semantic.interaction.scene.excursion_home",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/excursion.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "We're back. Check in and settle down.",
                            },
                            ["TL"] = {
                                "Nakabalik na tayo. Mag-check in at magpahinga.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Bar the doors immediately. Don't let anything follow us in.",
                            },
                            ["TL"] = {
                                "Kandadohin ang pinto agad. Huwag magpapasok ng kahit ano.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Inventory the gear right now before anything goes missing.",
                            },
                            ["TL"] = {
                                "Ilista ang mga gamit ngayon bago may mawala.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Inside the fence, but don't drop your guard completely.",
                            },
                            ["TL"] = {
                                "Nasa loob na ng bakod, pero huwag ibaba nang buo ang bantay.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Check the perimeter sentries. Make sure the camp wasn't breached.",
                            },
                            ["TL"] = {
                                "Tingnan ang mga nagbabantay. Tiyaking di pinasok ang kampo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Secure the locks. Then we tally our supplies.",
                            },
                            ["TL"] = {
                                "I-lock ang pinto. Pagkatapos bilangin ang mga gamit.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "We're back. Did anyone get bitten? Speak up now.",
                            },
                            ["TL"] = {
                                "Nakabalik na. May nakagat ba? Magsalita ngayon din.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Drop the backpacks in the storeroom. Keep weapons loaded.",
                            },
                            ["TL"] = {
                                "Ibaba ang bag sa bodega. Panatilihing may karga ang armas.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Good, we're inside. Keep quiet so we don't draw strays.",
                            },
                            ["TL"] = {
                                "Mabuti, nasa loob na. Manahimik para di maakit ang mga patay.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Back inside the wire. Rest, but be ready to mobilize.",
                            },
                            ["TL"] = {
                                "Nasa loob na ng alambre. Magpahinga, pero laging handa.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_scene_travel_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.excursion_home.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.excursion_home.neutral",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[12]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionSceneTravelNews/Catalog",
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
                ["responseTemplateID"] = "semantic.interaction.scene.excursion_home",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/excursion.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "We're back. Good.",
                            },
                            ["TL"] = {
                                "Nakabalik na tayo. Mabuti.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Safe inside. Close the gate.",
                            },
                            ["TL"] = {
                                "Ligtas na sa loob. Isara ang tarangkahan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Made it back in one piece.",
                            },
                            ["TL"] = {
                                "Nakarating nang buo ang katawan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "We're home. Let's unpack the supplies.",
                            },
                            ["TL"] = {
                                "Nasa bahay na tayo. Idiskarga ang mga gamit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Back behind walls. Good run.",
                            },
                            ["TL"] = {
                                "Nasa likod na muli ng pader. Magandang biyahe.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "We've returned safely. Check the locks.",
                            },
                            ["TL"] = {
                                "Ligtas tayong nakabalik. Tingnan ang mga kandado.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Home base reached. Everyone check in.",
                            },
                            ["TL"] = {
                                "Nakarating na sa base. Mag-check in ang lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Trip concluded. Good to be back.",
                            },
                            ["TL"] = {
                                "Tapos na ang biyahe. Mabuti at nakabalik.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "We made it through the gates. Secure the perimeter.",
                            },
                            ["TL"] = {
                                "Nakalusot tayo sa tarangkahan. I-secure ang paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Back where it's safe. Good work today.",
                            },
                            ["TL"] = {
                                "Bumalik sa ligtas. Magaling ang ginawa niyo ngayon.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_scene_travel_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.excursion_home.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.excursion_home.terse",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[14]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionSceneTravelNews/Catalog",
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
                ["responseTemplateID"] = "semantic.interaction.scene.excursion_home",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/excursion.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "Back home.",
                            },
                            ["TL"] = {
                                "Nakauwi na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Home.",
                            },
                            ["TL"] = {
                                "Bahay na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Inside.",
                            },
                            ["TL"] = {
                                "Nasa loob.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Safe.",
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
                                "Gate closed.",
                            },
                            ["TL"] = {
                                "Sarado ang pinto.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Back.",
                            },
                            ["TL"] = {
                                "Bumalik na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Returned.",
                            },
                            ["TL"] = {
                                "Nakarating na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Unpack.",
                            },
                            ["TL"] = {
                                "Idiskarga.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Settled.",
                            },
                            ["TL"] = {
                                "Ayos na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Done.",
                            },
                            ["TL"] = {
                                "Tapos.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_scene_travel_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.excursion_home.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.excursion_home.warm",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[13]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionSceneTravelNews/Catalog",
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
                ["responseTemplateID"] = "semantic.interaction.scene.excursion_home",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/excursion.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "We're home. Good to have everyone back.",
                            },
                            ["TL"] = {
                                "Nasa bahay na tayo. Mabuting nakabalik ang lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "We made it back, friend! Welcome home.",
                            },
                            ["TL"] = {
                                "Nakarating tayo, kaibigan! Maligayang pagbabalik sa tahanan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Home sweet home. So glad we're both safe.",
                            },
                            ["TL"] = {
                                "Kay sarap makauwi. Masaya akong ligtas tayong pareho.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "We survived another run together! Put your feet up, partner.",
                            },
                            ["TL"] = {
                                "Nakaligtas tayo sa isa na namang biyahe! Magpahinga ka na, kasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Nothing beats walking back through our own door. Good job!",
                            },
                            ["TL"] = {
                                "Walang hihigit sa pagpasok sa sarili nating pinto. Magaling!",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Safe at last! Let me grab you some clean water.",
                            },
                            ["TL"] = {
                                "Ligtas na rin sa wakas! Kukuha kita ng malinis na tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "So relieved to see our camp again with you.",
                            },
                            ["TL"] = {
                                "Napakalaking ginhawa na makita muli ang kampo kasama ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "We did it, friend! Another successful trip in the books.",
                            },
                            ["TL"] = {
                                "Nagawa natin, kaibigan! Isa na namang tagumpay na biyahe.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Welcome back! Let's get you rested and fed.",
                            },
                            ["TL"] = {
                                "Maligayang pagbabalik! Magpahinga ka at kumain.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Home safe and sound. Proud to be on your team.",
                            },
                            ["TL"] = {
                                "Ligtas at buo. Ipinagmamalaki kong kasama kita.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_scene_travel_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.excursion_preparing.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.excursion_preparing.guarded",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionSceneTravelNews/Catalog",
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
                ["responseTemplateID"] = "semantic.interaction.scene.excursion_preparing",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/excursion.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Prep first. We move when everyone's ready.",
                            },
                            ["TL"] = {
                                "Maghanda muna. Aalis tayo kapag handa na ang lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "If you forget something vital out there, nobody is turning back for you.",
                            },
                            ["TL"] = {
                                "Kapag may naiwan kang mahalaga, walang babalik para sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Check your ammunition count twice. No excuses.",
                            },
                            ["TL"] = {
                                "Bilangin ang bala mo nang dalawang beses. Walang palusot.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Sharpen your blade now. We don't stop for maintenance in the field.",
                            },
                            ["TL"] = {
                                "Hasiin ang talim mo ngayon. Walang hinto para magkumpuni sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Pack light, pack lethal. Don't carry useless junk.",
                            },
                            ["TL"] = {
                                "Magdala ng magaan at nakamamatay. Huwag magdala ng kalat.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Inspect your boots. A twisted ankle out there is fatal.",
                            },
                            ["TL"] = {
                                "Suriin ang sapatos mo. Nakamamatay ang maipit ang paa sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Be completely ready before you step past that gate.",
                            },
                            ["TL"] = {
                                "Maging handang-handa bago lumabas sa tarangkahang 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Check your medical supplies. You bleed, you fix it.",
                            },
                            ["TL"] = {
                                "Tingnan ang gamot mo. Kapag nagdugo ka, gamutin mo sarili mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Preparing now. Stay disciplined once we cross the threshold.",
                            },
                            ["TL"] = {
                                "Naghahanda na. Maging disiplinado paglabas natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Lock and load. Don't slow the group down.",
                            },
                            ["TL"] = {
                                "Magkarga ng armas. Huwag mong pabagalin ang grupo.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_scene_travel_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.excursion_preparing.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.excursion_preparing.neutral",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionSceneTravelNews/Catalog",
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
                ["responseTemplateID"] = "semantic.interaction.scene.excursion_preparing",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/excursion.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "We're getting ready to head out.",
                            },
                            ["TL"] = {
                                "Naghahanda na tayong umalis.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Double-check your pack and gear before we leave.",
                            },
                            ["TL"] = {
                                "Suriing muli ang bag at gamit bago tayo umalis.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Making preparations for the run now.",
                            },
                            ["TL"] = {
                                "Naghahanda na para sa pagbiyahe ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Gather what you need. Departure is soon.",
                            },
                            ["TL"] = {
                                "Tipunin ang kailangan mo. Aalis na agad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Check weapons, food, and water.",
                            },
                            ["TL"] = {
                                "Suriin ang armas, pagkain, at tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Prepping for the excursion. Almost ready.",
                            },
                            ["TL"] = {
                                "Naghahanda para sa paglabas. Halos handa na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Let's make sure nothing essential gets left behind.",
                            },
                            ["TL"] = {
                                "Tiyaking walang mahahalagang gamit na maiiwan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Getting everything squared away for the road.",
                            },
                            ["TL"] = {
                                "Inaayos ang lahat para sa paglalakbay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Final checks before we open the gates.",
                            },
                            ["TL"] = {
                                "Huling pagsusuri bago buksan ang tarangkahan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Prepare your supplies. We move shortly.",
                            },
                            ["TL"] = {
                                "Ihanda ang mga supply. Kikilos na tayo maya-maya.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_scene_travel_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.excursion_preparing.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.excursion_preparing.terse",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionSceneTravelNews/Catalog",
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
                ["responseTemplateID"] = "semantic.interaction.scene.excursion_preparing",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/excursion.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "Get ready. We leave soon.",
                            },
                            ["TL"] = {
                                "Maghanda. Aalis tayo agad.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Pack up.",
                            },
                            ["TL"] = {
                                "Mag-impake.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Check gear.",
                            },
                            ["TL"] = {
                                "Tingnan ang gamit.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Prepping.",
                            },
                            ["TL"] = {
                                "Naghahanda.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Load out.",
                            },
                            ["TL"] = {
                                "Ihanda ang karga.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Almost time.",
                            },
                            ["TL"] = {
                                "Malapit na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Ready weapons.",
                            },
                            ["TL"] = {
                                "Ihanda ang armas.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Moving soon.",
                            },
                            ["TL"] = {
                                "Aalis na agad.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Supplies ready.",
                            },
                            ["TL"] = {
                                "Handa na ang supply.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Final checks.",
                            },
                            ["TL"] = {
                                "Huling pagsusuri.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_scene_travel_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.excursion_preparing.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.excursion_preparing.warm",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionSceneTravelNews/Catalog",
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
                ["responseTemplateID"] = "semantic.interaction.scene.excursion_preparing",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/excursion.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "We're getting ready. Make sure you've got what you need.",
                            },
                            ["TL"] = {
                                "Naghahanda na tayo. Siguraduhin mong dala mo ang kailangan mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Take your time prepping, friend. Better safe than sorry.",
                            },
                            ["TL"] = {
                                "Maghanda nang mabuti, kaibigan. Mas mabuting handa.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Need help packing anything up, partner?",
                            },
                            ["TL"] = {
                                "Kailangan mo ba ng tulong sa pag-iimpake, kasama?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Got an extra bandage if you need one. Let's prep well.",
                            },
                            ["TL"] = {
                                "May sobra akong bendahe kung kailangan mo. Maghanda tayo nang maayos.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Excited and nervous, but we've got each other. Ready up!",
                            },
                            ["TL"] = {
                                "Kaba at sabik, pero magkasama tayo. Maghanda na!",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Make sure you've eaten and drank water before we go.",
                            },
                            ["TL"] = {
                                "Tiyaking nakakain at nakainom ka bago tayo umalis.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Getting ready! We'll make this a successful run together.",
                            },
                            ["TL"] = {
                                "Naghahanda na! Gagawin nating matagumpay ang biyaheng ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "Double-check your boots and bandages, friend.",
                            },
                            ["TL"] = {
                                "Suriin ang bota at bendahe mo, kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'm right here prepping alongside you. We'll do great.",
                            },
                            ["TL"] = {
                                "Nandito lang ako naghahanda kasabay mo. Magiging maayos tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Readying supplies. Stay positive, we've got this!",
                            },
                            ["TL"] = {
                                "Inihahanda ang mga gamit. Maging positibo, kaya natin ito!",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_scene_travel_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.excursion_returning.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.excursion_returning.guarded",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[11]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionSceneTravelNews/Catalog",
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
                ["responseTemplateID"] = "semantic.interaction.scene.excursion_returning",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/excursion.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "We're returning. Stay alert until we're home.",
                            },
                            ["TL"] = {
                                "Pabalik na tayo. Mag-ingat hanggang makauwi.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "The trip back is when most scavengers get ambushed. Watch the trees.",
                            },
                            ["TL"] = {
                                "Sa pagbalik karaniwang tinatambangan ang tao. Bantayan ang puno.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Don't let your guard down just because we're heading home.",
                            },
                            ["TL"] = {
                                "Huwag ibaba ang bantay dahil lang pauwi na tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Check your rear. Make sure nothing is following our scent.",
                            },
                            ["TL"] = {
                                "Tingnan ang likod. Tiyaking walang sumusunod sa amoy natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Keep the haul hidden. We don't want to draw bandit eyes.",
                            },
                            ["TL"] = {
                                "Itago ang mga nakuha. Ayaw nating makahikayat ng magnanakaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Returning now. Speed up without making noise.",
                            },
                            ["TL"] = {
                                "Babalik na. Bilis-bilisan nang walang ginagawang ingay.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "We're inbound. Stay ready to drop the bags and fight.",
                            },
                            ["TL"] = {
                                "Papasok na. Maging handang ibaba ang bag at lumaban.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Watch our backtrail. Stragglers could be tailing us.",
                            },
                            ["TL"] = {
                                "Bantayan ang dinaanan. Baka may sumusunod sa atin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Almost at the gates, but keep checking corners.",
                            },
                            ["TL"] = {
                                "Malapit na sa tarangkahan, pero suriin pa rin ang mga kanto.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Returning. No relaxing until the deadbolt is thrown.",
                            },
                            ["TL"] = {
                                "Pabalik na. Walang magpapahinga hangga't di nakakandado.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_scene_travel_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.excursion_returning.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.excursion_returning.neutral",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[8]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionSceneTravelNews/Catalog",
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
                ["responseTemplateID"] = "semantic.interaction.scene.excursion_returning",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/excursion.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "We're heading home.",
                            },
                            ["TL"] = {
                                "Pauwi na tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Turn around. Time to get back to base.",
                            },
                            ["TL"] = {
                                "Lumingon na. Oras na para bumalik sa base.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Objective done. Heading back now.",
                            },
                            ["TL"] = {
                                "Tapos na ang sadya. Pabalik na ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Let's retrace our steps and get home safe.",
                            },
                            ["TL"] = {
                                "Balikan natin ang dinaanan at umuwi nang ligtas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Heading inbound. Keep your guard up until we're inside.",
                            },
                            ["TL"] = {
                                "Papasok na. Huwag ibaba ang bantay hanggang makapasok.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Pack up what we found. We're going home.",
                            },
                            ["TL"] = {
                                "Iimpake ang nahanap. Uuwi na tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Time to head back. Watch the trail behind us.",
                            },
                            ["TL"] = {
                                "Oras nang bumalik. Bantayan ang bakas sa likod natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Return journey begins now. Stay together.",
                            },
                            ["TL"] = {
                                "Pabalik na biyahe simula na. Magsama-sama.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "We're bound for home. Almost there.",
                            },
                            ["TL"] = {
                                "Pauwi na tayo. Malapit na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Moving back to safe ground. Keep alert.",
                            },
                            ["TL"] = {
                                "Babalik na sa ligtas na lugar. Maging alerto.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_scene_travel_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.excursion_returning.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.excursion_returning.terse",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[10]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionSceneTravelNews/Catalog",
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
                ["responseTemplateID"] = "semantic.interaction.scene.excursion_returning",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/excursion.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "Heading home.",
                            },
                            ["TL"] = {
                                "Pauwi na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Returning.",
                            },
                            ["TL"] = {
                                "Babalik na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Homeward.",
                            },
                            ["TL"] = {
                                "Pauwi.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Back to base.",
                            },
                            ["TL"] = {
                                "Balik sa base.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Time to return.",
                            },
                            ["TL"] = {
                                "Oras nang bumalik.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Turn back.",
                            },
                            ["TL"] = {
                                "Bumalik na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Inbound.",
                            },
                            ["TL"] = {
                                "Papasok na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Done. Home.",
                            },
                            ["TL"] = {
                                "Tapos. Uwi na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Retracing steps.",
                            },
                            ["TL"] = {
                                "Binabalikan ang daan.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Going back.",
                            },
                            ["TL"] = {
                                "Pabalik na.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_scene_travel_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.excursion_returning.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.excursion_returning.warm",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[9]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionSceneTravelNews/Catalog",
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
                ["responseTemplateID"] = "semantic.interaction.scene.excursion_returning",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/excursion.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "Time to head home. Let's get everyone back safe.",
                            },
                            ["TL"] = {
                                "Oras nang umuwi. Iuwi nating ligtas ang lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "We're going home, friend! Can't wait to rest.",
                            },
                            ["TL"] = {
                                "Uuwi na tayo, kaibigan! Sabik na akong magpahinga.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Great work out here. Let's get back home together.",
                            },
                            ["TL"] = {
                                "Magaling ang ginawa mo rito. Sabay na tayong umuwi.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Heading home, partner! A warm fire is waiting for us.",
                            },
                            ["TL"] = {
                                "Pauwi na, kasama! May mainit na apoy na naghihintay sa 'tin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Almost back to safety. Keep your spirits up, friend.",
                            },
                            ["TL"] = {
                                "Malapit na sa ligtas. Pasiglahin ang loob, kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "We did good today! Let's get this haul home.",
                            },
                            ["TL"] = {
                                "Maganda ang nagawa natin ngayon! Iuwi na natin ang nakuha.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Heading back! I'm so glad we're both still standing.",
                            },
                            ["TL"] = {
                                "Pabalik na! Masayang-masaya ako't nakatayo pa tayong pareho.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "Just a little further and we're home safe. Stay close.",
                            },
                            ["TL"] = {
                                "Kaunti na lang at ligtas na tayo sa bahay. Dumikit ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Homeward bound, partner. You did amazing.",
                            },
                            ["TL"] = {
                                "Pauwi na, kasama. Napakahusay mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Let's get back to our camp and take a well-deserved rest.",
                            },
                            ["TL"] = {
                                "Bumalik na tayo sa kampo para sa nararapat na pahinga.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_scene_travel_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.grounded_news_answer.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.grounded_news_answer.guarded",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[27]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionSceneTravelNews/Catalog",
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
                ["responseTemplateID"] = "semantic.interaction.scene.grounded_news_answer",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/grounded_news.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Nothing else I can verify yet.",
                            },
                            ["TL"] = {
                                "Wala pa akong ibang mapapatunayan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "I don't deal in rumors. That's the only confirmed piece.",
                            },
                            ["TL"] = {
                                "Di ako nakikipagtsismisan. Iyan lang ang kumpirmado.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Don't press for details I can't back up.",
                            },
                            ["TL"] = {
                                "Huwag kang maghanap ng detalyeng di ko mapatutunayan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "That's the extent of it. Keep it between us.",
                            },
                            ["TL"] = {
                                "Hanggang diyan lang. Sa ating dalawa lang 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "I won't guess about the rest. Stick to the facts.",
                            },
                            ["TL"] = {
                                "Hindi ako manghuhula. Manatili sa katotohanan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "That is all you need to know for now.",
                            },
                            ["TL"] = {
                                "Iyan lang ang kailangan mong malaman sa ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Anything beyond that is dangerous speculation.",
                            },
                            ["TL"] = {
                                "Anuman higit diyan ay mapanganib na haka-haka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "I've verified that much. Nothing more to say.",
                            },
                            ["TL"] = {
                                "Iyan lang ang nakumpirma ko. Wala nang dapat sabihin pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Take that information and plan accordingly.",
                            },
                            ["TL"] = {
                                "Kunin ang balitang 'yan at magplano nang maayos.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "That's all that's confirmed. Watch your step.",
                            },
                            ["TL"] = {
                                "Iyan lang ang tiyak. Mag-ingat ka sa hakbang mo.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_scene_travel_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.grounded_news_answer.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.grounded_news_answer.neutral",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[24]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionSceneTravelNews/Catalog",
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
                ["responseTemplateID"] = "semantic.interaction.scene.grounded_news_answer",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/grounded_news.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "That is what I can confirm right now.",
                            },
                            ["TL"] = {
                                "Iyan ang makukumpirma ko sa ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "That's all the verified information I have.",
                            },
                            ["TL"] = {
                                "Iyan lang ang napatunayang impormasyong hawak ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "That covers the extent of what I know.",
                            },
                            ["TL"] = {
                                "Iyan ang kabuuan ng nalalaman ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Beyond that, it's just guesswork.",
                            },
                            ["TL"] = {
                                "Higit pa riyan, hula-hula na lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "That's as much as I was able to find out.",
                            },
                            ["TL"] = {
                                "Iyan lang ang nagawa kong alamin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'll let you know if I hear anything more.",
                            },
                            ["TL"] = {
                                "Sasabihan kita kapag may narinig pa akong bago.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "That's the factual picture for now.",
                            },
                            ["TL"] = {
                                "Iyan ang totoong larawan sa ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "That's what's solid. The rest is rumor.",
                            },
                            ["TL"] = {
                                "Iyan ang totoo. Tsismis na ang iba.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I've told you everything I can verify.",
                            },
                            ["TL"] = {
                                "Nasabi ko na ang lahat ng kaya kong kumpirmahin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "That's the report as it stands.",
                            },
                            ["TL"] = {
                                "Iyan ang ulat sa kasalukuyan.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_scene_travel_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.grounded_news_answer.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.grounded_news_answer.terse",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[26]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionSceneTravelNews/Catalog",
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
                ["responseTemplateID"] = "semantic.interaction.scene.grounded_news_answer",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/grounded_news.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "That is all I can confirm.",
                            },
                            ["TL"] = {
                                "Iyan lang ang makukumpirma ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "That's it.",
                            },
                            ["TL"] = {
                                "Iyon lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "All I know.",
                            },
                            ["TL"] = {
                                "Lahat ng alam ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Confirmed only.",
                            },
                            ["TL"] = {
                                "Kumpirmado lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Nothing more.",
                            },
                            ["TL"] = {
                                "Wala nang iba.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "That's all.",
                            },
                            ["TL"] = {
                                "Iyon na ang lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Full report.",
                            },
                            ["TL"] = {
                                "Buong ulat.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "End of it.",
                            },
                            ["TL"] = {
                                "Diyan nagtatapos.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
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
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "All there is.",
                            },
                            ["TL"] = {
                                "Iyan lang.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_scene_travel_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.grounded_news_answer.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.grounded_news_answer.warm",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[25]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionSceneTravelNews/Catalog",
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
                ["responseTemplateID"] = "semantic.interaction.scene.grounded_news_answer",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/grounded_news.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "I wish I knew more, but that is what I can confirm.",
                            },
                            ["TL"] = {
                                "Sana mas marami akong alam, pero iyan ang makukumpirma ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "That's all I have for you right now, friend, but I'll keep asking.",
                            },
                            ["TL"] = {
                                "Iyan lang muna, kaibigan, pero patuloy akong magtatanong.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "I wanted to share everything I knew to keep you safe.",
                            },
                            ["TL"] = {
                                "Gusto kong ibahagi ang lahat para manatili kang ligtas.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "If any more news comes my way, you'll be the first I tell.",
                            },
                            ["TL"] = {
                                "Kapag may bagong balita, ikaw ang una kong sasabihan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Hope that helps you out today, partner.",
                            },
                            ["TL"] = {
                                "Sana makatulong 'yan sa 'yo ngayong araw, kasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "That's the whole story as far as I've been told.",
                            },
                            ["TL"] = {
                                "Iyan ang buong kuwento ayon sa sinabi sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "I'm glad I could pass that along to you.",
                            },
                            ["TL"] = {
                                "Mabuti at naipasa ko sa 'yo 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "That's what we have to work with for now, friend.",
                            },
                            ["TL"] = {
                                "Iyan ang hawak natin sa ngayon, kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'll keep my ears open for you.",
                            },
                            ["TL"] = {
                                "Bukas ang tainga ko para sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "That's everything for now. Take good care of yourself.",
                            },
                            ["TL"] = {
                                "Iyan ang lahat sa ngayon. Ingatan mo ang sarili mo.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_scene_travel_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.grounded_news_share.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.grounded_news_share.guarded",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[23]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionSceneTravelNews/Catalog",
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
                ["responseTemplateID"] = "semantic.interaction.scene.grounded_news_share",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/grounded_news.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "I have something I can confirm.",
                            },
                            ["TL"] = {
                                "May bagay akong makukumpirma.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "I have verified intel, but keep it quiet.",
                            },
                            ["TL"] = {
                                "May napatunayan akong impormasyon, pero panatilihing lihim.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Listen close. I don't want everyone overhearing this.",
                            },
                            ["TL"] = {
                                "Makinig nang mabuti. Ayokong marinig ito ng lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "I'm sharing this with you because you need to know the risks.",
                            },
                            ["TL"] = {
                                "Ibinabahagi ko ito dahil kailangan mong malaman ang panganib.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "News from the perimeter. Don't go spreading it wildly.",
                            },
                            ["TL"] = {
                                "Balita mula sa paligid. Huwag mong ikalat kung saan-saan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "I verified this rumor myself. Take it seriously.",
                            },
                            ["TL"] = {
                                "Kinumpirma ko ang balitang ito mismo. Seryosohin mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Careful who you repeat this to, but here's the situation.",
                            },
                            ["TL"] = {
                                "Mag-ingat kung kanino mo sasabihin, pero ito ang kalagayan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "I have confirmed facts about what happened out there.",
                            },
                            ["TL"] = {
                                "May napatunayan akong katotohanan sa nangyari sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Keep your voice low. Here's what I confirmed.",
                            },
                            ["TL"] = {
                                "Hinaan ang boses mo. Ito ang nakumpirma ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Actionable intel. Use it to protect yourself.",
                            },
                            ["TL"] = {
                                "Magagamit na impormasyon. Gamitin para protektahan ang sarili.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_scene_travel_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.grounded_news_share.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.grounded_news_share.neutral",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[20]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionSceneTravelNews/Catalog",
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
                ["responseTemplateID"] = "semantic.interaction.scene.grounded_news_share",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/grounded_news.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I heard something worth passing on.",
                            },
                            ["TL"] = {
                                "May narinig akong mahalagang ipasa sa iyo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Got an update on what's happening nearby.",
                            },
                            ["TL"] = {
                                "May balita ako sa mga nangyayari sa paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "There's fresh news from the neighboring zone.",
                            },
                            ["TL"] = {
                                "May sariwang balita mula sa kalapit na lugar.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I picked up some information you should know about.",
                            },
                            ["TL"] = {
                                "May nakuha akong impormasyon na dapat mong malaman.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Heads up: I heard a report about conditions outside.",
                            },
                            ["TL"] = {
                                "Makinig ka: may narinig akong ulat tungkol sa kalagayan sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Passing along some intelligence I gathered.",
                            },
                            ["TL"] = {
                                "Ipinapasa ko ang ilang impormasyong nakalap ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Here's what I've learned from other travelers.",
                            },
                            ["TL"] = {
                                "Ito ang nalaman ko mula sa ibang manlalakbay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "You might want to hear this latest report.",
                            },
                            ["TL"] = {
                                "Baka gusto mong marinig itong pinakahuling balita.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I have some verified information to share.",
                            },
                            ["TL"] = {
                                "May napatunayan akong impormasyon na ibabahagi.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Listen to this news before you head out.",
                            },
                            ["TL"] = {
                                "Pakinggan mo itong balita bago ka lumabas.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_scene_travel_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.grounded_news_share.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.grounded_news_share.terse",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[22]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionSceneTravelNews/Catalog",
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
                ["responseTemplateID"] = "semantic.interaction.scene.grounded_news_share",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/grounded_news.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "Got some news for you.",
                            },
                            ["TL"] = {
                                "May balita ako para sa iyo.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "News.",
                            },
                            ["TL"] = {
                                "Balita.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Listen up.",
                            },
                            ["TL"] = {
                                "Makinig.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Heard something.",
                            },
                            ["TL"] = {
                                "May narinig ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Intel for you.",
                            },
                            ["TL"] = {
                                "Impormasyon para sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Update.",
                            },
                            ["TL"] = {
                                "Ulat.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Here's the word.",
                            },
                            ["TL"] = {
                                "Ito ang balita.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "New report.",
                            },
                            ["TL"] = {
                                "Bagong balita.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Check this.",
                            },
                            ["TL"] = {
                                "Tingnan mo 'to.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Word from outside.",
                            },
                            ["TL"] = {
                                "Balita mula sa labas.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_scene_travel_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.grounded_news_share.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.grounded_news_share.warm",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[21]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/SocialInteractionSceneTravelNews/Catalog",
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
                ["responseTemplateID"] = "semantic.interaction.scene.grounded_news_share",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/grounded_news.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "I thought you should hear what I learned.",
                            },
                            ["TL"] = {
                                "Naisip kong dapat mong marinig ang nalaman ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Hey friend, I found out something that might help us.",
                            },
                            ["TL"] = {
                                "Huy kaibigan, may nalaman akong makatutulong sa atin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "I wanted to make sure you were in the loop on this news.",
                            },
                            ["TL"] = {
                                "Gusto kong tiyakin na may alam ka sa balitang ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Got some good intel to share with you, partner.",
                            },
                            ["TL"] = {
                                "May magandang balita akong ibabahagi sa 'yo, kasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Always looking out for you—listen to what I heard.",
                            },
                            ["TL"] = {
                                "Lagi kitang iniisip—makinig ka sa narinig ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Thought of you as soon as I heard this update.",
                            },
                            ["TL"] = {
                                "Ikaw agad ang naisip ko nang marinig ko ang balitang ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Come here, I have news that might make things easier.",
                            },
                            ["TL"] = {
                                "Halika rito, may balita ako na magpapagaan ng sitwasyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "Happy to share this bit of hope with you today.",
                            },
                            ["TL"] = {
                                "Masayang ibahagi ang kaunting pag-asang ito sa 'yo ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Listen up, friend. This could keep us safer.",
                            },
                            ["TL"] = {
                                "Makinig ka, kaibigan. Mas makapagpapanatiling ligtas ito sa atin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "I wanted you to hear this first from me.",
                            },
                            ["TL"] = {
                                "Gusto kong sa akin mo unang marinig ito.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_scene_travel_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
