# CLAUDE.md for pressbox

## Build Commands
- Build: Open in Xcode, press ⌘B
- Run: Press ⌘R
- Clean: Press ⇧⌘K

## Test Commands
- Run all tests: ⌘U
- Run single test: Click diamond icon next to test or use Test Navigator (⌘6)
- Re-run last test: ⌃⌥⌘G

## Code Style Guidelines

### Formatting
- Indent with 4 spaces
- Keep line length under 120 characters
- Use empty line between methods

### Naming
- Types (classes, structs, enums): UpperCamelCase
- Variables, functions, properties: lowerCamelCase
- Be descriptive, avoid abbreviations

### Imports
- Swift standard libraries first (SwiftUI, Foundation)
- Third-party libraries next
- Local modules last
- Alphabetize within each group

### Types & Architecture
- Use Swift's strong type system
- Prefer value types (structs) over reference types (classes)
- Follow MVVM architecture pattern
- Use SwiftUI property wrappers appropriately (@State, @Environment)

### Error Handling
- Use do-try-catch for recoverable errors
- Use structured error types (enums with ErrorType)
- Only use fatalError() during development