<?php
date_default_timezone_set('America/Lima');
$config = require_once 'config/db.php';

$host = $config['host'];
$db   = $config['db'];
$user = $config['user'];
$pass = $config['pass'];

try {
    $pdo = new PDO("mysql:host=$host;dbname=$db;charset=utf8", $user, $pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->exec("SET time_zone = '-05:00';"); // Para America/Lima (UTC-5)
} catch (PDOException $e) {
    die("Error de conexión: " . $e->getMessage());
}
?>
