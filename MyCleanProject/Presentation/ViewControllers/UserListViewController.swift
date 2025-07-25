//
//  ViewController.swift
//  MyCleanProject
//
//  Created by eunchanKim on 6/24/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class UserListViewController: UIViewController {
    private let viewModel: UserListViewModelProtocol
    private let disposeBag = DisposeBag()
    private let saveFavorite = PublishRelay<UserListItem>()
    private let deleteFavorite = PublishRelay<Int>()
    private let fetchMore = PublishRelay<Void>()
    
    private let searchTextField = {
        let textField = UITextField()
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.systemGray.cgColor
        textField.layer.cornerRadius = 6
        textField.placeholder = "검색어를 입력해주세요"
        let image = UIImageView(image: .init(systemName: "magnifyingglass"))
        image.frame = .init(x: 0, y: 0, width: 20, height: 20)
        textField.leftView = image
        textField.leftViewMode = .always
        textField.tintColor = .black
        return textField
    }()
    
    private let tabButtonView = TabButtonView(tabList: [.api, .favorite])
    
    private let tableView = {
        let tableView = UITableView()
        tableView.register(UserTableViewCell.self, forCellReuseIdentifier: UserTableViewCell.id)
        tableView.register(HeaderTableViewCell.self, forCellReuseIdentifier: HeaderTableViewCell.id)
        return tableView
    }()
    
    init(viewModel: UserListViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = .white
        setUI()
        bindView()
        bindViewModel()
    }
    
    private func bindViewModel() {
        let tabButtonType = tabButtonView.selectedType.compactMap { $0 }
        let query = searchTextField.rx.text.orEmpty.debounce(.milliseconds(300), scheduler: MainScheduler.instance)
        let output = viewModel.transform(input: UserListViewModel.Input(tabButtonType: tabButtonType, query: query, saveFavorite: saveFavorite.asObservable(), deleteFavorite: deleteFavorite.asObservable(), fetchMore: fetchMore.asObservable()))
        
        output.cellData.bind(to: tableView.rx.items) { [weak self] tableView, index, cellData in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: cellData.id) else { return UITableViewCell() }
            (cell as? UserListCellProtocol)?.apply(cellData: cellData)
            
            if let cell = cell as? UserTableViewCell, case let .user(user, isFavorite) = cellData {

                cell.favoriteButton.rx.tap.bind {
                    if isFavorite {
                        self?.deleteFavorite.accept(user.id)
                    } else {
                        self?.saveFavorite.accept(user)
                    }
                }.disposed(by: cell.disposeBag)
            }
            return cell
        }.disposed(by: disposeBag)
        
        output.error
            .observe(on: MainScheduler.instance) // ✅ UI 업데이트를 메인 스레드에서!
            .bind { [weak self] errorMessage in
            let alert = UIAlertController(title: "에러", message: errorMessage, preferredStyle: .alert)
            alert.addAction(.init(title: "확인", style: .default))
            self?.present(alert, animated: true)
        }.disposed(by: disposeBag)
    }
    
    // pagenation
    private func bindView() {
        tableView.rx.prefetchRows.bind { [weak self] indexPath in
            guard let rows = self?.tableView.numberOfRows(inSection: 0), let itemIndex = indexPath.first?.item else { return }
            if itemIndex >= rows - 1 {
                self?.fetchMore.accept(())
            }
            // 현재 인덱스
        }.disposed(by: disposeBag)
    }
    
    private func setUI() {
        view.addSubview(searchTextField)
        view.addSubview(tabButtonView)
        view.addSubview(tableView)
        
        searchTextField.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
        
        tabButtonView.snp.makeConstraints { make in
            make.top.equalTo(searchTextField.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(tabButtonView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


}

