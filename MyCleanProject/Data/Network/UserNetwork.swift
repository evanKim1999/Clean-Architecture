//
//  UserNetwork.swift
//  MyCleanProject
//
//  Created by eunchanKim on 6/24/25.
//

import Foundation

final public class UserNetwork {
    private let manager: NetworkManagerProctocol
    
    init(manager: NetworkManagerProctocol) {
        self.manager = manager
    }
    
    func fetchUser(query: String, page: Int) async -> Result<UserListResult, NetworkError> {
        let url = "https://api.github.com/search/issues?q=\(query)&page=\(page)"
        
        return await manager.fetchData(url: url, method: .get, parameters: nil)
        
    }
}
