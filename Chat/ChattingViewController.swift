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

class ChattingViewController: MessagesViewController {
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
    private var outcomingReference: CollectionReference {
        return database.collection("users/\(path)/thread/\(channel.email)/thread")
    }
    private var incomingReference: CollectionReference {
        return database.collection("users/\(channel.email)/thread/\(path)/thread")
    }
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
    
    
    init(user: User, channel: Users) {
        self.currentUser = user
        self.channel = channel
        super.init(nibName: nil, bundle: nil)
        title = "\(channel.name) 과 대화"
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    }
    
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
    
    private func save(_ message: Message) {
        outcomingReference.addDocument(data: message.representation) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                print("Error sending message: \(error.localizedDescription)")
                return
            }
            self.messagesCollectionView.scrollToLastItem()
        }
    }
    
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
    private func insertNewMessage(_ message: Message) {
        if messages.contains(message) {
            return
        }
        
        messages.append(message)
        messages.sort()
        
        let isLatestMessage = messages.firstIndex(of: message) == (messages.count - 1)
        let shouldScrollToBottom =
        messagesCollectionView.isAtBottom && isLatestMessage
        
        messagesCollectionView.reloadData()
        
        if shouldScrollToBottom {
            messagesCollectionView.scrollToLastItem(animated: true)
        }
    }
    
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
    
    
    private func handleDocumentChange(_ change: DocumentChange) {
        guard var message = Message(document: change.document) else {
            return
        }
        
        switch change.type {
        case .added:
            if let url = message.downloadURL {
                downloadImage(at: url) { [weak self] image in
                    guard
                        let self = self,
                        let image = image
                    else {
                        return
                    }
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
    
    
    private func setUpMessageView() {
        maintainPositionOnKeyboardFrameChanged = true
        messageInputBar.inputTextView.tintColor = .primary
        messageInputBar.sendButton.setTitleColor(.primary, for: .normal)
        messageInputBar.delegate = self
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
    }
    
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
    func backgroundColor(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> UIColor {
        return isFromCurrentSender(message: message) ? .primary : .incomingMessage
    }
    
    
    func shouldDisplayHeader(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> Bool {
        return false
    }
    
    
    func configureAvatarView(
        _ avatarView: AvatarView,
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) {
       
        outcomingReference.whereField("senderId", isNotEqualTo: currentUser.uid).getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else { return }
            documents.forEach { doc in
                let data = doc.data()
                guard let senderUrl = data["senderUrl"] as? String else { return }
                guard let Url = URL(string: senderUrl) else { return }
            
                DispatchQueue.main.async {
                    avatarView.sd_setImage(with: Url, completed: nil)
                }
            }
        }
        
        incomingReference.whereField("senderId", isNotEqualTo: currentUser.uid).getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else { return }
            documents.forEach { doc in
                let data = doc.data()
                guard let senderUrl = data["senderUrl"] as? String else { return }
                guard let Url = URL(string: senderUrl) else { return }
            
                DispatchQueue.main.async {
                    avatarView.sd_setImage(with: Url, completed: nil)
                }
            }
        }
    }
    
    
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
    func footerViewSize(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> CGSize {
        return CGSize(width: 0, height: 8)
    }
    
    func messageTopLabelHeight(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> CGFloat {
        return 20
    }

}


extension ChattingViewController: MessagesDataSource {
    func numberOfSections(
        in messagesCollectionView: MessagesCollectionView
    ) -> Int {
        return messages.count
    }
    
    func currentSender() -> SenderType {
        var settingName = ""
        DataManager.shared.getUserInfo(email: path) { user in
            if let user = user {
                settingName = user.name
            }
        }
        
        return Sender(senderId: currentUser.uid, displayName: settingName)
    }
    
    func messageForItem(
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> MessageType {
        return messages[indexPath.section]
    }
    
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
    func inputBar(_ inputBar: InputBarAccessoryView,didPressSendButtonWith text: String) {
        DataManager.shared.getUserInfo(email: path) { user in
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
            ) { result, _ in
                guard let image = result else { return }
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
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        let itemProvider = results.first?.itemProvider
        
        if let itemProvider = itemProvider {
            itemProvider.canLoadObject(ofClass: UIImage.self)
            itemProvider.loadObject(ofClass: UIImage.self) { image, _ in
                guard let image = image as? UIImage else { return }
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
 
