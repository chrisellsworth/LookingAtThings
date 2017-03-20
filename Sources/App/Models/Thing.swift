import Vapor

struct Thing {
    let caption: String
    let imageUrl: String
    let link: String
    let looker: Looker
}

extension Thing: NodeRepresentable {
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "caption": caption,
            "image_url": imageUrl,
            "link": link,
            "looker": looker.description
            ])
    }
}
