//
//  LoginView.swift
//  iosStudia
//
//  Created by 이종우 on 2022/01/06.
//

import SwiftUI
import Firebase
import GoogleSignIn

struct LoginView: View {
    @State var email: String = ""
    @State var password: String = ""
    @State var isLoggedIn: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("나만의\n독창적인 공부\n스타일 찾기")
                .font(Font.custom("NanumSquare_ac Bold", size: 40))
                .padding(.bottom, 30)
            
            Text("이메일 주소")
                .font(.caption)
                .padding(.leading, 15)
            HStack {
                TextField("email@example.com", text: $email)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .padding(.leading, 15)
            }
            .frame(height: 40)
            .background(Color("TextFieldBgColor"))
            .cornerRadius(20)
            .padding(.bottom, 10)
            
            Text("비밀번호")
                .font(.caption)
                .padding(.leading, 15)
            HStack {
                SecureField("• • • • • • • •", text: $password)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .padding(.leading, 15)
            }
            .frame(height: 40)
            .background(Color("TextFieldBgColor"))
            .cornerRadius(20)
            .padding(.bottom, 10)
            
            HStack {
                Button(action: {
                    if let url = URL(string: "https://studia.blue/signup") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("계정 만들기")
                        .font(.body)
                        .foregroundColor(Color.black)
                }
                .frame(height: 30)
                
                Spacer()
                
                Button(action: {
                    if let url = URL(string: "https://studia.blue/iforgot") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("비밀번호 찾기")
                        .font(.body)
                        .foregroundColor(Color.black)
                }
                .frame(height: 30)
            }
            .padding(10)
            
            Button(action: {
                Auth.auth().signIn(withEmail: email, password: password) {(user, error)in
                    if(user != nil) {
                        // Logged in
                        print("--> Logged in as \(Auth.auth().currentUser?.email ?? "no user")")
                        isLoggedIn = true
                    } else {
                        // Login failed
                        print("--> Failed to Log In With Email and Password")
                    }
                }
            }) {
                Text("로그인")
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .frame(height: 40, alignment: .center)
            }
            .background(Color("ThemeColor"))
            .foregroundColor(Color.white)
            .cornerRadius(10)
            
            Button(action: {
                guard let clientID = FirebaseApp.app()?.options.clientID else { return }
                let config = GIDConfiguration(clientID: clientID)
                
                // Start Signin flow
                GIDSignIn.sharedInstance.signIn(with: config, presenting: (UIApplication.shared.windows.first?.rootViewController)!) { user, error in
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }
                    
                    guard
                        let authentication = user?.authentication,
                        let idToken = authentication.idToken
                    else {
                        return
                    }
                    
                    let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: authentication.accessToken)
                    
                    // Firebase Auth with Credential
                    Auth.auth().signIn(with: credential) { (authResult, error) in
                        if let error = error {
                            print("--> Error While Google Login: \(error.localizedDescription)")
                            return
                        }
                        
                        // Signed in. Woohoo!
                        isLoggedIn = true
                    }
                }
            }) {
                Image("google_login")
                    .resizable()
                    .frame(width: 25, height: 25)
                
                Text("Google 계정으로 로그인")
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .frame(height: 40, alignment: .center)
            .background(Color("BgColor"))
            .cornerRadius(10)
            .foregroundColor(Color("TextColor"))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color("ThemeColor"), lineWidth: 2)
            )
            .padding(.top, 5)
        }
        .frame(minWidth: 0, maxWidth: 500)
        .padding()
        .navigate(to: CalendarView(), when: $isLoggedIn)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}

extension View {
    func navigate<NewView: View>(to view: NewView, when binding: Binding<Bool>) -> some View {
        NavigationView {
            ZStack {
                self
                    .navigationBarTitle("")
                    .navigationBarHidden(true)
                
                NavigationLink(
                    destination: view
                        .navigationBarTitle("")
                        .navigationBarHidden(true),
                    isActive: binding
                ) {
                    EmptyView()
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}
