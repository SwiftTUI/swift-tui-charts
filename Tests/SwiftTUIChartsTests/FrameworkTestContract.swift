#if SWIFTTUI_TEST_CONTRACT_V1
  @_spi(Testing) import SwiftTUITestSupport
  typealias ContractTestRenderer = ViewTestRenderer
  typealias ContractTestContext = ViewTestContext
#else
  // The tagged 0.20.1 floor predates the narrow snapshot facade. Candidate
  // qualification selects it through a coordination-owned manifest setting.
  import SwiftTUIRuntime
  typealias ContractTestRenderer = DefaultRenderer
  typealias ContractTestContext = ResolveContext
#endif
