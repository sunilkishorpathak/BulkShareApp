//
//  EditAddressView.swift
//  BulkMatesApp
//
//  View for editing user address
//

import SwiftUI
import FirebaseFirestore

struct EditAddressView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var firebaseManager: FirebaseManager
    let user: User

    @State private var street: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var postalCode: String = ""
    @State private var selectedCountry: String = "US"
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    var isFormValid: Bool {
        !city.isEmpty && !state.isEmpty && !postalCode.isEmpty
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Address Details")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Street Address (Optional)")
                            .font(.caption)
                            .foregroundColor(.bulkShareTextMedium)

                        TextField("123 Main Street", text: $street)
                            .textFieldStyle(BulkShareTextFieldStyle())
                            .autocapitalization(.words)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("City")
                            .font(.caption)
                            .foregroundColor(.bulkShareTextMedium)

                        TextField("City", text: $city)
                            .textFieldStyle(BulkShareTextFieldStyle())
                            .autocapitalization(.words)
                    }

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("State")
                                .font(.caption)
                                .foregroundColor(.bulkShareTextMedium)

                            TextField("State", text: $state)
                                .textFieldStyle(BulkShareTextFieldStyle())
                                .autocapitalization(.allCharacters)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Zip Code")
                                .font(.caption)
                                .foregroundColor(.bulkShareTextMedium)

                            TextField("12345", text: $postalCode)
                                .textFieldStyle(BulkShareTextFieldStyle())
                                .keyboardType(.numberPad)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Country")
                            .font(.caption)
                            .foregroundColor(.bulkShareTextMedium)

                        Picker("Country", selection: $selectedCountry) {
                            ForEach(countries, id: \.code) { country in
                                HStack {
                                    Text(country.flag)
                                    Text(country.name)
                                }
                                .tag(country.code)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .tint(.bulkSharePrimary)
                    }
                }

                Section {
                    Button(action: saveAddress) {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .bulkSharePrimary))
                            } else {
                                Text("Save Address")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.bulkSharePrimary)
                            }
                            Spacer()
                        }
                    }
                    .disabled(isLoading || !isFormValid)

                    if user.address != nil {
                        Button(role: .destructive, action: showRemoveConfirmation) {
                            HStack {
                                Spacer()
                                Text("Remove Address")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.bulkSharePrimary)
                }
            }
            .onAppear {
                loadCurrentAddress()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func loadCurrentAddress() {
        if let address = user.address {
            street = address.street ?? ""
            city = address.city
            state = address.state
            postalCode = address.postalCode
            selectedCountry = address.country
        } else if let countryCode = user.countryCode {
            selectedCountry = countryCode
        }
    }

    private func saveAddress() {
        guard isFormValid else { return }

        isLoading = true

        let newAddress = Address(
            street: street.isEmpty ? nil : street,
            city: city,
            state: state,
            postalCode: postalCode,
            country: selectedCountry
        )

        let addressData: [String: Any] = [
            "street": street.isEmpty ? "" : street,
            "city": city,
            "state": state,
            "postalCode": postalCode,
            "country": selectedCountry
        ]

        let db = Firestore.firestore()
        db.collection("users").document(user.id).updateData([
            "address": addressData,
            "countryCode": selectedCountry
        ]) { error in
            isLoading = false
            if let error = error {
                errorMessage = "Failed to save address: \(error.localizedDescription)"
                showError = true
            } else {
                // Update the user in FirebaseManager
                if var updatedUser = firebaseManager.currentUser {
                    updatedUser.address = newAddress
                    updatedUser.countryCode = selectedCountry
                    firebaseManager.currentUser = updatedUser
                }
                dismiss()
            }
        }
    }

    private func showRemoveConfirmation() {
        // TODO: Implement confirmation alert
        removeAddress()
    }

    private func removeAddress() {
        isLoading = true

        let db = Firestore.firestore()
        db.collection("users").document(user.id).updateData([
            "address": FieldValue.delete()
        ]) { error in
            isLoading = false
            if let error = error {
                errorMessage = "Failed to remove address: \(error.localizedDescription)"
                showError = true
            } else {
                // Update the user in FirebaseManager
                if var updatedUser = firebaseManager.currentUser {
                    updatedUser.address = nil
                    firebaseManager.currentUser = updatedUser
                }
                dismiss()
            }
        }
    }
}

#Preview {
    EditAddressView(user: User.sampleUsers[0])
        .environmentObject(FirebaseManager.shared)
}
