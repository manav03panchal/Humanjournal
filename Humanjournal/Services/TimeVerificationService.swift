//
//  TimeVerificationService.swift
//  Humanjournal
//

import Foundation

actor TimeVerificationService {
    static let shared = TimeVerificationService()

    private let ntpServers = [
        "time.apple.com",
        "time.google.com",
        "pool.ntp.org"
    ]

    private var cachedNetworkTime: Date?
    private var cacheTimestamp: Date?
    private let cacheValiditySeconds: TimeInterval = 300

    private init() {}

    func getVerifiedDate() async -> Date {
        if let cached = cachedNetworkTime,
           let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) < cacheValiditySeconds {
            let elapsed = Date().timeIntervalSince(timestamp)
            return cached.addingTimeInterval(elapsed)
        }

        if let networkTime = await fetchNetworkTime() {
            cachedNetworkTime = networkTime
            cacheTimestamp = Date()
            return networkTime
        }

        return Date()
    }

    func isDateManipulated() async -> Bool {
        guard let networkTime = await fetchNetworkTime() else {
            return false
        }

        let deviceTime = Date()
        let difference = abs(networkTime.timeIntervalSince(deviceTime))

        return difference > 60
    }

    private func fetchNetworkTime() async -> Date? {
        for server in ntpServers {
            if let time = await fetchTimeFromServer(server) {
                return time
            }
        }
        return nil
    }

    private func fetchTimeFromServer(_ server: String) async -> Date? {
        guard let url = URL(string: "https://\(server)") else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse,
               let dateString = httpResponse.value(forHTTPHeaderField: "Date") {
                let formatter = DateFormatter()
                formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                return formatter.date(from: dateString)
            }
        } catch {
            return nil
        }

        return nil
    }
}
