<?php
session_start();
require_once 'funciones.php';

// Solo los administradores pueden actualizar
if (!isset($_SESSION['tipo_usuario']) || $_SESSION['tipo_usuario'] != 1) {
    $_SESSION['mensaje'] = "Acceso denegado.";
    $_SESSION['mensaje_tipo'] = "error";
    header('Location: anuncios.php');
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (empty($_POST['idanuncio']) || empty($_POST['fechainicio']) || empty($_POST['fechafin']) || empty($_POST['comentario'])) {
        $_SESSION['mensaje'] = "Todos los campos son obligatorios.";
        $_SESSION['mensaje_tipo'] = "error";
        header('Location: editar_anuncio.php?id=' . $_POST['idanuncio']);
        exit;
    }

    $idAnuncio = $_POST['idanuncio'];
    $anuncioActual = obtenerAnuncioPorId($idAnuncio);
    $rutaArchivo = $anuncioActual['rutaarchivo'];

    // Si se sube una nueva imagen
    if (isset($_FILES['rutaarchivo']) && $_FILES['rutaarchivo']['error'] == 0) {
        $file = $_FILES['rutaarchivo'];
        $allowedMimeTypes = ['image/jpeg', 'image/png', 'image/gif'];
        $maxFileSize = 5 * 1024 * 1024; // 5 MB

        if (!in_array($file['type'], $allowedMimeTypes)) {
            $_SESSION['mensaje'] = "Tipo de archivo no permitido. Solo se aceptan imágenes JPG, PNG y GIF.";
            $_SESSION['mensaje_tipo'] = "error";
            header('Location: editar_anuncio.php?id=' . $idAnuncio);
            exit;
        }

        if ($file['size'] > $maxFileSize) {
            $_SESSION['mensaje'] = "El archivo es demasiado grande. El tamaño máximo permitido es 5 MB.";
            $_SESSION['mensaje_tipo'] = "error";
            header('Location: editar_anuncio.php?id=' . $idAnuncio);
            exit;
        }
        
        $uploadDir = 'img/anuncios/';
        $fileName = uniqid() . '-' . basename($file['name']);
        $uploadFile = $uploadDir . $fileName;

        if (move_uploaded_file($file['tmp_name'], $uploadFile)) {
            if ($anuncioActual['rutaarchivo'] && file_exists($anuncioActual['rutaarchivo'])) {
                unlink($anuncioActual['rutaarchivo']);
            }
            $rutaArchivo = $uploadFile;
        } else {
            $_SESSION['mensaje'] = "Error al subir la nueva imagen.";
            $_SESSION['mensaje_tipo'] = "error";
            header('Location: editar_anuncio.php?id=' . $idAnuncio);
            exit;
        }
    }

    $datos = [
        'idanuncio' => $idAnuncio,
        'fechainicio' => $_POST['fechainicio'],
        'fechafin' => $_POST['fechafin'],
        'rutaarchivo' => $rutaArchivo,
        'comentario' => $_POST['comentario'],
        'editor' => $_SESSION['idemp']
    ];

    try {
        actualizarAnuncio($datos);
        $_SESSION['mensaje'] = "Anuncio actualizado correctamente.";
        $_SESSION['mensaje_tipo'] = "success";
        header('Location: anuncios.php');
        exit;
    } catch (Exception $e) {
        $_SESSION['mensaje'] = "Error al actualizar el anuncio: " . $e->getMessage();
        $_SESSION['mensaje_tipo'] = "error";
        header('Location: editar_anuncio.php?id=' . $idAnuncio);
        exit;
    }
} else {
    header('Location: anuncios.php');
    exit;
}
?>
