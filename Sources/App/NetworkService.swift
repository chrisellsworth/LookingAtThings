import Foundation
import HTTP
import Vapor

class NetworkService {
    enum NetworkServiceError: Error {
        case invalid(URL)
    }

    let drop: Droplet

    init(drop: Droplet) {
        self.drop = drop
    }

    func resolve(url: URL) throws -> URL {
        let response = try drop.client.get(url.absoluteString)

        let location = response.headers[HeaderKey.location]

        if let location = location, let locationURL = URL(string: location) {
            return locationURL
        } else {
            throw NetworkServiceError.invalid(url)
        }
    }
}
