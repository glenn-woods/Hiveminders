# Implementation Plan: Input System

## Overview

Incremental build-up of the input system for Godot 4.x in GDScript. We start with the resource data types, then the core autoload, then scheme detection, context stack, InputMap sync, default bindings, and finally wiring + testing. Each step produces runnable code that builds on the previous step.

## Tasks

- [x] 1. Create resource data types
  - [x] 1.1 Create ActionDefinition resource class
    - Create `scripts/input/action_definition.gd` with `class_name ActionDefinition extends Resource`
    - Export `action_name: String` and `action_type` (int enum matching InputSystem.ActionType: BOOL=0, AXIS=1, VECTOR2=2)
    - _Requirements: 1.1, 1.3_

  - [x] 1.2 Create ActionBinding resource class
    - Create `scripts/input/action_binding.gd` with `class_name ActionBinding extends Resource`
    - Export `action_name: String` and `events: Array[InputEvent]`
    - _Requirements: 1.2_

  - [x] 1.3 Create InputContextBindings resource class
    - Create `scripts/input/input_context_bindings.gd` with `class_name InputContextBindings extends Resource`
    - Export `context_name: String`, `actions: Array[ActionDefinition]`, `gamepad_bindings: Array[ActionBinding]`, `keyboard_mouse_bindings: Array[ActionBinding]`
    - _Requirements: 3.1, 5.4_

- [x] 2. Implement InputSystem autoload core
  - [x] 2.1 Create InputSystem script with enums, signals, and state
    - Create `scripts/input/input_system.gd` with `class_name InputSystem extends Node`
    - Define `InputScheme` enum (GAMEPAD, KEYBOARD_MOUSE) and `ActionType` enum (BOOL, AXIS, VECTOR2)
    - Declare signals: `active_scheme_changed(scheme: InputScheme)`, `context_changed(context_name: String)`
    - Declare state vars: `_active_scheme`, `_context_stack: Array[InputContextBindings]`, `_bindings_registry: Dictionary`
    - Implement public getters: `get_active_scheme()`, `get_active_context_name()`
    - _Requirements: 1.1, 2.1, 2.4, 3.6_

  - [x] 2.2 Implement `_sync_input_map()` method
    - Erase all actions currently registered by the system from InputMap
    - Read the top context from `_context_stack`
    - Register each `ActionDefinition` via `InputMap.add_action()`
    - Select the correct binding array based on `_active_scheme`
    - Add each event via `InputMap.action_add_event()`, skipping bindings whose `action_name` is not in the context's actions (log warning)
    - _Requirements: 4.1, 4.2, 1.2, 1.4, 3.4_

  - [ ]* 2.3 Write property test for Action Registration Completeness
    - **Property 1: Action Registration Completeness**
    - Generate random `InputContextBindings` with 1–20 `ActionDefinition` entries, call `_sync_input_map()`, assert all action names exist in `InputMap`
    - **Validates: Requirements 1.1, 4.1**

  - [ ]* 2.4 Write property test for Binding Correctness After Sync
    - **Property 2: Binding Correctness After Sync**
    - Generate random contexts with random bindings per scheme, call `_sync_input_map()`, assert InputMap events for each action exactly match the context's scheme-specific binding array
    - **Validates: Requirements 1.2, 3.1, 3.2, 3.4, 4.2**

  - [ ]* 2.5 Write property test for Unbound Events Are Not Registered
    - **Property 4: Unbound Events Are Not Registered**
    - Generate random context + random events NOT in bindings, assert those events are absent from InputMap after sync
    - **Validates: Requirements 1.4**

- [x] 3. Implement scheme detection
  - [x] 3.1 Implement `_input(event)` for scheme detection
    - Classify `InputEventJoypadButton` and `InputEventJoypadMotion` (above deadzone) as GAMEPAD
    - Classify `InputEventKey` and `InputEventMouseButton` as KEYBOARD_MOUSE
    - Ignore `InputEventMouseMotion` entirely
    - If detected scheme differs from `_active_scheme`, update `_active_scheme`, call `_sync_input_map()`, emit `active_scheme_changed`
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

  - [ ]* 3.2 Write property test for Scheme Detection Correctness
    - **Property 5: Scheme Detection Correctness**
    - Generate random starting scheme + random qualifying events, assert scheme switches correctly
    - **Validates: Requirements 2.1, 2.2, 2.3**

  - [ ]* 3.3 Write property test for Scheme Change Signal Emission
    - **Property 6: Scheme Change Signal Emission**
    - Generate random event sequences, count signal emissions, assert signal fires exactly once per actual scheme change and zero times when scheme matches
    - **Validates: Requirements 2.4**

