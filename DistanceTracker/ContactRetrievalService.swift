//
//  ContactRetrievalService.swift
//  DistanceTracker
//
//  Created by Sebastian Stewart on 20/04/2025.
//

import SwiftUI
import CoreData
import Contacts
import Combine

class ContactRetrievalService: NSObject, ObservableObject {
    var contacts = [CNContact]()
    
    var contactsPublisher = PassthroughSubject<[CNContact], Error>()
    var deniedContactAccessPublisher = PassthroughSubject<Void, Never>()

    
    private override init(){
        super.init()
    }
    
    static let shared = ContactRetrievalService()
    
    func getContacts() -> [CNContact]{
        return contacts
    }
    
    private func getContactImage(_ selectedContact: CNContact!) -> Image? {
        if (selectedContact.imageData != nil){
            return Image(uiImage: UIImage(data: selectedContact.imageData!)!)
        } else if (selectedContact.thumbnailImageData != nil){
            return Image(uiImage: UIImage(data: selectedContact.thumbnailImageData!)!)
        } else {
            return nil
        }
    }
    
    func getFormattedContactImage(_ selected: CNContact!, _ iconDiameter: CGFloat!) -> AnyView {
        let avatar = self.getContactImage(selected)
        if avatar != nil {
            return AnyView(avatar!
                    .resizable()
                    .clipShape(Circle())
                    .padding(.all,2)
                    .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                    .scaledToFit()
                    .frame(width: iconDiameter, height: iconDiameter, alignment: .center))
        } else {
            let initials = String(selected.givenName.first!) + String(selected.familyName.first!)
            return AnyView (ZStack {
                Circle().frame(width: iconDiameter, height: iconDiameter)
                Text(initials).foregroundStyle(Color(UIColor.white))
            })
        }
    }
    
    private func checkAuthorization(_ CNStore: CNContactStore) -> Bool{
        var accessGranted = false
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:
            accessGranted = true
        case .denied, .notDetermined, .restricted:
            CNStore.requestAccess(for: .contacts) { granted, error in
                if granted {
                    self.loadContacts()
                } else if let error = error {
                    self.deniedContactAccessPublisher.send()
                    print("ERROR - Error requesting contact access: \(error)")
                }
            }
        default:
            self.deniedContactAccessPublisher.send()
            print("ContactRetrievalService - Unexpected case")
        }
        
        return accessGranted
    }
    
    
    func loadContacts() {
        let CNStore = CNContactStore()
        self.contacts.removeAll()
        self.contacts.append(CNContact())
        
        guard (self.checkAuthorization(CNStore)) else { return }

        do {
            let keys = [CNContactGivenNameKey as CNKeyDescriptor,
                        CNContactFamilyNameKey as CNKeyDescriptor,
                        CNContactImageDataKey as CNKeyDescriptor,
                        CNContactThumbnailImageDataKey as CNKeyDescriptor,
                        CNContactIdentifierKey as CNKeyDescriptor
            ]
            self.contacts += try CNStore.unifiedContacts(matching: NSPredicate(value: true), keysToFetch: keys)
            self.contactsPublisher.send(self.contacts)
        } catch {
            print("ERROR - Error on contact fetching\(error)")
            self.contactsPublisher.send(completion: .failure(error))
        }
    }
}
