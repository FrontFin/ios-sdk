import Foundation

/// A message from Link that the SDK acts on.
///
/// Link also posts `transferFinished`, `withdrawalRequested` and
/// `brokerageAccountAccessToken`; those are parsed-and-dropped, because their
/// payloads carry user data and broker credentials that the SDK must never
/// surface, log or store.
enum BridgeMessage: Equatable {
    case close(status: LinkExitStatus)
    case loaded

    /// Parse a message posted by Link. On iOS the body arrives as a dictionary;
    /// a string (JSON) is accepted too. Anything that is not a known message —
    /// invalid JSON, a non-object, a missing `type`, or a dropped message type —
    /// yields `nil` and never throws.
    static func parse(_ body: Any?) -> BridgeMessage? {
        let object: [String: Any]?
        if let string = body as? String {
            guard
                let data = string.data(using: .utf8),
                let json = try? JSONSerialization.jsonObject(with: data),
                let dictionary = json as? [String: Any]
            else {
                return nil
            }
            object = dictionary
        } else if let dictionary = body as? [String: Any] {
            object = dictionary
        } else {
            object = nil
        }

        guard let message = object, let type = message["type"] as? String else {
            return nil
        }

        switch type {
        case "close":
            // Older Link builds post `close` with no payload. Only an explicit
            // `success` counts, so `success` is never reported unless Link says so.
            let status = (message["payload"] as? [String: Any])?["status"] as? String
            return .close(status: status == "success" ? .success : .canceled)
        case "loaded":
            return .loaded
        default:
            return nil
        }
    }
}
