//
//  ReceiverCell.swift
//  Miss Doctor
//
//  Created by Darshit Vadodaria on 05/06/17.
//  Copyright © 2017 Sarthak Shah. All rights reserved.
//

import UIKit

class ReceiverCell: UITableViewCell {
    
    
    
    @IBOutlet weak var imgReceiver: UIImageView!
    @IBOutlet weak var lblMsg: UILabel!
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var imgBubble: UIImageView!
    @IBOutlet weak var btnReceiverImgClick: UIButton!
    
    var msg : MDMessage?{
        didSet{
            setData()
        }
    }
    
    func setData(){
        self.lblMsg.text = msg?.text
        self.lblMsg.sizeToFit()
        self.lblTime.text =  msg?.msgTime
        self.imgBubble.image = UIImage.init(named: "recieveBubble")?.stretchableImage(withLeftCapWidth: 20, topCapHeight: 12)
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
