//
//  ScannerViewController.swift
//  ios-SampleCardDetection
//
//  Created by Necati Alperen IŞIK on 11.08.2024.
//

import UIKit
import AVFoundation
import CoreImage

class ScannerViewController: UIViewController {
    
    private lazy var focusView : UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.borderWidth = 1.0
        view.layer.borderColor = UIColor.white.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var overlayView : UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var resultStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = .center
        return stackView
    }()
    
    private lazy var resultBackground: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 10
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        return view
    }()
    
    private let cameraManager = CameraManager.shared
    private let scannerManager = ScannerManager.shared
    
    var shouldDetectName = false
    var shouldDetectCardNumber = true
    var shouldDetectSKT = true
    var shouldDetectIBAN = false
    var shouldDetectCVV = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        
        cameraManager.setupCamera(for: view, delegate: self)
        cameraManager.configureCameraSettings()
        setupUI()
    }
    
    private func setupNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = .white
        appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationItem.title = "Kart Tarayıcı"
        
        let refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshScan))
        navigationItem.rightBarButtonItem = refreshButton
    }
    
    @objc private func refreshScan() {
        resetResults()
        scannerManager.resetResults()
        cameraManager.startSession()
    }
    
    private func resetResults() {
        resultStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }
    
    private func setupUI() {
        view.addSubview(overlayView)
        view.addSubview(focusView)
        view.addSubview(resultBackground)
        view.addSubview(resultStackView)
        
        NSLayoutConstraint.activate([
            resultStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            resultStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            resultStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            
            resultBackground.leadingAnchor.constraint(equalTo: resultStackView.leadingAnchor),
            resultBackground.trailingAnchor.constraint(equalTo: resultStackView.trailingAnchor),
            resultBackground.topAnchor.constraint(equalTo: resultStackView.topAnchor),
            resultBackground.bottomAnchor.constraint(equalTo: resultStackView.bottomAnchor),
            
            focusView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            focusView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            focusView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.9),
            focusView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.4),
            
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    
        DispatchQueue.main.async {
            self.overlayView.layer.mask = self.createMaskLayer(excluding: self.focusView.frame)
        }
    }
    
    private func preprocessImage(_ image: CIImage) -> CIImage? {
        let filter = CIFilter(name: "CIExposureAdjust")
        filter?.setValue(image, forKey: kCIInputImageKey)
        filter?.setValue(1, forKey: kCIInputEVKey)
        
        if let outputImage = filter?.outputImage {
            let context = CIContext(options: nil)
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                return CIImage(cgImage: cgImage)
            }
        }
        return nil
    }
    
    private func displayDetectedInfo(_ info: String) {
        DispatchQueue.main.async {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.numberOfLines = 0
            label.textAlignment = .center
            label.text = info
            self.resultStackView.addArrangedSubview(label)
        }
    }
    
    private func createMaskLayer(excluding rect: CGRect) -> CALayer {
        let maskLayer = CAShapeLayer()
        let path = UIBezierPath(rect: view.bounds)
        path.append(UIBezierPath(rect: rect).reversing())
        maskLayer.path = path.cgPath
        return maskLayer
    }
}

extension ScannerViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let detectionOptions = ScannerManager.DetectionOptions(
            shouldDetectName: shouldDetectName,
            shouldDetectCardNumber: shouldDetectCardNumber,
            shouldDetectSKT: shouldDetectSKT,
            shouldDetectIBAN: shouldDetectIBAN,
            shouldDetectCVV: shouldDetectCVV
        )
        
        scannerManager.detectText(in: pixelBuffer, with: detectionOptions) { [weak self] detectedText in
            self?.displayDetectedInfo(detectedText)
        }
    }
}








