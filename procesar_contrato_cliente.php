<?php
session_start();
require_once 'conexion.php';
require_once 'funciones.php'; 
require_once 'auth_check.php'; 

$accion = $_POST['accion'] ?? $_GET['accion'] ?? null;
$idcontratocli = isset($_POST['idcontratocli']) ? filter_var($_POST['idcontratocli'], FILTER_VALIDATE_INT) : (isset($_GET['idcontratocli']) ? filter_var($_GET['idcontratocli'], FILTER_VALIDATE_INT) : null);
$editor_id = $_SESSION['idemp'] ?? 0; 

if (!$editor_id) {
    $_SESSION['mensaje_error'] = "Error de sesión. No se pudo identificar al editor.";
    header('Location: contratos_clientes.php');
    exit;
}

// Recoger todos los datos del formulario
$idcliente = filter_var($_POST['idcliente'] ?? null, FILTER_VALIDATE_INT);
$lider = filter_var($_POST['lider'] ?? null, FILTER_VALIDATE_INT);
$descripcion = trim($_POST['descripcion'] ?? '');
$fechainicio = $_POST['fechainicio'] ?? null;
$fechafin = !empty($_POST['fechafin']) ? $_POST['fechafin'] : null; // Permitir nulo

$horasfijasmes = filter_var($_POST['horasfijasmes'] ?? 0, FILTER_VALIDATE_INT, ['options' => ['min_range' => 0]]);
$costohorafija = filter_var($_POST['costohorafija'] ?? 0, FILTER_VALIDATE_FLOAT, ['flags' => FILTER_FLAG_ALLOW_FRACTION]);
$mesescontrato = filter_var($_POST['mesescontrato'] ?? 0, FILTER_VALIDATE_INT, ['options' => ['min_range' => 0]]);

$tipobolsa = trim($_POST['tipobolsa'] ?? '');
$costohoraextra = filter_var($_POST['costohoraextra'] ?? 0, FILTER_VALIDATE_FLOAT, ['flags' => FILTER_FLAG_ALLOW_FRACTION]);

$planmontomes = filter_var($_POST['planmontomes'] ?? 0, FILTER_VALIDATE_FLOAT, ['flags' => FILTER_FLAG_ALLOW_FRACTION]);
$planhoraextrames = filter_var($_POST['planhoraextrames'] ?? 0, FILTER_VALIDATE_INT, ['options' => ['min_range' => 0]]);
$status = trim($_POST['status'] ?? '');
$tipohora = trim($_POST['tipohora'] ?? ''); // 'Soporte' o 'No Soporte'
$activo = isset($_POST['activo']) ? 1 : 0;

// Cálculos en backend para asegurar integridad
$totalhorasfijas = ($horasfijasmes !== false && $mesescontrato !== false) ? $horasfijasmes * $mesescontrato : 0;
$montofijomes = ($horasfijasmes !== false && $costohorafija !== false) ? $horasfijasmes * $costohorafija : 0;

// Manejo del archivo PDF
$ruta_pdf_contrato = null;
if (isset($_FILES['pdf_contrato']) && $_FILES['pdf_contrato']['error'] == UPLOAD_ERR_OK) {
    $fileTmpPath = $_FILES['pdf_contrato']['tmp_name'];
    $fileName = $_FILES['pdf_contrato']['name'];
    $fileSize = $_FILES['pdf_contrato']['size'];
    $fileType = $_FILES['pdf_contrato']['type'];
    $fileNameCmps = explode(".", $fileName);
    $fileExtension = strtolower(end($fileNameCmps));

    $allowedfileExtensions = ['pdf'];
    if (in_array($fileExtension, $allowedfileExtensions)) {
        $cliente = obtenerClientePorId($idcliente);
        $clienteNombre = $cliente ? $cliente['nombrecomercial'] : 'desconocido';
        $fechaActual = date('Ymd');
        
        $uploadFileDir = 'PDF/contratos/';
        $newFileName = 'contrato_' . preg_replace('/[^a-zA-Z0-9_-]/', '_', $clienteNombre) . '_' . $fechaActual . '.' . $fileExtension;
        $dest_path = $uploadFileDir . $newFileName;

        if ($accion === 'actualizar' && $idcontratocli) {
            $contrato_actual = obtenerContratoClientePorId($idcontratocli);
            if ($contrato_actual && !empty($contrato_actual['ruta_pdf_contrato']) && file_exists($contrato_actual['ruta_pdf_contrato'])) {
                unlink($contrato_actual['ruta_pdf_contrato']);
            }
        }

        if(move_uploaded_file($fileTmpPath, $dest_path)) {
            $ruta_pdf_contrato = $dest_path;
        } else {
            $_SESSION['mensaje_error'] = 'Hubo un error moviendo el archivo al directorio de destino.';
            header('Location: ' . ($accion === 'crear' ? 'registrar_contrato_cliente.php' : 'editar_contrato_cliente.php?id=' . $idcontratocli));
            exit;
        }
    } else {
        $_SESSION['mensaje_error'] = 'El archivo debe ser un PDF.';
        header('Location: ' . ($accion === 'crear' ? 'registrar_contrato_cliente.php' : 'editar_contrato_cliente.php?id=' . $idcontratocli));
        exit;
    }
}

