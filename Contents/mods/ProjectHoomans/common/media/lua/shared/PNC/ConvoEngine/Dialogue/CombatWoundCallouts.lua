-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_wound_callouts",
        ["domainPath"] = "combat_wound_callouts",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.fighting.injured_callout",
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
                                ["fallback"] = "Blood is getting in my eyes, {addressee.name}! My {slot.wound.part} is torn open, keep them off me!",
                                ["id"] = "with_wounds_head_neck_critical",
                                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_head_neck_critical",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Watch my blind side, {addressee.name}, took an open cut to my {slot.wound.part}!",
                                ["id"] = "with_wounds_head_neck",
                                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_head_neck",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Holding my ribs together, {addressee.name}! Open wound on my {slot.wound.part}, don't let them close in!",
                                ["id"] = "with_wounds_torso_critical",
                                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_torso_critical",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Still standing, {addressee.name}, though my {slot.wound.part} is bleeding through my shirt!",
                                ["id"] = "with_wounds_torso",
                                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_torso",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "My hip and {slot.wound.part} are torn open, {addressee.name}! I can barely pivot, hold my flank!",
                                ["id"] = "with_wounds_pelvis_groin_severe",
                                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_pelvis_groin_severe",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Caught an open gash across my {slot.wound.part}, {addressee.name}, can't twist fast so watch my side!",
                                ["id"] = "with_wounds_pelvis_groin",
                                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_pelvis_groin",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "My {slot.wound.part} is bleeding bad, {addressee.name}, weapon feels heavy but I'm not stopping!",
                                ["id"] = "with_wounds_upper_limb_severe",
                                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_upper_limb_severe",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Got an open wound on my {slot.wound.part}, {addressee.name}, still fighting though!",
                                ["id"] = "with_wounds_upper_limb",
                                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_upper_limb",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "My {slot.wound.part} is giving way, {addressee.name}! Can't sprint with this bleeding wound, hold the line!",
                                ["id"] = "with_wounds_lower_limb_severe",
                                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_lower_limb_severe",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Footwork's sluggish with this open hit on my {slot.wound.part}, {addressee.name}, stay tight with me!",
                                ["id"] = "with_wounds_lower_limb",
                                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_lower_limb",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Still fighting through a fresh {slot.wound.label} on my {slot.wound.part}, {addressee.name}, we got this.",
                                ["id"] = "with_wounds_minor",
                                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_minor",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "The dressing on my {slot.wound.part} is soaked filthy, {addressee.name}! I need a clean wrap once we clear!",
                                ["id"] = "with_wounds_dirty_bandage",
                                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_dirty_bandage",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Bandages around my {slot.wound.part} are barely holding, {addressee.name}, help me finish these fast!",
                                ["id"] = "patched_up_head_neck_severe",
                                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_head_neck_severe",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Dressing on my {slot.wound.part} is holding for now, {addressee.name}, keep fighting!",
                                ["id"] = "patched_up_head_neck",
                                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_head_neck",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Wraps across my {slot.wound.part} are soaking red, {addressee.name}, help me drop the rest quick!",
                                ["id"] = "patched_up_torso_severe",
                                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_torso_severe",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Bandage on my {slot.wound.part} is holding, {addressee.name}, breathing hurts a bit but I'm steady.",
                                ["id"] = "patched_up_torso",
                                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_torso",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Bound my {slot.wound.part} as tight as I could, {addressee.name}, can't lunge far so keep them in front!",
                                ["id"] = "patched_up_pelvis_groin_severe",
                                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_pelvis_groin_severe",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Got my {slot.wound.part} wrapped up, {addressee.name}, stride's short but I'm holding the line!",
                                ["id"] = "patched_up_pelvis_groin",
                                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_pelvis_groin",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Wrap on my {slot.wound.part} is tight, {addressee.name}, hurts like hell to swing but I'll keep swinging!",
                                ["id"] = "patched_up_upper_limb_severe",
                                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_upper_limb_severe",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Bandaged my {slot.wound.part} and I'm still fighting, {addressee.name}, watch the left!",
                                ["id"] = "patched_up_upper_limb",
                                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_upper_limb",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Splints and wraps on my {slot.wound.part} are taking all I've got, {addressee.name}, stay on my shoulder!",
                                ["id"] = "patched_up_lower_limb_severe",
                                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_lower_limb_severe",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Got my {slot.wound.part} patched up, {addressee.name}, limping a bit but still standing my ground!",
                                ["id"] = "patched_up_lower_limb",
                                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_lower_limb",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Already patched that scrape on my {slot.wound.part}, {addressee.name}, ready to clear the rest.",
                                ["id"] = "patched_up_minor",
                                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_minor",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "I'm bleeding from this bite on my {slot.wound.part}, {addressee.name}! I'll fight till I drop, keep them off me!",
                                ["id"] = "with_wounds_bite_lethal",
                                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_bite_lethal",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Teeth tore my {slot.wound.part}, {addressee.name}! I don't feel feverish yet, just help me fight clear so I can wrap it!",
                                ["id"] = "with_wounds_bite_possible_exposure",
                                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_bite_possible_exposure",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Fever's burning and my {slot.wound.part} bite is still bleeding, {addressee.name}! Let me take these dead down with me!",
                                ["id"] = "with_wounds_bite_confirmed_symptomatic",
                                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_bite_confirmed_symptomatic",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Fighting with an open bite on my {slot.wound.part}, {addressee.name}, hurts awful but saliva won't turn me!",
                                ["id"] = "with_wounds_bite_non_transmissible",
                                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_bite_non_transmissible",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Wrapped the bite on my {slot.wound.part}, {addressee.name}, buying every minute I can to help you clear out!",
                                ["id"] = "patched_up_bite_lethal",
                                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_bite_lethal",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Wrapped the bite on my {slot.wound.part} tight, {addressee.name}, praying the fever doesn't come while we clear this!",
                                ["id"] = "patched_up_bite_possible_exposure",
                                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_bite_possible_exposure",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Bite on my {slot.wound.part} is wrapped, {addressee.name}, but the fever's setting in—let me hold the front for you!",
                                ["id"] = "patched_up_bite_confirmed_symptomatic",
                                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_bite_confirmed_symptomatic",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Got the bite on my {slot.wound.part} wrapped tight, {addressee.name}, sore as hell but I'm not turning!",
                                ["id"] = "patched_up_bite_non_transmissible",
                                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_bite_non_transmissible",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Still fighting with a hit on my {slot.wound.part}, {addressee.name}, keep our spacing tight!",
                                ["id"] = "default",
                                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.fighting",
            ["slots"] = {
                ["wound"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "entity.item",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "Blood is getting in my eyes, {addressee.name}! My {slot.wound.part} is torn open, keep them off me!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_head_neck_critical",
                    ["variantID"] = "with_wounds_head_neck_critical",
                },
                {
                    ["fallback"] = "Watch my blind side, {addressee.name}, took an open cut to my {slot.wound.part}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_head_neck",
                    ["variantID"] = "with_wounds_head_neck",
                },
                {
                    ["fallback"] = "Holding my ribs together, {addressee.name}! Open wound on my {slot.wound.part}, don't let them close in!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_torso_critical",
                    ["variantID"] = "with_wounds_torso_critical",
                },
                {
                    ["fallback"] = "Still standing, {addressee.name}, though my {slot.wound.part} is bleeding through my shirt!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_torso",
                    ["variantID"] = "with_wounds_torso",
                },
                {
                    ["fallback"] = "My hip and {slot.wound.part} are torn open, {addressee.name}! I can barely pivot, hold my flank!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_pelvis_groin_severe",
                    ["variantID"] = "with_wounds_pelvis_groin_severe",
                },
                {
                    ["fallback"] = "Caught an open gash across my {slot.wound.part}, {addressee.name}, can't twist fast so watch my side!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_pelvis_groin",
                    ["variantID"] = "with_wounds_pelvis_groin",
                },
                {
                    ["fallback"] = "My {slot.wound.part} is bleeding bad, {addressee.name}, weapon feels heavy but I'm not stopping!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_upper_limb_severe",
                    ["variantID"] = "with_wounds_upper_limb_severe",
                },
                {
                    ["fallback"] = "Got an open wound on my {slot.wound.part}, {addressee.name}, still fighting though!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_upper_limb",
                    ["variantID"] = "with_wounds_upper_limb",
                },
                {
                    ["fallback"] = "My {slot.wound.part} is giving way, {addressee.name}! Can't sprint with this bleeding wound, hold the line!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_lower_limb_severe",
                    ["variantID"] = "with_wounds_lower_limb_severe",
                },
                {
                    ["fallback"] = "Footwork's sluggish with this open hit on my {slot.wound.part}, {addressee.name}, stay tight with me!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_lower_limb",
                    ["variantID"] = "with_wounds_lower_limb",
                },
                {
                    ["fallback"] = "Still fighting through a fresh {slot.wound.label} on my {slot.wound.part}, {addressee.name}, we got this.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_minor",
                    ["variantID"] = "with_wounds_minor",
                },
                {
                    ["fallback"] = "The dressing on my {slot.wound.part} is soaked filthy, {addressee.name}! I need a clean wrap once we clear!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_dirty_bandage",
                    ["variantID"] = "with_wounds_dirty_bandage",
                },
                {
                    ["fallback"] = "Bandages around my {slot.wound.part} are barely holding, {addressee.name}, help me finish these fast!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_head_neck_severe",
                    ["variantID"] = "patched_up_head_neck_severe",
                },
                {
                    ["fallback"] = "Dressing on my {slot.wound.part} is holding for now, {addressee.name}, keep fighting!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_head_neck",
                    ["variantID"] = "patched_up_head_neck",
                },
                {
                    ["fallback"] = "Wraps across my {slot.wound.part} are soaking red, {addressee.name}, help me drop the rest quick!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_torso_severe",
                    ["variantID"] = "patched_up_torso_severe",
                },
                {
                    ["fallback"] = "Bandage on my {slot.wound.part} is holding, {addressee.name}, breathing hurts a bit but I'm steady.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_torso",
                    ["variantID"] = "patched_up_torso",
                },
                {
                    ["fallback"] = "Bound my {slot.wound.part} as tight as I could, {addressee.name}, can't lunge far so keep them in front!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_pelvis_groin_severe",
                    ["variantID"] = "patched_up_pelvis_groin_severe",
                },
                {
                    ["fallback"] = "Got my {slot.wound.part} wrapped up, {addressee.name}, stride's short but I'm holding the line!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_pelvis_groin",
                    ["variantID"] = "patched_up_pelvis_groin",
                },
                {
                    ["fallback"] = "Wrap on my {slot.wound.part} is tight, {addressee.name}, hurts like hell to swing but I'll keep swinging!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_upper_limb_severe",
                    ["variantID"] = "patched_up_upper_limb_severe",
                },
                {
                    ["fallback"] = "Bandaged my {slot.wound.part} and I'm still fighting, {addressee.name}, watch the left!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_upper_limb",
                    ["variantID"] = "patched_up_upper_limb",
                },
                {
                    ["fallback"] = "Splints and wraps on my {slot.wound.part} are taking all I've got, {addressee.name}, stay on my shoulder!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_lower_limb_severe",
                    ["variantID"] = "patched_up_lower_limb_severe",
                },
                {
                    ["fallback"] = "Got my {slot.wound.part} patched up, {addressee.name}, limping a bit but still standing my ground!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_lower_limb",
                    ["variantID"] = "patched_up_lower_limb",
                },
                {
                    ["fallback"] = "Already patched that scrape on my {slot.wound.part}, {addressee.name}, ready to clear the rest.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_minor",
                    ["variantID"] = "patched_up_minor",
                },
                {
                    ["fallback"] = "I'm bleeding from this bite on my {slot.wound.part}, {addressee.name}! I'll fight till I drop, keep them off me!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_bite_lethal",
                    ["variantID"] = "with_wounds_bite_lethal",
                },
                {
                    ["fallback"] = "Teeth tore my {slot.wound.part}, {addressee.name}! I don't feel feverish yet, just help me fight clear so I can wrap it!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_bite_possible_exposure",
                    ["variantID"] = "with_wounds_bite_possible_exposure",
                },
                {
                    ["fallback"] = "Fever's burning and my {slot.wound.part} bite is still bleeding, {addressee.name}! Let me take these dead down with me!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_bite_confirmed_symptomatic",
                    ["variantID"] = "with_wounds_bite_confirmed_symptomatic",
                },
                {
                    ["fallback"] = "Fighting with an open bite on my {slot.wound.part}, {addressee.name}, hurts awful but saliva won't turn me!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_bite_non_transmissible",
                    ["variantID"] = "with_wounds_bite_non_transmissible",
                },
                {
                    ["fallback"] = "Wrapped the bite on my {slot.wound.part}, {addressee.name}, buying every minute I can to help you clear out!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_bite_lethal",
                    ["variantID"] = "patched_up_bite_lethal",
                },
                {
                    ["fallback"] = "Wrapped the bite on my {slot.wound.part} tight, {addressee.name}, praying the fever doesn't come while we clear this!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_bite_possible_exposure",
                    ["variantID"] = "patched_up_bite_possible_exposure",
                },
                {
                    ["fallback"] = "Bite on my {slot.wound.part} is wrapped, {addressee.name}, but the fever's setting in—let me hold the front for you!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_bite_confirmed_symptomatic",
                    ["variantID"] = "patched_up_bite_confirmed_symptomatic",
                },
                {
                    ["fallback"] = "Got the bite on my {slot.wound.part} wrapped tight, {addressee.name}, sore as hell but I'm not turning!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_bite_non_transmissible",
                    ["variantID"] = "patched_up_bite_non_transmissible",
                },
                {
                    ["fallback"] = "Still fighting with a hit on my {slot.wound.part}, {addressee.name}, keep our spacing tight!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.fighting.injured_callout.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "combat.fighting.injured_callout",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "injured_callout",
            ["sourceId"] = "combat.fighting.injured_callout",
            ["sourcePath"] = "dialogue/combat_wound_callouts/combat_fighting_injured_callout.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatWoundCallouts",
        ["namespace"] = "combat.fighting",
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
            ["domains"] = {
                {
                    ["domain"] = "combat",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["events"] = {
                {
                    ["id"] = "combat_injury_callout",
                    ["kind"] = "combat_event",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:event_reactions",
                ["contentOwner"] = "projecthoomans.dialogue_content.events",
                ["responseAct"] = "WARN",
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
                                ["fallback"] = "Blood is getting in my eyes, {addressee.name}! My {slot.wound.part} is torn open, keep them off me!",
                                ["id"] = "with_wounds_head_neck_critical",
                            },
                            {
                                ["fallback"] = "Watch my blind side, {addressee.name}, took an open cut to my {slot.wound.part}!",
                                ["id"] = "with_wounds_head_neck",
                            },
                            {
                                ["fallback"] = "Holding my ribs together, {addressee.name}! Open wound on my {slot.wound.part}, don't let them close in!",
                                ["id"] = "with_wounds_torso_critical",
                            },
                            {
                                ["fallback"] = "Still standing, {addressee.name}, though my {slot.wound.part} is bleeding through my shirt!",
                                ["id"] = "with_wounds_torso",
                            },
                            {
                                ["fallback"] = "My hip and {slot.wound.part} are torn open, {addressee.name}! I can barely pivot, hold my flank!",
                                ["id"] = "with_wounds_pelvis_groin_severe",
                            },
                            {
                                ["fallback"] = "Caught an open gash across my {slot.wound.part}, {addressee.name}, can't twist fast so watch my side!",
                                ["id"] = "with_wounds_pelvis_groin",
                            },
                            {
                                ["fallback"] = "My {slot.wound.part} is bleeding bad, {addressee.name}, weapon feels heavy but I'm not stopping!",
                                ["id"] = "with_wounds_upper_limb_severe",
                            },
                            {
                                ["fallback"] = "Got an open wound on my {slot.wound.part}, {addressee.name}, still fighting though!",
                                ["id"] = "with_wounds_upper_limb",
                            },
                            {
                                ["fallback"] = "My {slot.wound.part} is giving way, {addressee.name}! Can't sprint with this bleeding wound, hold the line!",
                                ["id"] = "with_wounds_lower_limb_severe",
                            },
                            {
                                ["fallback"] = "Footwork's sluggish with this open hit on my {slot.wound.part}, {addressee.name}, stay tight with me!",
                                ["id"] = "with_wounds_lower_limb",
                            },
                            {
                                ["fallback"] = "Still fighting through a fresh {slot.wound.label} on my {slot.wound.part}, {addressee.name}, we got this.",
                                ["id"] = "with_wounds_minor",
                            },
                            {
                                ["fallback"] = "The dressing on my {slot.wound.part} is soaked filthy, {addressee.name}! I need a clean wrap once we clear!",
                                ["id"] = "with_wounds_dirty_bandage",
                            },
                            {
                                ["fallback"] = "Bandages around my {slot.wound.part} are barely holding, {addressee.name}, help me finish these fast!",
                                ["id"] = "patched_up_head_neck_severe",
                            },
                            {
                                ["fallback"] = "Dressing on my {slot.wound.part} is holding for now, {addressee.name}, keep fighting!",
                                ["id"] = "patched_up_head_neck",
                            },
                            {
                                ["fallback"] = "Wraps across my {slot.wound.part} are soaking red, {addressee.name}, help me drop the rest quick!",
                                ["id"] = "patched_up_torso_severe",
                            },
                            {
                                ["fallback"] = "Bandage on my {slot.wound.part} is holding, {addressee.name}, breathing hurts a bit but I'm steady.",
                                ["id"] = "patched_up_torso",
                            },
                            {
                                ["fallback"] = "Bound my {slot.wound.part} as tight as I could, {addressee.name}, can't lunge far so keep them in front!",
                                ["id"] = "patched_up_pelvis_groin_severe",
                            },
                            {
                                ["fallback"] = "Got my {slot.wound.part} wrapped up, {addressee.name}, stride's short but I'm holding the line!",
                                ["id"] = "patched_up_pelvis_groin",
                            },
                            {
                                ["fallback"] = "Wrap on my {slot.wound.part} is tight, {addressee.name}, hurts like hell to swing but I'll keep swinging!",
                                ["id"] = "patched_up_upper_limb_severe",
                            },
                            {
                                ["fallback"] = "Bandaged my {slot.wound.part} and I'm still fighting, {addressee.name}, watch the left!",
                                ["id"] = "patched_up_upper_limb",
                            },
                            {
                                ["fallback"] = "Splints and wraps on my {slot.wound.part} are taking all I've got, {addressee.name}, stay on my shoulder!",
                                ["id"] = "patched_up_lower_limb_severe",
                            },
                            {
                                ["fallback"] = "Got my {slot.wound.part} patched up, {addressee.name}, limping a bit but still standing my ground!",
                                ["id"] = "patched_up_lower_limb",
                            },
                            {
                                ["fallback"] = "Already patched that scrape on my {slot.wound.part}, {addressee.name}, ready to clear the rest.",
                                ["id"] = "patched_up_minor",
                            },
                            {
                                ["fallback"] = "I'm bleeding from this bite on my {slot.wound.part}, {addressee.name}! I'll fight till I drop, keep them off me!",
                                ["id"] = "with_wounds_bite_lethal",
                            },
                            {
                                ["fallback"] = "Teeth tore my {slot.wound.part}, {addressee.name}! I don't feel feverish yet, just help me fight clear so I can wrap it!",
                                ["id"] = "with_wounds_bite_possible_exposure",
                            },
                            {
                                ["fallback"] = "Fever's burning and my {slot.wound.part} bite is still bleeding, {addressee.name}! Let me take these dead down with me!",
                                ["id"] = "with_wounds_bite_confirmed_symptomatic",
                            },
                            {
                                ["fallback"] = "Fighting with an open bite on my {slot.wound.part}, {addressee.name}, hurts awful but saliva won't turn me!",
                                ["id"] = "with_wounds_bite_non_transmissible",
                            },
                            {
                                ["fallback"] = "Wrapped the bite on my {slot.wound.part}, {addressee.name}, buying every minute I can to help you clear out!",
                                ["id"] = "patched_up_bite_lethal",
                            },
                            {
                                ["fallback"] = "Wrapped the bite on my {slot.wound.part} tight, {addressee.name}, praying the fever doesn't come while we clear this!",
                                ["id"] = "patched_up_bite_possible_exposure",
                            },
                            {
                                ["fallback"] = "Bite on my {slot.wound.part} is wrapped, {addressee.name}, but the fever's setting in—let me hold the front for you!",
                                ["id"] = "patched_up_bite_confirmed_symptomatic",
                            },
                            {
                                ["fallback"] = "Got the bite on my {slot.wound.part} wrapped tight, {addressee.name}, sore as hell but I'm not turning!",
                                ["id"] = "patched_up_bite_non_transmissible",
                            },
                            {
                                ["fallback"] = "Still fighting with a hit on my {slot.wound.part}, {addressee.name}, keep our spacing tight!",
                                ["id"] = "default",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "combat",
                    ["id"] = "combat_injury",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "WARN",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "combat.fighting.injured_callout",
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
                            ["fallback"] = "Blood is getting in my eyes, {addressee.name}! My {slot.wound.part} is torn open, keep them off me!",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.fighting.injured_callout.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
            ["witness"] = {
                ["cardinality"] = "BOUNDED_MANY",
                ["kinds"] = {
                    "actor",
                },
                ["max"] = 3,
                ["min"] = 0,
                ["role"] = "witness",
            },
        },
        ["slots"] = {
            ["wound"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.item",
            },
        },
        ["sourceShard"] = "dialogue/combat_wound_callouts/combat_fighting_injured_callout.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Blood is getting in my eyes, {addressee.name}! My {slot.wound.part} is torn open, keep them off me!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_head_neck_critical",
                ["variantID"] = "with_wounds_head_neck_critical",
            },
            {
                ["fallback"] = "Watch my blind side, {addressee.name}, took an open cut to my {slot.wound.part}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_head_neck",
                ["variantID"] = "with_wounds_head_neck",
            },
            {
                ["fallback"] = "Holding my ribs together, {addressee.name}! Open wound on my {slot.wound.part}, don't let them close in!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_torso_critical",
                ["variantID"] = "with_wounds_torso_critical",
            },
            {
                ["fallback"] = "Still standing, {addressee.name}, though my {slot.wound.part} is bleeding through my shirt!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_torso",
                ["variantID"] = "with_wounds_torso",
            },
            {
                ["fallback"] = "My hip and {slot.wound.part} are torn open, {addressee.name}! I can barely pivot, hold my flank!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_pelvis_groin_severe",
                ["variantID"] = "with_wounds_pelvis_groin_severe",
            },
            {
                ["fallback"] = "Caught an open gash across my {slot.wound.part}, {addressee.name}, can't twist fast so watch my side!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_pelvis_groin",
                ["variantID"] = "with_wounds_pelvis_groin",
            },
            {
                ["fallback"] = "My {slot.wound.part} is bleeding bad, {addressee.name}, weapon feels heavy but I'm not stopping!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_upper_limb_severe",
                ["variantID"] = "with_wounds_upper_limb_severe",
            },
            {
                ["fallback"] = "Got an open wound on my {slot.wound.part}, {addressee.name}, still fighting though!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_upper_limb",
                ["variantID"] = "with_wounds_upper_limb",
            },
            {
                ["fallback"] = "My {slot.wound.part} is giving way, {addressee.name}! Can't sprint with this bleeding wound, hold the line!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_lower_limb_severe",
                ["variantID"] = "with_wounds_lower_limb_severe",
            },
            {
                ["fallback"] = "Footwork's sluggish with this open hit on my {slot.wound.part}, {addressee.name}, stay tight with me!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_lower_limb",
                ["variantID"] = "with_wounds_lower_limb",
            },
            {
                ["fallback"] = "Still fighting through a fresh {slot.wound.label} on my {slot.wound.part}, {addressee.name}, we got this.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_minor",
                ["variantID"] = "with_wounds_minor",
            },
            {
                ["fallback"] = "The dressing on my {slot.wound.part} is soaked filthy, {addressee.name}! I need a clean wrap once we clear!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_dirty_bandage",
                ["variantID"] = "with_wounds_dirty_bandage",
            },
            {
                ["fallback"] = "Bandages around my {slot.wound.part} are barely holding, {addressee.name}, help me finish these fast!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_head_neck_severe",
                ["variantID"] = "patched_up_head_neck_severe",
            },
            {
                ["fallback"] = "Dressing on my {slot.wound.part} is holding for now, {addressee.name}, keep fighting!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_head_neck",
                ["variantID"] = "patched_up_head_neck",
            },
            {
                ["fallback"] = "Wraps across my {slot.wound.part} are soaking red, {addressee.name}, help me drop the rest quick!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_torso_severe",
                ["variantID"] = "patched_up_torso_severe",
            },
            {
                ["fallback"] = "Bandage on my {slot.wound.part} is holding, {addressee.name}, breathing hurts a bit but I'm steady.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_torso",
                ["variantID"] = "patched_up_torso",
            },
            {
                ["fallback"] = "Bound my {slot.wound.part} as tight as I could, {addressee.name}, can't lunge far so keep them in front!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_pelvis_groin_severe",
                ["variantID"] = "patched_up_pelvis_groin_severe",
            },
            {
                ["fallback"] = "Got my {slot.wound.part} wrapped up, {addressee.name}, stride's short but I'm holding the line!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_pelvis_groin",
                ["variantID"] = "patched_up_pelvis_groin",
            },
            {
                ["fallback"] = "Wrap on my {slot.wound.part} is tight, {addressee.name}, hurts like hell to swing but I'll keep swinging!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_upper_limb_severe",
                ["variantID"] = "patched_up_upper_limb_severe",
            },
            {
                ["fallback"] = "Bandaged my {slot.wound.part} and I'm still fighting, {addressee.name}, watch the left!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_upper_limb",
                ["variantID"] = "patched_up_upper_limb",
            },
            {
                ["fallback"] = "Splints and wraps on my {slot.wound.part} are taking all I've got, {addressee.name}, stay on my shoulder!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_lower_limb_severe",
                ["variantID"] = "patched_up_lower_limb_severe",
            },
            {
                ["fallback"] = "Got my {slot.wound.part} patched up, {addressee.name}, limping a bit but still standing my ground!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_lower_limb",
                ["variantID"] = "patched_up_lower_limb",
            },
            {
                ["fallback"] = "Already patched that scrape on my {slot.wound.part}, {addressee.name}, ready to clear the rest.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_minor",
                ["variantID"] = "patched_up_minor",
            },
            {
                ["fallback"] = "I'm bleeding from this bite on my {slot.wound.part}, {addressee.name}! I'll fight till I drop, keep them off me!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_bite_lethal",
                ["variantID"] = "with_wounds_bite_lethal",
            },
            {
                ["fallback"] = "Teeth tore my {slot.wound.part}, {addressee.name}! I don't feel feverish yet, just help me fight clear so I can wrap it!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_bite_possible_exposure",
                ["variantID"] = "with_wounds_bite_possible_exposure",
            },
            {
                ["fallback"] = "Fever's burning and my {slot.wound.part} bite is still bleeding, {addressee.name}! Let me take these dead down with me!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_bite_confirmed_symptomatic",
                ["variantID"] = "with_wounds_bite_confirmed_symptomatic",
            },
            {
                ["fallback"] = "Fighting with an open bite on my {slot.wound.part}, {addressee.name}, hurts awful but saliva won't turn me!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.with_wounds_bite_non_transmissible",
                ["variantID"] = "with_wounds_bite_non_transmissible",
            },
            {
                ["fallback"] = "Wrapped the bite on my {slot.wound.part}, {addressee.name}, buying every minute I can to help you clear out!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_bite_lethal",
                ["variantID"] = "patched_up_bite_lethal",
            },
            {
                ["fallback"] = "Wrapped the bite on my {slot.wound.part} tight, {addressee.name}, praying the fever doesn't come while we clear this!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_bite_possible_exposure",
                ["variantID"] = "patched_up_bite_possible_exposure",
            },
            {
                ["fallback"] = "Bite on my {slot.wound.part} is wrapped, {addressee.name}, but the fever's setting in—let me hold the front for you!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_bite_confirmed_symptomatic",
                ["variantID"] = "patched_up_bite_confirmed_symptomatic",
            },
            {
                ["fallback"] = "Got the bite on my {slot.wound.part} wrapped tight, {addressee.name}, sore as hell but I'm not turning!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_bite_non_transmissible",
                ["variantID"] = "patched_up_bite_non_transmissible",
            },
            {
                ["fallback"] = "Still fighting with a hit on my {slot.wound.part}, {addressee.name}, keep our spacing tight!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_wound_callouts",
        ["domainPath"] = "combat_wound_callouts",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.injury.triage_exchange",
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
                                ["fallback"] = "Still holding my ground, {addressee.name}, caught a hit and keeping eyes forward.",
                                ["id"] = "default",
                                ["templateID"] = "convo.combat.injury.triage_exchange.say.1.default",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.injury",
            ["replies"] = {
                ["bite_non_lethal_stabilized"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "wellbeing.needs.checkin",
                        },
                    },
                    ["outcome"] = "bite_non_lethal_stabilized",
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
                                        ["fallback"] = "Thank god saliva doesn't carry it here, {addressee.name}. Still stings awful, wrapping it tight now.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.combat.injury.triage_exchange.reply.bite_non_lethal_stabilized.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["bite_psychopath_threatened"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "social.conflict.mediate_exchange",
                        },
                    },
                    ["outcome"] = "bite_psychopath_threatened",
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
                                        ["fallback"] = "Keep that barrel down, {addressee.name}! We finish clearing the dead before anyone talks about executions.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.combat.injury.triage_exchange.reply.bite_psychopath_threatened.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["bite_quarantined"] = {
                    ["outcome"] = "bite_quarantined",
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
                                        ["fallback"] = "I know the rules, {addressee.name}. Help me clear the stragglers and I'll stay apart from the group.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.combat.injury.triage_exchange.reply.bite_quarantined.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["covered_for_treatment"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "wellbeing.needs.checkin",
                        },
                    },
                    ["outcome"] = "covered_for_treatment",
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
                                        ["fallback"] = "Thanks, {addressee.name}! Keep them off my back while I tie off this open bleed.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.combat.injury.triage_exchange.reply.covered_for_treatment.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["ordered_fallback"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "wellbeing.needs.checkin",
                        },
                    },
                    ["outcome"] = "ordered_fallback",
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
                                        ["fallback"] = "Alright, backing up two steps behind you, {addressee.name}. Cover me while I catch my breath!",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.combat.injury.triage_exchange.reply.ordered_fallback.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["patched_push_on"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "combat.aftermath.debrief_exchange",
                        },
                    },
                    ["outcome"] = "patched_push_on",
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
                                        ["fallback"] = "Dressings are tight, {addressee.name}. Stay on my side and we'll sweep the rest of them.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.combat.injury.triage_exchange.reply.patched_push_on.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["reassured_bond"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "combat.aftermath.debrief_exchange",
                        },
                    },
                    ["outcome"] = "reassured_bond",
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
                                        ["fallback"] = "Heard you loud and clear, {addressee.name}. Still breathing, still swinging beside you.",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.combat.injury.triage_exchange.reply.reassured_bond.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["refused"] = {
                    ["outcome"] = "refused",
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
                                        ["fallback"] = "Save the talk for when there aren't teeth snapping in our faces!",
                                        ["id"] = "default",
                                        ["templateID"] = "convo.combat.injury.triage_exchange.reply.refused.say.1.default",
                                        ["textRole"] = "response",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "Still holding my ground, {addressee.name}, caught a hit and keeping eyes forward.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.injury.triage_exchange.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Thank god saliva doesn't carry it here, {addressee.name}. Still stings awful, wrapping it tight now.",
                    ["outcome"] = "bite_non_lethal_stabilized",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.combat.injury.triage_exchange.reply.bite_non_lethal_stabilized.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Keep that barrel down, {addressee.name}! We finish clearing the dead before anyone talks about executions.",
                    ["outcome"] = "bite_psychopath_threatened",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.combat.injury.triage_exchange.reply.bite_psychopath_threatened.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "I know the rules, {addressee.name}. Help me clear the stragglers and I'll stay apart from the group.",
                    ["outcome"] = "bite_quarantined",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.combat.injury.triage_exchange.reply.bite_quarantined.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Thanks, {addressee.name}! Keep them off my back while I tie off this open bleed.",
                    ["outcome"] = "covered_for_treatment",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.combat.injury.triage_exchange.reply.covered_for_treatment.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Alright, backing up two steps behind you, {addressee.name}. Cover me while I catch my breath!",
                    ["outcome"] = "ordered_fallback",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.combat.injury.triage_exchange.reply.ordered_fallback.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Dressings are tight, {addressee.name}. Stay on my side and we'll sweep the rest of them.",
                    ["outcome"] = "patched_push_on",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.combat.injury.triage_exchange.reply.patched_push_on.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Heard you loud and clear, {addressee.name}. Still breathing, still swinging beside you.",
                    ["outcome"] = "reassured_bond",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.combat.injury.triage_exchange.reply.reassured_bond.say.1.default",
                    ["variantID"] = "default",
                },
                {
                    ["fallback"] = "Save the talk for when there aren't teeth snapping in our faces!",
                    ["outcome"] = "refused",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.combat.injury.triage_exchange.reply.refused.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "combat.injury.triage_exchange",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "triage_exchange",
            ["sourceId"] = "combat.injury.triage_exchange",
            ["sourcePath"] = "dialogue/combat_wound_callouts/combat_injury_interactive_exchange.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatWoundCallouts",
        ["namespace"] = "combat.injury",
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
            ["closure"] = {
                ["closureClass"] = "resolved_episode",
                ["episodeId"] = "combat_injury_triage_exchange",
            },
            ["domains"] = {
                {
                    ["domain"] = "combat",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["inputPolicy"] = "typed_parity",
            ["metadata"] = {
                ["flow"] = {
                    ["constraints"] = {
                        ["all"] = {
                            {
                                ["op"] = "not_in",
                                ["path"] = "npcState.activeBehavior",
                                ["values"] = {
                                    "hostile",
                                    "dead",
                                },
                            },
                            {
                                ["op"] = "not_in",
                                ["path"] = "npcState.healthState",
                                ["values"] = {
                                    "dead",
                                    "incapacitated",
                                },
                            },
                            {
                                ["op"] = "neq",
                                ["path"] = "roles.hostile",
                                ["value"] = true,
                            },
                        },
                    },
                    ["id"] = "combat.injury.triage_exchange",
                    ["initial"] = "injury_report_open",
                    ["nodes"] = {
                        ["assess_wound_location"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["subject"] = "COMBAT_INJURY",
                                },
                                {
                                    ["intent"] = "AGREE",
                                    ["speechAct"] = "AGREE",
                                    ["subject"] = "COMBAT_INJURY",
                                },
                                {
                                    ["intent"] = "CLARIFY",
                                    ["speechAct"] = "CLARIFY",
                                    ["stateValue"] = "squad_check",
                                    ["subject"] = "COMBAT_INJURY",
                                },
                                {
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["stateValue"] = "bite_check",
                                    ["subject"] = "COMBAT_INJURY",
                                },
                                {
                                    ["intent"] = "REFUSE",
                                    ["speechAct"] = "REFUSE",
                                },
                            },
                            ["branchOffers"] = {
                                {
                                    ["constraints"] = {
                                        ["op"] = "eq",
                                        ["path"] = "npcState.hasOpenWounds",
                                        ["value"] = true,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "INFORM",
                                        ["speechAct"] = "INFORM",
                                        ["stateValue"] = "covered_for_treatment",
                                        ["subject"] = "COMBAT_INJURY",
                                    },
                                    ["id"] = "combat.injury.patch_with_wounds",
                                    ["labelFallback"] = "Press them to bandage open wounds",
                                    ["labelKey"] = "UI_PNC_CombatInjury_PatchOpen_Label",
                                    ["utteranceFallback"] = "It's still soaked with fresh blood. Step back two paces and wrap it!",
                                    ["utteranceKey"] = "UI_PNC_CombatInjury_PatchOpen_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "AGREE",
                                        ["speechAct"] = "AGREE",
                                        ["stateValue"] = "patched_push_on",
                                        ["subject"] = "COMBAT_INJURY",
                                    },
                                    ["id"] = "combat.injury.hold_patched_line",
                                    ["labelFallback"] = "Check if the bandage is holding",
                                    ["labelKey"] = "UI_PNC_CombatInjury_HoldPatched_Label",
                                    ["utteranceFallback"] = "If that dressing holds, swing steady and let me take the point.",
                                    ["utteranceKey"] = "UI_PNC_CombatInjury_HoldPatched_Utterance",
                                },
                                {
                                    ["constraints"] = {
                                        ["op"] = "eq",
                                        ["path"] = "scene.hasThirdPartyWitness",
                                        ["value"] = true,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "CLARIFY",
                                        ["speechAct"] = "CLARIFY",
                                        ["stateValue"] = "squad_check",
                                        ["subject"] = "COMBAT_INJURY",
                                    },
                                    ["id"] = "combat.injury.pull_squad_opinion",
                                    ["labelFallback"] = "Look to nearby squadmates",
                                    ["labelKey"] = "UI_PNC_CombatInjury_SquadCheck_Label",
                                    ["utteranceFallback"] = "Hey, keep eyes on their flank while we sort this injury out!",
                                    ["utteranceKey"] = "UI_PNC_CombatInjury_SquadCheck_Utterance",
                                },
                                {
                                    ["constraints"] = {
                                        ["op"] = "eq",
                                        ["path"] = "npcState.isBitten",
                                        ["value"] = true,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "QUESTION",
                                        ["speechAct"] = "QUESTION",
                                        ["stateValue"] = "bite_check",
                                        ["subject"] = "COMBAT_INJURY",
                                    },
                                    ["id"] = "combat.injury.inspect_bite_depth",
                                    ["labelFallback"] = "Verify bite transmission risk",
                                    ["labelKey"] = "UI_PNC_CombatInjury_InspectBite_Label",
                                    ["utteranceFallback"] = "Hold still so I can see whether that bite broke deep.",
                                    ["utteranceKey"] = "UI_PNC_CombatInjury_InspectBite_Utterance",
                                },
                            },
                            ["onClarify"] = "squad_reaction_interjection",
                            ["onMatch"] = "tactical_fallback_or_push",
                            ["onRefuse"] = "bite_transmission_check",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.flow.combat.injury.triage.assess",
                        },
                        ["bite_transmission_check"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["stateValue"] = "bite_non_lethal_stabilized",
                                    ["subject"] = "COMBAT_INJURY",
                                },
                                {
                                    ["intent"] = "WARN",
                                    ["speechAct"] = "WARN",
                                    ["stateValue"] = "bite_lethal",
                                    ["subject"] = "COMBAT_INJURY",
                                },
                                {
                                    ["intent"] = "CHALLENGE",
                                    ["speechAct"] = "CHALLENGE",
                                    ["stateValue"] = "bite_psychopath_threatened",
                                    ["subject"] = "COMBAT_INJURY",
                                },
                                {
                                    ["intent"] = "REFUSE",
                                    ["speechAct"] = "REFUSE",
                                },
                            },
                            ["branchOffers"] = {
                                {
                                    ["constraints"] = {
                                        ["op"] = "eq",
                                        ["path"] = "worldKnowledge.salivaTransmissible",
                                        ["value"] = false,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "INFORM",
                                        ["speechAct"] = "INFORM",
                                        ["stateValue"] = "bite_non_lethal_stabilized",
                                        ["subject"] = "COMBAT_INJURY",
                                    },
                                    ["id"] = "combat.injury.bite_not_transmissible",
                                    ["labelFallback"] = "Remind them bites do not turn people here",
                                    ["labelKey"] = "UI_PNC_CombatInjury_BiteNoSaliva_Label",
                                    ["utteranceFallback"] = "Breathe! The sickness does not spread by saliva here, just stop the bleeding!",
                                    ["utteranceKey"] = "UI_PNC_CombatInjury_BiteNoSaliva_Utterance",
                                },
                                {
                                    ["constraints"] = {
                                        ["op"] = "eq",
                                        ["path"] = "worldKnowledge.salivaTransmissible",
                                        ["value"] = true,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "WARN",
                                        ["speechAct"] = "WARN",
                                        ["stateValue"] = "bite_lethal",
                                        ["subject"] = "COMBAT_INJURY",
                                    },
                                    ["id"] = "combat.injury.bite_lethal_dread",
                                    ["labelFallback"] = "Acknowledge lethal bite risk",
                                    ["labelKey"] = "UI_PNC_CombatInjury_BiteLethal_Label",
                                    ["utteranceFallback"] = "Stay calm. Wrap that bite tight and watch the squad while we clear a way out.",
                                    ["utteranceKey"] = "UI_PNC_CombatInjury_BiteLethal_Utterance",
                                },
                                {
                                    ["constraints"] = {
                                        ["op"] = "eq",
                                        ["path"] = "scene.hasThirdPartyWitness",
                                        ["value"] = true,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "CHALLENGE",
                                        ["speechAct"] = "CHALLENGE",
                                        ["stateValue"] = "bite_psychopath_threatened",
                                        ["subject"] = "COMBAT_INJURY",
                                    },
                                    ["id"] = "combat.injury.psychopath_call_threat",
                                    ["labelFallback"] = "Confront hostile squadmate over bitten ally",
                                    ["labelKey"] = "UI_PNC_CombatInjury_PsychoThreat_Label",
                                    ["utteranceFallback"] = "Nobody is pulling a trigger on them in the middle of my fight!",
                                    ["utteranceKey"] = "UI_PNC_CombatInjury_PsychoThreat_Utterance",
                                },
                            },
                            ["onClarify"] = "squad_reaction_interjection",
                            ["onMatch"] = "quarantine_or_mercy_standoff",
                            ["onRefuse"] = "triage_resolution",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.flow.combat.injury.triage.bite_check",
                        },
                        ["injury_report_open"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "QUESTION",
                                    ["speechAct"] = "QUESTION",
                                    ["subject"] = "COMBAT_INJURY",
                                },
                                {
                                    ["intent"] = "INFORM",
                                    ["speechAct"] = "INFORM",
                                    ["subject"] = "COMBAT_INJURY",
                                },
                                {
                                    ["intent"] = "ACCEPT",
                                    ["speechAct"] = "ACCEPT",
                                    ["stateValue"] = "covered_for_treatment",
                                    ["subject"] = "COMBAT_INJURY",
                                },
                                {
                                    ["intent"] = "CLARIFY",
                                    ["speechAct"] = "CLARIFY",
                                    ["stateValue"] = "ordered_fallback",
                                    ["subject"] = "COMBAT_INJURY",
                                },
                                {
                                    ["intent"] = "WARN",
                                    ["speechAct"] = "WARN",
                                    ["stateValue"] = "bitten",
                                    ["subject"] = "COMBAT_INJURY",
                                },
                                {
                                    ["intent"] = "REFUSE",
                                    ["speechAct"] = "REFUSE",
                                },
                            },
                            ["branchOffers"] = {
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "QUESTION",
                                        ["speechAct"] = "QUESTION",
                                        ["subject"] = "COMBAT_INJURY",
                                    },
                                    ["id"] = "combat.injury.check_where_hit",
                                    ["labelFallback"] = "Ask where you're hit and how bad it is",
                                    ["labelKey"] = "UI_PNC_CombatInjury_CheckWhere_Label",
                                    ["utteranceFallback"] = "Where did they get you? Is that wrap still holding?",
                                    ["utteranceKey"] = "UI_PNC_CombatInjury_CheckWhere_Utterance",
                                },
                                {
                                    ["constraints"] = {
                                        ["op"] = "eq",
                                        ["path"] = "npcState.hasOpenWounds",
                                        ["value"] = true,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "ACCEPT",
                                        ["speechAct"] = "ACCEPT",
                                        ["stateValue"] = "covered_for_treatment",
                                        ["subject"] = "COMBAT_INJURY",
                                    },
                                    ["id"] = "combat.injury.offer_cover_wrap",
                                    ["labelFallback"] = "Cover them while they patch up",
                                    ["labelKey"] = "UI_PNC_CombatInjury_OfferCover_Label",
                                    ["utteranceFallback"] = "I have eyes on the dead. Tie that wound off right now!",
                                    ["utteranceKey"] = "UI_PNC_CombatInjury_OfferCover_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "CLARIFY",
                                        ["speechAct"] = "CLARIFY",
                                        ["stateValue"] = "ordered_fallback",
                                        ["subject"] = "COMBAT_INJURY",
                                    },
                                    ["id"] = "combat.injury.order_fallback",
                                    ["labelFallback"] = "Order them behind the line",
                                    ["labelKey"] = "UI_PNC_CombatInjury_OrderFallback_Label",
                                    ["utteranceFallback"] = "You're bleeding too hard to trade swings! Pull back behind me!",
                                    ["utteranceKey"] = "UI_PNC_CombatInjury_OrderFallback_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "INFORM",
                                        ["speechAct"] = "INFORM",
                                        ["stateValue"] = "reassured_bond",
                                        ["subject"] = "COMBAT_INJURY",
                                    },
                                    ["id"] = "combat.injury.reassure_keep_fighting",
                                    ["labelFallback"] = "Keep them focused and fighting",
                                    ["labelKey"] = "UI_PNC_CombatInjury_Reassure_Label",
                                    ["utteranceFallback"] = "Stay on my shoulder and watch your wrap. We are not losing you today.",
                                    ["utteranceKey"] = "UI_PNC_CombatInjury_Reassure_Utterance",
                                },
                                {
                                    ["constraints"] = {
                                        ["op"] = "eq",
                                        ["path"] = "npcState.isBitten",
                                        ["value"] = true,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "WARN",
                                        ["speechAct"] = "WARN",
                                        ["stateValue"] = "bitten",
                                        ["subject"] = "COMBAT_INJURY",
                                    },
                                    ["id"] = "combat.injury.check_bite_exposure",
                                    ["labelFallback"] = "Check the bite mark immediately",
                                    ["labelKey"] = "UI_PNC_CombatInjury_CheckBite_Label",
                                    ["utteranceFallback"] = "Wait, was that teeth? Let me see that bite right now!",
                                    ["utteranceKey"] = "UI_PNC_CombatInjury_CheckBite_Utterance",
                                },
                            },
                            ["onClarify"] = "tactical_fallback_or_push",
                            ["onMatch"] = "assess_wound_location",
                            ["onRefuse"] = "bite_transmission_check",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.flow.combat.injury.triage.open",
                            ["slots"] = {
                                ["woundPart"] = {
                                    ["owner"] = "combat.injury.triage_exchange",
                                    ["source"] = "slots.woundPart.value",
                                    ["type"] = "string",
                                },
                                ["woundType"] = {
                                    ["owner"] = "combat.injury.triage_exchange",
                                    ["source"] = "slots.woundType.value",
                                    ["type"] = "string",
                                },
                            },
                        },
                        ["quarantine_or_mercy_standoff"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "ACCEPT",
                                    ["speechAct"] = "ACCEPT",
                                    ["subject"] = "COMBAT_INJURY",
                                },
                                {
                                    ["intent"] = "CHALLENGE",
                                    ["speechAct"] = "CHALLENGE",
                                    ["subject"] = "COMBAT_INJURY",
                                },
                                {
                                    ["intent"] = "REFUSE",
                                    ["speechAct"] = "REFUSE",
                                },
                            },
                            ["branchOffers"] = {
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "ACCEPT",
                                        ["speechAct"] = "ACCEPT",
                                        ["stateValue"] = "bite_quarantined",
                                        ["subject"] = "COMBAT_INJURY",
                                    },
                                    ["id"] = "combat.injury.standoff_stabilize",
                                    ["labelFallback"] = "Order immediate bandage and watch",
                                    ["labelKey"] = "UI_PNC_CombatInjury_StandoffStabilize_Label",
                                    ["utteranceFallback"] = "Stay on your feet, wrap the bite, and we sort out the rest back at camp.",
                                    ["utteranceKey"] = "UI_PNC_CombatInjury_StandoffStabilize_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "CHALLENGE",
                                        ["speechAct"] = "CHALLENGE",
                                        ["stateValue"] = "bite_psychopath_threatened",
                                        ["subject"] = "COMBAT_INJURY",
                                    },
                                    ["id"] = "combat.injury.standoff_hostile_warning",
                                    ["labelFallback"] = "Warn aggressive squadmate to stand down",
                                    ["labelKey"] = "UI_PNC_CombatInjury_StandoffHostile_Label",
                                    ["utteranceFallback"] = "Try shooting my teammate and you answer to me next.",
                                    ["utteranceKey"] = "UI_PNC_CombatInjury_StandoffHostile_Utterance",
                                },
                            },
                            ["onMatch"] = "triage_resolution",
                            ["onRefuse"] = "triage_resolution",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.flow.combat.injury.triage.bite_standoff",
                        },
                        ["squad_reaction_interjection"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "MEDIATE",
                                    ["speechAct"] = "MEDIATE",
                                    ["subject"] = "COMBAT_INJURY",
                                },
                                {
                                    ["intent"] = "DISAGREE",
                                    ["speechAct"] = "DISAGREE",
                                    ["subject"] = "COMBAT_INJURY",
                                },
                                {
                                    ["intent"] = "REFUSE",
                                    ["speechAct"] = "REFUSE",
                                },
                            },
                            ["branchOffers"] = {
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "MEDIATE",
                                        ["speechAct"] = "MEDIATE",
                                        ["stateValue"] = "reassured_bond",
                                        ["subject"] = "COMBAT_INJURY",
                                    },
                                    ["id"] = "combat.injury.defend_injured_ally",
                                    ["labelFallback"] = "Keep the squad together and protect them",
                                    ["labelKey"] = "UI_PNC_CombatInjury_DefendAlly_Label",
                                    ["utteranceFallback"] = "Lower that barrel right now! We patch our own first and fight together.",
                                    ["utteranceKey"] = "UI_PNC_CombatInjury_DefendAlly_Utterance",
                                },
                                {
                                    ["constraints"] = {
                                        ["op"] = "eq",
                                        ["path"] = "worldKnowledge.salivaTransmissible",
                                        ["value"] = true,
                                    },
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "DISAGREE",
                                        ["speechAct"] = "DISAGREE",
                                        ["stateValue"] = "bite_quarantined",
                                        ["subject"] = "COMBAT_INJURY",
                                    },
                                    ["id"] = "combat.injury.quarantine_after_fight",
                                    ["labelFallback"] = "Set quarantine perimeter after contact",
                                    ["labelKey"] = "UI_PNC_CombatInjury_Quarantine_Label",
                                    ["utteranceFallback"] = "Keep twenty paces back once these walkers drop, we will watch the fever safely.",
                                    ["utteranceKey"] = "UI_PNC_CombatInjury_Quarantine_Utterance",
                                },
                            },
                            ["onClarify"] = "quarantine_or_mercy_standoff",
                            ["onMatch"] = "triage_resolution",
                            ["onRefuse"] = "triage_resolution",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.flow.combat.injury.triage.squad_interject",
                        },
                        ["tactical_fallback_or_push"] = {
                            ["accepts"] = {
                                {
                                    ["intent"] = "AGREE",
                                    ["speechAct"] = "AGREE",
                                    ["subject"] = "COMBAT_INJURY",
                                },
                                {
                                    ["intent"] = "ACCEPT",
                                    ["speechAct"] = "ACCEPT",
                                    ["subject"] = "COMBAT_INJURY",
                                },
                                {
                                    ["intent"] = "REFUSE",
                                    ["speechAct"] = "REFUSE",
                                },
                            },
                            ["branchOffers"] = {
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "AGREE",
                                        ["speechAct"] = "AGREE",
                                        ["stateValue"] = "ordered_fallback",
                                        ["subject"] = "COMBAT_INJURY",
                                    },
                                    ["id"] = "combat.injury.rotate_rear_guard",
                                    ["labelFallback"] = "Rotate them to rear guard",
                                    ["labelKey"] = "UI_PNC_CombatInjury_RotateRear_Label",
                                    ["utteranceFallback"] = "Switch spots with me now! Watch the rear while I clear the front.",
                                    ["utteranceKey"] = "UI_PNC_CombatInjury_RotateRear_Utterance",
                                },
                                {
                                    ["consumers"] = {
                                        "participant",
                                    },
                                    ["frame"] = {
                                        ["intent"] = "ACCEPT",
                                        ["speechAct"] = "ACCEPT",
                                        ["stateValue"] = "patched_push_on",
                                        ["subject"] = "COMBAT_INJURY",
                                    },
                                    ["id"] = "combat.injury.confirm_hold_patched",
                                    ["labelFallback"] = "Hold formation patched up",
                                    ["labelKey"] = "UI_PNC_CombatInjury_ConfirmHold_Label",
                                    ["utteranceFallback"] = "Good wrap. Stick close so nothing hits that limb again.",
                                    ["utteranceKey"] = "UI_PNC_CombatInjury_ConfirmHold_Utterance",
                                },
                            },
                            ["onMatch"] = "triage_resolution",
                            ["onRefuse"] = "triage_resolution",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.flow.combat.injury.triage.tactical_order",
                        },
                        ["triage_resolution"] = {
                            ["responsePool"] = "semantic.flow.combat.injury.triage.resolved",
                            ["terminal"] = true,
                        },
                    },
                    ["owner"] = "ProjectHoomans",
                    ["version"] = 1,
                },
                ["replySemantics"] = {
                    ["bite_non_lethal_stabilized"] = {
                        ["outcome"] = "bite_non_lethal_stabilized",
                        ["stance"] = "positive",
                    },
                    ["bite_psychopath_threatened"] = {
                        ["outcome"] = "bite_psychopath_threatened",
                        ["stance"] = "negative",
                    },
                    ["bite_quarantined"] = {
                        ["outcome"] = "bite_quarantined",
                        ["stance"] = "contextual",
                    },
                    ["covered_for_treatment"] = {
                        ["outcome"] = "covered_for_treatment",
                        ["stance"] = "positive",
                    },
                    ["ordered_fallback"] = {
                        ["outcome"] = "ordered_fallback",
                        ["stance"] = "neutral",
                    },
                    ["patched_push_on"] = {
                        ["outcome"] = "patched_push_on",
                        ["stance"] = "positive",
                    },
                    ["reassured_bond"] = {
                        ["outcome"] = "reassured_bond",
                        ["stance"] = "positive",
                    },
                    ["refused"] = {
                        ["outcome"] = "refused",
                        ["stance"] = "negative",
                    },
                },
                ["triggers"] = {
                    {
                        ["intent"] = "QUESTION",
                        ["subject"] = "COMBAT_INJURY",
                    },
                    {
                        ["intent"] = "CHECK",
                        ["subject"] = "COMBAT_INJURY",
                    },
                    {
                        ["intent"] = "OFFER",
                        ["subject"] = "COMBAT_INJURY",
                    },
                    {
                        ["intent"] = "ACCEPT",
                        ["subject"] = "COMBAT_INJURY",
                    },
                    {
                        ["intent"] = "CLARIFY",
                        ["subject"] = "COMBAT_INJURY",
                    },
                    {
                        ["intent"] = "WARN",
                        ["subject"] = "COMBAT_INJURY",
                    },
                    {
                        ["intent"] = "INFORM",
                        ["subject"] = "COMBAT_INJURY",
                    },
                },
            },
            ["repeatPolicy"] = "repeatable",
            ["reply"] = {
                ["bite_non_lethal_stabilized"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "wellbeing.needs.checkin",
                        },
                    },
                    ["outcome"] = "bite_non_lethal_stabilized",
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
                                        ["fallback"] = "Thank god saliva doesn't carry it here, {addressee.name}. Still stings awful, wrapping it tight now.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["bite_psychopath_threatened"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "social.conflict.mediate_exchange",
                        },
                    },
                    ["outcome"] = "bite_psychopath_threatened",
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
                                        ["fallback"] = "Keep that barrel down, {addressee.name}! We finish clearing the dead before anyone talks about executions.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["bite_quarantined"] = {
                    ["outcome"] = "bite_quarantined",
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
                                        ["fallback"] = "I know the rules, {addressee.name}. Help me clear the stragglers and I'll stay apart from the group.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["covered_for_treatment"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "wellbeing.needs.checkin",
                        },
                    },
                    ["outcome"] = "covered_for_treatment",
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
                                        ["fallback"] = "Thanks, {addressee.name}! Keep them off my back while I tie off this open bleed.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["ordered_fallback"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "wellbeing.needs.checkin",
                        },
                    },
                    ["outcome"] = "ordered_fallback",
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
                                        ["fallback"] = "Alright, backing up two steps behind you, {addressee.name}. Cover me while I catch my breath!",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["patched_push_on"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "combat.aftermath.debrief_exchange",
                        },
                    },
                    ["outcome"] = "patched_push_on",
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
                                        ["fallback"] = "Dressings are tight, {addressee.name}. Stay on my side and we'll sweep the rest of them.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["reassured_bond"] = {
                    ["after"] = {
                        ["recommend"] = {
                            "combat.aftermath.debrief_exchange",
                        },
                    },
                    ["outcome"] = "reassured_bond",
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
                                        ["fallback"] = "Heard you loud and clear, {addressee.name}. Still breathing, still swinging beside you.",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["refused"] = {
                    ["outcome"] = "refused",
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
                                        ["fallback"] = "Save the talk for when there aren't teeth snapping in our faces!",
                                        ["id"] = "default",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
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
                                ["fallback"] = "Still holding my ground, {addressee.name}, caught a hit and keeping eyes forward.",
                                ["id"] = "default",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["statePolicy"] = {
                {
                    ["admission"] = "no_op",
                    ["id"] = "blocked_dead_or_hostile",
                    ["outcome"] = "blocked",
                    ["reason"] = "hostile_dead_or_incapacitated",
                    ["replyOutcome"] = "refused",
                    ["when"] = {
                        ["any"] = {
                            {
                                ["op"] = "in",
                                ["path"] = "npcState.activeBehavior",
                                ["values"] = {
                                    "hostile",
                                    "dead",
                                },
                            },
                            {
                                ["op"] = "in",
                                ["path"] = "npcState.healthState",
                                ["values"] = {
                                    "dead",
                                    "incapacitated",
                                },
                            },
                            {
                                ["op"] = "eq",
                                ["path"] = "roles.hostile",
                                ["value"] = true,
                            },
                        },
                    },
                },
                {
                    ["admission"] = "dispatch",
                    ["id"] = "combat_injury_ready",
                    ["outcome"] = "actionable",
                    ["reason"] = "ready",
                },
            },
            ["topics"] = {
                {
                    ["domain"] = "combat",
                    ["id"] = "combat_injury",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "combat.injury.triage_exchange",
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
                            ["fallback"] = "Still holding my ground, {addressee.name}, caught a hit and keeping eyes forward.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.injury.triage_exchange.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
            ["witness"] = {
                ["cardinality"] = "BOUNDED_MANY",
                ["kinds"] = {
                    "actor",
                },
                ["max"] = 3,
                ["min"] = 0,
                ["role"] = "witness",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/combat_wound_callouts/combat_injury_interactive_exchange.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Still holding my ground, {addressee.name}, caught a hit and keeping eyes forward.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.injury.triage_exchange.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Thank god saliva doesn't carry it here, {addressee.name}. Still stings awful, wrapping it tight now.",
                ["outcome"] = "bite_non_lethal_stabilized",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.combat.injury.triage_exchange.reply.bite_non_lethal_stabilized.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Keep that barrel down, {addressee.name}! We finish clearing the dead before anyone talks about executions.",
                ["outcome"] = "bite_psychopath_threatened",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.combat.injury.triage_exchange.reply.bite_psychopath_threatened.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "I know the rules, {addressee.name}. Help me clear the stragglers and I'll stay apart from the group.",
                ["outcome"] = "bite_quarantined",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.combat.injury.triage_exchange.reply.bite_quarantined.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Thanks, {addressee.name}! Keep them off my back while I tie off this open bleed.",
                ["outcome"] = "covered_for_treatment",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.combat.injury.triage_exchange.reply.covered_for_treatment.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Alright, backing up two steps behind you, {addressee.name}. Cover me while I catch my breath!",
                ["outcome"] = "ordered_fallback",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.combat.injury.triage_exchange.reply.ordered_fallback.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Dressings are tight, {addressee.name}. Stay on my side and we'll sweep the rest of them.",
                ["outcome"] = "patched_push_on",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.combat.injury.triage_exchange.reply.patched_push_on.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Heard you loud and clear, {addressee.name}. Still breathing, still swinging beside you.",
                ["outcome"] = "reassured_bond",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.combat.injury.triage_exchange.reply.reassured_bond.say.1.default",
                ["variantID"] = "default",
            },
            {
                ["fallback"] = "Save the talk for when there aren't teeth snapping in our faces!",
                ["outcome"] = "refused",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.combat.injury.triage_exchange.reply.refused.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_wound_callouts",
        ["domainPath"] = "combat_wound_callouts",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.wound.ally_reaction",
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
                                ["fallback"] = "No! Don't talk like that, {addressee.name}! Stay beside me, I'm not leaving you out here!",
                                ["id"] = "close_bond_bite_lethal",
                                ["templateID"] = "convo.combat.wound.ally_reaction.say.1.close_bond_bite_lethal",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Stay with me, {addressee.name}! Don't you dare go down on my watch, I've got you!",
                                ["id"] = "close_bond_critical",
                                ["templateID"] = "convo.combat.wound.ally_reaction.say.1.close_bond_critical",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Easy, {addressee.name}, watch that patched {slot.wound.part}! Stick right by my shoulder, I'm not losing you!",
                                ["id"] = "close_bond_patched",
                                ["templateID"] = "convo.combat.wound.ally_reaction.say.1.close_bond_patched",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Fall back behind me, {addressee.name}, your {slot.wound.part} needs wrapping before you bleed out!",
                                ["id"] = "supportive_cover_wounded",
                                ["templateID"] = "convo.combat.wound.ally_reaction.say.1.supportive_cover_wounded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Watch your dressing on that {slot.wound.part}, {addressee.name}, shout if it starts soaking through!",
                                ["id"] = "supportive_cover_patched",
                                ["templateID"] = "convo.combat.wound.ally_reaction.say.1.supportive_cover_patched",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Copy that, {addressee.name}, pull behind the line and tie off your {slot.wound.part}!",
                                ["id"] = "tactical_cover_wounded",
                                ["templateID"] = "convo.combat.wound.ally_reaction.say.1.tactical_cover_wounded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Keep your {slot.wound.part} protected, {addressee.name}, we hold spacing until clear!",
                                ["id"] = "tactical_cover_patched",
                                ["templateID"] = "convo.combat.wound.ally_reaction.say.1.tactical_cover_patched",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "I'm closing the gap on your flank, {addressee.name}! Squad, tighten up and cover that {slot.wound.part}!",
                                ["id"] = "squad_crossfire_wingman",
                                ["templateID"] = "convo.combat.wound.ally_reaction.say.1.squad_crossfire_wingman",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "You're not turning, {addressee.name}, saliva doesn't spread it! Keep pressure on your {slot.wound.part} and keep moving!",
                                ["id"] = "bite_non_transmissible_relief",
                                ["templateID"] = "convo.combat.wound.ally_reaction.say.1.bite_non_transmissible_relief",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Quit groaning about your {slot.wound.part}, {addressee.name}, either hold your corner or get out of my way.",
                                ["id"] = "low_rel_dismissive",
                                ["templateID"] = "convo.combat.wound.ally_reaction.say.1.low_rel_dismissive",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "You got bit, {addressee.name}. Stay five steps back, and the second you look feverish I'm ending you.",
                                ["id"] = "low_rel_bite_execution_threat",
                                ["templateID"] = "convo.combat.wound.ally_reaction.say.1.low_rel_bite_execution_threat",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "You're bitten, {addressee.name}. Forget bandages. I'm putting you down myself before you turn on us.",
                                ["id"] = "psychopath_bite_execution_threat",
                                ["templateID"] = "convo.combat.wound.ally_reaction.say.1.psychopath_bite_execution_threat",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Stay sharp on your feet, {addressee.name}, keep watching your {slot.wound.part}!",
                                ["id"] = "default",
                                ["templateID"] = "convo.combat.wound.ally_reaction.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.wound",
            ["slots"] = {
                ["wound"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "entity.item",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "No! Don't talk like that, {addressee.name}! Stay beside me, I'm not leaving you out here!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.wound.ally_reaction.say.1.close_bond_bite_lethal",
                    ["variantID"] = "close_bond_bite_lethal",
                },
                {
                    ["fallback"] = "Stay with me, {addressee.name}! Don't you dare go down on my watch, I've got you!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.wound.ally_reaction.say.1.close_bond_critical",
                    ["variantID"] = "close_bond_critical",
                },
                {
                    ["fallback"] = "Easy, {addressee.name}, watch that patched {slot.wound.part}! Stick right by my shoulder, I'm not losing you!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.wound.ally_reaction.say.1.close_bond_patched",
                    ["variantID"] = "close_bond_patched",
                },
                {
                    ["fallback"] = "Fall back behind me, {addressee.name}, your {slot.wound.part} needs wrapping before you bleed out!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.wound.ally_reaction.say.1.supportive_cover_wounded",
                    ["variantID"] = "supportive_cover_wounded",
                },
                {
                    ["fallback"] = "Watch your dressing on that {slot.wound.part}, {addressee.name}, shout if it starts soaking through!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.wound.ally_reaction.say.1.supportive_cover_patched",
                    ["variantID"] = "supportive_cover_patched",
                },
                {
                    ["fallback"] = "Copy that, {addressee.name}, pull behind the line and tie off your {slot.wound.part}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.wound.ally_reaction.say.1.tactical_cover_wounded",
                    ["variantID"] = "tactical_cover_wounded",
                },
                {
                    ["fallback"] = "Keep your {slot.wound.part} protected, {addressee.name}, we hold spacing until clear!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.wound.ally_reaction.say.1.tactical_cover_patched",
                    ["variantID"] = "tactical_cover_patched",
                },
                {
                    ["fallback"] = "I'm closing the gap on your flank, {addressee.name}! Squad, tighten up and cover that {slot.wound.part}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.wound.ally_reaction.say.1.squad_crossfire_wingman",
                    ["variantID"] = "squad_crossfire_wingman",
                },
                {
                    ["fallback"] = "You're not turning, {addressee.name}, saliva doesn't spread it! Keep pressure on your {slot.wound.part} and keep moving!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.wound.ally_reaction.say.1.bite_non_transmissible_relief",
                    ["variantID"] = "bite_non_transmissible_relief",
                },
                {
                    ["fallback"] = "Quit groaning about your {slot.wound.part}, {addressee.name}, either hold your corner or get out of my way.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.wound.ally_reaction.say.1.low_rel_dismissive",
                    ["variantID"] = "low_rel_dismissive",
                },
                {
                    ["fallback"] = "You got bit, {addressee.name}. Stay five steps back, and the second you look feverish I'm ending you.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.wound.ally_reaction.say.1.low_rel_bite_execution_threat",
                    ["variantID"] = "low_rel_bite_execution_threat",
                },
                {
                    ["fallback"] = "You're bitten, {addressee.name}. Forget bandages. I'm putting you down myself before you turn on us.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.wound.ally_reaction.say.1.psychopath_bite_execution_threat",
                    ["variantID"] = "psychopath_bite_execution_threat",
                },
                {
                    ["fallback"] = "Stay sharp on your feet, {addressee.name}, keep watching your {slot.wound.part}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.wound.ally_reaction.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "combat.wound.ally_reaction",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "ally_reaction",
            ["sourceId"] = "combat.wound.ally_reaction",
            ["sourcePath"] = "dialogue/combat_wound_callouts/combat_wound_ally_reaction.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatWoundCallouts",
        ["namespace"] = "combat.wound",
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
            ["domains"] = {
                {
                    ["domain"] = "combat",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["events"] = {
                {
                    ["id"] = "combat_wound_ally_reaction",
                    ["kind"] = "combat_event",
                },
            },
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
                                ["fallback"] = "No! Don't talk like that, {addressee.name}! Stay beside me, I'm not leaving you out here!",
                                ["id"] = "close_bond_bite_lethal",
                            },
                            {
                                ["fallback"] = "Stay with me, {addressee.name}! Don't you dare go down on my watch, I've got you!",
                                ["id"] = "close_bond_critical",
                            },
                            {
                                ["fallback"] = "Easy, {addressee.name}, watch that patched {slot.wound.part}! Stick right by my shoulder, I'm not losing you!",
                                ["id"] = "close_bond_patched",
                            },
                            {
                                ["fallback"] = "Fall back behind me, {addressee.name}, your {slot.wound.part} needs wrapping before you bleed out!",
                                ["id"] = "supportive_cover_wounded",
                            },
                            {
                                ["fallback"] = "Watch your dressing on that {slot.wound.part}, {addressee.name}, shout if it starts soaking through!",
                                ["id"] = "supportive_cover_patched",
                            },
                            {
                                ["fallback"] = "Copy that, {addressee.name}, pull behind the line and tie off your {slot.wound.part}!",
                                ["id"] = "tactical_cover_wounded",
                            },
                            {
                                ["fallback"] = "Keep your {slot.wound.part} protected, {addressee.name}, we hold spacing until clear!",
                                ["id"] = "tactical_cover_patched",
                            },
                            {
                                ["fallback"] = "I'm closing the gap on your flank, {addressee.name}! Squad, tighten up and cover that {slot.wound.part}!",
                                ["id"] = "squad_crossfire_wingman",
                            },
                            {
                                ["fallback"] = "You're not turning, {addressee.name}, saliva doesn't spread it! Keep pressure on your {slot.wound.part} and keep moving!",
                                ["id"] = "bite_non_transmissible_relief",
                            },
                            {
                                ["fallback"] = "Quit groaning about your {slot.wound.part}, {addressee.name}, either hold your corner or get out of my way.",
                                ["id"] = "low_rel_dismissive",
                            },
                            {
                                ["fallback"] = "You got bit, {addressee.name}. Stay five steps back, and the second you look feverish I'm ending you.",
                                ["id"] = "low_rel_bite_execution_threat",
                            },
                            {
                                ["fallback"] = "You're bitten, {addressee.name}. Forget bandages. I'm putting you down myself before you turn on us.",
                                ["id"] = "psychopath_bite_execution_threat",
                            },
                            {
                                ["fallback"] = "Stay sharp on your feet, {addressee.name}, keep watching your {slot.wound.part}!",
                                ["id"] = "default",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "combat",
                    ["id"] = "combat_injury",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "combat.wound.ally_reaction",
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
                            ["fallback"] = "No! Don't talk like that, {addressee.name}! Stay beside me, I'm not leaving you out here!",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.wound.ally_reaction.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
            ["target"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "target",
            },
        },
        ["slots"] = {
            ["wound"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.item",
            },
        },
        ["sourceShard"] = "dialogue/combat_wound_callouts/combat_wound_ally_reaction.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "No! Don't talk like that, {addressee.name}! Stay beside me, I'm not leaving you out here!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.wound.ally_reaction.say.1.close_bond_bite_lethal",
                ["variantID"] = "close_bond_bite_lethal",
            },
            {
                ["fallback"] = "Stay with me, {addressee.name}! Don't you dare go down on my watch, I've got you!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.wound.ally_reaction.say.1.close_bond_critical",
                ["variantID"] = "close_bond_critical",
            },
            {
                ["fallback"] = "Easy, {addressee.name}, watch that patched {slot.wound.part}! Stick right by my shoulder, I'm not losing you!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.wound.ally_reaction.say.1.close_bond_patched",
                ["variantID"] = "close_bond_patched",
            },
            {
                ["fallback"] = "Fall back behind me, {addressee.name}, your {slot.wound.part} needs wrapping before you bleed out!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.wound.ally_reaction.say.1.supportive_cover_wounded",
                ["variantID"] = "supportive_cover_wounded",
            },
            {
                ["fallback"] = "Watch your dressing on that {slot.wound.part}, {addressee.name}, shout if it starts soaking through!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.wound.ally_reaction.say.1.supportive_cover_patched",
                ["variantID"] = "supportive_cover_patched",
            },
            {
                ["fallback"] = "Copy that, {addressee.name}, pull behind the line and tie off your {slot.wound.part}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.wound.ally_reaction.say.1.tactical_cover_wounded",
                ["variantID"] = "tactical_cover_wounded",
            },
            {
                ["fallback"] = "Keep your {slot.wound.part} protected, {addressee.name}, we hold spacing until clear!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.wound.ally_reaction.say.1.tactical_cover_patched",
                ["variantID"] = "tactical_cover_patched",
            },
            {
                ["fallback"] = "I'm closing the gap on your flank, {addressee.name}! Squad, tighten up and cover that {slot.wound.part}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.wound.ally_reaction.say.1.squad_crossfire_wingman",
                ["variantID"] = "squad_crossfire_wingman",
            },
            {
                ["fallback"] = "You're not turning, {addressee.name}, saliva doesn't spread it! Keep pressure on your {slot.wound.part} and keep moving!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.wound.ally_reaction.say.1.bite_non_transmissible_relief",
                ["variantID"] = "bite_non_transmissible_relief",
            },
            {
                ["fallback"] = "Quit groaning about your {slot.wound.part}, {addressee.name}, either hold your corner or get out of my way.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.wound.ally_reaction.say.1.low_rel_dismissive",
                ["variantID"] = "low_rel_dismissive",
            },
            {
                ["fallback"] = "You got bit, {addressee.name}. Stay five steps back, and the second you look feverish I'm ending you.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.wound.ally_reaction.say.1.low_rel_bite_execution_threat",
                ["variantID"] = "low_rel_bite_execution_threat",
            },
            {
                ["fallback"] = "You're bitten, {addressee.name}. Forget bandages. I'm putting you down myself before you turn on us.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.wound.ally_reaction.say.1.psychopath_bite_execution_threat",
                ["variantID"] = "psychopath_bite_execution_threat",
            },
            {
                ["fallback"] = "Stay sharp on your feet, {addressee.name}, keep watching your {slot.wound.part}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.wound.ally_reaction.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "combat_wound_callouts",
        ["domainPath"] = "combat_wound_callouts",
        ["exchangeFamily"] = {
            ["familyID"] = "combat.wound.received_beat",
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
                                ["fallback"] = "No, no! It bit my {slot.wound.part}, {addressee.name}! Teeth went straight through!",
                                ["id"] = "bite_lethal",
                                ["templateID"] = "convo.combat.wound.received_beat.say.1.bite_lethal",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 3,
                            },
                            {
                                ["fallback"] = "Agh! Teeth broke skin on my {slot.wound.part}, {addressee.name}! Help me clear out so we can see how deep that bite went!",
                                ["id"] = "bite_possible_exposure",
                                ["templateID"] = "convo.combat.wound.received_beat.say.1.bite_possible_exposure",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "My skin's burning up and that bite on my {slot.wound.part} is throbbing, {addressee.name}! The fever's taking hold!",
                                ["id"] = "bite_confirmed_symptomatic",
                                ["templateID"] = "convo.combat.wound.received_beat.say.1.bite_confirmed_symptomatic",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Agh! Teeth tore right into my {slot.wound.part}, {addressee.name}! Hurts like hell, help me wrap it once we clear!",
                                ["id"] = "bite_non_transmissible",
                                ["templateID"] = "convo.combat.wound.received_beat.say.1.bite_non_transmissible",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "I'm shot! Took a round in my {slot.wound.part}, {addressee.name}!",
                                ["id"] = "bullet",
                                ["templateID"] = "convo.combat.wound.received_beat.say.1.bullet",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Agh! Glass went deep into my {slot.wound.part}, {addressee.name}, bleeding everywhere!",
                                ["id"] = "deep_wound_glass",
                                ["templateID"] = "convo.combat.wound.received_beat.say.1.deep_wound_glass",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Ripped wide open on my {slot.wound.part}, {addressee.name}! Deep gash, I need stitches after this!",
                                ["id"] = "deep_wound",
                                ["templateID"] = "convo.combat.wound.received_beat.say.1.deep_wound",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Crack! Something snapped in my {slot.wound.part}, {addressee.name}!",
                                ["id"] = "fracture",
                                ["templateID"] = "convo.combat.wound.received_beat.say.1.fracture",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Agh! Burned my {slot.wound.part}, {addressee.name}, skin's blistering bad!",
                                ["id"] = "burn",
                                ["templateID"] = "convo.combat.wound.received_beat.say.1.burn",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Slashed my {slot.wound.part}, {addressee.name}! Nasty laceration, keep them back!",
                                ["id"] = "laceration",
                                ["templateID"] = "convo.combat.wound.received_beat.say.1.laceration",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Tch, grazed my {slot.wound.part}, {addressee.name}, just a scratch.",
                                ["id"] = "scratch",
                                ["templateID"] = "convo.combat.wound.received_beat.say.1.scratch",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Area's clear, {addressee.name}, but this {slot.wound.label} on my {slot.wound.part} needs attention right now.",
                                ["id"] = "post_combat_injury_check",
                                ["templateID"] = "convo.combat.wound.received_beat.say.1.post_combat_injury_check",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "My {slot.wound.part} is getting worse, {addressee.name}! I'm losing too much blood!",
                                ["id"] = "severity_escalation",
                                ["templateID"] = "convo.combat.wound.received_beat.say.1.severity_escalation",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Bandage on my {slot.wound.part} is soaked and dirty, {addressee.name}, I need a fresh dressing soon.",
                                ["id"] = "bandage_dirty",
                                ["templateID"] = "convo.combat.wound.received_beat.say.1.bandage_dirty",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Got my {slot.wound.part} bound up tight, {addressee.name}. Bleeding's finally under control.",
                                ["id"] = "treatment_stabilized",
                                ["templateID"] = "convo.combat.wound.received_beat.say.1.treatment_stabilized",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Stomach's turning and my skin feels clammy, {addressee.name}... something's wrong after that wound on my {slot.wound.part}.",
                                ["id"] = "knox_symptom_onset",
                                ["templateID"] = "convo.combat.wound.received_beat.say.1.knox_symptom_onset",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Burning up with fever, {addressee.name}... my head is pounding and I can barely focus.",
                                ["id"] = "fever_onset",
                                ["templateID"] = "convo.combat.wound.received_beat.say.1.fever_onset",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Caught a nasty chill in my chest, {addressee.name}, can't stop coughing and sneezing.",
                                ["id"] = "cold_illness_onset",
                                ["templateID"] = "convo.combat.wound.received_beat.say.1.cold_illness_onset",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Hands are numb and I can't stop shivering, {addressee.name}! I'm freezing out here!",
                                ["id"] = "hypothermia_onset",
                                ["templateID"] = "convo.combat.wound.received_beat.say.1.hypothermia_onset",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Dizzy from the heat, {addressee.name}... I'm overheating in this gear!",
                                ["id"] = "hyperthermia_onset",
                                ["templateID"] = "convo.combat.wound.received_beat.say.1.hyperthermia_onset",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Soaked to the bone and shivering, {addressee.name}—I'll catch a fever if I stay wet like this.",
                                ["id"] = "soaked_chill",
                                ["templateID"] = "convo.combat.wound.received_beat.say.1.soaked_chill",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Took a hit to my {slot.wound.part}, {addressee.name}, watch that angle!",
                                ["id"] = "default",
                                ["templateID"] = "convo.combat.wound.received_beat.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.wound",
            ["slots"] = {
                ["wound"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "entity.item",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "No, no! It bit my {slot.wound.part}, {addressee.name}! Teeth went straight through!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.wound.received_beat.say.1.bite_lethal",
                    ["variantID"] = "bite_lethal",
                },
                {
                    ["fallback"] = "Agh! Teeth broke skin on my {slot.wound.part}, {addressee.name}! Help me clear out so we can see how deep that bite went!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.wound.received_beat.say.1.bite_possible_exposure",
                    ["variantID"] = "bite_possible_exposure",
                },
                {
                    ["fallback"] = "My skin's burning up and that bite on my {slot.wound.part} is throbbing, {addressee.name}! The fever's taking hold!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.wound.received_beat.say.1.bite_confirmed_symptomatic",
                    ["variantID"] = "bite_confirmed_symptomatic",
                },
                {
                    ["fallback"] = "Agh! Teeth tore right into my {slot.wound.part}, {addressee.name}! Hurts like hell, help me wrap it once we clear!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.wound.received_beat.say.1.bite_non_transmissible",
                    ["variantID"] = "bite_non_transmissible",
                },
                {
                    ["fallback"] = "I'm shot! Took a round in my {slot.wound.part}, {addressee.name}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.wound.received_beat.say.1.bullet",
                    ["variantID"] = "bullet",
                },
                {
                    ["fallback"] = "Agh! Glass went deep into my {slot.wound.part}, {addressee.name}, bleeding everywhere!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.wound.received_beat.say.1.deep_wound_glass",
                    ["variantID"] = "deep_wound_glass",
                },
                {
                    ["fallback"] = "Ripped wide open on my {slot.wound.part}, {addressee.name}! Deep gash, I need stitches after this!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.wound.received_beat.say.1.deep_wound",
                    ["variantID"] = "deep_wound",
                },
                {
                    ["fallback"] = "Crack! Something snapped in my {slot.wound.part}, {addressee.name}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.wound.received_beat.say.1.fracture",
                    ["variantID"] = "fracture",
                },
                {
                    ["fallback"] = "Agh! Burned my {slot.wound.part}, {addressee.name}, skin's blistering bad!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.wound.received_beat.say.1.burn",
                    ["variantID"] = "burn",
                },
                {
                    ["fallback"] = "Slashed my {slot.wound.part}, {addressee.name}! Nasty laceration, keep them back!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.wound.received_beat.say.1.laceration",
                    ["variantID"] = "laceration",
                },
                {
                    ["fallback"] = "Tch, grazed my {slot.wound.part}, {addressee.name}, just a scratch.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.wound.received_beat.say.1.scratch",
                    ["variantID"] = "scratch",
                },
                {
                    ["fallback"] = "Area's clear, {addressee.name}, but this {slot.wound.label} on my {slot.wound.part} needs attention right now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.wound.received_beat.say.1.post_combat_injury_check",
                    ["variantID"] = "post_combat_injury_check",
                },
                {
                    ["fallback"] = "My {slot.wound.part} is getting worse, {addressee.name}! I'm losing too much blood!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.wound.received_beat.say.1.severity_escalation",
                    ["variantID"] = "severity_escalation",
                },
                {
                    ["fallback"] = "Bandage on my {slot.wound.part} is soaked and dirty, {addressee.name}, I need a fresh dressing soon.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.wound.received_beat.say.1.bandage_dirty",
                    ["variantID"] = "bandage_dirty",
                },
                {
                    ["fallback"] = "Got my {slot.wound.part} bound up tight, {addressee.name}. Bleeding's finally under control.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.wound.received_beat.say.1.treatment_stabilized",
                    ["variantID"] = "treatment_stabilized",
                },
                {
                    ["fallback"] = "Stomach's turning and my skin feels clammy, {addressee.name}... something's wrong after that wound on my {slot.wound.part}.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.wound.received_beat.say.1.knox_symptom_onset",
                    ["variantID"] = "knox_symptom_onset",
                },
                {
                    ["fallback"] = "Burning up with fever, {addressee.name}... my head is pounding and I can barely focus.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.wound.received_beat.say.1.fever_onset",
                    ["variantID"] = "fever_onset",
                },
                {
                    ["fallback"] = "Caught a nasty chill in my chest, {addressee.name}, can't stop coughing and sneezing.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.wound.received_beat.say.1.cold_illness_onset",
                    ["variantID"] = "cold_illness_onset",
                },
                {
                    ["fallback"] = "Hands are numb and I can't stop shivering, {addressee.name}! I'm freezing out here!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.wound.received_beat.say.1.hypothermia_onset",
                    ["variantID"] = "hypothermia_onset",
                },
                {
                    ["fallback"] = "Dizzy from the heat, {addressee.name}... I'm overheating in this gear!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.wound.received_beat.say.1.hyperthermia_onset",
                    ["variantID"] = "hyperthermia_onset",
                },
                {
                    ["fallback"] = "Soaked to the bone and shivering, {addressee.name}—I'll catch a fever if I stay wet like this.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.wound.received_beat.say.1.soaked_chill",
                    ["variantID"] = "soaked_chill",
                },
                {
                    ["fallback"] = "Took a hit to my {slot.wound.part}, {addressee.name}, watch that angle!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.wound.received_beat.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "combat.wound.received_beat",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "received_beat",
            ["sourceId"] = "combat.wound.received_beat",
            ["sourcePath"] = "dialogue/combat_wound_callouts/combat_wound_received_beat.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatWoundCallouts",
        ["namespace"] = "combat.wound",
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
            ["domains"] = {
                {
                    ["domain"] = "combat",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["events"] = {
                {
                    ["id"] = "combat_wound_received",
                    ["kind"] = "combat_event",
                },
            },
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
                                ["fallback"] = "No, no! It bit my {slot.wound.part}, {addressee.name}! Teeth went straight through!",
                                ["id"] = "bite_lethal",
                            },
                            {
                                ["fallback"] = "Agh! Teeth broke skin on my {slot.wound.part}, {addressee.name}! Help me clear out so we can see how deep that bite went!",
                                ["id"] = "bite_possible_exposure",
                            },
                            {
                                ["fallback"] = "My skin's burning up and that bite on my {slot.wound.part} is throbbing, {addressee.name}! The fever's taking hold!",
                                ["id"] = "bite_confirmed_symptomatic",
                            },
                            {
                                ["fallback"] = "Agh! Teeth tore right into my {slot.wound.part}, {addressee.name}! Hurts like hell, help me wrap it once we clear!",
                                ["id"] = "bite_non_transmissible",
                            },
                            {
                                ["fallback"] = "I'm shot! Took a round in my {slot.wound.part}, {addressee.name}!",
                                ["id"] = "bullet",
                            },
                            {
                                ["fallback"] = "Agh! Glass went deep into my {slot.wound.part}, {addressee.name}, bleeding everywhere!",
                                ["id"] = "deep_wound_glass",
                            },
                            {
                                ["fallback"] = "Ripped wide open on my {slot.wound.part}, {addressee.name}! Deep gash, I need stitches after this!",
                                ["id"] = "deep_wound",
                            },
                            {
                                ["fallback"] = "Crack! Something snapped in my {slot.wound.part}, {addressee.name}!",
                                ["id"] = "fracture",
                            },
                            {
                                ["fallback"] = "Agh! Burned my {slot.wound.part}, {addressee.name}, skin's blistering bad!",
                                ["id"] = "burn",
                            },
                            {
                                ["fallback"] = "Slashed my {slot.wound.part}, {addressee.name}! Nasty laceration, keep them back!",
                                ["id"] = "laceration",
                            },
                            {
                                ["fallback"] = "Tch, grazed my {slot.wound.part}, {addressee.name}, just a scratch.",
                                ["id"] = "scratch",
                            },
                            {
                                ["fallback"] = "Area's clear, {addressee.name}, but this {slot.wound.label} on my {slot.wound.part} needs attention right now.",
                                ["id"] = "post_combat_injury_check",
                            },
                            {
                                ["fallback"] = "My {slot.wound.part} is getting worse, {addressee.name}! I'm losing too much blood!",
                                ["id"] = "severity_escalation",
                            },
                            {
                                ["fallback"] = "Bandage on my {slot.wound.part} is soaked and dirty, {addressee.name}, I need a fresh dressing soon.",
                                ["id"] = "bandage_dirty",
                            },
                            {
                                ["fallback"] = "Got my {slot.wound.part} bound up tight, {addressee.name}. Bleeding's finally under control.",
                                ["id"] = "treatment_stabilized",
                            },
                            {
                                ["fallback"] = "Stomach's turning and my skin feels clammy, {addressee.name}... something's wrong after that wound on my {slot.wound.part}.",
                                ["id"] = "knox_symptom_onset",
                            },
                            {
                                ["fallback"] = "Burning up with fever, {addressee.name}... my head is pounding and I can barely focus.",
                                ["id"] = "fever_onset",
                            },
                            {
                                ["fallback"] = "Caught a nasty chill in my chest, {addressee.name}, can't stop coughing and sneezing.",
                                ["id"] = "cold_illness_onset",
                            },
                            {
                                ["fallback"] = "Hands are numb and I can't stop shivering, {addressee.name}! I'm freezing out here!",
                                ["id"] = "hypothermia_onset",
                            },
                            {
                                ["fallback"] = "Dizzy from the heat, {addressee.name}... I'm overheating in this gear!",
                                ["id"] = "hyperthermia_onset",
                            },
                            {
                                ["fallback"] = "Soaked to the bone and shivering, {addressee.name}—I'll catch a fever if I stay wet like this.",
                                ["id"] = "soaked_chill",
                            },
                            {
                                ["fallback"] = "Took a hit to my {slot.wound.part}, {addressee.name}, watch that angle!",
                                ["id"] = "default",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "combat",
                    ["id"] = "combat_injury",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "combat.wound.received_beat",
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
                            ["fallback"] = "No, no! It bit my {slot.wound.part}, {addressee.name}! Teeth went straight through!",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.wound.received_beat.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
            ["witness"] = {
                ["cardinality"] = "BOUNDED_MANY",
                ["kinds"] = {
                    "actor",
                },
                ["max"] = 3,
                ["min"] = 0,
                ["role"] = "witness",
            },
        },
        ["slots"] = {
            ["wound"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.item",
            },
        },
        ["sourceShard"] = "dialogue/combat_wound_callouts/combat_wound_received_beat.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "No, no! It bit my {slot.wound.part}, {addressee.name}! Teeth went straight through!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.wound.received_beat.say.1.bite_lethal",
                ["variantID"] = "bite_lethal",
            },
            {
                ["fallback"] = "Agh! Teeth broke skin on my {slot.wound.part}, {addressee.name}! Help me clear out so we can see how deep that bite went!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.wound.received_beat.say.1.bite_possible_exposure",
                ["variantID"] = "bite_possible_exposure",
            },
            {
                ["fallback"] = "My skin's burning up and that bite on my {slot.wound.part} is throbbing, {addressee.name}! The fever's taking hold!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.wound.received_beat.say.1.bite_confirmed_symptomatic",
                ["variantID"] = "bite_confirmed_symptomatic",
            },
            {
                ["fallback"] = "Agh! Teeth tore right into my {slot.wound.part}, {addressee.name}! Hurts like hell, help me wrap it once we clear!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.wound.received_beat.say.1.bite_non_transmissible",
                ["variantID"] = "bite_non_transmissible",
            },
            {
                ["fallback"] = "I'm shot! Took a round in my {slot.wound.part}, {addressee.name}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.wound.received_beat.say.1.bullet",
                ["variantID"] = "bullet",
            },
            {
                ["fallback"] = "Agh! Glass went deep into my {slot.wound.part}, {addressee.name}, bleeding everywhere!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.wound.received_beat.say.1.deep_wound_glass",
                ["variantID"] = "deep_wound_glass",
            },
            {
                ["fallback"] = "Ripped wide open on my {slot.wound.part}, {addressee.name}! Deep gash, I need stitches after this!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.wound.received_beat.say.1.deep_wound",
                ["variantID"] = "deep_wound",
            },
            {
                ["fallback"] = "Crack! Something snapped in my {slot.wound.part}, {addressee.name}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.wound.received_beat.say.1.fracture",
                ["variantID"] = "fracture",
            },
            {
                ["fallback"] = "Agh! Burned my {slot.wound.part}, {addressee.name}, skin's blistering bad!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.wound.received_beat.say.1.burn",
                ["variantID"] = "burn",
            },
            {
                ["fallback"] = "Slashed my {slot.wound.part}, {addressee.name}! Nasty laceration, keep them back!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.wound.received_beat.say.1.laceration",
                ["variantID"] = "laceration",
            },
            {
                ["fallback"] = "Tch, grazed my {slot.wound.part}, {addressee.name}, just a scratch.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.wound.received_beat.say.1.scratch",
                ["variantID"] = "scratch",
            },
            {
                ["fallback"] = "Area's clear, {addressee.name}, but this {slot.wound.label} on my {slot.wound.part} needs attention right now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.wound.received_beat.say.1.post_combat_injury_check",
                ["variantID"] = "post_combat_injury_check",
            },
            {
                ["fallback"] = "My {slot.wound.part} is getting worse, {addressee.name}! I'm losing too much blood!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.wound.received_beat.say.1.severity_escalation",
                ["variantID"] = "severity_escalation",
            },
            {
                ["fallback"] = "Bandage on my {slot.wound.part} is soaked and dirty, {addressee.name}, I need a fresh dressing soon.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.wound.received_beat.say.1.bandage_dirty",
                ["variantID"] = "bandage_dirty",
            },
            {
                ["fallback"] = "Got my {slot.wound.part} bound up tight, {addressee.name}. Bleeding's finally under control.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.wound.received_beat.say.1.treatment_stabilized",
                ["variantID"] = "treatment_stabilized",
            },
            {
                ["fallback"] = "Stomach's turning and my skin feels clammy, {addressee.name}... something's wrong after that wound on my {slot.wound.part}.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.wound.received_beat.say.1.knox_symptom_onset",
                ["variantID"] = "knox_symptom_onset",
            },
            {
                ["fallback"] = "Burning up with fever, {addressee.name}... my head is pounding and I can barely focus.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.wound.received_beat.say.1.fever_onset",
                ["variantID"] = "fever_onset",
            },
            {
                ["fallback"] = "Caught a nasty chill in my chest, {addressee.name}, can't stop coughing and sneezing.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.wound.received_beat.say.1.cold_illness_onset",
                ["variantID"] = "cold_illness_onset",
            },
            {
                ["fallback"] = "Hands are numb and I can't stop shivering, {addressee.name}! I'm freezing out here!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.wound.received_beat.say.1.hypothermia_onset",
                ["variantID"] = "hypothermia_onset",
            },
            {
                ["fallback"] = "Dizzy from the heat, {addressee.name}... I'm overheating in this gear!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.wound.received_beat.say.1.hyperthermia_onset",
                ["variantID"] = "hyperthermia_onset",
            },
            {
                ["fallback"] = "Soaked to the bone and shivering, {addressee.name}—I'll catch a fever if I stay wet like this.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.wound.received_beat.say.1.soaked_chill",
                ["variantID"] = "soaked_chill",
            },
            {
                ["fallback"] = "Took a hit to my {slot.wound.part}, {addressee.name}, watch that angle!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.wound.received_beat.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
}
