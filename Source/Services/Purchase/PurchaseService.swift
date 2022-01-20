//
//  PurchaseService.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 20.12.2021.
//

import ApphudSDK
import StoreKit
import Combine


fileprivate let kShouldShowSubscriptionsToNewUser = "kShouldShowSubscriptionsToNewUser"
fileprivate let kHasUserActiveSubscriptionsCached = "kDoesUserHaveActiveSubscriptionsCachedSinceLastSession"

fileprivate let kPreviousWeeklyPrice = "kPreviousWeeklyPrice"
fileprivate let kPreviousMonthlyPrice = "kPreviousMonthlyPrice"
fileprivate let kPreviousYearlyPrice = "kPreviousYearlyPrice"

enum PurchaseError: Error {
    case error(String)
}

extension SKProduct {
    var localizedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: price) ?? ""
    }
}

final class PurchesService {
    
    enum Action {
        case congifure
    }
    
    enum Response {
        case timerTick(String)
        case hasActiveSubscriptions(hasActiveSubscription: Bool, shouldShowHowItWorks: Bool)
        case gotUpdatedPrices(weekly: String, monthly: String, yearly: String)
    }
    
    static var hasUserActiveSubscriptionPricesCached: [String]? {
        get { (UserDefaults.standard.value(forKey: kHasUserActiveSubscriptionsCached) as? [String]) ?? nil }
        set { UserDefaults.standard.set(newValue, forKey: kHasUserActiveSubscriptionsCached) }
    }
    
    static var shouldDisplaySubscriptionsForCurrentUser: Bool {
        get { (UserDefaults.standard.value(forKey: kShouldShowSubscriptionsToNewUser) as? Bool) ?? true }
        set { UserDefaults.standard.set(newValue, forKey: kShouldShowSubscriptionsToNewUser) }
    }
    
