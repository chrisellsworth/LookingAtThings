import Foundation

class ThingService {
    enum ThingServiceError: Error {
        case invalidURL(String)
        case invalidQuery(String)
    }

    func get(_ thing: String) throws -> [Thing] {
        let url = try self.url(thing: thing)
        return try fetch(url: url)
    }

    func url(thing: String) throws -> URL {
        guard let encoded = thing.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw ThingServiceError.invalidQuery(thing)
        }

        let string = "http://kimjongillookingatthings.tumblr.com/search/\(encoded)/rss"
        if let url = URL(string: string) {
            return url
        } else {
            throw ThingServiceError.invalidURL(string)
        }
    }

    func fetch(url: URL) throws -> [Thing] {
        let document = try XMLDocument(contentsOf: url, options: 0)
        return try parse(document: document)
    }

    func parse(document: XMLDocument) throws -> [Thing] {
        let nodes = try document.nodes(forXPath: "//channel/item/description")
        let values = try nodes
            .map { $0.objectValue as? String }
            .flatMap { $0 }
            .map(extract)
            .flatMap { $0 }
        return values
    }

    func extract(string: String) throws -> Thing? {
        let regex = try NSRegularExpression(pattern: "^<img src=\"(.*)\"/><br/><br/><p>(.*)</p>$", options: [])
        var url: String?
        var caption: String?
        regex.enumerateMatches(in: string,
                               options: [],
                               range: NSRange(location: 0, length: string.characters.count),
                               using: { (result, _, _) in
                                guard let result = result, result.numberOfRanges == 3 else {
                                    return
                                }
                                url = (string as NSString).substring(with: result.rangeAt(1))
                                caption = (string as NSString).substring(with: result.rangeAt(2))
        })

        if let url = url, let caption = caption {
            return Thing(url: url, caption: caption)
        } else {
            return nil
        }
    }
}
