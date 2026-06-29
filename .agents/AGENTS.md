# Coding Standards

Think before coding. State your assumptions out loud. If the request is ambiguous, ask. If a simpler approach exists, push back. Stop when you are confused, name what is unclear, do not just pick one interpretation and run.

Simplicity first. Write the minimum code that solves the problem. No speculative abstractions. No flexibility nobody asked for. The test: would a senior engineer call this overcomplicated.

Surgical changes. Touch only what the task requires. Do not improve neighboring code. Do not refactor what is not broken. Every changed line should trace back to the request.

Goal-driven execution. Turn vague instructions into verifiable targets before writing a line. “Add validation” becomes “write tests for invalid inputs, then make them pass.”

# Definition of Done (DoD)

1. **DartDoc Documentation:** Every function, class, property, and parameter must be fully documented using `///` DartDoc comments. The documentation must be clear, detailed, and support IDE rollover tooltips so that a human developer can immediately understand the purpose, inputs, and outputs of the code.
2. **Comprehensive Test Coverage:** Every feature must have a corresponding test script (unit, widget, or component tests). A feature is not considered implemented until all associated tests are written, executed, and passed successfully.

