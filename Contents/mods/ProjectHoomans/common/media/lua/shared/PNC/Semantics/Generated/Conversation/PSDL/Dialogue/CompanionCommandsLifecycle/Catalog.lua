-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.camp.failed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.camp.failed",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CompanionCommandsLifecycle/Catalog",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.camp.failed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/camp.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I couldn't set up camp there.",
                            },
                            ["TL"] = {
                                "Hindi ako nakapag-set up ng kampo roon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Failed to establish camp. That spot wasn't viable.",
                            },
                            ["TL"] = {
                                "Bigo sa pagtatayo ng kampo. Di angkop ang lugar.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I tried to camp there, but it didn't work out.",
                            },
                            ["TL"] = {
                                "Sinubukan kong magkampo roon, pero hindi umubra.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Couldn't secure that position for a camp.",
                            },
                            ["TL"] = {
                                "Hindi ma-secure ang pwestong 'yon para sa kampo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Camp setup failed. The area is too exposed.",
                            },
                            ["TL"] = {
                                "Pumalpak ang pagtatayo ng kampo. Masyadong bukas ang lugar.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to bed down there. Too many issues.",
                            },
                            ["TL"] = {
                                "Di makatulog doon. Masyadong maraming aberya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "That campsite didn't pan out. Too dangerous.",
                            },
                            ["TL"] = {
                                "Di umubra ang kampong 'yon. Masyadong mapanganib.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Attempted to camp, but had to pull out.",
                            },
                            ["TL"] = {
                                "Sinubukang magkampo, pero kinailangang umurong.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Can't pitch camp there. Ground wasn't secure.",
                            },
                            ["TL"] = {
                                "Di makapaglatag ng kampo roon. Di ligtas ang lupa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Camping attempt failed. Finding another spot.",
                            },
                            ["TL"] = {
                                "Bigo ang pagtatangkang magkampo. Maghanap ng iba.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.camp.queued",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.camp.queued",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CompanionCommandsLifecycle/Catalog",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.camp.queued",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/camp.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Okay, I'll set up camp there.",
                            },
                            ["TL"] = {
                                "Sige, magse-set up ako ng kampo roon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Setting up our camp now.",
                            },
                            ["TL"] = {
                                "Naintindihan. Itatayo na ang kampo natin ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'll go get the camp established.",
                            },
                            ["TL"] = {
                                "Pupunta ako para itayo ang kampo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "On my way to set up camp.",
                            },
                            ["TL"] = {
                                "Papunta na para magtayo ng kampo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Making camp in that spot. Understood.",
                            },
                            ["TL"] = {
                                "Magtatayo ng kampo sa pwestong 'yon. Naintindihan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Right. Setting up shelter over there.",
                            },
                            ["TL"] = {
                                "Sige. Magtatayo ng silungan doon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I'll secure the camp site now.",
                            },
                            ["TL"] = {
                                "Seselyuhan ko ang kampo ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Moving to establish camp as ordered.",
                            },
                            ["TL"] = {
                                "Kikilos para magtayo ng kampo ayon sa utos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Got it. Pitching camp.",
                            },
                            ["TL"] = {
                                "Nakuha ko. Maglalatag ng kampo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Heading over to make camp.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Pupunta roon para magkampo.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.camp.queued.friendly",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.camp.queued.friendly",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CompanionCommandsLifecycle/Catalog",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.camp.queued.friendly",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/camp.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Sure, I'll set up camp there. Sounds cozy.",
                            },
                            ["TL"] = {
                                "Sige, magse-set up ako ng kampo roon. Mukhang maaliwalas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Happy to! Let's get a good fire going.",
                            },
                            ["TL"] = {
                                "Masayang gagawin! Magpaningas tayo ng maayos na apoy.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Good call, friend. I'll get our camp ready.",
                            },
                            ["TL"] = {
                                "Magandang pasya, kaibigan. Ihahanda ko ang kampo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Leave it to me! I'll make sure it's safe and comfortable.",
                            },
                            ["TL"] = {
                                "Ipaubaya mo sa akin! Titiyakin kong ligtas at komportable.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Great idea. I'll go set up camp for us.",
                            },
                            ["TL"] = {
                                "Magandang ideya. Pupunta ako para itayo ang kampo natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Right on! Time to get off our feet. Setting up now.",
                            },
                            ["TL"] = {
                                "Aba oo! Oras na para magpahinga. Magtatayo na ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Gladly. I'll have the beds laid out shortly.",
                            },
                            ["TL"] = {
                                "Malugod kong gagawin. Ilalatag ko ang higaan maya-maya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Sounds wonderful. I'll get our shelter squared away.",
                            },
                            ["TL"] = {
                                "Napakaganda. Aayusin ko ang silungan natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Sure thing, partner! Camp will be ready in no time.",
                            },
                            ["TL"] = {
                                "Walang anuman, kasama! Handa na ang kampo agad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "On it, friend! Rest easy, I'll handle camp.",
                            },
                            ["TL"] = {
                                "Inaasikaso na, kaibigan! Magpahinga ka, ako na sa kampo.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.camp.queued.repeated",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.camp.queued.repeated",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CompanionCommandsLifecycle/Catalog",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.camp.queued.repeated",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/camp.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm still setting up camp there.",
                            },
                            ["TL"] = {
                                "Nagtatayo pa rin ako ng kampo roon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Already working on the camp. Give me a minute.",
                            },
                            ["TL"] = {
                                "Ginagawa ko na ang kampo. Bigyan mo ako ng sandali.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Still on it. Setting up takes a little time.",
                            },
                            ["TL"] = {
                                "Inaasikaso pa rin. May katagalan ang pagtatayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I'm already pitching the camp there.",
                            },
                            ["TL"] = {
                                "Naglalatag na ako ng kampo roon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Working as fast as I can on that camp.",
                            },
                            ["TL"] = {
                                "Ginagawa ko nang mabilis ang kampong 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Yeah, I heard you the first time. Still making camp.",
                            },
                            ["TL"] = {
                                "Oo, narinig ko sa una pa lang. Ginagawa pa rin ang kampo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I'm already in the middle of setting up.",
                            },
                            ["TL"] = {
                                "Kasalukuyan na akong nagtatayo roon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Camp setup is already in progress.",
                            },
                            ["TL"] = {
                                "Kasalukuyan nang isinasagawa ang pagkakampo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Still securing the campsite. Hold tight.",
                            },
                            ["TL"] = {
                                "Sinisigurado pa rin ang kampo. Maghintay lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Almost done with the camp. Don't rush me.",
                            },
                            ["TL"] = {
                                "Halos tapos na sa kampo. Huwag mo akong madaliin.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.camp.queued.trusted",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.camp.queued.trusted",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CompanionCommandsLifecycle/Catalog",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.camp.queued.trusted",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/camp.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "All right, I'll make camp there.",
                            },
                            ["TL"] = {
                                "Sige, magtatayo ako ng kampo roon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I trust your eye for good ground. Setting up camp.",
                            },
                            ["TL"] = {
                                "Tiwala ako sa pagpili mo ng lupa. Magtatayo ng kampo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "You picked the spot, I'll build the shelter.",
                            },
                            ["TL"] = {
                                "Pinili mo ang pwesto, itatayo ko ang silungan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. I'll make sure our campsite is locked down tight.",
                            },
                            ["TL"] = {
                                "Naintindihan. Titiyakin kong saradong-sarado ang kampo natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I know you've got our safety in mind. Making camp.",
                            },
                            ["TL"] = {
                                "Alam kong kaligtasan natin ang iniisip mo. Magkakampo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Right away. We'll be secure there together.",
                            },
                            ["TL"] = {
                                "Agad-agad. Ligtas tayo roon nang magkasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I'll get it ready for both of us.",
                            },
                            ["TL"] = {
                                "Ihahanda ko para sa ating dalawa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Trust your judgment completely. Camp is going up.",
                            },
                            ["TL"] = {
                                "Lubos akong nagtitiwala sa pasya mo. Itatayo na ang kampo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Setting up camp. We earned this rest.",
                            },
                            ["TL"] = {
                                "Nagtatayo ng kampo. Karapat-dapat tayo sa pahingang ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Good call, partner. I'll secure the camp perimeter.",
                            },
                            ["TL"] = {
                                "Magandang pasya, kasama. Seselyuhan ko ang paligid ng kampo.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.camp.queued.withdrawn",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.camp.queued.withdrawn",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[5]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CompanionCommandsLifecycle/Catalog",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.camp.queued.withdrawn",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/camp.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'll set up camp there.",
                            },
                            ["TL"] = {
                                "Magtatayo ako ng kampo roon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Fine. Heading over to camp.",
                            },
                            ["TL"] = {
                                "Sige. Pupunta roon para magkampo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Camping.",
                            },
                            ["TL"] = {
                                "Naintindihan. Magkakampo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "If you say so. I'll make camp.",
                            },
                            ["TL"] = {
                                "Kung sinasabi mo. Magtatayo ako ng kampo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Going to set it up now.",
                            },
                            ["TL"] = {
                                "Pupunta para itayo ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "All right. Pitching shelter.",
                            },
                            ["TL"] = {
                                "Sige. Magtatayo ng silong.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I'll do it.",
                            },
                            ["TL"] = {
                                "Gagawin ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Making camp. Leave me to it.",
                            },
                            ["TL"] = {
                                "Nagtatayo ng kampo. Hayaan mo na ako rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Fine. Camping there.",
                            },
                            ["TL"] = {
                                "Sige. Magkakampo roon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Heard. Setting up.",
                            },
                            ["TL"] = {
                                "Narinig ko. Nagtatayo na.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.camp.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.camp.rejected",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[6]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CompanionCommandsLifecycle/Catalog",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.camp.rejected",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/camp.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I can't set up camp there right now.",
                            },
                            ["TL"] = {
                                "Hindi ako makapag-set up ng kampo roon ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "That spot is far too dangerous to sleep in.",
                            },
                            ["TL"] = {
                                "Masyadong mapanganib ang pwestong 'yon para tulugan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "No way. It's crawling with dead over there.",
                            },
                            ["TL"] = {
                                "Ayoko nga. Puno ng patay doon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I refuse to camp in that area. Find somewhere safer.",
                            },
                            ["TL"] = {
                                "Tumatanggi akong magkampo roon. Maghanap ng mas ligtas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Too exposed. We'd get ambushed in our sleep.",
                            },
                            ["TL"] = {
                                "Masyadong bukas. Matatambangan tayo habang natutulog.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Can't camp there. No walls, no fire, no cover.",
                            },
                            ["TL"] = {
                                "Di makapagkampo roon. Walang pader, apoy, o silong.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Not camping there. That's asking to be eaten alive.",
                            },
                            ["TL"] = {
                                "Di ako magkakampo roon. Parang nagpapakain tayo nang buhay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to comply. That position is totally compromised.",
                            },
                            ["TL"] = {
                                "Di makasusunod. Masyadong dehado ang pwestong 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I won't bed down there. Pick another room.",
                            },
                            ["TL"] = {
                                "Di ako hihiga roon. Pumili ka ng ibang kwarto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Camping rejected. We need real security first.",
                            },
                            ["TL"] = {
                                "Tinatanggihan ang kampo. Kailangan natin ng tunay na kaligtasan.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.follow.failed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.follow.failed",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[7]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CompanionCommandsLifecycle/Catalog",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.follow.failed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/follow.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I couldn't start following you.",
                            },
                            ["TL"] = {
                                "Hindi ko masimulan ang pagsunod sa iyo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Failed to follow. Path was obstructed.",
                            },
                            ["TL"] = {
                                "Bigo sa pagsunod. May harang sa daan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I tried to follow, but got caught on something.",
                            },
                            ["TL"] = {
                                "Sinubukan kong sumunod, pero naipit ako sa kung saan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Lost your trail. Couldn't keep following.",
                            },
                            ["TL"] = {
                                "Nawala ang bakas mo. Di nakasunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to follow through that passage.",
                            },
                            ["TL"] = {
                                "Di makasunod sa lagusang 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Follow command failed. Way is blocked.",
                            },
                            ["TL"] = {
                                "Pumalpak ang utos na sumunod. Barado ang daan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I couldn't match your route.",
                            },
                            ["TL"] = {
                                "Hindi ko nasabayan ang ruta mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Blocked off. Can't follow that way.",
                            },
                            ["TL"] = {
                                "May harang. Di makasunod sa daang 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Attempted to follow, but lost visual.",
                            },
                            ["TL"] = {
                                "Sinubukang sumunod, pero nawala sa paningin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Can't reach you to follow. Clear the path.",
                            },
                            ["TL"] = {
                                "Di kita maabot para sumunod. Hawiin ang daan.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.follow.queued",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.follow.queued",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[8]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CompanionCommandsLifecycle/Catalog",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.follow.queued",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/follow.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Okay, I'll follow you.",
                            },
                            ["TL"] = {
                                "Sige, susundan kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Right behind you.",
                            },
                            ["TL"] = {
                                "Nasa likod mo lang ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Following now. Lead the way.",
                            },
                            ["TL"] = {
                                "Sumusunod na ngayon. Mauna ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Sticking close behind.",
                            },
                            ["TL"] = {
                                "Naintindihan. Didikit sa likod mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Moving with you. Lead on.",
                            },
                            ["TL"] = {
                                "Kumikilos kasabay mo. Mauna na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'm with you. Let's move.",
                            },
                            ["TL"] = {
                                "Kasama mo ako. Kilos na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Right on your tail. Watching our rear.",
                            },
                            ["TL"] = {
                                "Nasa buntot mo lang. Binabantayan ang likod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Following your pace. Keep going.",
                            },
                            ["TL"] = {
                                "Sasabay sa bilis mo. Tuloy lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Falling in behind you.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Papatabi sa likod mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Got it. Moving out with you.",
                            },
                            ["TL"] = {
                                "Nakuha ko. Lalakad kasabay mo.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.follow.queued.friendly",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.follow.queued.friendly",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[9]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CompanionCommandsLifecycle/Catalog",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.follow.queued.friendly",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/follow.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Of course, I'll follow you.",
                            },
                            ["TL"] = {
                                "Siyempre, susundan kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Gladly, friend! Lead the way.",
                            },
                            ["TL"] = {
                                "Malugod, kaibigan! Ituro ang daan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Always happy to travel with you. Let's go!",
                            },
                            ["TL"] = {
                                "Laging masayang maglakbay kasama ka. Tara na!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I'm right behind you, partner. Let's do this.",
                            },
                            ["TL"] = {
                                "Nasa likod mo lang ako, kasama. Gawin na natin ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Right with you, friend! Watch your steps.",
                            },
                            ["TL"] = {
                                "Kasabay mo ako, kaibigan! Mag-ingat sa hakbang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Wouldn't rather be following anyone else.",
                            },
                            ["TL"] = {
                                "Wala nang ibang gugustuhin kong sundan kundi ikaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Lead on! I've got your six covered.",
                            },
                            ["TL"] = {
                                "Mauna ka! Hawak ko ang likod mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Sure thing! Sticking like glue to you, friend.",
                            },
                            ["TL"] = {
                                "Walang anuman! Didikit na parang pandikit sa 'yo, kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Happy to follow. Keep us safe!",
                            },
                            ["TL"] = {
                                "Masayang sumunod. Panatilihin tayong ligtas!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Right behind you, partner. Onward!",
                            },
                            ["TL"] = {
                                "Nasa likod mo lang, kasama. Pasulong!",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.follow.queued.repeated",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.follow.queued.repeated",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[10]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CompanionCommandsLifecycle/Catalog",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.follow.queued.repeated",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/follow.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm still following you.",
                            },
                            ["TL"] = {
                                "Sinusundan pa rin kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Already following right behind you.",
                            },
                            ["TL"] = {
                                "Nakasunod na ako mismo sa likod mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Still on your heels. No need to repeat.",
                            },
                            ["TL"] = {
                                "Nasa likod mo pa rin. Di na kailangang ulitin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I haven't gone anywhere. Still right here.",
                            },
                            ["TL"] = {
                                "Wala akong pinuntahan. Narito pa rin ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Following you already. Just keep walking.",
                            },
                            ["TL"] = {
                                "Sumusunod na sa 'yo. Magpatuloy ka lang sa paglalakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'm right behind you! Look over your shoulder.",
                            },
                            ["TL"] = {
                                "Nasa likod mo lang ako! Lumingon ka sa balikat mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Still with you. Don't worry.",
                            },
                            ["TL"] = {
                                "Kasama mo pa rin ako. Huwag kang mag-alala.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Already in tow. Lead the way.",
                            },
                            ["TL"] = {
                                "Nakasunod na. Mauna ka na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Following you as we speak.",
                            },
                            ["TL"] = {
                                "Sumusunod sa 'yo habang nagsasalita ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I'm already following. Keep moving.",
                            },
                            ["TL"] = {
                                "Sumusunod na ako. Tuloy lang sa paglakad.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.follow.queued.trusted",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.follow.queued.trusted",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[11]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CompanionCommandsLifecycle/Catalog",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.follow.queued.trusted",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/follow.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I know you. I'll follow.",
                            },
                            ["TL"] = {
                                "Kilala kita. Susunod ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I trust your lead completely. Following you.",
                            },
                            ["TL"] = {
                                "Lubos akong nagtitiwala sa pangunguna mo. Susunod sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Lead the way, partner. I'm with you to the end.",
                            },
                            ["TL"] = {
                                "Ituro ang daan, kasama. Kasama mo ako hanggang dulo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "You've proven your judgment. I'll follow anywhere.",
                            },
                            ["TL"] = {
                                "Napatunayan mo na ang galing mo. Susunod ako kahit saan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. I trust you to keep us alive.",
                            },
                            ["TL"] = {
                                "Naintindihan. Tiwala akong bubuhayin mo tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Right behind you. We watch out for one another.",
                            },
                            ["TL"] = {
                                "Nasa likod mo lang. Nagbabantayan tayo sa isa't isa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I'm at your side, friend. Lead on.",
                            },
                            ["TL"] = {
                                "Nasa tabi mo ako, kaibigan. Mauna ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "You make the calls, I back you up. Following.",
                            },
                            ["TL"] = {
                                "Ikaw ang magpasya, susuportahan kita. Sumusunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I know you have my back. Following your lead.",
                            },
                            ["TL"] = {
                                "Alam kong hawak mo ang likod ko. Sumusunod sa pangunguna mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Understood, partner. Right behind you.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko, kasama. Nasa likod mo lang.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.follow.queued.withdrawn",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.follow.queued.withdrawn",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[12]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CompanionCommandsLifecycle/Catalog",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.follow.queued.withdrawn",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/follow.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'll follow.",
                            },
                            ["TL"] = {
                                "Susunod ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Fine. Walking behind you.",
                            },
                            ["TL"] = {
                                "Sige. Lalakad sa likod mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Following. Whatever.",
                            },
                            ["TL"] = {
                                "Sumusunod. Kahit ano pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Moving.",
                            },
                            ["TL"] = {
                                "Naintindihan. Kumikilos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Right behind. Don't stop suddenly.",
                            },
                            ["TL"] = {
                                "Nasa likod lang. Huwag hihinto nang bigla.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'll keep up.",
                            },
                            ["TL"] = {
                                "Sasabay ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Following. Keep going.",
                            },
                            ["TL"] = {
                                "Sumusunod. Tuloy lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "All right. Let's go.",
                            },
                            ["TL"] = {
                                "Sige. Tara na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Behind you.",
                            },
                            ["TL"] = {
                                "Nasa likod mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Moving along.",
                            },
                            ["TL"] = {
                                "Sumasabay.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.follow.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.follow.rejected",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[13]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CompanionCommandsLifecycle/Catalog",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.follow.rejected",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/follow.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I can't follow you right now.",
                            },
                            ["TL"] = {
                                "Hindi kita masusundan ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I need to stay here. Can't follow.",
                            },
                            ["TL"] = {
                                "Kailangan kong manatili rito. Di makasusunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Refusing to follow into that danger.",
                            },
                            ["TL"] = {
                                "Tumatangging sumunod sa panganib na 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Too exhausted or injured to keep up. I can't follow.",
                            },
                            ["TL"] = {
                                "Masyadong pagod o sugatan para sumabay. Di makasusunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I have business here. You go on ahead.",
                            },
                            ["TL"] = {
                                "May inaasikaso ako rito. Mauna ka na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Can't follow. My hands are full.",
                            },
                            ["TL"] = {
                                "Di makasusunod. Marami akong ginagawa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Not following you into that mess.",
                            },
                            ["TL"] = {
                                "Di kita susundan sa gulong 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I won't follow you right now.",
                            },
                            ["TL"] = {
                                "Hindi kita susundan sa ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Stay back, I'm not following.",
                            },
                            ["TL"] = {
                                "Umatras ka, di ako susunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Follow order rejected. I'm holding position.",
                            },
                            ["TL"] = {
                                "Tinatanggihan ang utos na sumunod. Hawak ko ang pwesto.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.return_home.failed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.return_home.failed",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[14]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CompanionCommandsLifecycle/Catalog",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.return_home.failed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/return_home.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I couldn't head home.",
                            },
                            ["TL"] = {
                                "Hindi ako nakauwi.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "The path back home is completely blocked.",
                            },
                            ["TL"] = {
                                "Ganap na may harang ang daan pabalik sa tahanan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Failed to return. Too many hostiles along the route.",
                            },
                            ["TL"] = {
                                "Bigo sa pag-uwi. Masyadong maraming kalaban sa ruta.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I couldn't find a safe way back to base.",
                            },
                            ["TL"] = {
                                "Wala akong makitang ligtas na daan pabalik sa base.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Return trip failed. Had to double back.",
                            },
                            ["TL"] = {
                                "Pumalpak ang pag-uwi. Kinailangang bumalik.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to reach home safely right now.",
                            },
                            ["TL"] = {
                                "Di makarating sa tahanan nang ligtas sa ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Tried heading back, but the streets were overrun.",
                            },
                            ["TL"] = {
                                "Sinubukang umuwi, pero pinamumugaran ang mga kalsada.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Lost the route home in the chaos.",
                            },
                            ["TL"] = {
                                "Nawala ang daan pauwi sa gitna ng gulo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Can't reach base from this position.",
                            },
                            ["TL"] = {
                                "Di maabot ang base mula sa pwestong ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Return to base aborted. Route compromised.",
                            },
                            ["TL"] = {
                                "Itinigil ang pag-uwi sa base. May aberya sa ruta.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.return_home.queued",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.return_home.queued",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[15]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CompanionCommandsLifecycle/Catalog",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.return_home.queued",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/return_home.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Okay, I'll head home.",
                            },
                            ["TL"] = {
                                "Sige, uuwi ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Heading back to base now.",
                            },
                            ["TL"] = {
                                "Pabalik na sa base ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Moving toward home.",
                            },
                            ["TL"] = {
                                "Naintindihan. Papatungo na sa tahanan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I'll make my way back to our shelter.",
                            },
                            ["TL"] = {
                                "Babalik ako sa silungan natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Returning to camp as ordered.",
                            },
                            ["TL"] = {
                                "Babalik sa kampo ayon sa utos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Right. Time to head home.",
                            },
                            ["TL"] = {
                                "Sige. Oras na para umuwi.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Retracing my steps to base.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Binabalikan ang daan sa base.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "On my way back home.",
                            },
                            ["TL"] = {
                                "Papauwi na ako ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Got it. Returning to home coordinates.",
                            },
                            ["TL"] = {
                                "Nakuha ko. Pabalik sa mga coordinate ng tahanan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Heading inbound for home.",
                            },
                            ["TL"] = {
                                "Papasok na pauwi.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.return_home.queued.friendly",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.return_home.queued.friendly",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[16]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CompanionCommandsLifecycle/Catalog",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.return_home.queued.friendly",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/return_home.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Sure, I'll head home. See you back there soon!",
                            },
                            ["TL"] = {
                                "Sige, uuwi ako. Kita tayo roon agad!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Sounds wonderful, friend. I'll get back to camp safely.",
                            },
                            ["TL"] = {
                                "Napakaganda, kaibigan. Babalik ako sa kampo nang ligtas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Heading home, partner! Make sure you stay safe too.",
                            },
                            ["TL"] = {
                                "Pauwi na, kasama! Tiyakin mong mag-iingat ka rin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I'll go keep the fire warm for when you return.",
                            },
                            ["TL"] = {
                                "Pupunta ako para panatilihing mainit ang apoy pagbalik mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Great idea! I'll head home and stow our gear.",
                            },
                            ["TL"] = {
                                "Magandang ideya! Uuwi ako at itatabi ang gamit natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Happy to head home. Don't stay out too late, friend!",
                            },
                            ["TL"] = {
                                "Masayang uuwi. Huwag kang magpagabi sa labas, kaibigan!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "On my way back to our safe place. Take care!",
                            },
                            ["TL"] = {
                                "Papauwi na sa ligtas nating lugar. Mag-ingat ka!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Heading home with a smile. See you shortly, partner.",
                            },
                            ["TL"] = {
                                "Pauwi nang may ngiti. Magkita tayo maya-maya, kasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'll get things tidy back at base for us.",
                            },
                            ["TL"] = {
                                "Aayusin ko ang mga gamit sa base para sa atin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Heading home! Be careful on your way back.",
                            },
                            ["TL"] = {
                                "Pauwi na! Mag-ingat ka sa pagbalik mo.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.return_home.queued.repeated",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.return_home.queued.repeated",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[17]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CompanionCommandsLifecycle/Catalog",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.return_home.queued.repeated",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/return_home.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm still heading home.",
                            },
                            ["TL"] = {
                                "Pauwi pa rin ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Already on my way back. Just navigating the path.",
                            },
                            ["TL"] = {
                                "Pauwi na ako. Dumaraan lang sa ligtas na ruta.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Still traveling toward base. Be there soon.",
                            },
                            ["TL"] = {
                                "Naglalakbay pa rin patungong base. Nandoon na agad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I haven't stopped moving toward home.",
                            },
                            ["TL"] = {
                                "Di ako humihinto sa paglakad pauwi.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Already heading home. Keep calm.",
                            },
                            ["TL"] = {
                                "Pauwi na nga ako. Kumalma ka lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Still on the road home.",
                            },
                            ["TL"] = {
                                "Nasa daan pa rin pauwi.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Almost there. Still heading for base.",
                            },
                            ["TL"] = {
                                "Malapit na roon. Papatungo pa rin sa base.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Already following the return route.",
                            },
                            ["TL"] = {
                                "Sumusunod na sa rutang pabalik.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Still en route to home. No need to yell.",
                            },
                            ["TL"] = {
                                "Nasa biyahe pa rin pauwi. Di kailangang sumigaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I'm already on the way back.",
                            },
                            ["TL"] = {
                                "Pauwi na talaga ako.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.return_home.queued.trusted",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.return_home.queued.trusted",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[18]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CompanionCommandsLifecycle/Catalog",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.return_home.queued.trusted",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/return_home.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "All right, I'm heading home. Guard the rear.",
                            },
                            ["TL"] = {
                                "Sige, pauwi na ako. Bantayan mo ang likod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I trust your call. I'll make sure base is secure.",
                            },
                            ["TL"] = {
                                "Tiwala ako sa pasya mo. Titiyakin kong ligtas ang base.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Heading home, partner. Don't take unnecessary risks out here.",
                            },
                            ["TL"] = {
                                "Pauwi na, kasama. Huwag sumugal sa panganib dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. I'll be waiting at camp for your return.",
                            },
                            ["TL"] = {
                                "Naintindihan. Maghihintay ako sa kampo sa pagbalik mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Heading home. Make sure you come back in one piece.",
                            },
                            ["TL"] = {
                                "Pauwi na. Tiyakin mong makababalik ka nang buo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'll hold down the fort until you get back.",
                            },
                            ["TL"] = {
                                "Babantayan ko ang kuta hanggang sa makabalik ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Heading back. Trusting you to watch yourself.",
                            },
                            ["TL"] = {
                                "Pabalik na. Nagtitiwala akong iingatan mo ang sarili mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'll see you at home, friend. Stay vigilant.",
                            },
                            ["TL"] = {
                                "Magkita tayo sa bahay, kaibigan. Manatiling mapagmatyag.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Returning to our haven. Stay alive for me.",
                            },
                            ["TL"] = {
                                "Babalik sa kanlungan natin. Manatiling buhay para sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Heading back to secure our home.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Pabalik na para i-secure ang tahanan natin.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.return_home.queued.withdrawn",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.return_home.queued.withdrawn",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[19]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CompanionCommandsLifecycle/Catalog",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.return_home.queued.withdrawn",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/return_home.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'll head home.",
                            },
                            ["TL"] = {
                                "Uuwi ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Going back now.",
                            },
                            ["TL"] = {
                                "Babalik na ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Heading to base.",
                            },
                            ["TL"] = {
                                "Papatungo sa base.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Home.",
                            },
                            ["TL"] = {
                                "Naintindihan. Bahay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Fine. I'm leaving.",
                            },
                            ["TL"] = {
                                "Sige. Aalis na ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Heading back alone.",
                            },
                            ["TL"] = {
                                "Babalik mag-isa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Going home. Whatever.",
                            },
                            ["TL"] = {
                                "Uuwi na. Kahit ano pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "All right. Heading back.",
                            },
                            ["TL"] = {
                                "Sige. Pabalik na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
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
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Moving toward shelter.",
                            },
                            ["TL"] = {
                                "Papatungo sa silungan.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.return_home.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.return_home.rejected",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[20]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CompanionCommandsLifecycle/Catalog",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.return_home.rejected",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/return_home.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I can't head home right now.",
                            },
                            ["TL"] = {
                                "Hindi ako makauuwi ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "The road home is cut off by hordes.",
                            },
                            ["TL"] = {
                                "Pinutol ng mga kawan ang daan pauwi.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'm not leaving you out here alone. Can't go home.",
                            },
                            ["TL"] = {
                                "Di kita iiwan dito nang mag-isa. Di ako uuwi.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Too much danger on the way back right now.",
                            },
                            ["TL"] = {
                                "Masyadong maraming panganib sa daan pabalik ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Refusing to return home while we're surrounded.",
                            },
                            ["TL"] = {
                                "Tumatangging umuwi habang napapaligiran tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I have to finish what we started before I head back.",
                            },
                            ["TL"] = {
                                "Kailangan kong tapusin ang sinimulan bago umuwi.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Can't head home. The gates are compromised.",
                            },
                            ["TL"] = {
                                "Di makauwi. May sira ang tarangkahan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to return to base right now.",
                            },
                            ["TL"] = {
                                "Di makabalik sa base sa ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I won't abandon the mission to go home now.",
                            },
                            ["TL"] = {
                                "Di ko tatalikuran ang misyon para lang umuwi ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Return home rejected. Not safe to travel.",
                            },
                            ["TL"] = {
                                "Tinatanggihan ang pag-uwi. Di ligtas maglakbay.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.stay.failed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.stay.failed",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[21]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CompanionCommandsLifecycle/Catalog",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.stay.failed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/stay.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I couldn't start the stay order.",
                            },
                            ["TL"] = {
                                "Hindi ko masimulan ang utos na manatili.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Failed to hold position here.",
                            },
                            ["TL"] = {
                                "Bigo sa paghawak ng pwesto rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I tried to stay, but the ground wasn't safe.",
                            },
                            ["TL"] = {
                                "Sinubukan kong manatili, pero di ligtas ang lupa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Couldn't lock down this position.",
                            },
                            ["TL"] = {
                                "Di maikandado ang pwestong ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Stay command failed. Enemies forced me to move.",
                            },
                            ["TL"] = {
                                "Pumalpak ang pananatili. Pinilit akong gumalaw ng kalaban.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to stay put in this area.",
                            },
                            ["TL"] = {
                                "Di makapanatili sa lugar na ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Holding ground failed. Too much incoming fire.",
                            },
                            ["TL"] = {
                                "Bigo ang paghawak sa pwesto. Masyadong maraming putok.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Can't stay here. Position is untenable.",
                            },
                            ["TL"] = {
                                "Di makapanatili rito. Masyadong dehado ang pwesto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Attempted to hold, but got pushed back.",
                            },
                            ["TL"] = {
                                "Sinubukang humawak, pero naitulak paatras.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Could not secure a stay order here.",
                            },
                            ["TL"] = {
                                "Hindi ma-secure ang pananatili rito.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.stay.queued",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.stay.queued",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[22]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CompanionCommandsLifecycle/Catalog",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.stay.queued",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/stay.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Okay, I'll stay here.",
                            },
                            ["TL"] = {
                                "Sige, mananatili ako rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Holding position right here.",
                            },
                            ["TL"] = {
                                "Hawak ko ang pwestong ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Staying put.",
                            },
                            ["TL"] = {
                                "Naintindihan. Dito lang ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I'll hold this ground.",
                            },
                            ["TL"] = {
                                "Hahawakan ko ang pwestong ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Standing guard right here. Understood.",
                            },
                            ["TL"] = {
                                "Nakatayong bantay dito. Naintindihan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Right. I won't move from this spot.",
                            },
                            ["TL"] = {
                                "Sige. Di ako aalis sa lugar na 'to.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Holding this perimeter. Go ahead.",
                            },
                            ["TL"] = {
                                "Binabantayan ang paligid na ito. Sige na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Maintaining this position.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Pananatilihin ang posisyong ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Got it. Staying right where I am.",
                            },
                            ["TL"] = {
                                "Nakuha ko. Mananatili kung nasaan ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Holding ground as ordered.",
                            },
                            ["TL"] = {
                                "Hawak ang pwesto ayon sa utos.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.stay.queued.friendly",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.stay.queued.friendly",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[23]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CompanionCommandsLifecycle/Catalog",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.stay.queued.friendly",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/stay.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Sure, I'll stay here. Take your time, friend!",
                            },
                            ["TL"] = {
                                "Sige, mananatili ako rito. Huwag kang magmadali, kaibigan!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I'll keep watch right here, partner. Be careful!",
                            },
                            ["TL"] = {
                                "Magbabantay ako rito, kasama. Mag-ingat ka!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "No problem! I'll guard our spot until you get back.",
                            },
                            ["TL"] = {
                                "Walang problema! Babantayan ko ang pwesto natin hanggang makabalik ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Happy to hold the fort here for you, friend.",
                            },
                            ["TL"] = {
                                "Masayang babantayan ang kuta rito para sa 'yo, kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Sure thing! I'll be waiting right here for you.",
                            },
                            ["TL"] = {
                                "Walang anuman! Maghihintay ako rito mismo para sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I won't wander off. Stay safe out there, partner!",
                            },
                            ["TL"] = {
                                "Di ako lalayo. Mag-ingat ka sa labas, kasama!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Holding the line right here with a smile. Go do what you need to do.",
                            },
                            ["TL"] = {
                                "Hawak ang linya rito nang may ngiti. Gawin mo ang kailangan mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'll make sure nobody sneaks past this spot, friend.",
                            },
                            ["TL"] = {
                                "Titiyakin kong walang makalulusot dito, kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Resting my feet and keeping watch. See you soon!",
                            },
                            ["TL"] = {
                                "Ipapahinga ang paa at magbabantay. Kita tayo agad!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "All good! I'll be right here when you return.",
                            },
                            ["TL"] = {
                                "Ayos ang lahat! Narito lang ako pagbalik mo.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.stay.queued.repeated",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.stay.queued.repeated",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[24]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CompanionCommandsLifecycle/Catalog",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.stay.queued.repeated",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/stay.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm already staying here.",
                            },
                            ["TL"] = {
                                "Nananatili na ako rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Still holding this spot. Haven't budged.",
                            },
                            ["TL"] = {
                                "Hawak pa rin ang pwesto. Di gumagalaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'm already staying put, don't worry.",
                            },
                            ["TL"] = {
                                "Dito na nga ako, huwag kang mag-alala.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Haven't moved an inch. Still right here.",
                            },
                            ["TL"] = {
                                "Di gumalaw kahit isang pulgada. Narito pa rin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Still guarding this exact position.",
                            },
                            ["TL"] = {
                                "Binabantayan pa rin ang mismong posisyong ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I heard you before. I'm staying right here.",
                            },
                            ["TL"] = {
                                "Narinig na kita kanina. Dito lang ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Already holding ground. Go on.",
                            },
                            ["TL"] = {
                                "Hawak na ang lupa. Sige na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Still staying here. No need to remind me.",
                            },
                            ["TL"] = {
                                "Nananatili pa rin dito. Di na kailangang ipaalala.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'm rooted right here. Keep moving.",
                            },
                            ["TL"] = {
                                "Nakatuntong na ako rito. Tuloy ka na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Already staying. I'm watching the area.",
                            },
                            ["TL"] = {
                                "Nandito na nga. Binabantayan ko ang lugar.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.stay.queued.trusted",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.stay.queued.trusted",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[25]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CompanionCommandsLifecycle/Catalog",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.stay.queued.trusted",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/stay.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "All right, I'll stay. Watch your back out there.",
                            },
                            ["TL"] = {
                                "Sige, mananatili ako. Bantayan mo ang likod mo sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I trust your plan. I'll secure this position.",
                            },
                            ["TL"] = {
                                "Tiwala ako sa plano mo. Seselyuhan ko ang pwestong ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Holding this ground for both of us, partner.",
                            },
                            ["TL"] = {
                                "Hahawakan ko ang pwestong ito para sa atin, kasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I won't let anything breach this spot while you're away.",
                            },
                            ["TL"] = {
                                "Walang makakapasok dito habang wala ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. I'll stay right here until you call.",
                            },
                            ["TL"] = {
                                "Naintindihan. Dito lang ako hanggang tawagin mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "You can count on me to hold this room, friend.",
                            },
                            ["TL"] = {
                                "Makaaasa ka sa akin na bantayan ang kwartong ito, kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Holding this vantage point. Be careful out there.",
                            },
                            ["TL"] = {
                                "Hawak ang magandang tanawin na ito. Mag-ingat ka sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'll be right here when you return, partner. Stay alive.",
                            },
                            ["TL"] = {
                                "Narito lang ako pagbalik mo, kasama. Manatiling buhay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Trusting you to come back safe. Holding the line.",
                            },
                            ["TL"] = {
                                "Nagtitiwala akong babalik kang ligtas. Hawak ang linya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. I'll hold this post with my life.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Babantayan ko ang posteng ito nang buong tapang.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.stay.queued.withdrawn",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.stay.queued.withdrawn",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[26]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CompanionCommandsLifecycle/Catalog",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.stay.queued.withdrawn",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/stay.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Okay, I'll stay.",
                            },
                            ["TL"] = {
                                "Sige, mananatili ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Fine. Staying here.",
                            },
                            ["TL"] = {
                                "Sige. Dito lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Holding ground.",
                            },
                            ["TL"] = {
                                "Hawak ang lupa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Staying.",
                            },
                            ["TL"] = {
                                "Naintindihan. Mananatili.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I'll stay put.",
                            },
                            ["TL"] = {
                                "Dito lang ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Not moving.",
                            },
                            ["TL"] = {
                                "Di gagalaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Fine by me. Go.",
                            },
                            ["TL"] = {
                                "Ayos sa akin. Alis na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Staying right here.",
                            },
                            ["TL"] = {
                                "Dito lang mismo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Waiting.",
                            },
                            ["TL"] = {
                                "Naiintindihan. Naghihintay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Holding position.",
                            },
                            ["TL"] = {
                                "Hawak ang posisyon.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.stay.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.stay.rejected",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[27]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CompanionCommandsLifecycle/Catalog",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.stay.rejected",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/stay.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I can't stay here right now.",
                            },
                            ["TL"] = {
                                "Hindi ako makapananatili rito ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Too dangerous to stay put. We need to keep moving.",
                            },
                            ["TL"] = {
                                "Masyadong mapanganib manatili rito. Kailangang gumalaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I won't stay in an open kill zone.",
                            },
                            ["TL"] = {
                                "Di ako tatayo sa bukas na lugar na pugad ng patayan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Staying here is suicide. I'm coming with you.",
                            },
                            ["TL"] = {
                                "Pagpapakamatay ang manatili rito. Sasama ako sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I refuse to hold this spot without adequate cover.",
                            },
                            ["TL"] = {
                                "Tumatanggi akong humawak dito nang walang maayos na silong.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Cannot stay here. The perimeter is totally exposed.",
                            },
                            ["TL"] = {
                                "Di makapanatili rito. Masyadong kita ang paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I'm not standing like a target. I have to move.",
                            },
                            ["TL"] = {
                                "Di ako tatayong parang target. Kailangan kong gumalaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to hold position. Hostiles are too close.",
                            },
                            ["TL"] = {
                                "Di mahawakan ang pwesto. Masyadong malapit ang kalaban.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I won't stay behind while you need backup.",
                            },
                            ["TL"] = {
                                "Di ako maiiwan habang kailangan mo ng saklolo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Stay order rejected. We must relocate.",
                            },
                            ["TL"] = {
                                "Tinatanggihan ang pananatili. Kailangan nating lumipat.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.stop_following.failed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.stop_following.failed",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[28]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CompanionCommandsLifecycle/Catalog",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.stop_following.failed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/stop_following.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I couldn't stop following.",
                            },
                            ["TL"] = {
                                "Hindi ako nakahinto sa pagsunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Failed to break follow stance.",
                            },
                            ["TL"] = {
                                "Bigo sa pagtigil sa pagsunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I tried to hold back, but the crowd pushed me with you.",
                            },
                            ["TL"] = {
                                "Sinubukan kong huminto, pero itinulak ako ng kawan kasabay mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Couldn't disengage from following.",
                            },
                            ["TL"] = {
                                "Hindi makahiwalay sa pagsunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Stop following failed. Route required continuous movement.",
                            },
                            ["TL"] = {
                                "Pumalpak ang paghinto sa pagsunod. Kailangan ng tuloy-tuloy na galaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to stop following right now.",
                            },
                            ["TL"] = {
                                "Di makahinto sa pagsunod ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Attempted to halt, but had to keep moving.",
                            },
                            ["TL"] = {
                                "Sinubukang huminto, pero kinailangang magpatuloy.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Can't detach from follow mode here.",
                            },
                            ["TL"] = {
                                "Di makahiwalay sa pagsunod dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Follow lock failed to release.",
                            },
                            ["TL"] = {
                                "Di bumitaw ang pagsunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Couldn't stop following in this tight corridor.",
                            },
                            ["TL"] = {
                                "Di makahinto sa pagsunod sa makipot na daang ito.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.stop_following.queued",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.stop_following.queued",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[29]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CompanionCommandsLifecycle/Catalog",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.stop_following.queued",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/stop_following.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Okay, I'll stop following.",
                            },
                            ["TL"] = {
                                "Sige, titigil ako sa pagsunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Breaking off pursuit.",
                            },
                            ["TL"] = {
                                "Naintindihan. Titigil na sa pagsunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'll stop here and hold.",
                            },
                            ["TL"] = {
                                "Hihinto ako rito at magbabantay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Ceasing follow. Standing down.",
                            },
                            ["TL"] = {
                                "Ititigil ang pagsunod. Uurong sa pwesto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. I'll remain in this area.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Mananatili ako sa lugar na 'to.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Right. Not following anymore.",
                            },
                            ["TL"] = {
                                "Sige. Di na susunod pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Stopping here. You go on.",
                            },
                            ["TL"] = {
                                "Hihinto rito. Mauna ka na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Got it. Halting my movement.",
                            },
                            ["TL"] = {
                                "Nakuha ko. Hihinto sa paglakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Breaking off. I'll hold ground.",
                            },
                            ["TL"] = {
                                "Bumibitiw na. Hahawakan ko ang pwesto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Stopping follow routine.",
                            },
                            ["TL"] = {
                                "Naintindihan. Ititigil ang pagsunod.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.stop_following.queued.friendly",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.stop_following.queued.friendly",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[30]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CompanionCommandsLifecycle/Catalog",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.stop_following.queued.friendly",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/stop_following.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Got it, I'll stop following. Take care out there, friend!",
                            },
                            ["TL"] = {
                                "Nakuha ko, titigil ako sa pagsunod. Mag-ingat ka sa labas, kaibigan!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Sure thing! I'll hold down this spot for you, partner.",
                            },
                            ["TL"] = {
                                "Walang anuman! Babantayan ko ang pwestong ito para sa 'yo, kasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Happy to give you some space. Holler if you need me!",
                            },
                            ["TL"] = {
                                "Masayang bibigyan kita ng puwang. Tawagin mo ako kapag kailangan mo ako!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I'll stop following here, friend. Be careful on your solo run.",
                            },
                            ["TL"] = {
                                "Hihinto ako sa pagsunod dito, kaibigan. Mag-ingat sa sarili mong lakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Understood, partner! I'll be right here waiting.",
                            },
                            ["TL"] = {
                                "Naintindihan, kasama! Narito lang ako naghihintay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Stopping here with a smile. Don't be a stranger!",
                            },
                            ["TL"] = {
                                "Hihinto rito nang may ngiti. Magpakita ka agad!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Sure! I'll catch my breath while you scout ahead.",
                            },
                            ["TL"] = {
                                "Sige! Hihinga muna ako habang nagmamanman ka sa unahan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "All right, friend! I'll stay put until you return.",
                            },
                            ["TL"] = {
                                "Sige, kaibigan! Dito lang ako hanggang makabalik ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Halting here. Good luck out there, partner!",
                            },
                            ["TL"] = {
                                "Hihinto rito. Magandang suwerte sa 'yo sa labas, kasama!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "No worries! I'll stop following and guard our rear.",
                            },
                            ["TL"] = {
                                "Walang problema! Titigil sa pagsunod at babantayan ang likod.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.stop_following.queued.repeated",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.stop_following.queued.repeated",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[31]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CompanionCommandsLifecycle/Catalog",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.command.stop_following.queued.repeated",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/stop_following.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I've already stopped following.",
                            },
                            ["TL"] = {
                                "Tumigil na ako sa pagsunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I'm already standing still. Not following you.",
                            },
                            ["TL"] = {
                                "Nakatayo na nga ako. Di na kita sinusundan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Already halted. Look, I'm not moving.",
                            },
                            ["TL"] = {
                                "Huminto na. Tingnan mo, di ako gumagalaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I stopped following after the first command.",
                            },
                            ["TL"] = {
                                "Huminto na ako sa pagsunod pagkatapos ng unang utos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Still not following you. I'm right here.",
                            },
                            ["TL"] = {
                                "Di pa rin kita sinusundan. Narito lang ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Already stopped. Go ahead without me.",
                            },
                            ["TL"] = {
                                "Huminto na. Sige na, mauna ka nang wala ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I'm not following anymore, I promise.",
                            },
                            ["TL"] = {
                                "Di na kita sinusundan, pangako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Already stationary. No need to tell me again.",
                            },
                            ["TL"] = {
                                "Nakatigil na ako. Di na kailangang sabihin ulit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I've been stopped for a while now.",
                            },
                            ["TL"] = {
                                "Kanina pa ako huminto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Still halted. Move along freely.",
                            },
                            ["TL"] = {
                                "Nakatigil pa rin. Lumakad ka na nang malaya.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
