import HTTP
import Vapor
import Foundation

class ThingController {
    let service = ThingService()

    func get(request: Request, thing: String) throws -> ResponseRepresentable {
        let results = try service.get(thing)
        let nodes = try results.map { try $0.makeNode() }
        let array = Node.array(nodes)
        return try JSON(node: array)
    }

    func slack(request: Request) throws -> ResponseRepresentable {
        guard let text = request.query?["text"]?.string else {
            throw Abort.custom(status: .preconditionFailed, message: "Missing text")
        }

        var response: [String: Any] = [
            "response_type": "ephemeral",
            "text": "There is no \(text) to look at."
        ]

        if let result = try service.get(text).first {
            response = [
                "response_type": "in_channel",
                "attachments": [[
                    "text": result.caption,
                    "image_url": result.url
                ]]
            ]
        }

        let data = try JSONSerialization.data(withJSONObject: response, options: [])
        let bytes = String(data: data, encoding: .utf8)?.toBytes()

        if let bytes = bytes {
            return try JSON.init(bytes: bytes)
        } else {
            throw Abort.serverError
        }
    }
}
