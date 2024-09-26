//
//  PickBlackCard.swift
//  MultipeerCAHGameDemo
//
//  Created by Bintang Anandhiya on 24/09/24.
//

import SwiftUI

struct BlackCardView: View {
    let word: String
    let color: Color
    let id: Int
    let selectedId: Binding<Int>
    
    @State var flip = 1.0
    @State var flipped = false
    @State var flipText = false
    var body: some View {
        ZStack {
            Text(word)
                .font(.title3)
                .foregroundColor(.white)
                .bold()
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(width: 300, height: 150)
        .background{
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white,lineWidth: 5)
                .fill(selectedId.wrappedValue != id ? .black : .purple)
        }
    }
}

struct PickBlackCardView: View {
    @EnvironmentObject var gameManager: CAHGameManager
    @EnvironmentObject var multipeerManager: GameMultipeerSession
    @State var scrollheight = 0.0
    @State var selectedId = 0
    @State var tempSelectedQuestion: (Int, String) = (0, "ERROR")
    
    var body: some View {
        
        VStack(spacing: 20){
            if(gameManager.players[gameManager.judgeId] == multipeerManager.myPeerID.displayName){
                HStack{
    //                let unametemp: String = gameManager.players[gameManager.currentPlayerId].name
                    Text("\(Image(systemName: "crown.fill"))  ")
                        .font(.title)
                    Spacer()
                    Button("     Next     "){
                        multipeerManager.send(gameAction: GameAction(displayName: multipeerManager.session.myPeerID.displayName, action: "judgePick", cardId: tempSelectedQuestion.0))
                        gameManager.selectedQuestion = tempSelectedQuestion
                        gameManager.progressGame()
                    }
                    .buttonStyle(GrowingButton())
                    .font(.title2)
                }
                .padding(.horizontal,45)
                
                
                ScrollView(showsIndicators: false) {
                    
                    VStack(spacing: 15) {
                        ForEach(0..<gameManager.questionOptions.count, id: \.self) { index in
                            let offset = Double(index)*150
                            let stay = min(offset-scrollheight, 0)
                            
                            BlackCardView(word: gameManager.questionOptions[index].1, color: Color.white,id: index, selectedId: $selectedId)
                                .transformEffect(.init(translationX: 0, y: -stay))
                                .simultaneousGesture(TapGesture().onEnded({ _ in
                                    selectedId = index
                                    tempSelectedQuestion = gameManager.questionOptions[index]
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
            }else{
                Text("\(Image(systemName: "crown.fill"))  The Judge is Picking")
            }
        }
        .onAppear{
            gameManager.selectedQuestion = gameManager.questionOptions[0]
        }
        .onChange(of: multipeerManager.receivedGameAction) { oldValue, newValue in
            if(newValue.action == "judgePick"){
                let tempCardId = newValue.cardId ?? 0
                gameManager.selectedQuestion = (tempCardId, gameManager.questions[tempCardId])
                gameManager.progressGame()
            }
        }
    }
}

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}
//
//#Preview {
//    PickBlackCardView()
//}
