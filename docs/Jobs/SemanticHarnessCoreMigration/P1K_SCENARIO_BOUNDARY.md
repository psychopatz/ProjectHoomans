# P1-K mixed scenario boundary

## Audit result

The remaining Hoomans `runtime/scenario.py` is not a second copy of the Core
document engine. It already aliases Core for display-name derivation, stable
actor IDs, deep merge, JSON load, and atomic JSON save.

The code that remains local is provider/domain policy:

- the Hoomans synthetic `DEFAULT_SCENARIO`;
- health normalization and legacy health compatibility;
- required PNC actor fields and semantic-lab profile validation;
- available-mod and provider fixture validation;
- save/import normalization at the Hoomans worker boundary.

Moving those pieces into Core would make Core own Project Hoomans policy and
would prevent DTAbstract and DTHoomans from supplying their own document
defaults. No further P1-K source extraction is safe.

## Next boundary

The next migration target is P2 semantic execution: inspect Hoomans semantic
adapters, conversation orchestration, output projection, and interaction
seams against the existing Core semantic services. Move contracts and generic
orchestration only; keep provider callbacks and provider data in adopters.
