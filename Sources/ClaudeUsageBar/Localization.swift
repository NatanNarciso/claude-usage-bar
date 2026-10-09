import Foundation

/// Bundle de onde as strings são lidas. Em geral é o do app; as ferramentas de
/// geração de imagens (tools/) apontam para uma pasta <idioma>.lproj específica.
nonisolated(unsafe) var localizationBundle: Bundle = .main

/// Busca a string traduzida (Resources/<idioma>.lproj/Localizable.strings) e aplica os argumentos.
func L(_ key: String, _ args: CVarArg...) -> String {
    let format = localizationBundle.localizedString(forKey: key, value: key, table: nil)
    return args.isEmpty ? format : String(format: format, arguments: args)
}
