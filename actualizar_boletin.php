<?php
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}
require_once 'funciones.php';

// --- Toda la lógica de procesamiento de POST va aquí ---
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    // Si no es POST, simplemente redirigir
    header('Location: boletin_regulatorio.php');
    exit;
}

if (!isset($_SESSION['tipo_usuario']) || $_SESSION['tipo_usuario'] != 1) {
    $_SESSION['mensaje_error'] = 'Acceso denegado.';
    header('Location: boletin_regulatorio.php');
    exit;
}

$id_boletin = filter_input(INPUT_POST, 'id', FILTER_VALIDATE_INT);
if (!$id_boletin) {
    $_SESSION['mensaje_error'] = 'ID de boletín no válido.';
    header('Location: boletin_regulatorio.php');
    exit;
}

$boletin_actual = obtenerBoletinRegulatorioPorId($id_boletin);
if (!$boletin_actual) {
    $_SESSION['mensaje_error'] = 'Boletín no encontrado.';
    header('Location: boletin_regulatorio.php');
    exit;
}

$meses = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"];
$errores = [];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $anio = filter_input(INPUT_POST, 'anio', FILTER_VALIDATE_INT);
    $mes = $_POST['mes'] ?? '';
    $asunto = trim($_POST['asunto'] ?? '');
    $fecha_publicacion = $_POST['fecha_publicacion'] ?? '';
    $archivo_actual = $_POST['archivo_actual'] ?? '';
    $archivo_nuevo = $_FILES['archivo'] ?? null;
    $editor = $_SESSION['idemp'];

    if (!$anio || $anio < 2000 || $anio > date("Y") + 5) $errores[] = "El año no es válido.";
    if (empty($mes) || !in_array($mes, $meses)) $errores[] = "El mes no es válido.";
    if (empty($asunto)) $errores[] = "El asunto es obligatorio.";
    if (empty($fecha_publicacion)) $errores[] = "La fecha de publicación es obligatoria.";

    $nombre_archivo = $archivo_actual;
    $ruta_archivo = null;

    if (isset($archivo_nuevo) && $archivo_nuevo['error'] === UPLOAD_ERR_OK) {
        $tipo_archivo = mime_content_type($archivo_nuevo['tmp_name']);
        $extension_archivo = strtolower(pathinfo($archivo_nuevo['name'], PATHINFO_EXTENSION));
        $tamano_archivo = $archivo_nuevo['size'];

        if ($tipo_archivo != 'application/pdf' || $extension_archivo != 'pdf') {
            $errores[] = "El nuevo archivo debe ser un PDF.";
        }
        
        if ($tamano_archivo > 5 * 1024 * 1024) { // 5 MB
            $errores[] = "El archivo no debe exceder los 5 MB.";
        }

        if (empty($errores)) {
            $directorio_destino = 'PDF/boletines/';
            if (!file_exists($directorio_destino)) {
                mkdir($directorio_destino, 0755, true);
            }
            $nombre_base = 'boletin_' . strtolower(str_replace(' ', '_', $mes)) . '_' . $anio;
            $nombre_archivo = preg_replace("/[^a-zA-Z0-9_.-]/", "", $nombre_base) . '.pdf';
            $ruta_archivo = $directorio_destino . $nombre_archivo;
        }
    }

    if (empty($errores)) {
        $datos = [
            'anio' => $anio,
            'mes' => $mes,
            'asunto' => $asunto,
            'archivo' => $nombre_archivo,
            'fecha_publicacion' => $fecha_publicacion,
            'editor' => $editor
        ];

        if ($ruta_archivo && !move_uploaded_file($archivo_nuevo['tmp_name'], $ruta_archivo)) {
            $_SESSION['mensaje_error'] = "Error al subir el nuevo archivo.";
            header('Location: editar_boletin.php?id=' . $id_boletin);
            exit;
        }

        if (actualizarBoletinRegulatorio($id_boletin, $datos)) {
            if ($ruta_archivo && $archivo_actual != $nombre_archivo && file_exists('PDF/boletines/' . $archivo_actual)) {
                unlink('PDF/boletines/' . $archivo_actual);
            }
            $_SESSION['mensaje_exito'] = 'Boletín actualizado correctamente.';
            header('Location: boletin_regulatorio.php');
            exit;
        } else {
            $_SESSION['mensaje_error'] = 'Error al actualizar el registro en la base de datos. Verifique si ya existe un registro para ese año y mes.';
            header('Location: editar_boletin.php?id=' . $id_boletin);
            exit;
        }
    } else {
        $_SESSION['mensaje_error'] = implode('<br>', $errores);
        header('Location: editar_boletin.php?id=' . $id_boletin);
        exit;
    }
} else {
    // Si no es POST, redirigir
    header('Location: boletin_regulatorio.php');
    exit;
}
?>