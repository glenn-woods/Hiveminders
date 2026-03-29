# Requirements Document

## Introduction

This document defines the minimal foundation for the Input System in a Godot 4.x colony simulation featuring isometric and 3rd-person gameplay modes. The scope is deliberately narrow: abstract actions, scheme detection, a context stack, Godot InputMap integration, and one set of default bindings. The architecture is modular so that future features can be layered on without refactoring the core.

### Deferred Features (Planned, Not In Scope)

- Key/button rebinding and persistence
- UI prompt adaptation (device-specific icons and labels)
- Multiplayer input isolation and per-player instances
- Device-to-player assignment
- Player join/leave lifecycle
- Device hot-plug handling
- Network multiplayer input boundary
- Specific isometric mode action definitions (camera pan, zoom, select, area paint, etc.)
- Specific 3rd-person mode action definitions (move, look, attack, interact, etc.)
- Mode switching logic (possess/unpossess) — the context stack provides the mechanism; game logic will drive it

## Glossary

- **Input_System**: The top-level system that receives raw device events, resolves them into abstract Actions via the active Input_Context and Active_Scheme Bindings, and dispatches those Actions to game systems.
- **Action**: A named, device-agnostic game event (e.g., "move", "interact") consumed by gameplay systems. Each Action has a value type: boolean, axis, or vector2.
- **Input_Context**: A named set of Action-to-Binding mappings representing a gameplay mode. Contexts are managed in a stack; only the topmost context processes input.
- **Input_Scheme**: One of two mutually exclusive device families: Gamepad or Keyboard_Mouse.
- **Active_Scheme**: The Input_Scheme currently driving input, determined by the most recent qualifying device event.
- **Binding**: A mapping from a physical input (key, button, axis) to an Action within a specific Input_Context and Input_Scheme.
- **Default_Bindings**: The shipped set of Bindings for each Input_Scheme, providing enough mappings to move around and interact.

## Requirements

### Requirement 1: Abstract Action Layer

**User Story:** As a game developer, I want all gameplay systems to consume named Actions rather than raw input events, so that input device details are fully decoupled from game logic.

#### Acceptance Criteria

1. THE Input_System SHALL expose every player-facing input as a named Action defined in a central action registry.
2. WHEN a physical input event occurs, THE Input_System SHALL resolve the event to the corresponding Action using the current Input_Context and Active_Scheme Bindings.
3. THE Input_System SHALL support three Action value types: boolean (pressed/released), axis (–1.0 to 1.0), and vector2 (two-axis composite).
4. WHEN no Binding exists for a physical input event in the current Input_Context, THE Input_System SHALL discard the event without propagating an Action.

### Requirement 2: Input Scheme Detection

**User Story:** As a player, I want the game to automatically detect whether I am using a gamepad or keyboard/mouse, so that the active scheme always matches my current device.

#### Acceptance Criteria

1. THE Input_System SHALL classify every connected input device as belonging to exactly one Input_Scheme: Gamepad or Keyboard_Mouse.
2. WHEN a qualifying input event is received from a device belonging to a different Input_Scheme than the Active_Scheme, THE Input_System SHALL switch the Active_Scheme to match the new device.
3. THE Input_System SHALL treat mouse movement alone as insufficient to trigger an Active_Scheme switch to Keyboard_Mouse; a mouse button press or keyboard key press SHALL be required.
4. WHEN the Active_Scheme changes, THE Input_System SHALL emit an "active_scheme_changed" signal containing the new Active_Scheme value.

### Requirement 3: Input Context Stack

**User Story:** As a game developer, I want a context stack so that different gameplay modes can define different Bindings, and modal overlays can temporarily override input without losing the previous context.

#### Acceptance Criteria

1. THE Input_System SHALL maintain a stack of Input_Contexts, where the topmost context receives input.
2. WHEN a new Input_Context is pushed onto the stack, THE Input_System SHALL activate that context and update Godot InputMap Bindings to reflect the new topmost context.
3. WHEN the topmost Input_Context is popped from the stack, THE Input_System SHALL restore the Bindings of the new topmost context.
4. WHILE an Input_Context is not the topmost context on the stack, THE Input_System SHALL prevent that context from processing input events.
5. THE Input_System SHALL complete a context switch within a single frame to prevent input events from being processed by the wrong context.
6. THE Input_System SHALL expose push and pop operations as the public API for context management, allowing game systems to drive mode transitions externally.

### Requirement 4: Godot InputMap Integration

**User Story:** As a game developer, I want the Input System to build on Godot 4.x's built-in InputMap and action system, so that the implementation leverages engine features rather than replacing them.

#### Acceptance Criteria

1. THE Input_System SHALL register all Actions as Godot InputMap actions at startup using Godot's `InputMap.add_action` and `InputMap.action_add_event` APIs.
2. WHEN the active Input_Context or Active_Scheme changes, THE Input_System SHALL update the Godot InputMap entries to reflect the current Bindings.
3. THE Input_System SHALL use Godot's `Input.is_action_pressed`, `Input.is_action_just_pressed`, and `Input.get_vector` functions as the primary query interface for boolean and vector2 Actions.
4. THE Input_System SHALL use Godot's `Input.get_axis` function as the primary query interface for axis Actions.

### Requirement 5: Default Bindings

**User Story:** As a player, I want the game to ship with working default controls for both gamepad and keyboard/mouse, so that I can move around and interact immediately without configuration.

#### Acceptance Criteria

1. THE Input_System SHALL ship with one complete set of Default_Bindings for the Gamepad Input_Scheme covering all Actions defined in the initial Input_Contexts.
2. THE Input_System SHALL ship with one complete set of Default_Bindings for the Keyboard_Mouse Input_Scheme covering all Actions defined in the initial Input_Contexts.
3. WHEN the Input_System initializes and no user overrides exist, THE Input_System SHALL load the Default_Bindings for both Input_Schemes.
4. THE Input_System SHALL store Default_Bindings in a data-driven format (resource file or dictionary) so that adding or modifying bindings does not require code changes.
