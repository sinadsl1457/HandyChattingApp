//
//  ChattingViewController.swift
//  HandyChattingApp
//
//  Created by 황신택 on 2021/12/21.
//

import UIKit
import Firebase
import MessageKit
import InputBarAccessoryView
import FirebaseFirestore
import Photos
import PhotosUI
import SDWebImage
import KakaoSDKCommon
import KakaoSDKTalk
import GoogleUtilities

/// Viewcontroller that show chats
class ChattingViewController: MessagesViewController {
    /// When uploading photo to server and download url,  make to disable inputbar
    private var isSendingPhoto = false {
        didSet {
            messageInputBar.leftStackViewItems.forEach { item in
                guard let item = item as? InputBarButtonItem else { return }
                item.isEnabled = !self.isSendingPhoto
            }
        }
    }
    private let storage = Storage.storage().reference()
    private let currentUser: User
    private var channel: Users
    private var messages: [Message] = []
    private var messageListener: ListenerRegistration?
    private let database = Firestore.firestore()
    let pushNotification = PushNotificationSender()
    
    /// Set outcomingMessage referecne that chat room path in firestore
    private var outcomingReference: CollectionReference {
        return database.collection("users/\(path)/thread/\(channel.email)/thread")
    }
    /// Set incomingMessage referecne that chat room path in firestore
    private var incomingReference: CollectionReference {
        return database.collection("users/\(channel.email)/thread/\(path)/thread")
    }
    
    /// make can get to currentUser email absolutely
    /// generally we can get this info from currentUser.email but sometimes it's not working so i made like this.
    private var path: String {
        var path = ""
        currentUser.providerData.forEach {
            if let providerEmail = $0.email {
                path = currentUser.email ?? providerEmail
            }
        }
        return path
    }
    
    private var uiPicker = UIImagePickerController()
    
    var picker: PHPickerViewController = {
        var config = PHPickerConfiguration()
        config.filter = .any(of: [.images, .videos])
        config.selectionLimit = 10
        return PHPickerViewController(configuration: config)
    }()
    
    
    /// whenever make new chatroom or enter through channelList,  pass to this class property and it's can make initilize.
    /// - Parameters:
    ///   - user: currentUser(me)
    ///   - channel: Users(target)
    init(user: User, channel: Users) {
        self.currentUser = user
        self.channel = channel
        super.init(nibName: nil, bundle: nil)
        title = "\(channel.name) 과 대화"
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        removeBadgeCount()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        picker.delegate = self
        uiPicker.delegate = self
        navigationItem.largeTitleDisplayMode = .never
        listenToMessages()
        setUpMessageView()
        configureMessageAvatars()
        addCameraBarButton()
        turnOffNoti()
    }
    
    private func turnOffNoti() {
        let channelRef = database
            .collection("users")
        channelRef.document(path)
            .setData(["noti": false], merge: true)
    }
    
