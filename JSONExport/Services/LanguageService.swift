//
//  LanguageService.swift
//  JSONExport
//
//  Created by Claude on 2026/2/2.
//  Copyright © 2026. All rights reserved.
//

import Foundation


protocol LanguageServiceProtocol {

    func loadSupportedLanguages() -> [String: LangModel]

    func saveLastSelectedLanguage(_ languageName: String)

    func loadLastSelectedLanguage() -> String?
}


final class LanguageService: LanguageServiceProtocol {

    private let userDefaults: UserDefaults

    private let selectedLanguageKey = "selectedLanguage"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadSupportedLanguages() -> [String: LangModel] {
        var langs = [String: LangModel]()

        guard let langFiles = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) else {
            return langs
        }

        for langFile in langFiles {
            guard let data = try? Data(contentsOf: langFile),
                  let langDictionary = (try? JSONSerialization.jsonObject(with: data, options: [])) as? NSDictionary else {
                continue
            }

            let lang = LangModel(fromDictionary: langDictionary)

            if langs[lang.displayLangName] != nil {
                continue
            }

            langs[lang.displayLangName] = lang
        }

        return langs
    }

    func saveLastSelectedLanguage(_ languageName: String) {
        self.userDefaults.set(languageName, forKey: self.selectedLanguageKey)
    }

    func loadLastSelectedLanguage() -> String? {
        return self.userDefaults.value(forKey: self.selectedLanguageKey) as? String
    }
}
