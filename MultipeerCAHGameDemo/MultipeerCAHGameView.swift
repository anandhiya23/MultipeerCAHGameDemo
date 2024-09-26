//
//  MultipeerCAHGameView.swift
//  MultipeerCAHGameDemo
//
//  Created by Bintang Anandhiya on 24/09/24.
//

import SwiftUI

struct MultipeerCAHGameView: View {
    @State var rpsSession: GameMultipeerSession?
    @State var currentVieww: Int = 0
    @State var username = ""
    
    var body: some View {
        switch currentVieww {
        case 1:
            PairView()
                .environmentObject(rpsSession!)
                .environmentObject(CAHGameManager())
        default:
            VStack(spacing: 20){
                Spacer()
                
                Image(systemName: "doc.questionmark.fill")
                    .foregroundColor(.black)
                    .font(.system(size: 100))
                
                Text("Cah Mbanyol")
                    .fontWeight(.bold)
                    .font(.largeTitle)
                
                Text("Masukkan nama panggilan di\nbawah ini. Pilih sesuatu yang akan\ndikenalioleh teman-temanmu!")
                    .font(.caption)
                    .fontWeight(.regular)
                    .multilineTextAlignment(.center)
                
                TextField("Nama Panggilan", text: $username)
                    .padding([.horizontal], 75.0)
                    .padding(.bottom, 24)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Lanjut →") {
                    rpsSession = GameMultipeerSession(username: username)
                    currentVieww = 1
                }.buttonStyle(GrowingButton())
                
                Spacer()
            }
        }
    }
}

//#Preview {
//    MultipeerCAHGameView()
//        .environmentObject(GameMultipeerSession(username: "TEST"))
//}
