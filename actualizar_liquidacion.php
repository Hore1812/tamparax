<?php
session_start(); // Asegurar que la sesión esté iniciada para acceder a $_SESSION['idemp']
require_once 'funciones.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['idliquidacion'])) {
    try {
        if (!isset($_SESSION['idemp'])) {
            throw new Exception("ID de usuario no encontrado en la sesión. Por favor, inicie sesión de nuevo.");
        }
        $idLiquidacionFromPost = $_POST['idliquidacion'];

        $datos = [
            'fecha' => $_POST['fecha'],
            'asunto' => $_POST['asunto'],
            'tema' => $_POST['tema'],
            'motivo' => $_POST['motivo'],
            'tipohora' => $_POST['tipohora'],
            'acargode' => $_POST['acargode'],
            'lider' => $_POST['lider'],
            'cantidahoras' => $_POST['cantidahoras'],
            'estado' => $_POST['estado'],
            'idcontratocli' => $_POST['cliente'],
            'editor' => $_SESSION['idemp'],
            'enlace_onedrive' => null,
            'fecha_completo' => null,
            'colaboradores' => []
        ];
        
        if ($datos['estado'] == 'Completo') {
            $datos['enlace_onedrive'] = !empty($_POST['enlace_onedrive']) ? $_POST['enlace_onedrive'] : null;
            $datos['fecha_completo'] = !empty($_POST['fecha_completo']) ? $_POST['fecha_completo'] : null;

            if (isset($_POST['colaboradores'])) {
                $totalPorcentaje = 0;
            
                foreach ($_POST['colaboradores'] as $colab) {
                    if (!empty($colab['id']) && !empty($colab['porcentaje'])) {
                        $datos['colaboradores'][] = [
                            'id' => $colab['id'],
                            'porcentaje' => $colab['porcentaje'],
                            'comentario' => $colab['comentario'] ?? ''
                        ];
                        $totalPorcentaje += (int)$colab['porcentaje'];
                    }
                }
                
                if (!empty($datos['colaboradores']) && $totalPorcentaje != 100) {
                    throw new Exception("La suma total de porcentajes de los colaboradores debe ser exactamente 100%. Actual: $totalPorcentaje%");
                }
            }
        }
        
        $actualizado = actualizarLiquidacion($idLiquidacionFromPost, $datos);
        
        if ($actualizado) {
            $_SESSION['mensaje_exito'] = "Liquidación ID: $idLiquidacionFromPost actualizada correctamente.";
        } else {
            throw new Exception("No se pudo actualizar la liquidación ID: $idLiquidacionFromPost. Es posible que no hubiera cambios que guardar o ocurrió un error.");
        }
        
        header('Location: liquidaciones.php');
        exit;

    } catch (Exception $e) {
        $_SESSION['mensaje_error'] = "Error al actualizar la liquidación ID: " . ($idLiquidacionFromPost ?? '') . ". " . $e->getMessage();
        header('Location: editar_liquidacion.php?id=' . ($idLiquidacionFromPost ?? ''));
        exit;
    }
} else {
    $_SESSION['mensaje_error'] = "Acceso no válido para actualizar liquidación.";
    header('Location: liquidaciones.php');
    exit;
}
?>
