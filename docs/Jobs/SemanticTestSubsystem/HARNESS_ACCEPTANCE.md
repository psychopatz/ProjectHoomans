# Harness Acceptance — Final Closure Hardening

## A6R9 regression-authority gate

Require:

- no active GUI behavioral path using `kind="regression"`;
- no hard-coded greeting/follow behavioral matrix bypassing semantic fixtures;
- lifecycle/rejection/selection/general Regression actions resolve canonical semantic fixtures;
- dead legacy regression helpers removed;
- existing GUI fixture acceptance remains green.

## A6R10 assertion and naming gate

Require:

- realization cases assert their named realization outcome or are renamed/reclassified;
- response-pool fixture overlap reviewed and redundant coverage consolidated;
- fixture overlap report remains bounded;
- obsolete phase labels removed from active test descriptions/docstrings/classification where they are historical-only;
- retained Python test filename policy has an automated guard.

## A6R11 migration gate

For high-value direct-worker candidates:

- compare current Python behavior to fixture coverage;
- add missing fixture assertions/cases where necessary;
- rerun parity;
- remove redundant behavioral methods only after parity;
- retain exact API/protocol/editor/quality/save/native/performance contracts;
- regenerate classification with current descriptive reasons.

Fail the gate if ordinary semantic scenario→input→outcome tests remain LOW_LEVEL solely because they call the production worker.

## A6R12 final gate

From exact committed participant vector:

- Core fixture/authority tests PASS;
- fixture lint PASS with zero exact duplicates/naming/domain-path violations;
- full semantic corpus PASS;
- focused retained/migrated Python suites PASS;
- no historical C0A/legacy regression fixture authority remains;
- no active parallel GUI behavioral regression lane remains;
- active job docs and durable policies agree on COMPLETE.

The final handoff must be a committed handoff containing the participant commit vector.
