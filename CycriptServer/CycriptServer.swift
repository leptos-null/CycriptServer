//
//  CycriptServer.swift
//  CycriptServer
//
//  Created by Leptos on 2/4/23.
//

import Foundation
import Cycript

final class CycriptServer: ObservableObject {
    static let shared = CycriptServer()
    
    let port: Int16 = 31075
    private(set) var isRunning = false
    
    func run() {
        guard !isRunning else { return }
        CYListenServer(port)
        isRunning = true
    }
}
