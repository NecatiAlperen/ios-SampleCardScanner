//
//  ScannerManager.swift
//  ios-SampleCardDetection
//
//  Created by Necati Alperen IŞIK on 11.08.2024.
//

import Foundation
import Vision
import CoreImage

final class ScannerManager {
    
    static let shared = ScannerManager()
    private init() {}
    
    private var detectedCardNumber: String?
    private var detectedSKT: String?
    private var detectedName: String?
    private var detectedIBAN: String?
    private var detectedCVV: String?
    
    // Ignore list
    private let ignoreList = ["VALID", "THRU", "VALIO", "THRO","BANK","BANKA","CARD","KART","FINANS","IBAN","VISA","ENBD"]

    func resetResults() {
        detectedCardNumber = nil
        detectedSKT = nil
        detectedName = nil
        detectedIBAN = nil
        detectedCVV = nil
    }
    
    struct DetectionOptions {
        let shouldDetectName: Bool
        let shouldDetectCardNumber: Bool
        let shouldDetectSKT: Bool
        let shouldDetectIBAN: Bool
        let shouldDetectCVV: Bool
    }
    
    func detectText(in image: CVPixelBuffer,
                    with options: DetectionOptions,
                    completion: @escaping (String) -> Void) {
        
        let request = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                print("No text detected or failed to recognize.")
                return
            }
            
            for observation in observations {
                guard let recognizedText = observation.topCandidates(1).first?.string else { continue }
                
                // no
                if options.shouldDetectCardNumber,
                   recognizedText.range(of: #"^\d{4} \d{4} \d{4} \d{4}$"#, options: .regularExpression) != nil,
                   self.detectedCardNumber == nil {
                    self.detectedCardNumber = recognizedText
                    completion("Kart Numarası: \(recognizedText)")
                    print("Detected Card Number: \(recognizedText)")
                }
                
                // SKT
                if options.shouldDetectSKT,
                   recognizedText.range(of: #"^(0[1-9]|1[0-2])\/([2-9][0-9]{1,3})$"#, options: .regularExpression) != nil,
                   self.detectedSKT == nil {
                    self.detectedSKT = recognizedText
                    completion("SKT: \(recognizedText)")
                    print("Detected SKT: \(recognizedText)")
                }

                // İsim
                if options.shouldDetectName,
                   self.detectedName == nil,
                   !self.ignoreList.contains(where: recognizedText.contains),
                   recognizedText.range(of: #"^[A-ZÇĞİÖŞÜ]{2,}\s+[A-ZÇĞİÖŞÜ]{2,}(?:\s[A-ZÇĞİÖŞÜ]+)*$"#, options: .regularExpression) != nil {
                    self.detectedName = recognizedText
                    completion("İsim: \(recognizedText)")
                    print("Detected Name: \(recognizedText)")
                }
                
                // CVV
                if options.shouldDetectCVV,
                   recognizedText.range(of: #"^\d{3}$"#, options: .regularExpression) != nil,
                   self.detectedCVV == nil {
                    self.detectedCVV = recognizedText
                    completion("CVV: \(recognizedText)")
                    print("Detected CVV: \(recognizedText)")
                }

                // IBAN
                if options.shouldDetectIBAN,
                   recognizedText.range(of: #"^TR\d{24}$"#, options: .regularExpression) != nil,
                   self.detectedIBAN == nil {
                    self.detectedIBAN = recognizedText
                    completion("IBAN: \(recognizedText)")
                    print("Detected IBAN: \(recognizedText)")
                }
            }
        }
        
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["tr-TR"]
        request.usesLanguageCorrection = true
        
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: image, options: [:])
        do {
            try requestHandler.perform([request])
        } catch {
            print("Failed to perform text detection: \(error.localizedDescription)")
        }
    }
}



