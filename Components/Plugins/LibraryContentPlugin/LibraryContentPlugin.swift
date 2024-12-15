//
//  Created by Artem Novichkov on 13.12.2024.
//

import Foundation
import PackagePlugin

@main
struct LibraryContentPlugin: CommandPlugin {

    func performCommand(context: PluginContext, arguments: [String]) async throws {
        var argumentExtractor = ArgumentExtractor(arguments)
        let targetNames = argumentExtractor.extractOption(named: "target")
        if targetNames.isEmpty {
            return
        }
        for target in try context.package.targets(named: targetNames) {
            guard let target = target as? SwiftSourceModuleTarget else {
                continue
            }
            guard target.kind == .generic else {
                continue
            }
            let tool = try context.tool(named: "generate-library-content")
            let toolExec = URL(fileURLWithPath: tool.url.path())
            let process = try Process.run(toolExec, arguments: ["--input", target.directoryURL.path,
                                                               "--output", target.directoryURL.appending(path: "LibraryContent.swift").path])
            process.waitUntilExit()
            if process.terminationReason == .exit && process.terminationStatus == 0 {
                print("LibraryContent.swift has been generated successfully")
            }
            else {
                let problem = "\(process.terminationReason):\(process.terminationStatus)"
                Diagnostics.error("Failed to generate LibraryContent.swift: \(problem)")
            }
        }
    }
}
