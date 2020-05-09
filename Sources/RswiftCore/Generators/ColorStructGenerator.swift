//
//  ColorStructGenerator.swift
//  R.swift
//
//  Created by Tom Lokhorst on 2017-06-06.
//  From: https://github.com/mac-cain13/R.swift
//  License: MIT License
//

import Foundation

struct ColorStructGenerator: ExternalOnlyStructGenerator {
  private let assetFolders: [AssetFolder]

  init(assetFolders: [AssetFolder]) {
    self.assetFolders = assetFolders
  }

  func generatedStruct(at externalAccessLevel: AccessLevel, prefix: SwiftIdentifier) -> Struct {
    let structName: SwiftIdentifier = "color"
    let qualifiedName = prefix + structName
    let assetFolderColorNames = assetFolders
      .flatMap { $0.colorAssets }

    let groupedColors = assetFolderColorNames.grouped(bySwiftIdentifier: { $0 })
    groupedColors.printWarningsForDuplicatesAndEmpties(source: "color", result: "color")


    let assetSubfolders = AssetSubfolders(
      all: assetFolders.flatMap { $0.subfolders },
      assetIdentifiers: groupedColors.uniques.map { SwiftIdentifier(name: $0) })

    assetSubfolders.printWarningsForDuplicates()

    let structs = assetSubfolders.folders
      .map { $0.generatedColorStruct(at: externalAccessLevel, prefix: qualifiedName) }
      .filter { !$0.isEmpty }

    let colorLets = groupedColors
      .uniques
      .map { name in
        Let(
          comments: ["Color `\(name)`."],
          accessModifier: externalAccessLevel,
          isStatic: true,
          name: SwiftIdentifier(name: name),
          typeDefinition: .inferred(Type.ColorResource),
          value: "Rswift.ColorResource(bundle: R.hostingBundle, name: \"\(name)\")"
        )
    }

    return Struct(
      availables: [],
      comments: ["This `\(qualifiedName)` struct is generated, and contains static references to \(colorLets.count) colors."],
      accessModifier: externalAccessLevel,
      type: Type(module: .host, name: structName),
      implements: [],
      typealiasses: [],
      properties: colorLets,
      functions: groupedColors.uniques.map { colorFunction(for: $0, at: externalAccessLevel, prefix: qualifiedName) },
      structs: structs,
      classes: [],
      os: []
    )
  }

  private func colorFunction(for name: String, at externalAccessLevel: AccessLevel, prefix: SwiftIdentifier) -> Function {
    let structName = SwiftIdentifier(name: name)
    let qualifiedName = prefix + structName

    return Function(
      availables: ["tvOS 11.0, *", "iOS 11.0, *"],
      comments: ["`UIColor(named: \"\(name)\", bundle: ..., traitCollection: ...)`"],
      accessModifier: externalAccessLevel,
      isStatic: true,
      name: structName,
      generics: nil,
      parameters: [
        Function.Parameter(
          name: "compatibleWith",
          localName: "traitCollection",
          type: Type._UITraitCollection.asOptional(),
          defaultValue: "nil"
        )
      ],
      doesThrow: false,
      returnType: Type._UIColor.asOptional(),
      body: "return UIKit.UIColor(resource: \(qualifiedName), compatibleWith: traitCollection)",
      os: ["iOS", "tvOS"]
    )
  }
}

private extension NamespacedAssetSubfolder {
  func generatedColorStruct(at externalAccessLevel: AccessLevel, prefix: SwiftIdentifier) -> Struct {
    let allFunctions = colorAssets
    let groupedFunctions = allFunctions.grouped(bySwiftIdentifier: { $0 })

    groupedFunctions.printWarningsForDuplicatesAndEmpties(source: "color", result: "color")


    let assetSubfolders = AssetSubfolders(
      all: subfolders,
      assetIdentifiers: allFunctions.map { SwiftIdentifier(name: $0) })

    assetSubfolders.printWarningsForDuplicates()

    let colorPath = resourcePath + (!path.isEmpty ? "/" : "")
    let structName = SwiftIdentifier(name: self.name)
    let qualifiedName = prefix + structName
    let structs = assetSubfolders.folders
      .map { $0.generatedColorStruct(at: externalAccessLevel, prefix: qualifiedName) }
      .filter { !$0.isEmpty }

    let colorLets = groupedFunctions
      .uniques
      .map { name in
        Let(
          comments: ["Color `\(name)`."],
          accessModifier: externalAccessLevel,
          isStatic: true,
          name: SwiftIdentifier(name: name),
          typeDefinition: .inferred(Type.ColorResource),
          value: "Rswift.ColorResource(bundle: R.hostingBundle, name: \"\(colorPath)\(name)\")"
        )
    }
	
	let allColorNames = colorLets.map { $0.name.description }
	let allColorsLet = Let(comments: ["An array of all color assets contained in this namespaced folder (not including subfolders)"],
						   accessModifier: externalAccessLevel,
						   isStatic: true,
						   name: "allColors",
						   typeDefinition: .specified(Type._Array.withGenericArgs([Type.ColorResource])),
						   value: "[" + allColorNames.joined(separator: ", ") + "]")

    return Struct(
      availables: [],
      comments: ["This `\(qualifiedName)` struct is generated, and contains static references to \(colorLets.count) colors."],
      accessModifier: externalAccessLevel,
      type: Type(module: .host, name: structName),
      implements: [],
      typealiasses: [],
      properties: [allColorsLet] + colorLets,
      functions: groupedFunctions.uniques.map { colorFunction(for: $0, at: externalAccessLevel, prefix: qualifiedName) },
      structs: structs,
      classes: [],
      os: []
    )
  }

  private func colorFunction(for name: String, at externalAccessLevel: AccessLevel, prefix: SwiftIdentifier) -> Function {
    let structName = SwiftIdentifier(name: name)
    let qualifiedName = prefix + structName

    return Function(
      availables: ["tvOS 11.0, *", "iOS 11.0, *"],
      comments: ["`UIColor(named: \"\(name)\", bundle: ..., traitCollection: ...)`"],
      accessModifier: externalAccessLevel,
      isStatic: true,
      name: structName,
      generics: nil,
      parameters: [
        Function.Parameter(
          name: "compatibleWith",
          localName: "traitCollection",
          type: Type._UITraitCollection.asOptional(),
          defaultValue: "nil"
        )
      ],
      doesThrow: false,
      returnType: Type._UIColor.asOptional(),
      body: "return UIKit.UIColor(resource: \(qualifiedName), compatibleWith: traitCollection)",
      os: ["iOS", "tvOS"]
    )
  }
}
