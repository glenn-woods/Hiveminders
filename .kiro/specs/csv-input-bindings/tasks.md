# Implementation Plan: CSV Input Bindings

## Overview

Implement a CSV-based input binding system for Hiveminders. Build three new GDScript classes (EventTokenParser, CsvBindingsParser, CsvBindingsPrinter), integrate CSV loading into the existing InputSystem, create the CSV data file, and validate everything with property-based and unit tests.

## Tasks

- [x] 1. Implement EventTokenParser
  - [x] 1.1 Create `hiveminders/scripts/input/event_token_parser.gd` with `token_to_event()` and `event_to_token()` static methods
    - Implement `key:<KeyName>` token parsing using `OS.find_keycode_from_string()` and single uppercase letter mapping (A=65..Z=90)
    - Implement `mouse_button:<Index>` token parsing to `InputEventMouseButton`
    - Implement `joy_button:<Index>` token parsing to `InputEventJoypadButton`
    - Implement `joy_axis:<Axis>:<Value>` token parsing to `InputEventJoypadMotion`
    - Implement `event_to_token()` reverse conversion using `OS.get_keycode_string()`
    - Return `[InputEvent, ""]` on success, `[null, "error message"]` on failure for `token_to_event()`
    - Return `""` for unsupported event types in `event_to_token()`
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

  - [ ]* 1.2 Write property test for event token round-trip
    - **Property 1: Event token round-trip**
    - Use `InputGenerators.random_input_event()` to generate random events, convert to token and back, assert equivalence
    - Run 100+ iterations
    - **Validates: Requirements 2.1, 2.2, 2.3, 2.4**

- [x] 2. Implement CsvBindingsParser
  - [x] 2.1 Create `hiveminders/scripts/input/csv_bindings_parser.gd` with `ParseResult` inner class and `parse()` static method
    - Implement line splitting, empty line discarding, and trailing whitespace stripping
    - Validate header row matches `context,action,action_type,gamepad,keyboard_mouse`
    - Validate `action_type` is one of `BOOL`, `AXIS`, `VECTOR2`
    - Detect duplicate `(context, action)` pairs
    - Parse `gamepad` and `keyboard_mouse` cells: split on `|`, trim whitespace, call `EventTokenParser.token_to_event()`
    - Group rows by context, build `InputContextBindings` with `actions`, `gamepad_bindings`, `keyboard_mouse_bindings`
    - Accumulate all errors in `ParseResult.errors` without aborting early
    - Allow empty binding cells to produce no binding for that scheme
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.5, 3.1, 3.2, 3.3, 3.4, 3.5, 4.1, 4.2, 4.3, 4.4, 4.5_

  - [ ]* 2.2 Write property test for whitespace insignificance
    - **Property 2: Whitespace insignificance in token cells**
    - Generate valid CSV rows, add random whitespace around tokens and pipes, assert same parse result
    - Run 100+ iterations
    - **Validates: Requirements 2.5**

  - [ ]* 2.3 Write property test for parser context count
    - **Property 3: Parser produces one context per unique context name**
    - Generate random `InputContextBindings` arrays, print to CSV, parse, assert context count matches unique context names
    - Run 100+ iterations
    - **Validates: Requirements 3.1**

- [x] 3. Implement CsvBindingsPrinter
  - [x] 3.1 Create `hiveminders/scripts/input/csv_bindings_printer.gd` with `print_csv()` static method
    - Sort contexts alphabetically by `context_name`
    - Emit header line `context,action,action_type,gamepad,keyboard_mouse`
    - For each context and action, look up matching `ActionBinding` in gamepad and keyboard_mouse bindings
    - Convert events to tokens via `EventTokenParser.event_to_token()`, join with ` | `
    - Emit CSV row per action
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

  - [ ]* 3.2 Write property test for printer alphabetical order
    - **Property 4: Printer output is alphabetically ordered by context**
    - Generate random `InputContextBindings` arrays, print, verify context order is alphabetical
    - Run 100+ iterations
    - **Validates: Requirements 6.4**

  - [ ]* 3.3 Write property test for printer header and row count
    - **Property 5: Printer output has correct header and row count**
    - Generate random `InputContextBindings` arrays, print, verify line count = total actions + 1 and first line is the expected header
    - Run 100+ iterations
    - **Validates: Requirements 1.2, 6.1**

- [x] 4. Checkpoint - Verify core classes
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Round-trip property tests
  - [ ]* 5.1 Write property test for print-then-parse round-trip
    - **Property 6: Print-then-parse round-trip**
    - Generate random `InputContextBindings` arrays (unique action names per context, supported event types), print with `CsvBindingsPrinter`, parse with `CsvBindingsParser`, assert semantic equivalence
    - Run 100+ iterations
    - **Validates: Requirements 7.2**

  - [ ]* 5.2 Write property test for parse-then-print-then-parse round-trip
    - **Property 7: Parse-then-print-then-parse round-trip**
    - Generate valid CSV strings (via print from random bindings), parse, print, parse again, assert equivalence to first parse
    - Run 100+ iterations
    - **Validates: Requirements 7.1**

- [x] 6. Unit tests for error handling and edge cases
  - [x] 6.1 Create `hiveminders/tests/test_csv_bindings.gd` with unit tests for parser error conditions
    - Test missing/wrong header returns error mentioning expected header (Req 4.1)
    - Test invalid `action_type` returns error with row number and invalid value (Req 4.2)
    - Test invalid event token returns error with row number, column, and token (Req 4.3)
    - Test duplicate action in same context returns error with context and action name (Req 4.4)
    - Test empty CSV input returns error with file path info (Req 4.5)
    - Test empty binding cell produces no binding for that scheme but other scheme still works (Req 1.5)
    - _Requirements: 1.5, 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 7. Integrate CSV loading into InputSystem
  - [x] 7.1 Add `csv_bindings_path` exported property to `hiveminders/scripts/input/input_system.gd`
    - Add `@export var csv_bindings_path: String = ""` property
    - In `_ready()`, before `_load_bindings_from_directory()`: if `csv_bindings_path` is non-empty, read the file, call `CsvBindingsParser.parse()`, register results in `_bindings_registry`, log errors via `push_error()`, and skip directory scan
    - If `csv_bindings_path` is empty, fall back to existing `.tres` directory loading
    - If parser returns errors, still register any successfully parsed contexts
    - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [x] 8. Create the CSV data file
  - [x] 8.1 Create `hiveminders/input/input_bindings.csv` with bindings for base, isometric, and third_person contexts
    - Use the header `context,action,action_type,gamepad,keyboard_mouse`
    - Populate with the equivalent bindings from the existing `.tres` resource files
    - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [x] 9. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Property tests use the existing `InputGenerators` helper class in `hiveminders/tests/helpers/input_generators.gd`
- All new scripts go in `hiveminders/scripts/input/`
- Test file goes in `hiveminders/tests/test_csv_bindings.gd`
- The CSV data file goes at `hiveminders/input/input_bindings.csv`
