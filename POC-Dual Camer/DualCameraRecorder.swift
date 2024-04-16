//
//  DualCameraRecorder.swift
//  POC-Dual Camer
//
//

import Foundation
import AVFoundation
import UIKit

class DualCameraRecorder:NSObject {
    private var multiCamSession: AVCaptureMultiCamSession?
    private var frontPreviewLayer: AVCaptureVideoPreviewLayer?
    private var backPreviewLayer: AVCaptureVideoPreviewLayer?
    private var frameCaptureTimer: Timer?
    private var frameCallback: ((UIImage?, UIImage?) -> Void)?

    func startPreview(frontView: UIView, backView: UIView, frameCallback: @escaping (UIImage?, UIImage?) -> Void) {
        self.frameCallback = frameCallback

        let session = AVCaptureMultiCamSession()

        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let frontInput = try? AVCaptureDeviceInput(device: frontCamera),
              let backInput = try? AVCaptureDeviceInput(device: backCamera) else {
            print("Failed to initialize camera inputs")
            return
        }

        guard session.canAddInput(frontInput) && session.canAddInput(backInput) else {
            print("Failed to add camera inputs to multi-cam session")
            return
        }

        session.beginConfiguration()
        session.addInput(frontInput)
        session.addInput(backInput)

        let frontPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        frontPreviewLayer.videoGravity = .resizeAspectFill
        frontPreviewLayer.frame = frontView.bounds
        frontView.layer.addSublayer(frontPreviewLayer)

        let backPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        backPreviewLayer.videoGravity = .resizeAspectFill
        backPreviewLayer.frame = backView.bounds
        backView.layer.addSublayer(backPreviewLayer)

        session.commitConfiguration()

        self.multiCamSession = session
        self.frontPreviewLayer = frontPreviewLayer
        self.backPreviewLayer = backPreviewLayer

        session.startRunning()

        startFrameCaptureTimer()
    }

    func stopPreview() {
        multiCamSession?.stopRunning()
        frontPreviewLayer?.removeFromSuperlayer()
        backPreviewLayer?.removeFromSuperlayer()
        stopFrameCaptureTimer()
    }

    private func startFrameCaptureTimer() {
        frameCaptureTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.captureFrames()
        }
    }

    private func stopFrameCaptureTimer() {
        frameCaptureTimer?.invalidate()
        frameCaptureTimer = nil
    }

    private func captureFrames() {
        guard let multiCamSession = multiCamSession,
              let frameCallback = frameCallback else { return }

        let frontOutput = AVCaptureVideoDataOutput()
        frontOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]

        let backOutput = AVCaptureVideoDataOutput()
        backOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]

        if multiCamSession.canAddOutput(frontOutput) && multiCamSession.canAddOutput(backOutput) {
            multiCamSession.addOutput(frontOutput)
            multiCamSession.addOutput(backOutput)

            frontOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "FrontCameraQueue"))
            backOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "BackCameraQueue"))
        }
    }
}

extension DualCameraRecorder: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
            return
        }

        let cameraPosition: AVCaptureDevice.Position = (connection.inputPorts.first?.input as? AVCaptureDeviceInput)?.device.position ?? .unspecified
        let image = UIImage(ciImage: CIImage(cvPixelBuffer: imageBuffer))

        if cameraPosition == .front {
            frameCallback?(image, nil)
        } else if cameraPosition == .back {
            frameCallback?(nil, image)
        }
    }
}
