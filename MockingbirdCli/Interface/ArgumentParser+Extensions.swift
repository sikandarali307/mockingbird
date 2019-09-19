//
//  ArgumentParser+Extensions.swift
//  MockingbirdCli
//
//  Created by Andrew Chang on 8/23/19.
//

import Foundation
import MockingbirdGenerator
import PathKit
import SPMUtility

extension ArgumentParser {
  // MARK: Options
  
  func addProjectPath() -> OptionArgument<PathArgument> {
    return add(option: "--project",
               kind: PathArgument.self,
               usage: "Path to your project’s `.xcodeproj` file.",
               completion: .filename)
  }
  
  func addSourceRoot() -> OptionArgument<PathArgument> {
    return add(option: "--srcroot",
               kind: PathArgument.self,
               usage: "The folder containing your project's source files.",
               completion: .filename)
  }
  
  func addTargets() -> OptionArgument<[String]> {
    return add(option: "--targets",
               kind: [String].self,
               usage: "List of target names to generate mocks for.")
  }
  
  /// Convenience for `--targets`. Accepts multiple targets.
  func addTarget() -> OptionArgument<[String]> {
    return add(option: "--target",
               kind: [String].self,
               usage: "A target name to generate mocks for.")
  }
  
  func addSourceTargets() -> OptionArgument<[String]> {
    return add(option: "--targets",
               kind: [String].self,
               usage: "List of target names that should generate mocks.")
  }
  
  /// Convenience for source `--targets`. Accepts multiple targets.
  func addSourceTarget() -> OptionArgument<[String]> {
    return add(option: "--target",
               kind: [String].self,
               usage: "A target name that should generate mocks.")
  }
  
  func addDestinationTarget() -> OptionArgument<String> {
    return add(option: "--destination",
               kind: String.self,
               usage: "The target name where the Run Script Phase will be installed.")
  }
  
  func addOutputs() -> OptionArgument<[PathArgument]> {
    return add(option: "--outputs",
               kind: [PathArgument].self,
               usage: "List of mock output file paths for each target.",
               completion: .filename)
  }
  
  /// Convenience for `--outputs`. Accepts multiple outputs.
  func addOutput() -> OptionArgument<[PathArgument]> {
    return add(option: "--output",
               kind: [PathArgument].self,
               usage: "Mock output file path.",
               completion: .filename)
  }
  
  func addCompilationCondition() -> OptionArgument<String> {
    return add(option: "--condition",
               kind: String.self,
               usage: "Compilation condition to wrap all generated mocks in, e.g. `DEBUG`.",
               completion: .values([
                (value: "DEBUG", description: "Debug build configuration"),
                (value: "RELEASE", description: "Release build configuration"),
                (value: "TEST", description: "Test build configuration")]))
  }
  
  func addMetagenerateOutput() -> OptionArgument<PathArgument> {
    return add(option: "--output",
               kind: PathArgument.self,
               usage: "Output directory to generate source files.",
               completion: .filename)
  }
  
  func addMetagenerateCount() -> OptionArgument<Int> {
    return add(option: "--count",
               kind: Int.self,
               usage: "Number of source files to generate.")
  }
  
  // MARK: Global Options
  
  func addVerboseLogLevel() -> OptionArgument<Bool> {
    return add(option: "--verbose",
               kind: Bool.self,
               usage: "Log all errors, warnings, and debug messages.")
  }
  
  func addQuietLogLevel() -> OptionArgument<Bool> {
    return add(option: "--quiet",
               kind: Bool.self,
               usage: "Only log error messages.")
  }
  
  // MARK: Flags
  
  func addOnlyProtocols() -> OptionArgument<Bool> {
    return add(option: "--only-protocols",
               kind: Bool.self,
               usage: "Only generate mocks for protocols.")
  }
  
  func addDisableModuleImport() -> OptionArgument<Bool> {
    return add(option: "--disable-module-import",
               kind: Bool.self,
               usage: "Omit `@testable import <module>` from generated mocks.")
  }
  
  func addIgnoreExistingRunScript() -> OptionArgument<Bool> {
    return add(option: "--ignore-existing",
               kind: Bool.self,
               usage: "Don’t overwrite existing Run Scripts created by Mockingbird CLI.")
  }
  
