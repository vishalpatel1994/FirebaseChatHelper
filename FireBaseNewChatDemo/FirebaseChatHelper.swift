//
//  FirebaseChatHelper.swift
//  fireBaseChat
//
//  Created by Vishal Patel on 27/01/17.
//  Copyright © 2017 Vishal Patel. All rights reserved.
//

import Foundation
import Firebase

class FirebaseChatHelper: NSObject {

    let ref = FIRDatabase.database().reference()
    
    let deviceId = UIDevice.current.identifierForVendor?.uuidString
    
    private lazy var messageRef: FIRDatabaseReference = self.ref.child(DatabaseTableKeys.kMessageStoreKey)
    private var newMessageRefHandle: FIRDatabaseHandle?
    private var updatedMessageRefHandle: FIRDatabaseHandle?
    
    typealias ServiceBlock = (_ anydata:AnyObject?,_ error:Error?)  -> Void
    typealias BlockData = (_ data:FIRDataSnapshot) -> Void
    typealias MessagesBlock = (_ data:[[String:AnyObject]]) -> Void
    
    struct DatabaseTableKeys {
        static let kUserProfileBaseKey = "user_profile"
        static let kFireBaseStorageURL = "gs://chatdemo-7f74b.appspot.com"
        static let kMessageStoreKey    = "messages"
       static let kTypingIndicator =  "typingIndicator"
        
    }
    
    static let sharedInstance : FirebaseChatHelper = {
        let instance = FirebaseChatHelper()
        return instance
    }()
    
    
    // for login in firebase
    func login(emailId:UITextField , password:UITextField,block:@escaping ServiceBlock){
        FIRAuth.auth()?.signIn(withEmail: emailId.text!, password: password.text!) { (user, error) in
                if error == nil {
                    print("You have successfully logged in")
                    block(user!,nil)

                } else {
                    print(error!.localizedDescription)
                    if error!.localizedDescription == "There is no user record corresponding to this identifier. The user may have been deleted."{
                        self.signUpNewUser(userName: " ", firstName: " ", lastName: " ", phone: " ", emailId: emailId.text!, password: password.text!, Block: { (user, error) in
                            if user != nil{
                                block(user!,nil)
                            }
                            else{
                                block(nil,error!)
                            }
                        })
                    }
                    else{
                        block(nil,error!)
                    }
                }
            }
    }

    // for signUp  in fireBase
    func signUpNewUser(userName:String,firstName:String,lastName:String,phone:String,emailId:String ,password:String,Block:@escaping ServiceBlock){
        
        FIRAuth.auth()?.createUser(withEmail: emailId, password: password) { (user, error) in
            
            if error == nil {
                //Goes to the Setup page which lets the user take a photo for their profile picture and also chose a username
                let data :Dictionary<String,Any> = ["userName":userName,"firstName":firstName,"lastName":lastName,"phone":phone,"emailId":emailId]
               
                self.ref.child(DatabaseTableKeys.kUserProfileBaseKey).child("\(user!.uid)").setValue(data)
                
                print("You have successfully signed up with new user")
                //Block(user!,nil)
                Block(user!,nil)
            } else {
                Block(nil,error!)
            }
        }
    }
    
    //  for observ with  partiular root name
    func fetchDataFromParticularRoot(rootName:String ,block:@escaping BlockData)  {
        _ = self.ref.child(rootName).observe(FIRDataEventType.value, with: {(snapshot) in
            block(snapshot)
        })
    }
    
    func getAllMessages(convoId :String , block:@escaping MessagesBlock){
        
        var arrMessages = [[String: AnyObject]]()
        
        messageRef = self.ref.child("\(FirebaseChatHelper.DatabaseTableKeys.kMessageStoreKey)/\(convoId)")
        let messageQuery = messageRef.queryLimited(toLast:5000)
        newMessageRefHandle = messageQuery.observe(.value, with: { (snapshot) -> Void in
            
            print("Total Count:\(snapshot.childrenCount)")
            if snapshot.exists(){
                arrMessages.removeAll()
                
                let sorted = ((snapshot.value! as AnyObject).allValues as NSArray).sortedArray(using: [NSSortDescriptor(key: "timestamp",ascending: true)])
                // now we loop through sorted to get every single message
                for element in sorted {
                    if element is [String: AnyObject] {
                        let dict = element as! [String:AnyObject]
                        arrMessages.append(dict)
                    }
                }
                block(arrMessages)
            }else{
                //no data
                block(arrMessages)
            }
        })
    }

    
    // We can use the observe method to listen for new
    //MARK :-  messages being written to the Firebase DB
    func observeMessage(convoId :String , block:@escaping BlockData)  {
        messageRef = self.ref.child("\(FirebaseChatHelper.DatabaseTableKeys.kMessageStoreKey)/\(convoId)")
        let messageQuery = messageRef.queryLimited(toLast:5000)
      newMessageRefHandle = messageQuery.observe(.childAdded, with: { (snapshot) -> Void in
        
            block(snapshot)
        
        })
    }
    
    
    //MARK :- send message dictionary param 
    func sendTextMessageDict(senderid: String, senderName: String, text: String ,timestamp :Double) -> NSDictionary {
        return ["senderid":senderid,"senderName":senderName,"text":text ,"timestamp":timestamp]
    }
    func sendImageMessageDict(photoURL: String, senderid: String) -> NSDictionary {
         return ["photoURL":photoURL,"senderid":senderid]
    }
    
    //MARK :- online Or offline show method
    func showOnlineOfflineCall(userId:String ,online:Bool) {
      
        let myconnectionRef = FIRDatabase.database().reference(withPath: "\(FirebaseChatHelper.DatabaseTableKeys.kUserProfileBaseKey)/\(userId)")
        // when user logs in ,set the value true
        myconnectionRef.child("online").setValue(online)
        myconnectionRef.child("last_online").setValue(NSDate().timeIntervalSince1970)
        // observer which will monitor if user is  logged in or out
//        myconnectionRef.observe(.value, with: { (snapShot) in
//            
//            guard let conncted = snapShot.value as? Bool, conncted else{
//                return
//            }
//        })
        
    }

}

