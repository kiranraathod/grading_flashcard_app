## Remaining RepositoryException Fixes

Since there are many RepositoryException issues, let me create a simple script to fix the remaining ones:

### Pattern to fix:
`throw RepositoryException('message');`

### Should become:
`throw RepositoryException(message: 'message', operation: 'operationName');`

Here are the remaining fixes needed based on the analysis errors. I'll use specific operation names based on the context:

