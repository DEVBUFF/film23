//
//  IAPManager.swift
//  film24
//
//  Created by Igor Ryazancev on 10.01.2023.
//

import StoreKit
import TPInAppReceipt

typealias ProductType = IAPManager.ProductType

protocol IAPManagerDelegate: AnyObject {
    func loadingProducts()
    func loadProductsFinished()
    func inAppLoadingStarted()
    func inAppLoadingSucceded(productType: ProductType)
    func inAppLoadingFailed(error: Swift.Error?, productType: ProductType)
    func subscriptionStatusUpdated(value: Bool)
    func restored(productType: ProductType)
    func purchasesNotFound()
}

class IAPManager: NSObject {
    
    static let shared = IAPManager()
    
    private override init() {}
    
    let paymentQueue = SKPaymentQueue.default()
        
    private(set) var products: [SKProduct]? {
        didSet {
            products?.sort { $0.price.floatValue < $1.price.floatValue }
        }
    }
    weak var delegate: IAPManagerDelegate?
    
    var isSubscriptionAvailable: Bool = true {
        didSet(value) {
            self.delegate?.subscriptionStatusUpdated(value: value)
        }
    }
        
    deinit {
        print("IAPManager - deinited")
    }
    
    func removeObserver() {
        paymentQueue.remove(self)
    }
    
    //public methods
    func loadProducts() {
        let productIdentifiers = Set<String>(ProductType.all.map({$0.rawValue}))
        let request = SKProductsRequest(productIdentifiers: productIdentifiers)
        request.delegate = self
        request.start()
        paymentQueue.add(self)
        delegate?.loadingProducts()
    }
    
    func purchaseProduct(productType: ProductType) {
        guard let products = self.products else { return }
        guard let product = products.filter({$0.productIdentifier == productType.rawValue}).first else {
            self.delegate?.inAppLoadingFailed(error: InAppErrors.noProductsAvailable, productType: productType)
            return
        }
        let payment = SKMutablePayment(product: product)
        paymentQueue.add(payment)
    }
    
    func restorePurchases() {
        if (SKPaymentQueue.canMakePayments()) {
            paymentQueue.restoreCompletedTransactions()
        }
    }
    
}

//MARK: - Public methods
extension IAPManager {
    
    func hasSubscription() -> Bool {
       return isSubscriptionActive()
    }
    
}

//MARK: - Private methods
private extension IAPManager {
    
    func isSubscriptionActive() -> Bool {
        if let receipt = try? InAppReceipt.localReceipt(){
            if receipt.hasActiveAutoRenewablePurchases {
                 return true
            }
        }
        
        return false
    }
    
}

////MARK: - SKPaymentTransactionObserver
extension IAPManager: SKPaymentTransactionObserver {
    
    func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        print("Transactions count: = \(transactions.count)")
        print("Transactions queue count: = \(queue.transactions.count)")
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        print("Transactions count: = \(transactions.count)")
        print("Transactions queue count: = \(queue.transactions.count)")
        for transaction in transactions {
            guard let productType = ProductType(rawValue: transaction.payment.productIdentifier) else { return }

            switch transaction.transactionState {
            case .purchasing:
                self.delegate?.inAppLoadingStarted()
            case .purchased:
                self.isSubscriptionAvailable = true
                self.delegate?.inAppLoadingSucceded(productType: productType)
                paymentQueue.finishTransaction(transaction)
            case .failed:
                if let transactionError = transaction.error as NSError?,
                    transactionError.code != SKError.paymentCancelled.rawValue {
                    if transactionError.code == 0 {
                        restorePurchases()
                    } else {
                        self.delegate?.inAppLoadingFailed(error: transaction.error, productType: productType)
                    }

                } else {
                    self.delegate?.inAppLoadingFailed(error: InAppErrors.noSubscriptionPurchased, productType: productType)
                }
                paymentQueue.finishTransaction(transaction)
            case .restored:
                paymentQueue.finishTransaction(transaction)
                guard hasSubscription() else {
                    delegate?.purchasesNotFound()
                    finishTransactions()
                    return
                }
                self.isSubscriptionAvailable = true
                self.delegate?.restored(productType: productType)

            case .deferred:
                self.delegate?.inAppLoadingFailed(error: nil, productType: productType)
                paymentQueue.finishTransaction(transaction)
            print("deferred")
            @unknown default:
                fatalError()
            }
        }
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        print("finished")
        if queue.transactions.isEmpty {
            delegate?.purchasesNotFound()
        }
    }
    
    func finishTransactions() {
        for transaction in paymentQueue.transactions {
            paymentQueue.finishTransaction(transaction)
        }
        print(paymentQueue.transactions.count)
    }


}

////MARK: - SKProductsRequestDelegate
extension IAPManager: SKProductsRequestDelegate {

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        self.products = response.products
        delegate?.loadProductsFinished()
    }

}

//MARK: - Common
extension IAPManager {
    
    enum ProductType: String {
        case monthly = "com.film24.subscription_monthly"
       
        var type: String {
            switch self {
            case .monthly:
                return "monthly"
            }
        }
        
        static var all: [ProductType] = [.monthly]
        
    }
    
    enum InAppErrors: Swift.Error {
        case noSubscriptionPurchased
        case noProductsAvailable
        
        var localizedDescription: String {
            switch self {
            case .noSubscriptionPurchased:
                return "No subscription purchased"
            case .noProductsAvailable:
                return "No products available"
            }
        }
    }
    
}

