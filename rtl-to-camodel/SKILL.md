---
name: rtl-to-camodel
description: Use when migrating RTL design modules into cycle-accurate C++ CModel/CAModel implementations, analyzing how RTL timing maps to CModel behavior, or verifying migrated CModel modules against RTL function and cycle timing.
---

# RTL to CAModel

## Purpose

Use this skill to migrate RTL design modules into cycle-accurate C++ CModel/CAModel implementations. The target is functional and cycle-level equivalence with RTL, not a simplified functional approximation.

## Trigger Rules

Use this skill when the user asks to:

- Migrate an RTL module into CModel or CAModel.
- Implement a C++ cycle-accurate model from RTL.
- Compare or align an existing CModel/CAModel module against RTL function and timing.
- Analyze RTL behavior before writing the matching CModel/CAModel.

Do not use this skill for:

- RTL-only analysis with no CModel/CAModel migration or alignment goal.
- CModel-only bug fixes where RTL is not the reference.
- Generic refactors, formatting, or documentation tasks.
- Non-cycle-accurate functional modeling unless the user explicitly says RTL timing matters.

## Non-Negotiable Rules

- Do not simplify RTL behavior to finish faster.
- Do not guess about timing, handshake, queue, state-update, or pipeline semantics. Ask the user before writing code if these are unclear.
- Do not modify the basic model unless the user explicitly authorizes it.
- Only modify the requested module and migration-required files. Avoid unrelated refactors.
- Think like hardware: distinguish combinational decisions, old register values, sampled inputs, clock-edge updates, and next-cycle visible state.
- For first-time migration of a module, do not edit code until you have written the key RTL timing understanding and CModel mapping plan and the user has approved it.

## Required Context Pass

For a first pass on a module, read the user-specified files plus the closest available context:

1. RTL source for the target module and its immediate interfaces.
2. Existing CModel/CAModel basic model interfaces, ports, queues, and clock/update conventions.
3. Similar migrated modules already present in the repository.
4. Relevant tests, dump/replay utilities, timing configuration, and mapping documents.
5. User-provided design notes or known-difference reports.

If the repository contains `cmodel/make.sh`, inspect it before choosing CModel build, unit test, dump, replay, or timing replay commands.

## Migration Workflow

1. **Define the boundary**: identify inputs, outputs, clocks/resets, valid/ready signals, queues, memories, control state, data state, and task/transaction ownership.
2. **Extract RTL timing**: write down what is decided from old state in the current cycle, what is updated on the clock edge, and what becomes visible next cycle.
3. **Map to CModel structure**: map RTL registers, FIFOs, arbiters, handshakes, and pipeline stages to C++ state and `Clock()` ordering.
4. **Check timing hazards**: read `references/rtl-camodel-timing-checklist.md` before implementation or review.
5. **Ask on ambiguity**: if any cycle-affecting behavior remains uncertain, stop and ask the user before editing.
6. **Implement narrowly**: preserve existing local style and module boundaries; add helpers only when they clarify real hardware behavior.
7. **Verify with evidence**: run RTL and CModel tests where available, use xwave for RTL waveform evidence, and compare cycle-level behavior.
8. **Report clearly**: summarize function result, cycle timing match/mismatch, commands run, waveform evidence, and residual risk.

## Verification Requirements

Default verification strength is strict:

- Run the corresponding RTL test when available.
- Run CModel build/unit test/replay or timing replay when available.
- Use the `xwave` skill to inspect RTL waveform behavior whenever proving RTL cycle timing.
- Compare key per-cycle state: valid/ready handshakes, queue push/pop, issue/dispatch, state table updates, output packets, completion signals, and externally visible side effects.

RTL-to-CModel replay rules:

- Strict replay must start from reset release by default. Extract the RTL trace from the reset-deasserted cycle, reset the CModel to the same initial state, then replay every cycle forward.
- Do not use a cropped business-event window, synthetic warm-up, or hand-built pre-state as a shortcut to claim full strict alignment. Those modes may be used only as debug aids or when the user explicitly approves them, and the report must label them as partial/windowed evidence.
- Replay traces should record all relevant module boundary ports every cycle: input valid/ready/payload, output valid/ready/payload, external memory or bus responses, and backpressure signals. Event-only traces are acceptable for narrow debugging but are not enough to prove full-cycle equivalence.
- Put reusable replay machinery in shared dump/replay infrastructure: cycle scheduler, JSONL reader, valid/ready adapters, output comparators, reset handling, external bus responders, and reports. Module-specific replay code should only bind ports, define payload schemas, and encode/decode module-specific fields.
- If replay starts after reset release, state exactly what RTL state may already exist and do not claim complete function/timing equivalence for that testcase.

