//
//  AddressMonitor.swift
//  CycriptServer
//
//  Created by Leptos on 2/4/23.
//

import Foundation
import Network

final class AddressMonitor: ObservableObject {
    @Published private(set) var ipv4: [in_addr]
    
    private let pathMonitor = NWPathMonitor()
    
    // thanks to https://stackoverflow.com/a/25627545
    private static func getIfAddresses() -> [in_addr] {
        // Get list of all interfaces on the local machine:
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0,
              let firstAddr = ifaddr else { return [] }
        
        let addresses: [in_addr] = sequence(first: firstAddr, next: \.pointee.ifa_next)
            .lazy
            .map(\.pointee)
            .filter { addrs in
                let flags = Int32(addrs.ifa_flags)
                guard (flags & IFF_UP)       != .zero, // is up
                      (flags & IFF_RUNNING)  != .zero, // is running
                      (flags & IFF_SIMPLEX)  != .zero, // is simplex
                      (flags & IFF_LOOPBACK) == .zero, // is not loopback
                      addrs.ifa_addr.pointee.sa_family == UInt8(AF_INET) // is IPv4
                else { return false}
                return true
            }
            .map { addrs in
                addrs.ifa_addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1, \.pointee.sin_addr)
            }
        
        freeifaddrs(ifaddr)
        return addresses
    }
    
    func refresh() {
        ipv4 = Self.getIfAddresses()
    }
    
    init() {
        // the code we want (for both the list and the change notification) is described in
        // https://developer.apple.com/library/archive/technotes/tn1145/_index.html#//apple_ref/doc/uid/DTS10002984-CH1-CALLINGALLIPS
        // however the functions are macOS only.
        // `NWPathMonitor` is good for most use-cases, however some events are not picked up.
        // for example, if a tunnel is opened to the device, `pathUpdateHandler` is not
        // called, however the device is now accessible by another address.
        
        ipv4 = Self.getIfAddresses()
        pathMonitor.pathUpdateHandler = { [weak self] path in
            self?.refresh()
        }
        pathMonitor.start(queue: .main)
    }
}
