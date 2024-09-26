//
//  RevealWinnerView.swift
//  MultipeerCAHGameDemo
//
//  Created by Bintang Anandhiya on 24/09/24.
//

import SwiftUI

struct RevealWinnerView: View {
    @EnvironmentObject var gameManager: CAHGameManager
    @EnvironmentObject var multipeerManager: GameMultipeerSession
    var body: some View {
        
        Color.green
            .ignoresSafeArea()
            .overlay{
                Button("   NEXT   "){
                    gameManager.progressGame()
                    multipeerManager.send(action: "restartGame")
                }
                .buttonStyle(GrowingButton())
                .position(x:200,y:700)
            }
            .overlay{
                VStack(spacing: 15){
                    Text("\(Image(systemName: "person.fill")) \(gameManager.winner)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("+1 Point")
                        .font(.title)
                }
            }
            .onChange(of: multipeerManager.receivedGameAction) { oldValue, newValue in
                if(newValue.action == "restartGame"){
                    gameManager.progressGame()
                }
            }
            
    }
}
