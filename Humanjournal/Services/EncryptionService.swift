//
//  EncryptionService.swift
//  Humanjournal
//

import Foundation
import CryptoKit

enum EncryptionError: Error {
    case keyGenerationFailed
    case encryptionFailed
    case decryptionFailed
    case invalidData
}

final class EncryptionService {
    static let shared = EncryptionService()

    private let keychainService = KeychainService.shared

    private init() {}

    func ensureKeyExists() throws {
        if !keychainService.encryptionKeyExists() {
            let key = SymmetricKey(size: .bits256)
            let keyData = key.withUnsafeBytes { Data($0) }
            try keychainService.saveEncryptionKey(keyData)
        }
    }

    func encrypt(_ plaintext: String) throws -> Data {
        guard let data = plaintext.data(using: .utf8) else {
            throw EncryptionError.invalidData
        }
        return try encrypt(data)
    }

    func encrypt(_ data: Data) throws -> Data {
        let key = try getSymmetricKey()

        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            guard let combined = sealedBox.combined else {
                throw EncryptionError.encryptionFailed
            }
            return combined
        } catch {
            throw EncryptionError.encryptionFailed
        }
    }

    func decrypt(_ encryptedData: Data) throws -> Data {
        let key = try getSymmetricKey()

        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return decryptedData
        } catch {
            throw EncryptionError.decryptionFailed
        }
    }

    func decryptToString(_ encryptedData: Data) throws -> String {
        let decryptedData = try decrypt(encryptedData)
        guard let string = String(data: decryptedData, encoding: .utf8) else {
            throw EncryptionError.invalidData
        }
        return string
    }

    private func getSymmetricKey() throws -> SymmetricKey {
        let keyData = try keychainService.getEncryptionKey()
        return SymmetricKey(data: keyData)
    }
}
