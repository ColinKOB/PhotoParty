import Foundation
import MultipeerConnectivity

protocol MultipeerServiceDelegate: AnyObject {
    func didReceiveGameState(_ game: Game)
    func didReceiveSubmission(_ submission: Submission)
    func didReceiveVote(from playerId: UUID, for submissionId: UUID)
    func playerDidConnect(_ player: Player)
    func playerDidDisconnect(_ playerId: UUID)
    func didReceiveError(_ error: MultipeerError)
}

enum MultipeerError: Error {
    case notConnected
    case encodingFailed
    case decodingFailed
    case sessionFailed
    case timeout
}

class MultipeerService: NSObject, ObservableObject {
    static let serviceType = "photoparty"

    private var peerID: MCPeerID!
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    @Published var isHosting = false
    @Published var isBrowsing = false
    @Published var connectedPeers: [MCPeerID] = []
    @Published var availableGames: [DiscoveredGame] = []

    weak var delegate: MultipeerServiceDelegate?

    private var localPlayer: Player?
    private var gameCode: String?
    private var peerToPlayerMap: [MCPeerID: UUID] = [:]

    override init() {
        super.init()
    }

    func setup(playerName: String, playerId: UUID) {
        peerID = MCPeerID(displayName: "\(playerName)|\(playerId.uuidString)")
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
    }

    // MARK: - Hosting

    func startHosting(gameCode: String, player: Player) {
        self.gameCode = gameCode
        self.localPlayer = player

        let discoveryInfo = [
            "gameCode": gameCode,
            "hostName": player.name,
            "hostEmoji": player.avatarEmoji
        ]

        advertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: discoveryInfo,
            serviceType: MultipeerService.serviceType
        )
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        isHosting = true
        print("Started hosting game: \(gameCode)")
    }

    func stopHosting() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        isHosting = false
        print("Stopped hosting")
    }

    // MARK: - Browsing

    func startBrowsing() {
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: MultipeerService.serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        isBrowsing = true
        availableGames.removeAll()
        print("Started browsing for games")
    }

    func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        browser = nil
        isBrowsing = false
        print("Stopped browsing")
    }

    func joinGame(_ game: DiscoveredGame, player: Player) {
        self.localPlayer = player
        browser?.invitePeer(game.peerID, to: session, withContext: nil, timeout: 30)
        print("Invited to join game: \(game.gameCode)")
    }

    // MARK: - Communication

    func sendGameState(_ game: Game) {
        let message = GameMessage.gameState(game)
        send(message)
    }

    func sendSubmission(_ submission: Submission) {
        let message = GameMessage.submission(submission)
        send(message)
    }

    func sendVote(from playerId: UUID, for submissionId: UUID) {
        let message = GameMessage.vote(playerId: playerId, submissionId: submissionId)
        send(message)
    }

    func sendPlayerInfo(_ player: Player) {
        let message = GameMessage.playerInfo(player)
        send(message)
    }

    private func send(_ message: GameMessage) {
        guard !session.connectedPeers.isEmpty else {
            print("No connected peers to send to")
            return
        }

        do {
            let data = try JSONEncoder().encode(message)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            print("Sent message: \(message.type)")
        } catch {
            print("Failed to send message: \(error)")
            delegate?.didReceiveError(.encodingFailed)
        }
    }

    func disconnect() {
        session.disconnect()
        stopHosting()
        stopBrowsing()
        connectedPeers.removeAll()
        peerToPlayerMap.removeAll()
    }
}

// MARK: - MCSessionDelegate

extension MultipeerService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async { [weak self] in
            switch state {
            case .connected:
                print("Peer connected: \(peerID.displayName)")
                self?.connectedPeers = session.connectedPeers

                // Parse player info from peer display name
                let components = peerID.displayName.split(separator: "|")
                if components.count == 2,
                   let playerIdString = components.last,
                   let playerId = UUID(uuidString: String(playerIdString)) {
                    let playerName = String(components.first ?? "Player")
                    self?.peerToPlayerMap[peerID] = playerId

                    // If we're the host, send our game state to the new peer
                    if self?.isHosting == true, let player = self?.localPlayer {
                        self?.sendPlayerInfo(player)
                    }
                }

                AudioService.shared.playSound(.playerJoin)
                AudioService.shared.playHaptic(.success)

            case .notConnected:
                print("Peer disconnected: \(peerID.displayName)")
                self?.connectedPeers = session.connectedPeers

                if let playerId = self?.peerToPlayerMap[peerID] {
                    self?.delegate?.playerDidDisconnect(playerId)
                    self?.peerToPlayerMap.removeValue(forKey: peerID)
                }

                AudioService.shared.playSound(.playerLeave)

            case .connecting:
                print("Connecting to peer: \(peerID.displayName)")

            @unknown default:
                print("Unknown peer state")
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            let message = try JSONDecoder().decode(GameMessage.self, from: data)
            print("Received message: \(message.type)")

            DispatchQueue.main.async { [weak self] in
                switch message {
                case .gameState(let game):
                    self?.delegate?.didReceiveGameState(game)

                case .submission(let submission):
                    self?.delegate?.didReceiveSubmission(submission)

                case .vote(let playerId, let submissionId):
                    self?.delegate?.didReceiveVote(from: playerId, for: submissionId)

                case .playerInfo(let player):
                    self?.peerToPlayerMap[peerID] = player.id
                    self?.delegate?.playerDidConnect(player)
                }
            }
        } catch {
            print("Failed to decode message: \(error)")
            delegate?.didReceiveError(.decodingFailed)
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Not used
    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Not used
    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Not used
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension MultipeerService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("Received invitation from: \(peerID.displayName)")
        // Auto-accept invitations
        invitationHandler(true, session)
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("Failed to start advertising: \(error)")
        delegate?.didReceiveError(.sessionFailed)
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension MultipeerService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        print("Found peer: \(peerID.displayName), info: \(info ?? [:])")

        guard let info = info,
              let gameCode = info["gameCode"],
              let hostName = info["hostName"] else {
            return
        }

        let hostEmoji = info["hostEmoji"] ?? "😀"

        DispatchQueue.main.async { [weak self] in
            let game = DiscoveredGame(
                peerID: peerID,
                gameCode: gameCode,
                hostName: hostName,
                hostEmoji: hostEmoji
            )

            if !(self?.availableGames.contains(where: { $0.peerID == peerID }) ?? false) {
                self?.availableGames.append(game)
            }
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Lost peer: \(peerID.displayName)")

        DispatchQueue.main.async { [weak self] in
            self?.availableGames.removeAll { $0.peerID == peerID }
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("Failed to start browsing: \(error)")
        delegate?.didReceiveError(.sessionFailed)
    }
}

// MARK: - Supporting Types

struct DiscoveredGame: Identifiable {
    let id = UUID()
    let peerID: MCPeerID
    let gameCode: String
    let hostName: String
    let hostEmoji: String
}

enum GameMessage: Codable {
    case gameState(Game)
    case submission(Submission)
    case vote(playerId: UUID, submissionId: UUID)
    case playerInfo(Player)

    var type: String {
        switch self {
        case .gameState: return "gameState"
        case .submission: return "submission"
        case .vote: return "vote"
        case .playerInfo: return "playerInfo"
        }
    }
}
