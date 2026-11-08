import AppIntents

// ToolIntent only exists in the iOS 27.3 SDK (Xcode beta). Swift 6.4 ships in
// both Xcodes, so a compiler check cannot tell them apart: define
// SIRI_TOOL_INTENT in a build made with that SDK.
#if SIRI_TOOL_INTENT
@available(iOS 27.3, *)
extension AddMonthlyEntryIntent: ToolIntent {}

@available(iOS 27.3, *)
extension FindBillsIntent: ToolIntent {}
#endif
