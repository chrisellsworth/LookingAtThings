import Foundation
import Vapor

class ThingService {
    let drop: Droplet

    init(drop: Droplet) {
        self.drop = drop
    }

    enum ThingServiceError: Error {
        case invalidURL(String)
        case invalidQuery(String)
        case invalidComponents([String])
    }

    func baseURL(looker: Looker) -> String {
        switch looker {
        case .il:
            return "http://kimjongillookingatthings.tumblr.com"
        case .un:
            return "http://kimjongunlookingatthings.tumblr.com"
        }
    }

    func get(_ thing: String) throws -> [Thing] {
        let results = try get(thing, looker: .il)
        if results.isEmpty {
            return try get(thing, looker: .un)
        } else {
            return results
        }
    }

    func get(_ thing: String, looker: Looker) throws -> [Thing] {
        let url: URL
        if thing == "anything" {
            url = try self.randomURL(looker: looker)
        } else {
            url = try self.url(thing: thing, looker: looker)
        }
        return try fetch(url: url, looker: looker)
    }

    func url(thing: String, looker: Looker) throws -> URL {
        guard let encoded = thing.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw ThingServiceError.invalidQuery(thing)
        }

        let baseURL = self.baseURL(looker: looker)
        let string = "\(baseURL)/search/\(encoded)/rss"
        if let url = URL(string: string) {
            return url
        } else {
            throw ThingServiceError.invalidURL(string)
        }
    }

    func randomURL(looker: Looker) throws -> URL {
        let baseURL = self.baseURL(looker: looker)
        let string = "\(baseURL)/random"
        if let url = URL(string: string) {
            return try rss(url: url)
        } else {
            throw ThingServiceError.invalidURL(string)
        }
    }

    func rss(url: URL) throws -> URL {
        let resolved = try NetworkService(drop: drop).resolve(url: url)
        return try stripAnchor(url: resolved).appendingPathComponent("rss")
    }

    func stripAnchor(url: URL) throws -> URL {
        let components = url.absoluteString.components(separatedBy: "#")
        if let first = components.first, let base = URL(string: first) {
            return base
        } else {
            throw ThingServiceError.invalidComponents(components)
        }
    }

    func fetch(url: URL, looker: Looker) throws -> [Thing] {
#if os(Linux)
        let document = try XMLDocument(contentsOf: url, options: [])
#else
        let document = try XMLDocument(contentsOf: url, options: 0)
#endif
        return try parse(document: document, looker: looker)
    }

    func parse(document: XMLDocument, looker: Looker) throws -> [Thing] {
        let nodes = try document.nodes(forXPath: "//channel/item")
        let values = try nodes
            .map { try parse(node: $0, looker: looker) }
            .flatMap { $0 }
        return values
    }

    func parse(node: XMLNode, looker: Looker) throws -> Thing? {
        guard let description = try extract(path: "description", from: node) as? String else {
            return nil
        }

        guard let link = try extract(path: "link", from: node) as? String else {
            return nil
        }

        let (imageUrl, caption) = try parseDescription(description: description)

        if let imageUrl = imageUrl, let caption = caption {
            return Thing(caption: caption,
                         imageUrl: imageUrl,
                         link: link,
                         looker: looker)
        } else {
            return nil
        }
    }

    func parseDescription(description: String) throws -> (url: String?, caption: String?) {
        let pattern = "^<img src=\"(.*)\"/><br/><br/><p>(.*)</p>$"
#if os(Linux)
        let regex = try RegularExpression(pattern: pattern, options: [])
#else
        let regex = try NSRegularExpression(pattern: pattern, options: [])
#endif
        var imageUrl: String?
        var caption: String?
        regex.enumerateMatches(in: description,
                               options: [],
                               range: NSRange(location: 0, length: description.characters.count),
                               using: { (result, _, _) in
                                guard let result = result, result.numberOfRanges == 3 else {
                                    return
                                }
#if os(Linux)
                                imageUrl = NSString(string: description).substring(with: result.range(at: 1))
                                caption = NSString(string: description).substring(with: result.range(at: 2))
#else
                                imageUrl = (description as NSString).substring(with: result.rangeAt(1))
                                caption = (description as NSString).substring(with: result.rangeAt(2))
#endif
        })

        return (url: imageUrl, caption: caption)
    }

    func extract(path: String, from node: XMLNode) throws -> Any? {
        return try node.nodes(forXPath: path).first?.objectValue
    }
}
