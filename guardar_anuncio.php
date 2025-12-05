<?php
session_start();
require_once 'funciones.php';

// Solo los administradores pueden guardar
if (!isset($_SESSION['tipo_usuario']) || $_SESSION['tipo_usuario'] != 1) {
    $_SESSION['mensaje'] = "Acceso denegado.";
    $_SESSION['mensaje_tipo'] = "error";
    header('Location: anuncios.php');
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Validaciones básicas
    if (empty($_POST['fechainicio']) || empty($_POST['fechafin']) || empty($_POST['comentario']) || empty($_FILES['rutaarchivo']['name'])) {
        $_SESSION['mensaje'] = "Todos los campos son obligatorios.";
        $_SESSION['mensaje_tipo'] = "error";
        header('Location: registrar_anuncio.php');
        exit;
    }

    // Validación de seguridad del archivo
    $file = $_FILES['rutaarchivo'];
    $allowedMimeTypes = ['image/jpeg', 'image/png', 'image/gif'];
    $maxFileSize = 5 * 1024 * 1024; // 5 MB

    if (!in_array($file['type'], $allowedMimeTypes)) {
        $_SESSION['mensaje'] = "Tipo de archivo no permitido. Solo se aceptan imágenes JPG, PNG y GIF.";
        $_SESSION['mensaje_tipo'] = "error";
        header('Location: registrar_anuncio.php');
        exit;
    }

    if ($file['size'] > $maxFileSize) {
        $_SESSION['mensaje'] = "El archivo es demasiado grande. El tamaño máximo permitido es 5 MB.";
        $_SESSION['mensaje_tipo'] = "error";
        header('Location: registrar_anuncio.php');
        exit;
    }

    $uploadDir = 'img/anuncios/';
    $fileName = uniqid() . '-' . basename($file['name']);
    $uploadFile = $uploadDir . $fileName;

    if (!is_dir($uploadDir)) {
        mkdir($uploadDir, 0755, true);
    }

    if (move_uploaded_file($file['tmp_name'], $uploadFile)) {
        $datos = [
            'fechainicio' => $_POST['fechainicio'],
            'fechafin' => $_POST['fechafin'],
            'rutaarchivo' => $uploadFile,
            'comentario' => $_POST['comentario'],
            'editor' => $_SESSION['idemp']
        ];

        try {
            registrarAnuncio($datos);
            $_SESSION['mensaje'] = "Anuncio registrado correctamente.";
            $_SESSION['mensaje_tipo'] = "success";
            header('Location: anuncios.php');
            exit;
        } catch (Exception $e) {
            unlink($uploadFile);
            $_SESSION['mensaje'] = "Error al registrar el anuncio: " . $e->getMessage();
            $_SESSION['mensaje_tipo'] = "error";
            header('Location: registrar_anuncio.php');
            exit;
        }
    } else {
        $_SESSION['mensaje'] = "Error al subir la imagen.";
        $_SESSION['mensaje_tipo'] = "error";
        header('Location: registrar_anuncio.php');
        exit;
    }
} else {
    header('Location: registrar_anuncio.php');
    exit;
}
?>
