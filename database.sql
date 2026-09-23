-- Sıra Bende - WAMP / MySQL tam kurulum veritabanı
-- Karakter seti: utf8mb4
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS=0;
DROP DATABASE IF EXISTS sirabende;
CREATE DATABASE sirabende CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE sirabende;

DROP TABLE IF EXISTS audit_logs;
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS user_badges;
DROP TABLE IF EXISTS badges;
DROP TABLE IF EXISTS group_messages;
DROP TABLE IF EXISTS group_members;
DROP TABLE IF EXISTS `groups`;
DROP TABLE IF EXISTS reports;
DROP TABLE IF EXISTS reviews;
DROP TABLE IF EXISTS messages;
DROP TABLE IF EXISTS conversations;
DROP TABLE IF EXISTS credit_transactions;
DROP TABLE IF EXISTS exchanges;
DROP TABLE IF EXISTS applications;
DROP TABLE IF EXISTS listings;
DROP TABLE IF EXISTS user_skills;
DROP TABLE IF EXISTS skills;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  full_name VARCHAR(120) NOT NULL,
  username VARCHAR(30) NOT NULL UNIQUE,
  email VARCHAR(190) NOT NULL UNIQUE,
  phone VARCHAR(30) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('user','moderator','admin') NOT NULL DEFAULT 'user',
  status ENUM('active','suspended','banned') NOT NULL DEFAULT 'active',
  city VARCHAR(80) NOT NULL,
  district VARCHAR(80) NULL,
  birth_date DATE NOT NULL,
  avatar VARCHAR(255) NULL,
  bio TEXT NULL,
  availability VARCHAR(255) NULL,
  credit_balance DECIMAL(10,2) NOT NULL DEFAULT 0,
  held_credits DECIMAL(10,2) NOT NULL DEFAULT 0,
  trust_score DECIMAL(5,2) NOT NULL DEFAULT 50,
  total_help_minutes INT UNSIGNED NOT NULL DEFAULT 0,
  level INT UNSIGNED NOT NULL DEFAULT 1,
  verification_code VARCHAR(10) NULL,
  verification_expires_at DATETIME NULL,
  phone_verified_at DATETIME NULL,
  last_seen_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_users_status_city(status,city),
  INDEX idx_users_role(role)
) ENGINE=InnoDB;

