//
//  UserListViewModel.swift
//  MyCleanProject
//
//  Created by eunchanKim on 6/25/25.
//

import Foundation
import RxSwift
import RxCocoa

protocol UserListViewModelProtocol {
    func transform(input: UserListViewModel.Input) -> UserListViewModel.Output
}

public final class UserListViewModel: UserListViewModelProtocol {
    private let usecase: UserListUsecaseProtocol
    
    // RxSwift
    private let disposeBag = DisposeBag()
    
    // PublishRelay = 초기값 필요없고 값 전달만 하는 용도
    private let error = PublishRelay<String>()
    
    // BehaviorRelay = 초기값 필요하며 값에 접근용도
    private let fetchUserList = BehaviorRelay<[UserListItem]>(value: [])
    private let allFavoriteUserList = BehaviorRelay<[UserListItem]>(value: []) // fetchUser 즐겨찾기 여부를 위한 전체목록
    private let favoriteUserList = BehaviorRelay<[UserListItem]>(value: []) // 목록에 보여줄 리스트
    private var page: Int = 1
    public init(usecase: UserListUsecaseProtocol) {
        self.usecase = usecase
    }
    
    // 이벤트(VC) -> 가공 혹은 외부에서 데이터 호출 혹은 뷰 데이터를 전달(VM) -> VC
    public struct Input { // VM 에게 전달 해야할 이벤트
        let tabButtonType: Observable<TabButtonType>
        let query: Observable<String>
        let saveFavorite: Observable<UserListItem>
        let deleteFavorite: Observable<Int>
        let fetchMore: Observable<Void>
    }
    public struct Output { // VC 에게 전달할 뷰 데이터
        let cellData: Observable<[UserListCellData]>
        let error: Observable<String>
    }
    
    public func transform(input: Input) -> Output { // VC 이벤트 -> VM 데이터
        
        input.query.bind { [weak self] query in //TODO: user Fetch and get favorite Users
            guard let self = self, validateQuery(query: query) else {
                self?.getFavoriteUsers(query: "")
                return
            }
            page = 1
            fetchUser(query: query, page: page)
            getFavoriteUsers(query: query)
        }.disposed(by: disposeBag)
        
        
        input.saveFavorite
            .withLatestFrom(input.query, resultSelector: { users, query in
                return (users, query)
            })
            .bind {[weak self] user, query in //TODO: 즐겨찾기 추가
                self?.saveFavoriteUser(user: user, query: query)
            }.disposed(by: disposeBag)
        
        
        input.deleteFavorite
            .withLatestFrom(input.query, resultSelector: {($0, $1)})
            .bind {[weak self] userID, query in //TODO: 즐겨찾기 삭제
                self?.deleteFavoriteUser(userID: userID, query: query)
            }.disposed(by: disposeBag)
        
        
        input.fetchMore
            .withLatestFrom(input.query)
            .bind { [weak self] query in //TODO: 다음페이지 검색
                guard let self = self else { return }
                page += 1
                fetchUser(query: query, page: page)
            
        }.disposed(by: disposeBag)
        
        // 탭 -> api유저리스트 or 즐겨찾기 유저리스트
        // .combineLatest를 사용하는 이유 : 각각의 요소의 값이 바뀌었을 때 새로운 정보를 전달하기 위함
        let cellData = Observable.combineLatest(input.tabButtonType, fetchUserList, favoriteUserList, allFavoriteUserList)
            .map { [weak self] tabButtonType, fetchUserList, favoriteUserList, allFavoriteUserList in
            
            var cellData: [UserListCellData] = []
            guard let self = self else { return cellData }
            
            
            //TODO: cellData 생성
            switch tabButtonType {
            case .api:
                let tuple = usecase.checkFavoriteState(fetchUsers: fetchUserList, favoriteUsers: allFavoriteUserList)
                let userCellList = tuple.map { user, isFavorite in
                    UserListCellData.user(user: user, isFavorite: isFavorite)
                }
                return userCellList
            case .favorite:
                let dict = usecase.convertListToDictionary(favoriteUsers: favoriteUserList)
                let keys = dict.keys.sorted()
                keys.forEach { key in
                    cellData.append(.header(key))
                    if let users = dict[key] {
                        cellData += users.map { UserListCellData.user(user: $0, isFavorite: true) }
                    }
                }
            }
            return cellData
        }
        
        return Output(cellData: cellData, error: error.asObservable())
    }
    
    private func fetchUser(query: String, page: Int) {
        // 한국어를 영어로 인코딩
        guard let urlAllowedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        
        Task {
            let result = await usecase.fetchUser(query: urlAllowedQuery, page: page)
            switch result {
            case let .success(users):
                if page == 0 {//첫번째 페이지
                    fetchUserList.accept(users.items)
                    
                } else {//두번째 그 이상페이지
                    fetchUserList.accept(fetchUserList.value + users.items)
                }
            case let .failure(error):
                self.error.accept(error.description)
            }
        }
    }
    
    private func getFavoriteUsers(query: String) {
        let result = usecase.getFavoriteUsers()
        switch result {
        case .success(let users):
            if query.isEmpty {
                favoriteUserList.accept(users)
            } else { //검색어가 있을 때 필터링
                let filteredUsers = users.filter { user in
                    user.login.contains(query)
                }
                favoriteUserList.accept(filteredUsers)
            }
            allFavoriteUserList.accept(users)
        case .failure(let error):
            self.error.accept(error.description)
        }
    }
    
    private func saveFavoriteUser(user: UserListItem, query: String) {
        let result = usecase.saveFavoirteUser(user: user)
        switch result {
        case .success:
            getFavoriteUsers(query: query)
        case .failure(let error):
            self.error.accept(error.description)
        }
    }
    
    private func deleteFavoriteUser(userID: Int, query: String) {
        let result = usecase.deleteFavoriteUser(userID: userID)
        switch result {
        case .success:
            getFavoriteUsers(query: query)
        case .failure(let error):
            self.error.accept(error.description)
        }
    }
    
    private func validateQuery(query: String) -> Bool {
        if query.isEmpty {
            return false
        } else {
            return true
        }
    }
}

public enum TabButtonType: String{
    case api = "API"
    case favorite = "Favorite"
}

public enum UserListCellData {
    case user(user: UserListItem, isFavorite: Bool)
    case header(String)
}
