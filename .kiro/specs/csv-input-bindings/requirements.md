# Requirements Document

## Introduction

Hiveminders currently defines input bindings as hand-authored `.tres` resource files (one per context: base, isometric, third_person). Each file embeds ActionDefinition and ActionBinding sub-resources with raw Godot key/button codes, making them difficult to read, compare, and bulk-edit.

This feature introduces a CSV-based authoring workflow for input bindings. A single `.csv` file acts as the source of truth for all input contexts, action definitions, and per-scheme bindings. A CSV Parser reads the file at runtime and produces the same `InputContextBindings` resources the existing `InputSystem` already consumes, requiring no changes to the runtime input pipeline.

## Glossary

- **CSV_File**: A comma-separated-values file located in the project that contains all input binding data across every context and scheme.
- **CSV_Parser**: A GDScript class responsible for reading the CSV_File, validating its contents, and producing InputContextBindings resources.
- **InputSystem**: The existing singleton node (`input_system.gd`) that manages the context stack, scheme detection, and InputMap synchronization.
- **InputContextBindings**: An existing Resource type that groups a context name, its ActionDefinitions, and per-scheme ActionBinding arrays.
- **ActionDefinition**: An existing Resource type that pairs an action name with an ActionType (BOOL, AXIS, VECTOR2).
- **ActionBinding**: An existing Resource type that pairs an action name with an array of InputEvent objects for one scheme.
- **Context**: A named group of actions and bindings (e.g. "base", "isometric", "third_person") that can be pushed/popped on the InputSystem stack.
- **Scheme**: One of two device families — GAMEPAD or KEYBOARD_MOUSE — each with its own column(s) in the CSV_File.
- **Action_Type**: The value type of an action: BOOL (0), AXIS (1), or VECTOR2 (2).
- **Event_Token**: A human-readable string in a CSV cell that identifies a single input event (e.g. "key:W", "joy_button:0", "mouse_button:1", "joy_axis:0:-1.0").

## Requirements

### Requirement 1: CSV File Format

**User Story:** As a game designer, I want a clearly defined CSV format for input bindings, so that I can view and edit all bindings in a spreadsheet-style editor.

#### Acceptance Criteria

1. THE CSV_File SHALL contain one row per action-context combination with the following columns: `context`, `action`, `action_type`, `gamepad`, `keyboard_mouse`.
2. THE CSV_File SHALL use a header row as the first row with the exact column names: `context,action,action_type,gamepad,keyboard_mouse`.
3. THE CSV_File SHALL support the Action_Type values `BOOL`, `AXIS`, and `VECTOR2` in the `action_type` column.
4. THE CSV_File SHALL allow multiple Event_Tokens in a single `gamepad` or `keyboard_mouse` cell, separated by a pipe character (`|`).
5. THE CSV_File SHALL allow empty `gamepad` or `keyboard_mouse` cells to indicate no binding for that scheme.

### Requirement 2: Event Token Syntax

**User Story:** As a game designer, I want a readable shorthand for input events, so that I do not need to memorize Godot key codes.

#### Acceptance Criteria

1. THE CSV_Parser SHALL recognize the Event_Token format `key:<KeyName>` and map the token to an InputEventKey with the corresponding Godot keycode (e.g. `key:W` maps to keycode 87).
2. THE CSV_Parser SHALL recognize the Event_Token format `mouse_button:<Index>` and map the token to an InputEventMouseButton with the corresponding button_index (e.g. `mouse_button:1` maps to left click).
3. THE CSV_Parser SHALL recognize the Event_Token format `joy_button:<Index>` and map the token to an InputEventJoypadButton with the corresponding button_index.
4. THE CSV_Parser SHALL recognize the Event_Token format `joy_axis:<Axis>:<Value>` and map the token to an InputEventJoypadMotion with the corresponding axis index and axis_value (e.g. `joy_axis:0:-1.0` maps to left-stick left).
5. THE CSV_Parser SHALL treat whitespace surrounding Event_Tokens and pipe separators as insignificant and trim the whitespace before parsing.

### Requirement 3: CSV Parsing

