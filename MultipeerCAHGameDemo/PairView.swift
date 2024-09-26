import SwiftUI
import os

struct GrowingButton: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 15)
            .padding(.horizontal, 20)
            .background(isEnabled ? .black : .gray)
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 1.1 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct PairView: View {
    @EnvironmentObject var gmSession: GameMultipeerSession
    @EnvironmentObject var gameManager: CAHGameManager
    private var logger = Logger()
    
    @State var tempPlayerOrder: [String] = []
        
    var body: some View {
        VStack{
            if gameManager.phase == -1{
                PairingView
            }else if gameManager.phase == 0{
                PickBlackCardView()
            }else if gameManager.phase == 1{
                PlayerPickView()
            }else if gameManager.phase == 2{
                RevealCardView()
            }else if gameManager.phase == 3{
                RevealWinnerView()
            }
        }
        .alert("Received invite from \(gmSession.recvdInviteFrom?.displayName ?? "ERR")", isPresented: $gmSession.recvdInvite) {
            Button("Accept Invite") {
                if (gmSession.invitationHandler != nil) {
                    gmSession.invitationHandler!(true, gmSession.session)
                    gmSession.previouslyDisconnectedHost = gmSession.recvdInviteFrom
                    gmSession.recvdInvite = false
                }
            }
            Button("Reject Invite") {
                if (gmSession.invitationHandler != nil) {
                    gmSession.invitationHandler!(false, nil)
                    gmSession.recvdInvite = false
                }
            }
        }
//        .overlay(alignment: .center){
//            Button("ForceAdvert"){
//                gmSession.serviceAdvertiser.stopAdvertisingPeer()
//                Task{
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
//                        gmSession.serviceAdvertiser.startAdvertisingPeer()
//                    })
//                }
////                logger.info("Officially connected to \(String(gmSession.session.connectedPeers.reduce("", {msg, ite in msg + ("," + ite.displayName)})))")
//            }
//            .buttonStyle(GrowingButton())
//        }
        .onChange(of: gmSession.receivedGameAction) { oldValue, newValue in
            let gameAction: GameAction = newValue
            if(gameAction.action == "keepUp"){
                gameManager.phase = gameAction.gamePhase ?? 0
            }
        }
    }
    
    var PairingView: some View{
        ScrollView {
            VStack{
                Spacer().padding(.bottom, 50)
                HStack(alignment: .center) {
                    Button{
                        tempPlayerOrder = gmSession.session.connectedPeers.map{$0.displayName}
                        tempPlayerOrder.append(gmSession.myPeerID.displayName)
                        gmSession.send(gameAction: GameAction(displayName: gmSession.myPeerID.displayName, action: "startGame", playerOrder: tempPlayerOrder))
                        gameManager.players = tempPlayerOrder
                        gameManager.judgeId = (gameManager.judgeId + 1) % gameManager.players.count
                        gameManager.progressGame()
                    }label: {
                        Image(systemName: "play.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40)
                    }
                }
                
                Button("Open Room") {
                    gmSession.openRoom()
                }
                .buttonStyle(GrowingButton())
                .disabled(gmSession.isOpeningRoom || gmSession.paired)
                
                VStack{
                    ForEach(gmSession.availablePeers, id: \.self) { peer in
                        Text("\(peer.displayName)")
                            .font(.title2)
                            .foregroundColor(.black)
                            .bold()
                            .multilineTextAlignment(.center)
                            .padding()
                            .frame(width: 300, height: 80)
                            .background{
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.white)
                                    .stroke(.black, lineWidth: 3)
                            }
                            .onTapGesture {
                                gmSession.serviceBrowser.invitePeer(peer, to: gmSession.session, withContext: nil, timeout: 30)
                            }
                    }
                }
            }
        }
        .onChange(of: gmSession.receivedGameAction) { oldValue, newValue in
            let gameAction: GameAction = newValue
            if(gameAction.action == "startGame"){
                gameManager.players = gameAction.playerOrder ?? ["ERROR"]
                gameManager.judgeId = (gameManager.judgeId + 1) % gameManager.players.count
                gameManager.progressGame()
            }
        }
    }
}

//#Preview {
//    PairView()
//        .environmentObject(GameMultipeerSession(username: "TEST"))
//}
