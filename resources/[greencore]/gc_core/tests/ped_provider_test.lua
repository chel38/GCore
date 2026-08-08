-- RU: Тесты провайдера педа GreenCore.
-- EN: GreenCore ped provider tests.

-- RU: Тест существования списка моделей.
-- EN: Test that the model list exists.
GCTest.Register('ped_provider.model_list_exists', function()
    local models = GCPedProvider.GetModels()

    GCTest.ExpectNotNil(models, 'model list is returned')
    GCTest.ExpectTrue(type(models) == 'table', 'model list is a table')
    GCTest.ExpectTrue(#models > 0, 'model list is not empty')
end)

-- RU: Тест валидности конфигурации.
-- EN: Test of configuration validity.
GCTest.Register('ped_provider.config_valid', function()
    local models, errorCode = GCPedProvider.ValidateConfig()

    GCTest.ExpectNotNil(models, 'validated models are returned')
    GCTest.ExpectNil(errorCode, 'no error for valid config')
end)

-- RU: Тест случайной модели из белого списка.
-- EN: Test that the random model belongs to the whitelist.
GCTest.Register('ped_provider.random_model_in_whitelist', function()
    local models = GCPedProvider.GetModels()

    -- RU: Выполняем несколько выборов и проверяем, что каждый результат в списке.
    -- EN: Perform several selections and verify that each result is in the list.
    local session = {}

    for _ = 1, 20 do
        local pedDefinition, errorCode = GCPedProvider.Resolve(40, session)

        GCTest.ExpectNotNil(pedDefinition, 'ped definition is resolved')
        GCTest.ExpectNil(errorCode, 'no error on ped resolution')
        GCTest.ExpectTrue(GCUtils.Contains(models, pedDefinition.name), 'selected model belongs to whitelist: ' .. tostring(pedDefinition.name))
    end
end)

-- RU: Тест avoidImmediateRepeat.
-- EN: Test of avoidImmediateRepeat.
GCTest.Register('ped_provider.avoid_immediate_repeat', function()
    local models = GCPedProvider.GetModels()

    -- RU: Тест имеет смысл только при нескольких моделях.
    -- EN: The test only makes sense with multiple models.
    if #models <= 1 then
        GCTest.ExpectTrue(true, 'skip avoidImmediateRepeat test for single-model list')
        return
    end

    -- RU: Берём первую модель как lastPed и проверяем, что следующая другая.
    -- EN: Take the first model as lastPed and verify the next one is different.
    local lastPed = models[1]

    -- RU: Если список > 1, Resolve с avoidImmediateRepeat не должен вернуть lastPed.
    -- EN: If the list has > 1, Resolve with avoidImmediateRepeat must not return lastPed.
    local session = {
        lastPed = lastPed
    }

    local pedDefinition, _ = GCPedProvider.Resolve(41, session)

    GCTest.ExpectNotNil(pedDefinition, 'ped is resolved')
    GCTest.ExpectFalse(pedDefinition.name == lastPed, 'avoidImmediateRepeat avoids the last ped')
end)

-- RU: Тест работы с одним элементом списка.
-- EN: Test of a single-model list.
GCTest.Register('ped_provider.single_model_list', function()
    -- RU: Временно заменяем конфигурацию на один элемент.
    -- EN: Temporarily replace the configuration with a single element.
    local originalRandomPed = GCConfig.Spawn.randomPed

    GCConfig.Spawn.randomPed = {
        enabled = true,
        avoidImmediateRepeat = true,
        models = { 'mp_m_freemode_01' }
    }

    -- RU: Сбрасываем кэш валидации (модуль перечитает конфигурацию).
    -- EN: Reset the validation cache (the module will re-read the configuration).
    GCPedProvider.ResetConfigCache()
    GCPedProvider.ValidateConfig()

    -- RU: Выполняем несколько выборов.
    -- EN: Perform several selections.
    local session = {
        lastPed = 'mp_m_freemode_01'
    }

    local allValid = true

    for _ = 1, 5 do
        local pedDefinition, _ = GCPedProvider.Resolve(42, session)
        allValid = allValid and pedDefinition ~= nil and pedDefinition.name == 'mp_m_freemode_01'
    end

    GCTest.ExpectTrue(allValid, 'single-model list always returns the only model')

    -- RU: Восстанавливаем конфигурацию и кэш.
    -- EN: Restore the configuration and cache.
    GCConfig.Spawn.randomPed = originalRandomPed
    GCPedProvider.ResetConfigCache()
    GCPedProvider.ValidateConfig()
end)

-- RU: Тест fallback при отключённом случайном выборе.
-- EN: Test of fallback when random selection is disabled.
GCTest.Register('ped_provider.disabled_uses_fallback', function()
    -- RU: Временно отключаем случайный выбор.
    -- EN: Temporarily disable random selection.
    local originalRandomPed = GCConfig.Spawn.randomPed

    GCConfig.Spawn.randomPed = {
        enabled = false,
        models = {}
    }

    local session = {}
    local pedDefinition, errorCode = GCPedProvider.Resolve(43, session)

    GCTest.ExpectNotNil(pedDefinition, 'fallback ped is resolved when random is disabled')
    GCTest.ExpectNil(errorCode, 'no error for fallback resolution')
    GCTest.ExpectEqual(pedDefinition.name, GCConfig.Spawn.fallbackPed, 'fallback ped matches configuration')

    -- RU: Восстанавливаем конфигурацию.
    -- EN: Restore the configuration.
    GCConfig.Spawn.randomPed = originalRandomPed
    GCPedProvider.ValidateConfig()
end)

-- RU: Тест ResolveFallback.
-- EN: Test of ResolveFallback.
GCTest.Register('ped_provider.fallback', function()
    local pedDefinition = GCPedProvider.ResolveFallback()

    GCTest.ExpectNotNil(pedDefinition, 'fallback ped definition is returned')
    GCTest.ExpectEqual(pedDefinition.name, GCConfig.Spawn.fallbackPed, 'fallback ped name matches configuration')
end)

-- RU: Тест невалидного playerSource.
-- EN: Test of an invalid player source.
GCTest.Register('ped_provider.invalid_source', function()
    local pedDefinition, errorCode = GCPedProvider.Resolve('not-a-number', {})

    GCTest.ExpectNil(pedDefinition, 'no ped for invalid source')
    GCTest.ExpectNotNil(errorCode, 'error code for invalid source')
end)