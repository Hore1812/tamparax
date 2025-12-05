<?php
session_start();
require_once '../conexion.php';
require_once '../auth_check.php';

header('Content-Type: application/json');

$response = ['success' => false, 'message' => 'Acción no permitida.'];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $idAdenda = isset($_POST['idadenda']) ? filter_var($_POST['idadenda'], FILTER_VALIDATE_INT) : null;
    $editor_id = $_SESSION['idemp'] ?? 0;

    if (!$editor_id) {
        $response['message'] = 'Error de sesión. No se pudo identificar al usuario.';
        echo json_encode($response);
        exit;
    }

    if ($idAdenda) {
        try {
            $pdo->beginTransaction();

            // 1. Obtener la ruta del archivo PDF antes de eliminar el registro
            $stmt_path = $pdo->prepare("SELECT rutaarchivo FROM adendacliente WHERE idadendacli = ?");
            $stmt_path->execute([$idAdenda]);
            $ruta_pdf = $stmt_path->fetchColumn();

            // 2. Eliminar el registro de la adenda de la base de datos
            $stmt_delete = $pdo->prepare("DELETE FROM adendacliente WHERE idadendacli = ?");
            $delete_success = $stmt_delete->execute([$idAdenda]);

            if ($delete_success) {
                // 3. Si la eliminación en la BD fue exitosa, eliminar el archivo físico
                if ($ruta_pdf && file_exists('../' . $ruta_pdf)) {
                    unlink('../' . $ruta_pdf);
                }
                $pdo->commit();
                $response['success'] = true;
                $response['message'] = 'Adenda eliminada correctamente.';
            } else {
                $pdo->rollBack();
                $response['message'] = 'No se pudo eliminar el registro de la adenda.';
            }
        } catch (PDOException $e) {
            $pdo->rollBack();
            $response['message'] = 'Error en la base de datos: ' . $e->getMessage();
        }
    } else {
        $response['message'] = 'ID de adenda no válido o no proporcionado.';
    }
}

echo json_encode($response);
exit;
