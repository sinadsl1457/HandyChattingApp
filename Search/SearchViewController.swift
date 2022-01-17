//
//  SearchViewController.swift
//  HandyChattingApp
//
//  Created by 황신택 on 2022/01/02.
//

import UIKit
import FirebaseAuth
import Firebase
import FirebaseFirestore

/// viewcontroller that showing all user list.
class SearchViewController: CommonViewController {
    @IBOutlet weak var listTableView: UITableView!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    private lazy var searchController: UISearchController = {
        let sc = UISearchController(searchResultsController: nil)
        sc.searchResultsUpdater = self
        sc.delegate = self
        sc.obscuresBackgroundDuringPresentation = false
        sc.searchBar.placeholder = "사용자를 검색하세요."
        sc.searchBar.autocapitalizationType = .allCharacters
        return sc
    }()
    
    var userList: [Users] = []
    var filteredUserList: [Users] = []
    var isSearching = false
    private var userListener: ListenerRegistration?
    private var messageReference: CollectionReference?
    // Absolutely to get current email
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        title = "사용자 찾기"
        listTableView.dataSource = self
        listTableView.delegate = self
        getUserDataFromFireStore()
        indicator.style = .large
        indicator.startAnimating()
        loadingView.backgroundColor = .clear
        userProfileListener()
        
        // hide the tab bar for 2 seconds to take time to get data from the server.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.indicator.stopAnimating()
            self.loadingView.isHidden = true
            self.tabBarController?.tabBar.isHidden = false
        }
        tabBarController?.tabBar.isHidden = true
    }
    
    
    /// whenever happened that add, update, delete this listener try call appropriate method realtime.
    private func userProfileListener() {
        userListener = DataManager.shared.usersReference.addSnapshotListener({ querySnapshot, error in
            guard let snapshot = querySnapshot else {
                self.alert(message: "채널에 업데이트를 실패했습니다 \(error?.localizedDescription ?? "no error")")
                return
            }
            
            snapshot.documentChanges.forEach { change in
                guard let user = Users(document: change.document) else { return }
                if change.type == .modified {
                    guard let index = self.userList.firstIndex(of: user) else { return }
                    
                    self.userList[index] = user
                    self.listTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                }
            }
        })
    }
    
    
    /// append to userlist all userlist from firestore.
    private func getUserDataFromFireStore() {
        DataManager.shared.usersReference.getDocuments { querySnapshots, error in
            if let error = error {
                print(error.localizedDescription)
            }
            guard let documents = querySnapshots?.documents else { return }
            
            for document in documents {
                if let user = Users(document: document) {
                    self.userList.append(user)
                    self.listTableView.reloadData()
                }
            }
        }
    }
    
    
    private func setupNavigationBar() {
        navigationItem.searchController = searchController
    }
    
    
    /// must be remove listener once finished task. that's why declare variable
    deinit {
        userListener?.remove()
    }
}


extension SearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching {
            return filteredUserList.count
        } else {
            return userList.count
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchTableViewCell", for: indexPath) as! SearchTableViewCell
        if isSearching {
            let filteredModel = filteredUserList[indexPath.row]
            cell.configureCell(with: filteredModel)
            return cell
        } else {
            let model = userList[indexPath.row]
            cell.configureCell(with: model)
            return cell
        }
    }
    
    
    /// save the selected user to the reference. At the same time, save sender information to the recipient.
    /// - Parameters:
    ///   - tableView: tableView
    ///   - indexPath: indexpath include users
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let user = userList[indexPath.row]
        chooseAlert(title: "대화방 만들기", message: "\(user.name) 과 대화를 하시겠습니까?") {[weak self] _ in
            guard let self = self else { return }
            if let currentUser = self.currentUser {
                guard currentUser.email != user.email else {
                    self.alert(message: "나와의 대화는 지원하지않습니다.")
                    return
                }
                // outcoming message
                let outcomingUserRef = self.database.collection("users/\(self.path)/thread")
                outcomingUserRef.document(user.email).setData(user.rep)
                // incoming message
                let incomingUserRef = self.database.collection("users/\(user.email)/thread")
                DataManager.shared.getUserInfo(email: self.path) { user in
                    if let user = user {
                        incomingUserRef.document(user.email).setData(user.rep)
                    }
                }
                
                let viewContoller = ChattingViewController(user: currentUser, channel: user)
                self.navigationController?.pushViewController(viewContoller, animated: true)
            }
        }
    }
}


extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}


/// make for search users list
/// save to filteredUserList with filtered userlist
extension SearchViewController: UISearchResultsUpdating, UISearchControllerDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchBarText = searchController.searchBar.text else { return }
        isSearching = true
        
        filteredUserList = userList.filter({ $0.name.hasPrefix(searchBarText) })
        listTableView.reloadData()
    }
}


