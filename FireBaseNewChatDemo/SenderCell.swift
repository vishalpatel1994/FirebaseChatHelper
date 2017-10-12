//
//  SenderCell.swift
//  Miss Doctor
//
//  Created by Darshit Vadodaria on 05/06/17.
//  Copyright © 2017 Sarthak Shah. All rights reserved.
//

import UIKit

class SenderCell: UITableViewCell {

    @IBOutlet weak var lblMsg: UILabel!
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var imgBubble: UIImageView!
    
    var msg : MDMessage?{
        didSet{
            setData()
        }
    }
    
    func setData(){
        self.lblMsg.text = msg?.text
        self.lblMsg.sizeToFit()
        self.lblTime.text = msg?.msgTime
        self.imgBubble.image = UIImage.init(named: "senderBubble")?.stretchableImage(withLeftCapWidth: 15 , topCapHeight: 10)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
