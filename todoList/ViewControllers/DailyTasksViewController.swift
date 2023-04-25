//
//  ViewController.swift
//  todoList
//
//
//  Created by perennial on 2023/04/23.
//  Copyright © 2023 perennial. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import MapKit
import CoreLocation
protocol SendDataDelegate {
    func sendData(oldTask: Todo?, newTask: Todo, indexPath: IndexPath?)
    func sendData(scheduledTasks: [String : [Todo]], newDate: Date)
}

class DailyTasksViewController: UIViewController{
    
    @IBOutlet weak var tblTodo: UITableView!
    @IBOutlet weak var btnAdd: UIButton!
    @IBOutlet weak var btnEditTable: UIBarButtonItem!
    
    @IBOutlet var WeatherCollectionView: UICollectionView!
    private var todoSections: BehaviorRelay<[Task]> = BehaviorRelay(value: [])
    private var dataSource: RxTableViewSectionedReloadDataSource<Task>!
    var viewModel = TodoListViewModel()
    var disposeBag = DisposeBag()
    var url: String = ""
    var weatherData: WeatherFeed?
    
    let locationManager = CLLocationManager()
    var coordinates = CLLocationCoordinate2D(latitude: 16.0686, longitude: 80.5482)
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
//
        self.title = Date.getCurrentDate()
        // Cell 등록
        let nibName = UINib(nibName: TodoTableViewCell.nibName, bundle: nil)
        tblTodo.register(nibName, forCellReuseIdentifier: TodoTableViewCell.identifier)
        tblTodo.rowHeight = UITableView.automaticDimension
        locationManager.delegate = self
        let status: CLAuthorizationStatus = CLLocationManager.authorizationStatus()
                if status == CLAuthorizationStatus.notDetermined || status == CLAuthorizationStatus.denied || status == CLAuthorizationStatus.restricted
                {
                    locationManager.requestAlwaysAuthorization()
                }
        // UI Binding
        
        setupBindings()
        
        self.getLocation()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 테이블 데이터 갱신
        tblTodo.reloadData()
    }
    
    func fetch(urlString:String)
    {
        if let url = URL(string: urlString){   //unwrap url
            
            URLSession
                .shared
                .dataTask(with: url) { [weak self](data, response,error) in
                    
                    DispatchQueue.main.async { //need on main thread; publishing changes from background thread isnt allowed
                        
                        if let error = error{  //unrap error if is one
                            print(error)
                            self?.showAlert(title: "Error", message: error.localizedDescription)
                        }else{
                            let decoder = JSONDecoder() //using json decoder to do the work for us
                            
                            if let data = data,
                               let feed = try? decoder.decode(WeatherFeed.self, from: data){
                                self?.weatherData = feed
                                self?.WeatherCollectionView.reloadData()
                                
//                                self?.updateDisplayableData(feed: feed)   //get the data we need to display to user
//                                self?.weatherFeedArray.append(feed)   //don't need to, but just save all data returned by api
                                
                                //print( feed )
                            }else{
                                self?.showAlert(title: "Error", message:"Failed to decode the Weather JSON")
                                //print("failed to decode")
                            }
                        }
                    }
                    
                    
                }.resume()
        }
        
        
    }
    
    
    // MARK: - UI Binding
    
    func setupBindings() {
        dataSource = RxTableViewSectionedReloadDataSource<Task> { dataSource, tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: TodoTableViewCell.identifier, for: indexPath) as! TodoTableViewCell
            
            // cell 설정
            cell.bind(task: item)
            
            // 체크박스 선택 시 작업 추가
            cell.btnCheckbox.indexPath = indexPath
            cell.btnCheckbox.addTarget(self, action: #selector(self.checkboxSelection(_:)), for: .touchUpInside)
            return cell
        }
        
        Observable.zip(tblTodo.rx.modelSelected(Todo.self), tblTodo.rx.itemSelected)
            .bind { [weak self] (task, indexPath) in
                guard let addTaskVC = self?.storyboard?.instantiateViewController(identifier: AddTaskViewController.storyboardID) as? AddTaskViewController else { return }
                addTaskVC.editTask = task
                addTaskVC.indexPath = indexPath
                addTaskVC.delegate = self
                addTaskVC.currentDate = self?.viewModel.selectedDate.value
                
                self?.navigationController?.pushViewController(addTaskVC, animated: true)
            }
            .disposed(by: disposeBag)
        
        tblTodo.rx.itemDeleted
            .bind { indexPath in
                if indexPath.section == 0 {
                    _ = self.viewModel.remove(section: .scheduled, row: indexPath.row, date: nil)
                } else {
                    _ = self.viewModel.remove(section: .anytime, row: indexPath.row, date: nil)
                }
            }
            .disposed(by: disposeBag)
        
        tblTodo.rx.itemMoved
            .bind { srcIndexPath, dstIndexPath in
                var movedTask: Todo?
                
                if srcIndexPath.section == 0 {
                    movedTask = self.viewModel.remove(section: .scheduled, row: srcIndexPath.row, date: nil)
                } else {
                    movedTask = self.viewModel.remove(section: .anytime, row: srcIndexPath.row, date: nil)
                }
                
                if let movedTask = movedTask {
                    if dstIndexPath.section == 0 {
                        self.viewModel.insert(task: movedTask, section: .scheduled, row: dstIndexPath.row, date: nil)
                    } else {
                        self.viewModel.insert(task: movedTask, section: .anytime, row: dstIndexPath.row, date: nil)
                    }
                }
            }
            .disposed(by: disposeBag)
        
        dataSource.titleForHeaderInSection = { ds, index in
            let date = ds.sectionModels[index].date
            return date.isEmpty ? Section.anytime.rawValue : "\(Section.scheduled.rawValue) \(date)"
        }
        
        todoSections.asDriver()
            .drive(tblTodo.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
       
        Observable.combineLatest(viewModel.todoScheduled, viewModel.todoAnytime, viewModel.selectedDate)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] scheduled, anytime, date in
                let dateString = date.toString()
                self?.todoSections.accept([Task(date: dateString, items: scheduled[dateString] ?? []),
                                           Task(date: "", items: anytime)])
            })
            .disposed(by: disposeBag)
    }
    

    // MARK: - Actions
    

    @IBAction func addTaskButtonPressed(_ sender: UIButton) {
        // Create Task 화면 표시
        guard let addTaskVC = self.storyboard?.instantiateViewController(identifier: AddTaskViewController.storyboardID) as? AddTaskViewController else { return }
        addTaskVC.delegate = self
        addTaskVC.currentDate = viewModel.selectedDate.value
        
        self.navigationController?.pushViewController(addTaskVC, animated: true)
    }
    
   
    @IBAction func editTableButtonPressed(_ sender: UIBarButtonItem) {
        if tblTodo.isEditing {
            btnEditTable.title = "Edit"
            tblTodo.setEditing(false, animated: true)
        } else {
            btnEditTable.title = "Done"
            tblTodo.setEditing(true, animated: true)
        }
    }
    
    /* calendar barbutton pressed */
    @IBAction func calendarButtonPressed(_ sender: UIBarButtonItem) {
        // Calendar
        guard let calendarVC = self.storyboard?.instantiateViewController(identifier: CalendarViewController.storyboardID) as? CalendarViewController else { return }
        calendarVC.delegate = self
        calendarVC.todoScheduled = viewModel.todoScheduled.value
        calendarVC.selectedDate = viewModel.selectedDate.value
        
        let navController = UINavigationController(rootViewController: calendarVC)
        navController.modalPresentationStyle = .fullScreen
        
        present(navController, animated: true, completion: nil)
    }
    
    /* check box selection */
    @objc func checkboxSelection(_ sender: CheckUIButton) {
        guard let indexPath = sender.indexPath else { return }
        
        if indexPath.section == 0 {
            viewModel.changeComplete(section: .scheduled, row: indexPath.row)
        } else {
            viewModel.changeComplete(section: .anytime, row: indexPath.row)
        }
    }
    
    private func showAlert(title: String, message: String){
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "Ok", style: .default)
        ac.addAction(ok)
        present(ac, animated: true)
    }
}

