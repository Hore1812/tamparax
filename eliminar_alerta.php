<?php
require_once 'auth_check.php';
require_once 'funciones.php';

// Asegurarse de que el usuario sea administrador
if ($_SESSION['tipo_usuario'] != 1) {
    $_SESSION['mensaje'] = 'Acceso denegado.';
    $_SESSION['mensaje_tipo'] = 'danger';
    header('Location: index.php');
    exit();
}

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    // Validar que se reciba un ID
    if (!isset($_POST['id']) || !is_numeric($_POST['id'])) {
        $_SESSION['mensaje'] = 'ID de alerta no válido para eliminación.';
        $_SESSION['mensaje_tipo'] = 'danger';
        header('Location: alertas_normativas.php');
        exit();
    }

    $idAlerta = $_POST['id'];

    $resultado = eliminarAlertaNormativa($idAlerta);

    if ($resultado) {
        $_SESSION['mensaje'] = 'Alerta normativa eliminada exitosamente.';
        $_SESSION['mensaje_tipo'] = 'success';
    } else {
        $_SESSION['mensaje'] = 'Error al eliminar la alerta normativa.';
        // El mensaje de error detallado se guarda en la sesión desde la función
        $_SESSION['mensaje_tipo'] = 'danger';
    }

    header('Location: alertas_normativas.php');
    exit();

} else {
    // Si no es POST, redirigir
    header('Location: alertas_normativas.php');
    exit();
}
?>
