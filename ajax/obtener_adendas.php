<?php
require_once '../conexion.php';

header('Content-Type: application/json');

$idContrato = isset($_GET['idcontrato']) ? (int)$_GET['idcontrato'] : 0;

if ($idContrato > 0) {
    try {
        $stmt = $pdo->prepare("SELECT * FROM adendacliente WHERE idcontratocli = ? ORDER BY fechainicio DESC");
        $stmt->execute([$idContrato]);
        $adendas = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode($adendas);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Error al consultar la base de datos: ' . $e->getMessage()]);
    }
} else {
    http_response_code(400);
    echo json_encode(['error' => 'ID de contrato no válido.']);
}
