/* MIT License

Copyright (c) 2025 Tech Artists Agency

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

import TAAnalytics
import Heap

/// Sends messages to Heap Analytics about analytics events & user properties.
public class HeapIOAnalyticsConsumer: AnalyticsConsumer, AnalyticsConsumerWithReadWriteUserID {

    public typealias T = Heap.Type

    private let sdkKey: String
    private let enabledInstallTypes: [TAAnalyticsConfig.InstallType]
    private let isRedacted: Bool

    // MARK: AnalyticsConsumer

    /// - Parameters:
    ///   - isRedacted: If parameter & user property values should be redacted.
    ///   - enabledInstallTypes: Install types for which the consumer is enabled.
    public init(
        enabledInstallTypes: [TAAnalyticsConfig.InstallType] = TAAnalyticsConfig.InstallType.allCases,
        isRedacted: Bool = true,
        sdkKey: String
    ) {
        self.sdkKey = sdkKey
        self.enabledInstallTypes = enabledInstallTypes
        self.isRedacted = isRedacted
    }

    public func startFor(
        installType: TAAnalyticsConfig.InstallType,
        userDefaults: UserDefaults,
        TAAnalytics: TAAnalytics
    ) async throws {
        if !self.enabledInstallTypes.contains(installType) {
            throw InstallTypeError.invalidInstallType
        }
        
        Heap.initialize(sdkKey)
    }

    public func track(trimmedEvent: EventAnalyticsModelTrimmed, params: [String: any AnalyticsBaseParameterValue]?) {
        
        var eventProperties = [String: String]()
        if let params = params {
            for (key, value) in params {
                eventProperties[key] = value.description
            }
        }
        Heap.track(trimmedEvent.rawValue, withProperties: eventProperties)
    }

    public func set(trimmedUserProperty: UserPropertyAnalyticsModelTrimmed, to: String?) {
        let userPropertyKey = trimmedUserProperty.rawValue

        if let value = to {
            Heap.addUserProperties([userPropertyKey: value])
        }
    }

    public func trim(event: EventAnalyticsModel) -> EventAnalyticsModelTrimmed {
        let trimmedEventName = event.rawValue.ta_trim(toLength: 40, debugType: "event")
        return EventAnalyticsModelTrimmed(trimmedEventName)
    }

    public func trim(userProperty: UserPropertyAnalyticsModel) -> UserPropertyAnalyticsModelTrimmed {
        let trimmedUserPropertyKey = userProperty.rawValue.ta_trim(toLength: 24, debugType: "user property")
        return UserPropertyAnalyticsModelTrimmed(trimmedUserPropertyKey)
    }

    public var wrappedValue: Heap.Type {
        return Heap.self
    }

    // MARK: AnalyticsConsumerWithReadWriteUserID

    public func set(userID: String?) {
        if let userID = userID {
            Heap.identify(userID)
        }
    }

    public func getUserID() -> String? {
        return nil
    }
}