    private func removeBadgeCount() {
        let channelRef = database.collection("users/\(path)/thread")
        channelRef.document(channel.email).getDocument {[weak self] snapsnot, _ in
            guard let self = self else { return }
            guard let data = snapsnot?.data() else { return }
            guard let cnt = data["messageCnt"] as? Int else { return }
            UserDefaults.extensions.badge -= cnt
            UIApplication.shared.applicationIconBadgeNumber -= cnt
            channelRef.document(self.channel.email).setData(["messageCnt": 0],
                                                                    merge: true)
        }
    }
    
    
    /// Whenever changed in outcomingReference, pass doc changes data to handleDocumentChange method.
    private func listenToMessages() {
        messageListener = outcomingReference
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                guard let snapshot = querySnapshot else {
                    print("""
              Error listening for channel updates: \
              \(error?.localizedDescription ?? "No error")
              """)
                    return
                }
                
                snapshot.documentChanges.forEach { change in
                    self.handleDocumentChange(change)
                }
            }
    }
    
    /// Whenever changed in incomingReference, pass doc changes data to handleDocumentChange method.
    private func incomingListenToMessages() {
        messageListener = incomingReference
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                guard let snapshot = querySnapshot else {
                    print("""
              Error listening for channel updates: \
              \(error?.localizedDescription ?? "No error")
              """)
                    return
                }
                snapshot.documentChanges.forEach { change in
                    self.handleDocumentChange(change)
                }
            }
    }
    
    /// Whenever a user delivers a message, it is automatically added to that reference.
    /// - Parameter message: Message
    private func save(_ message: Message) {
        outcomingReference
            .addDocument(data: message.representation) { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    print("Error sending message: \(error.localizedDescription)")
                    return
                }
                self.messagesCollectionView.scrollToLastItem()
            }
    }
    
    /// Whenever a target user received a message, it is automatically added to that reference.
    /// - Parameter message: Message
    private func incomingSave(_ message: Message) {
        incomingReference.addDocument(data: message.representation) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                print("Error sending message: \(error.localizedDescription)")
                return
            }
            self.messagesCollectionView.scrollToLastItem()
        }
    }
    
    deinit {
        messageListener?.remove()
    }
    
    // MARK: - Actions
    @objc private func addPicturePressed() {
        let alert = UIAlertController(title: "choose your desired task.", message: "if you choose library can access your album?", preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "take a picture.", style: .default) { _ in
            self.chooseCameraButton()
        }
        
        alert.addAction(cameraAction)
        
        let libraryAction = UIAlertAction(title: "access your library.", style: .default) { _ in
            self.chooseLibraryButton()
        }
        
        alert.addAction(libraryAction)
        present(alert, animated: true, completion: nil)
    }
    
    
    /// implemented function that can take a picture in user camera and can choose picture in user library.
    /// i used two class that UIImagePickerController, PHPickerViewController for study.
    private func chooseCameraButton() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            uiPicker.sourceType = .camera
        }
        present(uiPicker, animated: true, completion: nil)
    }
    
    private func chooseLibraryButton() {
        present(picker, animated: true, completion: nil)
    }
    
    
    // MARK: - Helpers
    /// When a new message is added to the document, the handle method delivers the message instance.
    /// If the latest message and bottom of the collection view are conditions is true, scroll to the last item.
    /// - Parameter message: Message
    private func insertNewMessage(_ message: Message) {
        if messages.contains(message) {
            return
        }
        
        messages.append(message) 
        messages.sort()
        
        let isLatestMessage = messages.firstIndex(of: message) == (messages.count - 1)
        let shouldScrollToBottom = messagesCollectionView.isAtBottom && isLatestMessage
        
        messagesCollectionView.reloadData()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.messagesCollectionView.scrollToLastItem(at: .top, animated: false)
            if shouldScrollToBottom {
                self.messagesCollectionView.scrollToLastItem(animated: false)
            }
        }
    }
    
    /// given users and Image upload to storage and if success it return download url
    /// - Parameters:
    ///   - image: selected picture
    ///   - channel: Users
    ///   - completion: url
    private func uploadImage(
        _ image: UIImage,
        to channel: Users,
        completion: @escaping (URL?) -> Void
    ) {
        guard
            let scaledImage = image.scaledToSafeUploadSize,
            let data = scaledImage.jpegData(compressionQuality: 0.4)
        else {
            return completion(nil)
        }
        
        let channelId = channel.id
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let imageName = [UUID().uuidString, String(Date().timeIntervalSince1970)]
            .joined()
        let imageReference = storage.child("\(channelId)/\(imageName)")
        imageReference.putData(data, metadata: metadata) { _, _ in
            imageReference.downloadURL { url, _ in
                completion(url)
            }
        }
    }
    
    
    /// make user upload picture in chat and pass messageInstance to save with included currentUser Info
    /// - Parameter image: selected Image
    private func sendPhoto(_ image: UIImage) {
        isSendingPhoto = true
        
        uploadImage(image, to: channel) { [weak self] url in
            guard let self = self else { return }
            self.isSendingPhoto = false
            
            guard let url = url else {
                return
            }
            
            DataManager.shared.getUserInfo(email: self.path) { user in
                if let user = user {
                    var message = Message(user: self.currentUser, image: image, users: user)
                    message.downloadURL = url
                    
                    self.save(message)
                    self.messagesCollectionView.scrollToLastItem()
                }
            }
        }
    }
    
    /// make user upload picture in chat and passing messageInstance to save method with included currentUser Info
    /// incoming ref also must be have this doc bc target user can see uploaded picture.
    /// - Parameter image: selected Image
    private func incomingSendPhoto(_ image: UIImage) {
        isSendingPhoto = true
        
        uploadImage(image, to: channel) { [weak self] url in
            guard let self = self else { return }
            self.isSendingPhoto = false
            
            guard let url = url else {
                return
            }
            
            DataManager.shared.getUserInfo(email: self.path) { user in
                if let user = user {
                    var message = Message(user: self.currentUser, image: image, users: user)
                    message.downloadURL = url
                    
                    self.incomingSave(message)
                    self.messagesCollectionView.scrollToLastItem()
                }
            }
        }
    }
    
    /// Handling messageList from given documents change data and do task appropriately.
    /// - Parameter change: DocumentChange
    private func handleDocumentChange(_ change: DocumentChange) {
        guard var message = Message(document: change.document) else {
            return
        }
        
        switch change.type {
        case .added:
            if let url = message.downloadURL {
                downloadImage(at: url) { [weak self] image in
                    guard let self = self, let image = image else { return }
                    message.image = image
                    self.insertNewMessage(message)
                }
            } else {
                insertNewMessage(message)
            }
        default:
            break
        }
    }
    
    /// Setup functionally
    private func setUpMessageView() {
        maintainPositionOnKeyboardFrameChanged = true
        messageInputBar.inputTextView.tintColor = .primary
        messageInputBar.sendButton.setTitleColor(.primary, for: .normal)
        messageInputBar.delegate = self
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
    }
    
    /// Configure avatar, lable size and postion.
    private func configureMessageAvatars() {
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            layout.setMessageIncomingAvatarSize(CGSize(width: 55, height: 55))
            layout.setMessageIncomingMessageTopLabelAlignment(LabelAlignment.init(textAlignment: .left, textInsets: UIEdgeInsets(top: 0, left: 70, bottom: 0, right: 0)))
            
            layout.textMessageSizeCalculator.outgoingAvatarSize = .zero
            layout.setMessageOutgoingAvatarSize(.zero)
            let outgoingLabelAlignment = LabelAlignment(
                textAlignment: .right,
                textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 15))
            layout.setMessageOutgoingMessageTopLabelAlignment(outgoingLabelAlignment)
        }
    }
    
    /// Make camerabutton functionality
    private func addCameraBarButton() {
        let cameraItem = InputBarButtonItem(type: .system)
        cameraItem.tintColor = .primary
        cameraItem.image = UIImage(systemName: "camera")
        
        cameraItem.addTarget(
            self,
            action: #selector(addPicturePressed),
            for: .primaryActionTriggered)
        cameraItem.setSize(CGSize(width: 60, height: 30), animated: false)
        messageInputBar.leftStackView.alignment = .center
        messageInputBar.setLeftStackViewWidthConstant(to: 50, animated: false)
        
        messageInputBar
            .setStackViewItems([cameraItem], forStack: .left, animated: false)
    }
    
    
    /// Given url make return caculated image data
    /// - Parameters:
    ///   - url: message Instance url
    ///   - completion: image
    private func downloadImage(at url: URL, completion: @escaping (UIImage?) -> Void) {
        let ref = Storage.storage().reference(forURL: url.absoluteString)
        let megaByte = Int64(1 * 1024 * 1024)
        
        ref.getData(maxSize: megaByte) { data, _ in
            guard let imageData = data else {
                completion(nil)
                return
            }
            completion(UIImage(data: imageData))
        }
    }
}


