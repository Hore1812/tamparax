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
    // Validar que los campos requeridos no estén vacíos
    $required_fields = ['id', 'entidad', 'tipo_norma', 'numero_norma', 'fecha', 'detalle'];
    foreach ($required_fields as $field) {
        if (!isset($_POST[$field]) || empty(trim($_POST[$field]))) {
            $_SESSION['mensaje'] = 'Por favor, complete todos los campos obligatorios.';
            $_SESSION['mensaje_tipo'] = 'danger';
            // Redirigir de vuelta al formulario de edición si hay un error
            header('Location: editar_alerta.php?id=' . $_POST['id']);
            exit();
        }
    }

    $idAlerta = $_POST['id'];
    $datos = [
        'tematica' => trim($_POST['tematica']),
        'entidad' => trim($_POST['entidad']),
        'tipo_norma' => trim($_POST['tipo_norma']),
        'numero_norma' => trim($_POST['numero_norma']),
        'fecha' => $_POST['fecha'],
        'detalle' => trim($_POST['detalle']),
        'url' => !empty($_POST['url']) ? trim($_POST['url']) : null,
        'editor' => $_SESSION['idemp'] // ID del empleado que está actualizando
    ];

    $resultado = actualizarAlertaNormativa($idAlerta, $datos);

    if ($resultado) {
        $_SESSION['mensaje'] = 'Alerta normativa actualizada exitosamente.';
        $_SESSION['mensaje_tipo'] = 'success';
    } else {
        $_SESSION['mensaje'] = 'Error al actualizar la alerta normativa.';
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
