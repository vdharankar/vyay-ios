import Foundation

class Config {
    static let shared = Config()
    
    private init() {}
    
    private var configDict: [String: Any]? {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            print("Error: Could not find Config.plist")
            return nil
        }
        return dict
    }
    
    var openAIApiKey: String {
        return configDict?["OpenAI_API_Key"] as? String ?? ""
    }
} 