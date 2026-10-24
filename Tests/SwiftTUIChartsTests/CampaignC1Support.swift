import Foundation
import Testing

/// Preserve a reproducible unmarked path, guarding only a confirmed assertion.
func c1Known(_ comment: Comment, _ body: () -> Void) {
  if ProcessInfo.processInfo.environment["SWIFTTUI_C1_UNMARKED"] == "1" {
    body()
  } else {
    withKnownIssue(comment) { body() }
  }
}