    static var isUserHasActiveSubscriptionsStatusSinceLastUserSession: Bool {
        get { (UserDefaults.standard.value(forKey: kHasUserActiveSubscriptionsCached) as? Bool) ?? false }
        set { UserDefaults.standard.set(newValue, forKey: kHasUserActiveSubscriptionsCached) }
    }
    /// cached prices
    static var previousWeeklyPrice: String {
        get { (UserDefaults.standard.value(forKey: kPreviousWeeklyPrice) as? String) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: kPreviousWeeklyPrice) }
    }
    static var previousMonthlyPrice: String {
        get { (UserDefaults.standard.value(forKey: kPreviousMonthlyPrice) as? String) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: kPreviousMonthlyPrice) }
    }
    static var previousYearlyPrice: String {
        get { (UserDefaults.standard.value(forKey: kPreviousYearlyPrice) as? String) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: kPreviousYearlyPrice) }
    }
    
    let input = PassthroughSubject<Action, Never>()
    let output = PassthroughSubject<Response, Never>()
    
    /// determine if user has active subscriptions and which was not canceled during trial period
    private var _isUserHasActiveSubscription: Bool?
    var isUserHasActiveSubscription: Bool {
        _isUserHasActiveSubscription ?? PurchesService.isUserHasActiveSubscriptionsStatusSinceLastUserSession
    }
    /// check if user had any subscription
    var isUserEverHadSubscriptions: Bool {
        let d = Apphud.subscriptions()?.isEmpty ?? false
        return d
    }
    /// weekly discaunt prices case: no active subs && no previus subs
    var isWeeklyPlanWithDiscaunt: Bool { !isUserHasActiveSubscription && !isUserEverHadSubscriptions }
    /// gift section should be visible: no active subs
    var isGiftPopupShouldBeVisibleForUser: Bool { !isUserHasActiveSubscription }
    /// how it works should be shown: not even trial was tried
    var isHowItWorksShouldBeVisibleForUser: Bool { !isUserHasActiveSubscription && !isUserEverHadSubscriptions }
    /// was at least one request for update
    var isConnectionWasOccuredAndReceivedUpdates: Bool = false
    
    /// configured in-app purchases data
    let appPurchasesInfoList = CurrentValueSubject<[ApphudProduct], Never>([])

    private var updatedPrices: (weekly: String, monthly: String, yearly: String) = ("", "", "")
    private var giftOfferTimerCancellable: AnyCancellable?
    private var giftOfferTimerEnds: Date?
    private var bag = Set<AnyCancellable>()
        
    init() {
        input.sink(receiveValue: { [weak self] action in
            switch action {
            case .congifure:
                self?.configure()
            }
        }).store(in: &bag)
    }
    
    private func configure() {
        /// callback when all apphud necessary data is loaded
        Apphud.paywallsDidLoadCallback { [weak self] (paywalls) in
            let paywall = paywalls
            let appPurchasesInfoList = paywall.map({ $0.products }).flatMap({ $0 })
            Logger.log("\(appPurchasesInfoList)", type: .purchase)
            self?.appPurchasesInfoList.send(appPurchasesInfoList)
            self?.updatedAllPrices()
            self?.refreshUserPurchasesStatus()
            self?.isConnectionWasOccuredAndReceivedUpdates = true
        }
    }
    
    /// get specific in-app purchase info
    func getCurrentPurchase(model: Purchase) -> ApphudProduct? {
        appPurchasesInfoList.value.filter({ $0.productId == model.productId }).last
    }
    
    func updatedAllPrices() {
        updatedPrices.weekly = getPriceForPurchase(model: .weekly) ?? ""
        if updatedPrices.weekly != "" {
            PurchesService.previousWeeklyPrice = updatedPrices.weekly
        }
        updatedPrices.monthly = getPriceForPurchase(model: .monthly) ?? ""
        if updatedPrices.monthly != "" {
            PurchesService.previousMonthlyPrice = updatedPrices.monthly
        }
        updatedPrices.yearly = getPriceForPurchase(model: .annual) ?? ""
        if updatedPrices.yearly != "" {
            PurchesService.previousYearlyPrice = updatedPrices.yearly
        }
        output.send(.gotUpdatedPrices(weekly: updatedPrices.weekly.withoutTrailingZeros, monthly:updatedPrices.monthly.withoutTrailingZeros, yearly: updatedPrices
                                        .yearly.withoutTrailingZeros))
    }
    
    func getPriceForPurchase(model: Purchase) -> String? {
        let price = appPurchasesInfoList.value.filter({ $0.productId == model.productId })
            .last?.skProduct?.localizedPrice.withoutTrailingZeros ?? nil
        guard let price = price else { return nil }
        switch model {
        case .weekly: PurchesService.previousWeeklyPrice = price
        case .monthly: PurchesService.previousMonthlyPrice = price
        case .annual: PurchesService.previousYearlyPrice = price
        }
        return price
    }
    
    func getFormattedYearPriceForPurchase(isPurePrice: Bool = false, size: CGFloat = 12) -> NSMutableAttributedString? {
        let productId = Purchase.annual.productId
        guard let product = appPurchasesInfoList.value.filter({ $0.productId == productId })
                .last?.skProduct else { return nil }
        let price = product.price
        let currencyCode = " " + (product.priceLocale.currencyCode ?? "")
        let priceParts = String.makeAttriabutedStringNoFormatting(" / ", size: size)
        var priceDoubled = (Int(truncating: price) * 2).description
        priceDoubled.append(currencyCode)
        let strikedPrice = String.makeStrikeThroughText(priceDoubled, size: size)
        if isPurePrice {
            return strikedPrice
        }
        priceParts.append(strikedPrice)
        return priceParts
    }
    
    /// check if user's specific purchase is still active
    func checkIfPurchaseIsActive(_ purchase: Purchase) -> Bool {
        Apphud.subscriptions()?
            .filter({ $0.productId == purchase.productId })
            .first(where: { $0.isActive() }) != nil
    }
    
    /// determine if user has active subscriptions and which was not canceled during trial period
    func refreshUserPurchasesStatus() {
        /// if subscription was cancelled on trial period
        if let activeSubscription = Apphud.subscriptions()?.first(where: { $0.isActive() }),
           activeSubscription.status == .trial && activeSubscription.canceledAt != nil {
            _isUserHasActiveSubscription = false
        } else {
            _isUserHasActiveSubscription = Apphud.hasActiveSubscription()
        }
        PurchesService.isUserHasActiveSubscriptionsStatusSinceLastUserSession = _isUserHasActiveSubscription ?? isUserHasActiveSubscription
        output.send(.hasActiveSubscriptions(
            hasActiveSubscription: _isUserHasActiveSubscription ?? isUserHasActiveSubscription, shouldShowHowItWorks: isHowItWorksShouldBeVisibleForUser))
        Logger.log("Does user have active and not canceled subscriptions: \(isUserHasActiveSubscription.description.uppercased())", type: .purchase)
    }
    
    /// make purchase
    func buy(model: Purchase) -> AnyPublisher<(), Error> {
       return Deferred {
            Future<(), Error> { [weak self] promise in
                /// attempt to get all data about this purchase
                guard let product = self?.getCurrentPurchase(model: model) else {
                    return promise(.failure(PurchaseError.error("Couldn't load this product")))
                }
                let callback: ((ApphudPurchaseResult) -> Void) = { purchaseResultModel in
                    /// got error during buy subscription process
                    if let error = purchaseResultModel.error {
                        return promise(.failure(error))
                        /// attempt to fetch subscription model from purchaseResult and check it isActive state
                    } else if let subscription = purchaseResultModel.subscription, subscription.isActive() {
                        promise(.success(()))
                        self?.refreshUserPurchasesStatus()
                    /// attempt to fetch nonRenewingPurchase model from purchaseResult and check it isActive state
                    } else if let purchase = purchaseResultModel.nonRenewingPurchase, purchase.isActive() {
                        promise(.success(()))
                        self?.refreshUserPurchasesStatus()
                    }
                }
                Apphud.purchase(product, callback: callback)
            }
       }
       .eraseToAnyPublisher()
    }
        
    /// restore previous purchase which did expire
    /// refresh available in-app purchases for app and user's subscriptions status
    func restoreLastExpiredPurchase() -> AnyPublisher<Bool, PurchaseError> {
        /// refresh available in-app purchases for app
        return Deferred {
            Future<Bool, PurchaseError> { promise in
                Apphud.restorePurchases { [weak self] subscriptions, purchases, error in
                    if let error = error, let purchaseError = self?.handlePurchasesError(error) {
                        Logger.logError(purchaseError)
                        return promise(.failure(purchaseError))
                    }
                    /// if we have active subscription plans configured
                    if let subscriptions = subscriptions, !subscriptions.filter({ $0.isActive() }).isEmpty {
                        /// determine if user has active subscriptions and which was not canceled during trial period
                        self?.refreshUserPurchasesStatus()
                        promise(.success(true))
                    } else {
                        promise(.success(false))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// timer for gift offer
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
    
    func handleErrorAsErrorText(_ error: Error) -> String {
        let purchaseError: PurchaseError = handlePurchasesError(error)
        switch purchaseError {
        case .error(let errorMessage):
            Logger.log(errorMessage)
            return errorMessage
        }
    }
    
    /// purchases error handling
    private func handlePurchasesError(_ error: Error) -> PurchaseError {
        if let _ = error as? URLError {
            return PurchaseError.error("Connection error: \((error as NSError).code). Message: \((error as NSError).localizedDescription)")
        } else if let appHudError = error as? ApphudError {
            _ = appHudError.userInfo[NSLocalizedFailureReasonErrorKey] as? NSString
            _ = appHudError.userInfo[NSLocalizedDescriptionKey] as? NSString
            return PurchaseError.error("Payments internal error: \((error as NSError).code). Message: \((error as NSError).localizedDescription)")
        } else if let skError = error as? SKError {
            switch skError.code {
            case .clientInvalid:
                return PurchaseError.error("Indicating that the client is not allowed to perform the attempted purchase action")
            case .paymentCancelled:
                return PurchaseError.error("Payment request was canceled")
            case .paymentInvalid:
                return PurchaseError.error("One of the payment parameters wasn’t recognized by the App Store")
            case .storeProductNotAvailable:
                return PurchaseError.error("Requested product is not available in the store")
            case .paymentNotAllowed:
                return PurchaseError.error("The user is not allowed to authorize payments")
            case .cloudServicePermissionDenied:
                return PurchaseError.error("The user has not allowed access to Cloud service information")
            case .cloudServiceNetworkConnectionFailed:
                return PurchaseError.error("Could not connect to network")
            case .unknown:
                return PurchaseError.error("Unknown error during purchase")
            case _:
                return PurchaseError.error("Unhandled error. Something went wrong during purchase")
            }
        } else if (error as NSError).code == -1001 {
            return PurchaseError.error("Please check your network connection")
        }
        return PurchaseError.error("Feels like something went wrong...")
    }
}


// if has subscr - non gift

//    Недельная подписка имеет предложение для новых пользователей - 3 дня бесплатно (встроенно)
//    Также у недельной подписки есть промо оффер appid.weekly.offer - 2.99 за первую неделю
//    При запуске чекается если у юзера не было подписки то ему предлагается недельная подписка с триалом на 3 дня
//    Если юзер уже использовал триал то ему выдается промооффер appid.weekly.offer
//    Если юзер использовал и то и то то ему выдается просто недельная подписка
//    При выводе годовой подписки рядом всегда пишем зачеркную цену х2 типа подарок
//    1) если юзер не подписался а закрыл окно то висит плашка хау ту триал воркс где предлагается промо предложение на 3 дня appid.weekly
//    2) если юзер использовал промо и отписался то ему предлагается appid.weekly.offer с 2.99 за первую неделю
//    3) если юзер не проходит под правила выше то выходит плашка с гифтом где внутри предлагает подписаться на год
