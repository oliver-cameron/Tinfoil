//
//  ContentView.swift
//  Tinfoil
//
//  Created by Oliver Cameron on 20/9/2024.
//

import SwiftUI
import WebKit
struct ContentView: View {
    @Binding var document: TinfoilDocument
    var body: some View {
        ZStack{
            ForEach(document.parseSVG(), id:\.id){unit in
                AnyView(unit)
            }
        }
    }
 
}

