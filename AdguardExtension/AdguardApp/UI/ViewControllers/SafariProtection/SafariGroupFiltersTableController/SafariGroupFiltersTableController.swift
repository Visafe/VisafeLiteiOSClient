/**
       This file is part of Adguard for iOS (https://github.com/AdguardTeam/AdguardForiOS).
       Copyright © Adguard Software Limited. All rights reserved.

       Adguard for iOS is free software: you can redistribute it and/or modify
       it under the terms of the GNU General Public License as published by
       the Free Software Foundation, either version 3 of the License, or
       (at your option) any later version.

       Adguard for iOS is distributed in the hope that it will be useful,
       but WITHOUT ANY WARRANTY; without even the implied warranty of
       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
       GNU General Public License for more details.

       You should have received a copy of the GNU General Public License
       along with Adguard for iOS.  If not, see <http://www.gnu.org/licenses/>.
 */

import UIKit
import SafariAdGuardSDK

final class SafariGroupFiltersTableController: UITableViewController {

    // MARK: - UI Elements

    @IBOutlet var searchButton: UIBarButtonItem!
    @IBOutlet var cancelButton: UIBarButtonItem!

    // MARK: - Public properties

    var displayType: DisplayType!

    enum DisplayType {
        case one(groupType: SafariGroup.GroupType)
        case all
    }

    // MARK: - Private properties

    private let filterDetailsSegueId = "FilterDetailsSegueId"
    private var selectedFilter: SafariGroup.Filter!
    private var headerView: AGSearchView?

    /* Services */
    private let themeService: ThemeServiceProtocol = ServiceLocator.shared.getService()!
    private let safariProtection: SafariProtectionProtocol = ServiceLocator.shared.getService()!
    private let configuration: ConfigurationServiceProtocol = ServiceLocator.shared.getService()!
    private var model: SafariGroupFiltersModelProtocol!

    // Observer
    private var proStatusObserver: NotificationToken?

    // MARK: - UITableViewController lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup view model
        switch displayType {
        case .one(let groupType):
            model = OneSafariGroupFiltersModel(groupType: groupType, safariProtection: safariProtection, configuration: configuration, themeService: themeService)
            navigationItem.rightBarButtonItems = [searchButton]

            proStatusObserver = NotificationCenter.default.observe(name: .proStatusChanged, object: nil, queue: .main) { [weak self] _ in
                if self?.configuration.proStatus == false && groupType.proOnly {
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        case .all:
            model = AllSafariGroupsFiltersModel(safariProtection: safariProtection, configuration: configuration)
            title = String.localizedString("navigation_item_filters_title")
            navigationItem.rightBarButtonItems = [cancelButton]
            addTableHeaderView()
            headerView?.textField.becomeFirstResponder()
        case .none:
            break
        }
        tableView.delegate = model
        tableView.dataSource = model
        model.setup(tableView: tableView)
        model.tableView = tableView
        model.delegate = self

        updateTheme()
        setupBackButton()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        guard let destinationVC = segue.destination as? FilterDetailsViewController else {
            return
        }
        destinationVC.filterMeta = selectedFilter
        destinationVC.delegate = model
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.layoutTableHeaderView()
    }

    // MARK: - Actions

    @IBAction func searchButtonTapped(_ sender: UIBarButtonItem) {
        navigationItem.rightBarButtonItems = [cancelButton]
        addTableHeaderView()
        headerView?.textField.becomeFirstResponder()
    }

    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        navigationItem.rightBarButtonItems = [searchButton]
        removeTableHeaderView()
        model.searchString = nil
    }

    // MARK: - Private methods

    private func addTableHeaderView() {
        headerView = AGSearchView()
        headerView?.delegate = self
        tableView.tableHeaderView = headerView

    }

    private func removeTableHeaderView() {
        headerView = nil
        tableView.tableHeaderView = nil
    }
}

// MARK: - SafariGroupFiltersTableController + SafariGroupFiltersModelDelegate

extension SafariGroupFiltersTableController: SafariGroupFiltersModelDelegate {

    func filterTapped(_ filter: SafariGroup.Filter) {
        selectedFilter = filter
        performSegue(withIdentifier: filterDetailsSegueId, sender: self)
    }

    func tagTapped(_ tagName: String) {
        if headerView == nil {
            addTableHeaderView()
        }

        let searchText = headerView?.textField.text ?? ""

        if !searchText.isEmpty {
            headerView?.textField.text = searchText + " " + tagName
        } else {
            headerView?.textField.text = tagName
        }
        model.searchString = headerView?.textField.text

        headerView?.textField.rightView?.isHidden = false
        headerView?.textField.becomeFirstResponder()
        navigationItem.rightBarButtonItems = [cancelButton]
    }

    func addNewFilterTapped() {
        let storyboard = UIStoryboard(name: "Filters", bundle: nil)
        guard let controller = storyboard.instantiateViewController(withIdentifier: "AddCustomFilterController") as? AddCustomFilterController else {
            return
        }

        controller.type = .safariCustom
        controller.delegate = model
        present(controller, animated: true, completion: nil)
    }
}

// MARK: - SafariGroupFiltersTableController + AGSearchViewDelegate

extension SafariGroupFiltersTableController: AGSearchViewDelegate {
    func textChanged(to newText: String) {
        model.searchString = newText
    }
}

// MARK: - SafariGroupFiltersTableController + ThemableProtocol

extension SafariGroupFiltersTableController: ThemableProtocol {
    func updateTheme() {
        view.backgroundColor = themeService.backgroundColor
        themeService.setupTable(tableView)
        tableView.reloadData()
    }
}