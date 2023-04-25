//
//  TodoListViewModel.swift
//  todoList
//
//  Created by perennial on 2023/04/23.
//  Copyright © 2023 perennial. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

enum Section: String {
    case scheduled = "Scheduled"
    case anytime = "Anytime"
}

enum DefaultsKey {
    static let isFirstLaunch = "isFirstLaunch"
}

class TodoListViewModel: NSObject {
    var todoScheduled = BehaviorRelay<[String : [Todo]]>(value: [:])    // e.g. "2020-09-23" : [Todo]
    var todoAnytime = BehaviorRelay<[Todo]>(value: [])
    var selectedDate = BehaviorRelay<Date>(value: Date())
    
    var disposeBag = DisposeBag()
    
    override init() {
        super.init()
        
        // fetch all Data
        if nil != UserDefaults.standard.value(forKey: DefaultsKey.isFirstLaunch) {
            loadAllData()   // fetch all Data
        } else {
            loadFirstData() // fetch inital Data
        }
        
        // Save Scheduled
        _ = todoScheduled
            .subscribe(onNext: { [weak self] in
                self?.saveData(data: $0, key: Section.scheduled.rawValue)
            })
            .disposed(by: disposeBag)
        
        _ = todoAnytime
            .subscribe(onNext: { [weak self] in
                self?.saveData(data: $0, key: Section.anytime.rawValue)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Data Processing
    
    /* save data*/
    func saveData<T: Encodable>(data: T, key: String) {
        let userDefaults = UserDefaults.standard
        let encoder = JSONEncoder()
        
        if let jsonData = try? encoder.encode(data) {
            if let jsonString = String(data: jsonData, encoding: .utf8){
                userDefaults.set(jsonString, forKey: key)
            }
        }
        // synchornize
        userDefaults.synchronize()
    }
    
    /*fetch all data from DB */
    func loadAllData() {
        let userDefaults = UserDefaults.standard
        let decoder = JSONDecoder()
        
        // Scheduled
        if let jsonString = userDefaults.value(forKey: Section.scheduled.rawValue) as? String {
            if let jsonData = jsonString.data(using: .utf8),
               let scheduledData = try? decoder.decode([String : [Todo]].self, from: jsonData) {
                todoScheduled.accept(scheduledData)
            }
        }
        
        // Anytime
        if let jsonString = userDefaults.value(forKey: Section.anytime.rawValue) as? String {
            if let jsonData = jsonString.data(using: .utf8),
               let anytimeData = try? decoder.decode([Todo].self, from: jsonData) {
                todoAnytime.accept(anytimeData)
            }
        }
    }
    
    /* initial Data */
    func loadFirstData() {
        let userDefaults = UserDefaults.standard
        let date = selectedDate.value.toString()
        
        userDefaults.setValue(false, forKey: DefaultsKey.isFirstLaunch)
        self.todoScheduled.accept([date : [Todo(title: "Create new task",
                                                date: date,
                                                time: "8:00 PM",
                                                description: "Enter the description for the scheduled task.")]])
        self.todoAnytime.accept([Todo(title: "Update your task", date: "", time: "", description: "This task has not yet been scheduled.")])
        userDefaults.synchronize()
    }
    
    // MARK: - Tasks
    
    /* mark as Complete */
    func changeComplete(section: Section, row: Int) {
        if section == .scheduled {
            var tasks = todoScheduled.value
            let date = selectedDate.value.toString()
            tasks[date]?[row].isCompleted.toggle()
            todoScheduled.accept(tasks)
        } else if section == .anytime {
            var tasks = todoAnytime.value
            tasks[row].isCompleted.toggle()
            todoAnytime.accept(tasks)
        }
    }
    
    /* Todo add */
    func insert(task:Todo, section: Section, row: Int?, date: String?) {
        var task = task
        
        if section == .scheduled {
            var scheduled = todoScheduled.value
            let date = date ?? selectedDate.value.toString()
            var newTasks = todoScheduled.value[date] ?? []
            
            task.date = date
            if let row = row { newTasks.insert(task, at: row) }
            else { newTasks.append(task) }
            
            scheduled[date] = newTasks
            todoScheduled.accept(scheduled)
        } else if section == .anytime {
            var anytime = todoAnytime.value
            
            task.date = ""
            task.time = ""
            if let row = row { anytime.insert(task, at: row) }
            else { anytime.append(task) }
            
            todoAnytime.accept(anytime)
        }
    }
    
    /* Todo remove */
    func remove(section: Section, row: Int, date: String?) -> Todo? {
        var removedTask: Todo?
        
        if section == .scheduled {
            var scheduled = todoScheduled.value
            let date = date ?? selectedDate.value.toString()
            
            removedTask = scheduled[date]?.remove(at: row)
            todoScheduled.accept(scheduled)
        } else if section == .anytime {
            var anytime = todoAnytime.value
            
            removedTask = anytime.remove(at: row)
            todoAnytime.accept(anytime)
        }
        
        return removedTask
    }
}
