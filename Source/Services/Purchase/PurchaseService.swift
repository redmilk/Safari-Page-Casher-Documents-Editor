//
//  PurchaseService.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 20.12.2021.
//

import ApphudSDK
import StoreKit
import Combine

// if has subscr - non gift
// if was subscr,

//    Недельная подписка имеет предложение для новых пользователей - 3 дня бесплатно (встроенно)
//    Также у недельной подписки есть промо оффер appid.weekly.offer - 2.99 за первую неделю
//    При запуске чекается если у юзера не было подписки то ему предлагается недельная подписка с триалом на 3 дня
//    Если юзер уже использовал триал то ему выдается промооффер appid.weekly.offer
//    Если юзер использовал и то и то то ему выдается просто недельная подписка
//    При выводе годовой подписки рядом всегда пишем зачеркную цену х2 типа подарок
//    1) если юзер не подписался а закрыл окно то висит плашка хау ту триал воркс где предлагается промо предложение на 3 дня appid.weekly
//    2) если юзер использовал промо и отписался то ему предлагается appid.weekly.offer с 2.99 за первую неделю
//    3) если юзер не проходит под правила выше то выходит плашка с гифтом где внутри предлагает подписаться на год


enum PurchaseError: Error {
    case error(String)
}

final class PurchesService {
    enum Response {
        case timerTick(String)
    }
    
    let output = PassthroughSubject<Response, Never>()
    var isActiveSubscription = CurrentValueSubject<Bool?, Never>(nil)
    let products = CurrentValueSubject<[ApphudProduct], Never>([])
    private var bag = Set<AnyCancellable>()
    private var giftOfferTimerCancellable: AnyCancellable?
    private var giftOfferTimerEnds: Date?
        
    init() {
        Apphud.paywallsDidLoadCallback { [unowned self] (paywalls) in
            let paywall = paywalls
            print("paywall:=\(paywall)")
            let products = paywall.map({ $0.products }).flatMap({ $0 })
            products.forEach { product in
                print("productid:=\(product.productId)")
            }
            print("products:=\(products)")
            print("")
            self.products.send(products)
            refreshPurchase()
        }
    }
    
    func startTimerForGiftOffer() {
        giftOfferTimerEnds = Date().addingTimeInterval(10 * 60)
        giftOfferTimerCancellable?.cancel()
        giftOfferTimerCancellable = Timer.publish(every: 1, on: .main, in: .default)
            .autoconnect()
            .sink(receiveValue: { [weak self] date in
                guard let self = self, let endDate = self.giftOfferTimerEnds else { return }
                let distanceTimeInterval: Int = Int(date.distance(to: endDate).rounded(.up))
                let min = Int(distanceTimeInterval / 60)
                let sec = distanceTimeInterval % 60
                if min <= 0 && sec <= 0 {
                    self.startTimerForGiftOffer()
                }
                self.output.send(.timerTick("\(min) min \(sec) sec"))
            })
    }
    
    func checkSubscriptionsState() {
        let isUserAlreadyHadSubscription = false
        let isTrialHasBeenUsed = false
        let isTrialAndWeekWithTrialWasUsed = false
        let isTrialWasUsedAndHeCanceledSubscription = false
        let isSpecialGiftShouldBeShown = !isTrialHasBeenUsed && !isTrialAndWeekWithTrialWasUsed && !isTrialWasUsedAndHeCanceledSubscription
    }
    
    func refreshPurchase() {
        var isActive = false
        let activeSubscription = Apphud.subscriptions()?.first(where: { $0.isActive() })
        if activeSubscription?.status == .trial && activeSubscription?.canceledAt != nil {
            isActive = false
        } else {
            isActive = Apphud.hasActiveSubscription()
            print("hasActiveSubscription:=\(isActive)")
        }
        guard isActive != isActiveSubscription.value else { return }
        print("isActive:=\(isActive)")
        isActiveSubscription.send(isActive)
    }
    
    func getPurchase(model: Purchase) -> ApphudProduct? {
        return products.value.filter({ $0.productId == model.productId }).last
    }
    
