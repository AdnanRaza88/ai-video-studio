# Storage

- SQLite for metadata only
- Private app filesystem for models, project assets, cache, logs
- MediaStore for user-exported videos
- Never store large binary assets inside SQLite
- Clear cache and intermediate assets safely; never auto-delete projects
