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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath)
        guard indexPath.row < searchResults.count else {
            return cell
        }
        let result = searchResults[indexPath.row]
        cell.textLabel?.text = "\(result.city), \(result.state)"
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < searchResults.count else {
            return
        }
        let result = searchResults[indexPath.row]
        RealWorldLocationService.shared.worldPoints.append(result)
        dismiss(animated: true, completion: nil)
    }

    @IBAction
    func tappedDone(_ sender: Any) {
        dismiss(animated: true, completion: nil)
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
