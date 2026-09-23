<?php require __DIR__.'/bootstrap.php'; header('Content-Type: application/json; charset=utf-8');
try { echo json_encode(['ok'=>true,'app'=>env('APP_NAME'),'mysql'=>db()->query('SELECT VERSION()')->fetchColumn()],JSON_UNESCAPED_UNICODE|JSON_PRETTY_PRINT); }
catch(Throwable $e){http_response_code(500);echo json_encode(['ok'=>false,'error'=>$e->getMessage()],JSON_UNESCAPED_UNICODE|JSON_PRETTY_PRINT);}
