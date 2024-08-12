//
//  CameraManger.swift
//  ios-SampleCardDetection
//
//  Created by Necati Alperen IŞIK on 12.08.2024.
//

import AVFoundation
import UIKit

final class CameraManager {
    
    static let shared = CameraManager()
    private init() {}
    
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    func setupCamera(for view: UIView, delegate: AVCaptureVideoDataOutputSampleBufferDelegate) {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else {
            print("Error: Unable to create capture session.")
            return
        }

        guard let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Error: Unable to access the back camera.")
            return
        }

        do {
            let videoInput = try createVideoInput(for: videoCaptureDevice)
            addInput(videoInput, to: captureSession)
        } catch {
            print("Error: Unable to create video input - \(error).")
            return
        }

        let videoOutput = createVideoOutput(delegate: delegate)
        addOutput(videoOutput, to: captureSession)

        configurePreviewLayer(for: captureSession, on: view)
        startSession()
    }
    
    private func configureWhiteBalance(for device: AVCaptureDevice) {
        if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
            device.whiteBalanceMode = .continuousAutoWhiteBalance
        }
    }

    private func configureExposure(for device: AVCaptureDevice) {
        if device.isExposureModeSupported(.continuousAutoExposure) {
            device.exposureMode = .continuousAutoExposure
        }
    }

    private func configureFocus(for device: AVCaptureDevice) {
        if device.isFocusModeSupported(.continuousAutoFocus) {
            device.focusMode = .continuousAutoFocus
        }
    }

    func configureCameraSettings() {
        guard let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Error: Unable to access the back camera.")
            return
        }

        do {
            try videoCaptureDevice.lockForConfiguration()
            configureWhiteBalance(for: videoCaptureDevice)
            configureExposure(for: videoCaptureDevice)
            configureFocus(for: videoCaptureDevice)
            videoCaptureDevice.unlockForConfiguration()
        } catch {
            print("Error configuring camera: \(error)")
        }
    }

    private func createVideoInput(for device: AVCaptureDevice) throws -> AVCaptureDeviceInput {
        return try AVCaptureDeviceInput(device: device)
    }

    private func addInput(_ input: AVCaptureDeviceInput, to session: AVCaptureSession) {
        if session.canAddInput(input) {
            session.addInput(input)
        } else {
            print("Error: Unable to add input to session.")
        }
    }

    private func createVideoOutput(delegate: AVCaptureVideoDataOutputSampleBufferDelegate) -> AVCaptureVideoDataOutput {
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(delegate, queue: DispatchQueue(label: "videoQueue"))
        return videoOutput
    }

    private func addOutput(_ output: AVCaptureVideoDataOutput, to session: AVCaptureSession) {
        if session.canAddOutput(output) {
            session.addOutput(output)
        } else {
            print("Error: Unable to add output to session.")
        }
    }

    private func configurePreviewLayer(for session: AVCaptureSession, on view: UIView) {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.frame = view.layer.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer!)
    }

    func startSession() {
        captureSession?.startRunning()
    }

    func stopSession() {
        captureSession?.stopRunning()
    }
}


