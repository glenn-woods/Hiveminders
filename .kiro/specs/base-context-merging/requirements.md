# Requirements Document

## Introduction

The InputSystem manages input contexts via a stack, but currently only the topmost context's actions and bindings are registered in Godot's InputMap. This means global actions defined in the base context (such as "pause" and "toggle_mode") become unavailable when a gameplay context like "isometric" or "third_person" is pushed on top.

This feature modifies the InputSystem's `_sync_input_map()` method to merge the base context's actions and bindings with the top context's actions and bindings. The base context's actions are always available regardless of which context sits on top of the stack. When the top context defines an action with the same name as a base action, the top context's binding takes precedence.

## Glossary

- **InputSystem**: The singleton node (`input_system.gd`) that manages the context stack, scheme detection, and InputMap synchronization.
- **InputMap**: Godot's built-in action-to-event mapping used by the engine's input polling functions (`Input.is_action_pressed`, etc.).
- **Base_Context**: The first context pushed onto the context stack during startup. The Base_Context is never popped and sits at the bottom of the stack.
- **Top_Context**: The context at the top of the context stack whose bindings are currently active.
- **Context_Stack**: An ordered list of InputContextBindings maintained by the InputSystem; only the Base_Context and Top_Context participate in InputMap registration.
- **Action**: A named input action (e.g. "pause", "select") registered in InputMap.
- **Binding**: An ActionBinding resource that maps an action name to one or more InputEvent objects for a specific input scheme.
- **Merged_Action_Set**: The union of actions from the Base_Context and the Top_Context, where duplicate action names are resolved in favor of the Top_Context.
- **InputContextBindings**: A Resource type that groups a context name, its ActionDefinitions, and per-scheme ActionBinding arrays.
- **ActionDefinition**: A Resource type that pairs an action name with an ActionType (BOOL, AXIS, VECTOR2).
- **ActionBinding**: A Resource type that pairs an action name with an array of InputEvent objects for one scheme.

## Requirements

### Requirement 1: Base Context Actions Always Available

**User Story:** As a player, I want global actions like pause to work at all times, so that I can always pause the game regardless of which gameplay mode is active.

#### Acceptance Criteria

1. WHEN the InputSystem synchronizes InputMap and the Context_Stack contains more than one context, THE InputSystem SHALL register all actions from the Base_Context in InputMap in addition to the actions from the Top_Context.
2. WHEN the InputSystem synchronizes InputMap and the Context_Stack contains exactly one context (the Base_Context), THE InputSystem SHALL register only the Base_Context's actions in InputMap.
3. WHEN the InputSystem synchronizes InputMap, THE InputSystem SHALL register the bindings from the Base_Context for each Base_Context action that is not overridden by the Top_Context.

### Requirement 2: Top Context Override

**User Story:** As a game designer, I want a gameplay context to override a base action's binding when needed, so that I can repurpose a key for context-specific behavior.

#### Acceptance Criteria

1. WHEN the Top_Context defines an action with the same name as a Base_Context action, THE InputSystem SHALL register the Top_Context's binding for that action instead of the Base_Context's binding.
2. WHEN the Top_Context defines an action with the same name as a Base_Context action, THE InputSystem SHALL use the Top_Context's ActionDefinition (including action_type) for that action.
3. WHEN the Top_Context does not define an action that exists in the Base_Context, THE InputSystem SHALL register the Base_Context's ActionDefinition and binding for that action unchanged.

### Requirement 3: Scheme-Aware Merging

**User Story:** As a developer, I want the merging logic to respect the active input scheme, so that gamepad and keyboard bindings are correctly selected during the merge.

#### Acceptance Criteria

1. WHILE the active scheme is GAMEPAD, THE InputSystem SHALL select gamepad_bindings from both the Base_Context and the Top_Context when building the Merged_Action_Set.
2. WHILE the active scheme is KEYBOARD_MOUSE, THE InputSystem SHALL select keyboard_mouse_bindings from both the Base_Context and the Top_Context when building the Merged_Action_Set.
3. WHEN the active scheme changes, THE InputSystem SHALL re-synchronize InputMap using the merged actions and the newly active scheme's bindings.

### Requirement 4: Base Context Identity

**User Story:** As a developer, I want the base context to be clearly identified from the stack, so that the merging logic uses a reliable reference.

#### Acceptance Criteria

1. THE InputSystem SHALL identify the Base_Context as the first entry in the Context_Stack (index 0).
2. WHEN a pop_context call would remove the last context from the stack, THE InputSystem SHALL reject the pop and keep the Base_Context on the stack.
3. WHEN the Context_Stack contains exactly one context, THE InputSystem SHALL treat that context as both the Base_Context and the Top_Context and register only its actions (no duplication).

### Requirement 5: No CSV Duplication Required

**User Story:** As a game designer, I want base actions to be available everywhere without copying rows into every context in the CSV file, so that I maintain bindings in one place.

#### Acceptance Criteria

1. THE InputSystem SHALL make Base_Context actions available in all contexts without requiring the CSV_File to duplicate Base_Context action rows in other context sections.
2. WHEN a new context is added to the CSV_File, THE InputSystem SHALL automatically merge Base_Context actions into that context without additional configuration.

### Requirement 6: Merged Action Set Correctness

**User Story:** As a developer, I want the merged action set to be predictable and correct, so that no actions are lost or duplicated in InputMap.

#### Acceptance Criteria

1. FOR ALL context stack states where the stack has more than one context, the Merged_Action_Set SHALL contain exactly the union of Base_Context action names and Top_Context action names (no duplicates).
2. FOR ALL actions in the Merged_Action_Set, THE InputSystem SHALL register exactly one InputMap action entry per action name.
3. WHEN the InputSystem synchronizes InputMap, THE InputSystem SHALL first erase all previously registered actions before registering the Merged_Action_Set.
