//
//  ContactRetrievalService.swift
//  DistanceTracker
//
//  Created by Sebastian Stewart on 16/03/2025.
//

import SwiftUI
import CoreData
import Contacts
import Combine

struct ContactView: View {
    @StateObject var contactRetrievalService = ContactRetrievalService.shared
    @StateObject private var coreDataStack = CoreDataStack.shared

    @State var tokens: Set<AnyCancellable> = []

    @State var contacts = [CNContact]()
    @State var selectedUser: Int = 0
    let iconDiameter: CGFloat = 40
    
    @State var isTrusted: Bool? = nil
    @State var anyTrusted: Bool = false
    
    
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
            if selectedUser != 0 {
                PartnerStack
            } else {
                HStack{
                    Text("No selected User")
                }
            }
        }
        .onAppear(){
            observeContactUpates()
            observeContactAccessDenied()
            contactRetrievalService.loadContacts()
            anyTrusted = !coreDataStack.checkUsersTableEmpty()
        }
        .onChange(of: isTrusted){
            if isTrusted != nil && isTrusted!{
                anyTrusted = true
            } else {
                anyTrusted = !coreDataStack.checkUsersTableEmpty()
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
                    contactRetrievalService.getFormattedContactImage(selected, iconDiameter)
                }
                Spacer().frame(width: 12)
                VStack(alignment: .leading){
                    Text("\(selected.givenName) \(selected.familyName)")
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
            
        }
    }
    
    var people: [NSManagedObject] = []
    
    func trustUser(){
        let selected = contacts[selectedUser]
        let id: UUID = selected.id
        let trustedUser = coreDataStack.createUser()
        trustedUser.userId = id
        
        coreDataStack.save()
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
    
    func observeContactUpates() {
        contactRetrievalService.contactsPublisher
            .receive(on: DispatchQueue.main)
            .sink {completion in
                if case .failure(let error) = completion {
                    print(error)
                }
            } receiveValue: { contacts in
                self.contacts = contacts
            }
            .store(in : &tokens)
    }
    
    func observeContactAccessDenied() {
        contactRetrievalService.deniedContactAccessPublisher
            .receive(on: DispatchQueue.main)
            .sink {
                print("Show some kind of alert to the user for contact access denied")
            }
            .store(in: &tokens)
    }
}
