import Foundation

// regle mdp simples
struct PasswordPolicy {
    static func violations(for password: String) -> [String] {
        var errs: [String] = []
        if password.count < 8 { errs.append("Au moins 8 caractères") }

        let upper = CharacterSet.uppercaseLetters
        let lower = CharacterSet.lowercaseLetters
        let digits = CharacterSet.decimalDigits
        let specials = CharacterSet.alphanumerics.inverted

        if password.rangeOfCharacter(from: upper) == nil { errs.append("Au moins une majuscule") }
        if password.rangeOfCharacter(from: lower) == nil { errs.append("Au moins une minuscule") }
        if password.rangeOfCharacter(from: digits) == nil { errs.append("Au moins un chiffre") }
        if password.rangeOfCharacter(from: specials) == nil { errs.append("Au moins un caractère spécial") }

        return errs
    }

    static func signupErrors(password: String, confirm: String) -> [String] {
        var all = violations(for: password)
        if password != confirm { all.append("Les mots de passe ne correspondent pas") }
        return all
    }
}
