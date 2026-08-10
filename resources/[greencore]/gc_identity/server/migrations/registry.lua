GCIdentityMigrations = {
    definitions = {}
}

function GCIdentityMigrations.Register(definition)
    assert(type(definition) == 'table', 'migration definition must be a table')
    assert(type(definition.version) == 'string', 'migration version must be a string')
    assert(definition.version:match('^%d%d%d_[a-z0-9_]+$'), 'invalid migration version')
    assert(type(definition.description) == 'string', 'migration description must be a string')
    assert(type(definition.statements) == 'table' and #definition.statements > 0,
        'migration statements must not be empty')

    for _, existing in ipairs(GCIdentityMigrations.definitions) do
        assert(existing.version ~= definition.version, 'duplicate migration version')
    end

    table.insert(GCIdentityMigrations.definitions, definition)
end
function GCIdentityMigrations.List()
    local ordered = {}

    for index, definition in ipairs(GCIdentityMigrations.definitions) do
        ordered[index] = definition
    end

    table.sort(ordered, function(left, right)
        return left.version < right.version
    end)

    return ordered
end
