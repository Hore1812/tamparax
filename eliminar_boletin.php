<?php
session_start();
require_once 'funciones.php';

// Validar que el usuario sea administrador
if (!isset($_SESSION['tipo_usuario']) || $_SESSION['tipo_usuario'] != 1) {
    $_SESSION['mensaje_error'] = 'Acceso denegado.';
    header('Location: boletin_regulatorio.php');
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['id'])) {
    $id_boletin = filter_input(INPUT_POST, 'id', FILTER_VALIDATE_INT);

    if ($id_boletin) {
        // Obtener la información del boletín para saber qué archivo eliminar
        $boletin = obtenerBoletinRegulatorioPorId($id_boletin);

        if ($boletin) {
            // Intentar eliminar el registro de la base de datos
            if (eliminarBoletinRegulatorio($id_boletin)) {
                // Si se elimina de la BD, intentar eliminar el archivo físico
                $ruta_archivo = 'PDF/boletines/' . $boletin['archivo'];
                if (file_exists($ruta_archivo)) {
                    unlink($ruta_archivo);
                }
                $_SESSION['mensaje_exito'] = 'Boletín eliminado correctamente.';
            } else {
                $_SESSION['mensaje_error'] = 'Error al eliminar el boletín de la base de datos.';
            }
        } else {
            $_SESSION['mensaje_error'] = 'No se encontró el boletín a eliminar.';
        }
    } else {
        $_SESSION['mensaje_error'] = 'ID de boletín no válido.';
    }
} else {
    $_SESSION['mensaje_error'] = 'Solicitud no válida.';
}

header('Location: boletin_regulatorio.php');
exit;
?>
