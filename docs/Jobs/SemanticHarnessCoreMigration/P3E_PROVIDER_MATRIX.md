# P3-E — optional provider launch matrix

## Result

Project Hoomans now advertises `DTCommon` and `DTHoomans` only when the
optional DynamicTrading runtime is discovered. With DynamicTrading absent,
the Hoomans profile remains Core + ProjectHoomans and still launches with
physical materialization.

DynamicTrading's `dtabstract` and `dthoomans` profile selections are both fed
through Core's `WorkerLaunchSpec.from_profile_selection()`. Their neutral
environment is required to equal the Core selection metadata, while their
materialization modes remain respectively `abstract` and `physical`.

No provider-specific worker or merchant policy moved into Core. DTCommon,
DTAbstract, and DTHoomans remain optional adopters of the same Core contract.

## Gates

- Hoomans runtime configuration matrix: 5 passing.
- DynamicTrading provider-adapter matrix: 4 passing.
- Core full suite remains green at 36 tests.
- Optional-provider discovery remains non-fatal when the sibling repository is
  absent; native SP/MP behavior remains a user-owned gate.