// MARK: - MessagesDisplayDelegate
extension ChattingViewController: MessagesDisplayDelegate {
    /// If message sender id and sender id are the same return .primary color other word .incomingMessage color
    /// - Parameters:
    ///   - message: MessageType
    ///   - indexPath: IndexPath
    ///   - messagesCollectionView: MessagesCollectionView
    /// - Returns: UIcolor
    func backgroundColor(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> UIColor {
        return isFromCurrentSender(message: message) ? .primary : .incomingMessage
    }
    
    
    
    /// Make show target user profile image
    /// Access to target user path, get photoUrl and then passing to sd_setImage
    /// - Parameters:
    ///   - avatarView: target user avartarView
    ///   - message: MessageType
    ///   - indexPath: IndexPath
    ///   - messagesCollectionView: MessageCollectionView
    func configureAvatarView(
        _ avatarView: AvatarView,
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) {
        let userRef = self.database.collection("users/\(path)/thread/")
        userRef.document(channel.email).getDocument { snapshot, error in
            guard let data = snapshot?.data() else { return }
            guard let urlStr = data["photoUrl"] as? String,
                  let url = URL(string: urlStr) else {
                      print(error?.localizedDescription ?? "")
                      return
                  }
            
            DispatchQueue.main.async {
                avatarView.sd_setImage(with: url, completed: nil)
            }
        }
    }
    
    
    /// The position of the bubbleTail varies depending on the condition of the current user ID and the sender ID.
    /// - Parameters:
    ///   - message: MessageType
    ///   - indexPath: IndexPath
    ///   - messagesCollectionView: MessagesCollectionView
    /// - Returns: bubbleTail
    func messageStyle(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> MessageStyle {
        let corner: MessageStyle.TailCorner =
        isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(corner, .curved)
    }
}


// MARK: - MessagesLayoutDelegate
extension ChattingViewController: MessagesLayoutDelegate {
    /// Set footer size
    /// - Parameters:
    ///   - message: MessageType
    ///   - indexPath: IndexPath
    ///   - messagesCollectionView: MessagesCollectionView
    /// - Returns: CGSize
    func footerViewSize(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> CGSize {
        return CGSize(width: 0, height: 0)
    }
    
    /// Set user name height size
    /// - Parameters:
    ///   - message: MessageType
    ///   - indexPath: IndexPath
    ///   - messagesCollectionView: MessagesCollectionView
    /// - Returns: height size
    func messageTopLabelHeight(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> CGFloat {
        return 20
    }
}


extension ChattingViewController: MessagesDataSource {
    /// Shows the number of messages stored in the message array.
    /// - Parameter messagesCollectionView: MessagesCollectionView
    /// - Returns: Messages Count
    func numberOfSections(
        in messagesCollectionView: MessagesCollectionView
    ) -> Int {
        return messages.count
    }
    
    
    
    /// Set sender type
    /// this method is require method. and It is used to form conditional statements for current user IDs and sender IDs.
    /// - Returns: SenderType
    func currentSender() -> SenderType {
        var settingName = ""
        DataManager.shared.getUserInfo(email: path) { user in
            if let user = user {
                settingName = user.name
            }
        }
        return Sender(senderId: currentUser.uid, displayName: settingName)
    }
    
    /// Show all messages that included saved message
    /// - Parameters:
    ///   - indexPath: IndexPath
    ///   - messagesCollectionView: MessagesCollectionView
    /// - Returns: messages
    func messageForItem(
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> MessageType {
        return messages[indexPath.section]
    }
    
    /// Set attributed Text and Display the user name above the bubbleTail.
    /// - Parameters:
    ///   - message: MessageType
    ///   - indexPath: indexPath
    /// - Returns: NSAttributedString
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let name = message.sender.displayName
        return NSAttributedString(
            string: name,
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .caption1),
                .foregroundColor: UIColor(white: 0.3, alpha: 1)
            ])
    }
}


// MARK: - InputBarAccessoryViewDelegate
extension ChattingViewController: InputBarAccessoryViewDelegate {
    /// passing the message to the save method and incomingSave too.
    /// It's the starting point. for implement message.
    /// - Parameters:
    ///   - inputBar: InputBarAccessoryView
    ///   - text: String
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let ref = database.collection("users")
        ref.document(channel.email).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                print(error.localizedDescription)
            }
            guard let data = snapshot?.data() else { return }
            guard let token = data["fcmToken"] as? String else { return }
            guard let email = data["email"] as? String else { return }
            
            ref.document(self.path).getDocument { currentUserSnapshot, error in
                if let error = error {
                    print(error.localizedDescription)
                }
                guard let data = currentUserSnapshot?.data() else { return }
                guard let name = data["name"] as? String else { return }
                
                let targetRef = self.database.collection("users")
                targetRef.document(self.channel.email).getDocument { snapshot, error in
                    guard let data = snapshot?.data() else { return }
                    guard let signin = data["signin"] as? Bool else { return }
                    guard let noti = data["noti"] as? Bool else { return }
                    if noti {
                        // 인커밍 유저가 같은 방에 있다면 노티 및 대화카운트 메소드를 호출하지 않게하기위한 조건문.
                        if signin {
                            // 다른 아이디 유저한테 노티를 안보내게 해주는 조건문.
                            self.pushNotification.sendPushNotification(to: token,
                                                                  title: name,
                                                                  body: text,
                                                                  email: email)
                        }
                        self.pushNotification.updateMessageCount(self.channel.email, self.path)
                    }
                }
            }
        }
        
        
        DataManager.shared.getUserInfo(email: path) {[weak self] user in
            guard let self = self else { return }
            if let users = user {
                let message = Message(user: self.currentUser, users: users, content: text)
                self.save(message)
                self.incomingSave(message)
                inputBar.inputTextView.text = ""
            }
        }
    }
}



