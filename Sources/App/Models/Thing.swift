import Vapor

struct Thing {
    let url: String
    let caption: String
}

extension Thing: NodeRepresentable {
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "url": url,
            "caption": caption
            ])
    }
}
