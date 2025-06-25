//
//  MockUserRepository.swift
//  MyCleanProjectTests
//
//  Created by eunchanKim on 6/25/25.
//

import Foundation
@testable import MyCleanProject

public struct MockUserRepository: UserRepositoryProtocol{
    
    public func fetchUser(query: String, page: Int) async -> Result<MyCleanProject.UserListResult, MyCleanProject.NetworkError> {
        .failure(.detaNil)
    }
    
    public func getFavoriteUsers() -> Result<[MyCleanProject.UserListItem], MyCleanProject.CoreDataError> {
        .failure(.entityNotFound(""))
    }
    
    public func saveFavoirteUser(user: MyCleanProject.UserListItem) -> Result<Bool, MyCleanProject.CoreDataError> {
        .failure(.entityNotFound(""))
    }
    
    public func deleteFavoriteUser(userID: Int) -> Result<Bool, MyCleanProject.CoreDataError> {
        .failure(.entityNotFound(""))
    }
    

}
