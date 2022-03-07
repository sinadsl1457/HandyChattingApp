//
//  ChnnelsViewController.swift
//  HandyChattingApp
//
//  Created by 황신택 on 2021/12/20.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

/// Viewcontroller that show channel list
class ChannelsViewController: CommonViewController {
    @IBOutlet weak var listTableView: UITableView!
    var channelList: [Users] = []
    var chatListener: ListenerRegistration?
    
    @IBAction func readAll(_ sender: Any) {
        UserDefaults.extensions.badge = 0
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    /// make tableView reloadData before did load view for display lastest message
    /// - Parameter animated: Bool
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        listTableView.reloadData()
        turnOnNoti()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "채팅"
        channelListener()
    }

    private func turnOnNoti() {
        database
            .collection("users")
            .document(path)
            .setData(["noti": true], merge: true)
    }
    
    /// Whenever happend that CRUD in firestore, the listener pass doc changes to handleDocumentChange method.
    private func channelListener() {
        let userRef = self.database.collection("users/\(path)/thread")
        chatListener = userRef.addSnapshotListener({[weak self] querySnapshot, error in
            guard let self = self else { return }
            guard let snapshot = querySnapshot else {
                self.alert(message: "채널에 업데이트를 실패했습니다 \(error?.localizedDescription ?? "no error")")
                return
            }
            snapshot.documentChanges.forEach { change in
                self.handleDocumentChange(change)
            }
        })
    }
    
    /// Once finished task listener should remove it.
    deinit {
        chatListener?.remove()
    }
    
    /// add to channelList and sort from given data.
    /// - Parameter channel: Users
    private func addChannelToTable(_ channel: Users) {
        if channelList.contains(channel) {
            return
        }
        
        channelList.append(channel)
        channelList.sort()
        
        guard let index = channelList.firstIndex(of: channel) else {
            return
        }
        listTableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }
    
    /// update to channlList specific index from given data.
    /// - Parameter channel: Users
    private func updateChannelInTable(_ channel: Users) {
        guard let index = channelList.firstIndex(of: channel) else {
            return
        }
        
        channelList[index] = channel
        listTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }
    
    /// delete to channlList specific index from given data.
    /// - Parameter channel: Users
    private func removeChannelFromTable(_ channel: Users) {
        guard let index = channelList.firstIndex(of: channel) else {
            return
        }
        
        channelList.remove(at: index)
        listTableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }
    
    /// Handling ChannelList from given documents change data and do task appropriately depends on CRUD
    /// - Parameter change: DocumentChange
    private func handleDocumentChange(_ change: DocumentChange) {
        guard let chat = Users(document: change.document) else { return }
        
        switch change.type {
        case .added:
            addChannelToTable(chat)
        case .modified:
            updateChannelInTable(chat)
        case .removed:
            removeChannelFromTable(chat)
        }
    }
    
    
}



extension ChannelsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        channelList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChannelTableViewCell", for: indexPath) as! ChannelTableViewCell
        cell.selectionStyle = .none
        let target = channelList[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        cell.configureCell(with: target)
        cell.isHiddenCount(target) { zero in
            if zero {
                cell.messageCount.isHidden = true
            } else {
                cell.messageCount.isHidden = false
            }
        }
        return cell
    }
    
    /// Remove to channel list
    /// once swipe remove specific index and then remove in firestore doc too but currently not support remove collection in other word Even if you delete the document, the subcollections are not deleted. so can't complety remove chat list now.
    /// - Parameters:
    ///   - tableView: channelList
    ///   - editingStyle: delete
    ///   - indexPath: Indexpath
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let channel = channelList[indexPath.row]
        if editingStyle == .delete {
            let userRef = self.database.collection("users/\(path)/thread")
            userRef.document(channel.email).delete {[weak self] error in
                guard let self = self else { return }
                if let error = error {
                    self.alert(message: error.localizedDescription)
                    return
                }
                let collection = self.database.collection("users/\(self.path)/thread/\(channel.email)/thread")
                collection.getDocuments { querySnapshot, error in
                    if let error = error {
                        print(error.localizedDescription)
                    }
                    guard let documents = querySnapshot?.documents else { return }
                    documents.forEach { $0.reference.delete() }
                    
                }
                self.alert(message: "삭제 되었습니다.")
            }
        }
    }
    
}

extension ChannelsViewController: UITableViewDelegate {
    /// Whenever enter chatroom make passing users data and current user data to chatviewcontroller init
    /// - Parameters:
    ///   - tableView: channelListTableView
    ///   - indexPath: channelList
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let channel = channelList[indexPath.row]
        if let currentUSer = currentUser {
            let viewContoller = ChattingViewController(user: currentUSer, channel: channel)
            navigationController?.pushViewController(viewContoller, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}