    func checkIfPurchaseIsActive(_ purchase: Purchase) -> Bool {
        guard let purchase = Apphud.subscriptions()?
                .filter({ $0.productId == purchase.productId })
                .first(where: { $0.isActive() }) else { return false }
        print("purchase:=\(purchase)")
        return true
    }
    
    func buy(model: Purchase) -> AnyPublisher<Bool, PurchaseError> {
       return Deferred {
            Future<Bool, PurchaseError> { [unowned self] promise in
                guard let product = self.getPurchase(model: model) else {
                    return promise(.failure(PurchaseError.error("Couldn't load this product")))
                }
                let callback: ((ApphudPurchaseResult) -> Void) = { result in
                    if let subscription = result.subscription, subscription.isActive() {
                        promise(.success(true))
                        self.refreshPurchase()
                    } else if let purchase = result.nonRenewingPurchase, purchase.isActive() {
                        promise(.success(true))
                        self.refreshPurchase()
                    } else if let error = result.error as? SKError {
                        switch error.code {
                        case .unknown:
                            promise(.success(false))
                        case .clientInvalid:
                            promise(.success(false))
                        case .paymentCancelled:
                            promise(.success(false))
                        case .paymentInvalid:
                            promise(.success(false))
                        case .paymentNotAllowed:
                            promise(.failure(PurchaseError.error("Purchase is not allowed on your device")))
                        case .storeProductNotAvailable:
                            promise(.success(false))
                        case .cloudServicePermissionDenied:
                            promise(.failure(PurchaseError.error("Access denied, try another account \(error)")))
                        case .cloudServiceNetworkConnectionFailed:
                            promise(.failure(PurchaseError.error("Could not connect to network")))
                        default:
                            break
                        }
                    } else if let error = result.error {
                        promise(.failure(PurchaseError.error(error.localizedDescription)))
                    }
                }
                
                if let promo = model.promoId, let productStoreKit = product.skProduct {
                    Apphud.purchasePromo(productStoreKit, discountID: promo, callback)
                } else {
                    Apphud.purchase(product, callback: callback)
                }
            }
       }
       .eraseToAnyPublisher()
    }
    
    // MARK: - Promo
    func isAvaliablePromo() -> Bool {
        guard let subscriptions = Apphud.subscriptions() else { return true }
        return subscriptions.filter({$0.status == .promo}).isEmpty
    }
    func promoPurchase() -> Purchase {
        if !hadPurchase() {
            return .weekly
        } else {
            return .annual
        }
    }
    
    func singlePurchase() -> Purchase {
        if !hadPurchase() {
            return .weekly
        } else {
            return .weeklyTrial
        }
    }
    
    func listOfPurchase() -> [Purchase] {
        return [.monthly, .annual]
    }
    
    func fullListOfPurchase() -> [Purchase] {
        return [.weekly, .monthly, .annual]
    }
    
    func hadPurchase() -> Bool {
        return !(Apphud.subscriptions()?.isEmpty ?? true)
    }
    
    func restorePurchases() -> AnyPublisher<Bool, PurchaseError> {
        return Deferred {
            Future<Bool, PurchaseError> { promise in
                Apphud.restorePurchases{[unowned self] subscription, purchases, error in
                    if let subscription = subscription, !subscription.filter({$0.isActive()}).isEmpty {
                        self.refreshPurchase()
                        promise(.success(false))
                    } else if error != nil {
                        promise(.failure(PurchaseError.error(error?.localizedDescription ?? "Error purchase")))
                    } else {
                        promise(.failure(PurchaseError.error(error?.localizedDescription ?? "Nothing to restore")))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

//protocol PurchesServicable {
//    var products: BehaviorRelay<[ApphudProduct]> {get}
//    var isActiveSubscription: BehaviorRelay<Bool?> {get}
//    func getPurchase(model: Purchase) -> ApphudProduct?
//    func buy(model: Purchase) -> Observable<Bool>
//    func isActiv(model: Purchase) -> Bool
//    func restorePurchases() -> Observable<Bool>
//    func promoPurchase() -> Purchase
//    func singlePurchase() -> Purchase
//    func listOfPurchase() -> [Purchase]
//    func hadPurchase() -> Bool
//    func fullListOfPurchase() -> [Purchase]
//}
