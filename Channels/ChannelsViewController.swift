//
//  ChnnelsViewController.swift
//  HandyChattingApp
//
//  Created by 황신택 on 2021/12/20.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class ChannelsViewController: CommonViewController {
    @IBOutlet weak var listTableView: UITableView!
    var channelList: [Users] = []
    var chatListener: ListenerRegistration?
    private let database = Firestore.firestore()
    private var path: String {
        var path = ""
        if let currentUser = currentUser {
            currentUser.providerData.forEach {
                if let providerEmail = $0.email {
                    path = currentUser.email ?? providerEmail
                }
            }
        }
        return path
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "대화"
        let userRef = self.database.collection("users/\(path)/thread")
        chatListener = userRef.addSnapshotListener({ querySnapshot, error in
            guard let snapshot = querySnapshot else {
                self.alert(message: "채널에 업데이트를 실패했습니다 \(error?.localizedDescription ?? "no error")")
                return
            }
            snapshot.documentChanges.forEach { change in
                self.handleDocumentChange(change)
            }
        })
    }
    
    
    deinit {
        chatListener?.remove()
    }
    
    
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
    
    private func updateChannelInTable(_ channel: Users) {
        guard let index = channelList.firstIndex(of: channel) else {
            return
        }
        
        channelList[index] = channel
        listTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }
    
    private func removeChannelFromTable(_ channel: Users) {
        guard let index = channelList.firstIndex(of: channel) else {
            return
        }
        
        channelList.remove(at: index)
        listTableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }
    
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
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let channelName = channelList[indexPath.row].name
            DataManager.shared.chatsReference.document(channelName).delete { error in
                if let error = error {
                    self.alert(message: error.localizedDescription)
                    return
                }
            }
            
            let channel = channelList[indexPath.row]
            guard let index = channelList.firstIndex(of: channel) else {
                return
            }
            channelList.remove(at: index)
            listTableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        }
    }
    
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
}

extension ChannelsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let channel = channelList[indexPath.row]
        if let currentUser = currentUser {
            let viewContoller = ChattingViewController(user: currentUser, channel: channel)
            navigationController?.pushViewController(viewContoller, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}
