import SwiftUI

struct ExcludedAppRow: View {
    let identity: AppIdentity
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: identity.icon)
                .resizable()
                .interpolation(.high)
                .frame(width: 28, height: 28)

            Text(identity.name)
                .font(.body)
                .lineLimit(1)

            Spacer(minLength: 8)

            Button("移除", role: .destructive) {
                onRemove()
            }
        }
        .padding(.vertical, 2)
    }
}
