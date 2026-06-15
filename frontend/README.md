# GoDone Mobile

Flutter Android frontend ini terhubung ke backend web Laravel di folder `../../backend`.

## Backend Yang Dipakai

- APK release memakai backend production:
  `https://backend-go-done-v2-production-39e7.up.railway.app/api`
- Android emulator debug memakai backend lokal:
  `http://10.0.2.2:8000/api`
- Web/desktop debug memakai backend lokal:
  `http://127.0.0.1:8000/api`

## Jalankan Dengan Backend Web Lokal

Dari folder `godone-mobile/frontend`:

```powershell
cd ..\..\backend
php artisan serve --host=127.0.0.1 --port=8000
```

Lalu jalankan Android dari folder ini:

```powershell
flutter run
```

Untuk HP fisik di jaringan yang sama, pakai IP laptop:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
```

Ganti `192.168.1.10` dengan IP laptop.