// MARK: - UIImagePickerControllerDelegate
extension ChattingViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    /// Ask phimagemanager to do what and get the image and passing to sendPhoto Method.
    /// we can set specific size, contentMode, and asset
    /// - Parameters:
    ///   - picker: UIImagePickerController,
    ///   - info: [UIImagePickerController.InfoKey: Any]
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true)
        
        if let asset = info[.phAsset] as? PHAsset {
            let size = CGSize(width: 500, height: 500)
            PHImageManager.default().requestImage(
                for: asset,
                   targetSize: size,
                   contentMode: .aspectFit,
                   options: nil
            ) { [weak self] result, _ in
                guard let image = result, let self = self else { return }
                self.sendPhoto(image)
                self.incomingSendPhoto(image)
            }
            
        } else if let image = info[.originalImage] as? UIImage {
            sendPhoto(image)
            
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}


extension ChattingViewController: PHPickerViewControllerDelegate {
    /// Use itemprovider can access library
    /// - Parameters:
    ///   - picker: PHPickerViewController
    ///   - results: [PHPickerResult]
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        let itemProvider = results.first?.itemProvider
        
        if let itemProvider = itemProvider {
            itemProvider.canLoadObject(ofClass: UIImage.self)
            itemProvider.loadObject(ofClass: UIImage.self) {[weak self] image, _ in
                guard let image = image as? UIImage, let self = self else { return }
                DispatchQueue.main.async {
                    self.sendPhoto(image)
                    self.incomingSendPhoto(image)
                }
            }
        } else {
            print("faild to load")
        }
    }
}

