import Foundation

/// RangeImporter — tiny CLI for transcribing third-party preflop charts into
/// the canonical Cutoff JSON format.
///
/// Usage:
///   swift run RangeImporter import --input <crib.csv|crib_dir> --output <Cutoff/Resources/Ranges>
///   swift run RangeImporter derive-9max --input <8max_dir> --output <Cutoff/Resources/Ranges>
///
/// The `import` mode turns each `.csv` crib sheet into a canonical JSON range
/// file. Filename drives the slug — see `ChartSlug.parse`.
///
/// The `derive-9max` mode reads existing `mtt_8max_*.json` files, applies the
/// rule-based 9-max adaptation from `NineMaxAdapter`, and writes the
/// `mtt_9max_*` siblings. Used in Phase C to regenerate the 9-max library
/// honestly (no fabricated solver output).

let args = CommandLine.arguments

guard args.count >= 2 else {
    Self_printUsageAndExit()
}

let mode = args[1]
var input: String?
var output: String?
var i = 2
while i < args.count {
    switch args[i] {
    case "--input":  i += 1; if i < args.count { input  = args[i] }
    case "--output": i += 1; if i < args.count { output = args[i] }
    default: break
    }
    i += 1
}

guard let input, let output else {
    Self_printUsageAndExit()
}

switch mode {
case "import":
    try runImport(inputPath: input, outputDir: output)
case "derive-9max":
    try runDerive9Max(inputDir: input, outputDir: output)
default:
    Self_printUsageAndExit()
}

// MARK: -

func runImport(inputPath: String, outputDir: String) throws {
    let fm = FileManager.default
    let inputURL = URL(fileURLWithPath: inputPath)
    var inputs: [URL] = []

    var isDir: ObjCBool = false
    guard fm.fileExists(atPath: inputURL.path, isDirectory: &isDir) else {
        throw ImporterError.cliFailure("input path does not exist: \(inputPath)")
    }
    if isDir.boolValue {
        let contents = try fm.contentsOfDirectory(at: inputURL, includingPropertiesForKeys: nil)
        inputs = contents.filter { $0.pathExtension.lowercased() == "csv" }
    } else {
        inputs = [inputURL]
    }
    if inputs.isEmpty {
        throw ImporterError.cliFailure("no .csv files found at \(inputPath)")
    }

    try fm.createDirectory(atPath: outputDir, withIntermediateDirectories: true)
    let publisher = PublisherMetadata.rangeConverter8maxMTT
    let emitter = Emitter(publisher: publisher)

    for url in inputs {
        let stem = url.deletingPathExtension().lastPathComponent
        guard let slug = ChartSlug.parse(stem) else {
            print("[skip] \(stem): filename does not match mtt_<size>max_<depth>bb_<pos>_<facing>")
            continue
        }
        let csv = try String(contentsOf: url, encoding: .utf8)
        let sheet = try CribSheet.parse(csv, sourceName: stem)
        let json = try emitter.emit(slug: slug, sheet: sheet)
        let outURL = URL(fileURLWithPath: outputDir).appendingPathComponent("\(slug.id).json")
        try json.write(to: outURL)
        print("[ok]   \(slug.id).json — \(sheet.coveredHandCount)/169 hands covered")
    }
}

func runDerive9Max(inputDir: String, outputDir: String) throws {
    let fm = FileManager.default
    let inputs = try fm.contentsOfDirectory(at: URL(fileURLWithPath: inputDir), includingPropertiesForKeys: nil)
        .filter { $0.lastPathComponent.hasPrefix("mtt_8max_") && $0.pathExtension == "json" }

    try fm.createDirectory(atPath: outputDir, withIntermediateDirectories: true)
    let publisher = PublisherMetadata.rangeConverter8maxMTT

    for url in inputs {
        // Recover the source crib by reading hands back from JSON.
        let sourceJSON = try Data(contentsOf: url)
        let stem = url.deletingPathExtension().lastPathComponent
        guard let sourceSlug = ChartSlug.parse(stem) else { continue }
        let sourceSheet = try cribSheet(fromCanonicalJSON: sourceJSON)

        // Decide target positions to generate. UTG and UTG+1 in 9-max both
        // pull from 8-max UTG; other seats map 1:1.
        let targets: [ChartSlug.Position]
        if sourceSlug.position == .utg {
            targets = [.utg, .utg1]
        } else {
            targets = [sourceSlug.position]
        }

        for target in targets {
            let (adapted, note) = NineMaxAdapter.adapt(
                eightMax: sourceSheet,
                sourcePosition: sourceSlug.position,
                targetPosition: target
            )
            let targetSlug = ChartSlug(
                tableSize: 9,
                depthBB: sourceSlug.depthBB,
                position: target,
                facing: sourceSlug.facing
            )
            let emitter = Emitter(publisher: publisher, extraAssumption: note)
            let json = try emitter.emit(slug: targetSlug, sheet: adapted)
            let outURL = URL(fileURLWithPath: outputDir).appendingPathComponent("\(targetSlug.id).json")
            try json.write(to: outURL)
            print("[ok]   \(targetSlug.id).json ← \(sourceSlug.id).json")
        }
    }
}

/// Reverse-parse a canonical JSON's `hands` block back into a CribSheet so we
/// can run the adapter on the structured strategy rather than on the raw file.
func cribSheet(fromCanonicalJSON data: Data) throws -> CribSheet {
    let raw = try JSONSerialization.jsonObject(with: data)
    guard let dict = raw as? [String: Any],
          let hands = dict["hands"] as? [String: Any] else {
        throw ImporterError.cliFailure("source JSON missing `hands` block")
    }
    var entries: [String: [String: Double]] = [:]
    for (notation, value) in hands {
        if let str = value as? String {
            entries[notation] = [coarse(forPreflopActionKey: str): 1.0]
        } else if let obj = value as? [String: Double] {
            var bucket: [String: Double] = [:]
            for (k, v) in obj { bucket[coarse(forPreflopActionKey: k), default: 0] += v }
            entries[notation] = bucket
        }
    }
    return CribSheet(entries: entries)
}

/// Reverse of `Emitter.preflopActionKey(forCoarse:)`.
func coarse(forPreflopActionKey key: String) -> String {
    switch key {
    case "fold":     return "fold"
    case "call":     return "call"
    case "limp":     return "limp"
    case "raise25x", "raise3x", "minRaise", "raise": return "raise"
    case "shove", "jam": return "jam"
    case "limpRaise": return "raise"
    default:         return key
    }
}

enum ImporterError: Error, CustomStringConvertible {
    case cliFailure(String)
    var description: String {
        switch self {
        case .cliFailure(let m): return m
        }
    }
}

func Self_printUsageAndExit() -> Never {
    let usage = """
    usage:
      RangeImporter import --input <file_or_dir.csv> --output <dir>
      RangeImporter derive-9max --input <dir_with_mtt_8max_*.json> --output <dir>
    """
    FileHandle.standardError.write(Data(usage.utf8))
    exit(2)
}
