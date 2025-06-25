//
//  UserNetwork.swift
//  MyCleanProject
//
//  Created by eunchanKim on 6/24/25.
//

import Foundation

public protocol UserNetworkProtocol {
    func fetchUser(query: String, page: Int) async -> Result<UserListResult, NetworkError>
}

final public class UserNetwork: UserNetworkProtocol{
    private let manager: NetworkManagerProctocol
    
    init(manager: NetworkManagerProctocol) {
        self.manager = manager
    }
    
    public func fetchUser(query: String, page: Int) async -> Result<UserListResult, NetworkError> {
        let url = "https://api.github.com/search/issues?q=\(query)&page=\(page)"
        
        return await manager.fetchData(url: url, method: .get, parameters: nil)
        
    }
}
