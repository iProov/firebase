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
import SVProgressHUD

enum Action {
    case createUser, signIn
}

class ViewController: UIViewController {
    @IBOutlet weak var userIDTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        userIDTextField.text = UUID().uuidString
    }

    @IBAction func registerWithGPAButtonPressed(_ sender: Any) {
        start(action: .createUser, assuranceType: .genuinePresence)
    }

    @IBAction func registerWithLAButtonPressed(_ sender: Any) {
        start(action: .createUser, assuranceType: .liveness)
    }

    @IBAction func loginWithGPAButtonPressed(_ sender: Any) {
        start(action: .signIn, assuranceType: .genuinePresence)
    }

    @IBAction func loginWithLAButtonPressed(_ sender: Any) {
        start(action: .signIn, assuranceType: .liveness)
    }

    @IBAction func logoutButtonPressed(_ sender: Any) {
        try? Auth.auth().signOut()
    }
    
    private func start(action: Action, assuranceType: AssuranceType) {

        SVProgressHUD.show()

        let completion = { (result: AuthDataResult?, error: Error?) -> Void in
            if result?.user != nil {
                switch action {
                case .createUser:
                    SVProgressHUD.showSuccess(withStatus: "User created")
                case .signIn:
                    SVProgressHUD.showSuccess(withStatus: "User signed in")
                }
            } else if let error = error {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            } else {
                SVProgressHUD.dismiss()
            }
        }

        let progressCallback = { (progress: IProovProgress) in
            SVProgressHUD.showProgress(Float(progress.progress), status: progress.message)
        }

        let options = Options()
        options.title = "Firebase Auth Example"

        switch action {
        case .createUser:
            Auth.iProov().createUser(withUserID: userIDTextField.text!,
                                     assuranceType: assuranceType,
                                     options: options,
                                     progressCallback: progressCallback,
                                     completion: completion)
        case .signIn:
            Auth.iProov().signIn(withUserID: userIDTextField.text!,
                                 assuranceType: assuranceType,
                                 options: options,
                                 progressCallback: progressCallback,
                                 completion: completion)
        }

    }

}