CREATE TABLE categories (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(80) NOT NULL,
  slug VARCHAR(90) NOT NULL UNIQUE,
  icon VARCHAR(20) NULL,
  sort_order INT NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE skills (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  category_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(100) NOT NULL,
  slug VARCHAR(110) NOT NULL UNIQUE,
  risk_level ENUM('low','medium','restricted') NOT NULL DEFAULT 'low',
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  CONSTRAINT fk_skills_category FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE CASCADE,
  INDEX idx_skills_category(category_id,is_active)
) ENGINE=InnoDB;

CREATE TABLE user_skills (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  skill_id BIGINT UNSIGNED NOT NULL,
  type ENUM('offer','request') NOT NULL,
  experience_level ENUM('beginner','intermediate','advanced','expert') NOT NULL DEFAULT 'beginner',
  description TEXT NULL,
  verification_status ENUM('none','pending','verified','rejected') NOT NULL DEFAULT 'none',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_user_skill_type(user_id,skill_id,type),
  CONSTRAINT fk_user_skills_user FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_user_skills_skill FOREIGN KEY(skill_id) REFERENCES skills(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE listings (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  skill_id BIGINT UNSIGNED NOT NULL,
  listing_type ENUM('request','offer') NOT NULL,
  title VARCHAR(120) NOT NULL,
  description TEXT NOT NULL,
  delivery_type ENUM('online','in_person','hybrid') NOT NULL DEFAULT 'online',
  estimated_minutes SMALLINT UNSIGNED NOT NULL DEFAULT 30,
  complexity_bonus DECIMAL(4,2) NOT NULL DEFAULT 0,
  credit_cost DECIMAL(8,2) NOT NULL,
  city VARCHAR(80) NULL,
  district VARCHAR(80) NULL,
  available_at DATETIME NULL,
  special_conditions TEXT NULL,
  featured TINYINT(1) NOT NULL DEFAULT 0,
  status ENUM('open','paused','matched','completed','cancelled') NOT NULL DEFAULT 'open',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_listings_user FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_listings_skill FOREIGN KEY(skill_id) REFERENCES skills(id),
  INDEX idx_listings_search(status,listing_type,delivery_type,created_at),
  INDEX idx_listings_city(city),
  INDEX idx_listings_skill(skill_id)
) ENGINE=InnoDB;

CREATE TABLE applications (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  listing_id BIGINT UNSIGNED NOT NULL,
  applicant_id BIGINT UNSIGNED NOT NULL,
  message TEXT NOT NULL,
  proposed_at DATETIME NULL,
  status ENUM('pending','accepted','rejected','cancelled') NOT NULL DEFAULT 'pending',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_application(listing_id,applicant_id),
  CONSTRAINT fk_applications_listing FOREIGN KEY(listing_id) REFERENCES listings(id) ON DELETE CASCADE,
  CONSTRAINT fk_applications_user FOREIGN KEY(applicant_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_applications_status(listing_id,status)
) ENGINE=InnoDB;

CREATE TABLE exchanges (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  requester_id BIGINT UNSIGNED NOT NULL,
  provider_id BIGINT UNSIGNED NOT NULL,
  listing_id BIGINT UNSIGNED NOT NULL,
  application_id BIGINT UNSIGNED NULL,
  agreed_minutes SMALLINT UNSIGNED NOT NULL,
  agreed_credits DECIMAL(8,2) NOT NULL,
  delivery_type ENUM('online','in_person','hybrid') NOT NULL,
  scope TEXT NOT NULL,
  meeting_url VARCHAR(500) NULL,
  scheduled_at DATETIME NULL,
  started_at DATETIME NULL,
  ended_at DATETIME NULL,
  requester_confirmed TINYINT(1) NOT NULL DEFAULT 0,
  provider_confirmed TINYINT(1) NOT NULL DEFAULT 0,
  dispute_reason TEXT NULL,
  status ENUM('accepted','in_progress','completed','cancelled','disputed') NOT NULL DEFAULT 'accepted',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_exchanges_requester FOREIGN KEY(requester_id) REFERENCES users(id),
  CONSTRAINT fk_exchanges_provider FOREIGN KEY(provider_id) REFERENCES users(id),
  CONSTRAINT fk_exchanges_listing FOREIGN KEY(listing_id) REFERENCES listings(id),
  CONSTRAINT fk_exchanges_application FOREIGN KEY(application_id) REFERENCES applications(id) ON DELETE SET NULL,
  INDEX idx_exchanges_requester(requester_id,status),
  INDEX idx_exchanges_provider(provider_id,status)
) ENGINE=InnoDB;

CREATE TABLE credit_transactions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  exchange_id BIGINT UNSIGNED NULL,
  amount DECIMAL(10,2) NOT NULL,
  transaction_type ENUM('initial','hold','release','earn','refund','adjustment') NOT NULL,
  balance_after DECIMAL(10,2) NOT NULL,
  held_after DECIMAL(10,2) NOT NULL DEFAULT 0,
  description VARCHAR(255) NOT NULL,
  status ENUM('pending','completed','cancelled') NOT NULL DEFAULT 'completed',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_credit_user FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_credit_exchange FOREIGN KEY(exchange_id) REFERENCES exchanges(id) ON DELETE SET NULL,
  INDEX idx_credit_user_date(user_id,created_at)
) ENGINE=InnoDB;

CREATE TABLE conversations (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  exchange_id BIGINT UNSIGNED NOT NULL UNIQUE,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_conversation_exchange FOREIGN KEY(exchange_id) REFERENCES exchanges(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE messages (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  conversation_id BIGINT UNSIGNED NOT NULL,
  sender_id BIGINT UNSIGNED NOT NULL,
  message TEXT NULL,
  attachment_path VARCHAR(255) NULL,
  attachment_type ENUM('image','document') NULL,
  moderation_status ENUM('clean','flagged','hidden') NOT NULL DEFAULT 'clean',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_messages_conversation FOREIGN KEY(conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
  CONSTRAINT fk_messages_sender FOREIGN KEY(sender_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_messages_conversation(conversation_id,created_at)
) ENGINE=InnoDB;

CREATE TABLE reviews (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  exchange_id BIGINT UNSIGNED NOT NULL,
  reviewer_id BIGINT UNSIGNED NOT NULL,
  reviewed_user_id BIGINT UNSIGNED NOT NULL,
  rating TINYINT UNSIGNED NOT NULL,
  comment TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_review(exchange_id,reviewer_id),
  CONSTRAINT fk_reviews_exchange FOREIGN KEY(exchange_id) REFERENCES exchanges(id) ON DELETE CASCADE,
  CONSTRAINT fk_reviews_reviewer FOREIGN KEY(reviewer_id) REFERENCES users(id),
  CONSTRAINT fk_reviews_reviewed FOREIGN KEY(reviewed_user_id) REFERENCES users(id),
  INDEX idx_reviews_user(reviewed_user_id,created_at)
) ENGINE=InnoDB;

CREATE TABLE reports (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  reporter_id BIGINT UNSIGNED NOT NULL,
  target_type ENUM('user','listing','exchange','group','message') NOT NULL,
  target_id BIGINT UNSIGNED NOT NULL,
  reason TEXT NOT NULL,
  evidence VARCHAR(255) NULL,
  status ENUM('open','reviewing','resolved','dismissed') NOT NULL DEFAULT 'open',
  resolved_by BIGINT UNSIGNED NULL,
  resolved_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_reports_reporter FOREIGN KEY(reporter_id) REFERENCES users(id),
  CONSTRAINT fk_reports_resolver FOREIGN KEY(resolved_by) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_reports_status(status,created_at),
  INDEX idx_reports_target(target_type,target_id)
) ENGINE=InnoDB;

CREATE TABLE `groups` (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  owner_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(120) NOT NULL,
  description TEXT NOT NULL,
  visibility ENUM('public','private') NOT NULL DEFAULT 'public',
  city VARCHAR(80) NULL,
  cover_image VARCHAR(255) NULL,
  messaging_enabled TINYINT(1) NOT NULL DEFAULT 1,
  status ENUM('active','paused','closed') NOT NULL DEFAULT 'active',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_groups_owner FOREIGN KEY(owner_id) REFERENCES users(id),
  INDEX idx_groups_status(status,visibility,created_at)
) ENGINE=InnoDB;

CREATE TABLE group_members (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  group_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  role ENUM('pending','member','moderator','admin','owner') NOT NULL DEFAULT 'member',
  is_muted TINYINT(1) NOT NULL DEFAULT 0,
  muted_until DATETIME NULL,
  joined_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_group_member(group_id,user_id),
  CONSTRAINT fk_group_members_group FOREIGN KEY(group_id) REFERENCES `groups`(id) ON DELETE CASCADE,
  CONSTRAINT fk_group_members_user FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_group_members_role(group_id,role)
) ENGINE=InnoDB;

CREATE TABLE group_messages (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  group_id BIGINT UNSIGNED NOT NULL,
  sender_id BIGINT UNSIGNED NOT NULL,
  message TEXT NULL,
  attachment_path VARCHAR(255) NULL,
  attachment_type ENUM('image','document') NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_group_messages_group FOREIGN KEY(group_id) REFERENCES `groups`(id) ON DELETE CASCADE,
  CONSTRAINT fk_group_messages_sender FOREIGN KEY(sender_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_group_messages_date(group_id,created_at)
) ENGINE=InnoDB;

CREATE TABLE badges (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  description VARCHAR(255) NOT NULL,
  requirement VARCHAR(255) NULL,
  icon VARCHAR(30) NULL
) ENGINE=InnoDB;

CREATE TABLE user_badges (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  badge_id BIGINT UNSIGNED NOT NULL,
  earned_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_user_badge(user_id,badge_id),
  CONSTRAINT fk_user_badges_user FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_user_badges_badge FOREIGN KEY(badge_id) REFERENCES badges(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE notifications (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(150) NOT NULL,
  message VARCHAR(500) NOT NULL,
  link VARCHAR(255) NULL,
  read_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_notifications_user FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_notifications_user(user_id,read_at,created_at)
) ENGINE=InnoDB;

CREATE TABLE audit_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  actor_id BIGINT UNSIGNED NULL,
  action VARCHAR(100) NOT NULL,
  target_type VARCHAR(50) NOT NULL,
  target_id BIGINT UNSIGNED NULL,
  metadata JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_audit_actor FOREIGN KEY(actor_id) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_audit_target(target_type,target_id),
  INDEX idx_audit_date(created_at)
) ENGINE=InnoDB;

INSERT INTO categories(id,name,slug,icon,sort_order) VALUES
(1,'Eğitim','egitim','📚',1),(2,'Kariyer','kariyer','💼',2),(3,'Dil Pratiği','dil-pratigi','🗣️',3),(4,'Teknoloji','teknoloji','💻',4),(5,'Tasarım ve İçerik','tasarim-icerik','🎨',5),(6,'Günlük Hayat','gunluk-hayat','🏡',6);

INSERT INTO skills(id,category_id,name,slug,risk_level) VALUES
(1,1,'Matematik','matematik','low'),(2,1,'Excel','excel','low'),(3,1,'Sunum Hazırlama','sunum-hazirlama','low'),(4,1,'Satranç','satranc','low'),
(5,2,'CV Düzenleme','cv-duzenleme','low'),(6,2,'Mülakat Provası','mulakat-provasi','low'),(7,2,'LinkedIn Profili','linkedin-profili','low'),(8,2,'Portfolyo Değerlendirme','portfolyo-degerlendirme','low'),
(9,3,'İngilizce Konuşma','ingilizce-konusma','low'),(10,3,'Almanca Konuşma','almanca-konusma','low'),(11,3,'Türkçe Pratiği','turkce-pratigi','low'),(12,3,'Metin Çevirisi','metin-cevirisi','medium'),
(13,4,'Bilgisayar Kurulumu','bilgisayar-kurulumu','medium'),(14,4,'Telefon Kullanımı','telefon-kullanimi','low'),(15,4,'Yazılım Öğrenme','yazilim-ogrenme','low'),(16,4,'İnternet Sorunları','internet-sorunlari','medium'),
(17,5,'Canva','canva','low'),(18,5,'Logo Geri Bildirimi','logo-geri-bildirimi','low'),(19,5,'Fotoğraf Düzenleme','fotograf-duzenleme','low'),(20,5,'Metin Düzeltme','metin-duzeltme','low'),
(21,6,'Bitki Bakımı','bitki-bakimi','low'),(22,6,'Evcil Hayvan Gezdirme','evcil-hayvan-gezdirme','medium'),(23,6,'Mobilya Kurulumu','mobilya-kurulumu','medium'),(24,6,'Şehir İçi Ulaşım','sehir-ici-ulasim','low');

-- Şifreler: Admin123! ve Demo123!
INSERT INTO users(id,full_name,username,email,phone,password_hash,role,status,city,district,birth_date,bio,availability,credit_balance,held_credits,trust_score,total_help_minutes,level,phone_verified_at,created_at,updated_at) VALUES
(1,'Sıra Bende Yöneticisi','admin','admin@sirabende.local','05000000001','$2y$12$3joIcR.nspDn6z6lgbHpquhvqvWbQAbF9txjtf9Ow8xV2hXCpwWTq','admin','active','İstanbul','Kadıköy','1990-01-01','Platform yönetim hesabı.','Her zaman',20,0,100,1200,20,NOW(),NOW(),NOW()),
(2,'Deniz Yılmaz','demo','demo@sirabende.local','05000000002','$2y$12$5njxnc4ea3VP.zNQyoGqCuxSWAZUQ/IYsIXF9e.gSjFHbyfnOuBSO','user','active','İstanbul','Beşiktaş','1998-04-16','CV, sunum ve başlangıç düzeyi tasarım konularında destek olabilirim.','Hafta içi 19.00 sonrası',8,0,92,870,10,NOW(),NOW(),NOW()),
(3,'Ayşe Kaya','aysekaya','ayse@sirabende.local','05000000003','$2y$12$5njxnc4ea3VP.zNQyoGqCuxSWAZUQ/IYsIXF9e.gSjFHbyfnOuBSO','user','active','İstanbul','Şişli','1999-08-10','İngilizce pratiği ve Excel öğrenmek istiyorum; Canva konusunda yardımcı olabilirim.','Salı ve Perşembe akşamları',4,0,86,420,5,NOW(),NOW(),NOW()),
(4,'Mert Arslan','mertarslan','mert@sirabende.local','05000000004','$2y$12$5njxnc4ea3VP.zNQyoGqCuxSWAZUQ/IYsIXF9e.gSjFHbyfnOuBSO','user','active','Ankara','Çankaya','1996-03-22','Yazılım ve bilgisayar kurulumu alanlarında deneyimliyim.','Hafta sonu',6,2,89,640,7,NOW(),NOW(),NOW()),
(5,'Zeynep Akın','zeynepakin','zeynep@sirabende.local','05000000005','$2y$12$5njxnc4ea3VP.zNQyoGqCuxSWAZUQ/IYsIXF9e.gSjFHbyfnOuBSO','user','active','İzmir','Bornova','1997-11-05','İngilizce konuşma pratiği yapabilir, metin düzenlemeye yardım edebilirim.','Pazar günleri',5,0,95,1040,12,NOW(),NOW(),NOW());

INSERT INTO user_skills(user_id,skill_id,type,experience_level) VALUES
(2,5,'offer','advanced'),(2,3,'offer','advanced'),(2,17,'offer','intermediate'),(2,9,'request','beginner'),
(3,17,'offer','advanced'),(3,2,'request','beginner'),(3,9,'request','intermediate'),
(4,13,'offer','advanced'),(4,15,'offer','advanced'),(4,5,'request','beginner'),
(5,9,'offer','advanced'),(5,20,'offer','advanced'),(5,15,'request','beginner');

INSERT INTO listings(id,user_id,skill_id,listing_type,title,description,delivery_type,estimated_minutes,complexity_bonus,credit_cost,city,district,available_at,special_conditions,featured,status,created_at,updated_at) VALUES
(1,3,2,'request','Başlangıç düzeyinde Excel öğrenmek istiyorum','Tablo oluşturma, temel formüller ve filtreleme konularını birlikte uygulayabileceğim birini arıyorum.','online',60,0,2,'İstanbul','Şişli',DATE_ADD(NOW(),INTERVAL 2 DAY),'Ekran paylaşımı yapabilirim.',1,'open',NOW(),NOW()),
(2,2,5,'offer','Yeni mezunlar için CV geri bildirimi verebilirim','CV içeriğini, sıralamasını ve okunabilirliğini birlikte değerlendirebilir; net geliştirme önerileri sunabilirim.','online',45,.5,2,'İstanbul','Beşiktaş',DATE_ADD(NOW(),INTERVAL 3 DAY),'İşe yerleştirme garantisi verilmez.',1,'open',NOW(),NOW()),
(3,5,9,'offer','İngilizce konuşma pratiği yapabiliriz','Günlük konular üzerine rahat bir konuşma pratiği yapabilir, telaffuz ve kelime seçimi konusunda geri bildirim verebilirim.','online',30,0,1,'İzmir','Bornova',DATE_ADD(NOW(),INTERVAL 1 DAY),NULL,1,'open',NOW(),NOW()),
(4,4,13,'offer','Bilgisayar kurulumunda uzaktan destek','Yeni bilgisayarda temel programların kurulumu ve güvenli başlangıç ayarları için ekran paylaşımıyla yardımcı olabilirim.','online',60,.5,2.5,'Ankara','Çankaya',DATE_ADD(NOW(),INTERVAL 4 DAY),'Lisanssız yazılım kurulmaz.',0,'open',NOW(),NOW()),
(5,4,5,'request','Yazılım pozisyonu için CV değerlendirmesi','Backend geliştirici pozisyonlarına başvuracağım CV için teknik içerik ve anlatım geri bildirimi arıyorum.','online',45,.5,2,'Ankara','Çankaya',DATE_ADD(NOW(),INTERVAL 5 DAY),NULL,0,'matched',NOW(),NOW()),
(6,3,17,'offer','Canva başlangıç eğitimi verebilirim','Sosyal medya gönderisi, şablon düzenleme ve temel tasarım ilkelerini bir saatlik uygulamayla anlatabilirim.','online',60,0,2,'İstanbul','Şişli',DATE_ADD(NOW(),INTERVAL 6 DAY),NULL,0,'open',NOW(),NOW());

INSERT INTO applications(id,listing_id,applicant_id,message,proposed_at,status,created_at,updated_at) VALUES
(1,5,2,'İnsan kaynakları odaklı CV inceleme deneyimim var; teknik içerik sıralamasına birlikte bakabiliriz.',DATE_ADD(NOW(),INTERVAL 5 DAY),'accepted',NOW(),NOW()),
(2,1,4,'Excel temellerini ekran paylaşımıyla ve örnek dosya üzerinden anlatabilirim.',DATE_ADD(NOW(),INTERVAL 2 DAY),'pending',NOW(),NOW());

INSERT INTO exchanges(id,requester_id,provider_id,listing_id,application_id,agreed_minutes,agreed_credits,delivery_type,scope,meeting_url,scheduled_at,status,created_at,updated_at) VALUES
(1,4,2,5,1,45,2,'online','Yazılım pozisyonlarına yönelik CV içeriği, bölüm sıralaması ve anlatımın birlikte incelenmesi.','https://meet.google.com/',DATE_ADD(NOW(),INTERVAL 5 DAY),'accepted',NOW(),NOW());
INSERT INTO conversations(id,exchange_id,created_at,updated_at) VALUES(1,1,NOW(),NOW());
INSERT INTO messages(conversation_id,sender_id,message,created_at) VALUES
(1,4,'Merhaba Deniz, özellikle proje açıklamalarımı daha net hâle getirmek istiyorum.',NOW()),
(1,2,'Merhaba Mert, görüşmede önce hedef pozisyonları sonra CV bölümlerini birlikte inceleyelim.',NOW());

INSERT INTO credit_transactions(user_id,amount,transaction_type,balance_after,held_after,description,status,created_at) VALUES
(1,20,'initial',20,0,'Yönetici test bakiyesi','completed',NOW()),
(2,10,'initial',10,0,'Demo başlangıç bakiyesi','completed',DATE_SUB(NOW(),INTERVAL 10 DAY)),
(3,4,'initial',4,0,'Demo başlangıç bakiyesi','completed',NOW()),
(4,8,'initial',8,0,'Demo başlangıç bakiyesi','completed',DATE_SUB(NOW(),INTERVAL 5 DAY)),
(4,-2,'hold',6,2,'Görev için kredi blokesi: Yazılım pozisyonu için CV değerlendirmesi','completed',NOW()),
(5,5,'initial',5,0,'Demo başlangıç bakiyesi','completed',NOW());

INSERT INTO `groups`(id,owner_id,name,description,visibility,city,messaging_enabled,status,created_at,updated_at) VALUES
(1,2,'Yeni Mezunlar Dayanışması','CV, mülakat, portfolyo ve iş arama deneyimlerinin paylaşıldığı güvenli topluluk.','public','İstanbul',1,'active',NOW(),NOW()),
(2,5,'İngilizce Pratik Grubu','Haftalık konuşma konuları ve küçük grup pratikleri için oluşturulan topluluk.','public','Türkiye',1,'active',NOW(),NOW()),
(3,4,'Yazılım Öğrenenler','Başlangıç seviyesinde yazılım öğrenenlerin soru sorup kaynak paylaşabildiği onaylı grup.','private','Türkiye',1,'active',NOW(),NOW());
INSERT INTO group_members(group_id,user_id,role,joined_at) VALUES
(1,2,'owner',NOW()),(1,3,'member',NOW()),(1,4,'member',NOW()),
(2,5,'owner',NOW()),(2,2,'admin',NOW()),(2,3,'member',NOW()),
(3,4,'owner',NOW()),(3,2,'member',NOW());
INSERT INTO group_messages(group_id,sender_id,message,created_at) VALUES
(1,2,'Herkese hoş geldiniz. İlk haftanın konusu: CV’de proje anlatımı.',NOW()),
(1,3,'Ben de örnek bir CV şablonu üzerinden sorularımı paylaşacağım.',NOW()),
(2,5,'Pazar günü 20.00 için konuşma konusu: travel and hobbies.',NOW());

INSERT INTO badges(id,name,description,requirement,icon) VALUES
(1,'İlk Yardım','İlk görevini tamamladı.','1 tamamlanan görev','🤝'),
(2,'10 Saat Paylaştı','Toplam 10 saat katkı sağladı.','600 yardım dakikası','⏱️'),
(3,'Zamanında','Görevlerine düzenli olarak zamanında katıldı.','Yüksek zamanında katılım','✅'),
(4,'Topluluk Rehberi','Topluluklarda güvenilir destek sağladı.','Yönetici onayı','🌿');
INSERT INTO user_badges(user_id,badge_id,earned_at) VALUES(2,1,NOW()),(2,2,NOW()),(5,1,NOW()),(5,2,NOW());

INSERT INTO notifications(user_id,title,message,link,created_at) VALUES
(2,'Yeni görev','Mert ile CV değerlendirme görevin oluşturuldu.','exchange&id=1',NOW()),
(4,'Görev oluşturuldu','Deniz ile CV değerlendirme görevin oluşturuldu.','exchange&id=1',NOW()),
(3,'Yeni teklif','Mert Excel ilanına teklif gönderdi.','listing&id=1',NOW());

INSERT INTO audit_logs(actor_id,action,target_type,target_id,metadata,created_at) VALUES
(1,'database_seed','system',NULL,JSON_OBJECT('version','1.0.0'),NOW());

SET FOREIGN_KEY_CHECKS=1;
