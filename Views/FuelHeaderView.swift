//
//  FuelHeaderView.swift
//  Yanosik
//
//  Created by Liza on 22/03/2025.
//

import SwiftUI

struct FuelHeaderView: View {
    let current: Double
    let capacity: Double

    @State private var animatedProgress: Double = 0

    private var percent: Double {
        capacity == 0 ? 0 : current / capacity
    }

    private var progressColor: Color {
        switch percent {
        case 0..<0.16: return .red
        case 0.16..<0.5: return .yellow
        default: return .green
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
                    .frame(height: 100)
                    .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)

                VStack(spacing: 12) {
                    Text("Stan baku")
                        .font(.headline)
                        .foregroundColor(.primary)

                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.systemGray5))
                            .frame(height: 20)

                        Capsule()
                            .fill(progressColor)
                            .frame(width: CGFloat(animatedProgress) * UIScreen.main.bounds.width * 0.8, height: 20)
                            .animation(.easeOut(duration: 1.0), value: animatedProgress)
                    }
                    .padding(.horizontal)

                    Text("\(Int(current))/\(Int(capacity)) L")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            .padding(.top, 10)

            Text("Historia tankowania")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
        }
        .background(Color(uiColor: .systemBackground))
        .onAppear {
            animatedProgress = percent
        }
    }
}

#Preview {
    FuelHeaderView(current: 25, capacity: 60)
}
