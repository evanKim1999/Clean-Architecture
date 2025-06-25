//
//  UserRepository.swift
//  MyCleanProject
//
//  Created by eunchanKim on 6/24/25.
//

import Foundation

public struct UserRepository: UserRepositoryProtocol {
    private let coreData: UserCoreDataProtocol, network: UserNetworkProtocol
    
    init(coreData: UserCoreDataProtocol, network: UserNetworkProtocol) {
        self.coreData = coreData
        self.network = network
    }
    
    public func fetchUser(query: String, page: Int) async -> Result<UserListResult, NetworkError> {
        return await network.fetchUser(query: query, page: page)
    }
    
    public func getFavoriteUsers() -> Result<[UserListItem], CoreDataError> {
        return coreData.getFavoriteUsers()
    }
    
    public func saveFavoirteUser(user: UserListItem) -> Result<Bool, CoreDataError> {
        return coreData.saveFavoirteUser(user: user)
    }
    
    public func deleteFavoriteUser(userID: Int) -> Result<Bool, CoreDataError> {
        return coreData.deleteFavoriteUser(userID: userID)
    }

}
