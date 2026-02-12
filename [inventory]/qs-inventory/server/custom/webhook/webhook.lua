--[[
    Welcome webhooks setup!
    Here you will have the link to configure the admin webhooks,
    you can modify them from server/custom/misc/SetInventoryData.lua.
]]

Webhooks = Webhooks or {}

Webhooks = {
    -- logs-admin
    ['exploit'] = 'https://discord.com/api/webhooks/1471429434534789258/a4obej5yjChMptx83o2AneshGzEpLt0ONBDjl5l-j15vsS1w9Tkoxi5-rJYFXijFiAxh',
    ['admin'] = 'https://discord.com/api/webhooks/1471429434534789258/a4obej5yjChMptx83o2AneshGzEpLt0ONBDjl5l-j15vsS1w9Tkoxi5-rJYFXijFiAxh',
    -- logs-shop
    ['bought'] = 'https://discord.com/api/webhooks/1471429688982503506/dl6nwhDhculcWxnCWnNQrRWLuqV4dxDWkZH7avtCaDiG02BcMchhsp2gFg4JLhN-iSLk',
    ['sell'] = 'https://discord.com/api/webhooks/1471429688982503506/dl6nwhDhculcWxnCWnNQrRWLuqV4dxDWkZH7avtCaDiG02BcMchhsp2gFg4JLhN-iSLk',
    ['crafting'] = 'https://discord.com/api/webhooks/1471429688982503506/dl6nwhDhculcWxnCWnNQrRWLuqV4dxDWkZH7avtCaDiG02BcMchhsp2gFg4JLhN-iSLk',
    -- logs-transferts
    ['swap'] = 'https://discord.com/api/webhooks/1471429759656530156/9AfHrS7pFqWN13zV-wX6vonhjH9jkq3Ysvzo62D93UjzTG56lvGPmDoTZtjSJ4xB3pF-',
    ['drop'] = 'https://discord.com/api/webhooks/1471429759656530156/9AfHrS7pFqWN13zV-wX6vonhjH9jkq3Ysvzo62D93UjzTG56lvGPmDoTZtjSJ4xB3pF-',
    ['giveitem'] = 'https://discord.com/api/webhooks/1471429759656530156/9AfHrS7pFqWN13zV-wX6vonhjH9jkq3Ysvzo62D93UjzTG56lvGPmDoTZtjSJ4xB3pF-',
    -- logs-stockage
    ['stash'] = 'https://discord.com/api/webhooks/1471429849766826106/bE3S6yG3ZShUEh1ESIVjX_rGiXkTpiNq9ghDfPxswCeUbYLumlDSsFsF96ASS70fb89K',
    ['trunk'] = 'https://discord.com/api/webhooks/1471429849766826106/bE3S6yG3ZShUEh1ESIVjX_rGiXkTpiNq9ghDfPxswCeUbYLumlDSsFsF96ASS70fb89K',
    ['garbage'] = 'https://discord.com/api/webhooks/1471429849766826106/bE3S6yG3ZShUEh1ESIVjX_rGiXkTpiNq9ghDfPxswCeUbYLumlDSsFsF96ASS70fb89K',
    ['glovebox'] = 'https://discord.com/api/webhooks/1471429849766826106/bE3S6yG3ZShUEh1ESIVjX_rGiXkTpiNq9ghDfPxswCeUbYLumlDSsFsF96ASS70fb89K',
    -- logs-crime
    ['robbery'] = 'https://discord.com/api/webhooks/1471429935934738433/EGeg0Gy83dfjqKhXBMdkB-ZO5c1w46513TIMYSgg4ZllI1xWfnK0b55P6f0noYoxE9aK',
    ['traphouse'] = 'https://discord.com/api/webhooks/1471429935934738433/EGeg0Gy83dfjqKhXBMdkB-ZO5c1w46513TIMYSgg4ZllI1xWfnK0b55P6f0noYoxE9aK',
}
