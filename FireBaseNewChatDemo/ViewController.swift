//
//  ViewController.swift
//  FireBaseNewChatDemo
//
//  Created by Vishal Patel on 31/05/17.
//  Copyright © 2017 Vishal Patel. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    @IBAction func btnActionLogin(_ sender: UIButton) {
        
        FirebaseChatHelper.sharedInstance.login(emailId: self.txtEmail, password: self.txtPassword, block: { (user, error) in
            
            if user != nil{
                // self.performSegue(withIdentifier: "loginSegue", sender: nil)
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "userListVC") as! userListVC
                vc.currentUserName = self.txtEmail!.text
                self.navigationController?.pushViewController(vc, animated: true)
                
            }
            else{
                let alertController = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                alertController.addAction(defaultAction)
                self.present(alertController, animated: true, completion: nil)
            }
            
            
        })
    }
}

