//
//  LoginViewController.swift
//  HandyChattingApp
//
//  Created by 황신택 on 2021/12/17.
//

import UIKit
import FirebaseAuth
import GoogleSignIn
import Firebase
import AuthenticationServices
import CryptoKit
import KakaoSDKAuth
import KakaoSDKCommon
import KakaoSDKUser
import FBSDKLoginKit


/// Social media Login
class LoginViewController: CommonViewController {
    @IBOutlet weak var loginStackView: UIStackView!
    fileprivate var currentNonce: String?
    let manager = LoginManager()
    @IBOutlet weak var emailLoginView: UIView!
    @IBOutlet weak var facebookLoginView: UIView!
    @IBOutlet weak var googleLoginView: UIView!
    @IBOutlet weak var kakaoLoginView: UIView!
    @IBOutlet weak var appleLoginView: UIView!
    
    
    /// User can sigin-in using registered email
    @IBAction func signUpDidTouch(_ sender: Any) {
        let alert = UIAlertController(title: "SignIn", message: "please enter your email and password", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Access", style: .default) { _ in
            guard let emailField = alert.textFields?.first,
                  let passwordField = alert.textFields?.last,
                  let emailFieldText = emailField.text,
                  let passwordFieldText = passwordField.text,
                  // once passing email try to validate
                  self.isEmailValid(emailFieldText),
                  self.isPasswordValid(passwordFieldText) else {
                      self.alert(message: "please check your email form or password form")
                      return
                  }
            
            Auth.auth().signIn(withEmail: emailFieldText, password: passwordFieldText) { _, error in
                if let error = error {
#if DEBUG
                    print(error.localizedDescription)
#endif
                }
            }
        }
        
        alert.addAction(okAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        
        alert.addTextField { textEmail in
            textEmail.text = "Enter your email"
            textEmail.clearButtonMode = .always
        }
        
        alert.addTextField { password in
            password.isSecureTextEntry = true
            password.placeholder = "Enter your password"
        }
        
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    
    /// User can sign-in using google account
    @IBAction func signInGoogle(_ sender: Any) {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { [unowned self] user, error in
            if let error = error {
                alert(message: error.localizedDescription)
                return
            }
            
            // get google account profile information and idtoken.
            guard
                let authentication = user?.authentication,
                let idToken = authentication.idToken,
                let name = user?.profile?.name,
                let email = user?.profile?.email,
                let photoUrl = user?.profile?.imageURL(withDimension: 320)
            else {
                return
            }
            
            // create credential
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: authentication.accessToken)
            
            Auth.auth().signIn(with: credential) { userInfo, error in
                if let error = error {
                    alert(message: error.localizedDescription)
                }
                
                // check whether already exist email or not in firebase
                DataManager.shared.userExists(with: email) { exist in
                    if !exist {
                        // if not exist make new Document in firestore collection
                        DataManager.shared.createNewUserDocument(name: name, email: email, photoUrl: photoUrl.absoluteString)
                    }
                }
                
                // save display name
                AppSettings.displayName = name
            }
        }
    }
    
    
    /// User can sign-in kakao account
    @IBAction func signInKakao(_ sender: Any) {
        //
        UserApi.shared.loginWithKakaoAccount {(oauthToken, error) in
            if let error = error {
                print(error)
            }
            else {
                print("loginWithKakaoAccount() success.")
                
                if let  _ = oauthToken {
                    // check token exist or not
                    if (AuthApi.hasToken()) {
                        UserApi.shared.accessTokenInfo { (_, error) in
                            if let error = error {
                                if let sdkError = error as? SdkError, sdkError.isInvalidTokenError() == true  {
                                    // need lgoin
                                    self.alert(message: sdkError.localizedDescription)
                                }
                                else {
                                    // etc.. error
                                    self.alert(message: "카카오에 로그인 할 수 없습니다.")
                                }
                            }
                            else {
                                print("토큰 유효성 체크 성공(필요 시 토큰 갱신됨")
                                
                                UserApi.shared.me() {[weak self](user, error) in
                                    guard let self = self else { return }
                                    if let error = error {
                                        print(error)
                                    }
                                    else {
                                        print("me() success.")
                                        if let user = user,
                                           let id = user.id,
                                           let email = user.kakaoAccount?.email,
                                           let nickName = user.kakaoAccount?.profile?.nickname,
                                           let imageUrl = user.kakaoAccount?.profile?.profileImageUrl
                                        {
                                            AppSettings.displayName = nickName
                                            
                                            // firebase not support kakaotalk athentication, so make should first createUser and then implement sign-in
                                            Auth.auth().createUser(withEmail: email,
                                                                   password: String(id))
                                            { _, _ in
                                                DataManager.shared.createNewUserDocument(name: nickName, email: email, photoUrl: imageUrl.absoluteString)
                                            }
                                            
                                            Auth.auth().signIn(withEmail: email,
                                                               password: String(id),
                                                               completion:  {_, _ in })
                                                
                                        }
                                    }
                                }
                            }
                        }
                    }
                    else {
                        self.alert(message: "로그인이 만료되었습니다. 다시 로그인 해 주세요.")
                    }
                }
            }
        }
    }
    
    
    /// User can sigin-in fackbook account
    @IBAction func FbSignIn(_ sender: Any) {
        manager.logIn(permissions: ["public_profile", "email"], from: self) { result, error in
            if let error = error {
                print(error)
                return
            }
            
            if let result = result {
                if result.isCancelled {
                    print("사용자가 취소함")
                } else {
                    if let token = AccessToken.current {
                        let credential = FacebookAuthProvider
                            .credential(withAccessToken: token.tokenString)
                        Auth.auth().signIn(with: credential) {[weak self] userInfo, error in
                            guard let self = self else { return }
                            if let error = error {
                                self.alert(message: error.localizedDescription)
                            }
                            print("페이스북 로그인 성공")
                            let request = GraphRequest(graphPath: "me", parameters: ["fields": "id, name, email, picture.width(480).height(480)"])
                            request.start { connection, result, error in
                                if let error = error {
                                    print(error)
                                    return
                                }
                                
                                if let result = result as? [String: Any] {
                                    guard let name = result["name"] as? String else { return }
                                    guard let email = result["email"] as? String else { return }
                                    guard let profile = result["picture"] as? [String: Any],
                                          let data = profile["data"] as? [String: Any],
                                          let url = data["url"] as? String else { return }
                                    
                                    AppSettings.displayName = name
                                    
                                    DataManager.shared.userExists(with: email) { exist in
                                        if !exist {
                                            DataManager.shared.createNewUserDocument(name: name, email: email, photoUrl: url)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        [emailLoginView, facebookLoginView, googleLoginView, kakaoLoginView, appleLoginView].forEach {
            $0?.layer.cornerRadius = 30
            $0?.clipsToBounds = true
        }
        
    }
    
    
    /// User can sigin-in apple account
    /// Start Apple's login process by including a delegate that processes Apple's response and nonce's SHA256 hash in your request.
    @IBAction func handleAppleLogin(_ sender: Any) {
        let nonce = randomNonceString()
        currentNonce = nonce
        let idProvider = ASAuthorizationAppleIDProvider() // get my id
        let request = idProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
}

/// Implement the ASAuthorizationControllerDelegate to process Apple's responses.
extension LoginViewController: ASAuthorizationControllerDelegate {
    /// if occur signin error call this method
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        alert(message: error.localizedDescription)
    }
    
    ///If you have succeeded in logging in, authenticate to Firebase using an ID token in Apple's response with nonhashed nonce.
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
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
            Auth.auth().signIn(with: credential) {[weak self] (authResult, error) in
                guard let self = self else { return }
                if let error = error {
                    self.alert(message: error.localizedDescription)
                    return
                }
                
                if let email = appleIDCredential.email,
                   let name = appleIDCredential.fullName?.givenName {
                    DataManager.shared.createNewUserDocument(name: name, email: email, photoUrl: "")
                }
            }
        }
    }
}


extension LoginViewController: ASAuthorizationControllerPresentationContextProviding {
    /// once didtap apple login button make present view
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}


extension LoginViewController {
    ///. Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
    /// Each login request generates an arbitrary string, 'nonce', which is used to verify that an ID token has been explicitly granted in response to the app's authentication request. This step is required to prevent retransmission attacks.
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: Array<Character> =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
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
    
    /// If you send nonce's SHA256 hash with a login request, Apple will forward the original value in response. Firebase hashes the original nonce and compares it with the value delivered by Apple to verify the response.
    @available(iOS 13, *)
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

