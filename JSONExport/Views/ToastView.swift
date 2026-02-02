//
//  ToastView.swift
//  JSONExport
//
//  Created by Claude on 2026/2/2.
//  Copyright © 2026. All rights reserved.
//

import SwiftUI


struct ToastView: View {

    let message: String

    var body: some View {
        Text(self.message)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.75))
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}


struct ToastModifier: ViewModifier {

    @Binding var isPresented: Bool

    let message: String

    let duration: Double

    func body(content: Content) -> some View {
        ZStack {
            content

            if self.isPresented {
                VStack {
                    Spacer()

                    ToastView(message: self.message)
                        .padding(.bottom, 50)
                        .transition(.opacity.combined(with: .scale))
                }
                .animation(.easeInOut(duration: 0.3), value: self.isPresented)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + self.duration) {
                        self.isPresented = false
                    }
                }
            }
        }
    }
}


extension View {

    func toast(
        isPresented: Binding<Bool>,
        message: String,
        duration: Double = 2.0
    ) -> some View {
        self.modifier(
            ToastModifier(
                isPresented: isPresented,
                message: message,
                duration: duration
            )
        )
    }
}
