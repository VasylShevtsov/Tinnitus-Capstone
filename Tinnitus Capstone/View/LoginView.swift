//
//  Login.swift
//  Tinnitus Capstone
//
//  Created by Anika Patel on 11/10/25.
//

import SwiftUI // this is apples UI framework


struct LoginView: View {
    
    var body: some View{ //this describes what the screen looks like
        List{ //this creats a scrolling list. handles spacing and grouping
            Section(header: Text("Login").font(.title2).bold()){
                HStack{
                    Text("Name")
                    Spacer()
                    Text("your name here").foregroundColor(.secondary) //this creates the placeholder text
                    
                }
                
                HStack{
                    Text("Username")
                    Spacer()
                    Text("@username").foregroundColor(.secondary)
                }
                
                HStack{
                    Text("Email")
                    Spacer()
                    Text("name@domain.com").foregroundColor(.secondary)
                }
            }
            
        }
        
    }
}
