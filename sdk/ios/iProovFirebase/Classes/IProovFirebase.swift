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

struct IProovFailure: Error {
    let result: FailureResult
}

public struct IProovProgress {
    let progress: Double
    let message: String
}

extension Auth {
    
    public func createUser(withIProovUserID userID: String,
                           assuranceType: AssuranceType = .genuinePresence,
                           options: Options? = nil,
                           extensionID: String = "auth-iproov",
                           progressCallback: IProovProgressCallback? = nil,
                           completion: AuthCallback?) {
        
        doIProov(userID: userID,
                 claimType: ClaimType.enrol,
                 assuranceType: assuranceType,
                 options: options,
                 extensionID: extensionID,
                 progressCallback: progressCallback,
                 completion: completion)
    }
    
    public func signIn(withIProovUserID userID: String,
                       assuranceType: AssuranceType = .genuinePresence,
                       options: Options? = nil,
                       extensionID: String = "auth-iproov",
                       progressCallback: IProovProgressCallback? = nil,
                       completion: AuthCallback?) {
        
        doIProov(userID: userID,
                 claimType: ClaimType.verify,
                 assuranceType: assuranceType,
                 options: options,
                 extensionID: extensionID,
                 progressCallback: progressCallback,
                 completion: completion)
        
    }
    
    private func doIProov(userID: String,
                          claimType: ClaimType,
                          assuranceType: AssuranceType,
                          options: Options?,
                          extensionID: String,
                          progressCallback: IProovProgressCallback?,
                          completion: AuthCallback?) {
        
        Functions.functions().httpsCallable("ext-\(extensionID)-getToken").call([
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
                                  extensionID: extensionID,
                                  completion: completion)
                }
            }
        }
    }
    
    private func validate(userID: String,
                          token: String,
                          claimType: ClaimType,
                          extensionID: String,
                          completion: AuthCallback?) {
        
        Functions.functions().httpsCallable("ext-\(extensionID)-validate").call([
            "userId": userID,
            "token": token,
            "claimType": claimType.rawValue
        ]) { result, error in
                
            if let error = error {
                completion?(nil, error)
                return
            }

            let jwt = result!.data as! String
            Auth.auth().signIn(withCustomToken: jwt, completion: completion)
        }
    }
}
