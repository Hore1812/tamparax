<?php
session_start();
require_once 'conexion.php';
require_once 'auth_check.php';

function manejarSubidaPdf($idcontratocli, $pdo, $nombreCampo = 'pdf_adenda') {
    if (isset($_FILES[$nombreCampo]) && $_FILES[$nombreCampo]['error'] == UPLOAD_ERR_OK) {
        $fileTmpPath = $_FILES[$nombreCampo]['tmp_name'];
        $fileName = $_FILES[$nombreCampo]['name'];
        $fileExtension = strtolower(pathinfo($fileName, PATHINFO_EXTENSION));

        if ($fileExtension == 'pdf') {
            $stmt = $pdo->prepare("SELECT c.nombrecomercial FROM contratocliente cc JOIN cliente c ON cc.idcliente = c.idcliente WHERE cc.idcontratocli = ?");
            $stmt->execute([$idcontratocli]);
            $clienteNombre = $stmt->fetchColumn() ?: 'desconocido';
            
            $fechaActual = date('Ymd');
            $uploadFileDir = 'PDF/adendas/';
            if (!is_dir($uploadFileDir)) {
                mkdir($uploadFileDir, 0777, true);
            }
            $newFileName = 'adenda_' . preg_replace('/[^a-zA-Z0-9_-]/', '_', $clienteNombre) . '_' . $idcontratocli . '_' . $fechaActual . '_' . uniqid() . '.' . $fileExtension;
            $dest_path = $uploadFileDir . $newFileName;

            if (move_uploaded_file($fileTmpPath, $dest_path)) {
                return $dest_path;
            } else {
                $_SESSION['mensaje_error'] = 'Hubo un error al mover el archivo PDF.';
                return false;
            }
        } else {
            $_SESSION['mensaje_error'] = 'El archivo debe ser un PDF.';
            return false;
        }
    }
    return null; // No se subió archivo nuevo
}

$accion = $_POST['accion'] ?? null;
$idcontratocli = isset($_POST['idcontratocli']) ? filter_var($_POST['idcontratocli'], FILTER_VALIDATE_INT) : null;
$editor_id = $_SESSION['idemp'] ?? 0;

if (!$editor_id) {
    $_SESSION['mensaje_error'] = "Error de sesión. No se pudo identificar al editor.";
    header('Location: contratos_clientes.php');
    exit;
}

