//
//  LoginPageView.swift
//  DistanceTracker
//
//  Created by Sebastian Stewart on 23/07/2025.
//

import SwiftUI
import Combine
import Darwin

struct LoginPageView: View{
    @State private var emailField: String = ""
    @State private var passwordField: String = ""
    
    @AppStorage("loggedIn") private var loggedIn = false
    
    var body: some View {
        Form {
            TextField("Email", text: $emailField)
            TextField("Password", text: $passwordField)
            Button(action: login) {
                Text("Login")
            }
        }
    }
    
    func login(){
        let loginBody = ["email": emailField, "password": passwordField] as Dictionary<String, String>
        
        var request = URLRequest(url: URL(string: "http://localhost:65300/login")!)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: loginBody, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
            print(response!)
            
            guard let httpResponse = response as? HTTPURLResponse else { self.loggedIn = false; return}
            guard httpResponse.statusCode == 200 else { self.loggedIn = false; return }

            do {
                let json = try JSONSerialization.jsonObject(with: data!) as! Dictionary<String, AnyObject>
                print(json)
                self.loggedIn = true
                
            } catch {
                print("error", error)
                self.loggedIn = false
            }
            
        })
        
        task.resume()
    }
}
