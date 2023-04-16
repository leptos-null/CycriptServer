//
//  ContentView.swift
//  CycriptServer
//
//  Created by Leptos on 2/4/23.
//

import SwiftUI

struct ContentView: View {
    @State private var application: UIApplication = .shared
    @StateObject private var server: CycriptServer = .shared
    @StateObject private var ipMonitor = AddressMonitor()
    
    private func octets(for addr: in_addr) -> (UInt8, UInt8, UInt8, UInt8) {
        return (
            UInt8(truncatingIfNeeded: addr.s_addr >> (0 * 8)),
            UInt8(truncatingIfNeeded: addr.s_addr >> (1 * 8)),
            UInt8(truncatingIfNeeded: addr.s_addr >> (2 * 8)),
            UInt8(truncatingIfNeeded: addr.s_addr >> (3 * 8))
        )
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 12) {
                ForEach(ipMonitor.ipv4) { ipAddr in
                    AddressRow(hostOctets: octets(for: ipAddr), port: server.port)
                }
            }
            .animation(.default, value: ipMonitor.ipv4)
            .font(.system(.title2, design: .monospaced))
            .fixedSize()
            .onAppear(perform: server.run)
            
            Spacer()
            
            VStack(spacing: 12) {
                Toggle("Prevent Idle", isOn: $application.isIdleTimerDisabled)
                    .padding(.horizontal)
                    .frame(maxWidth: 448)
                
                Text("The application must remain in the foreground to evalute commands")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .font(.footnote)
            }
        }
        .padding()
    }
}

struct AddressRow: View {
    let hostOctets: (UInt8, UInt8, UInt8, UInt8)
    let port: Int16
    
    var body: some View {
        HStack {
            if #available(iOS 15.0, *) {
                addressText
                    .textSelection(.enabled)
            } else {
                addressText
            }
            
            Spacer(minLength: 8)
            
            Button {
                UIPasteboard.general.string = String(format: "%hhu.%hhu.%hhu.%hhu:%hd",
                                                     hostOctets.0, hostOctets.1, hostOctets.2, hostOctets.3, port)
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
                    .labelStyle(.iconOnly)
            }
            .padding(4)
            .hoverEffect()
        }
    }
    
    @ViewBuilder
    private var addressText: Text {
        hostText
        + Text(":").foregroundColor(.secondary)
        + portText
    }
    
    @ViewBuilder
    private var hostOctetSeparatorText: Text {
        Text(".")
            .foregroundColor(.secondary)
    }
    
    @ViewBuilder
    private var hostText: Text {
        Text(String(format: "%hhu", hostOctets.0))
        + hostOctetSeparatorText
        + Text(String(format: "%hhu", hostOctets.1))
        + hostOctetSeparatorText
        + Text(String(format: "%hhu", hostOctets.2))
        + hostOctetSeparatorText
        + Text(String(format: "%hhu", hostOctets.3))
    }
    
    @ViewBuilder
    private var portText: Text {
        Text(String(format: "%hd", port))
            .foregroundColor(.secondary)
    }
}

extension in_addr: Hashable {
    public static func == (lhs: in_addr, rhs: in_addr) -> Bool {
        lhs.s_addr == rhs.s_addr
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(s_addr)
    }
}

extension in_addr: Identifiable {
    public var id: Self { self }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
