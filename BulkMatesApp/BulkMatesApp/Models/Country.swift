//
//  Country.swift
//  BulkMatesApp
//
//  Country data for phone codes and addresses
//

import Foundation

struct Country: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let code: String  // ISO code (e.g., "US", "IN")
    let flag: String  // Emoji flag
    let phoneCode: String  // ISD code (e.g., "+1", "+91")

    func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }

    static func == (lhs: Country, rhs: Country) -> Bool {
        lhs.code == rhs.code
    }
}

let countries: [Country] = [
    Country(name: "United States", code: "US", flag: "🇺🇸", phoneCode: "+1"),
    Country(name: "Canada", code: "CA", flag: "🇨🇦", phoneCode: "+1"),
    Country(name: "United Kingdom", code: "GB", flag: "🇬🇧", phoneCode: "+44"),
    Country(name: "India", code: "IN", flag: "🇮🇳", phoneCode: "+91"),
    Country(name: "Australia", code: "AU", flag: "🇦🇺", phoneCode: "+61"),
    Country(name: "Germany", code: "DE", flag: "🇩🇪", phoneCode: "+49"),
    Country(name: "France", code: "FR", flag: "🇫🇷", phoneCode: "+33"),
    Country(name: "Mexico", code: "MX", flag: "🇲🇽", phoneCode: "+52"),
    Country(name: "Japan", code: "JP", flag: "🇯🇵", phoneCode: "+81"),
    Country(name: "China", code: "CN", flag: "🇨🇳", phoneCode: "+86"),
    Country(name: "Brazil", code: "BR", flag: "🇧🇷", phoneCode: "+55"),
    Country(name: "Spain", code: "ES", flag: "🇪🇸", phoneCode: "+34"),
    Country(name: "Italy", code: "IT", flag: "🇮🇹", phoneCode: "+39"),
    Country(name: "Netherlands", code: "NL", flag: "🇳🇱", phoneCode: "+31"),
    Country(name: "South Korea", code: "KR", flag: "🇰🇷", phoneCode: "+82"),
    Country(name: "Singapore", code: "SG", flag: "🇸🇬", phoneCode: "+65"),
    Country(name: "Switzerland", code: "CH", flag: "🇨🇭", phoneCode: "+41"),
    Country(name: "Sweden", code: "SE", flag: "🇸🇪", phoneCode: "+46"),
    Country(name: "Norway", code: "NO", flag: "🇳🇴", phoneCode: "+47"),
    Country(name: "Denmark", code: "DK", flag: "🇩🇰", phoneCode: "+45")
]

func getCountry(byCode code: String) -> Country? {
    return countries.first { $0.code == code }
}

func getISDCode(forCountry countryCode: String) -> String {
    return getCountry(byCode: countryCode)?.phoneCode ?? "+1"
}

func getCountry(byPhoneCode phoneCode: String) -> Country? {
    return countries.first { $0.phoneCode == phoneCode }
}
