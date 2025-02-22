import Foundation
import UIKit
import CoreData

typealias DashboardSnapshot = NSDiffableDataSourceSnapshot<DashboardCardSection, DashboardCardModel>
typealias DashboardDataSource = UICollectionViewDiffableDataSource<DashboardCardSection, DashboardCardModel>

class BlogDashboardViewModel {
    private weak var viewController: BlogDashboardViewController?

    private let managedObjectContext: NSManagedObjectContext
    var blog: Blog

    private lazy var service: BlogDashboardService = {
        return BlogDashboardService(managedObjectContext: managedObjectContext)
    }()

    private lazy var dataSource: DashboardDataSource? = {
        guard let viewController = viewController else {
            return nil
        }

        return DashboardDataSource(collectionView: viewController.collectionView) { [unowned self] collectionView, indexPath, identifier in

            let cellType = identifier.id.cell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellType.defaultReuseID, for: indexPath)

            if let cellConfigurable = cell as? BlogDashboardCardConfigurable {
                cellConfigurable.configure(blog: blog, viewController: viewController, apiResponse: identifier.apiResponse)
            }

            return cell

        }
    }()

    init(viewController: BlogDashboardViewController, managedObjectContext: NSManagedObjectContext = ContextManager.shared.mainContext, blog: Blog) {
        self.viewController = viewController
        self.managedObjectContext = managedObjectContext
        self.blog = blog
    }

    /// Apply the initial configuration when the view loaded
    func viewDidLoad() {
        loadCardsFromCache()
    }

    /// Call the API to return cards for the current blog
    func loadCards() {
        guard let dotComID = blog.dotComID?.intValue else {
            return
        }

        viewController?.showLoading()

        service.fetch(wpComID: dotComID, completion: { [weak self] snapshot in
            self?.viewController?.stopLoading()
            self?.apply(snapshot: snapshot)
        }, failure: { [weak self] in
            self?.viewController?.stopLoading()
        })
    }

    func loadCardsFromCache() {
        guard let dotComID = blog.dotComID?.intValue else {
            return
        }

        let snapshot = service.fetchLocal(wpComID: dotComID)
        apply(snapshot: snapshot)
    }

    func card(for sectionIndex: Int) -> DashboardCard? {
        dataSource?.itemIdentifier(for: IndexPath(row: 0, section: sectionIndex))?.id
    }
}

// MARK: - Private methods

private extension BlogDashboardViewModel {

    func apply(snapshot: DashboardSnapshot) {
        dataSource?.apply(snapshot, animatingDifferences: false)
    }
}
