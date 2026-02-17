Gunward.Locales = {}

function Gunward.AddLocale(lang, translations)
    Gunward.Locales[lang] = translations
end

function Lang(key, ...)
    local locale = Gunward.Locales[Config.Locale]
    local str = locale and locale[key]
    if not str then
        Gunward.Debug('Missing locale key:', key)
        return key
    end
    if ... then return string.format(str, ...) end
    return str
end
