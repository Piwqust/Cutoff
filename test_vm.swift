import Foundation

let dir = "/Users/dameer/Desktop/code/MTT TR/Cutoff/Resources/Ranges"
let files = try! FileManager.default.contentsOfDirectory(atPath: dir)

var hasOpp = 0
var btnVsOpenOpps = Set<String>()

for file in files where file.hasSuffix(".json") {
    let url = URL(fileURLWithPath: dir).appendingPathComponent(file)
    let data = try! Data(contentsOf: url)
    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
       let spot = json["spot"] as? [String: Any] {
        if let opp = spot["opponentPosition"] as? String {
            hasOpp += 1
            let pos = spot["position"] as? String
            let facing = spot["facingAction"] as? String
            if pos == "BTN" && facing == "vsOpen" {
                btnVsOpenOpps.insert(opp)
            }
        }
    }
}
print("Total charts with opp: \(hasOpp)")
print("BTN vsOpen opps: \(btnVsOpenOpps)")
