//
// Copyright (c) 2022 gematik GmbH
//
// Licensed under the Apache License, Version 2.0 (the License);
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an 'AS IS' BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import ASN1Kit
import ArgumentParser
import DataKit
import Foundation

struct ParseCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "parse",
        abstract: "Parse ASN.1 encoded file or from cmd-line input"
    )

    enum ParseError: Error, CustomStringConvertible {
        case unsupportedMode(_: String)
        case asn1Error(Swift.Error)

        var description: String {
            switch self {
            case .unsupportedMode(let message):
                return message
            case .asn1Error(let error):
                return error.localizedDescription
            }
        }
    }

    @Option(name: .shortAndLong, help: "path to ANS.1 encoded file")
    var file: String = ""

    @Option(name: .shortAndLong, help: "String passed as ASN.1 encoded hex")
    var string: String = ""

    @Flag(name: .shortAndLong, help: "Show verbose logging")
    var verbose: Bool = false

    func run() throws {
        let fileURL = URL(fileURLWithPath: (file as NSString).expandingTildeInPath)
        let fileContents = try? fileURL.readFileContents()
        guard !string.isEmpty || fileContents != nil else {
            throw ParseError.unsupportedMode("No string or valid file path passed")
        }

        do {
            let data: Data
            if let fileContents = fileContents {
                data = fileContents
            } else {
                let sanitized = string.sanitize()
                data = try Data(hex: sanitized)
            }
            let asn1 = try ASN1Decoder.decode(asn1: data)

            print("ASN1: [\(asn1)]")
        } catch let error {
            throw ParseError.asn1Error(error)
        }
    }
}

extension String {
    /// Remove all non hex-characters from String so it can be interpreted by Data(hex:)
    func sanitize() -> String {
        let allowedCharacters = "0123456789abcdefABCDEF".characterSet
        return self.filter(allowedCharacters.contains)
    }
}
