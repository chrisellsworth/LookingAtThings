enum Looker: String {
    case il
    case un
}

extension Looker: CustomStringConvertible {
    var description: String {
        switch self {
        case .il:
            return "Kim Jong-il"
        case .un:
            return "Kim Jong-un"
        }
    }
}
