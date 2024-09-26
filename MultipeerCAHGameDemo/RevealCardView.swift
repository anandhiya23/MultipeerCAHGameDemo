//
//  RevealCardView.swift
//  MultipeerCAHGameDemo
//
//  Created by Bintang Anandhiya on 24/09/24.
//

import SwiftUI

struct FlipCardView: View {
    let id: Int
    let word: String
    let selectedId: Binding<Int>
    
    @State var flip = 0.0
    @State var flipped = false
    var body: some View {
        ZStack {
            if (flipped){
                Text(word)
                    .font(.title)
                    .foregroundColor(.black)
                    .bold()
                    .multilineTextAlignment(.center)
                    .scaleEffect(CGSize(width: 1.0, height: -1.0))
                    .padding()
                    .frame(width: 300, height: 150)
                    .background{
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedId.wrappedValue != id ? .white : .green)
                            .stroke(.black, lineWidth: 3)
                    }
            }else{
                Text("DJAWIR \(Image(systemName: "questionmark.bubble"))")
                    .font(.largeTitle)
                    .foregroundColor(.black)
                    .bold()
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(width: 300, height: 150)
                    .background{
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.white)
                            .stroke(.black, lineWidth: 3)
                    }
                
            }

        }
        .rotation3DEffect(.degrees(flip), axis: (x: 1, y: 0, z: 0))
        .onTapGesture {
            if flipped{
//                withAnimation(.easeIn(duration: 0.2)){
//                    flip = 90
//                }completion: {
//                    flipped = false
//                    withAnimation {
//                        flip = 0
//                    }
//                }
            }else{
                withAnimation(.easeIn(duration: 0.2)){
                    flip = 90
                }completion: {
                    flipped = true
                    withAnimation {
                        flip = 180
                    }
                }
            }
        }
    }
}

struct RevealCardView: View {
    @EnvironmentObject var gameManager: CAHGameManager
    @EnvironmentObject var multipeerManager: GameMultipeerSession
    
    @State var hasFlipped: [Bool] = []
    @State var hasFlippedCount = 0
    
    @State var scrollheight = 0.0
    @State var selectedId = -1
    @State var pickingWinner = false
    
    @State var disableNextButton = true
    @State var bigbrainUIIndexDeduction = 0
    
    @State var tempPickedWinner = "Bintang?"
    
    var body: some View {
        VStack(spacing: 20){
            ZStack {
                Text(gameManager.selectedQuestion.1)
                    .font(.title3)
                    .foregroundColor(.white)
                    .bold()
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(width: 300, height: 150)
            .background{
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.black,lineWidth: 5)
                    .fill(.black)
            }
            
            if(gameManager.players[gameManager.judgeId] == multipeerManager.myPeerID.displayName){
                HStack{
                    Text(disableNextButton ? "Reveal \(hasFlippedCount)/\(hasFlipped.count)" : "Pick Winner")
                        .font(.title)
                    Spacer()
                    Button("   Next   "){
                        multipeerManager.send(gameAction: GameAction(displayName: multipeerManager.myPeerID.displayName, action: "judgePickWinner", winner: tempPickedWinner))
                        gameManager.winner = tempPickedWinner
                        gameManager.progressGame()
                    }
                    .buttonStyle(GrowingButton())
                    .font(.title2)
                    .disabled(disableNextButton)
                }
                .padding(.horizontal,45)
            }
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 15) {
                    
                    ForEach(0..<gameManager.playerPickedCards.count, id: \.self) { index in
                        let offset = Double(index)*150
                        let stay = min(offset-scrollheight, 0)
                        
                        FlipCardView(id: index, word: gameManager.answers[gameManager.playerPickedCards[index].1], selectedId: $selectedId)
                        .transformEffect(.init(translationX: 0, y: -stay))
                        .onAppear{
                            hasFlipped.append(false)
                        }
                        .simultaneousGesture(TapGesture().onEnded({ _ in
                            selectedId = index
                            if !hasFlipped[index]{
                                hasFlipped[index] = true
                                hasFlippedCount += 1
                                
                                if hasFlippedCount >= gameManager.playerPickedCards.count{
                                    disableNextButton = false
                                }
                            }
                            
                            tempPickedWinner = gameManager.playerPickedCards[index].0
                        }))
                    }
                }
                .background(GeometryReader {
                    Color.clear.preference(key: ViewOffsetKey.self,
                                           value: -$0.frame(in: .named("scroll")).origin.y)
                })
                .onPreferenceChange(ViewOffsetKey.self) { scrollheight = $0}
                .frame(width: 600)
                
            }
            .coordinateSpace(name: "scroll")
            .scrollClipDisabled()
            .defaultScrollAnchor(.bottom)
        }
        .onChange(of: multipeerManager.receivedGameAction) { oldValue, newValue in
            if(newValue.action == "judgePickWinner"){
                let tempCardId = newValue.cardId ?? 0
                gameManager.selectedQuestion = (tempCardId, gameManager.questions[tempCardId])
                gameManager.winner = newValue.winner ?? "ERROR"
                gameManager.progressGame()
            }
        }
    }
}

//#Preview {
//    RevealCardView()
//}
