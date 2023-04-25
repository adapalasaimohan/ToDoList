//
//  Task.swift
//  todoList
//
//
//  Created by perennial on 2023/04/23.
//  Copyright © 2023 perennial. All rights reserved.
//

import Foundation
import RxDataSources

struct Task {
    var date: String
    var items: [Todo]
}

extension Task: SectionModelType {
    typealias Item = Todo
    
    init(original: Task, items: [Item]) {
        self = original
        self.items = items
    }
}
