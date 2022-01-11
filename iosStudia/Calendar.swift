//
//  Calendar.swift
//  iosStudia
//
//  Created by 이종우 on 2022/01/10.
//

import Foundation
import Firebase

struct Calendar: Codable {
    let memo: String
    let reminder: [String]
}

extension Dictionary {
    var JSON: Data {
        do {
            return try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
        } catch {
            return Data()
        }
    }
}

extension DataSnapshot {
  var valueToJSON: Data {
      guard let dictionary = value as? [String: Any] else {
          return Data()
      }
      return dictionary.JSON
  }

  var listToJSON: Data {
      guard let object = children.allObjects as? [DataSnapshot] else {
          return Data()
      }

      let dictionary: [NSDictionary] = object.compactMap { $0.value as? NSDictionary }

      do {
          return try JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
      } catch {
          return Data()
      }
  }
}
