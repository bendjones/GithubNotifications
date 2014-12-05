    //
//  InterfaceController.swift
//  Foo WatchKit Extension
//
//  Created by Ben Jones on 11/18/14.
//  Copyright (c) 2014 SocialCode Inc. All rights reserved.
//

import WatchKit
import Foundation
import ImageIO


class GithubTableRowController: NSObject {
    @IBOutlet weak var imageView: WKInterfaceImage!
    @IBOutlet weak var label: WKInterfaceLabel!
}

class GithubNotficationDetailController: WKInterfaceController {
    class ContextWrapper {
        let text: String
        let imageName: String
        
        init(text: String, imageName: String) {
            self.text = text
            self.imageName = imageName
        }
    }
    
    @IBOutlet weak var imageView: WKInterfaceImage!
    @IBOutlet weak var usernameLabel: WKInterfaceLabel!
    @IBOutlet weak var label: WKInterfaceLabel!
    
    override init(context: AnyObject?) {
        super.init(context: context)
        
        if let note = context as? ContextWrapper {
            label.setText(note.text)
            imageView.setImageNamed(note.imageName)
            usernameLabel.setText(note.imageName)
            setTitle(note.imageName)
        }
    }
}

class InterfaceController: WKInterfaceController {
    var notifications = [Notification]()
    
    @IBOutlet weak var table: WKInterfaceTable?
    
    @IBOutlet weak var button: WKInterfaceButton?
    
    @IBOutlet weak var image: WKInterfaceImage?
    
    var lastIndex = 0
    
    var animateIndex = 0

    override init(context: AnyObject?) {
        // Initialize variables here.
        super.init(context: context)
        
//        loadData()
    }
    
    func loadData() {
        self.table?.setNumberOfRows(self.notifications.count, withRowType: "GithubNotificationRowController")
        
        for (index, notification) in enumerate(self.notifications) {
            let row = self.table?.rowControllerAtIndex(index) as GithubTableRowController
            row.label.setText(notification.subject)
            row.imageView.setImageNamed(notification.repo.owner.login)
            
            WKInterfaceDevice.currentDevice()
            let promise = MediaClient.sharedClient.fetchMedia(fromURL: notification.repo.owner.avatarUrl.absoluteString!)
            promise.whenResolved { url in
                self.resizeImage(url, name: notification.repo.owner.login) { image in
                    let row = self.table?.rowControllerAtIndex(index) as GithubTableRowController
                    row.imageView.setImageNamed(notification.repo.owner.login)
                }
            }
            .whenRejected { println("Image Download Error \($0.localizedDescription)") }
        }
    }
    
    func resizeImage(url: NSURL, name: String, completionHandler: (UIImage? -> Void)) {
        if let imageSource = CGImageSourceCreateWithURL(url, nil) {
            let screenScale = Float(UIScreen.mainScreen().scale)
            
            let options = [
                kCGImageSourceThumbnailMaxPixelSize as String: 68 * screenScale,
                kCGImageSourceCreateThumbnailFromImageIfAbsent as String: true,
            ]
            
            if let scaledImage = UIImage(CGImage: CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options), scale: CGFloat(screenScale), orientation: .Up) {
                let data = UIImagePNGRepresentation(scaledImage)
                
                WKInterfaceDevice.currentDevice().addCachedImageWithData(data, name: name)
                
                WKInterfaceDevice.currentDevice().addCachedImageWithData(data, name: "animate-\(animateIndex)")
                
                animateIndex++
                completionHandler(scaledImage)
            } else {
                completionHandler(nil)
            }
        }
    }
    

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        image?.setImageNamed("heart2-")
        image?.startAnimatingWithImagesInRange(NSMakeRange(0, 53), duration: 2.5, repeatCount: 0)
        
        NSLog("%@ will activate", self)
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        NSLog("%@ did deactivate", self)
        super.didDeactivate()
    }

    @IBAction func buttonTap() {
        
    }
    
    override func contextForSegueWithIdentifier(segueIdentifier: String, inTable table: WKInterfaceTable, rowIndex: Int) -> AnyObject?
    {
        
        let note = notifications[rowIndex]
        let wrapper = GithubNotficationDetailController.ContextWrapper(text: note.subject, imageName: note.repo.owner.login)
        
        return wrapper
    }
}
