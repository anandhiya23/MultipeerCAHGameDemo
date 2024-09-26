//
//  CAHGameManager.swift
//  MultipeerCAHGameDemo
//
//  Created by Bintang Anandhiya on 24/09/24.
//

import Foundation
import MultipeerConnectivity

class CAHGameManager: ObservableObject{
    let questions = [
        "Apa sing paling mbebayani nalika lelungan nganggo bis?",
        "Rahasia suksesku mung...",
        "Apa sing ndadekake pesta iki dadi bener-bener spektakuler?",
        "Solusi sing paling gampang kanggo kabeh masalah uripku yaiku...",
        "Aku ora bakal lali nalika aku ndelok...",
        "Apa sing sejatine dadi kepinginan paling gedhe ing uripku?",
        "Ngrungokake simfoni musik lan...",
        "Rapat keluarga bakal dadi lucu banget yen ditambahake...",
        "Aja lali nyimpen...",
        "Wong Jawa kuwi terkenal amarga...",
        "Apa sing dadi alesan utama wong-wong padha ketawa ing pesta iki?",
        "Kegiyatan rahasia sing daktindakake nalika ora ana wong liya yaiku...",
        "Wong tuwaku ora ngerti yen aku nyimpen...",
        "Nalika umurku 10 taun, aku ora bakal mbayangake yen aku bakal nindakake...",
        "Apa sing biasane ndadekake wong-wong Jowo kuwi ora isa diremehake?",
        "Senjata rahasia kanggo menang perang mental yaiku...",
        "Ngapa pacarku putus karo aku? Amarga...",
        "Nalika aku mangan siang, aku nemokake...",
        "Apa sing ndadekake aku dadi juara ing kompetisi dadakan iki?",
        "Duwe kanca sing duwe bakat aneh yaiku kaya...",
        "Wong-wong bakal ora percoyo yen aku ngaku yen aku tau ngalami...",
        "Aku wis ngentekake seprapat gajiku kanggo...",
        "Sambunganku karo bos dadi aneh nalika dheweke ngucap...",
        "Aku ndelok dheweke nganggo kemeja abang lan langsung eling karo...",
        "Iki rahasia ngapa aku ora seneng ketemu karo tetangga: ...",
        "Aku pancen ngimpi bisa nguripake uripku kaya...",
        "Apa sing paling tak enteni yen mlebu ing donya gaib?",
        "Rasa isin paling gedheku yaiku nalika aku...",
        "Aku mutusake lunga saka acara iki amarga ana...",
        "Keluargaku mung percaya yen aku bisa dadi wong sukses yen aku...",
        "Apa sing nggawe kabeh rencanaku kacau balau minggu iki?",
        "Solusi kanggo stress yaiku...",
        "Aku tresna sampean karena sampean..."
        ]
    let answers = [
        "Bayi sing jogetan ndangdut ing YouTube.",
        "Numpak becak karo kuda jaran ing mburi.",
        "Mangan rujak nganggo sendok es krim.",
        "Klelep ing kolam renang ing jero 50 cm.",
        "Ngombe alkohol.",
        "Gamelan karo beats EDM.",
        "Duwe piaraan kadal sing iso ngguyu.",
        "Mulyono",
        "Cendhak",
        "Adus karo mbokmu",
        "Gudeg YuJum",
        "Wong tuwo",
        "Raja jawa",
        "Bojo anyar",
        "Rakyat Melarat",
        "Ngambung Asu",
        "Nglangkahi Telek",
        "Kaesang",
        "Ora duwe duit",
        "Joko Widodo",
        "Nyekar ing tengah wengi",
        "Pupus tresno",
        "Tiba ing bolongan",
        "Mangan telek luwak",
        "Megawati",
        "Tempek teles",
        "Bokong gudhel",
        "Kethek rabies",
        "Nglaliake mantan",
        "Peli",
        "Motornya mogok tengah dalan.",
        "Cucian numpuk sak gunung.",
        "Lali nganggo masker.",
        "Ketemu mantan nang pasar.",
        "Asu",
        "Jancok",
        "Kathok jero",
        "Lara tresna",
        "Kunti bogel kemasan sachet",
        "Montor mabur",
        "Bubur sing dienggo udhu",
        "Ngombe wedang jahe karo Mbah Kakung",
        "Kanca-kanca sing ora tau mulih.",
        "Sate wedhus",
        "Kecanthol meja",
        "Angguk-angguk ngerti, padahal ora.",
        "Jogetan ala ndangdut.",
        "Mangan bakso gratis.",
        "Turu tekan siang.",
        "Ngopi karo rokok kretek.",
        "Kerokan sak lemu-lemune.",
        "Klelep ing empang.",
        "Omah bocor pas udan.",
        "Ngising neng sawah terus ndelok ana sing liwat.",
        "Kedanan nonton video jorok.",
        "Ketok bokong pas lagi yoga.",
        "Manuk e ketok gondal gandul koyo lele",
        "Manuk sing dowo",
        "Selingkuh karo bojone kanca",
        "Golek jodoh online.",
        "Malam minggu karo kanca.",
        "Piknik ing alas.",
        "Sabung ayam",
        "Aku ra kethok"
    ]
    @Published var phase = -1
    @Published var players: [String] = ["ERROR"]
    @Published var questionOptions: [(Int, String)] = [(0,"ERROR")]
    @Published var selectedQuestion: (Int, String) = (0,"ERROR")
    @Published var judgeId = -1
    @Published var myAnswerCards: [Int] = [0,1,2,3]
    
    @Published var playerPickedCards: [(String,Int)] = []
    @Published var playerDonePicking: Int = 0
    
    @Published var winner = "ERROR"

    init() {
        questionOptions = shuffleGet4Questions()
        myAnswerCards = shuffleGet10Answers()
    }

    
    func progressGame(){
        if phase == -1{
            phase = 0
        }else if phase == 0{
            phase += 1
        }else if phase == 1{
            phase += 1
        }else if phase == 2{
            phase += 1
        }else if phase == 3{
            phase = 0
            playerPickedCards = []
            playerDonePicking = 0
            winner = ""
            judgeId = (judgeId + 1) % players.count
        }
    }
    
    func checkProgressToPickWinner() -> Bool{
        if(playerDonePicking >= (players.count - 1)){
            return true
        }else{
            return false
        }
    }
    
    func shuffleGet4Questions() -> [(Int, String)]{
        let shuffledQuestions = questions.enumerated().shuffled()
        return Array(shuffledQuestions.prefix(4))
    }
    
    func shuffleGet10Answers() -> [Int]{
        let shuffledAnswers = answers.enumerated().shuffled()
        return Array(shuffledAnswers.prefix(10).map{$0.0})
    }
}
