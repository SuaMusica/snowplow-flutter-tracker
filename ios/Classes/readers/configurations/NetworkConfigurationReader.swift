// Copyright (c) 2022 Snowplow Analytics Ltd. All rights reserved.
//
// This program is licensed to you under the Apache License Version 2.0,
// and you may not use this file except in compliance with the Apache License Version 2.0.
// You may obtain a copy of the Apache License Version 2.0 at http://www.apache.org/licenses/LICENSE-2.0.
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the Apache License Version 2.0 is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the Apache License Version 2.0 for the specific language governing permissions and limitations there under.

import Foundation
import SnowplowTracker

struct NetworkConfigurationReader: Decodable {
    let endpoint: String
    let method: String?
    let customPostPath: String?
    let requestHeaders: [String: String]?
}

extension NetworkConfigurationReader {
    func toConfiguration() -> NetworkConfiguration {
        let networkConfig: NetworkConfiguration

        if let m = method {
            networkConfig = NetworkConfiguration(endpoint: endpoint, method: m == "get" ? .get : .post)
        } else {
            networkConfig = NetworkConfiguration(endpoint: endpoint, method: .post)
        }

        if let c = customPostPath {
            networkConfig.customPostPath(c)
        }
        if let h = requestHeaders {
            networkConfig.requestHeaders(h)
        }
        return networkConfig
    }
}
