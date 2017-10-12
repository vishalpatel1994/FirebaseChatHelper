/*
* Copyright (c) 2015 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import UIKit
import Photos
import Firebase
import JSQMessagesViewController

final class ChatViewController: JSQMessagesViewController,UIApplicationDelegate {
  
    // MARK: Properties
    var imageURLNotSetKey = ""
  
    //var channelRef: FIRDatabaseReference?
    
    var currentUserName :String?
    
    // recevir ref
    var receiverData : AnyObject?
    var rootRef = FIRDatabase.database().reference()
    var convoId : String?
    
    private lazy var messageRef: FIRDatabaseReference = self.rootRef.child(FirebaseChatHelper.DatabaseTableKeys.kMessageStoreKey)
    fileprivate lazy var storageRef: FIRStorageReference = FIRStorage.storage().reference(forURL: FirebaseChatHelper.DatabaseTableKeys.kFireBaseStorageURL)
    
    private lazy var userIsTypingRef: FIRDatabaseReference = self.rootRef.child(FirebaseChatHelper.DatabaseTableKeys.kTypingIndicator).child(self.senderId)
    private lazy var usersTypingQuery: FIRDatabaseQuery = self.rootRef.child(FirebaseChatHelper.DatabaseTableKeys.kTypingIndicator).queryOrderedByValue().queryEqual(toValue: true)

    private var newMessageRefHandle: FIRDatabaseHandle?
    private var updatedMessageRefHandle: FIRDatabaseHandle?
  
     var messages: [JSQMessage] = []
     var photoMessageMap = [String: JSQPhotoMediaItem]()
  
    private var localTyping = false
//    var channel: Channel? {
//        didSet {
//            title = channel?.name
//        }
//    }

    var isTyping: Bool {
        get {
            return localTyping
        }
        set {
            localTyping = newValue
            userIsTypingRef.setValue(newValue)
        }
    }
  
    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()
  
    
    
  // MARK: View Lifecycle
  
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.senderId = FIRAuth.auth()?.currentUser?.uid
        
        
        let keyWindow  = UIApplication.shared.keyWindow
        // No avatars
//        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
//        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        
        // set connection online
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidBecomeActive, object: nil, queue: OperationQueue.main) { (notification) in
            FirebaseChatHelper.sharedInstance.showOnlineOfflineCall(userId: self.senderId!, online: true)
        }
    
        // set profile avtar width and height
        collectionView?.collectionViewLayout.incomingAvatarViewSize = CGSize(width: kJSQMessagesCollectionViewAvatarSizeDefault, height:kJSQMessagesCollectionViewAvatarSizeDefault )
        collectionView?.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: kJSQMessagesCollectionViewAvatarSizeDefault, height:kJSQMessagesCollectionViewAvatarSizeDefault )
        
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
  
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
       
        observeTyping()
    }
  
    deinit {
        if let refHandle = newMessageRefHandle {
            messageRef.removeObserver(withHandle: refHandle)
        }
        if let refHandle = updatedMessageRefHandle {
            messageRef.removeObserver(withHandle: refHandle)
        }
    }
  
    
  // MARK: Collection view data source (and related) methods
  
    override func collectionView(_ collectionView: JSQMessagesCollectionView, avatarImageDataForItemAt indexPath: IndexPath) -> JSQMessageAvatarImageDataSource? {
        
            // shows sender name on top of the message
            let message = messages[indexPath.item]
            let AvatarLeonard = JSQMessagesAvatarImageFactory.avatarImage(withUserInitials: String(message.senderDisplayName.characters.prefix(1)), backgroundColor: UIColor.cyan, textColor: UIColor.white, font: UIFont.systemFont(ofSize: 12), diameter: 12)
            return AvatarLeonard
    

    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
  
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
  
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) ->JSQMessageBubbleImageDataSource! {
        
        let message = messages[indexPath.item] // 1
        if message.senderId == senderId { // 2
            return outgoingBubbleImageView
        } else { // 3
            return incomingBubbleImageView
        }
    }
  
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
    
        let message = messages[indexPath.item]
    
        if message.senderId == senderId { // 1
            cell.textView?.textColor = UIColor.white // 2
        } else {
            cell.textView?.textColor = UIColor.black // 3
        }
    
        return cell
    }
  
    
  
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat {
        return 15
    }
  
    override func collectionView(_ collectionView: JSQMessagesCollectionView?, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString?{
            let message = messages[indexPath.item]
            switch message.senderId {
            case senderId:
                return nil
            default:
                guard let senderDisplayName = message.senderDisplayName else {
                    assertionFailure()
                    return nil
                }
                return NSAttributedString(string: senderDisplayName)
            }
    }

    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, attributedTextForCellTopLabelAt indexPath: IndexPath) -> NSAttributedString? {
        
        return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: self.messages[indexPath.item].date)
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout, heightForCellTopLabelAt indexPath: IndexPath) -> CGFloat {
 
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }
    
    
    
    // MARK: Firebase related methods
  
     func observeMessages() {
    
    //    messageRef = rootRef.child("\(FirebaseChatHelper.DatabaseTableKeys.kMessageStoreKey)/\(self.convoId!)")
    //    let messageQuery = messageRef.queryLimited(toLast:500)
    //
    // We can use the observe method to listen for new
    // messages being written to the Firebase DB
    
        FirebaseChatHelper.sharedInstance.observeMessage(convoId: self.convoId!, block: { (snapshot) in
            let messageData = snapshot.value as! NSDictionary
            //print(messageData)
            if let id = messageData["senderid"] as! String!, let name = messageData["senderName"] as! String!, let timestamp = messageData["timestamp"]  , let text = messageData["text"] as! String!, text.characters.count > 0 {
                self.addMessage(withId: id, name: name, text: text, date: timestamp as! Double)
                self.finishReceivingMessage()
            }
            else if let id = messageData["senderid"] as! String!, let photoURL = messageData["photoURL"] as! String!
            {
                if let mediaItem = JSQPhotoMediaItem(maskAsOutgoing: id == self.senderId)
                {
                    self.addPhotoMessage(withId: id, key: snapshot.key, mediaItem: mediaItem)
                    
                    if photoURL.hasPrefix("gs://")
                    {
                        self.fetchImageDataAtURL(photoURL, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: nil)
                    }
                }
            }
            else {
                print("Error! Could not decode message data")
            }
        })
    
        // We can also use the observer method to listen for
        // changes to existing messages.
        // We use this to be notified when a photo has been stored
        // to the Firebase Storage, so we can update the message data
        FirebaseChatHelper.sharedInstance.observeMessage(convoId: self.convoId!, block: { (snapshot) in
            let key = snapshot.key
            let messageData = snapshot.value as! NSDictionary
      
            if let photoURL = messageData["photoURL"] as! String! {
                // The photo has been updated.
                if let mediaItem = self.photoMessageMap[key] {
                    self.fetchImageDataAtURL(photoURL, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: key)
                }
            }
        })
    }
  
    private func fetchImageDataAtURL(_ photoURL: String, forMediaItem mediaItem: JSQPhotoMediaItem, clearsPhotoMessageMapOnSuccessForKey key: String?) {
        let storageRef = self.storageRef.child(photoURL)
        storageRef.data(withMaxSize: Int64(INT_MAX)){ (data, error) in
            if let error = error {
                print("Error downloading image data: \(error)")
                return
            }
      
            storageRef.metadata(completion: { (metadata, metadataErr) in
                if let error = metadataErr {
                    print("Error downloading metadata: \(error)")
                    return
                }
        
                if (metadata?.contentType == "image/gif") {
                    //mediaItem.image = UIImage.gifWithData(data!)
                } else {
                    mediaItem.image = UIImage.init(data: data!)
                }
                self.collectionView.reloadData()
        
                guard key != nil else {
                    return
                }
                self.photoMessageMap.removeValue(forKey: key!)
            })
        }
    }
  
    private func observeTyping() {
            let typingIndicatorRef = rootRef.child(FirebaseChatHelper.DatabaseTableKeys.kTypingIndicator)
            userIsTypingRef = typingIndicatorRef.child(senderId)
            userIsTypingRef.onDisconnectRemoveValue()
            usersTypingQuery = typingIndicatorRef.queryOrderedByValue().queryEqual(toValue: true)
    
            usersTypingQuery.observe(.value) { (data: FIRDataSnapshot) in
      
            // You're the only typing, don't show the indicator
                if data.childrenCount == 1 && self.isTyping {
                return
                }
      
                // Are there others typing?
                self.showTypingIndicator = data.childrenCount > 0
                self.scrollToBottom(animated: true)
            }
    }
  
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
    
            // 1
            //    let itemRef = messageRef.childByAutoId()
            let itemRef = rootRef.child(FirebaseChatHelper.DatabaseTableKeys.kMessageStoreKey).child("\(self.convoId!)").childByAutoId()
        
            //2
            let timeStamp =  date.timeIntervalSince1970 * 1000.0.rounded()
            let messageItem = FirebaseChatHelper.sharedInstance.sendTextMessageDict(senderid: senderId!, senderName: senderDisplayName!, text: text! ,timestamp:timeStamp)        // 3
            itemRef.setValue(messageItem)
    
            // 4
            JSQSystemSoundPlayer.jsq_playMessageSentSound()
    
            // 5
            finishSendingMessage()
            isTyping = false
    }
  
    func sendPhotoMessage(photoUrl:String) -> String? {
            let itemRef = messageRef.child("\(self.convoId!)").childByAutoId()
            let messageItem = FirebaseChatHelper.sharedInstance.sendImageMessageDict(photoURL: photoUrl, senderid: senderId!)
    
            itemRef.setValue(messageItem)
    
            JSQSystemSoundPlayer.jsq_playMessageSentSound()
    
            finishSendingMessage()
            return itemRef.key
    }
  
    func setImageURL(_ url: String, forPhotoMessageWithKey key: String) {
            let itemRef = messageRef.child(key)
            itemRef.updateChildValues(["photoURL": url])
    }
  
    // MARK: UI and User Interaction
  
    private func setupOutgoingBubble() -> JSQMessagesBubbleImage {
            let bubbleImageFactory = JSQMessagesBubbleImageFactory()
            return bubbleImageFactory!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    }

    private func setupIncomingBubble() -> JSQMessagesBubbleImage {
            let bubbleImageFactory = JSQMessagesBubbleImageFactory()
            return bubbleImageFactory!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    }

    override func didPressAccessoryButton(_ sender: UIButton) {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.allowsEditing = true   
            if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)) {
                picker.sourceType = UIImagePickerControllerSourceType.camera
            } else {
                picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
            }
    
            present(picker, animated: true, completion:nil)
    }
  
    private func addMessage(withId id: String, name: String, text: String ,date :Double) {
            let timeStamp =  Date(timeIntervalSince1970: TimeInterval(date)/1000)
            if let message = JSQMessage(senderId: id, senderDisplayName: name, date: timeStamp as Date!, text: text){//(senderId: id, displayName: name, text: text) {
                messages.append(message)
        }
    }
    
    private func addPhotoMessage(withId id: String, key: String, mediaItem: JSQPhotoMediaItem) {
            if let message = JSQMessage(senderId: id, displayName: "", media: mediaItem) {
                messages.append(message)
      
                if (mediaItem.image == nil) {
                    photoMessageMap[key] = mediaItem
                }
                collectionView.reloadData()
            }
    }
  
    // MARK: UITextViewDelegate methods
  
    override func textViewDidChange(_ textView: UITextView) {
            super.textViewDidChange(textView)
            // If the text is not empty, the user is typing
            isTyping = textView.text != ""
        }
    }

    // MARK: Image Picker Delegate
    extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
            func imagePickerController(_ picker: UIImagePickerController,
                             didFinishPickingMediaWithInfo info: [String : Any]) {

                picker.dismiss(animated: true, completion:nil)
                let picture = info[UIImagePickerControllerEditedImage] as? UIImage
                
                
                // 1
                if let photoReferenceUrl = info[UIImagePickerControllerReferenceURL] as? URL {
                    // Handle picking a Photo from the Photo Library
                    // 2
                    let assets = PHAsset.fetchAssets(withALAssetURLs: [photoReferenceUrl], options: nil)
                    let asset = assets.firstObject

                    // 3
                   
                        // 4
                        asset?.requestContentEditingInput(with: nil, completionHandler: { (contentEditingInput, info) in
                            let imageFileURL = contentEditingInput?.fullSizeImageURL

                            // 5
                            let id = self.senderId!
                            let timeInterval = Int(Date.timeIntervalSinceReferenceDate * 1000)
                            let endUrlName = photoReferenceUrl.lastPathComponent
                            let path = "\(id)/\(timeInterval)/\(endUrlName)"
//  
                            
                            print(path)
                            self.imageURLNotSetKey = path

//                            let path = "\(String(describing: FIRAuth.auth()?.currentUser?.uid))"
                            // 6
                            self.storageRef.child(path).putFile(imageFileURL!, metadata: nil) { (metadata, error) in
                                if let error = error {
                                    print("Error uploading photo: \(error.localizedDescription)")
                                    return
                                }
                                // 7
                                let key = self.sendPhotoMessage(photoUrl: self.imageURLNotSetKey)
//                                self.setImageURL(self.storageRef.child((metadata?.path)!).description, forPhotoMessageWithKey: key!)
                            }
                        })
                    
                } else {
                    // Handle picking a Photo from the Camera - TODO
                }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true, completion:nil)
        }
    }

