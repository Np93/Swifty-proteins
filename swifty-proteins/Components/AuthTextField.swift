import SwiftUI

// modele de champ de texte pour login/mot de passe (pour vue login et signup)
struct AuthTextField<FieldType: Hashable>: View {
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool
    var isPassword: Bool
    var onToggleSecure: () -> Void
    var focusedField: FocusState<FieldType?>.Binding
    var field: FieldType
    var submitLabel: SubmitLabel
    var onSubmit: () -> Void
    var body: some View {
        HStack {
            Group {
                if isPassword && isSecure {
                    SecureField(placeholder, text: $text)
                        .textContentType(.password)
                        .privacySensitive()
                } else if isPassword {
                    TextField(placeholder, text: $text)
                        .textContentType(.password)
                        .privacySensitive()
                } else {
                    TextField(placeholder, text: $text)
                        .textContentType(.username)
                        .keyboardType(.asciiCapable)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused(focusedField, equals: field)
            .submitLabel(submitLabel)
            .onSubmit(onSubmit)
            if isPassword {
                Button(action: onToggleSecure) {
                    Image(systemName: isSecure ? "eye.slash" : "eye")
                }
                .foregroundStyle(Color("SubColor"))
                .accessibilityLabel(isSecure ? "Afficher le mot de passe" : "Masquer le mot de passe")
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 48)
        .background(Color("SectionColor"), in: RoundedRectangle(cornerRadius: 12))
        .foregroundStyle(Color("OnSectionColor"))
    }
}
