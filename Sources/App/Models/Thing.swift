import Vapor

struct Thing {
    let url: String
    let caption: String
    let looker: Looker
}

extension Thing: NodeRepresentable {
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "url": url,
            "caption": caption,
            "looker": looker.description
            ])
    }
}
