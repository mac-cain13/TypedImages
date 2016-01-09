//
//  ResourceFile.swift
//  R.swift
//
//  Created by Mathijs Kadijk on 10-12-15.
//  Copyright © 2015 Mathijs Kadijk. All rights reserved.
//

import Foundation

struct ResourceFileGenerator: Generator {
  let externalStruct: Struct?
  let internalStruct: Struct? = nil

  init(resourceFiles: [ResourceFile]) {
    let groupedResourceFiles = resourceFiles
      .groupUniquesAndDuplicates { sanitizedSwiftName($0.fullname) }

    for duplicate in groupedResourceFiles.duplicates {
      let names = duplicate.map { $0.fullname }.sort().joinWithSeparator(", ")
      warn("Skipping \(duplicate.count) resource files because symbol '\(sanitizedSwiftName(duplicate.first!.fullname))' would be generated for all of these files: \(names)")
    }

    externalStruct = Struct(
      type: Type(module: .Host, name: "file"),
      implements: [],
      typealiasses: [],
      properties: groupedResourceFiles
        .uniques
        .map {
          let pathExtensionOrNilString = $0.pathExtension.map { "\"\($0)\"" } ?? "nil"
          return Let(isStatic: true, name: $0.fullname, type: nil, value: "FileResource(bundle: _R.hostingBundle, name: \"\($0.filename)\", pathExtension: \(pathExtensionOrNilString))")
        },
      functions: [],
      structs: []
    )
  }
}
