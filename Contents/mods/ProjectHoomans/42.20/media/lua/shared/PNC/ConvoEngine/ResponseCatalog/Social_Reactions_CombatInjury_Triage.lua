-- Combat injury triage exchange flow response pools.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local ConvoPlanFamily = require
    "PNC/ConvoEngine/ResponseCatalog/ConvoPlanFamily"

local Catalog = PNC.ConvoEngine.ResponseCatalog
if type(Catalog) ~= "table" or type(Catalog.Register) ~= "function" then
    return false
end

local CONTENT_OWNER = "projecthoomans.dialogue_content.events"
local T = "combat.injury.triage_exchange"

local function registerTriageFlowPool(poolID, variants)
    local out = {}
    for _, v in ipairs(variants) do
        ConvoPlanFamily.install(v.tpl, { defaultContentOwner = CONTENT_OWNER })
        out[#out + 1] = {
            id = poolID .. "." .. v.id,
            templateID = v.tpl,
            fallback = v.fb,
            contentOwner = CONTENT_OWNER,
            when = v.when,
            priority = v.pri or 50,
            plan = {
                dialogueAct = v.act or "INFORM",
                sourcePoolID = poolID,
                topic = "combat_injury",
                turns = { {
                    segments = {
                        { kind = "translation", templateID = v.tpl, fallback = v.fb },
                    },
                    offers = {},
                } },
            },
        }
    end
    Catalog.Register(poolID, { variants = out })
end

registerTriageFlowPool("semantic.flow.combat.injury.triage.open", {
    { id = "bitten", tpl = T .. ".bite_quarantined", fb = "Teeth caught me in the scramble! Help me clear a lane so we can check the bite!", when = { isBitten = true }, pri = 95 },
    { id = "open_wounds", tpl = T .. ".covered_for_treatment", fb = "Still bleeding through my clothes—cover my front while I tie this wound off!", when = { hasOpenWounds = true }, pri = 85 },
    { id = "default", tpl = T, fb = "Still holding my ground, caught a hit and keeping eyes forward.", pri = 50 },
})

registerTriageFlowPool("semantic.flow.combat.injury.triage.assess", {
    { id = "covered", tpl = T .. ".covered_for_treatment", fb = "Thanks! Keep them off my back while I tie off this open bleed.", when = { stateValue = "covered_for_treatment" }, pri = 95 },
    { id = "reassured", tpl = T .. ".reassured_bond", fb = "Heard you loud and clear. Still breathing, still swinging beside you.", when = { stateValue = "reassured_bond" }, pri = 90 },
    { id = "open_wounds", tpl = T .. ".covered_for_treatment", fb = "The hit tore deep and it's still bleeding—give me two seconds of cover to wrap it!", when = { hasOpenWounds = true }, pri = 80 },
    { id = "default", tpl = T .. ".patched_push_on", fb = "Dressings are tight. Stay on my side and we'll sweep the rest of them.", pri = 50 },
})

registerTriageFlowPool("semantic.flow.combat.injury.triage.bite_check", {
    { id = "non_transmissible", tpl = T .. ".bite_non_lethal_stabilized", fb = "Thank god saliva doesn't carry it here. Still stings awful, wrapping it tight now.", when = { salivaTransmissible = false }, pri = 95 },
    { id = "default", tpl = T .. ".bite_quarantined", fb = "Teeth broke the skin. Let's clear the stragglers first and I'll keep my distance.", pri = 50 },
})

registerTriageFlowPool("semantic.flow.combat.injury.triage.squad_interject", {
    { id = "threatened", tpl = T .. ".bite_psychopath_threatened", fb = "Keep that barrel down! We finish clearing the dead before anyone talks about executions.", when = { stateValue = "bite_psychopath_threatened" }, pri = 95 },
    { id = "default", tpl = T .. ".reassured_bond", fb = "Eyes on the perimeter! Hold the line together while we sort this wound out.", pri = 50 },
})

registerTriageFlowPool("semantic.flow.combat.injury.triage.tactical_order", {
    { id = "fallback", tpl = T .. ".ordered_fallback", fb = "Alright, backing up two steps behind you. Cover me while I catch my breath!", when = { stateValue = "ordered_fallback" }, pri = 95 },
    { id = "covered", tpl = T .. ".covered_for_treatment", fb = "Wrapping it right behind you—keep those walkers off my shoulder!", when = { stateValue = "covered_for_treatment" }, pri = 92 },
    { id = "default", tpl = T .. ".patched_push_on", fb = "Dressings are holding. Stay on my flank and we push through.", pri = 50 },
})

registerTriageFlowPool("semantic.flow.combat.injury.triage.bite_standoff", {
    { id = "non_lethal", tpl = T .. ".bite_non_lethal_stabilized", fb = "Saliva doesn't turn people here—just let me wrap the tear and keep fighting!", when = { stateValue = "bite_non_lethal_stabilized" }, pri = 96 },
    { id = "threatened", tpl = T .. ".bite_psychopath_threatened", fb = "Keep that barrel down! We finish clearing the dead before anyone talks about executions.", when = { stateValue = "bite_psychopath_threatened" }, pri = 94 },
    { id = "default", tpl = T .. ".bite_quarantined", fb = "I know the rules. Help me clear the stragglers and I'll stay apart from the group.", pri = 50 },
})

registerTriageFlowPool("semantic.flow.combat.injury.triage.resolved", {
    { id = "fallback", tpl = T .. ".ordered_fallback", fb = "Pulling back to rear guard now—watch the front!", when = { stateValue = "ordered_fallback" }, pri = 95 },
    { id = "covered", tpl = T .. ".covered_for_treatment", fb = "Tying off the dressing under your cover right now!", when = { stateValue = "covered_for_treatment" }, pri = 94 },
    { id = "non_lethal", tpl = T .. ".bite_non_lethal_stabilized", fb = "Bite's wrapped tight and saliva isn't lethal here. Back in formation!", when = { stateValue = "bite_non_lethal_stabilized" }, pri = 93 },
    { id = "quarantined", tpl = T .. ".bite_quarantined", fb = "Understood. I'll keep my distance from the squad and watch for fever.", when = { stateValue = "bite_quarantined" }, pri = 92 },
    { id = "threatened", tpl = T .. ".bite_psychopath_threatened", fb = "Nobody's firing on our own while I'm standing here. Eyes back on the dead!", when = { stateValue = "bite_psychopath_threatened" }, pri = 91 },
    { id = "reassured", tpl = T .. ".reassured_bond", fb = "Heard you loud and clear. Still breathing, still swinging beside you.", when = { stateValue = "reassured_bond" }, pri = 90 },
    { id = "refused", tpl = T .. ".refused", fb = "Save the talk for when there aren't teeth snapping in our faces!", when = { intent = "REFUSE" }, pri = 88 },
    { id = "default", tpl = T .. ".patched_push_on", fb = "Dressings are tight. Stay on my side and we'll sweep the rest of them.", pri = 50 },
})

return true
