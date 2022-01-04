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
    private let user: User
    private let channel: Users
    private var messages: [Message] = []
    private var messageListener: ListenerRegistration?
    private let database = Firestore.firestore()
    private var reference: CollectionReference?
    private var uiPicker = UIImagePickerController()
    
    var picker: PHPickerViewController = {
        var config = PHPickerConfiguration()
        config.filter = .any(of: [.images, .videos])
        config.selectionLimit = 10
        return PHPickerViewController(configuration: config)
    }()
    
    
    init(user: User, channel: Users) {
        self.user = user
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
        removeMessageAvatars()
        addCameraBarButton()
    }
    
    private func listenToMessages() {
        let name = channel.name
        reference = database.collection("chats/\(name)/thread")
        
        messageListener = reference?
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
        reference?.addDocument(data: message.representation) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                print("Error sending message: \(error.localizedDescription)")
                return
            }
            self.messagesCollectionView.scrollToLastItem()
        }
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
            
            var message = Message(user: self.user, image: image)
            message.downloadURL = url
            
            self.save(message)
            self.messagesCollectionView.scrollToLastItem()
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
    
    private func removeMessageAvatars() {
        guard
            let layout = messagesCollectionView.collectionViewLayout
                as? MessagesCollectionViewFlowLayout
        else {
            return
        }
        layout.textMessageSizeCalculator.outgoingAvatarSize = .zero
        layout.textMessageSizeCalculator.incomingAvatarSize = .zero
        layout.setMessageIncomingAvatarSize(.zero)
        layout.setMessageOutgoingAvatarSize(.zero)
        let incomingLabelAlignment = LabelAlignment(
            textAlignment: .left,
            textInsets: UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0))
        layout.setMessageIncomingMessageTopLabelAlignment(incomingLabelAlignment)
        let outgoingLabelAlignment = LabelAlignment(
            textAlignment: .right,
            textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 15))
        layout.setMessageOutgoingMessageTopLabelAlignment(outgoingLabelAlignment)
    }
    
    private func addCameraBarButton() {
        // 1
        let cameraItem = InputBarButtonItem(type: .system)
        cameraItem.tintColor = .primary
        cameraItem.image = UIImage(systemName: "camera")
        
        // 2
        cameraItem.addTarget(
            self,
            action: #selector(addPicturePressed),
            for: .primaryActionTriggered)
        cameraItem.setSize(CGSize(width: 60, height: 30), animated: false)
        messageInputBar.leftStackView.alignment = .center
        messageInputBar.setLeftStackViewWidthConstant(to: 50, animated: false)
        
        // 3
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
    // 1
    func backgroundColor(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> UIColor {
        return isFromCurrentSender(message: message) ? .primary : .incomingMessage
    }
    
    // 2
    func shouldDisplayHeader(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> Bool {
        return false
    }
    
    // 3
    func configureAvatarView(
        _ avatarView: AvatarView,
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) {
        avatarView.isHidden = true
    }
    
    // 4
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
    // 1
    func footerViewSize(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> CGSize {
        return CGSize(width: 0, height: 8)
    }
    
    // 2
    func messageTopLabelHeight(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> CGFloat {
        return 20
    }
}


// MARK: - MessagesDataSource
extension ChattingViewController: MessagesDataSource {
    // 1
    func numberOfSections(
        in messagesCollectionView: MessagesCollectionView
    ) -> Int {
        return messages.count
    }
    
    // 2
    func currentSender() -> SenderType {
        return Sender(senderId: user.uid, displayName: AppSettings.displayName)
    }
    
    // 3
    func messageForItem(
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> MessageType {
        return messages[indexPath.section]
    }
    
    // 4
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
        // 1
        let message = Message(user: user, content: text)
        
        // 2
        save(message)
        
        // 3
        inputBar.inputTextView.text = ""
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
                }
            }
        } else {
            print("faild to load")
        }
    }
}
