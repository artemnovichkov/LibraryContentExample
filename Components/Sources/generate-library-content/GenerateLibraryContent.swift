//
//  Created by Artem Novichkov on 13.12.2024.
//

import Foundation
import ArgumentParser
import SwiftSyntax
import SwiftParser
import SwiftSyntaxBuilder

@main
struct GenerateLibraryContent: ParsableCommand {

    @Option(help: "Target directory URL")
    var input: String

    @Option(help: "Directory containing the swift files")
    var output: String

    func run() throws {
        let fileNames = try FileManager.default.contentsOfDirectory(atPath: input)
        var viewNodes: [StructDeclSyntax] = []
        for fileName in fileNames {
            let contents = FileManager.default.contents(atPath: input + "/" + fileName)
            let source = String(data: contents!, encoding: .utf8)!
            let sourceFile = Parser.parse(source: source)
            let visitor = ViewStructVisitor(viewMode: .fixedUp)
            visitor.walk(sourceFile)
            viewNodes.append(contentsOf: visitor.viewNodes)
        }
        let finalCode = makeLibraryContent(nodes: viewNodes).formatted().description
        let url = URL(fileURLWithPath: output)
        try finalCode.write(to: url, atomically: true, encoding: .utf8)
    }

    // MARK: - Private

    private func makeLibraryContent(nodes: [StructDeclSyntax]) -> SourceFileSyntax {
        SourceFileSyntax {
            ImportDeclSyntax(path: .init { ImportPathComponentSyntax(name: "DeveloperToolsSupport") })
            ImportDeclSyntax(path: .init { ImportPathComponentSyntax(name: "SwiftUI") })
                .with(\.trailingTrivia, .newlines(2))

            let attributes = AttributeListSyntax {
                .attribute(AttributeSyntax(attributeName: TypeSyntax("preconcurrency")))
            }
            let attributedTypeSyntax = AttributedTypeSyntax(specifiers: [],
                                                            attributes: attributes,
                                                            baseType: TypeSyntax("LibraryContentProvider"))
            let inheritanceClause = InheritanceClauseSyntax {
                InheritedTypeSyntax(type: attributedTypeSyntax)
            }
            StructDeclSyntax(name: "LibraryContent", inheritanceClause: inheritanceClause) {
                let attributes = AttributeListSyntax {
                    AttributeListSyntax.Element.attribute(AttributeSyntax(attributeName: TypeSyntax("MainActor")))
                    AttributeListSyntax.Element.attribute(AttributeSyntax(attributeName: TypeSyntax("LibraryContentBuilder")))
                }
                    .with(\.trailingTrivia, .newline)
                let accessorBlock = AccessorBlockSyntax(accessors: AccessorBlockSyntax.Accessors(
                    CodeBlockItemListSyntax {
                        nodes.map(makeLibraryItem)
                    })
                )
                let bindings = PatternBindingListSyntax {
                    PatternBindingSyntax(
                        pattern: IdentifierPatternSyntax(identifier: .identifier("views")),
                        typeAnnotation: TypeAnnotationSyntax(type: ArrayTypeSyntax(element: TypeSyntax("LibraryItem"))),
                        accessorBlock: accessorBlock
                    )
                }
                VariableDeclSyntax(attributes: attributes,
                                   bindingSpecifier: .keyword(.var),
                                   bindings: bindings)
                .with(\.leadingTrivia, .newlines(2))
            }
        }
    }

    private func makeLibraryItem(node: StructDeclSyntax) -> FunctionCallExprSyntax {
        let viewExpression = FunctionCallExprSyntax(callee: DeclReferenceExprSyntax(baseName: node.name))
        let categoryExpression = MemberAccessExprSyntax(name: "control")

        let callee = DeclReferenceExprSyntax(baseName: .identifier("LibraryItem"))
        return FunctionCallExprSyntax(callee: callee) {
            LabeledExprSyntax(label: nil, expression: viewExpression)
            LabeledExprSyntax(label: "category", expression: categoryExpression)
        }
    }
}

final class ViewStructVisitor: SyntaxVisitor {

    var viewNodes: [StructDeclSyntax] = []

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        if let inheritanceClause = node.inheritanceClause {
            for inheritance in inheritanceClause.inheritedTypes {
                if inheritance.type.description.trimmingCharacters(in: .whitespacesAndNewlines) == "View" {
                    viewNodes.append(node)
                }
            }
        }
        return .visitChildren
    }
}
