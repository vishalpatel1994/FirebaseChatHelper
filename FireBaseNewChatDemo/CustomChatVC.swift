//
//  CustomChatVC.swift
//  CustomChatWithFirebase
//
//  Created by Vishal Patel on 11/07/17.
//  Copyright © 2017 Vishal Patel. All rights reserved.
//

import UIKit
import Firebase
import ObjectMapper

class CustomChatVC: UIViewController {
    
    @IBOutlet weak var tblChat: UITableView!
    @IBOutlet weak var tblPopupList: UITableView!
    @IBOutlet weak var txtSendMessage: UITextView!
    
    var messages: [MDMessage] = []
    
    
    var senderId : String = ""
    var senderDisplayName: String!
    
    var currentUserName :String?
    
    // recevir ref
    var receiverData : AnyObject?
    //var receiverExpiredData : Expired?
    var rootRef = FIRDatabase.database().reference()
    var convoId : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // making convoId
        let receiverID = receiverData?["key"] as! String
        if(self.senderId > receiverID){
            self.convoId = receiverID + self.senderId
        }
        else{
            self.convoId = self.senderId + receiverID
        }
        observeMessages()
    }
    func observeMessages() {
        
               
                FirebaseChatHelper.sharedInstance.getAllMessages(convoId: self.convoId!, block: { (snapshot) in
        
                    self.messages.removeAll()
        
                    for message in snapshot {
                        var messageData =  message
                        
                        if let id = messageData["senderid"] as! String!, let name = messageData["senderName"] as! String!, let timestamp = messageData["timestamp"]  , let text = messageData["text"] as! String!, text.characters.count > 0 {
//                           /let timeDate =  Date(timeIntervalSince1970: TimeInterval(interval)/1000)
                            //messageData.setValue(timeDate as! Any, forKey: "timestamp")
                            messageData["timestamp"] = timestamp
                            
                            let message : MDMessage = Mapper<MDMessage>().map(JSON: (messageData) as [String : Any])!
                            self.messages.append(message)
                        }
                        else {
                            print("Error! Could not decode message data")
                        }
                    }
                    
                    self.refreshMessages()
                })
            }
    func refreshMessages() {
        
                if self.messages.count > 0{
                    
                    self.tblChat.isHidden = false
                    self.tblChat.reloadData()
                    if self.messages.count > 0{
                        let index : IndexPath = IndexPath.init(row: self.messages.count - 1 , section: 0)
                        self.tblChat.scrollToRow(at: index, at: .bottom, animated: false)
                    }
                }else{
                    
                    self.tblChat.isHidden = true
                }
            }
    @IBAction func btnActionSendMsg(_ sender: UIButton) {
        
        let itemRef = self.rootRef.child(FirebaseChatHelper.DatabaseTableKeys.kMessageStoreKey).child("\(self.convoId!)").childByAutoId()
        
        //2
        let timeStamp = (Date().timeIntervalSince1970 * 1000)
        let messageItem = FirebaseChatHelper.sharedInstance.sendTextMessageDict(senderid: self.senderId, senderName: self.senderDisplayName, text: txtSendMessage.text! ,timestamp:timeStamp)
        // 3
        itemRef.setValue(messageItem)
        if self.messages.count > 1{
            let index : IndexPath = IndexPath.init(row: self.messages.count - 1 , section: 0)
            self.tblChat.scrollToRow(at: index, at: .bottom, animated: true)
        }
        txtSendMessage.text = ""
    }
}
extension CustomChatVC : UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
            return UITableViewAutomaticDimension
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
//        if tableView == self.tblPopupList{
//            return 3
//        }
//        else{
            return messages.count
//        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
//        if  tableView == tblPopupList{
//            let cell = UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: "Cell")
//            cell.selectionStyle = .none
//            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 17)
//            switch indexPath.row {
//            case 0:
//                cell.textLabel!.text = "Unmatch"
//                break
//            case 1:
//                cell.textLabel!.text = "Report"
//                break
//            case 2:
////                if (self.receiverData != nil) {
////                    cell.textLabel!.text = (self.receiverData?.is_blocked)! == true ? "Unblock" : "Block"
////                }
//                
//                break
//            default:
//                break
//            }
//            return cell
//        }
//        else{
            let msg = messages[indexPath.row]
            
            if msg.senderid == self.senderId{
                let cell = tableView.dequeueReusableCell(withIdentifier: "SenderCell") as! SenderCell
                cell.msg = msg
                return cell
            }
            else{
                let cell = tableView.dequeueReusableCell(withIdentifier: "ReceiverCell") as! ReceiverCell
                cell.msg = msg
//                cell.btnReceiverImgClick.addTarget(self, action: #selector(ChatVC.openProfile(sender:)), for: .touchUpInside)
//                cell.imgReceiver.imgUrl = (receiverData?.image)!
                return cell
            }
//        }
        
    }
   
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        print("Did Select")
//        self.dropDownParentView.isHidden = true
//        if tableView == tblPopupList{
//            switch indexPath.row {
//            case 0:
//                unmatchUser()
//                break
//            case 1:
//                break
//            case 2:
//                blockUser()
//                break
//            default:
//                break
//            }
//            
//        }
        self.view.endEditing(true)
        
    }
    
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if tableView == tblChat{
            return 0
        }
        else{
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
//        if tableView == tblChat{
////            let view = UIView.init(frame: CGRect.init(x: (tblChat.frame.size.width/2)-84.0, y: 0, width: tblChat.frame.size.width/2, height: 37.0))
////            view.backgroundColor = UIColor.clear
////            viewHeader.frame = CGRect.init(x: (tblChat.frame.size.width/2)-84, y: 9.0, width: viewHeader.frame.size.width, height: viewHeader.frame.size.height)
////            if (self.receiverData != nil ) {
////                self.matchDate.text = "Matched: " + (receiverData?.acceptedTime)!
////            }
////            view.addSubview(viewHeader)
//            return view
//        }
//        else{
            return nil
//        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        if tableView == tblChat{
            return 0
        }
        else{
            return 0
        }
        
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
//        if tableView == tblChat{
//            if isExpired && isUnMatched == false{
//                let view = UIView.init(frame: CGRect.init(x: (tblChat.frame.size.width/2)-84.0, y: 0, width: tblChat.frame.size.width/2, height: 37.0))
//                view.backgroundColor = UIColor.clear
//                viewFooter.frame = CGRect.init(x: (tblChat.frame.size.width/2)-84, y: 1.0, width: viewFooter.frame.size.width, height: viewFooter.frame.size.height)
//                if (self.receiverData != nil ) {
//                    self.expiryDate.text = "Expired: " + (receiverData?.expiryTime)!
//                }
//                
//                view.addSubview(viewFooter)
//                return view
//            }
//            else{
//                let view = UIView.init(frame: CGRect.init(x: (tblChat.frame.size.width/2)-84.0, y: 0, width: tblChat.frame.size.width/2, height: 1.0))
//                view.backgroundColor = UIColor.clear
//                return view
//            }
//        }
//        else{
            return nil
//        }
        
    }
}
