//
//  Contact.swift
//  ContactList
//
//  Created by Prearo, Andrea on 3/5/16.
//  Copyright © 2016 Prearo, Andrea. All rights reserved.
//

import Foundation
import Alamofire
import Locksmith

class Contact {
    
    let avatar: String?
    let firstName: String?
    let lastName: String?
    let company: String?
    let phone: [String]?
    let email: [String]?
    let location: [Location?]?

    init?(avatar: String?,
        firstName: String?,
        lastName: String?,
        company: String?,
        phone: [String]?,
        email: [String]?,
        location: [Location?]?) {
        self.avatar = avatar
        self.firstName = firstName
        self.lastName = lastName
        self.company = company
        self.phone = phone
        self.email = email
        self.location = location
    }
    
    class func getAll(completionBlock: (success: Bool, contacts: [Contact?]?, error: NSError?) -> ()) {
        let account = AuthorizedUser.loadFromStore()
        if account.isFailure {
            completionBlock(success: false, contacts: nil, error: account.error)
            return
        }

        guard let token = account.value?.token else {
            completionBlock(success: false, contacts: nil, error: ErrorCodes.InvalidToken())
            return
        }

        Alamofire.request(
            .GET,
            WebServiceConstants.Contacts,
            headers: [WebServiceConstants.TokenHeader: token])
        .responseJSON { response in
            if let error = WebService.verifyAuthenticationErrors(response) {
                completionBlock(success: false, contacts: nil, error: error)
                return
            }
            
            guard response.result.isSuccess else {
                if let error = response.result.error {
                    completionBlock(success: false, contacts: nil, error: error)
                } else {
                    completionBlock(success: false, contacts: nil, error: nil)
                }
                return
            }

            guard let jsonResponse = response.result.value as? [[String: AnyObject]] else {
                completionBlock(success: false, contacts: nil, error: nil)
                return
            }

            let contacts = jsonResponse.map({
                return Contact.decode($0)
            })

            completionBlock(success: true, contacts: contacts, error: nil)
        }
    }
    
}

extension Contact {
    
    static func decode(json: [String: AnyObject]) -> Contact? {
        let avatar = json["avatar"] as? String
        let firstName = json["firstName"] as? String
        let lastName = json["lastName"] as? String
        let company = json["company"] as? String
        let phone = json["phone"] as? [String]
        let email = json["email"] as? [String]
        let locationArray = json["location"] as? [[String: AnyObject]]
        let location = locationArray.map {
            Location.decode($0)
        }
        return Contact(avatar: avatar,
            firstName: firstName,
            lastName: lastName,
            company: company,
            phone: phone,
            email: email,
            location: location)
    }
    
}
