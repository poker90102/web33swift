//
//  ViewController.swift
//  web3Swift-Demo
//
//  Created by Petr Korolev on 11/12/2017.
//  Copyright © 2017 Bankex Foundation. All rights reserved.
//

import UIKit
import Foundation

class ViewController: UIViewController {

    @IBOutlet var addressTV: UITextField!
    @IBOutlet var resultTF: UITextView!
    @IBAction func request(_ sender: Any) {
    }
    
    
    @IBAction func paste() {
        let pb: UIPasteboard = UIPasteboard.general
        resultTF.text = pb.string
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

