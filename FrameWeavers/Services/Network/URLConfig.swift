import Foundation

struct URLConfig {
    static func value(for key: String) -> String? {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "env") else {
            print("错误：找不到Config.env文件。请确保它已添加到项目中。")
            return nil
        }
        
        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
            
            for line in lines {
                if line.starts(with: "#") || line.isEmpty { continue }
                
                let parts = line.components(separatedBy: "=")
                if parts.count == 2 {
                    let keyFromFile = parts[0].trimmingCharacters(in: .whitespaces)
                    let value = parts[1].trimmingCharacters(in: .whitespaces)
                    
                    if keyFromFile == key {
                        return value
                    }
                }
            }
        } catch {
            print("错误：无法读取Config.env文件 - \(error)")
        }
        
        return nil
    }
    
    static var baseURL: String {
        return value(for: "BASE_URL") ?? "https://fallback.com/"
    }
}
