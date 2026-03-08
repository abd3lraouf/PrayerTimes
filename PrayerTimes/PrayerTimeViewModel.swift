import Foundation
import Combine
import Adhan
import CoreLocation
import SwiftUI
import AppKit
import NavigationStack

@propertyWrapper
struct FlexibleDouble: Codable, Equatable, Hashable {
    var wrappedValue: Double
    init(wrappedValue: Double) { self.wrappedValue = wrappedValue }
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let doubleValue = try? container.decode(Double.self) {
            wrappedValue = doubleValue
        } else if let stringValue = try? container.decode(String.self), let doubleValue = Double(stringValue) {
            wrappedValue = doubleValue
        } else {
            throw DecodingError.typeMismatch(Double.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected Double or String representing Double"))
        }
    }
}

class PrayerTimeViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var menuTitle: NSAttributedString = NSAttributedString(string: NSLocalizedString("PrayerTimes Pro", comment: ""))
    @Published var todayTimes: [String: Date] = [:]
    @Published var nextPrayerName: String = ""
    @Published var countdown: String = "--:--"
    @Published var locationStatusText: String = NSLocalizedString("Preparing prayer schedule...", comment: "")
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var locationSearchQuery: String = ""
    @Published var locationSearchResults: [LocationSearchResult] = []
    @Published var isLocationSearching: Bool = false
    @Published var locationSearchError: String? = nil
    @Published var locationInfoText: String = ""
    @Published var isPrayerImminent: Bool = false
    @Published var isRequestingLocation: Bool = false

    let notificationSettings = NotificationSettings()
    var fastingManager: FastingModeManager?
    private let languageManager = LanguageManager()
    private var automaticLocationCache: (name: String, coordinates: CLLocationCoordinate2D)?
    private var tomorrowFajrTime: Date?

    @AppStorage(StorageKeys.animationType) var animationType: AnimationType = .fade
    @AppStorage(StorageKeys.useMinimalMenuBarText) var useMinimalMenuBarText: Bool = false { didSet { _cachedDateFormatter = nil; updateAndDisplayTimes() } }
    @AppStorage(StorageKeys.showSunnahPrayers) var showSunnahPrayers: Bool = false { didSet { updatePrayerTimes() } }
    @AppStorage(StorageKeys.useAccentColor) var useAccentColor: Bool = true
    @AppStorage(StorageKeys.useCompactLayout) var useCompactLayout: Bool = false
    @AppStorage(StorageKeys.use24HourFormat) var use24HourFormat: Bool = false { didSet { _cachedDateFormatter = nil; updateAndDisplayTimes() } }
    @AppStorage(StorageKeys.useHanafiMadhhab) var useHanafiMadhhab: Bool = false { didSet { updatePrayerTimes() } }
    @AppStorage(StorageKeys.isUsingManualLocation) var isUsingManualLocation: Bool = false
    @AppStorage(StorageKeys.hasManuallySelectedMethod) var hasManuallySelectedMethod: Bool = false
    @AppStorage(StorageKeys.lastDetectedCountryCode) private var lastDetectedCountryCode: String = ""
    @Published var suggestedMethod: PrayerTimesCalculationMethod? = nil
    @AppStorage(StorageKeys.fajrCorrection) var fajrCorrection: Double = 0 { didSet { updatePrayerTimes() } }
    @AppStorage(StorageKeys.dhuhrCorrection) var dhuhrCorrection: Double = 0 { didSet { updatePrayerTimes() } }
    @AppStorage(StorageKeys.asrCorrection) var asrCorrection: Double = 0 { didSet { updatePrayerTimes() } }
    @AppStorage(StorageKeys.maghribCorrection) var maghribCorrection: Double = 0 { didSet { updatePrayerTimes() } }
    @AppStorage(StorageKeys.ishaCorrection) var ishaCorrection: Double = 0 { didSet { updatePrayerTimes() } }
    @AppStorage(StorageKeys.alwaysShowMenuBarIcon) var alwaysShowMenuBarIcon: Bool = true

    @Published var menuBarTextMode: MenuBarTextMode {
        didSet {
            UserDefaults.standard.set(menuBarTextMode.rawValue, forKey: StorageKeys.menuBarTextMode)
            if menuBarTextMode == .hidden { useMinimalMenuBarText = false; alwaysShowMenuBarIcon = true }
            startTimer()
            updateMenuTitle()
        }
    }
    
    private var isAutoSelectingMethod = false
    @Published var method: PrayerTimesCalculationMethod { didSet { UserDefaults.standard.set(method.name, forKey: StorageKeys.calculationMethodName); if !isAutoSelectingMethod { hasManuallySelectedMethod = true }; updatePrayerTimes() } }
    private var currentCoordinates: CLLocationCoordinate2D?
    private var cancellables = Set<AnyCancellable>()
    private let locMgr = CLLocationManager()
    private var timer: Timer?
    private var locationTimeZone: TimeZone = .current { didSet { _cachedDateFormatter = nil } }
    private var locationDisplayTimer: Timer?
    private var _cachedDateFormatter: DateFormatter?
    private var _cachedNumberFormatter: NumberFormatter?
    private var lastCalculationDate: Date?


    override init() {
        let savedMethodName = UserDefaults.standard.string(forKey: StorageKeys.calculationMethodName) ?? "Muslim World League"
        self.method = PrayerTimesCalculationMethod.allCases.first { $0.name == savedMethodName } ?? .allCases[0]
        let savedTextMode = UserDefaults.standard.string(forKey: StorageKeys.menuBarTextMode)
        self.menuBarTextMode = MenuBarTextMode(rawValue: savedTextMode ?? "") ?? .countdown
        self.authorizationStatus = locMgr.authorizationStatus
        super.init()
        locMgr.delegate = self
        startTimer()
        setupSearchPublisher()
        setupNotificationObserver()
        NotificationCenter.default.addObserver(forName: .popoverDidOpen, object: nil, queue: .main) { [weak self] _ in
            self?.updateCountdown()
        }
        NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            let currentNumeralLocale = self.languageManager.numeralLocale.identifier
            if self._cachedNumberFormatter?.locale.identifier != currentNumeralLocale {
                self._cachedNumberFormatter = nil
                self._cachedDateFormatter = nil
                self.updateCountdown()
            }
        }
    }
    
    func forwardAnimation() -> NavigationAnimation? {
        switch animationType {
        case .none: return nil
        case .fade: return .prayertimesCrossfade
        case .slide: return .push
        }
    }
    
    func backwardAnimation() -> NavigationAnimation? {
        switch animationType {
        case .none: return nil
        case .fade: return .prayertimesCrossfade
        case .slide: return .pop
        }
    }
    
    private func setupNotificationObserver() {
        // Notification delegate handling is done in AppDelegate via UNUserNotificationCenterDelegate
    }
    
    func scheduleNotifications() {
        updateNotifications()
    }

    func handleDetectedCountryCode(_ countryCode: String) {
        let recommended = PrayerTimesCalculationMethod.recommendedMethod(forCountryCode: countryCode)
        if !hasManuallySelectedMethod {
            isAutoSelectingMethod = true
            self.method = recommended
            isAutoSelectingMethod = false
            lastDetectedCountryCode = countryCode
            suggestedMethod = nil
        } else if countryCode != lastDetectedCountryCode && recommended.name != method.name {
            suggestedMethod = recommended
        }
        lastDetectedCountryCode = countryCode
    }

    func acceptSuggestedMethod() {
        guard let suggested = suggestedMethod else { return }
        isAutoSelectingMethod = true
        self.method = suggested
        isAutoSelectingMethod = false
        suggestedMethod = nil
    }

    func dismissSuggestedMethod() {
        hasManuallySelectedMethod = true
        suggestedMethod = nil
    }

    private struct NominatimResult: Codable, Hashable {
        @FlexibleDouble var lat: Double; @FlexibleDouble var lon: Double
        let display_name: String; let address: NominatimAddress
    }

    private struct NominatimAddress: Codable, Hashable {
        let city: String?, town: String?, village: String?, state: String?, county: String?, country: String?
    }
    
    private func setupSearchPublisher() {
        $locationSearchQuery
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .removeDuplicates()
            .handleEvents(receiveOutput: { [weak self] query in
                let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
                self?.isLocationSearching = !trimmedQuery.isEmpty
                self?.locationSearchError = nil
                if trimmedQuery.isEmpty { self?.locationSearchResults = [] }
            })
            .flatMap { [weak self] query -> AnyPublisher<[LocationSearchResult], Never> in
                guard let self = self else { return Just([]).eraseToAnyPublisher() }
                let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
                guard !trimmedQuery.isEmpty else { return Just([]).eraseToAnyPublisher() }

                if let coordResult = self.parseCoordinates(from: trimmedQuery) {
                    return Just([coordResult]).eraseToAnyPublisher()
                }

                var components = URLComponents(string: "https://nominatim.openstreetmap.org/search")!
                components.queryItems = [
                    URLQueryItem(name: "q", value: trimmedQuery),
                    URLQueryItem(name: "format", value: "json"),
                    URLQueryItem(name: "addressdetails", value: "1"),
                    URLQueryItem(name: "accept-language", value: "en"),
                    URLQueryItem(name: "limit", value: "20")
                ]
                guard let url = components.url else { return Just([]).eraseToAnyPublisher() }
                var request = URLRequest(url: url)
                request.setValue("PrayerTimes Pro Prayer Times App/1.0", forHTTPHeaderField: "User-Agent")

                return URLSession.shared.dataTaskPublisher(for: request)
                    .map(\.data)
                    .decode(type: [NominatimResult].self, decoder: JSONDecoder())
                    .catch { [weak self] error -> Just<[NominatimResult]> in
                        DispatchQueue.main.async {
                            self?.locationSearchError = NSLocalizedString("location_search_error", comment: "")
                        }
                        return Just([])
                    }
                    .map { results -> [LocationSearchResult] in
                        let mappedResults = results.compactMap { result -> LocationSearchResult? in
                            let name = result.address.city ?? result.address.town ?? result.address.village ?? result.address.county ?? result.address.state ?? ""
                            let country = result.address.country ?? ""
                            guard !country.isEmpty else { return nil }
                            let finalName = name.isEmpty ? result.display_name.components(separatedBy: ",")[0] : name
                            return LocationSearchResult(name: finalName, country: country, coordinates: CLLocationCoordinate2D(latitude: result.lat, longitude: result.lon))
                        }
                        let uniqueResults = Array(Set(mappedResults))
                        return uniqueResults.sorted { $0.name < $1.name }
                    }
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] results in
                self?.isLocationSearching = false
                self?.locationSearchResults = results
            }
            .store(in: &cancellables)
    }
    
    private func parseCoordinates(from string: String) -> LocationSearchResult? {
        let cleaned = string.replacingOccurrences(of: " ", with: "")
        let components = cleaned.split(separator: ",").compactMap { Double($0) }
        guard components.count == 2,
              let lat = components.first,
              let lon = components.last,
              (-90...90).contains(lat),
              (-180...180).contains(lon) else {
            return nil
        }
        return LocationSearchResult(
            name: "Custom Coordinate",
            country: String(format: "%.4f, %.4f", lat, lon),
            coordinates: CLLocationCoordinate2D(latitude: lat, longitude: lon)
        )
    }
    func setManualLocation(city: String, coordinates: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        self.locationTimeZone = TimeZoneLocate.timeZoneWithLocation(location)

        var locationNameToSave = city

        if city == "Custom Coordinate" {
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
                guard let self = self else { return }
                if let placemark = placemarks?.first, let cityName = placemark.locality {
                    locationNameToSave = cityName
                    self.locationStatusText = cityName
                    let manualData: [String: Any] = [
                        "name": locationNameToSave,
                        "latitude": coordinates.latitude,
                        "longitude": coordinates.longitude
                    ]
                    UserDefaults.standard.set(manualData, forKey: StorageKeys.manualLocationData)
                    if let cc = placemark.isoCountryCode {
                        self.handleDetectedCountryCode(cc)
                    }
                } else {
                    self.locationStatusText = String(format: "Coord: %.2f, %.2f", coordinates.latitude, coordinates.longitude)
                }
            }
        } else {
            self.locationStatusText = city
            let countryGeocoder = CLGeocoder()
            countryGeocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
                if let cc = placemarks?.first?.isoCountryCode {
                    DispatchQueue.main.async {
                        self?.handleDetectedCountryCode(cc)
                    }
                }
            }
        }

        let manualLocationData: [String: Any] = [
            "name": locationNameToSave,
            "latitude": coordinates.latitude,
            "longitude": coordinates.longitude
        ]
        UserDefaults.standard.set(manualLocationData, forKey: StorageKeys.manualLocationData)
        isUsingManualLocation = true
        currentCoordinates = coordinates
        authorizationStatus = .authorized
        locationSearchQuery = ""
        locationSearchResults = []
        updateAndDisplayTimes()
    }
    
    func startLocationProcess() {
        if isUsingManualLocation, let manualData = loadManualLocation() {
            currentCoordinates = manualData.coordinates
            locationStatusText = manualData.name
            let location = CLLocation(latitude: manualData.coordinates.latitude, longitude: manualData.coordinates.longitude)
            self.locationTimeZone = TimeZoneLocate.timeZoneWithLocation(location)
            self.authorizationStatus = .authorized
            DispatchQueue.main.async {
                self.updateAndDisplayTimes()
            }
        } else {
            self.locationTimeZone = .current
            handleAuthorizationStatus(status: locMgr.authorizationStatus)
        }
    }
    
    private func loadManualLocation() -> (name: String, coordinates: CLLocationCoordinate2D)? {
        guard let data = UserDefaults.standard.dictionary(forKey: StorageKeys.manualLocationData),
              let name = data["name"] as? String,
              let lat = data["latitude"] as? CLLocationDegrees,
              let lon = data["longitude"] as? CLLocationDegrees else {
            return nil
        }
        return (name, CLLocationCoordinate2D(latitude: lat, longitude: lon))
    }
    func switchToAutomaticLocation() {
        isUsingManualLocation = false
        UserDefaults.standard.removeObject(forKey: StorageKeys.manualLocationData)
        if let cache = automaticLocationCache {
            currentCoordinates = cache.coordinates
            locationStatusText = cache.name
            updateAndDisplayTimes()
        } else {
            handleAuthorizationStatus(status: locMgr.authorizationStatus)
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
        guard let location = locs.last else { return }

        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard let locality = placemarks?.first?.locality else {
                    self.isRequestingLocation = false
                    return
                }

                self.automaticLocationCache = (name: locality, coordinates: location.coordinate)

                if let countryCode = placemarks?.first?.isoCountryCode {
                    self.handleDetectedCountryCode(countryCode)
                }

                if !self.isUsingManualLocation {
                    self.currentCoordinates = location.coordinate
                    self.locationStatusText = locality
                    self.updateAndDisplayTimes()
                }

                if self.isRequestingLocation {
                    self.isRequestingLocation = false
                }
            }
        }
    }
    private func updateAndDisplayTimes() {
        updatePrayerTimes()
        if isUsingManualLocation {
            startLocationDisplayTimer()
        } else {
            stopLocationDisplayTimer()
        }
    }
    
    func updatePrayerTimes() {
        guard let coord = currentCoordinates else { return }
        
        lastCalculationDate = Date()
        
        var locationCalendar = Calendar(identifier: .gregorian); locationCalendar.timeZone = self.locationTimeZone
        let todayInLocation = locationCalendar.dateComponents([.year, .month, .day], from: Date())
        let tomorrowInLocation = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let tomorrowDC = locationCalendar.dateComponents([.year, .month, .day], from: tomorrowInLocation)
        var params = method.params; params.madhab = self.useHanafiMadhhab ? .hanafi : .shafi
        guard let prayersToday = PrayerTimes(coordinates: Coordinates(latitude: coord.latitude, longitude: coord.longitude), date: todayInLocation, calculationParameters: params),
              let prayersTomorrow = PrayerTimes(coordinates: Coordinates(latitude: coord.latitude, longitude: coord.longitude), date: tomorrowDC, calculationParameters: params) else { return }
        
        let correctedFajr = prayersToday.fajr.addingTimeInterval(fajrCorrection * 60)
        let correctedDhuhr = prayersToday.dhuhr.addingTimeInterval(dhuhrCorrection * 60)
        let correctedAsr = prayersToday.asr.addingTimeInterval(asrCorrection * 60)
        let correctedMaghrib = prayersToday.maghrib.addingTimeInterval(maghribCorrection * 60)
        let correctedIsha = prayersToday.isha.addingTimeInterval(ishaCorrection * 60)
        
        var allPrayerTimes: [(name: String, time: Date)] = [("Fajr", correctedFajr), ("Sunrise", prayersToday.sunrise), ("Dhuhr", correctedDhuhr), ("Asr", correctedAsr), ("Maghrib", correctedMaghrib), ("Isha", correctedIsha)]
        
        if showSunnahPrayers {
            let correctedFajrTomorrow = prayersTomorrow.fajr.addingTimeInterval(fajrCorrection * 60)
            let nightDuration = correctedFajrTomorrow.timeIntervalSince(correctedIsha)
            let lastThirdOfNightStart = correctedIsha.addingTimeInterval(nightDuration * (2/3.0))
            allPrayerTimes.append(("Tahajud", lastThirdOfNightStart))
            
            let dhuhaTime = prayersToday.sunrise.addingTimeInterval(20 * 60)
            allPrayerTimes.append(("Dhuha", dhuhaTime))
        }
        
        let correctedFajrTomorrow = prayersTomorrow.fajr.addingTimeInterval(fajrCorrection * 60)
        
        DispatchQueue.main.async {
            self.todayTimes = Dictionary(uniqueKeysWithValues: allPrayerTimes.map { ($0.name, $0.time) })
            self.tomorrowFajrTime = correctedFajrTomorrow
            self.updateNextPrayer()
            self.updateNotifications()
        }
    }
    
    private func updateNextPrayer() {
        let now = Date()
        var potentialPrayers = todayTimes.map { (key: $0.key, value: $0.value) }
        if let fajrTomorrow = tomorrowFajrTime {
            potentialPrayers.append((key: "Fajr", value: fajrTomorrow))
        }
        let allSortedPrayers = potentialPrayers.sorted { $0.value < $1.value }
        let listToSearch: [(key: String, value: Date)]
        if showSunnahPrayers {
            listToSearch = allSortedPrayers
        } else {
            listToSearch = allSortedPrayers.filter { $0.key != "Tahajud" && $0.key != "Dhuha" }
        }
        
        if let nextPrayer = listToSearch.first(where: { $0.value > now }) {
            self.nextPrayerName = nextPrayer.key
        } else {
            if let firstPrayerOfNextCycle = listToSearch.first {
                self.nextPrayerName = firstPrayerOfNextCycle.key
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    self?.updatePrayerTimes()
                }
            }
        }
        updateCountdown()
    }
    
    private func updateCountdown() {
        var nextPrayerDate: Date?
        if nextPrayerName == "Fajr" && todayTimes["Fajr"] ?? Date() < Date() {
            nextPrayerDate = tomorrowFajrTime
        } else {
            nextPrayerDate = todayTimes[nextPrayerName]
        }

        guard let nextDate = nextPrayerDate else {
            countdown = "--:--"; updateMenuTitle(); return
        }

        let diff = Int(nextDate.timeIntervalSince(Date()))
        isPrayerImminent = (diff <= 600 && diff > 0)

        let numeralLocaleId = languageManager.numeralLocale.identifier
        if _cachedNumberFormatter == nil || _cachedNumberFormatter?.locale.identifier != numeralLocaleId {
            let nf = NumberFormatter()
            nf.locale = languageManager.numeralLocale
            _cachedNumberFormatter = nf
        }
        let numberFormatter = _cachedNumberFormatter!
        let isolateStart = languageManager.isRTLEnabled ? "\u{2067}" : "\u{2066}"  // RLI for RTL, LRI for LTR
        let isolateEnd = "\u{2069}"  // PDI
        let hourAbbr = NSLocalizedString("time_hour_abbrev", comment: "")
        let minAbbr = NSLocalizedString("time_minute_abbrev", comment: "")
        let secAbbr = NSLocalizedString("time_second_abbrev", comment: "")

        if diff > 0 {
            if diff < 60 {
                // Under 1 minute: show seconds
                let formattedS = numberFormatter.string(from: NSNumber(value: diff)) ?? "\(diff)"
                countdown = "\(isolateStart)\(formattedS)\(secAbbr)\(isolateEnd)"
            } else {
                // Round up to nearest minute
                let totalMinutes = (diff + 59) / 60
                let h = totalMinutes / 60
                let m = totalMinutes % 60

                if h > 0 && m > 0 {
                    let formattedH = numberFormatter.string(from: NSNumber(value: h)) ?? "\(h)"
                    let formattedM = numberFormatter.string(from: NSNumber(value: m)) ?? "\(m)"
                    countdown = "\(isolateStart)\(formattedH)\(hourAbbr) \(formattedM)\(minAbbr)\(isolateEnd)"
                } else if h > 0 {
                    let formattedH = numberFormatter.string(from: NSNumber(value: h)) ?? "\(h)"
                    countdown = "\(isolateStart)\(formattedH)\(hourAbbr)\(isolateEnd)"
                } else {
                    let formattedM = numberFormatter.string(from: NSNumber(value: m)) ?? "\(m)"
                    countdown = "\(isolateStart)\(formattedM)\(minAbbr)\(isolateEnd)"
                }
            }
        } else {
            countdown = NSLocalizedString("time_now", comment: "")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.updateNextPrayer() }
        }
        updateMenuTitle()
    }
    
    private lazy var ltrParagraphStyle: NSParagraphStyle = {
        let style = NSMutableParagraphStyle()
        style.alignment = .left
        style.baseWritingDirection = .leftToRight
        return style.copy() as! NSParagraphStyle
    }()

    private lazy var rtlParagraphStyle: NSParagraphStyle = {
        let style = NSMutableParagraphStyle()
        style.alignment = .right
        style.baseWritingDirection = .rightToLeft
        return style.copy() as! NSParagraphStyle
    }()

    private func createMenuTitle(_ text: String, color: NSColor? = nil) -> NSAttributedString {
        let isRTL = languageManager.isRTLEnabled

        var attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: isRTL ? rtlParagraphStyle : ltrParagraphStyle
        ]

        if let color = color {
            attributes[.foregroundColor] = color
        }

        return NSAttributedString(string: text, attributes: attributes)
    }
    
    func updateMenuTitle() {
        guard isPrayerDataAvailable else {
            self.menuTitle = createMenuTitle(NSLocalizedString("PrayerTimes Pro", comment: ""))
            return
        }
        
        var textToShow = ""
        let isFasting = fastingManager?.isFastingModeEnabled == true && fastingManager?.currentFastingDay != nil
        let localizedPrayerName: String
        if isFasting && nextPrayerName == "Fajr" {
            localizedPrayerName = NSLocalizedString("Suhoor", comment: "")
        } else if isFasting && nextPrayerName == "Maghrib" {
            localizedPrayerName = NSLocalizedString("Iftar", comment: "")
        } else {
            localizedPrayerName = NSLocalizedString(nextPrayerName, comment: "")
        }
        
        switch menuBarTextMode {
        case .hidden:
            textToShow = ""
        case .countdown:
            if useMinimalMenuBarText {
                textToShow = "\(localizedPrayerName) -\(countdown)"
            } else {
                textToShow = String(format: NSLocalizedString("prayer_in_countdown", comment: ""), localizedPrayerName, countdown)
            }
        case .exactTime:
            var nextPrayerDate: Date?
            if nextPrayerName == "Fajr" && todayTimes["Fajr"] ?? Date() < Date() {
                nextPrayerDate = tomorrowFajrTime
            } else {
                nextPrayerDate = todayTimes[nextPrayerName]
            }
            
            guard let nextDate = nextPrayerDate else {
                textToShow = NSLocalizedString("PrayerTimes Pro", comment: "")
                break
            }
            
            if useMinimalMenuBarText {
                textToShow = "\(localizedPrayerName) \(dateFormatter.string(from: nextDate))"
            } else {
                textToShow = String(format: NSLocalizedString("prayer_at_time", comment: ""), localizedPrayerName, dateFormatter.string(from: nextDate))
            }
        }
        
        let color: NSColor? = isPrayerImminent ? .systemRed : nil
        self.menuTitle = createMenuTitle(textToShow, color: color)
    }
    
    var dateFormatter: DateFormatter {
        if let cached = _cachedDateFormatter,
           cached.locale.identifier == languageManager.numeralLocale.identifier { return cached }
        let formatter = DateFormatter()
        formatter.timeZone = self.locationTimeZone
        formatter.locale = languageManager.numeralLocale
        if useMinimalMenuBarText {
            formatter.dateFormat = use24HourFormat ? "H.mm" : "h.mm"
        } else {
            formatter.timeStyle = .short
        }
        _cachedDateFormatter = formatter
        return formatter
    }
    
    private func startLocationDisplayTimer() {
        stopLocationDisplayTimer()
        locationDisplayTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let timeFormatter = DateFormatter()
            timeFormatter.timeZone = self.locationTimeZone
            timeFormatter.timeStyle = .medium
            let tzName = self.locationTimeZone.identifier
            let currentTime = timeFormatter.string(from: Date())
            self.locationInfoText = "Timezone: \(tzName) | Current Time: \(currentTime)"
        }
    }

    private func stopLocationDisplayTimer() {
        locationDisplayTimer?.invalidate()
        locationDisplayTimer = nil
        locationInfoText = ""
    }
    
    private func updateNotifications() {
        NotificationManager.cancelPrayerNotifications()
        guard !todayTimes.isEmpty else { return }

        if notificationSettings.prayerNotificationsEnabled {
            var prayersToNotify = ["Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha"]
            if showSunnahPrayers {
                if todayTimes.keys.contains("Tahajud") { prayersToNotify.insert("Tahajud", at: 0) }
                if todayTimes.keys.contains("Dhuha") { prayersToNotify.insert("Dhuha", at: prayersToNotify.firstIndex(of: "Dhuhr") ?? 2) }
            }
            NotificationManager.scheduleNotifications(for: todayTimes, prayerOrder: prayersToNotify, settings: notificationSettings)
        }

        if let fm = fastingManager, fm.isFastingModeEnabled {
            NotificationManager.scheduleFastingNotifications(prayerTimes: todayTimes, fastingManager: fm)
        }
    }
    
    var isPrayerDataAvailable: Bool { !todayTimes.isEmpty }
    
    func startTimer() {
        timer?.invalidate()
        let interval: TimeInterval = (menuBarTextMode == .hidden) ? 60 : 1
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            // Check if any full-screen notifications should fire now
            NotificationManager.checkPendingFullScreenNotifications()

            if let lastDate = self.lastCalculationDate,
               !Calendar.current.isDate(lastDate, inSameDayAs: Date()) {
                self.fastingManager?.checkAndAutoEnable()
                self.updatePrayerTimes()
            } else {
                self.updateCountdown()
            }
        }
        // Ensure timer fires even during menu interaction / scrolling
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    private func handleAuthorizationStatus(status: CLAuthorizationStatus) {
        self.authorizationStatus = status
        switch status {
        case .authorized:
            if automaticLocationCache == nil {
                locationStatusText = NSLocalizedString("Fetching Location...", comment: "")
            }
            locMgr.requestLocation()
        case .denied, .restricted:
            locationStatusText = NSLocalizedString("Location access denied.", comment: "")
            isRequestingLocation = false
            todayTimes = [:]
        case .notDetermined:
            isRequestingLocation = false
            locationStatusText = NSLocalizedString("Location access needed", comment: "")
        @unknown default:
            isRequestingLocation = false
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if !isUsingManualLocation {
            handleAuthorizationStatus(status: manager.authorizationStatus)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.isRequestingLocation = false
        self.locationStatusText = NSLocalizedString("Unable to determine location.", comment: "")
    }
    
    func requestLocationPermission() {
        if authorizationStatus == .notDetermined {
            isRequestingLocation = true
            DispatchQueue.main.async {
                self.locMgr.requestWhenInUseAuthorization()
            }
        }
    }

    func openLocationSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") else { return }
        NSWorkspace.shared.open(url)
    }
}
