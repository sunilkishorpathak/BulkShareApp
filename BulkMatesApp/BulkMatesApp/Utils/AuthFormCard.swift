//
//  AuthFormCard.swift
//  BulkShareApp
//
//  Created by Sunil Pathak on 9/27/25.
//


//
//  AuthFormCard.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import SwiftUI

struct AuthFormCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack {
            content
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct BulkShareTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(16)
            .background(Color.bulkShareBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.bulkShareTextLight.opacity(0.3), lineWidth: 1)
            )
    }
}

#Preview {
    AuthFormCard {
        VStack {
            Text("Sample Form Content")
            TextField("Email", text: .constant(""))
                .textFieldStyle(BulkShareTextFieldStyle())
        }
    }
    .padding()
    .background(Color.bulkSharePrimary)
}