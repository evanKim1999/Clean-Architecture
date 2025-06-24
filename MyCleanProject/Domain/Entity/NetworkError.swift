//
//  NetworkError.swift
//  MyCleanProject
//
//  Created by eunchanKim on 6/24/25.
//

import Foundation

public enum NetworkError: Error {
    case urlError
    case invalidReponse
    case failToDecode(String)
    case detaNil
    case serverError(Int)
    case requestFailed(String)
    
    public var description: String {
        switch self {
        case .urlError:
            "URL이 올바르지 않습니다"
        case .invalidReponse:
            "응답이 유효하지 않습니다"
        case .failToDecode(let description):
            "디코딩 에러 \(description)"
        case .detaNil:
            "데이터가 없습니다"
        case .serverError(let statusCode):
            "서버에러 \(statusCode)"
        case .requestFailed(let message):
            "서버 요청 실패 \(message)"
        }
    }
}
