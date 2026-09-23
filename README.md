# Sıra Bende — WAMP / MySQL MVP

**Slogan:** Bugün ben sana, yarın biri bana.

Bu paket, Sıra Bende projesinin WAMP üzerinde çalışan mobil uyumlu PHP + MySQL MVP sürümüdür. Arayüzde paket içindeki gerçek marka görselleri kullanılır.

## Paket içeriği

```text
sirabende/
├─ backend/          PHP işlem katmanı, oturum, güvenlik ve sağlık kontrolü
├─ frontend/         Kullanıcı arayüzü, CSS, JavaScript, PWA dosyaları ve logo
├─ fronted/          Yazım farklılığı için frontend'e yönlendiren uyumluluk klasörü
├─ uploads/          Profil, mesaj, grup ve bildirim dosyaları
├─ .env              Yerel ortam ayarları
├─ .env.example      Örnek ortam ayarları
├─ database.sql      Temiz kurulum ve örnek veriler
├─ migration.sql     Eski kurulumları yeni alanlara yükseltme dosyası
└─ README.md         Bu kurulum rehberi
```

## Gereksinimler

- WampServer 64 bit
- Apache
- PHP 8.1 veya üzeri
- MySQL 8 veya güncel MariaDB
- PHP eklentileri: `pdo_mysql`, `fileinfo`, `mbstring`

## Temiz kurulum

1. Eski `C:\wamp64\www\sirabende` klasörünü silin.
2. ZIP dosyasını doğrudan `C:\wamp64\www\` içine çıkarın. Sonuç şu olmalıdır:

   ```text
   C:\wamp64\www\sirabende\frontend\index.php
   ```

3. WampServer'ı çalıştırın. Simgenin yeşil olduğundan emin olun.
4. Tarayıcıdan `http://localhost/phpmyadmin/` adresini açın.
5. Soldaki eski `sirabende` veritabanını silin veya doğrudan **İçe Aktar / Import** bölümüne geçin. Paket içindeki `database.sql` dosyasını seçip çalıştırın. Dosya veritabanını silip temiz biçimde yeniden oluşturur.
6. MySQL root hesabınızın şifresi varsa `.env` dosyasındaki alanı düzenleyin:

   ```env
   DB_USERNAME=root
   DB_PASSWORD=MYSQL_SIFRENIZ
   ```

7. Projeyi açın:

   ```text
   http://localhost/sirabende/frontend/
   ```

Ana klasörden de açılabilir:

```text
http://localhost/sirabende/
```

## Hızlı sağlık testi

Şu adresi açın:

```text
http://localhost/sirabende/backend/health.php
```

Başarılı kurulumda buna benzer bir JSON cevabı görünür:

```json
{
  "ok": true,
  "app": "Sıra Bende",
  "mysql": "8.x.x"
}
```

## Hazır test hesapları

### Kullanıcı

```text
E-posta: demo@sirabende.local
Şifre:   Demo123!
```

### Yönetici

```text
E-posta: admin@sirabende.local
Şifre:   Admin123!
```

Ayrıca Ayşe, Mert ve Zeynep için örnek hesaplar/veriler bulunur. Bu hesapların şifresi de `Demo123!` şeklindedir.

## Telefon doğrulama

Yerel geliştirmede gerçek SMS servisi bağlı değildir. `.env` içinde:

```env
PHONE_DEMO_MODE=true
```

olduğu için yeni hesap oluşturulduğunda 6 haneli doğrulama kodu ekranda bildirim olarak gösterilir.

## Çalışan ana özellikler

