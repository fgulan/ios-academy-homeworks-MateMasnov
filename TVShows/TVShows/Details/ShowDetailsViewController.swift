//
//  ShowDetailsViewController.swift
//  TVShows
//
//  Created by Infinum Student Academy on 26/07/2018.
//  Copyright © 2018 Mate Masnov. All rights reserved.
//

import UIKit
import PromiseKit
import CodableAlamofire

class ShowDetailsViewController: UIViewController, Progressable {

    //MARK: - Privates -
    private var showId: String!
    private var token: String!
    private var showDetails: ShowDetails?
    private var episodesList: [Show] = []
    
    //MARK: - Outlets -
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.dataSource = self
            tableView.delegate = self
            tableView.estimatedRowHeight = 100
        }
    }
    
    //MARK: - Controller functions -
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView()
        
        loadDetails()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    func setShowId(showId: String) {
        self.showId = showId
    }
    
    func setToken(token: String) {
        self.token = token
    }

    //MARK: - API functions -
    private func getDetailsAPICall(token: String, showId: String) -> Promise<ShowDetails> {
        let headers = ["Authorization": token]
        
        return Promise {
            seal in
            
            Alamofire
                .request("https://api.infinum.academy/api/shows/\(showId)",
                         method: .get,
                         encoding: JSONEncoding.default,
                         headers: headers)
                .validate()
                .responseDecodableObject(keyPath: "data", decoder: JSONDecoder()) {
                    (response: DataResponse<ShowDetails>) in
                    
                    switch response.result {
                    case .success(let detailsResponse):
                        seal.fulfill(detailsResponse)
                    case .failure(let error):
                        seal.reject(error)
                    }
            }
        }
    }
    
    private func getAllEpisodesAPICall(token: String, showId: String) -> Promise<[Show]> {
        let headers = ["Authorization": token]
        
        return Promise {
            seal in
            
            Alamofire
                .request("https://api.infinum.academy/api/shows/\(showId)/episodes",
                    method: .get,
                    encoding: JSONEncoding.default,
                    headers: headers)
                .validate()
                .responseDecodableObject(keyPath: "data", decoder: JSONDecoder()) {
                    (response: DataResponse<[Show]>) in
                    
                    switch response.result {
                    case .success(let episodes):
                        seal.fulfill(episodes)
                    case .failure(let error):
                        seal.reject(error)
                    }
            }
        }
    }
    
    private func loadDetails() {
        showSpinner()
        getDetailsAPICall(token: token, showId: showId)
            .then({ (showDetails) -> Promise<[Show]> in
                self.showDetails = showDetails
                return self.getAllEpisodesAPICall(token: self.token, showId: self.showId)
            })
            .done { [weak self] (episodes) in
                guard let `self` = self else { return }
                
                self.episodesList = episodes
                self.tableView.reloadData()
            }
            .catch { [weak self] (error) in
                guard let `self` = self else { return }
                
                self.presentAlert(title: "API error", message: "Something went wrong")
            }
            .finally { [weak self] in
                self?.hideSpinner()
        }
    }
    
    //MARK: - Actions -
    @IBAction
    func backButtonAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction
    func addEpisodeAction(_ sender: Any) {
        let addEpisodeStoryboard: UIStoryboard = UIStoryboard(name: "AddEpisode", bundle: nil)
        let addEpisodeViewController =
            addEpisodeStoryboard.instantiateViewController(withIdentifier: "AddEpisodeViewController")
                as! AddEpisodeViewController
        let navigationController = UINavigationController.init(rootViewController: addEpisodeViewController)
        
        addEpisodeViewController.delegate = self
        addEpisodeViewController.setToken(token: token)
        addEpisodeViewController.setShowId(showId: showId)
        
        present(navigationController, animated: true, completion: nil)
    }
}

//MARK: - Extensions -
extension ShowDetailsViewController: AddEpisodeControllerDelegate {
    func addedEpisode(episode: Episode) {
        showSpinner()
        
        let newShow: Show = Show(id: episode.showId, title: episode.title, imageUrl: episode.imageUrl, likesCount: nil)
        episodesList.append(newShow)
        tableView.reloadData()
        hideSpinner()
    }
}

extension ShowDetailsViewController: UITableViewDelegate {
    
}

extension ShowDetailsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if episodesList.count == 0 {
            return 0
        }
        
        return episodesList.count + 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row: Int = indexPath.row
        
        if row == 0 {
            let cell: ShowImageTableViewCell = tableView.dequeueReusableCell(
                withIdentifier: "ShowImageTableViewCell",
                for: indexPath
                ) as! ShowImageTableViewCell
            
            let item: ImageCellItem = ImageCellItem(url: "")
            
            cell.configure(with: item)
            
            return cell
        } else if row == 1 {
            let cell: ShowDescriptionTableViewCell = tableView.dequeueReusableCell(
                withIdentifier: "ShowDescriptionTableViewCell",
                for: indexPath
                ) as! ShowDescriptionTableViewCell
            
            guard let showDetails = showDetails else { return cell }
            
            let description: String = showDetails.description == "" ? "No description" : showDetails.description
            let item: DescriptionCellItem = DescriptionCellItem(title: showDetails.title, description: description, numberOfEpisodes: episodesList.count)
            
            cell.configure(with: item)
            
            return cell
        } else {
            let cell: EpisodeTableViewCell = tableView.dequeueReusableCell(
                withIdentifier: "EpisodeTableViewCell",
                for: indexPath
                ) as! EpisodeTableViewCell
            
            let title: String = episodesList[row - 2].title == "" ? "No title" : episodesList[row - 2].title
            let item: EpisodeCellItem = EpisodeCellItem(title: title, details: "S2 E\(row - 1)")
            
            cell.configure(with: item)
            
            return cell
        }
    
    }
}