try {
    if ($accion === 'crear') {
        if ($idcliente === false || $lider === false || empty($descripcion) || empty($fechainicio) || 
            $horasfijasmes === false || $costohorafija === false || $mesescontrato === false || 
            $costohoraextra === false || $planmontomes === false || $planhoraextrames === false || 
            empty($status) || empty($tipohora)) {
            $_SESSION['mensaje_error'] = "Todos los campos marcados con * son requeridos y deben tener valores válidos.";
            header('Location: registrar_contrato_cliente.php');
            exit;
        }
        
        $datos_contrato = compact(
            'idcliente', 'lider', 'descripcion', 'fechainicio', 'fechafin', 
            'horasfijasmes', 'costohorafija', 'mesescontrato', 'totalhorasfijas', 
            'tipobolsa', 'costohoraextra', 'montofijomes', 'planmontomes', 
            'planhoraextrames', 'status', 'tipohora', 'activo'
        );
        $datos_contrato['editor'] = $editor_id;
        if ($ruta_pdf_contrato) {
            $datos_contrato['ruta_pdf_contrato'] = $ruta_pdf_contrato;
        }

        if (registrarContratoCliente($datos_contrato)) {
            $_SESSION['mensaje_exito'] = "Contrato de cliente registrado correctamente.";
        } else {
            $_SESSION['mensaje_error'] = "Error al registrar el contrato." . ($_SESSION['mensaje_error_detalle'] ?? '');
            unset($_SESSION['mensaje_error_detalle']);
            header('Location: registrar_contrato_cliente.php');
            exit;
        }

    } elseif ($accion === 'actualizar' && $idcontratocli) {
         if ($idcliente === false || $lider === false || empty($descripcion) || empty($fechainicio) || 
            $horasfijasmes === false || $costohorafija === false || $mesescontrato === false || 
            $costohoraextra === false || $planmontomes === false || $planhoraextrames === false || 
            empty($status) || empty($tipohora)) {
            $_SESSION['mensaje_error'] = "Todos los campos marcados con * son requeridos y deben tener valores válidos.";
            header('Location: editar_contrato_cliente.php?id=' . $idcontratocli);
            exit;
        }
        
        $datos_contrato = compact(
            'idcliente', 'lider', 'descripcion', 'fechainicio', 'fechafin', 
            'horasfijasmes', 'costohorafija', 'mesescontrato', 'totalhorasfijas', 
            'tipobolsa', 'costohoraextra', 'montofijomes', 'planmontomes', 
            'planhoraextrames', 'status', 'tipohora', 'activo'
        );
        $datos_contrato['editor'] = $editor_id;
        if ($ruta_pdf_contrato) {
            $datos_contrato['ruta_pdf_contrato'] = $ruta_pdf_contrato;
        }

        if (actualizarContratoCliente($idcontratocli, $datos_contrato)) {
            $_SESSION['mensaje_exito'] = "Contrato de cliente actualizado correctamente.";
        } else {
            $_SESSION['mensaje_error'] = "Error al actualizar el contrato o no se realizaron cambios." . ($_SESSION['mensaje_error_detalle'] ?? '');
            unset($_SESSION['mensaje_error_detalle']);
            header('Location: editar_contrato_cliente.php?id=' . $idcontratocli);
            exit;
        }
    } elseif (($accion === 'desactivar' || $accion === 'activar') && $idcontratocli) {
        $nuevo_estado = ($accion === 'activar') ? 1 : 0;
        if (actualizarEstadoContratoCliente($idcontratocli, $nuevo_estado, $editor_id)) {
            $_SESSION['mensaje_exito'] = "Estado del contrato actualizado correctamente.";
        } else {
            $_SESSION['mensaje_error'] = "Error al actualizar el estado del contrato." . ($_SESSION['mensaje_error_detalle'] ?? '');
            unset($_SESSION['mensaje_error_detalle']);
        }
    } else {
        $_SESSION['mensaje_error'] = "Acción no válida o ID de contrato no proporcionado.";
    }

} catch (PDOException $e) {
    error_log("Error de BD en procesar_contrato_cliente.php: " . $e->getMessage());
    $_SESSION['mensaje_error'] = "Error de base de datos. Por favor, contacte al administrador.";
} catch (Exception $e) {
    error_log("Error general en procesar_contrato_cliente.php: " . $e->getMessage());
    $_SESSION['mensaje_error'] = "Ocurrió un error inesperado. Por favor, contacte al administrador.";
}

header('Location: contratos_clientes.php');
exit;
?>