- Üyelik, giriş, çıkış ve demo telefon doğrulama
- Profil fotoğrafı, şehir, biyografi, uygunluk ve beceri yönetimi
- Yardım talebi veya yardım teklifi yayınlama
- Arama ve kategori/yöntem/ilan türü filtreleme
- Teklif gönderme, reddetme ve kabul etme
- Görev fişi, görüşme bağlantısı ve kredi blokesi
- Görevi başlatma, iki taraflı tamamlama ve kredi aktarımı
- Görev itirazı ve şikâyet sistemi
- Göreve bağlı özel mesajlaşma, fotoğraf ve PDF gönderme
- Zaman kredisi hareketleri
- Karşılıklı değerlendirme ve güven puanı
- Topluluk oluşturma ve katılma
- Grup sohbeti, fotoğraf/PDF gönderme
- Grup sahibi, yönetici, moderatör ve üye rolleri
- Üye onaylama, rol değiştirme, 24 saat susturma ve gruptan çıkarma
- Yönetici tarafından grup mesajlaşmasını açma/kapatma
- Bildirim merkezi
- Yönetim paneli, kullanıcı/ilan/şikâyet yönetimi
- Mobil uyumlu arayüz ve temel PWA desteği

## Kredi hesabı

Temel sistem:

```text
15 dakika = 0,5 kredi
30 dakika = 1 kredi
60 dakika = 2 kredi
```

İlan oluştururken en fazla `+1 kredi` karmaşıklık eklemesi seçilebilir. Kredi gerçek para değildir; satın alınamaz veya nakde çevrilemez.

## Dosya yükleme

İzin verilen türler:

- JPG
- PNG
- WEBP
- PDF

Varsayılan üst sınır `.env` içinde `5 MB` olarak ayarlanmıştır:

```env
UPLOAD_MAX_MB=5
```

Apache'nin dosya yazabilmesi için `uploads` klasörü yazılabilir olmalıdır. Windows/WAMP yerel kurulumunda normalde ek işlem gerekmez.

## Mevcut veritabanını güncelleme

Taze kurulumda **yalnızca `database.sql`** kullanın.

Daha eski bir Sıra Bende veritabanını güncelliyorsanız önce yedek alın, ardından phpMyAdmin üzerinden `migration.sql` dosyasını bir kez çalıştırın. Bu dosya eksik alanları ve yeni mesaj/bildirim tablolarını ekler.

## Klasör adı veya port değişirse

Proje klasörü farklıysa `.env` içindeki `APP_URL` değerini değiştirin:

```env
APP_URL=http://localhost/yeni-klasor-adi
```

Apache farklı portta çalışıyorsa örnek:

```env
APP_URL=http://localhost:8080/sirabende
```

## Hata çözümü


### `#1064 ... near groups` veya `Table sirabende.listings doesn't exist`

Bu hata eski pakette MySQL 8 tarafından ayrılmış `GROUPS` kelimesinin tablo adı olarak kaçışsız kullanılmasından kaynaklanıyordu. Bu sürümde tablo adı tüm SQL ve PHP sorgularında düzeltilmiştir. Eski yarım veritabanını kullanmayın; bu paketteki `database.sql` dosyasını yeniden içe aktarın.

### `Unknown database 'sirabende'`

`database.sql` dosyası içe aktarılmamış veya aktarım yarıda kalmıştır. phpMyAdmin'den dosyayı yeniden içe aktarın.

### `Access denied for user 'root'`

`.env` içindeki `DB_USERNAME` ve `DB_PASSWORD` değerlerini WAMP MySQL hesabınıza göre düzenleyin.

### Beyaz ekran

`.env` içinde yerel geliştirme için şunun açık olduğundan emin olun:

```env
APP_DEBUG=true
```

Ardından WAMP Apache hata günlüğünü kontrol edin.

### Yüklenen görsel görünmüyor

`uploads` klasörünün varlığını ve Apache tarafından yazılabilir olduğunu kontrol edin. Projeyi doğrudan dosyaya çift tıklayarak değil, `http://localhost/...` adresinden çalıştırın.

## Güvenlik notu

Bu paket yerel test ve MVP gösterimi içindir. İnternete açık gerçek kullanım öncesinde gerçek SMS/e-posta servisi, gizli anahtar yönetimi, KVKK metinleri, detaylı içerik moderasyonu, hız sınırlama, yedekleme, antivirüs dosya taraması ve bağımsız güvenlik testi eklenmelidir.