  func addAynchronousGeneration() -> OptionArgument<Bool> {
    return add(option: "--asynchronous",
               kind: Bool.self,
               usage: "Generate mocks asynchronously in the background when building.")
  }
  
  func addDisableSwiftlint() -> OptionArgument<Bool> {
    return add(option: "--disable-swiftlint",
               kind: Bool.self,
               usage: "Disable all SwiftLint rules in generated mocks.")
  }
}

extension ArgumentParser.Result {
  func getProjectPath(using argument: OptionArgument<PathArgument>,
                      environment: [String: String]) throws -> Path {
    let projectPath: Path
    if let rawProjectPath = get(argument)?.path.pathString ?? environment["PROJECT_FILE_PATH"] {
      projectPath = Path(rawProjectPath)
    } else {
      throw ArgumentParserError.expectedValue(option: "--project <xcodeproj file path>")
    }
    guard projectPath.isDirectory, projectPath.extension == "xcodeproj" else {
      throw ArgumentParserError.invalidValue(argument: "--project \(projectPath.absolute())",
                                             error: .custom("Not a valid `.xcodeproj` path"))
    }
    return projectPath
  }
  
  func getSourceRoot(using argument: OptionArgument<PathArgument>,
                     environment: [String: String],
                     projectPath: Path) throws -> Path {
    if let rawSourceRoot = get(argument)?.path.pathString ?? environment["SRCROOT"] {
      return Path(rawSourceRoot)
    } else {
      return projectPath.parent()
    }
  }
  
  func getTargets(using argument: OptionArgument<[String]>,
                  convenienceArgument: OptionArgument<[String]>,
                  environment: [String: String]) throws -> [String] {
    if let targets = get(argument) ?? get(convenienceArgument) {
      return targets
    } else if let target = environment["TARGET_NAME"] {
      return [target]
    } else {
      throw ArgumentParserError.expectedValue(option: "--targets <list of target names>")
    }
  }
  
  func getOutputs(using argument: OptionArgument<[PathArgument]>,
                  convenienceArgument: OptionArgument<[PathArgument]>) throws -> [Path]? {
    if let rawOutputs = (get(argument) ?? get(convenienceArgument))?.map({ $0.path.pathString }) {
      return rawOutputs.map({ Path($0) })
    }
    return nil
  }
  
  func getSourceTargets(using argument: OptionArgument<[String]>,
                        convenienceArgument: OptionArgument<[String]>) throws -> [String] {
    if let targets = get(argument) ?? get(convenienceArgument) {
      return targets
    } else {
      throw ArgumentParserError.expectedValue(option: "--targets <list of target names>")
    }
  }
  
  func getDestinationTarget(using argument: OptionArgument<String>) throws -> String {
    if let target = get(argument) {
      return target
    } else {
      throw ArgumentParserError.expectedValue(option: "--destination <target name>")
    }
  }
  
  func getOutputDirectory(using argument: OptionArgument<PathArgument>) throws -> Path {
    if let rawOutput = get(argument)?.path.pathString {
      let path = Path(rawOutput)
      guard path.isDirectory else {
        throw ArgumentParserError.invalidValue(argument: "--output \(path.absolute())",
                                               error: .custom("Not a valid directory"))
      }
      return path
    }
    throw ArgumentParserError.expectedValue(option: "--output <list of output file paths>")
  }
  
  func getCount(using argument: OptionArgument<Int>) throws -> Int? {
    if let count = get(argument) {
      guard count > 0 else {
        throw ArgumentParserError.invalidValue(argument: "--count \(count)",
                                               error: .custom("Not a positive number"))
      }
      return count
    }
    return nil
  }
  
  func getLogLevel(verboseOption: OptionArgument<Bool>,
                   quietOption: OptionArgument<Bool>) throws -> LogLevel {
    let isVerbose = get(verboseOption) == true
    let isQuiet = get(quietOption) == true
    guard !isVerbose || !isQuiet else {
      throw ArgumentParserError.invalidValue(argument: "--verbose --quiet",
                                             error: .custom("Cannot specify both --verbose and --quiet"))
    }
    if isVerbose {
      return .verbose
    } else if isQuiet {
      return .quiet
    } else {
      return .normal
    }
  }
}
