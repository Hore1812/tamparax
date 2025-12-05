<?php
header('Content-Type: application/json');
require_once '../conexion.php';

if (!isset($_GET['id']) || !filter_var($_GET['id'], FILTER_VALIDATE_INT)) {
    echo json_encode(['error' => 'ID de adenda no válido.']);
    exit;
}

$idAdenda = (int)$_GET['id'];

try {
    $sql = "SELECT * FROM adendacliente WHERE idadendacli = ?";
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$idAdenda]);
    $adenda = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($adenda) {
        echo json_encode($adenda);
    } else {
        echo json_encode(['error' => 'No se encontró la adenda.']);
    }
} catch (PDOException $e) {
    // En un entorno de producción, sería mejor registrar este error en lugar de mostrarlo
    echo json_encode(['error' => 'Error de base de datos: ' . $e->getMessage()]);
}