If any required input is missing, such as RTL test command, waveform path, replay data, or CModel command, do not claim full alignment. State exactly what was verified, what was not verified, and what is needed next.

## Reusable Verification Runbook

Use this fixed flow for RTL-to-CModel design and verification unless the module has a stronger project-specific runbook:

1. **Code understanding pass**
   - Read the RTL boundary module first: valid/ready ports, payload fields, FIFO/skid buffers, arbiters, ID allocation, reset behavior, and clocking-block sampling.
   - Then read the CModel counterpart: `Clock()` order, `BasicInterface` semantics, queue ownership, and every port push/pop or read/write location.
   - Write down which RTL decisions are combinational, which use old register state, which update at posedge, and which become visible next cycle.
   - Do not add or remove latency just to satisfy one testcase. Any timing change must map to an RTL register, FIFO, arbitration, or interface boundary root cause.

2. **CModel build and ordinary regression**
   - Build: `cd <repo>/cmodel/build && cmake --build . --target runUnitTest -j4`.
   - Run one module: `TRAVERSAL_ORDER=insertion ./runUnitTest --gtest_filter=<module>.*`.
   - Add `PRINT_LEVEL=2` only when detailed cycle logs are needed.
   - Keep reusable dump/replay code under `cmodel/src/dump_replay/`.
   - Verify the common replay layer with `./runUnitTest --gtest_filter=CmodelDumpReplay.*`.

3. **RTL waveform to CModel strict replay**
   - Strict replay defaults to reset-start: start extracting from reset release, reset the CModel to the same initial state, and replay every cycle forward.
   - Convert waveforms with `fsdb2vcd input.fsdb -o output.vcd` before VCD-based extraction.
   - The trace must sample module-boundary ports every cycle: input valid/ready/payload, output valid/ready/payload, external AXI/RAM responses, and backpressure.
   - The replay driver drives only RTL-observed input valid/payload and output ready/backpressure. CModel-generated ready, valid, and payload must be compared against RTL each cycle.
   - If a trace starts after reset release, label it debug/windowed and do not claim complete function or timing equivalence.

4. **BIU examples, not global requirements**
   - Read extractor: `cmodel/unit_tests/biu/extract_biu_read_trace_from_vcd.py`.
   - ARU extractor: `cmodel/unit_tests/biu/extract_biu_aru_trace_from_vcd.py`.
   - Read replay: `BIU_RTL_READ_TRACE_JSONL=<trace.jsonl> BIU_RTL_REPLAY_FAIL_FAST=1 TRAVERSAL_ORDER=insertion ./runUnitTest --gtest_filter=biu.rtl_trace_replay_read_jsonl`.
   - ARU replay: `BIU_RTL_TRACE_JSONL=<trace.jsonl> BIU_RTL_REPLAY_FAIL_FAST=1 TRAVERSAL_ORDER=insertion ./runUnitTest --gtest_filter=biu.rtl_trace_replay_aru_write_jsonl`.
   - Mixed replay: set both `BIU_RTL_READ_TRACE_JSONL` and `BIU_RTL_TRACE_JSONL`, then run `./runUnitTest --gtest_filter=biu.rtl_trace_replay_mixed_jsonl`.
   - Archived BIU comparison: `cmodel/unit_tests/biu/compare_biu_archived_traces.sh <ARCHIVE_DIR>`.

5. **Result labels**
   - `strict-timing`: reset-start RTL trace replay passes, with cycle timing and byte/bit payload matching.
   - `functional-pass`: CModel tests pass, but RTL waveform replay has not proven cycle timing.
   - `subset`: only the core semantics or a subset of the RTL testcase is covered.
   - `not-proven`: missing RTL waveform, missing CModel counterpart, missing replay driver, or incomplete trace.
   - Env-driven replay tests that `SKIP` because no trace env is set are normal, but they never count as strict pass.

6. **Mismatch triage order**
   - First check replay mechanics: reset-start coverage, trace completeness, valid-hold behavior, output-ready consumption, and payload schema.
   - Then check external models: AXI/RAM response legality, same-ID ordering, random delay policy, and backpressure reproduction.
   - Only after those are ruled out, modify the CModel design, and tie the fix to the RTL structure that explains the cycle or payload mismatch.

## Final Response Format

Prefer Chinese unless the user asks otherwise. Use concise tables when they make timing or evidence easier to read.

Include:

- Changed files and why.
- Functional comparison result.
- Cycle-level timing comparison result.
- Commands run and their outcomes.
- xwave evidence, or why xwave could not be used.
- Remaining risks or assumptions.

## References

- `references/rtl-camodel-timing-checklist.md`: checklist for common RTL-to-CModel timing mismatches, distilled from known SU CModel vs RTL differences.
