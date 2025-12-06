<?php
// cron/actualizar_contratos.php

// Establecer la zona horaria para asegurar que CURDATE() funcione como se espera
date_default_timezone_set('America/Lima');

// Incluir el archivo de conexión a la base de datos.
// La ruta es relativa a este script.
require_once dirname(__DIR__) . '/conexion.php';

function actualizar_estado_contratos() {
    global $pdo;

    // Consulta para actualizar los contratos de tipo 'Soporte' a 'Finalizado'
    // si su fecha de finalización ya ha pasado y aún están 'Vigente'.
    $sql = "UPDATE contratocliente
            SET status = 'Finalizado',
                modificado = CURRENT_TIMESTAMP
            WHERE tipohora = 'Soporte'
              AND status = 'Vigente'
              AND fechafin IS NOT NULL
              AND fechafin < CURDATE();";

    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute();

        $filas_afectadas = $stmt->rowCount();

        // Registrar la ejecución en un log (o simplemente imprimir si se ejecuta desde la consola)
        $mensaje = sprintf(
            "[%s] Cron Job ejecutado. Se actualizaron %d contratos a 'Finalizado'.\n",
            date('Y-m-d H:i:s'),
            $filas_afectadas
        );
        echo $mensaje;

        // Opcionalmente, guardar en un archivo de log
        // file_put_contents(dirname(__DIR__) . '/cron/cron.log', $mensaje, FILE_APPEND);

    } catch (PDOException $e) {
        $mensaje_error = sprintf(
            "[%s] ERROR en Cron Job: No se pudo actualizar los contratos. Error: %s\n",
            date('Y-m-d H:i:s'),
            $e->getMessage()
        );
        error_log($mensaje_error); // Usa el sistema de logs de PHP/servidor
        echo $mensaje_error;

        // Opcionalmente, guardar en un archivo de log de errores
        // file_put_contents(dirname(__DIR__) . '/cron/cron_error.log', $mensaje_error, FILE_APPEND);
    }
}

// Ejecutar la función
actualizar_estado_contratos();

?>
