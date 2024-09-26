import SwiftUI


struct CardView: View {
    let id: Int
    let word: String
    let selectedId: Binding<Int>
    let trigger: Binding<Bool>
    
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
                    .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
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
        .onChange(of: trigger.wrappedValue, { oldValue, newValue in
            if flipped{
                flipped = false
                flip = 0
            }else{
                withAnimation(.easeIn(duration: 0.2).delay(Double(id)*0.1)){
                    flip = 90
                }completion: {
                    flipped = true
                    withAnimation {
                        flip = 180
                    }
                }
            }
        })
    }
}

struct PlayerPickView: View {
    @EnvironmentObject var gameManager: CAHGameManager
    @EnvironmentObject var multipeerManager: GameMultipeerSession
    
    @State var scrollheight = 0.0
    @State var selectedId = 0
    
    @State var holdProgress = 0.0
    @State var isHolding = false
    @State var holdCompleted = false
    
    @State var flipTrigger = false
    
    @State var tempPickedCard = 0
    
    @State private var workItem: DispatchWorkItem?
    
    @State var waitingForOthers = false
    
    var body: some View {
        
        VStack(spacing: 20){
            if (gameManager.players[gameManager.judgeId] != multipeerManager.myPeerID.displayName && waitingForOthers == false){
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
                
                HStack{
                    Text(flipTrigger ? "Pilih..." : "\(Image(systemName: "person.fill")) \(multipeerManager.myPeerID.displayName)")
                        .font(.title)
                    Spacer()
                    Button(flipTrigger ? "   Kunci   " : "    Buka    "){
                        
                    }
                    .simultaneousGesture(TapGesture().onEnded({ _ in
                        if flipTrigger{
                            
                            waitingForOthers = true
                            multipeerManager.send(gameAction: GameAction(displayName: multipeerManager.session.myPeerID.displayName, action: "playerPick", cardId: tempPickedCard))
                            
                            gameManager.playerPickedCards.append((multipeerManager.session.myPeerID.displayName, tempPickedCard))
                            gameManager.playerDonePicking += 1
                            
                            if (gameManager.checkProgressToPickWinner()){
                                gameManager.progressGame()
                            }
                            
                            flipTrigger = false
                            selectedId = 0
                        }
                    }))
                    .simultaneousGesture(LongPressGesture(minimumDuration:1)
                    .onChanged({ bool in
                        if !flipTrigger{
                            isHolding = true
                            holdProgress = 15
                            workItem = DispatchWorkItem {
                                withAnimation(.linear(duration: 1)) {
                                    holdProgress = 158
                                }
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now(), execute: workItem!)
                        }
                    })
                    .onEnded({ bool in
                        if !flipTrigger{
                            isHolding = false
                            holdProgress = 0
                            flipTrigger = true
                        }
                    }))
                    .simultaneousGesture(DragGesture(minimumDistance: 0)
                    .onChanged({ val in
                        if abs(val.translation.width) > 120 || abs(val.translation.height) > 65{
                            if isHolding{
                                workItem?.cancel()
                                holdProgress = 0
                            }
                            isHolding = false
                        }
                    })
                    .onEnded { _ in
                        if isHolding{
                            workItem?.cancel()
                            holdProgress = 0
                        }
                        isHolding = false
                    })
                    .buttonStyle(GrowingButton())
                    .font(.title2)
                    .background(){
                        ZStack(){
                            Rectangle()
                                .fill(.green)
                                .frame(width: holdProgress)
                        }
                        .frame(width: 164,height: 85,alignment: .leading)
                        .clipShape(RoundedRectangle(cornerRadius: 50))
                    }
                    .disabled(waitingForOthers)
                }
                .padding(.horizontal,45)
                
                
                ScrollView(showsIndicators: false) {
                    
                    VStack(spacing: 15) {
                        ForEach(0..<gameManager.myAnswerCards.count, id: \.self) { index in
                            let offset = Double(index)*150
                            let stay = min(offset-scrollheight, 0)
                            
                            CardView(id: index, word: gameManager.answers[gameManager.myAnswerCards[index]], selectedId: $selectedId, trigger: $flipTrigger)
                                .transformEffect(.init(translationX: 0, y: -stay))
                                .simultaneousGesture(TapGesture().onEnded({ _ in
                                    selectedId = index
                                    tempPickedCard = gameManager.myAnswerCards[index]
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
            }else{
                Text("\(Image(systemName: "person.fill"))  Waiting for others")
            }
        }
        .onChange(of: multipeerManager.receivedGameAction) { oldValue, newValue in
            if(newValue.action == "playerPick"){
                let tempCardId = newValue.cardId ?? 0
                gameManager.playerPickedCards.append((newValue.displayName, tempCardId))
                gameManager.playerDonePicking += 1
                
                if (gameManager.checkProgressToPickWinner()){
                    gameManager.progressGame()
                }
            }
        }
    }
}
