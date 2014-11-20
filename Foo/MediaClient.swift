//
//  MediaClient.swift
//  MessageOptics
//
//  Created by Ben Jones on 8/12/14.
//  Copyright (c) 2014 SocialCode Inc. All rights reserved.
//

import Foundation

public class MediaClient {
    private enum ErrorCodes: Int {
        case BADURL = 1221
        case SAVEERROR = 1223
    }

    public let cacheDirectory: String = "com.socialcode.media"

    public lazy var mediaDirectoryPath: NSURL? = {
        let cacheDirs = NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask)
        let systemCacheDir = cacheDirs.last as NSURL
        let fullPath = systemCacheDir.URLByAppendingPathComponent(self.cacheDirectory)

        if NSFileManager.defaultManager().fileExistsAtPath(fullPath.path!) == false {
            var fileCreateError: NSError?

            NSFileManager.defaultManager().createDirectoryAtPath(fullPath.path!, withIntermediateDirectories: true, attributes: nil, error: &fileCreateError)

            if fileCreateError != nil {
                NSLog("Error creating media directory at url \(fullPath.path)")
                return nil
            }
        }

        return fullPath
    }()

    public class var sharedClient: MediaClient {
        struct Singleton {
            static let instance = MediaClient()
        }

        return Singleton.instance
    }

    private init() {

    }

    public func fetchMedia(fromURL URL: String, additionalKey: String? = nil) -> Promise<NSURL> {
        let attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_BACKGROUND, 0)
        let queue = dispatch_queue_create("MessageOptics.MediaClient.FetchMedia", attr)
        
        let mediaFetchPromise = Promise<NSURL>()
        if URL == "" {
            let badURLError = NSError(domain: "Bad or malformed URL", code: ErrorCodes.BADURL.rawValue, userInfo: [ "url" : URL])
            mediaFetchPromise.reject(badURLError)
            
            return mediaFetchPromise
        }

        dispatch_async(queue) {
            let config = NSURLSessionConfiguration.defaultSessionConfiguration()
            let session = NSURLSession(configuration: config)
        
            let actualURL = NSURL(string: URL)!
            let task = session.downloadTaskWithURL(actualURL) { destUrl, response, error in
                if error != nil {
                    dispatch_async(dispatch_get_main_queue()) {
                        mediaFetchPromise.reject(error!)
                    }
                } else {
                    if let destUrl = destUrl {
                        if let responseFilename = response?.suggestedFilename {
                            var fileName = responseFilename
                            if let key = additionalKey {
                                fileName = "\(key)_\(fileName)"
                            }
                            
                            if let finalUrl = self.mediaDirectoryPath?.URLByAppendingPathComponent(fileName) {
                                if NSFileManager.defaultManager().fileExistsAtPath(finalUrl.path!) {
                                    dispatch_async(dispatch_get_main_queue()) {
                                        mediaFetchPromise.resolve(finalUrl)
                                    }
                                } else {
                                    var moveError: NSError?
                                    if NSFileManager.defaultManager().moveItemAtURL(destUrl, toURL: finalUrl, error: &moveError) == false {
                                        dispatch_async(dispatch_get_main_queue()) {
                                            mediaFetchPromise.reject(moveError!)
                                        }
                                    } else {
                                        dispatch_async(dispatch_get_main_queue()) {
                                            mediaFetchPromise.resolve(finalUrl)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            task.resume()
        }

        return mediaFetchPromise
    }
}
