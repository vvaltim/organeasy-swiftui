enum AdUnits {
    #if DEBUG
    static let banner = "ca-app-pub-3940256099942544/2435281174"
    static let rewarded = "ca-app-pub-3940256099942544/1712485313"
    static let interstitial = "ca-app-pub-3940256099942544/4411468910"
    static let appOpen = "ca-app-pub-3940256099942544/5575463023"
    #else
    static let banner = "ca-app-pub-9858319089507407/9389039810"
    static let rewarded = "ca-app-pub-9858319089507407/7413613167"
    static let interstitial = "ca-app-pub-9858319089507407/8477973319"
    static let appOpen = "ca-app-pub-9858319089507407/7079336558"
    #endif
}
