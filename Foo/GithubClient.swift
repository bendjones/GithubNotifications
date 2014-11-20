//
//  GithubClient.swift
//  Foo
//
//  Created by Ben Jones on 11/19/14.
//  Copyright (c) 2014 SocialCode Inc. All rights reserved.
//

import Foundation

struct Notification {
    /*
    "actor": {
        "id": 261833,
        "login": "aussielunix",
        "gravatar_id": "",
        "url": "https://api.github.com/users/aussielunix",
        "avatar_url": "https://avatars.githubusercontent.com/u/261833?"
    }
    */
    struct Owner {
        let id: String
        let login: String
        let gravatar_id: String
        let url: NSURL
        let avatarUrl: NSURL
    }
    
    struct Repo {
        let id: String
        let name: String
        let url: NSURL
        
        let description: String
        
        let owner: Owner
    }
    
    let id: String
    let type: String
    
    let repo: Repo
    
    let subject: String
    let url: NSURL
    let lastCommitURL: NSURL
}

let token = "REPLACE_WITH_GITHUB_TOKEN"

class GithubClient {
    class var sharedClient: GithubClient {
        struct Singleton {
            static let instance = GithubClient()
        }
        
        return Singleton.instance
    }
    
    private init() {
        
    }
    
    lazy var sessionConfig: NSURLSessionConfiguration = {
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionConfig.HTTPAdditionalHeaders = [ "Authorization" : "token \(token)", "Content-Type" : "application/json" ]
        
        return sessionConfig
    }()
    
    func fetchEvents(completionHandler: ([Notification] -> Void)){
        let session = NSURLSession(configuration: sessionConfig)
        let task = session.dataTaskWithURL(NSURL(string: "https://api.github.com/notifications")!) { (data, response, error) in
            let jsonError: NSError? = nil
            let json = JSON(data: data!)
            
            var notifications = [Notification]()
            
            if let jsonArray = json.array {
                for obj in jsonArray {
                    if let owner = obj["repository"]["owner"].dictionary {
                        let createdOwner = Notification.Owner(id: owner["id"]!.stringValue, login: owner["login"]!.stringValue, gravatar_id: owner["gravatar_id"]!.stringValue, url: NSURL(string: owner["url"]!.stringValue)!, avatarUrl: NSURL(string: owner["avatar_url"]!.stringValue)!)
                        
                        let repoObj = obj["repository"].dictionaryValue
                        let createdRepo = Notification.Repo(id: repoObj["id"]!.stringValue, name: repoObj["name"]!.stringValue, url: NSURL(string: repoObj["url"]!.stringValue)!, description: repoObj["description"]!.stringValue, owner: createdOwner)
                        
                        let createdNotification = Notification(id: obj["id"].stringValue, type: obj["type"].stringValue, repo: createdRepo, subject: obj["subject"]["title"].stringValue, url: NSURL(string: obj["subject"]["url"].stringValue)!, lastCommitURL: NSURL(string: obj["subject"]["latest_comment_url"].stringValue)!)
                        
                        notifications.append(createdNotification)
                    }
                }
            }
            
            completionHandler(notifications)
        }
        
        task.resume()
    }
}