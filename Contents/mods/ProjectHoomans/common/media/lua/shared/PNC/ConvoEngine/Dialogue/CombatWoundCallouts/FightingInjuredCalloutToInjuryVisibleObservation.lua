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
                                ["fallback"] = "Dressing on my {slot.wound.part} is taking all I've got, {addressee.name}, stay on my shoulder!",
                                ["id"] = "patched_up_lower_limb_severe",
                                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_lower_limb_severe",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Got my {slot.wound.part} patched up, {addressee.name}, still standing my ground!",
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
                    ["fallback"] = "Dressing on my {slot.wound.part} is taking all I've got, {addressee.name}, stay on my shoulder!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_lower_limb_severe",
                    ["variantID"] = "patched_up_lower_limb_severe",
                },
                {
                    ["fallback"] = "Got my {slot.wound.part} patched up, {addressee.name}, still standing my ground!",
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
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatWoundCallouts/FightingInjuredCalloutToInjuryVisibleObservation",
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
                                ["fallback"] = "Dressing on my {slot.wound.part} is taking all I've got, {addressee.name}, stay on my shoulder!",
                                ["id"] = "patched_up_lower_limb_severe",
                            },
                            {
                                ["fallback"] = "Got my {slot.wound.part} patched up, {addressee.name}, still standing my ground!",
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
                ["fallback"] = "Dressing on my {slot.wound.part} is taking all I've got, {addressee.name}, stay on my shoulder!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.fighting.injured_callout.say.1.patched_up_lower_limb_severe",
                ["variantID"] = "patched_up_lower_limb_severe",
            },
            {
                ["fallback"] = "Got my {slot.wound.part} patched up, {addressee.name}, still standing my ground!",
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
            ["familyID"] = "combat.injury.pain_reaction",
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
                                ["fallback"] = "Ah, scratched my {slot.wound.part}!",
                                ["id"] = "scratch_minor",
                                ["templateID"] = "convo.combat.injury.pain_reaction.say.1.scratch_minor",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Hmph. Barely grazed my {slot.wound.part}.",
                                ["id"] = "scratch_stoic",
                                ["templateID"] = "convo.combat.injury.pain_reaction.say.1.scratch_stoic",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Bastard nicked my {slot.wound.part}!",
                                ["id"] = "scratch_aggressive",
                                ["templateID"] = "convo.combat.injury.pain_reaction.say.1.scratch_aggressive",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Gah! Cut open my {slot.wound.part}!",
                                ["id"] = "laceration_moderate",
                                ["templateID"] = "convo.combat.injury.pain_reaction.say.1.laceration_moderate",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Agh! Torn deep across my {slot.wound.part}, bleeding fast!",
                                ["id"] = "laceration_severe",
                                ["templateID"] = "convo.combat.injury.pain_reaction.say.1.laceration_severe",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Son of a bitch sliced my {slot.wound.part}!",
                                ["id"] = "laceration_aggressive",
                                ["templateID"] = "convo.combat.injury.pain_reaction.say.1.laceration_aggressive",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Ngh, bad cut on my {slot.wound.part}. Still standing.",
                                ["id"] = "laceration_stoic",
                                ["templateID"] = "convo.combat.injury.pain_reaction.say.1.laceration_stoic",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Crack, agh! Something broke in my {slot.wound.part}!",
                                ["id"] = "fracture",
                                ["templateID"] = "convo.combat.injury.pain_reaction.say.1.fracture",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Gah! Ripped wide open on my {slot.wound.part}!",
                                ["id"] = "deep_wound",
                                ["templateID"] = "convo.combat.injury.pain_reaction.say.1.deep_wound",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Agh! Shards drove straight into my {slot.wound.part}!",
                                ["id"] = "deep_wound_glass",
                                ["templateID"] = "convo.combat.injury.pain_reaction.say.1.deep_wound_glass",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Agh! Searing burn across my {slot.wound.part}!",
                                ["id"] = "burn",
                                ["templateID"] = "convo.combat.injury.pain_reaction.say.1.burn",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Agh, I'm shot! Round hit my {slot.wound.part}!",
                                ["id"] = "bullet",
                                ["templateID"] = "convo.combat.injury.pain_reaction.say.1.bullet",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Ngh, took a round in my {slot.wound.part}!",
                                ["id"] = "bullet_stoic",
                                ["templateID"] = "convo.combat.injury.pain_reaction.say.1.bullet_stoic",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "No, agh! Teeth sank into my {slot.wound.part}!",
                                ["id"] = "bite",
                                ["templateID"] = "convo.combat.injury.pain_reaction.say.1.bite",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "No, no, no! It bit my {slot.wound.part}, get it off me!",
                                ["id"] = "bite_panicked",
                                ["templateID"] = "convo.combat.injury.pain_reaction.say.1.bite_panicked",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Agh! Filthy teeth tore my {slot.wound.part}, won't turn me, but it's bleeding hard!",
                                ["id"] = "bite_non_transmissible",
                                ["templateID"] = "convo.combat.injury.pain_reaction.say.1.bite_non_transmissible",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Agh, another hard hit on my {slot.wound.part}! I'm taking too many wounds!",
                                ["id"] = "multiple_hits_severe",
                                ["templateID"] = "convo.combat.injury.pain_reaction.say.1.multiple_hits_severe",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Gah, took a hit to my {slot.wound.part}!",
                                ["id"] = "default",
                                ["templateID"] = "convo.combat.injury.pain_reaction.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.injury",
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
                    ["fallback"] = "Ah, scratched my {slot.wound.part}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.injury.pain_reaction.say.1.scratch_minor",
                    ["variantID"] = "scratch_minor",
                },
                {
                    ["fallback"] = "Hmph. Barely grazed my {slot.wound.part}.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.injury.pain_reaction.say.1.scratch_stoic",
                    ["variantID"] = "scratch_stoic",
                },
                {
                    ["fallback"] = "Bastard nicked my {slot.wound.part}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.injury.pain_reaction.say.1.scratch_aggressive",
                    ["variantID"] = "scratch_aggressive",
                },
                {
                    ["fallback"] = "Gah! Cut open my {slot.wound.part}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.injury.pain_reaction.say.1.laceration_moderate",
                    ["variantID"] = "laceration_moderate",
                },
                {
                    ["fallback"] = "Agh! Torn deep across my {slot.wound.part}, bleeding fast!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.injury.pain_reaction.say.1.laceration_severe",
                    ["variantID"] = "laceration_severe",
                },
                {
                    ["fallback"] = "Son of a bitch sliced my {slot.wound.part}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.injury.pain_reaction.say.1.laceration_aggressive",
                    ["variantID"] = "laceration_aggressive",
                },
                {
                    ["fallback"] = "Ngh, bad cut on my {slot.wound.part}. Still standing.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.injury.pain_reaction.say.1.laceration_stoic",
                    ["variantID"] = "laceration_stoic",
                },
                {
                    ["fallback"] = "Crack, agh! Something broke in my {slot.wound.part}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.injury.pain_reaction.say.1.fracture",
                    ["variantID"] = "fracture",
                },
                {
                    ["fallback"] = "Gah! Ripped wide open on my {slot.wound.part}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.injury.pain_reaction.say.1.deep_wound",
                    ["variantID"] = "deep_wound",
                },
                {
                    ["fallback"] = "Agh! Shards drove straight into my {slot.wound.part}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.injury.pain_reaction.say.1.deep_wound_glass",
                    ["variantID"] = "deep_wound_glass",
                },
                {
                    ["fallback"] = "Agh! Searing burn across my {slot.wound.part}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.injury.pain_reaction.say.1.burn",
                    ["variantID"] = "burn",
                },
                {
                    ["fallback"] = "Agh, I'm shot! Round hit my {slot.wound.part}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.injury.pain_reaction.say.1.bullet",
                    ["variantID"] = "bullet",
                },
                {
                    ["fallback"] = "Ngh, took a round in my {slot.wound.part}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.injury.pain_reaction.say.1.bullet_stoic",
                    ["variantID"] = "bullet_stoic",
                },
                {
                    ["fallback"] = "No, agh! Teeth sank into my {slot.wound.part}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.injury.pain_reaction.say.1.bite",
                    ["variantID"] = "bite",
                },
                {
                    ["fallback"] = "No, no, no! It bit my {slot.wound.part}, get it off me!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.injury.pain_reaction.say.1.bite_panicked",
                    ["variantID"] = "bite_panicked",
                },
                {
                    ["fallback"] = "Agh! Filthy teeth tore my {slot.wound.part}, won't turn me, but it's bleeding hard!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.injury.pain_reaction.say.1.bite_non_transmissible",
                    ["variantID"] = "bite_non_transmissible",
                },
                {
                    ["fallback"] = "Agh, another hard hit on my {slot.wound.part}! I'm taking too many wounds!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.injury.pain_reaction.say.1.multiple_hits_severe",
                    ["variantID"] = "multiple_hits_severe",
                },
                {
                    ["fallback"] = "Gah, took a hit to my {slot.wound.part}!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.injury.pain_reaction.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "combat.injury.pain_reaction",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "pain_reaction",
            ["sourceId"] = "combat.injury.pain_reaction",
            ["sourcePath"] = "dialogue/combat_wound_callouts/combat_injury_pain_reaction.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatWoundCallouts/FightingInjuredCalloutToInjuryVisibleObservation",
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
            ["domains"] = {
                {
                    ["domain"] = "combat",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["events"] = {
                {
                    ["id"] = "combat_injury_pain_reaction",
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
                                ["fallback"] = "Ah, scratched my {slot.wound.part}!",
                                ["id"] = "scratch_minor",
                            },
                            {
                                ["fallback"] = "Hmph. Barely grazed my {slot.wound.part}.",
                                ["id"] = "scratch_stoic",
                            },
                            {
                                ["fallback"] = "Bastard nicked my {slot.wound.part}!",
                                ["id"] = "scratch_aggressive",
                            },
                            {
                                ["fallback"] = "Gah! Cut open my {slot.wound.part}!",
                                ["id"] = "laceration_moderate",
                            },
                            {
                                ["fallback"] = "Agh! Torn deep across my {slot.wound.part}, bleeding fast!",
                                ["id"] = "laceration_severe",
                            },
                            {
                                ["fallback"] = "Son of a bitch sliced my {slot.wound.part}!",
                                ["id"] = "laceration_aggressive",
                            },
                            {
                                ["fallback"] = "Ngh, bad cut on my {slot.wound.part}. Still standing.",
                                ["id"] = "laceration_stoic",
                            },
                            {
                                ["fallback"] = "Crack, agh! Something broke in my {slot.wound.part}!",
                                ["id"] = "fracture",
                            },
                            {
                                ["fallback"] = "Gah! Ripped wide open on my {slot.wound.part}!",
                                ["id"] = "deep_wound",
                            },
                            {
                                ["fallback"] = "Agh! Shards drove straight into my {slot.wound.part}!",
                                ["id"] = "deep_wound_glass",
                            },
                            {
                                ["fallback"] = "Agh! Searing burn across my {slot.wound.part}!",
                                ["id"] = "burn",
                            },
                            {
                                ["fallback"] = "Agh, I'm shot! Round hit my {slot.wound.part}!",
                                ["id"] = "bullet",
                            },
                            {
                                ["fallback"] = "Ngh, took a round in my {slot.wound.part}!",
                                ["id"] = "bullet_stoic",
                            },
                            {
                                ["fallback"] = "No, agh! Teeth sank into my {slot.wound.part}!",
                                ["id"] = "bite",
                            },
                            {
                                ["fallback"] = "No, no, no! It bit my {slot.wound.part}, get it off me!",
                                ["id"] = "bite_panicked",
                            },
                            {
                                ["fallback"] = "Agh! Filthy teeth tore my {slot.wound.part}, won't turn me, but it's bleeding hard!",
                                ["id"] = "bite_non_transmissible",
                            },
                            {
                                ["fallback"] = "Agh, another hard hit on my {slot.wound.part}! I'm taking too many wounds!",
                                ["id"] = "multiple_hits_severe",
                            },
                            {
                                ["fallback"] = "Gah, took a hit to my {slot.wound.part}!",
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
            ["responsePlanID"] = "combat.injury.pain_reaction",
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
                            ["fallback"] = "Ah, scratched my {slot.wound.part}!",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.injury.pain_reaction.say_1",
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
        },
        ["slots"] = {
            ["wound"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.item",
            },
        },
        ["sourceShard"] = "dialogue/combat_wound_callouts/combat_injury_pain_reaction.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Ah, scratched my {slot.wound.part}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.injury.pain_reaction.say.1.scratch_minor",
                ["variantID"] = "scratch_minor",
            },
            {
                ["fallback"] = "Hmph. Barely grazed my {slot.wound.part}.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.injury.pain_reaction.say.1.scratch_stoic",
                ["variantID"] = "scratch_stoic",
            },
            {
                ["fallback"] = "Bastard nicked my {slot.wound.part}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.injury.pain_reaction.say.1.scratch_aggressive",
                ["variantID"] = "scratch_aggressive",
            },
            {
                ["fallback"] = "Gah! Cut open my {slot.wound.part}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.injury.pain_reaction.say.1.laceration_moderate",
                ["variantID"] = "laceration_moderate",
            },
            {
                ["fallback"] = "Agh! Torn deep across my {slot.wound.part}, bleeding fast!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.injury.pain_reaction.say.1.laceration_severe",
                ["variantID"] = "laceration_severe",
            },
            {
                ["fallback"] = "Son of a bitch sliced my {slot.wound.part}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.injury.pain_reaction.say.1.laceration_aggressive",
                ["variantID"] = "laceration_aggressive",
            },
            {
                ["fallback"] = "Ngh, bad cut on my {slot.wound.part}. Still standing.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.injury.pain_reaction.say.1.laceration_stoic",
                ["variantID"] = "laceration_stoic",
            },
            {
                ["fallback"] = "Crack, agh! Something broke in my {slot.wound.part}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.injury.pain_reaction.say.1.fracture",
                ["variantID"] = "fracture",
            },
            {
                ["fallback"] = "Gah! Ripped wide open on my {slot.wound.part}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.injury.pain_reaction.say.1.deep_wound",
                ["variantID"] = "deep_wound",
            },
            {
                ["fallback"] = "Agh! Shards drove straight into my {slot.wound.part}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.injury.pain_reaction.say.1.deep_wound_glass",
                ["variantID"] = "deep_wound_glass",
            },
            {
                ["fallback"] = "Agh! Searing burn across my {slot.wound.part}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.injury.pain_reaction.say.1.burn",
                ["variantID"] = "burn",
            },
            {
                ["fallback"] = "Agh, I'm shot! Round hit my {slot.wound.part}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.injury.pain_reaction.say.1.bullet",
                ["variantID"] = "bullet",
            },
            {
                ["fallback"] = "Ngh, took a round in my {slot.wound.part}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.injury.pain_reaction.say.1.bullet_stoic",
                ["variantID"] = "bullet_stoic",
            },
            {
                ["fallback"] = "No, agh! Teeth sank into my {slot.wound.part}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.injury.pain_reaction.say.1.bite",
                ["variantID"] = "bite",
            },
            {
                ["fallback"] = "No, no, no! It bit my {slot.wound.part}, get it off me!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.injury.pain_reaction.say.1.bite_panicked",
                ["variantID"] = "bite_panicked",
            },
            {
                ["fallback"] = "Agh! Filthy teeth tore my {slot.wound.part}, won't turn me, but it's bleeding hard!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.injury.pain_reaction.say.1.bite_non_transmissible",
                ["variantID"] = "bite_non_transmissible",
            },
            {
                ["fallback"] = "Agh, another hard hit on my {slot.wound.part}! I'm taking too many wounds!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.injury.pain_reaction.say.1.multiple_hits_severe",
                ["variantID"] = "multiple_hits_severe",
            },
            {
                ["fallback"] = "Gah, took a hit to my {slot.wound.part}!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.injury.pain_reaction.say.1.default",
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
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatWoundCallouts/FightingInjuredCalloutToInjuryVisibleObservation",
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
            ["familyID"] = "combat.injury.visible_observation",
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
                                ["fallback"] = "You've got an open wound on your {slot.wound.part}, {addressee.name}. You should get that covered.",
                                ["id"] = "open_wound",
                                ["templateID"] = "convo.combat.injury.visible_observation.say.1.open_wound",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "You're bleeding hard from your {slot.wound.part}, {addressee.name}! Patch it up right now!",
                                ["id"] = "heavy_bleeding",
                                ["templateID"] = "convo.combat.injury.visible_observation.say.1.heavy_bleeding",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "That bandage on your {slot.wound.part} looks filthy, {addressee.name}. Change it when you can.",
                                ["id"] = "dirty_bandage",
                                ["templateID"] = "convo.combat.injury.visible_observation.say.1.dirty_bandage",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "That wound on your {slot.wound.part} might be infected, {addressee.name}.",
                                ["id"] = "suspected_infection",
                                ["templateID"] = "convo.combat.injury.visible_observation.say.1.suspected_infection",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Hold still, {addressee.name}. That wound on your {slot.wound.part} is inflamed, we need to disinfect and dress it.",
                                ["id"] = "medic_infection_assessment",
                                ["templateID"] = "convo.combat.injury.visible_observation.say.1.medic_infection_assessment",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Hold still, {addressee.name}. Let me see that {slot.wound.part}.",
                                ["id"] = "medic_triage_offer",
                                ["templateID"] = "convo.combat.injury.visible_observation.say.1.medic_triage_offer",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "You're favoring your {slot.wound.part} and limping, {addressee.name}. Don't push your stride too hard.",
                                ["id"] = "limp_mobility",
                                ["templateID"] = "convo.combat.injury.visible_observation.say.1.limp_mobility",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "You got hit again on your {slot.wound.part}, {addressee.name}! You're taking too many wounds!",
                                ["id"] = "multiple_wounds_escalation",
                                ["templateID"] = "convo.combat.injury.visible_observation.say.1.multiple_wounds_escalation",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Wait, {addressee.name}, you took a new hit on your {slot.wound.part} too?",
                                ["id"] = "new_wound_noticed",
                                ["templateID"] = "convo.combat.injury.visible_observation.say.1.new_wound_noticed",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "Wait... is that a bite mark on your {slot.wound.part}, {addressee.name}?",
                                ["id"] = "visible_bite",
                                ["templateID"] = "convo.combat.injury.visible_observation.say.1.visible_bite",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "You look feverish, {addressee.name}. Can you sit for a minute?",
                                ["id"] = "feverish_weak",
                                ["templateID"] = "convo.combat.injury.visible_observation.say.1.feverish_weak",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                            {
                                ["fallback"] = "You're hurt on your {slot.wound.part}, {addressee.name}. Take care of that wound.",
                                ["id"] = "default",
                                ["templateID"] = "convo.combat.injury.visible_observation.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 2,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "combat.injury",
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
                    ["fallback"] = "You've got an open wound on your {slot.wound.part}, {addressee.name}. You should get that covered.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.injury.visible_observation.say.1.open_wound",
                    ["variantID"] = "open_wound",
                },
                {
                    ["fallback"] = "You're bleeding hard from your {slot.wound.part}, {addressee.name}! Patch it up right now!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.injury.visible_observation.say.1.heavy_bleeding",
                    ["variantID"] = "heavy_bleeding",
                },
                {
                    ["fallback"] = "That bandage on your {slot.wound.part} looks filthy, {addressee.name}. Change it when you can.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.injury.visible_observation.say.1.dirty_bandage",
                    ["variantID"] = "dirty_bandage",
                },
                {
                    ["fallback"] = "That wound on your {slot.wound.part} might be infected, {addressee.name}.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.injury.visible_observation.say.1.suspected_infection",
                    ["variantID"] = "suspected_infection",
                },
                {
                    ["fallback"] = "Hold still, {addressee.name}. That wound on your {slot.wound.part} is inflamed, we need to disinfect and dress it.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.injury.visible_observation.say.1.medic_infection_assessment",
                    ["variantID"] = "medic_infection_assessment",
                },
                {
                    ["fallback"] = "Hold still, {addressee.name}. Let me see that {slot.wound.part}.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.injury.visible_observation.say.1.medic_triage_offer",
                    ["variantID"] = "medic_triage_offer",
                },
                {
                    ["fallback"] = "You're favoring your {slot.wound.part} and limping, {addressee.name}. Don't push your stride too hard.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.injury.visible_observation.say.1.limp_mobility",
                    ["variantID"] = "limp_mobility",
                },
                {
                    ["fallback"] = "You got hit again on your {slot.wound.part}, {addressee.name}! You're taking too many wounds!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.injury.visible_observation.say.1.multiple_wounds_escalation",
                    ["variantID"] = "multiple_wounds_escalation",
                },
                {
                    ["fallback"] = "Wait, {addressee.name}, you took a new hit on your {slot.wound.part} too?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.injury.visible_observation.say.1.new_wound_noticed",
                    ["variantID"] = "new_wound_noticed",
                },
                {
                    ["fallback"] = "Wait... is that a bite mark on your {slot.wound.part}, {addressee.name}?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.injury.visible_observation.say.1.visible_bite",
                    ["variantID"] = "visible_bite",
                },
                {
                    ["fallback"] = "You look feverish, {addressee.name}. Can you sit for a minute?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.injury.visible_observation.say.1.feverish_weak",
                    ["variantID"] = "feverish_weak",
                },
                {
                    ["fallback"] = "You're hurt on your {slot.wound.part}, {addressee.name}. Take care of that wound.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.combat.injury.visible_observation.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "combat.injury.visible_observation",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "visible_observation",
            ["sourceId"] = "combat.injury.visible_observation",
            ["sourcePath"] = "dialogue/combat_wound_callouts/combat_injury_visible_observation.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CombatWoundCallouts/FightingInjuredCalloutToInjuryVisibleObservation",
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
            ["domains"] = {
                {
                    ["domain"] = "combat",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["events"] = {
                {
                    ["id"] = "combat_injury_visible_observation",
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
                                ["fallback"] = "You've got an open wound on your {slot.wound.part}, {addressee.name}. You should get that covered.",
                                ["id"] = "open_wound",
                            },
                            {
                                ["fallback"] = "You're bleeding hard from your {slot.wound.part}, {addressee.name}! Patch it up right now!",
                                ["id"] = "heavy_bleeding",
                            },
                            {
                                ["fallback"] = "That bandage on your {slot.wound.part} looks filthy, {addressee.name}. Change it when you can.",
                                ["id"] = "dirty_bandage",
                            },
                            {
                                ["fallback"] = "That wound on your {slot.wound.part} might be infected, {addressee.name}.",
                                ["id"] = "suspected_infection",
                            },
                            {
                                ["fallback"] = "Hold still, {addressee.name}. That wound on your {slot.wound.part} is inflamed, we need to disinfect and dress it.",
                                ["id"] = "medic_infection_assessment",
                            },
                            {
                                ["fallback"] = "Hold still, {addressee.name}. Let me see that {slot.wound.part}.",
                                ["id"] = "medic_triage_offer",
                            },
                            {
                                ["fallback"] = "You're favoring your {slot.wound.part} and limping, {addressee.name}. Don't push your stride too hard.",
                                ["id"] = "limp_mobility",
                            },
                            {
                                ["fallback"] = "You got hit again on your {slot.wound.part}, {addressee.name}! You're taking too many wounds!",
                                ["id"] = "multiple_wounds_escalation",
                            },
                            {
                                ["fallback"] = "Wait, {addressee.name}, you took a new hit on your {slot.wound.part} too?",
                                ["id"] = "new_wound_noticed",
                            },
                            {
                                ["fallback"] = "Wait... is that a bite mark on your {slot.wound.part}, {addressee.name}?",
                                ["id"] = "visible_bite",
                            },
                            {
                                ["fallback"] = "You look feverish, {addressee.name}. Can you sit for a minute?",
                                ["id"] = "feverish_weak",
                            },
                            {
                                ["fallback"] = "You're hurt on your {slot.wound.part}, {addressee.name}. Take care of that wound.",
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
            ["responsePlanID"] = "combat.injury.visible_observation",
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
                            ["fallback"] = "You've got an open wound on your {slot.wound.part}, {addressee.name}. You should get that covered.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.combat.injury.visible_observation.say_1",
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
        },
        ["slots"] = {
            ["wound"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.item",
            },
        },
        ["sourceShard"] = "dialogue/combat_wound_callouts/combat_injury_visible_observation.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "You've got an open wound on your {slot.wound.part}, {addressee.name}. You should get that covered.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.injury.visible_observation.say.1.open_wound",
                ["variantID"] = "open_wound",
            },
            {
                ["fallback"] = "You're bleeding hard from your {slot.wound.part}, {addressee.name}! Patch it up right now!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.injury.visible_observation.say.1.heavy_bleeding",
                ["variantID"] = "heavy_bleeding",
            },
            {
                ["fallback"] = "That bandage on your {slot.wound.part} looks filthy, {addressee.name}. Change it when you can.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.injury.visible_observation.say.1.dirty_bandage",
                ["variantID"] = "dirty_bandage",
            },
            {
                ["fallback"] = "That wound on your {slot.wound.part} might be infected, {addressee.name}.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.injury.visible_observation.say.1.suspected_infection",
                ["variantID"] = "suspected_infection",
            },
            {
                ["fallback"] = "Hold still, {addressee.name}. That wound on your {slot.wound.part} is inflamed, we need to disinfect and dress it.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.injury.visible_observation.say.1.medic_infection_assessment",
                ["variantID"] = "medic_infection_assessment",
            },
            {
                ["fallback"] = "Hold still, {addressee.name}. Let me see that {slot.wound.part}.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.injury.visible_observation.say.1.medic_triage_offer",
                ["variantID"] = "medic_triage_offer",
            },
            {
                ["fallback"] = "You're favoring your {slot.wound.part} and limping, {addressee.name}. Don't push your stride too hard.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.injury.visible_observation.say.1.limp_mobility",
                ["variantID"] = "limp_mobility",
            },
            {
                ["fallback"] = "You got hit again on your {slot.wound.part}, {addressee.name}! You're taking too many wounds!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.injury.visible_observation.say.1.multiple_wounds_escalation",
                ["variantID"] = "multiple_wounds_escalation",
            },
            {
                ["fallback"] = "Wait, {addressee.name}, you took a new hit on your {slot.wound.part} too?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.injury.visible_observation.say.1.new_wound_noticed",
                ["variantID"] = "new_wound_noticed",
            },
            {
                ["fallback"] = "Wait... is that a bite mark on your {slot.wound.part}, {addressee.name}?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.injury.visible_observation.say.1.visible_bite",
                ["variantID"] = "visible_bite",
            },
            {
                ["fallback"] = "You look feverish, {addressee.name}. Can you sit for a minute?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.injury.visible_observation.say.1.feverish_weak",
                ["variantID"] = "feverish_weak",
            },
            {
                ["fallback"] = "You're hurt on your {slot.wound.part}, {addressee.name}. Take care of that wound.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.combat.injury.visible_observation.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
}
