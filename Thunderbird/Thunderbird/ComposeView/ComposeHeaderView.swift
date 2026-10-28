// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import SwiftUI
import Core

struct ComposeHeaderView: View {
    @State var email: Email?

    @Environment(AccountManager.self) private var accountManager: AccountManager
    @State private var subject: String = ""
    @State private var toRecipients: [String] = []
    @State private var replyToRecipients: [String] = []
    @State private var ccRecipients: [String] = []
    @State private var bccRecipients: [String] = []
    @State private var selectedSender: UUID = UUID()
    @State private var showCCBCC: Bool = false
    @State private var showReplyTo: Bool = false

    var ccBccString: String {
        let ccString = (ccRecipients.count > 0) ? "Cc: \(ccRecipients.count)" : "Cc"
        let bccString = (bccRecipients.count > 0) ? "Bcc \(bccRecipients.count)" : "Bcc"
        return "\(ccString)/\(bccString)"
    }

    func populateFromEmail(_ email: Email?) {
        guard let email else { return }

        subject = email.subject ?? subject

        toRecipients = email.toStringArray
        replyToRecipients = email.replyToStringArray
        ccRecipients = email.ccStringArray
        bccRecipients = email.bccStringArray
    }

    var fromField: some View {
        HStack {
            Text("from_header")
                .fontWeight(.semibold)
                .foregroundStyle(.gray)

            Menu(accountManager.account(for: selectedSender)?.name ?? "select an account") {
                ForEach(accountManager.allAccounts) { account in
                    Button {
                        selectedSender = account.id
                    } label: {
                        HStack {
                            Image(systemName: "checkmark")
                                .tint(selectedSender == account.id ? .blue : .clear)

                            Text(account.name)
                        }
                    }
                }
            }

            Spacer()
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Group {
                HStack {
                    fromField

                    Spacer()

                    // TODO: HOW WOULD DESIGN LIKE TO HANDLE THE SHOW/HIDE NATURE OF THIS FIELD?
                    Button("", systemImage: (showReplyTo ? "chevron.up" : "chevron.down")) {
                        withAnimation {
                            showReplyTo.toggle()
                        }
                    }
                    .foregroundStyle(.black)
                }

                if showReplyTo {
                    Divider()
                    MultiAddressBar("reply_to_header", $replyToRecipients)
                }

                Divider()

                HStack {
                    MultiAddressBar("to_header", $toRecipients)

                    Button {
                        withAnimation {
                            showCCBCC.toggle()
                        }
                    } label: {
                        Text(ccBccString)
                            .padding(4)
                            .padding(.horizontal, 12)
                    }
                    .overlay(
                        Capsule()
                            .stroke(lineWidth: 1)
                            .foregroundStyle(.blue)
                    )
                }
            }

            if showCCBCC {
                Divider()
                MultiAddressBar("cc_header", $ccRecipients)
                Divider()
                MultiAddressBar("bcc_header", $bccRecipients)
            }

            Divider()

            HStack {
                Text("subject_header")
                    .fontWeight(.semibold)
                    .foregroundStyle(.gray)
                TextField("", text: $subject, axis: .vertical)
                    .font(.subheadline)
                    .lineLimit(1...3)
            }

            Divider()
        }
        .padding()
        .onAppear {
            selectedSender = accountManager.allAccounts.first?.id ?? UUID()
            populateFromEmail(email)
        }
    }
}

struct MultiAddressBar: View {
    init(
        _ header: LocalizedStringResource = "",
        _ entryText: Binding<[String]>,
    ) {
        headerText = header
        _entryText = entryText
    }

    private var headerText: LocalizedStringResource
    @Binding private var entryText: [String]
    @State private var entryString: String = ""

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(headerText)
                    .fixedSize()
                    .fontWeight(.semibold)
                    .foregroundStyle(.gray)

                TextField("", text: $entryString)
                    .textFieldStyle(.automatic)
                    #if os(iOS)
                .autocapitalization(.none)
                    #endif
                    .autocorrectionDisabled()
                    .focusable()
                    .onSubmit {
                        if entryString.isEmailAddress {
                            withAnimation {
                                entryText.append(entryString)
                                entryString = ""
                            }
                        }
                    }
            }

            HStackWrap {
                ForEach(entryText, id: \.self) { email in
                    EmailPill(email, $entryText)
                }
            }
        }
    }
}

struct EmailPill: View {
    init(_ email: String, _ currentEntries: Binding<[String]>) {
        emailAddress = email
        _entries = currentEntries
    }

    @State private var emailAddress: String
    @Binding private var entries: [String]

    var body: some View {
        HStack {
            Text(emailAddress)
                .foregroundStyle(.blue)
                .onTapGesture {
                    withAnimation {
                        let entry = entries.remove(at: entries.firstIndex(of: emailAddress)!)

                    }
                }

            // TODO: CAN WE DROP THIS BUTTON WITH DESIGN APPROVAL?
            Label("remove_button", systemImage: "x.circle")
                .foregroundStyle(.blue)
                .labelStyle(.iconOnly)
                .onTapGesture {
                    withAnimation {
                        _ = entries.remove(at: entries.firstIndex(of: emailAddress)!)
                    }
                }
        }
        .padding(4)
        .padding(.horizontal, 8)
        .background(
            Capsule()
//                .stroke(lineWidth: 1)
                .foregroundStyle(.gray)
        )
    }
}

#Preview {
    @Previewable @State var accountManager: AccountManager = AccountManager()

    ComposeHeaderView()
        .environment(accountManager)
}
