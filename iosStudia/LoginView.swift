import SwiftUI
import SafariServices
import Firebase
import GoogleSignIn
import CryptoKit
import AuthenticationServices

struct LoginView: View {
    @State private var isLoggedIn: Bool = false     // Navigate to CalendarView when true
    @State private var loginFailed: Bool = false    // Show "login failed" popup
    @State private var showSignUpSheet: Bool = false
    @State private var showIforgotSheet: Bool = false
    @State fileprivate var currentNonce: String?
    
    @Environment(\.colorScheme) var colorScheme
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError(
                        "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
                    )
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationLink(destination: CalendarView().accentColor(.white), isActive: $isLoggedIn) { EmptyView() }
            
            Text("studia")
                .font(Font.custom("Courgette Regular", size: 40))
                .foregroundColor(Color("ThemeColor"))
            
            Text("시작하기")
                .font(Font.custom("NanumSquare_ac Bold", size: 50))
                .padding(.bottom, 100)
            
            NavigationLink(destination: PWLoginView()) {
                Label("이메일, 비밀번호로 로그인", systemImage: "key.fill")
                    .font(.system(size: 17, weight: .medium))
                    .frame(minWidth: 0, maxWidth: .infinity)
            }
            .frame(height: 45, alignment: .center)
            .background(Color("LoginBtnColor"))
            .foregroundColor(Color.white)
            .cornerRadius(10)
            
            Button(action: {
                guard let clientID = FirebaseApp.app()?.options.clientID else { return }
                let config = GIDConfiguration(clientID: clientID)
                
                // Start Signin flow
                GIDSignIn.sharedInstance.signIn(with: config, presenting: (UIApplication.shared.windows.first?.rootViewController)!) { user, error in
                    if error != nil { return }
                    
                    guard
                        let authentication = user?.authentication,
                        let idToken = authentication.idToken
                    else { return }
                    
                    let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: authentication.accessToken)
                    
                    // Firebase Auth with Credential
                    Auth.auth().signIn(with: credential) { (authResult, error) in
                        if error != nil { return }
                        
                        // Signed in successfully
                        isLoggedIn = true
                    }
                }
            }) {
                Label{
                    Text("Google로 로그인")
                        .font(.system(size: 17, weight: .medium))
                } icon: {
                    Image("google_login")
                        .resizable()
                        .frame(width: 17, height: 17)
                }
                .frame(minWidth: 0, maxWidth: .infinity)
            }
            .frame(height: 45, alignment: .center)
            .background(Color("BgColor"))
            .cornerRadius(10)
            .foregroundColor(Color("TextColor"))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color("ThemeColor"), lineWidth: 2)
            )
            .padding(.top, 5)
            
            SignInWithAppleButton(.signIn, onRequest: AppleIDSignInConfigure, onCompletion: AppleIDSignInHandle)
                .signInWithAppleButtonStyle(
                    colorScheme == .dark ? .white : .black
                )
                .frame(minWidth: 0, maxWidth: .infinity)
                .frame(height: 45, alignment: .center)
                .cornerRadius(10)
                .padding(.top, 5)
        }
        .frame(minWidth: 0, maxWidth: 500)
        .padding()
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .alert(isPresented: $loginFailed) {
            Alert(title: Text("로그인 실패"),
                  message: Text("로그인 중 문제가 발생하였습니다."),
                  dismissButton: .default(Text("확인"))
            )
        }
    }
    
    func AppleIDSignInConfigure(request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.email]
        request.nonce = sha256(nonce)
    }
    
    func AppleIDSignInHandle(authResult: Result<ASAuthorization, Error>) {
        switch authResult {
        case .success(let auth):
            print(auth)
            if let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential {
                guard let nonce = currentNonce else {
                    fatalError("Invalid state: A login callback was received, but no login request was sent.")
                }
                guard let appleIDToken = appleIDCredential.identityToken else {
                    print("Unable to fetch identity token")
                    return
                }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                    return
                }
                // Initialize a Firebase credential.
                let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                          idToken: idTokenString,
                                                          rawNonce: nonce)
                // Sign in with Firebase.
                Auth.auth().signIn(with: credential) { (authResult, error) in
                    if error != nil { return }
                    
                    // Signed in successfully
                    isLoggedIn = true
                }
            } else { print("error!") }
            
        case .failure(let error):
            print(error)
        }
    }
}

struct PWLoginView: View {
    @State private var email: String = ""           // User input for email
    @State private var password: String = ""        // User input for password
    @State private var loading: Bool = false        // Show spinner when true
    @State private var isLoggedIn: Bool = false     // Navigate to CalendarView when true
    @State private var loginFailed: Bool = false    // Show "login failed" popup
    @State private var showSignUpSheet: Bool = false
    @State private var showIforgotSheet: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            NavigationLink(destination: LoginFinishedView(), isActive: $isLoggedIn) { EmptyView() }
            
            Text("이메일 주소")
                .font(.caption)
                .padding(.leading, 15)
            
            HStack {
                TextField("email@example.com", text: $email)
                    .disableAutocorrection(true)
                    .keyboardType(.emailAddress)
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
                    self.showSignUpSheet = true
                }) {
                    Text("계정 만들기")
                        .font(.body)
                        .foregroundColor(Color("TextColor"))
                }
                .frame(height: 30)
                .sheet(isPresented: $showSignUpSheet) {
                    SafariView(url:URL(string: "https://studia.blue/signup")!)
                        .edgesIgnoringSafeArea(.bottom)
                }
                
                Spacer()
                
                Button(action: {
                    self.showIforgotSheet = true
                }) {
                    Text("비밀번호 찾기")
                        .font(.body)
                        .foregroundColor(Color("TextColor"))
                }
                .frame(height: 30)
                .sheet(isPresented: $showIforgotSheet) {
                    SafariView(url:URL(string: "https://studia.blue/iforgot")!)
                        .edgesIgnoringSafeArea(.bottom)
                }
            }
            .padding(10)
            
            Button(action: {
                self.loading = true
                Auth.auth().signIn(withEmail: email, password: password) {(user, error)in
                    if(user != nil) {
                        // Logged in
                        self.isLoggedIn = true
                    } else {
                        // Login failed, show alert
                        self.loading = false
                        self.loginFailed = true
                    }
                }
            }) {
                if self.loading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(minWidth: 0, maxWidth: .infinity)
                } else {
                    Text("로그인")
                        .font(.system(size: 17, weight: .medium))
                        .frame(minWidth: 0, maxWidth: .infinity)
                }
            }
            .frame(height: 45, alignment: .center)
            .background(Color("ThemeColor"))
            .foregroundColor(Color.white)
            .cornerRadius(10)
        }
        .padding()
        .navigationTitle("로그인")
        .navigationBarTitleDisplayMode(.large)
        .alert(isPresented: $loginFailed) {
            Alert(title: Text("로그인 실패"),
                  message: Text("가입되지 않은 아이디이거나 비밀번호가 잘못되었습니다."),
                  dismissButton: .default(Text("확인"))
            )
        }
    }
}

struct LoginFinishedView: View {
    @State private var go: Bool = false
    
    var body: some View {
        VStack {
            NavigationLink(destination: CalendarView().accentColor(.white), isActive: $go) { EmptyView() }
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            self.go = true
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) { }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { LoginView() }
        NavigationView { PWLoginView() }
    }
}
