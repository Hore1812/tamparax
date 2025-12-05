<?php
session_start();
require_once 'funciones.php';

// Solo los administradores pueden eliminar
if (!isset($_SESSION['tipo_usuario']) || $_SESSION['tipo_usuario'] != 1) {
    $_SESSION['mensaje'] = "Acceso denegado.";
    $_SESSION['mensaje_tipo'] = "error";
    header('Location: anuncios.php');
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['id']) && is_numeric($_POST['id'])) {
    $idAnuncio = $_POST['id'];
    $anuncio = obtenerAnuncioPorId($idAnuncio);

    if ($anuncio) {
        try {
            // Eliminar el archivo de imagen
            if (file_exists($anuncio['rutaarchivo'])) {
                unlink($anuncio['rutaarchivo']);
            }

            eliminarAnuncio($idAnuncio);
            $_SESSION['mensaje'] = "Anuncio eliminado correctamente.";
            $_SESSION['mensaje_tipo'] = "success";
        } catch (Exception $e) {
            $_SESSION['mensaje'] = "Error al eliminar el anuncio: " . $e->getMessage();
            $_SESSION['mensaje_tipo'] = "error";
        }
    } else {
        $_SESSION['mensaje'] = "Anuncio no encontrado.";
        $_SESSION['mensaje_tipo'] = "error";
    }
} else {
    $_SESSION['mensaje'] = "Solicitud no válida.";
    $_SESSION['mensaje_tipo'] = "error";
}

header('Location: anuncios.php');
exit;
?>
