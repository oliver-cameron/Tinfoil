//
//  TinfoilApp.swift
//  Tinfoil
//
//  Created by Oliver Cameron on 20/9/2024.
//

import SwiftUI

@main
struct TinfoilApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: TinfoilDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
