//
//  ViewController.swift
//  HipChatMessageParser
//
//  Created by Alexey Zhilnikov on 20/03/2016.
//  Copyright © 2016 Alexey Zhilnikov. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak private var messageTextField: UITextField!
    @IBOutlet weak private var jsonLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Show keyboard.
        messageTextField.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Action
    
    @IBAction func clearButtonTapped(sender: UIButton) {
        messageTextField.text = ""
        jsonLabel.text = ""
        // Show keyboard.
        messageTextField.becomeFirstResponder()
    }
    
    // MARK: - Text field delegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // Clear previous result.
        jsonLabel.text = ""
        
        let messageParser = MessageParser(message: textField.text!)
        messageParser.jsonString{data in self.jsonLabel.text = data}
        
        // Hide keyboard.
        textField.resignFirstResponder()
        return true
    }
}
