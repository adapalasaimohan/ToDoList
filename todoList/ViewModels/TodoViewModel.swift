//
//  TodoViewModel.swift
//  todoList
//
//
//  Created by perennial on 2023/04/23.
//  Copyright © 2023 perennial. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class TodoViewModel: NSObject {
    var task = BehaviorRelay<Todo>(value: Todo.empty)
    var disposeBag = DisposeBag()
    
    init(_ task: Todo) {
        _ = BehaviorSubject<Todo>.just(task)
            .take(1)
            .subscribe(onNext: self.task.accept(_:))
            .disposed(by: disposeBag)
    }
    
    lazy var checkImageString: Observable<String> = self.task.map { return $0.isCompleted ? "checkmark.circle.fill" : "circle" }
}
