//
//  ViewController.swift
//  POC-Dual Camer
//
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var frontCameraView: UIView!
    @IBOutlet weak var backCameraView: UIView!
    @IBOutlet weak var ivFront: UIImageView!
    @IBOutlet weak var ivBack: UIImageView!
    
    private var dualCameraRecorder = DualCameraRecorder()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startCameraPreview()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCameraPreview()
    }
    
    private func startCameraPreview() {
        dualCameraRecorder.startPreview(frontView: frontCameraView, backView: backCameraView, frameCallback: { [self]
            frontImage, backImage in
            DispatchQueue.main.async { [self] in
                ivFront.image = frontImage
                ivBack.image = backImage
            }
        })
    }
    
    private func stopCameraPreview() {
        dualCameraRecorder.stopPreview()
    }
}

