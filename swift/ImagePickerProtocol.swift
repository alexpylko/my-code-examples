//
//  ImagePickerProtocol.swift
//  SplitGreens
//
//  Created by Oleksii Pylko on 23/02/16.
//  Copyright © 2016 Oleksii Pylko. All rights reserved.
//
import UIKit
import MobileCoreServices

protocol ImagePickerProtocol : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func takePhotoAction(action: UIAlertAction)
    
    func choosePictureAction(action: UIAlertAction)
    
}

extension ImagePickerProtocol where Self : UIViewController {
    
    private func imagePickerActionSheetController() -> UIAlertController {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            let takeAction = UIAlertAction(title: "image-picker.action-sheet.take-picture".localized, style: .Default, handler: takePhotoAction)
            alertController.addAction(takeAction)
        }
        
        if UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary) {
            let chooseAction = UIAlertAction(title: "image-picker.action-sheet.choose-photo".localized, style: .Default, handler: choosePictureAction)
            alertController.addAction(chooseAction)
        }
        
        let defaultAction = UIAlertAction(title: "image-picker.action-sheet.close".localized, style: .Cancel, handler: nil)
        alertController.addAction(defaultAction)
        
        return alertController
    }
    
    func presentImagePickerActionSheetController() {
        presentViewController(imagePickerActionSheetController(), animated: true, completion: nil)
    }
    
    func takePhotoAction(action: UIAlertAction) {
        presentViewController(imagePickerControllerOfSourceType(.Camera), animated: true, completion: nil)
    }
    
    func choosePictureAction(action: UIAlertAction) {
        presentViewController(imagePickerControllerOfSourceType(.PhotoLibrary), animated: true, completion: nil)
    }
    
    private func imagePickerControllerOfSourceType(sourceType: UIImagePickerControllerSourceType) -> UIImagePickerController {
        let imagePickerController = UIImagePickerController()
        
        imagePickerController.sourceType = sourceType
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        imagePickerController.mediaTypes = [kUTTypeImage as String]
        
        return imagePickerController
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}
