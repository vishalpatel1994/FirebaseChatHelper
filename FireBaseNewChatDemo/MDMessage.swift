//
//	Message.swift
//
//	Create by Darshit Vadodaria on 5/6/2017
//	Copyright © 2017. All rights reserved.
//	Model file generated using JSONExport: https://github.com/Ahmed-Ali/JSONExport

import Foundation
import ObjectMapper

class MDMessage : NSObject,Mappable{

	var senderName : String?
	var senderid : String?
	var text : String?
	var timestamp : Date? = nil
    var msgTime : String = ""
	required init?(map: Map){}

	func mapping(map: Map)
	{
		senderName <- map["senderName"]
		senderid <- map["senderid"]
		text <- map["text"]
		timestamp <- map["timestamp"]
		setTime()
	}

    func setTime(){
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "hh:mm a"
//        msgTime = dateFormat.string(from: self.timestamp!)
    }
}
