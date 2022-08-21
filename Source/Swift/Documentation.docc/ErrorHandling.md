# Error Handling

Handling Lisp errors on Swift side and vice versa.

## Emacs Errors

Emacs Lisp is a dynamically typed language, the majority of input validation and type conformance checks end up being errors. It is a normal state of things. Runtime errors in Lisp doesn't have a stigma to them like in some other languages, especially because the user can literally call functions all the time.

In `EmacsSwiftModule`, we surface Lisp runtime errors as Swift exceptions. And in the vast majority of the cases users should just re-throw errors back to the user. Again, this is normal, especially if it happens in a user-facing function. Any interaction with ``Environment`` can potentially throw. You only handle these errors yourself if you actually expect a very specific error as a possibility and have a backup plan.

## Swift Errors

At the same time, Swift code exceptions are also fine and will be translated into Emacs error signals. You probably want to handle a bigger portion of this kind of errors, but if you won't, nothing bad will happen. If it won't crash Emacs, it's not critical.

> Important: If you choose to disable error propagation via `try!`, and do get an exception, it will crash Emacs. Swift runtime errors are critical.

## User Interruptions

If your code introduces a long-running Lisp function, you should check from time to time if the user interrupted it by pressing `C-g` (or similar). In this situation, it is recommended to quit any work as soon as possible. You can check it via ``Environment/interrupted()`` method. If you work with environment, any call to it will throw ``EmacsError/interrupted``, when in this state.

## Lifetime Violations

``Environment`` checks for lifetime and thread model consistency and throws ``EmacsError/lifetimeViolation`` or ``EmacsError/threadModelViolation``. Check <doc:Lifetimes> for more details.
