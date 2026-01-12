//
//  LoudnessMatch.swift
//  Tinnitus Capstone
//
//  Created by Anika Patel on 11/10/25.
//

import SwiftUI

struct LoudnessMatchView: View {
    @State private var loudness: Double = 0.5

    var body: some View {

        GeometryReader { geo in     // <--- KEY FIX: lets us control exact placement
            VStack(alignment: .leading, spacing: 24) {

                // MENU ICON
                HStack {
                    Image(systemName: "line.3.horizontal")
                        .font(.title3)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)

                // TITLE (CENTERED)
                Text("LOUDNESS MATCHING")
                    .font(.system(size: 24, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .center)

                Spacer()   // pushes content downward

                // SLIDER POSITIONED IN LEFT THIRD, VERTICALLY CENTERED
                VStack {
                    Slider(value: $loudness, in: 0...1)
                        .rotationEffect(.degrees(-90))
                        .frame(height: 320)
                        .position(
                            x: geo.size.width / 6,       // left third (1/6 of width)
                            y: geo.size.height / 2       // vertical center
                        )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Spacer()   // extra space below
            }
            .background(Color.white.ignoresSafeArea())
        }
    }
}

#Preview {
    LoudnessMatchView()
}