- [x] 4. Checkpoint
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Implement context stack operations
  - [x] 5.1 Implement `push_context()` and `pop_context()`
    - `push_context(name)`: look up name in `_bindings_registry`, push onto `_context_stack`, call `_sync_input_map()`, emit `context_changed`; if name not found, `push_warning()` and no-op
    - `pop_context()`: if stack size > 1, pop top, call `_sync_input_map()`, emit `context_changed`; if stack size == 1, `push_warning()` and no-op
    - _Requirements: 3.1, 3.2, 3.3, 3.5, 3.6_

  - [ ]* 5.2 Write property test for Context Stack Round-Trip
    - **Property 3: Context Stack Round-Trip**
    - Generate random initial stack + random context to push, push then pop, assert InputMap state is identical to state before push
    - **Validates: Requirements 3.3**

- [x] 6. Implement resource loading and `_ready()`
  - [x] 6.1 Implement `_ready()` to load binding resources and push initial context
    - Scan `res://input/contexts/` directory for `.tres` files (or load a known list)
    - Populate `_bindings_registry` with each loaded `InputContextBindings` keyed by `context_name`
    - Push the initial base context onto the stack
    - Call `_sync_input_map()` to set up InputMap for the default scheme
    - _Requirements: 4.1, 5.3_

- [x] 7. Create default binding resources
  - [x] 7.1 Create base context `.tres` resource file
    - Create `input/contexts/base.tres` as an `InputContextBindings` resource
    - Define actions: `pause` (BOOL), `toggle_mode` (BOOL)
    - Define gamepad bindings: `pause` → JoypadButton(START), `toggle_mode` → JoypadButton(SELECT)
    - Define keyboard/mouse bindings: `pause` → Key(ESCAPE), `toggle_mode` → Key(TAB)
    - _Requirements: 5.1, 5.2, 5.4_

  - [x] 7.2 Create isometric context `.tres` resource file
    - Create `input/contexts/isometric.tres` as an `InputContextBindings` resource
    - Define placeholder actions for isometric mode (e.g., `select` BOOL, `camera_pan` VECTOR2)
    - Provide gamepad and keyboard/mouse bindings for each action
    - _Requirements: 5.1, 5.2_

  - [x] 7.3 Create third_person context `.tres` resource file
    - Create `input/contexts/third_person.tres` as an `InputContextBindings` resource
    - Define placeholder actions for 3rd-person mode (e.g., `move` VECTOR2, `look` VECTOR2, `interact` BOOL, `attack` BOOL)
    - Provide gamepad and keyboard/mouse bindings for each action
    - _Requirements: 5.1, 5.2_

  - [ ]* 7.4 Write property test for Default Binding Coverage
    - **Property 7: Default Binding Coverage**
    - Load all shipped `.tres` files, for every `ActionDefinition` in each context assert both `gamepad_bindings` and `keyboard_mouse_bindings` contain at least one `ActionBinding` matching the action name
    - **Validates: Requirements 5.1, 5.2**

- [x] 8. Register autoload and wire everything together
  - [x] 8.1 Register InputSystem as autoload in project.godot
    - Add `InputSystem` autoload entry pointing to `scripts/input/input_system.gd`
    - Verify the autoload is accessible as `InputSystem` singleton from any script
    - _Requirements: 4.1, 4.3, 4.4_

- [x] 9. Create PBT test helpers
  - [x] 9.1 Create input generator helpers for property-based tests
    - Create `tests/helpers/input_generators.gd`
    - Implement generator functions: `random_action_definition()`, `random_action_binding()`, `random_input_context_bindings()`, `random_input_event()`, `random_scheme()`
    - Each generator produces randomized but valid resource instances for use in property tests
    - _Requirements: (testing infrastructure)_

- [x] 10. Final checkpoint
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties from the design document
- Unit tests validate specific examples and edge cases
- All game code queries actions through Godot's native `Input` singleton — the system only manages InputMap state
