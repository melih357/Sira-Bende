<?php
declare(strict_types=1);

define('ROOT_PATH', dirname(__DIR__));

function load_env(string $path): void {
    if (!is_file($path)) return;
    foreach (file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) ?: [] as $line) {
        $line = trim($line);
        if ($line === '' || str_starts_with($line, '#') || !str_contains($line, '=')) continue;
        [$k,$v] = array_map('trim', explode('=', $line, 2));
        if (($v[0] ?? '') === '"' && str_ends_with($v,'"')) $v = substr($v,1,-1);
        if (($v[0] ?? '') === "'" && str_ends_with($v,"'")) $v = substr($v,1,-1);
        $_ENV[$k] = $v; putenv("$k=$v");
    }
}
function env(string $key, mixed $default=null): mixed {
    $v = $_ENV[$key] ?? getenv($key);
    if ($v === false || $v === null || $v === '') return $default;
    return match(strtolower((string)$v)) {'true'=>true,'false'=>false,'null'=>null,default=>$v};
}
load_env(ROOT_PATH.'/.env');
if ((bool)env('APP_DEBUG',false)) { error_reporting(E_ALL); ini_set('display_errors','1'); }
date_default_timezone_set((string)env('APP_TIMEZONE','Europe/Istanbul'));
if (session_status() !== PHP_SESSION_ACTIVE) {
    session_name('sirabende_session');
    session_start(['cookie_httponly'=>true,'cookie_samesite'=>'Lax','use_strict_mode'=>true]);
}

function db(): PDO {
    static $pdo;
    if ($pdo instanceof PDO) return $pdo;
    $dsn='mysql:host='.env('DB_HOST','127.0.0.1').';port='.env('DB_PORT','3306').';dbname='.env('DB_DATABASE','sirabende').';charset=utf8mb4';
    $pdo = new PDO($dsn,(string)env('DB_USERNAME','root'),(string)env('DB_PASSWORD',''),[
        PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE=>PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES=>false,
    ]);
    return $pdo;
}
function e(mixed $v): string { return htmlspecialchars((string)($v ?? ''),ENT_QUOTES,'UTF-8'); }
function base_url(string $path=''): string { return rtrim((string)env('APP_URL','http://localhost/sirabende'),'/').($path!==''?'/'.ltrim($path,'/'):''); }
function app_url(string $page='home', array $params=[]): string {
    $params = array_merge(['page'=>$page],$params);
    return base_url('frontend/index.php?'.http_build_query($params));
}
function action_url(): string { return base_url('backend/action.php'); }
function asset(string $p): string { return base_url('frontend/assets/'.ltrim($p,'/')); }
function upload_url(?string $p): string { return $p ? base_url('uploads/'.ltrim($p,'/')) : asset('img/logo-mark.png'); }
function redirect_to(string $url): never { header('Location: '.$url); exit; }
function redirect_page(string $page='home', array $params=[]): never { redirect_to(app_url($page,$params)); }
function back(string $fallback='dashboard'): never { redirect_to($_SERVER['HTTP_REFERER'] ?? app_url($fallback)); }
function flash(string $type,string $msg): void { $_SESSION['_flash'][$type][]=$msg; }
function flashes(): array { $f=$_SESSION['_flash']??[]; unset($_SESSION['_flash']); return $f; }
function csrf_token(): string { return $_SESSION['_csrf'] ??= bin2hex(random_bytes(32)); }
function csrf_field(): string { return '<input type="hidden" name="_token" value="'.e(csrf_token()).'">'; }
function check_csrf(): void { if (!hash_equals(csrf_token(),(string)($_POST['_token']??''))) { http_response_code(419); exit('Oturum doğrulaması başarısız.'); } }
function current_user(): ?array {
    $id=(int)($_SESSION['user_id']??0); if(!$id) return null;
    $s=db()->prepare('SELECT * FROM users WHERE id=?'); $s->execute([$id]); $u=$s->fetch();
    if(!$u || $u['status']!=='active'){unset($_SESSION['user_id']);return null;} return $u;
}
function require_user(): array { $u=current_user(); if(!$u){flash('warning','Bu işlem için giriş yapmalısınız.');redirect_page('login');} return $u; }
function require_admin(): array { $u=require_user(); if(!in_array($u['role'],['admin','moderator'],true)){http_response_code(403);exit('Yetkisiz erişim.');} return $u; }
function is_admin(?array $u=null): bool { $u ??= current_user(); return $u && in_array($u['role'],['admin','moderator'],true); }
function credit_for_minutes(int $m,float $bonus=0): float { return round(max(.5,ceil(max(1,min(240,$m))/15)*.5)+max(0,min(1,$bonus)),2); }
function credit(mixed $n): string { return number_format((float)$n,1,',','.').' kredi'; }
function dt(?string $d,string $fmt='d.m.Y H:i'): string { return $d?date($fmt,strtotime($d)):'Belirtilmedi'; }
function status_label(string $s): string { return ['open'=>'Açık','paused'=>'Duraklatıldı','matched'=>'Eşleşti','completed'=>'Tamamlandı','cancelled'=>'İptal','pending'=>'Bekliyor','accepted'=>'Kabul edildi','rejected'=>'Reddedildi','in_progress'=>'Devam ediyor','disputed'=>'İtirazlı','active'=>'Aktif','suspended'=>'Askıda','banned'=>'Yasaklı','reviewing'=>'İnceleniyor','resolved'=>'Çözüldü','dismissed'=>'Geçersiz'][$s]??$s; }
function notify(int $uid,string $title,string $message,?string $link=null): void { $s=db()->prepare('INSERT INTO notifications(user_id,title,message,link,created_at) VALUES(?,?,?,?,NOW())');$s->execute([$uid,$title,$message,$link]); }
function audit(?int $actor,string $action,string $type,?int $id=null,array $meta=[]): void { $s=db()->prepare('INSERT INTO audit_logs(actor_id,action,target_type,target_id,metadata,created_at) VALUES(?,?,?,?,?,NOW())');$s->execute([$actor,$action,$type,$id,json_encode($meta,JSON_UNESCAPED_UNICODE)]); }
function upload_file(array $file,string $folder): ?string {
    if(($file['error']??UPLOAD_ERR_NO_FILE)===UPLOAD_ERR_NO_FILE)return null;
    if(($file['error']??1)!==UPLOAD_ERR_OK)throw new RuntimeException('Dosya yüklenemedi.');
    if(($file['size']??0)>((int)env('UPLOAD_MAX_MB',5))*1024*1024)throw new RuntimeException('Dosya boyutu sınırı aşıldı.');
    $mime=(new finfo(FILEINFO_MIME_TYPE))->file((string)$file['tmp_name']);
    $map=['image/jpeg'=>'jpg','image/png'=>'png','image/webp'=>'webp','application/pdf'=>'pdf'];
    if(!isset($map[$mime]))throw new RuntimeException('Yalnızca JPG, PNG, WEBP veya PDF yüklenebilir.');
    $rel=trim($folder,'/').'/'.date('Y/m');$dir=ROOT_PATH.'/uploads/'.$rel;
    if(!is_dir($dir))mkdir($dir,0775,true);
    $name=bin2hex(random_bytes(16)).'.'.$map[$mime];
    if(!move_uploaded_file((string)$file['tmp_name'],$dir.'/'.$name))throw new RuntimeException('Dosya kaydedilemedi.');
    return $rel.'/'.$name;
}
