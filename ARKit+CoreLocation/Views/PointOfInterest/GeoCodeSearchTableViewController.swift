//
//  GeoCodeSearchTableViewController.swift
//  ARKit+CoreLocation
//
//  Created by Eric Internicola on 8/30/18.
//  Copyright © 2018 Project Dent. All rights reserved.
//

import UIKit

class GeoCodeSearchTableViewController: UITableViewController {

    @IBOutlet weak var searchBar: UISearchBar!

    var searchResults = [GeoCodeResult]()
    var savedLocations = [GeoCodeResult]()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        savedLocations = RealWorldLocationService.shared.worldPoints
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Notification.ArClExample.locationsUpdated.addObserver(observer: self, selector: #selector(tableUpdated(_:)))
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return searchResults.count
        }

        return savedLocations.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath)
        cell.textLabel?.numberOfLines = 0
        if indexPath.section == 0 {
            guard indexPath.row < searchResults.count else {
                return cell
            }
            cell.textLabel?.text = searchResults[indexPath.row].cellDisplayText
        } else {
            guard indexPath.row < savedLocations.count else {
                return cell
            }
            cell.textLabel?.text = savedLocations[indexPath.row].cellDisplayText
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 0, indexPath.row < searchResults.count else {
            return
        }
        let result = searchResults[indexPath.row]
        RealWorldLocationService.shared.worldPoints.append(result)
        dismiss(animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Search Results"
        }
        return "Saved Locations"
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return searchResults.count > 0 ? 32 : 0
        }
        return savedLocations.count > 0 ? 32 : 0
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 1
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        return [
            UITableViewRowAction(style: .destructive, title: "Delete", handler: { (_, indexPath) in
                defer {
                    tableView.endEditing(true)
                }
                guard indexPath.row < self.savedLocations.count else {
                    return
                }
                RealWorldLocationService.shared.worldPoints.remove(at: indexPath.row)
            })
        ]
    }

    @IBAction
    func tappedDone(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction
    func tableUpdated(_ notification: NSNotification) {
        savedLocations = RealWorldLocationService.shared.worldPoints
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }

}

// MARK: - UISearchBarDelegate

extension GeoCodeSearchTableViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text else {
            return
        }
        search(for: text)
    }
}

// MARK: - Searching

extension GeoCodeSearchTableViewController {

    func search(for address: String) {
        GeoCodeService.shared.getGeoCodes(for: address) { (results, error) in
            if let error = error {
                return print("Failed to search: \(error.localizedDescription)")
            }
            guard let results = results else {
                return print("ERROR: results came back nil")
            }
            DispatchQueue.main.async { [weak self] in
                self?.searchResults = results
                self?.tableView.reloadData()
            }
        }
    }

}
