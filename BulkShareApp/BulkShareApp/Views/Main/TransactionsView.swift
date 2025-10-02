//
//  TransactionsView.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import SwiftUI

struct TransactionsView: View {
    @State private var transactions: [Transaction] = []
    @State private var userBalance: UserBalance?
    @State private var isLoading = true
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Balance Summary Card
                    if let balance = userBalance {
                        BalanceSummaryCard(balance: balance)
                    }
                    
                    // Transactions List
                    if isLoading {
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .bulkSharePrimary))
                                .scaleEffect(1.2)
                            Text("Loading transactions...")
                                .font(.subheadline)
                                .foregroundColor(.bulkShareTextMedium)
                                .padding(.top)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if transactions.isEmpty {
                        EmptyTransactionsView()
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Recent Transactions")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.bulkShareTextDark)
                                .padding(.horizontal)
                            
                            LazyVStack(spacing: 12) {
                                ForEach(transactions) { transaction in
                                    TransactionCard(
                                        transaction: transaction,
                                        currentUserId: FirebaseManager.shared.currentUser?.id ?? "",
                                        onMarkAsPaid: { markAsPaid(transaction) }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding()
            }
            .background(Color.bulkShareBackground.ignoresSafeArea())
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.large)
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                loadTransactions()
            }
            .refreshable {
                loadTransactions()
            }
        }
    }
    
    private func loadTransactions() {
        guard let currentUser = FirebaseManager.shared.currentUser else { return }
        
        isLoading = true
        
        Task {
            do {
                let userTransactions = try await FirebaseManager.shared.getUserTransactions(userId: currentUser.id)
                let balance = try await FirebaseManager.shared.getUserBalance(userId: currentUser.id)
                
                DispatchQueue.main.async {
                    self.transactions = userTransactions
                    self.userBalance = balance
                    self.isLoading = false
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.showAlert(
                        title: "Error",
                        message: "Failed to load transactions: \(error.localizedDescription)"
                    )
                }
            }
        }
    }
    
    private func markAsPaid(_ transaction: Transaction) {
        Task {
            do {
                try await FirebaseManager.shared.markTransactionAsPaid(transaction.id)
                
                DispatchQueue.main.async {
                    self.loadTransactions() // Refresh data
                    self.showAlert(
                        title: "Payment Recorded",
                        message: "Transaction marked as paid successfully."
                    )
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.showAlert(
                        title: "Error",
                        message: "Failed to update payment status: \(error.localizedDescription)"
                    )
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

struct BalanceSummaryCard: View {
    let balance: UserBalance
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("💰")
                    .font(.title2)
                    .frame(width: 40, height: 40)
                    .background(Color.bulkSharePrimary.opacity(0.1))
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Balance Summary")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.bulkShareTextDark)
                    
                    Text(balance.balanceDescription)
                        .font(.subheadline)
                        .foregroundColor(.bulkShareTextMedium)
                }
                
                Spacer()
            }
            
            HStack {
                // Money Owed
                VStack(spacing: 4) {
                    Text("You Owe")
                        .font(.caption)
                        .foregroundColor(.bulkShareTextMedium)
                    
                    Text("$\(balance.totalOwed, specifier: "%.2f")")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
                
                // Money Owed To You
                VStack(spacing: 4) {
                    Text("Owed to You")
                        .font(.caption)
                        .foregroundColor(.bulkShareTextMedium)
                    
                    Text("$\(balance.totalOwedTo, specifier: "%.2f")")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.bulkShareSuccess)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.bulkShareSuccess.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

struct TransactionCard: View {
    let transaction: Transaction
    let currentUserId: String
    let onMarkAsPaid: () -> Void
    
    @State private var otherUserName: String = "Loading..."
    
    var isOwing: Bool {
        transaction.fromUserId == currentUserId
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Transaction type indicator
                Image(systemName: isOwing ? "arrow.up.circle" : "arrow.down.circle")
                    .foregroundColor(isOwing ? .red : .bulkShareSuccess)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(isOwing ? "You owe \(otherUserName)" : "\(otherUserName) owes you")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.bulkShareTextDark)
                    
                    Text(transaction.createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.bulkShareTextMedium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("$\(transaction.amount, specifier: "%.2f")")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(isOwing ? .red : .bulkShareSuccess)
                    
                    TransactionStatusBadge(status: transaction.status)
                }
            }
            
            // Action buttons
            if transaction.status == .pending {
                HStack {
                    if isOwing {
                        Button("Mark as Paid") {
                            onMarkAsPaid()
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Color.bulkSharePrimary)
                        .cornerRadius(8)
                    } else {
                        Text("Waiting for payment...")
                            .font(.caption)
                            .foregroundColor(.bulkShareTextMedium)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(Color.bulkShareBackground)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .onAppear {
            loadOtherUserName()
        }
    }
    
    private func loadOtherUserName() {
        let otherUserId = isOwing ? transaction.toUserId : transaction.fromUserId
        
        Task {
            do {
                let user = try await FirebaseManager.shared.getUser(uid: otherUserId)
                DispatchQueue.main.async {
                    self.otherUserName = user.name
                }
            } catch {
                DispatchQueue.main.async {
                    self.otherUserName = "Unknown User"
                }
            }
        }
    }
}

struct TransactionStatusBadge: View {
    let status: TransactionStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(hex: status.color))
            .cornerRadius(6)
    }
}

struct EmptyTransactionsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard")
                .font(.system(size: 60))
                .foregroundColor(.bulkShareTextLight)
            
            Text("No Transactions")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.bulkShareTextMedium)
            
            Text("Your payment history will appear here when you start sharing bulk purchases.")
                .font(.subheadline)
                .foregroundColor(.bulkShareTextLight)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}


#Preview {
    TransactionsView()
}