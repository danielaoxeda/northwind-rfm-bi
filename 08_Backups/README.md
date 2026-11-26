# Backups locales

Respaldos binarios de las bases del proyecto. **No se versionan** (`.gitignore`
excluye `*.bak`); se conservan en este equipo y deben copiarse a un
almacenamiento externo.

| Archivo | Base | Fecha | Tamaño | SHA-256 |
|---|---|---:|---:|---|
| `Northwind_DW.bak` | `Northwind_DW` | 2026-11-26 | 0,72 MB | `4033F04A4EF123F2DDEFB4DAA35FBB5ADF3C2D452FF6531F8007043A32150C4E` |

Generado con:

```sql
BACKUP DATABASE Northwind_DW
TO DISK = N'...\Northwind_DW.bak'
WITH INIT, COMPRESSION, CHECKSUM;
```

Integridad verificada con `RESTORE VERIFYONLY ... WITH CHECKSUM` (válido).
