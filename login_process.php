<!-- login_process.php -->
<?php
session_start(); // Iniciar la sesión al principio de todo

require 'conexion.php'; // Conexión a la BD

$mensajeError = '';

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    if (empty($_POST['username']) || empty($_POST['password'])) {
        $mensajeError = "Por favor, ingresa tu nombre de usuario y contraseña.";
    } else {
        $username = $_POST['username'];
        $password = $_POST['password'];

        try {
            // Buscar al usuario y obtener el nombre del empleado asociado
            $stmt = $pdo->prepare("
                SELECT u.idusuario, u.nombre, u.password, u.activo, u.idemp, u.tipo, e.nombrecorto 
                FROM usuario u 
                LEFT JOIN empleado e ON u.idemp = e.idempleado 
                WHERE u.nombre = :username
            ");
            $stmt->bindParam(':username', $username);
            $stmt->execute();
            $user = $stmt->fetch(PDO::FETCH_ASSOC);

            if ($user) {
                if ($user['activo'] != 1) {
                    $mensajeError = "Tu cuenta no está activa. Contacta al administrador.";
                } else if (password_verify($password, $user['password'])) {
                    // Contraseña correcta y usuario activo
                    $_SESSION['idusuario'] = $user['idusuario'];
                    $_SESSION['nombre_usuario'] = $user['nombre'];
                    $_SESSION['idemp'] = $user['idemp'];
                    $_SESSION['tipo_usuario'] = $user['tipo'];
                    // Guardar el nombre del empleado en la sesión
                    $_SESSION['nombre_empleado'] = $user['nombrecorto'];
                    
                    $session_php_id = session_id();
                    $ip_address = $_SERVER['REMOTE_ADDR'];
                    
                    // Asumiendo que la tabla sesiones_log existe y tiene las columnas mencionadas
                    // Si la tabla no existe, esta parte causará un error.
                    try {
                        $stmt_log_insert = $pdo->prepare("
                            INSERT INTO sesiones_log 
                                (idusuario, session_php_id, ip_address_inicio, timestamp_inicio) 
                            VALUES 
                                (:idusuario, :session_php_id, :ip_address, NOW())
                        ");
                        $stmt_log_insert->bindParam(':idusuario', $user['idusuario']);
                        $stmt_log_insert->bindParam(':session_php_id', $session_php_id);
                        $stmt_log_insert->bindParam(':ip_address', $ip_address);
                        $stmt_log_insert->execute();
                        $_SESSION['id_sesion_log_db'] = $pdo->lastInsertId();
                    } catch (PDOException $e) {
                        // Loguear este error específico pero no detener el login
                        error_log("Error al insertar en sesiones_log: " . $e->getMessage());
                        // No se establece $_SESSION['id_sesion_log_db'] si falla
                    }

                    // MODIFICACIÓN: Redirigir a index.php en la raíz
                    header("Location: index.php"); 
                    exit;
                } else {
                    $mensajeError = "Nombre de usuario o contraseña incorrectos.";
                }
            } else {
                $mensajeError = "Nombre de usuario o contraseña incorrectos.";
            }
        } catch (PDOException $e) {
            error_log("Error en login_process.php: " . $e->getMessage());
            $mensajeError = "Ocurrió un error en el servidor. Inténtalo más tarde.";
        }
    }
}

if (!empty($mensajeError)) {
    $_SESSION['login_error'] = $mensajeError;
    header("Location: login.php"); 
    exit;
}
?>
