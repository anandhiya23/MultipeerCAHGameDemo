import MultipeerConnectivity
import os

class GameAction: Codable, Equatable{
    var displayName: String
    var action: String
    var cardId: Int?
    var playerOrder: [String]?
    var winner: String?
    var gamePhase: Int?
    
    init(displayName: String, action: String, cardId: Int? = nil, playerOrder: [String]? = nil, winner: String? = nil, gamePhase: Int? = nil) {
        self.displayName = displayName
        self.action = action
        self.cardId = cardId
        self.playerOrder = playerOrder
        self.winner = winner
        self.gamePhase = gamePhase
    }
    
    static func == (lhs: GameAction, rhs: GameAction) -> Bool {
        lhs.displayName == rhs.displayName && lhs.action == rhs.action && lhs.cardId == rhs.cardId
    }
}

class GameMultipeerSession: NSObject, ObservableObject {
    private let serviceType = "bintang-service"
    @Published var myPeerID: MCPeerID
    
    public let serviceAdvertiser: MCNearbyServiceAdvertiser
    public let serviceBrowser: MCNearbyServiceBrowser
    public let session: MCSession
        
    private let log = Logger()
    
    @Published var availablePeers: [MCPeerID] = []
    @Published var receivedGameAction: GameAction = GameAction(displayName: "self", action: "noAction")
    @Published var recvdInvite: Bool = false
    @Published var recvdInviteFrom: MCPeerID? = nil
    @Published var paired: Bool = false
    @Published var invitationHandler: ((Bool, MCSession?) -> Void)?
    
    @Published var isOpeningRoom: Bool = false
    
    @Published var gamePhaseTEMP: Int = 0
    
    @Published var previouslyDisconnectedHost: MCPeerID?
    @Published var previouslyDisconnectedPeers: [MCPeerID] = []
    
    init(username: String) {
        let peerID = MCPeerID(displayName: username)
        self.myPeerID = peerID
        
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        serviceBrowser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        super.init()
        
        session.delegate = self
        serviceAdvertiser.delegate = self
        serviceBrowser.delegate = self
                
        serviceAdvertiser.startAdvertisingPeer()
    }
    
    deinit {
        serviceAdvertiser.stopAdvertisingPeer()
        serviceBrowser.stopBrowsingForPeers()
    }
    
    func openRoom(){
        isOpeningRoom = true
        serviceBrowser.startBrowsingForPeers()
        serviceAdvertiser.stopAdvertisingPeer()
    }
    
    func send(gameAction: GameAction) {
        if !session.connectedPeers.isEmpty {
            log.info("send GameAction: \(gameAction.action) to connected peers")
            do {
                let encoder = JSONEncoder()
                try session.send(encoder.encode(gameAction), toPeers: session.connectedPeers, with: .reliable)
            } catch {
                log.error("Error sending: \(String(describing: error))")
            }
        }
    }
    
    func send(action: String, cardId: Int? = nil) {
        let gameAction = GameAction(displayName: myPeerID.displayName, action: action, cardId: cardId)
        if !session.connectedPeers.isEmpty {
            log.info("send GameAction: \(gameAction.action) to connected peers")
            do {
                let encoder = JSONEncoder()
                try session.send(encoder.encode(gameAction), toPeers: session.connectedPeers, with: .reliable)
            } catch {
                log.error("Error sending: \(String(describing: error))")
            }
        }
    }
}

extension GameMultipeerSession: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        //TODO: Inform the user something went wrong and try again
        log.error("ServiceAdvertiser didNotStartAdvertisingPeer: \(String(describing: error))")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        log.info("didReceiveInvitationFromPeer \(peerID.displayName)")
        
        DispatchQueue.main.async {
//            if(peerID == self.previouslyDisconnectedHost){
//                //directly connects if from previously disconnected host
                invitationHandler(true, self.session)
//            }else{
//                //Tell PairView to show the invitation alert
//                self.recvdInvite = true
//                // Give PairView the peerID of the peer who invited us
//                self.recvdInviteFrom = peerID
//                // Give PairView the `invitationHandler` so it can accept/deny the invitation
//                self.invitationHandler = invitationHandler
//            }
        }
    }
}

