import KeychainAccess

public class Datadog: API {
    internal var base_url: String = "api.datadoghq.com/api/v1/"
    internal var interval_seconds: TimeInterval = TimeInterval(10)
    public var metric: Metric = Metric.metric
    public var event: Event = Event.event
    private var timer: Timer = Timer()
    internal let keychain = Keychain(service: "api.datadoghq.com")
    public static let dd = Datadog()
    let host = UIDevice.current.identifierForVendor!.uuidString
    
    @objc private func sendData() {
        print("Sending metrics to the Datadog API.")
        if let cpu_usage = IOSAgent.current_CPU() {
            self.metric.send(metric: "system.cpu.user", points: Float(cpu_usage["user"]!), host: self.host, tags: [], type: .gauge)
            self.metric.send(metric: "system.cpu.idle", points: Float(cpu_usage["idle"]!), host: self.host, tags: [], type: .gauge)
            self.metric.send(metric: "system.cpu.system", points: Float(cpu_usage["system"]!), host: self.host, tags: [], type: .gauge)
        }
        if let mem_usage = IOSAgent.current_MEM() {
            self.metric.send(metric: "system.mem.used", points: mem_usage, host: self.host, tags: [], type: .gauge)
        }
        do {
            try self.metric._send(url: base_url) { (error: Error?) in
                print(error!)
            }
        } catch {
            fatalError(error.localizedDescription)
        }
        
    }
    
    private func get_credentials_from_plist() throws {
        var myDict: NSDictionary?
        if let path = Bundle.main.url(forResource: "datadog_config", withExtension: "plist") {
            myDict = NSDictionary(contentsOf: path)
        }
        if let dict = myDict {
            guard let api_key = dict["api_key"] as? String, let app_key = dict["app_key"] as? String else {
                throw DatadogAPIError.keyNotSet("API OR APP KEY NOT SET")
            }
            if keychain["api_key"] == nil || keychain["app_key"] == nil {
                do {
                    try keychain.set(api_key, key: "api_key")
                    try keychain.set(app_key, key: "app_key")
                    print("finished setting credentials")
                } catch {
                    throw DatadogAPIError.keyNotSet("Failed to set app or api key")
                }
                
            }
        }
    }
    
    
    private init() {
        do {
            try get_credentials_from_plist()
        } catch {
            fatalError(error.localizedDescription)
        }
        self.metric.addTags(tags: ["agent:ios"])
//        self.event.addTags(tags: ["host:ios_device1"])
        self.timer = Timer.scheduledTimer(timeInterval: self.interval_seconds, target: self, selector: #selector(Datadog.sendData), userInfo: nil, repeats: true)
    }
    
    
}