if ($accion === 'crear' && $idcontratocli) {
    $descripcion = trim($_POST['descripcion'] ?? '');
    $fechainicio = $_POST['fechainicio'] ?? null;
    $fechafin = $_POST['fechafin'] ?? null;
    $comentarios = trim($_POST['comentarios'] ?? '');

    $horasfijasmes = !empty($_POST['horasfijasmes']) ? filter_var($_POST['horasfijasmes'], FILTER_VALIDATE_INT) : null;
    $costohorafija = !empty($_POST['costohorafija']) ? filter_var($_POST['costohorafija'], FILTER_VALIDATE_FLOAT, ['flags' => FILTER_FLAG_ALLOW_FRACTION]) : null;
    $mesescontrato = !empty($_POST['mesescontrato']) ? filter_var($_POST['mesescontrato'], FILTER_VALIDATE_INT) : null;
    $totalhorasfijas = !empty($_POST['totalhorasfijas']) ? filter_var($_POST['totalhorasfijas'], FILTER_VALIDATE_INT) : null;
    $tipobolsa = !empty($_POST['tipobolsa']) ? trim($_POST['tipobolsa']) : null;
    $costohoraextra = !empty($_POST['costohoraextra']) ? filter_var($_POST['costohoraextra'], FILTER_VALIDATE_FLOAT, ['flags' => FILTER_FLAG_ALLOW_FRACTION]) : null;
    $montofijomes = !empty($_POST['montofijomes']) ? filter_var($_POST['montofijomes'], FILTER_VALIDATE_FLOAT, ['flags' => FILTER_FLAG_ALLOW_FRACTION]) : null;
    $planmontomes = !empty($_POST['planmontomes']) ? filter_var($_POST['planmontomes'], FILTER_VALIDATE_FLOAT, ['flags' => FILTER_FLAG_ALLOW_FRACTION]) : null;
    $planhorasextrasmes = !empty($_POST['planhorasextrasmes']) ? filter_var($_POST['planhorasextrasmes'], FILTER_VALIDATE_INT) : null;
    
    if (empty($descripcion) || empty($fechainicio) || empty($fechafin)) {
        $_SESSION['mensaje_error'] = "Los campos descripción, fecha de inicio y fecha de fin son obligatorios.";
        header('Location: registrar_adenda.php?idcontrato=' . $idcontratocli);
        exit;
    }

    $ruta_pdf_adenda = manejarSubidaPdf($idcontratocli, $pdo);
    if ($ruta_pdf_adenda === false) { // Error en la subida
        header('Location: registrar_adenda.php?idcontrato=' . $idcontratocli);
        exit;
    }
    if ($ruta_pdf_adenda === null) { // Archivo obligatorio no subido
        $_SESSION['mensaje_error'] = 'El archivo PDF es obligatorio para crear una adenda.';
        header('Location: registrar_adenda.php?idcontrato=' . $idcontratocli);
        exit;
    }

    try {
        // Calcular el nuevo numeroadenda
        $stmt_num = $pdo->prepare("SELECT MAX(numeroadenda) FROM adendacliente WHERE idcontratocli = ?");
        $stmt_num->execute([$idcontratocli]);
        $max_num = $stmt_num->fetchColumn();
        $nuevo_numeroadenda = ($max_num === null) ? 1 : $max_num + 1;

        $sql = "INSERT INTO adendacliente (numeroadenda, descripcion, fechainicio, fechafin, horasfijasmes, costohorafija, mesescontrato, totalhorasfijas, tipobolsa, costohoraextra, montofijomes, planmontomes, planhorasextrasmes, comentarios, idcontratocli, rutaarchivo, editor) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            $nuevo_numeroadenda, $descripcion, $fechainicio, $fechafin, $horasfijasmes, $costohorafija, $mesescontrato, $totalhorasfijas, $tipobolsa, $costohoraextra, $montofijomes, $planmontomes, $planhorasextrasmes, $comentarios, $idcontratocli, $ruta_pdf_adenda, $editor_id
        ]);
        $_SESSION['mensaje_exito'] = "Adenda registrada correctamente.";
    } catch (PDOException $e) {
        $_SESSION['mensaje_error'] = "Error al registrar la adenda en la base de datos: " . $e->getMessage();
    }
} elseif ($accion === 'editar' && $idcontratocli) {
    $idadendacli = isset($_POST['idadendacli']) ? filter_var($_POST['idadendacli'], FILTER_VALIDATE_INT) : null;
    if (!$idadendacli) {
        $_SESSION['mensaje_error'] = "ID de adenda no válido.";
        header('Location: contratos_clientes.php');
        exit;
    }

    $descripcion = trim($_POST['descripcion'] ?? '');
    $fechainicio = $_POST['fechainicio'] ?? null;
    $fechafin = $_POST['fechafin'] ?? null;
    $comentarios = trim($_POST['comentarios'] ?? '');

    $horasfijasmes = !empty($_POST['horasfijasmes']) ? filter_var($_POST['horasfijasmes'], FILTER_VALIDATE_INT) : null;
    $costohorafija = !empty($_POST['costohorafija']) ? filter_var($_POST['costohorafija'], FILTER_VALIDATE_FLOAT, ['flags' => FILTER_FLAG_ALLOW_FRACTION]) : null;
    $mesescontrato = !empty($_POST['mesescontrato']) ? filter_var($_POST['mesescontrato'], FILTER_VALIDATE_INT) : null;
    $totalhorasfijas = !empty($_POST['totalhorasfijas']) ? filter_var($_POST['totalhorasfijas'], FILTER_VALIDATE_INT) : null;
    $tipobolsa = !empty($_POST['tipobolsa']) ? trim($_POST['tipobolsa']) : null;
    $costohoraextra = !empty($_POST['costohoraextra']) ? filter_var($_POST['costohoraextra'], FILTER_VALIDATE_FLOAT, ['flags' => FILTER_FLAG_ALLOW_FRACTION]) : null;
    $montofijomes = !empty($_POST['montofijomes']) ? filter_var($_POST['montofijomes'], FILTER_VALIDATE_FLOAT, ['flags' => FILTER_FLAG_ALLOW_FRACTION]) : null;
    $planmontomes = !empty($_POST['planmontomes']) ? filter_var($_POST['planmontomes'], FILTER_VALIDATE_FLOAT, ['flags' => FILTER_FLAG_ALLOW_FRACTION]) : null;
    $planhorasextrasmes = !empty($_POST['planhorasextrasmes']) ? filter_var($_POST['planhorasextrasmes'], FILTER_VALIDATE_INT) : null;

    if (empty($descripcion) || empty($fechainicio) || empty($fechafin)) {
        $_SESSION['mensaje_error'] = "Los campos descripción, fecha de inicio y fecha de fin son obligatorios.";
        header('Location: editar_adenda.php?id=' . $idadendacli);
        exit;
    }

    $ruta_pdf_adenda_nueva = manejarSubidaPdf($idcontratocli, $pdo);
    if ($ruta_pdf_adenda_nueva === false) { // Error en la subida
        header('Location: editar_adenda.php?id=' . $idadendacli);
        exit;
    }

    $old_ruta_pdf = null;
    if ($ruta_pdf_adenda_nueva) {
        $stmt_old_path = $pdo->prepare("SELECT rutaarchivo FROM adendacliente WHERE idadendacli = ?");
        $stmt_old_path->execute([$idadendacli]);
        $old_ruta_pdf = $stmt_old_path->fetchColumn();
    }
    
    try {
        $sql_parts = [];
        $params = [];
        $fields = [
            'descripcion' => $descripcion,
            'fechainicio' => $fechainicio,
            'fechafin' => $fechafin,
            'horasfijasmes' => $horasfijasmes,
            'costohorafija' => $costohorafija,
            'mesescontrato' => $mesescontrato,
            'totalhorasfijas' => $totalhorasfijas,
            'tipobolsa' => $tipobolsa,
            'costohoraextra' => $costohoraextra,
            'montofijomes' => $montofijomes,
            'planmontomes' => $planmontomes,
            'planhorasextrasmes' => $planhorasextrasmes,
            'comentarios' => $comentarios,
            'editor' => $editor_id
        ];

        foreach ($fields as $key => $value) {
            $sql_parts[] = "$key = ?";
            $params[] = $value;
        }

        if ($ruta_pdf_adenda_nueva) {
            $sql_parts[] = "rutaarchivo = ?";
            $params[] = $ruta_pdf_adenda_nueva;
        }

        $sql = "UPDATE adendacliente SET " . implode(', ', $sql_parts) . " WHERE idadendacli = ?";
        $params[] = $idadendacli;

        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);

        if ($ruta_pdf_adenda_nueva && $old_ruta_pdf && file_exists($old_ruta_pdf)) {
            unlink($old_ruta_pdf);
        }

        $_SESSION['mensaje_exito'] = "Adenda actualizada correctamente.";
    } catch (PDOException $e) {
        $_SESSION['mensaje_error'] = "Error al actualizar la adenda: " . $e->getMessage();
    }
} else {
    $_SESSION['mensaje_error'] = "Acción no válida o ID de contrato no proporcionado.";
}

header('Location: contratos_clientes.php');
exit;
