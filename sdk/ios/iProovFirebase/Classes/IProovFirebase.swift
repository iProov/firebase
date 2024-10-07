//
//  Firebase.swift
//  iProovFirebase
//
//  Created by Jonathan Ellis on 20/12/2023.
//

import Foundation
import iProov
import FirebaseFunctions
import FirebaseCore
import FirebaseAuth

public typealias IProovProgressCallback = (IProovProgress) -> Void
public typealias AuthCallback = (AuthDataResult?, Error?) -> Void

public enum AssuranceType: String {
    case genuinePresence = "genuine_presence"
    case liveness = "liveness"
}

enum ClaimType: String {
    case enrol, verify
}

public struct IProovFailure: Error {
    public let result: FailureResult
}

public struct IProovPrivacyPolicyDeclined: Error {}

public struct IProovProgress {
    public let progress: Double
    public let message: String
}

public final class IProovAuth {

    private let auth: Auth
    private let functions: Functions
    private let extensionID: String
    
    init(app: FirebaseApp? = FirebaseApp.app(),
         region: String = "us-central1",
         extensionID: String = "auth-iproov") {
        
        guard let app = app else {
            fatalError("No Firebase app configured")
        }
        
        self.auth = Auth.auth(app: app)
        self.functions = Functions.functions(app: app, region: region)
        self.extensionID = extensionID
    }
    
    public func createUser(withUserID userID: String,
                           assuranceType: AssuranceType = .genuinePresence,
                           options: Options? = nil,
                           progressCallback: IProovProgressCallback? = nil,
                           completion: AuthCallback?) {
        
        getTokenAndLaunchIProov(userID: userID,
                 claimType: ClaimType.enrol,
                 assuranceType: assuranceType,
                 options: options,
                 progressCallback: progressCallback,
                 completion: completion)
    }
    
    public func signIn(withUserID userID: String,
                       assuranceType: AssuranceType = .genuinePresence,
                       options: Options? = nil,
                       progressCallback: IProovProgressCallback? = nil,
                       completion: AuthCallback?) {
        
        getTokenAndLaunchIProov(userID: userID,
                 claimType: ClaimType.verify,
                 assuranceType: assuranceType,
                 options: options,
                 progressCallback: progressCallback,
                 completion: completion)
        
    }
    
    private func getTokenAndLaunchIProov(userID: String,
                                         claimType: ClaimType,
                                         assuranceType: AssuranceType,
                                         options: Options?,
                                         progressCallback: IProovProgressCallback?,
                                         completion: AuthCallback?) {

        functions.httpsCallable("ext-\(extensionID)-getToken").call([
            "userId": userID,
            "claimType": claimType.rawValue,
            "assuranceType": assuranceType.rawValue,
        ]) { result, error in
            
            if let error = error {
                completion?(nil, error)
                return
            }
            
            let response = result!.data as! Dictionary<String, Any>
            
            let region = response["region"] as! String
            let token = response["token"] as! String

            let launchIProovWithParameters = {
                self.launchIProov(region: region,
                                  token: token,
                                  userID: userID,
                                  claimType: claimType,
                                  options: options,
                                  progressCallback: progressCallback,
                                  completion: completion)
            }

            if let privacyPolicyURLString = response["privacyPolicyUrl"] as? String,
               let privacyPolicyURL = URL(string: privacyPolicyURLString) {

                let viewController = PrivacyPolicyViewController(url: privacyPolicyURL) { accepted in
                    if accepted {
                        launchIProovWithParameters()
                    } else {
                        completion?(nil, IProovPrivacyPolicyDeclined())
                    }
                }

                viewController.presentModally()
            } else {
                launchIProovWithParameters()
            }
        }
    }
    
    private func validate(userID: String,
                          token: String,
                          claimType: ClaimType,
                          completion: AuthCallback?) {
        
        functions.httpsCallable("ext-\(extensionID)-validate").call([
            "userId": userID,
            "token": token,
            "claimType": claimType.rawValue
        ]) { result, error in
                
            if let error = error {
                completion?(nil, error)
                return
            }

            let jwt = result!.data as! String
            self.auth.signIn(withCustomToken: jwt, completion: completion)
        }
    }

    private func launchIProov(region: String,
                              token: String,
                              userID: String,
                              claimType: ClaimType,
                              options: Options?,
                              progressCallback: IProovProgressCallback?,
                              completion: AuthCallback?) {

        IProov.launch(streamingURL: URL(string: "wss://\(region).rp.secure.iproov.me/ws")!,
                      token: token,
                      options: options ?? Options()) { status in

            switch status {
            case .connecting:
                break // Do nothing

            case .connected:
                break // Do nothing

            case let .processing(progress, message):
                progressCallback?(IProovProgress(progress: progress, message: message))

            case let .error(error):
                completion?(nil, error)

            case .canceled:
                completion?(nil, nil)

            case let .failure(reason):
                completion?(nil, IProovFailure(result: reason))

            case .success:
                self.validate(userID: userID,
                              token: token,
                              claimType: claimType,
                              completion: completion)
            }
        }
    }

}

public extension Auth {
    
    static func iProov(app: FirebaseApp? = FirebaseApp.app(),
                       region: String = "us-central1",
                       extensionID: String = "auth-iproov") -> IProovAuth {
        
        return IProovAuth(app: app, region: region, extensionID: extensionID)
    }
    
}
