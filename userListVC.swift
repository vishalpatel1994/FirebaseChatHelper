//
//  userListVC.swift
//  FireBaseNewChatDemo
//
//  Created by Vishal Patel on 31/05/17.
//  Copyright © 2017 Vishal Patel. All rights reserved.
//

import UIKit
import Firebase

class userListVC: UIViewController,UITableViewDelegate,UITableViewDataSource,UIApplicationDelegate {
    
    let user = FIRAuth.auth()?.currentUser
    let deviceId = UIDevice.current.identifierForVendor?.uuidString
    
    let ref = FIRDatabase.database().reference()
    var currentUserName : String?
    
    @IBOutlet weak var tblView: UITableView!
    var usesData:NSDictionary = NSDictionary()
    
    var userArray:NSMutableArray = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "User List"
        
        getDataFromFirebase()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func getDataFromFirebase() {
       
        //get data from particular root and show it in tableview
        FirebaseChatHelper.sharedInstance.fetchDataFromParticularRoot(rootName: FirebaseChatHelper.DatabaseTableKeys.kUserProfileBaseKey) { (snapShot) in
            print(snapShot.value!)
            self.userArray = NSMutableArray()
            self.usesData = snapShot.value!  as! NSDictionary
            
            for(details) in self.usesData{
                let key = details.key as! String
                //print(key)
                if !(key == self.user!.uid) {
                    if let emailId = ((self.usesData[key] as! NSDictionary)["emailId"]) {
                        let userDict = ["key":key ,"emailId":emailId as! String]
                        self.userArray.add(userDict)
                    }
                    else{
                        print("Data not found")
                    }
                }
            }
            self.tblView .reloadData()
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.userArray.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier =  "cell"
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        let lblChnnel = cell.viewWithTag(100) as! UILabel
        lblChnnel.text = (userArray[indexPath.row]  as! NSDictionary) ["emailId"] as? String
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
//        self.performSegue(withIdentifier: "userToChatSegue", sender: (userArray[indexPath.row]))
        self.performSegue(withIdentifier: "customChat", sender: (userArray[indexPath.row]))
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        let userSendDict  = sender as! NSDictionary
        let chatVc = segue.destination as! CustomChatVC
        chatVc.senderId = self.user!.uid
        chatVc.senderDisplayName = self.currentUserName!
        chatVc.receiverData = userSendDict
        
    }
    
    @IBAction func btnBarButtonActionLogout(_ sender: UIBarButtonItem) {
        // logout and set online is false
        FirebaseChatHelper.sharedInstance.showOnlineOfflineCall(userId: user!.uid, online: false)
    }
    
}
