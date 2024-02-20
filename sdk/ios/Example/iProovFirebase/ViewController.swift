//
//  ViewController.swift
//  iProovFirebase
//
//  Created by Jonathan Ellis on 12/20/2023.
//  Copyright (c) 2023 Jonathan Ellis. All rights reserved.
//

import UIKit
import iProovFirebase
import iProov
import FirebaseAuth

class ViewController: UIViewController {
    @IBOutlet weak var userIDTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userIDTextField.text = UUID().uuidString
    }
    
    @IBAction func registerButtonTapped(_ sender: Any) {
        let options = Options()
        options.title = "Firebase Auth Example"
        
        Auth.auth().createUser(withIProovUserID: userIDTextField.text!,
                               assuranceType: .liveness,
                               options: options,
                               progressCallback: { progress in
            print(progress)
        }) { result, error in
            
            if let error = error {
                print("ERROR: \(error)")
                return
            }
            
            if let user = result?.user {
                print("Registered user: \(user.uid)")
            }
            
        }
        
    }
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        let options = Options()
        options.title = "Firebase Auth Example"
        
        Auth.auth().signIn(withIProovUserID: userIDTextField.text!,
                           assuranceType: .liveness,
                           options: options,
                           progressCallback: { progress in
            print(progress)
        }) { result, error in
            if let error = error {
                print("ERROR: \(error)")
                return
            }
            
            if let user = result?.user {
                print("Logged in user: \(user.uid)")
            }
        }
    }

}