**User Story:** As a developer, I want a parser that converts the CSV file into InputContextBindings resources, so that the existing InputSystem can consume them without modification.

#### Acceptance Criteria

1. WHEN the CSV_Parser reads a valid CSV_File, THE CSV_Parser SHALL produce one InputContextBindings resource per unique context value found in the file.
2. WHEN the CSV_Parser produces an InputContextBindings resource, THE CSV_Parser SHALL populate the `actions` array with one ActionDefinition per action row belonging to that context.
3. WHEN the CSV_Parser produces an InputContextBindings resource, THE CSV_Parser SHALL populate the `gamepad_bindings` array with one ActionBinding per action row that has a non-empty `gamepad` cell.
4. WHEN the CSV_Parser produces an InputContextBindings resource, THE CSV_Parser SHALL populate the `keyboard_mouse_bindings` array with one ActionBinding per action row that has a non-empty `keyboard_mouse` cell.
5. WHEN the CSV_Parser parses Event_Tokens for an action, THE CSV_Parser SHALL assign the resulting InputEvent objects to the `events` array of the corresponding ActionBinding.

### Requirement 4: CSV Validation and Error Reporting

**User Story:** As a developer, I want clear error messages when the CSV file contains mistakes, so that I can fix them quickly.

#### Acceptance Criteria

1. IF the CSV_File is missing the required header row, THEN THE CSV_Parser SHALL return an error message that identifies the expected header columns.
2. IF a row contains an unrecognized `action_type` value, THEN THE CSV_Parser SHALL return an error message that identifies the row number and the invalid value.
3. IF a cell contains an Event_Token with an unrecognized format, THEN THE CSV_Parser SHALL return an error message that identifies the row number, column name, and the invalid token.
4. IF the CSV_File contains duplicate action names within the same context, THEN THE CSV_Parser SHALL return an error message that identifies the context name and the duplicate action name.
5. IF the CSV_File cannot be opened or is empty, THEN THE CSV_Parser SHALL return an error message that includes the file path.

### Requirement 5: InputSystem Integration

**User Story:** As a developer, I want the InputSystem to load bindings from the CSV file, so that the CSV_File becomes the single source of truth for input configuration.

#### Acceptance Criteria

1. WHEN the InputSystem starts, THE InputSystem SHALL invoke the CSV_Parser to load InputContextBindings from the CSV_File before pushing the initial context.
2. WHEN the CSV_Parser returns valid InputContextBindings resources, THE InputSystem SHALL register each resource in its bindings registry keyed by context_name.
3. IF the CSV_Parser returns errors during startup, THEN THE InputSystem SHALL log each error as a Godot push_error message and continue loading any valid contexts.
4. THE InputSystem SHALL accept a configurable file path for the CSV_File via an exported property.

### Requirement 6: CSV Pretty-Printer

**User Story:** As a developer, I want to generate a CSV file from existing InputContextBindings resources, so that I can migrate current .tres bindings to the CSV format.

#### Acceptance Criteria

1. WHEN given an array of InputContextBindings resources, THE CSV_Printer SHALL produce a valid CSV string with the correct header row and one data row per action-context combination.
2. WHEN the CSV_Printer formats an ActionBinding, THE CSV_Printer SHALL convert each InputEvent in the binding's events array back into the corresponding Event_Token string.
3. WHEN an ActionBinding contains multiple events, THE CSV_Printer SHALL join the Event_Token strings with a pipe character (`|`) in the appropriate cell.
4. THE CSV_Printer SHALL write rows grouped by context name, with contexts appearing in alphabetical order.

### Requirement 7: Round-Trip Integrity

**User Story:** As a developer, I want confidence that parsing and printing are consistent, so that no binding data is lost during conversion.

#### Acceptance Criteria

1. FOR ALL valid CSV_File contents, parsing the CSV_File with the CSV_Parser then printing the resulting InputContextBindings with the CSV_Printer then parsing again SHALL produce InputContextBindings resources equivalent to the first parse result (round-trip property).
2. FOR ALL valid InputContextBindings resources, printing with the CSV_Printer then parsing with the CSV_Parser SHALL produce InputContextBindings resources equivalent to the originals.
