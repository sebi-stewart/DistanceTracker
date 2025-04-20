//
//  ContactRetrievalService.swift
//  DistanceTracker
//
//  Created by Sebastian Stewart on 16/03/2025.
//

import SwiftUI
import CoreData
import Contacts

struct ContactView: View {
    @State var contacts = [CNContact]()
    @State var selectedUser: Int = 0
    let iconDiameter: CGFloat = 40
    
    @Environment(\.managedObjectContext) private var viewContext
    @State var isTrusted: Bool? = nil
    @State var anyTrusted: Bool = false
    
    @StateObject private var coreDataStack = CoreDataStack.shared
    
    var body: some View{
        Section {
            Picker(selection: $selectedUser){
                ForEach(Array(contacts.enumerated()), id: \.element) { (index, contactDetail) in
                    Text("\(contactDetail.givenName) \(contactDetail.familyName)")
                        .tag(index)
                }
            } label: {
                Text("Partner")
            }
            .onChange(of: selectedUser) {
                setTrustedStatus(trusted: checkTrustedUser())
            }
        }
        .onAppear(){
            getContactList()
            anyTrusted = !coreDataStack.checkUsersTableEmpty()
        }
        .onChange(of: isTrusted){
            if isTrusted != nil && isTrusted!{
                anyTrusted = true
            } else {
                anyTrusted = !coreDataStack.checkUsersTableEmpty()
            }
        }
        Section {
            if selectedUser != 0 {
                PartnerStack
            } else {
                printAndReturnObject()
            }
        }
        if anyTrusted {
            Section {
                Button (action:untrustAllUsers){
                    Text("Untrust All Users")
                }
            }
        }

    }
    
    private var PartnerStack: some View {
        VStack{
            HStack {
                let selected = contacts[selectedUser]
                Section{
                    let avatar = getContactImage(selected)
                    if avatar != nil {
                        avatar!
                            .resizable()
                            .clipShape(Circle())
                            .padding(.all,2)
                            .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                            .scaledToFit()
                            .frame(width: iconDiameter, height: iconDiameter, alignment: .center)
                    } else {
                        let initials = String(selected.givenName.first!) + String(selected.familyName.first!)
                        ZStack {
                            Circle().frame(width: iconDiameter, height: iconDiameter)
                            Text(initials).foregroundStyle(Color(UIColor.white))
                        }
                    }
                }
                Spacer().frame(width: 12)
                Text("\(selected.givenName) \(selected.familyName)")
            }
            if self.isTrusted != nil {
                if self.isTrusted! {
                    Button (action:untrustUser){
                        Text("Untrust User")
                    }
                } else {
                    Button (action:trustUser){
                        Text("Trust User")
                    }
                }
            }
        }
    }
    
    var people: [NSManagedObject] = []
    
    func trustUser(){
        let selected = contacts[selectedUser]
        let id: UUID = selected.id
        let trustedUser = coreDataStack.createUser()
        trustedUser.userId = id
        
//        print("Got our user Id, saving ...")
        
        coreDataStack.save()
        
//        print("Saved our newly trusted user")
        
        setTrustedStatus(trusted: true)
    }
    
    func untrustUser(){
        let selected = contacts[selectedUser]
        let id: UUID = selected.id
        
        if let results = coreDataStack.searchUsers(userId: id) {
            for user in results {
                coreDataStack.delete(user: user)
            }
        }
        setTrustedStatus(trusted: false)
    }
    
    func untrustAllUsers(){
        coreDataStack.deleteAllUsers()
        selectedUser = 0
        setTrustedStatus(trusted: false)
        anyTrusted = false
//        print("untrustAllUsers - Not implemented Yet")
    }
    
    func setTrustedStatus(trusted: Bool){
        self.isTrusted = trusted
    }
    
    func checkTrustedUser() -> Bool{
        guard selectedUser != 0 else {return false}
        
        let selected = contacts[selectedUser]
        let id: UUID = selected.id
        
        let results = coreDataStack.searchUsers(userId: id)
        
        guard results != nil else { return false }
        let retrievedUser = results!.first
        guard retrievedUser != nil  else { return false}
        return true
    }
    
        
    func getContactImage(_ selectedContact: CNContact!) -> Image? {
//        print("Selected \(selectedContact.familyName)")
        if (selectedContact.imageData != nil){
            return Image(uiImage: UIImage(data: selectedContact.imageData!)!)
        } else if (selectedContact.thumbnailImageData != nil){
            return Image(uiImage: UIImage(data: selectedContact.thumbnailImageData!)!)
        } else {
            return nil
        }
    }
    
    func printAndReturnObject() -> HStack<Text>{
//        print("No selected User")
        return HStack{
            Text("No selected User")
        }
    }
    
    func getContactList() {
        let CNStore = CNContactStore()
        contacts.removeAll()
        contacts.append(CNContact())
        
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:
            do {
                let keys = [CNContactGivenNameKey as CNKeyDescriptor,
                            CNContactFamilyNameKey as CNKeyDescriptor,
                            CNContactImageDataKey as CNKeyDescriptor,
                            CNContactThumbnailImageDataKey as CNKeyDescriptor,
                            CNContactIdentifierKey as CNKeyDescriptor
                ]
                let request = CNContactFetchRequest(keysToFetch: keys)
                try CNStore.enumerateContacts(with: request, usingBlock: {contact, _ in
                    contacts.append(contact)
//                    print("Adding contact")
                })
            } catch {
                print("ERROR - Error on contact fetching\(error)")
            }
        case .denied, .notDetermined, .restricted:
            print("getContactList - Not determined or denied or restricted")
            CNStore.requestAccess(for: .contacts) { granted, error in
                if granted {
                    getContactList()
                } else if let error = error {
                    print("ERROR - Error requesting contact access: \(error)")
                }
            }
        default:
            print("")
        }
    }
}
