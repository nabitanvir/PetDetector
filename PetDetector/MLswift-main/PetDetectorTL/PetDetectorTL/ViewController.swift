//
//  ViewController.swift
//  PetDetectorTL
//
//  Created by raihan on 5/27/22.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var resultLabel: UILabel!
    
    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: DogsCatsTransferLearningClassifier().model)
                
                let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in self?.processResults(for: request, error: error)
                    
                })
                
                request.imageCropAndScaleOption = .scaleFit
                return request
            } catch {
                fatalError("error/classificationRequest: failed to load core ML model")
            }
        }()
    
        override func viewDidLoad() {
            super.viewDidLoad()
            // additional setup goes here
        }
        
        
        @IBAction func onSelectImageFromPhotoLibrary(_ sender: UIButton) {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .photoLibrary
            present(picker, animated: true)
        }
        
        @IBAction func onSelectImageFromCamera(_ sender: UIButton) {
            guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                let alertController = UIAlertController(title: "Error", message: "Could not access the camera.", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "ok", style: .default, handler: nil))
                self.present(alertController, animated: true, completion:  nil)
                return
            }
            
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .camera
            present(picker, animated: true)
        }
        
        func detectPet(in image: UIImage) {
            resultLabel.text = "Processing..."
            
            guard let ciImage = CIImage(image: image),
                  let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue))
                    
            else {
                print("Unable to create CIImage instance")
                resultLabel.text = "Failed."
                return
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
                
                do {
                    try handler.perform([self.classificationRequest])
                } catch {
                    print("failed to perform classification.")
                    
                }
            }
        }
        func processResults(for request: VNRequest, error: Error?) {
            DispatchQueue.main.async {
                guard let results = request.results
                else {
                    print("Unable top classify image.\n\(error!.localizedDescription)")
                    self.resultLabel.text = "Unable to classify image."
                    return
                }
                
                let classification = results as! [VNClassificationObservation]
                
                if classification.isEmpty {
                    self.resultLabel.text = "Did not recognize anything."
                    
                } else {
                    self.resultLabel.text = String(format: "%@%.1f%%", classification[0].identifier, classification[0].confidence * 100)
                }
            }
        }
    }
    
    extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            picker.dismiss(animated: true)
            let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
            imageView.image = image
            detectPet(in: image)
        }
    }
