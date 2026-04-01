# Implementation Plan: Base Context Merging

## Overview

Modify `_sync_input_map()` in `input_system.gd` to merge the base context (index 0) with the top context using dictionary-based override, so that global actions like "pause" remain available when a gameplay context is pushed. No new files or classes are needed — only the single method changes. Tests validate correctness via unit tests and randomized property-based tests using the existing `InputGenerators` helper.

## Tasks

- [x] 1. Implement base-context merging in `_sync_input_map()`
  - [x] 1.1 Rewrite `_sync_input_map()` to merge base and top contexts
    - Modify `hiveminders/scripts/input/input_system.gd`
    - After erasing previously registered actions and checking for empty stack:
      - Identify base context (`_context_stack[0]`) and top context (`_context_stack.back()`)
      - If base == top (stack size 1), register only that context (current behavior, no duplication)
      - Otherwise, build `merged_actions: Dictionary` (String → ActionDefinition): insert all base actions, then overlay all top actions (top wins on collision)
      - Register every action from `merged_actions` into InputMap
      - Build `merged_bindings: Dictionary` (String → ActionBinding) for the active scheme: insert base bindings, then overlay top bindings (top wins on collision)
      - Attach each merged binding's events to InputMap
    - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2, 2.3, 3.1, 3.2, 4.1, 6.1, 6.2, 6.3_

- [x] 2. Checkpoint — Verify implementation compiles
  - Ensure the modified `input_system.gd` has no syntax errors, ask the user if questions arise.

- [x] 3. Write unit tests for base-context merging
  - [x] 3.1 Create test file `hiveminders/tests/test_base_context_merging.gd`
    - Create a new GDScript test file extending Node, following the same pattern as `test_csv_bindings.gd`
    - Include a helper to build `InputContextBindings` with specific action names and bindings for test scenarios
    - Include a helper to set up an `InputSystem` node with a controlled `_bindings_registry` and `_context_stack`
    - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2, 2.3_

  - [x] 3.2 Write unit test: single context on stack registers only base actions
    - Push only "base" context, call `_sync_input_map()`, assert exactly base actions are registered with no duplication
    - _Requirements: 1.2, 4.3_

  - [x] 3.3 Write unit test: two contexts with no overlapping actions registers union
    - Push "base" then a top context with entirely different action names, assert all base + top actions are registered
    - _Requirements: 1.1, 5.1, 6.1_

  - [x] 3.4 Write unit test: top context overrides colliding base action
    - Create a top context that redefines a base action (e.g. "pause") with different binding events and action_type, assert the top's values are used
    - _Requirements: 2.1, 2.2_

  - [x] 3.5 Write unit test: non-overridden base actions retain base bindings
    - Push a top context that does not define a base action, assert that base action's bindings are unchanged
    - _Requirements: 1.3, 2.3_

  - [x] 3.6 Write unit test: pop back to base restores base-only actions
    - Push a top context, then pop it, assert only base actions remain registered
    - _Requirements: 4.2, 4.3_

  - [x] 3.7 Write unit test: scheme switch while merged updates bindings correctly
    - Push two contexts, switch scheme from KEYBOARD_MOUSE to GAMEPAD, assert bindings update to gamepad scheme for both base and top actions
    - _Requirements: 3.1, 3.2, 3.3_

- [x] 4. Checkpoint — Ensure all unit tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Write property-based tests for base-context merging
  - [ ]* 5.1 Write property test for Property 1: Merged action set equals union of base and top action names
    - **Property 1: Merged action set equals the union of base and top action names**
    - Generate random base and top `InputContextBindings` using `InputGenerators`, sync InputMap, assert registered actions == set union of base + top action names
    - Run minimum 100 iterations with randomized inputs
    - **Validates: Requirements 1.1, 5.1, 5.2, 6.1**

  - [ ]* 5.2 Write property test for Property 2: Top context wins on name collision
    - **Property 2: Top context wins on name collision**
    - Generate base and top contexts with forced overlapping action names but different action_types and binding events, sync, assert colliding actions use top's values
    - Run minimum 100 iterations with randomized inputs
    - **Validates: Requirements 2.1, 2.2**

  - [ ]* 5.3 Write property test for Property 3: Non-overridden base actions retain base definitions and bindings
    - **Property 3: Non-overridden base actions retain base definitions and bindings**
    - Generate contexts with some non-overlapping base actions, sync, assert those actions use base's binding events
    - Run minimum 100 iterations with randomized inputs
    - **Validates: Requirements 1.3, 2.3**

  - [ ]* 5.4 Write property test for Property 4: Scheme-aware binding selection during merge
    - **Property 4: Scheme-aware binding selection during merge**
    - Generate contexts with distinct gamepad vs keyboard bindings, sync under each scheme, assert only the correct scheme's bindings are attached
    - Run minimum 100 iterations with randomized inputs
    - **Validates: Requirements 3.1, 3.2**

  - [ ]* 5.5 Write property test for Property 5: No duplicate action registrations
    - **Property 5: No duplicate action registrations**
    - Generate random contexts, sync, assert `_registered_actions` has no duplicate entries
    - Run minimum 100 iterations with randomized inputs
    - **Validates: Requirements 6.2**

- [x] 6. Final checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- The only production file modified is `hiveminders/scripts/input/input_system.gd` — specifically `_sync_input_map()`
- Property tests use `InputGenerators` from `hiveminders/tests/helpers/input_generators.gd` for randomized data
- Test file follows the existing pattern in `test_csv_bindings.gd` (extends Node, `_ready()` calls test functions, uses `assert()`)
