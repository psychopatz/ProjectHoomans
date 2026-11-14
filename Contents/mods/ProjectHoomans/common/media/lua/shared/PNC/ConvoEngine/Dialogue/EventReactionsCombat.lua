-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "event_reactions_combat",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.reaction.default",
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
                                ["fallback"] = "Good work. Keep watching the area.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.reaction.default.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Good work. Keep watching the area.",
                                        "Threat's handled. Stay on your toes.",
                                        "Nice job. Don't relax just yet.",
                                        "Target down. Keep scanning the perimeter.",
                                        "Handled. Watch your surroundings.",
                                        "Good strike. Stay vigilant.",
                                        "That one's finished. Check the corners.",
                                        "Well done. Keep weapons at the ready.",
                                        "Clear here. Eyes on the shadows.",
                                        "Threat eliminated. Keep moving carefully.",
                                    },
                                    ["TL"] = {
                                        "Magandang trabaho. Patuloy na bantayan ang paligid.",
                                        "Naasikaso ang banta. Maging handa.",
                                        "Mahusay. Huwag munang magpakampante.",
                                        "Bagsak ang target. Patuloy na suriin ang paligid.",
                                        "Naasikaso na. Bantayan ang paligid mo.",
                                        "Magandang tama. Manatiling alerto.",
                                        "Tapos na ang isang 'yon. Tignan ang mga sulok.",
                                        "Magaling. Ihanda pa rin ang sandata.",
                                        "Malinis dito. Tumingin sa mga anino.",
                                        "Banta naalis na. Tuloy sa maingat na pagkilos.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.reaction",
            ["textRoles"] = {
                {
                    ["fallback"] = "Good work. Keep watching the area.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.reaction.default.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Good work. Keep watching the area.",
                            "Threat's handled. Stay on your toes.",
                            "Nice job. Don't relax just yet.",
                            "Target down. Keep scanning the perimeter.",
                            "Handled. Watch your surroundings.",
                            "Good strike. Stay vigilant.",
                            "That one's finished. Check the corners.",
                            "Well done. Keep weapons at the ready.",
                            "Clear here. Eyes on the shadows.",
                            "Threat eliminated. Keep moving carefully.",
                        },
                        ["TL"] = {
                            "Magandang trabaho. Patuloy na bantayan ang paligid.",
                            "Naasikaso ang banta. Maging handa.",
                            "Mahusay. Huwag munang magpakampante.",
                            "Bagsak ang target. Patuloy na suriin ang paligid.",
                            "Naasikaso na. Bantayan ang paligid mo.",
                            "Magandang tama. Manatiling alerto.",
                            "Tapos na ang isang 'yon. Tignan ang mga sulok.",
                            "Magaling. Ihanda pa rin ang sandata.",
                            "Malinis dito. Tumingin sa mga anino.",
                            "Banta naalis na. Tuloy sa maingat na pagkilos.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.reaction.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "default",
            ["sourceId"] = "combat.reaction.default",
            ["sourcePath"] = "adopters/hoomans/dialogue/event_reactions_combat/combat_reaction_default.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsCombat",
        ["namespace"] = "combat.reaction",
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
                                        "Good work. Keep watching the area.",
                                        "Threat's handled. Stay on your toes.",
                                        "Nice job. Don't relax just yet.",
                                        "Target down. Keep scanning the perimeter.",
                                        "Handled. Watch your surroundings.",
                                        "Good strike. Stay vigilant.",
                                        "That one's finished. Check the corners.",
                                        "Well done. Keep weapons at the ready.",
                                        "Clear here. Eyes on the shadows.",
                                        "Threat eliminated. Keep moving carefully.",
                                    },
                                    ["TL"] = {
                                        "Magandang trabaho. Patuloy na bantayan ang paligid.",
                                        "Naasikaso ang banta. Maging handa.",
                                        "Mahusay. Huwag munang magpakampante.",
                                        "Bagsak ang target. Patuloy na suriin ang paligid.",
                                        "Naasikaso na. Bantayan ang paligid mo.",
                                        "Magandang tama. Manatiling alerto.",
                                        "Tapos na ang isang 'yon. Tignan ang mga sulok.",
                                        "Magaling. Ihanda pa rin ang sandata.",
                                        "Malinis dito. Tumingin sa mga anino.",
                                        "Banta naalis na. Tuloy sa maingat na pagkilos.",
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
            ["responsePlanID"] = "combat.reaction.default",
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
                            ["fallback"] = "Good work. Keep watching the area.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.reaction.default.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/event_reactions_combat/combat_reaction_default.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Good work. Keep watching the area.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.reaction.default.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Good work. Keep watching the area.",
                        "Threat's handled. Stay on your toes.",
                        "Nice job. Don't relax just yet.",
                        "Target down. Keep scanning the perimeter.",
                        "Handled. Watch your surroundings.",
                        "Good strike. Stay vigilant.",
                        "That one's finished. Check the corners.",
                        "Well done. Keep weapons at the ready.",
                        "Clear here. Eyes on the shadows.",
                        "Threat eliminated. Keep moving carefully.",
                    },
                    ["TL"] = {
                        "Magandang trabaho. Patuloy na bantayan ang paligid.",
                        "Naasikaso ang banta. Maging handa.",
                        "Mahusay. Huwag munang magpakampante.",
                        "Bagsak ang target. Patuloy na suriin ang paligid.",
                        "Naasikaso na. Bantayan ang paligid mo.",
                        "Magandang tama. Manatiling alerto.",
                        "Tapos na ang isang 'yon. Tignan ang mga sulok.",
                        "Magaling. Ihanda pa rin ang sandata.",
                        "Malinis dito. Tumingin sa mga anino.",
                        "Banta naalis na. Tuloy sa maingat na pagkilos.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "event_reactions_combat",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.reaction.retreat",
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
                                ["fallback"] = "I need a moment before I can swing again.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.reaction.retreat.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I need a moment before I can swing again.",
                                        "Arms are heavy. Give me a second.",
                                        "Falling back! Need to recover stamina.",
                                        "Out of breath! Step back a bit.",
                                        "Can't keep swinging like this. Backing up.",
                                        "Give me space to breathe and reset.",
                                        "Too exhausted to strike. Pulling back.",
                                        "Need ten seconds to shake out my arms.",
                                        "Step back! I'm completely winded.",
                                        "Back up! Let me catch my breath.",
                                    },
                                    ["TL"] = {
                                        "Kailangan ko muna ng saglit bago makahataw ulit.",
                                        "Mabigat ang mga braso ko. Bigyan mo ako ng saglit.",
                                        "Aatras muna! Kailangang makabawi ng lakas.",
                                        "Hinihingal ako! Umatras muna nang kaunti.",
                                        "Hindi ko kayang tuloy-tuloy ang hataw. Aatras muna.",
                                        "Bigyan mo ako ng puwang para makahinga.",
                                        "Masyado akong pagod para humampas. Umuurong muna.",
                                        "Kailangan ko ng sampung segundo para ipagpag ang braso ko.",
                                        "Atras! Sagad na ang hingal ko.",
                                        "Umatras! Pahingahin mo muna ako.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.reaction",
            ["textRoles"] = {
                {
                    ["fallback"] = "I need a moment before I can swing again.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.reaction.retreat.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I need a moment before I can swing again.",
                            "Arms are heavy. Give me a second.",
                            "Falling back! Need to recover stamina.",
                            "Out of breath! Step back a bit.",
                            "Can't keep swinging like this. Backing up.",
                            "Give me space to breathe and reset.",
                            "Too exhausted to strike. Pulling back.",
                            "Need ten seconds to shake out my arms.",
                            "Step back! I'm completely winded.",
                            "Back up! Let me catch my breath.",
                        },
                        ["TL"] = {
                            "Kailangan ko muna ng saglit bago makahataw ulit.",
                            "Mabigat ang mga braso ko. Bigyan mo ako ng saglit.",
                            "Aatras muna! Kailangang makabawi ng lakas.",
                            "Hinihingal ako! Umatras muna nang kaunti.",
                            "Hindi ko kayang tuloy-tuloy ang hataw. Aatras muna.",
                            "Bigyan mo ako ng puwang para makahinga.",
                            "Masyado akong pagod para humampas. Umuurong muna.",
                            "Kailangan ko ng sampung segundo para ipagpag ang braso ko.",
                            "Atras! Sagad na ang hingal ko.",
                            "Umatras! Pahingahin mo muna ako.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.reaction.retreat",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "retreat",
            ["sourceId"] = "combat.reaction.retreat",
            ["sourcePath"] = "adopters/hoomans/dialogue/event_reactions_combat/combat_reaction_retreat.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsCombat",
        ["namespace"] = "combat.reaction",
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
                                        "I need a moment before I can swing again.",
                                        "Arms are heavy. Give me a second.",
                                        "Falling back! Need to recover stamina.",
                                        "Out of breath! Step back a bit.",
                                        "Can't keep swinging like this. Backing up.",
                                        "Give me space to breathe and reset.",
                                        "Too exhausted to strike. Pulling back.",
                                        "Need ten seconds to shake out my arms.",
                                        "Step back! I'm completely winded.",
                                        "Back up! Let me catch my breath.",
                                    },
                                    ["TL"] = {
                                        "Kailangan ko muna ng saglit bago makahataw ulit.",
                                        "Mabigat ang mga braso ko. Bigyan mo ako ng saglit.",
                                        "Aatras muna! Kailangang makabawi ng lakas.",
                                        "Hinihingal ako! Umatras muna nang kaunti.",
                                        "Hindi ko kayang tuloy-tuloy ang hataw. Aatras muna.",
                                        "Bigyan mo ako ng puwang para makahinga.",
                                        "Masyado akong pagod para humampas. Umuurong muna.",
                                        "Kailangan ko ng sampung segundo para ipagpag ang braso ko.",
                                        "Atras! Sagad na ang hingal ko.",
                                        "Umatras! Pahingahin mo muna ako.",
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
            ["responsePlanID"] = "combat.reaction.retreat",
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
                            ["fallback"] = "I need a moment before I can swing again.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.reaction.retreat.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/event_reactions_combat/combat_reaction_retreat.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I need a moment before I can swing again.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.reaction.retreat.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I need a moment before I can swing again.",
                        "Arms are heavy. Give me a second.",
                        "Falling back! Need to recover stamina.",
                        "Out of breath! Step back a bit.",
                        "Can't keep swinging like this. Backing up.",
                        "Give me space to breathe and reset.",
                        "Too exhausted to strike. Pulling back.",
                        "Need ten seconds to shake out my arms.",
                        "Step back! I'm completely winded.",
                        "Back up! Let me catch my breath.",
                    },
                    ["TL"] = {
                        "Kailangan ko muna ng saglit bago makahataw ulit.",
                        "Mabigat ang mga braso ko. Bigyan mo ako ng saglit.",
                        "Aatras muna! Kailangang makabawi ng lakas.",
                        "Hinihingal ako! Umatras muna nang kaunti.",
                        "Hindi ko kayang tuloy-tuloy ang hataw. Aatras muna.",
                        "Bigyan mo ako ng puwang para makahinga.",
                        "Masyado akong pagod para humampas. Umuurong muna.",
                        "Kailangan ko ng sampung segundo para ipagpag ang braso ko.",
                        "Atras! Sagad na ang hingal ko.",
                        "Umatras! Pahingahin mo muna ako.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "event_reactions_combat",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.reaction.threat",
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
                                ["fallback"] = "That threat is down. Stay alert.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.combat.reaction.threat.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "That threat is down. Stay alert.",
                                        "Threat neutralized. Don't drop your guard.",
                                        "Target eliminated. Keep watching.",
                                        "Danger's passed for now. Stay sharp.",
                                        "Handled that hazard. Eyes open.",
                                        "Threat's in the dirt. Scan the flanks.",
                                        "Threat ceased. Maintain alertness.",
                                        "Downed the contact. Watch your sector.",
                                        "No more threat from that one. Stay ready.",
                                        "Handled. Stay focused on remaining risks.",
                                    },
                                    ["TL"] = {
                                        "Bagsak na ang banta. Manatiling alerto.",
                                        "Naalis na ang banta. Huwag ibaba ang depensa.",
                                        "Target naalis na. Patuloy na magmatyag.",
                                        "Lumipas na ang panganib pansamantala. Maging handa.",
                                        "Nalutas ang panganib na 'yon. Buksan ang mata.",
                                        "Nasa lupa na ang banta. Suriin ang gilid.",
                                        "Tumigil na ang banta. Panatilihin ang pag-iingat.",
                                        "Naitumba ang kalaban. Bantayan ang parte mo.",
                                        "Wala nang panganib mula sa kanya. Maging handa.",
                                        "Naayos na. Tutukan ang iba pang panganib.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.reaction",
            ["textRoles"] = {
                {
                    ["fallback"] = "That threat is down. Stay alert.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.reaction.threat.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "That threat is down. Stay alert.",
                            "Threat neutralized. Don't drop your guard.",
                            "Target eliminated. Keep watching.",
                            "Danger's passed for now. Stay sharp.",
                            "Handled that hazard. Eyes open.",
                            "Threat's in the dirt. Scan the flanks.",
                            "Threat ceased. Maintain alertness.",
                            "Downed the contact. Watch your sector.",
                            "No more threat from that one. Stay ready.",
                            "Handled. Stay focused on remaining risks.",
                        },
                        ["TL"] = {
                            "Bagsak na ang banta. Manatiling alerto.",
                            "Naalis na ang banta. Huwag ibaba ang depensa.",
                            "Target naalis na. Patuloy na magmatyag.",
                            "Lumipas na ang panganib pansamantala. Maging handa.",
                            "Nalutas ang panganib na 'yon. Buksan ang mata.",
                            "Nasa lupa na ang banta. Suriin ang gilid.",
                            "Tumigil na ang banta. Panatilihin ang pag-iingat.",
                            "Naitumba ang kalaban. Bantayan ang parte mo.",
                            "Wala nang panganib mula sa kanya. Maging handa.",
                            "Naayos na. Tutukan ang iba pang panganib.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "combat.reaction.threat",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "threat",
            ["sourceId"] = "combat.reaction.threat",
            ["sourcePath"] = "adopters/hoomans/dialogue/event_reactions_combat/combat_reaction_threat.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/EventReactionsCombat",
        ["namespace"] = "combat.reaction",
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
                                        "That threat is down. Stay alert.",
                                        "Threat neutralized. Don't drop your guard.",
                                        "Target eliminated. Keep watching.",
                                        "Danger's passed for now. Stay sharp.",
                                        "Handled that hazard. Eyes open.",
                                        "Threat's in the dirt. Scan the flanks.",
                                        "Threat ceased. Maintain alertness.",
                                        "Downed the contact. Watch your sector.",
                                        "No more threat from that one. Stay ready.",
                                        "Handled. Stay focused on remaining risks.",
                                    },
                                    ["TL"] = {
                                        "Bagsak na ang banta. Manatiling alerto.",
                                        "Naalis na ang banta. Huwag ibaba ang depensa.",
                                        "Target naalis na. Patuloy na magmatyag.",
                                        "Lumipas na ang panganib pansamantala. Maging handa.",
                                        "Nalutas ang panganib na 'yon. Buksan ang mata.",
                                        "Nasa lupa na ang banta. Suriin ang gilid.",
                                        "Tumigil na ang banta. Panatilihin ang pag-iingat.",
                                        "Naitumba ang kalaban. Bantayan ang parte mo.",
                                        "Wala nang panganib mula sa kanya. Maging handa.",
                                        "Naayos na. Tutukan ang iba pang panganib.",
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
            ["responsePlanID"] = "combat.reaction.threat",
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
                            ["fallback"] = "That threat is down. Stay alert.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.reaction.threat.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/event_reactions_combat/combat_reaction_threat.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "That threat is down. Stay alert.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.reaction.threat.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "That threat is down. Stay alert.",
                        "Threat neutralized. Don't drop your guard.",
                        "Target eliminated. Keep watching.",
                        "Danger's passed for now. Stay sharp.",
                        "Handled that hazard. Eyes open.",
                        "Threat's in the dirt. Scan the flanks.",
                        "Threat ceased. Maintain alertness.",
                        "Downed the contact. Watch your sector.",
                        "No more threat from that one. Stay ready.",
                        "Handled. Stay focused on remaining risks.",
                    },
                    ["TL"] = {
                        "Bagsak na ang banta. Manatiling alerto.",
                        "Naalis na ang banta. Huwag ibaba ang depensa.",
                        "Target naalis na. Patuloy na magmatyag.",
                        "Lumipas na ang panganib pansamantala. Maging handa.",
                        "Nalutas ang panganib na 'yon. Buksan ang mata.",
                        "Nasa lupa na ang banta. Suriin ang gilid.",
                        "Tumigil na ang banta. Panatilihin ang pag-iingat.",
                        "Naitumba ang kalaban. Bantayan ang parte mo.",
                        "Wala nang panganib mula sa kanya. Maging handa.",
                        "Naayos na. Tutukan ang iba pang panganib.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