extension GameMultipeerSession: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        //TODO: Tell the user something went wrong and try again
        log.error("ServiceBroser didNotStartBrowsingForPeers: \(String(describing: error))")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        
        // Add the peer to the list of available peers
        if(previouslyDisconnectedPeers.contains(peerID)){
            log.info("Host's ServiceBrowser found previous peer: \(peerID.displayName)")
            serviceBrowser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
        }else{
            log.info("Host's ServiceBrowser found new peer: \(peerID)")
        }
        
        DispatchQueue.main.async {
            self.availablePeers.append(peerID)
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        log.info("ServiceBrowser lost peer: \(peerID.displayName)")
        // Remove lost peer from list of available peers
        DispatchQueue.main.async {
            self.availablePeers.removeAll(where: {
                $0 == peerID
            })
        }
    }
}

extension GameMultipeerSession: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        log.info("peer \(peerID.displayName) didChangeState: \(state.rawValue)")
        
        switch state {
        case MCSessionState.notConnected:
            // Peer disconnected
            DispatchQueue.main.async {
                self.paired = false
            }
            // Peer disconnected, start accepting invitaions again
            if(isOpeningRoom){
                DispatchQueue.main.async {
                    self.previouslyDisconnectedPeers.append(peerID)
                }
            }else{
                log.info("In 5s re-advertising as: \(peerID.displayName)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1){
                    self.log.info("Re-advertising as: \(peerID.displayName)")
                    self.serviceAdvertiser.startAdvertisingPeer()
                }
            }
            break
        case MCSessionState.connected:
            // Peer connected
            DispatchQueue.main.async{
                self.paired = true
            }
            
            if(self.isOpeningRoom && self.previouslyDisconnectedPeers.contains(peerID)){
                do {
                    let encoder = JSONEncoder()
                    try session.send(encoder.encode(GameAction(displayName: myPeerID.displayName, action: "keepUp", gamePhase: gamePhaseTEMP)), toPeers: [peerID], with: .reliable)
                } catch {
                    log.error("Error sending: \(String(describing: error))")
                }
            }
            // We are paired, stop accepting invitations
            serviceAdvertiser.stopAdvertisingPeer()
            break
        default:
            // Peer connecting or something else
            DispatchQueue.main.async {
                self.paired = false
            }
            break
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let decoder = JSONDecoder()
        if let gameAction = try? decoder.decode(GameAction.self, from: data){
            log.info("didReceive move \(gameAction.action)")
            // We received a move from the opponent, tell the GameView
            
            //Forward message to other peers connected
            if isOpeningRoom {
                if(session.connectedPeers.count > 1){
                    log.info("Room owner forward Move: \(gameAction.action) to all peers")
                    do {
                        let encoder = JSONEncoder()
                        try session.send(encoder.encode(gameAction), toPeers: session.connectedPeers.filter({ TargetPeerID in
                            TargetPeerID != peerID
                        }), with: .reliable)
//                      try session.send(encoder.encode(gameAction), toPeers: session.connectedPeers, with: .reliable)
                    } catch {
                        log.error("Error sending: \(String(describing: error))")
                    }
                }
            }
            
            //Set the recieved game action accordingly
            DispatchQueue.main.async {
                self.receivedGameAction = gameAction
            }
        } else {
            log.info("didReceive invalid value \(data.count) bytes")
        }
    }
    
    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        log.error("Receiving streams is not supported")
    }
    
    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        log.error("Receiving resources is not supported")
    }
    
    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        log.error("Receiving resources is not supported")
    }
    
    public func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        certificateHandler(true)
    }
}