// MARK: - SendDataDelegate

extension DailyTasksViewController: SendDataDelegate {
    
    /* Calendar -> DailyTasks */
    func sendData(scheduledTasks: [String : [Todo]], newDate: Date) {
        if !scheduledTasks.isEmpty {
            viewModel.todoScheduled.accept(scheduledTasks)
        }
        viewModel.selectedDate.accept(newDate)
    }
    
    /* AddTask -> DailyTasks */
    func sendData(oldTask: Todo?, newTask: Todo, indexPath: IndexPath?) {
        let oldDate = oldTask?.date ?? ""
        let newDate = newTask.date ?? ""
        
        // OldTask 제거
        if let _ = oldTask, let index = indexPath {
            if oldDate.isEmpty {    // Anytime
                _ = viewModel.remove(section: .anytime, row: index.row, date: nil)
            } else {                // Scheduled
                _ = viewModel.remove(section: .scheduled, row: index.row, date: oldTask?.date)
            }
        }
        
        // NewTask 추가
        if newDate.isEmpty {    // Anytime
            viewModel.insert(task: newTask, section: .anytime, row: indexPath?.row, date: nil)
        } else {                // Scheduled
            viewModel.insert(task: newTask, section: .scheduled, row: indexPath?.row, date: newDate)
        }
    }
}


// LOCATION / COORDINATES
extension DailyTasksViewController: CLLocationManagerDelegate , UICollectionViewDelegate,UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize{
        CGSize(width: collectionView.frame.size.width, height: 50)
    }

    // content of header
 
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.weatherData?.hourly.time.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WeatherCollectionViewCell", for: indexPath) as! WeatherCollectionViewCell
        let time = self.weatherData?.hourly.time[indexPath.row] ?? ""
        let temperature = self.weatherData?.hourly.temperature_2m[indexPath.row] ?? 0.0
        cell.setupWeather(time: time, weather: temperature)
        return cell
    }
    
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("location changed")
        
        if #available(iOS 14.0, *) {
            switch manager.authorizationStatus{
            case .notDetermined:
                break
            case .authorizedWhenInUse, .authorizedAlways:
                getLocation()
            default:
                showAlert(title: "Error", message: "Go to settings and allow location services for this app.")
                
            }
        } else {
            // Fallback on earlier versions
        }
        getLocation()
    }
    
    
    func getLocation(){
        guard let loc = locationManager.location?.coordinate else { return }
        
        coordinates = loc
        
        let date = Date()
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let theDate = dateFormatter.string(from: date)
        self.fetch(urlString:"https://api.open-meteo.com/v1/forecast?latitude=\(coordinates.latitude)&longitude=\(coordinates.longitude)&hourly=temperature_2m,rain&start_date=\(theDate)&end_date=\(theDate)")

    }
}

extension Date {

 static func getCurrentDate() -> String {

        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = "dd/MM/yyyy h:mm a"

        return dateFormatter.string(from: Date())

    }
}
