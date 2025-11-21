//
//  LoudnessMatch.swift
//  Tinnitus Capstone
//
//  Created by Anika Patel on 11/10/25.
//

/*
import SwiftUI

struct LoudnessMatchView: View {
    @State private var loudness: Double = 0.5 //creating a variable for Loudness
    
    var body: some View {
        
        //MENU ICON
        VStack (alignment: .leading, spacing: 24){
            HStack { //this makes a horizontal stack from L to R
                Image(systemName: "line.3.horizontal") //menu icon
                    .font(.title3) // icon size- making larger
                Spacer() //pushes everything to the left
                
            }
            .padding(.horizontal) //adds L & R padding so it is not stuck to side
            .padding(.top) //^^ but from the top
            
            //TITLE
            Text("LOUDNESS MATCHING")
                .font(.system(size:24, weight: .bold))
                //.padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .center)
            
            Spacer()
                
            //SLIDER
                
            Slider(value: $loudness, in: 0...1) //creates standard horizontal slider, this ties value from slider to var loudness
                .rotationEffect(.degrees(-90)) //rotates to make vertical
                .frame(height: 320) //height of slider
                .padding(.leading, 20)
            Spacer()
        }
        //BACKGROUND
        .background(Color.white.ignoresSafeArea()) //sets background to white
        
    }
    

}

#Preview{
    LoudnessMatchView()
}
*/

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

