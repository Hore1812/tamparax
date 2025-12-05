<?php
require_once 'conexion.php';

// ----------------- FUNCIONES DE LIQUIDACIONES (Existentes) ----------------- 
function obtenerLiquidaciones($filtros = []) {
    global $pdo;
    
    $sql = "SELECT LIQ.idliquidacion AS 'ID', LIQ.fecha AS 'FECHA', CLI.nombrecomercial AS 'CLIENTE', 
            TEM.descripcion AS TEMA, LIQ.asunto AS ASUNTO, LIQ.motivo as MOTIVO,
            LID.nombrecorto AS 'LIDER', LIQ.lider AS 'ID_LIDER', CAR.nombrecorto AS 'ENCARGADO', LIQ.estado AS 'ESTADO', 
            LIQ.cantidahoras AS 'HORAS', LIQ.tipohora AS 'TIPOHORA', LIQ.enlace_onedrive 
            FROM liquidacion LIQ 
            INNER JOIN contratocliente CON ON LIQ.idcontratocli=CON.idcontratocli 
            INNER JOIN cliente CLI ON CLI.idcliente=CON.idcliente 
            INNER JOIN empleado LID ON LIQ.lider=LID.idempleado 
            INNER JOIN empleado CAR ON LIQ.acargode=CAR.idempleado 
            INNER JOIN tema TEM ON LIQ.tema=TEM.idtema 
            WHERE LIQ.activo=1";
    
    $params = [];
    if (!empty($filtros['anio'])) { $sql .= " AND YEAR(LIQ.fecha) = ?"; $params[] = $filtros['anio']; }
    if (!empty($filtros['mes'])) { $sql .= " AND MONTH(LIQ.fecha) = ?"; $params[] = $filtros['mes']; }
    if (!empty($filtros['cliente'])) { $sql .= " AND CLI.idcliente = ?"; $params[] = $filtros['cliente']; }
    if (!empty($filtros['lider'])) { $sql .= " AND LID.idempleado = ?"; $params[] = $filtros['lider']; }
    if (!empty($filtros['estado'])) { $sql .= " AND LIQ.estado = ?"; $params[] = $filtros['estado']; }
    $sql .= " ORDER BY LIQ.idliquidacion DESC";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

// Funciones para CRUD de Anuncios
function obtenerAnuncios() {
    global $pdo;
    $sql = "SELECT a.*, e.nombrecorto as editor_nombre FROM anuncio a JOIN empleado e ON a.editor = e.idempleado ORDER BY a.fechainicio DESC";
    $sentencia = $pdo->prepare($sql);
    $sentencia->execute();
    return $sentencia->fetchAll(PDO::FETCH_ASSOC);
}

function obtenerHorasCompletadasSoporteMesActual() {
    global $pdo;
    $sql = "
        SELECT COALESCE(SUM(dp.cantidahoras), 0) as total_horas
        FROM detalles_planificacion dp
        JOIN planificacion p ON dp.Idplanificacion = p.Idplanificacion
        JOIN contratocliente cc ON p.idContratoCliente = cc.idcontratocli
        WHERE dp.estado = 'Completo'
          AND cc.tipohora = 'Soporte'
          AND MONTH(dp.fechaliquidacion) = MONTH(CURRENT_DATE())
          AND YEAR(dp.fechaliquidacion) = YEAR(CURRENT_DATE())
    ";
    $sentencia = $pdo->prepare($sql);
    $sentencia->execute();
    $resultado = $sentencia->fetch(PDO::FETCH_ASSOC);
    return $resultado['total_horas'] ?? 0;
}

function obtenerHorasMetaEmpleado($id_empleado) {
    global $pdo;
    $sql = "SELECT horasmeta FROM empleado WHERE idempleado = :id_empleado";
    $sentencia = $pdo->prepare($sql);
    $sentencia->bindParam(':id_empleado', $id_empleado, PDO::PARAM_INT);
    $sentencia->execute();
    $resultado = $sentencia->fetch(PDO::FETCH_ASSOC);
    return $resultado['horasmeta'] ?? 0;
}

function obtenerHorasPlanificadasPorTipoUsuarioMesActual($id_empleado) {
    global $pdo;
    $sql = "
        SELECT
            cc.tipohora,
            SUM(dp2.horas_asignadas) AS HorasPlanificadasAsignadas
        FROM planificacion p
        JOIN contratocliente cc ON p.idContratoCliente = cc.idcontratocli
        JOIN detalles_planificacion dp ON p.Idplanificacion = dp.Idplanificacion
        JOIN distribucion_planificacion dp2 ON dp.iddetalle = dp2.iddetalle
        WHERE dp2.idparticipante = :id_empleado
          AND MONTH(p.fechaplan) = MONTH(CURRENT_DATE())
          AND YEAR(p.fechaplan) = YEAR(CURRENT_DATE())
        GROUP BY cc.tipohora
    ";
    $sentencia = $pdo->prepare($sql);
    $sentencia->bindParam(':id_empleado', $id_empleado, PDO::PARAM_INT);
    $sentencia->execute();
    return $sentencia->fetchAll(PDO::FETCH_ASSOC);
}

function obtenerHorasAsignadasUsuarioMesActual($id_empleado) {
    global $pdo;
    $sql = "
        SELECT COALESCE(SUM(dh.calculo), 0) AS horas_asignadas_mes
        FROM distribucionhora dh
        JOIN liquidacion l ON dh.idliquidacion = l.idliquidacion
        WHERE l.estado = 'Completo'
          AND dh.participante = :id_empleado
          AND MONTH(l.fecha) = MONTH(CURRENT_DATE())
          AND YEAR(l.fecha) = YEAR(CURRENT_DATE())
    ";
    $sentencia = $pdo->prepare($sql);
    $sentencia->bindParam(':id_empleado', $id_empleado, PDO::PARAM_INT);
    $sentencia->execute();
    $resultado = $sentencia->fetch(PDO::FETCH_ASSOC);
    return $resultado['horas_asignadas_mes'] ?? 0;
}

function obtenerTotalHorasAsignadasMesActual() {
    global $pdo;
    $sql = "
        SELECT COALESCE(SUM(dh.calculo), 0) AS total_horas
        FROM distribucionhora dh
        JOIN liquidacion l ON dh.idliquidacion = l.idliquidacion
        WHERE l.estado = 'Completo'
          AND MONTH(l.fecha) = MONTH(CURRENT_DATE())
          AND YEAR(l.fecha) = YEAR(CURRENT_DATE())
    ";
    $sentencia = $pdo->prepare($sql);
    $sentencia->execute();
    $resultado = $sentencia->fetch(PDO::FETCH_ASSOC);
    return $resultado['total_horas'] ?? 0;
}

function obtenerHorasPlanificadasSoporteMesActual() {
    global $pdo;
    $sql = "
        SELECT COALESCE(SUM(p.horasplan), 0) as total_horas
        FROM planificacion p
        JOIN contratocliente cc ON p.idContratoCliente = cc.idcontratocli
        WHERE cc.tipohora = 'Soporte'
          AND MONTH(p.fechaplan) = MONTH(CURRENT_DATE())
          AND YEAR(p.fechaplan) = YEAR(CURRENT_DATE())
    ";
    $sentencia = $pdo->prepare($sql);
    $sentencia->execute();
    $resultado = $sentencia->fetch(PDO::FETCH_ASSOC);
    return $resultado['total_horas'] ?? 0;
}

function obtenerAnuncioPorId($id) {
    global $pdo;
    $sql = "SELECT * FROM anuncio WHERE idanuncio = :id";
    $sentencia = $pdo->prepare($sql);
    $sentencia->bindParam(':id', $id, PDO::PARAM_INT);
    $sentencia->execute();
    return $sentencia->fetch(PDO::FETCH_ASSOC);
}

function registrarAnuncio($datos) {
    global $pdo;
    $sql = "INSERT INTO anuncio (fechainicio, fechafin, rutaarchivo, comentario, editor) VALUES (:fechainicio, :fechafin, :rutaarchivo, :comentario, :editor)";
    $sentencia = $pdo->prepare($sql);
    $sentencia->execute($datos);
    return $pdo->lastInsertId();
}

function actualizarAnuncio($datos) {
    global $pdo;
    $sql = "UPDATE anuncio SET fechainicio = :fechainicio, fechafin = :fechafin, rutaarchivo = :rutaarchivo, comentario = :comentario, editor = :editor, modificado = current_timestamp() WHERE idanuncio = :idanuncio";
    $sentencia = $pdo->prepare($sql);
    $sentencia->execute($datos);
    return $sentencia->rowCount();
}

function eliminarAnuncio($id) {
    global $pdo;
    $sql = "DELETE FROM anuncio WHERE idanuncio = :id";
    $sentencia = $pdo->prepare($sql);
    $sentencia->bindParam(':id', $id, PDO::PARAM_INT);
    $sentencia->execute();
    return $sentencia->rowCount();
}

function obtenerAnunciosActivos() {
    global $pdo;
    $sql = "SELECT * FROM anuncio WHERE CURDATE() BETWEEN fechainicio AND fechafin ORDER BY fechainicio DESC";
    $sentencia = $pdo->prepare($sql);
    $sentencia->execute();
    return $sentencia->fetchAll(PDO::FETCH_ASSOC);
}

function obtenerColaboradores() {
    global $pdo;
    $sql = "SELECT idempleado AS 'ID', nombrecorto AS 'COLABORADOR', rutafoto FROM empleado WHERE activo=1 ORDER BY 2";
    $stmt = $pdo->query($sql);
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

function obtenerClientes() {
    global $pdo;
    $sql = "SELECT idcliente, nombrecomercial FROM cliente ORDER BY nombrecomercial";
    $stmt = $pdo->query($sql);
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

function obtenerLideres() { 
    global $pdo;
    $sql = "SELECT idempleado, nombrecorto FROM empleado WHERE activo = 1 ORDER BY nombrecorto";
    $stmt = $pdo->query($sql);
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

function obtenerTiposHora() {
    global $pdo;
    $sql = "SELECT DISTINCT tipohora FROM contratocliente";
    $stmt = $pdo->query($sql);
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

function obtenerClientesPorTipoHora($tipoHora) {
    global $pdo;
    $sql = "SELECT CON.idcontratocli, CONCAT(CON.idcliente,' – ',CLI.nombrecomercial) AS CLIENTE 
            FROM contratocliente AS CON 
            INNER JOIN cliente AS CLI ON CON.idcliente = CLI.idcliente 
            WHERE CON.tipohora=?";
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$tipoHora]);
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

function obtenerLiderPorContrato($idContrato) {
    global $pdo;
    $sql = "SELECT CON.lider, EMP.nombrecorto 
            FROM contratocliente AS CON 
            INNER JOIN empleado EMP ON CON.lider = EMP.idempleado 
            WHERE CON.idcontratocli=?";
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$idContrato]);
    return $stmt->fetch(PDO::FETCH_ASSOC);
}

function obtenerTemas() { 
    global $pdo;
    $sql = "SELECT idtema, descripcion FROM tema"; 
    $stmt = $pdo->query($sql);
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}


function obtenerEncargadoPorTema($idTema) { 
    global $pdo;
    $sql = "SELECT EMP.idempleado, EMP.nombrecorto 
            FROM empleado EMP 
            INNER JOIN tema TEM ON EMP.idempleado = TEM.idencargado 
            WHERE TEM.idtema=?";
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$idTema]);
    return $stmt->fetch(PDO::FETCH_ASSOC);
}

function obtenerColaboradoresPorLiquidacion($idLiquidacion) {
    global $pdo;
    $sql = "SELECT DIS.participante AS 'ID', EMP.nombrecorto AS 'COLABORADOR', 
            DIS.porcentaje AS 'Porcentaje', DIS.calculo AS 'CALCULO', 
            DIS.comentario AS 'COMENTARIO' 
            FROM distribucionhora DIS 
            INNER JOIN empleado EMP ON EMP.idempleado=DIS.participante 
            INNER JOIN liquidacion LIQ ON DIS.idliquidacion=LIQ.idliquidacion 
            WHERE LIQ.idliquidacion=?";
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$idLiquidacion]);
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

function obtenerHistoricoColaborador($idColaborador, $anio = null, $mes = null, $clienteIdcon = null) { 
    global $pdo;
    $sql = "SELECT LIQ.idliquidacion AS 'ID', LIQ.fecha AS 'FECHA', CLI.nombrecomercial AS 'CLIENTE', 
            TEM.descripcion AS TEMA, LIQ.asunto AS ASUNTO, LIQ.motivo as MOTIVO, 
            LID.nombrecorto AS 'LIDER', CAR.nombrecorto AS 'ENCARGADO', 
            -- LIQ.estado AS 'ESTADO', DIS.calculo AS 'ACUMULADO', LIQ.tipohora AS 'TIPOHORA' 
            DIS.calculo AS 'ACUMULADO', LIQ.cantidahoras AS 'HORAS', LIQ.tipohora AS 'TIPOHORA' 
            FROM liquidacion LIQ 
            INNER JOIN contratocliente CON ON LIQ.idcontratocli=CON.idcontratocli 
            INNER JOIN cliente CLI ON CLI.idcliente=CON.idcliente 
            INNER JOIN empleado LID ON LIQ.lider=LID.idempleado 
            INNER JOIN empleado CAR ON LIQ.acargode=CAR.idempleado 
            INNER JOIN tema TEM ON LIQ.tema=TEM.idtema 
            INNER JOIN distribucionhora DIS ON LIQ.idliquidacion=DIS.idliquidacion 
            WHERE LIQ.activo=1 AND DIS.participante=?";
    $params = [$idColaborador];
    if ($anio) { $sql .= " AND YEAR(LIQ.fecha) = ?"; $params[] = $anio; }
    if ($mes) { $sql .= " AND MONTH(LIQ.fecha) = ?"; $params[] = $mes; }
    if ($clienteIdcon) { $sql .= " AND   CON.idcontratocli = ?"; $params[] = $clienteIdcon; }
    $sql .= " ORDER BY LIQ.idliquidacion DESC";
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}


/*---------------------------------------------------------FUNCIONES MODIFICADAS PARA TRIGGER-------------------------------*/
function registrarLiquidacion($datos) {
    global $pdo;
    try {
        $pdo->beginTransaction();
        $sql = "INSERT INTO liquidacion (fecha, asunto, tema, motivo, tipohora, acargode, lider, cantidahoras, estado, idcontratocli, activo, editor, enlace_onedrive, fecha_completo) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?, ?)";
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            $datos['fecha'], $datos['asunto'], $datos['tema'], $datos['motivo'], 
            $datos['tipohora'], $datos['acargode'], $datos['lider'], 
            $datos['cantidahoras'], $datos['estado'], $datos['idcontratocli'], 
            $datos['editor'], $datos['enlace_onedrive'], $datos['fecha_completo']
        ]);
        $idLiquidacion = $pdo->lastInsertId();

        if ($datos['estado'] == 'Completo' && !empty($datos['colaboradores'])) {
            foreach ($datos['colaboradores'] as $colaborador) {
                $sql_dist = "INSERT INTO distribucionhora (participante, porcentaje, comentario, idliquidacion, fecha, horas, calculo) VALUES (?, ?, ?, ?, ?, ?, ?)";
                $stmt_dist = $pdo->prepare($sql_dist);
                $stmt_dist->execute([
                    $colaborador['id'], $colaborador['porcentaje'], $colaborador['comentario'], 
                    $idLiquidacion, $datos['fecha'], $datos['cantidahoras'], 
                    $datos['cantidahoras'] * (floatval($colaborador['porcentaje']) / 100)
                ]);
            }

            if ($idLiquidacion) {
                $stmt_touch = $pdo->prepare("UPDATE liquidacion SET modificado = CURRENT_TIMESTAMP WHERE idliquidacion = ?");
                $stmt_touch->execute([$idLiquidacion]);
            }
        }
        $pdo->commit();
        return $idLiquidacion;
    } catch (Exception $e) {
        $pdo->rollBack();
        error_log("Error en registrarLiquidacion: " . $e->getMessage());
        throw $e;
    }
}

function actualizarLiquidacion($idLiquidacion, $datos) {
    global $pdo;
    try {
        $pdo->beginTransaction();

        if ($datos['estado'] == 'Completo') {
            $stmt_delete_dist = $pdo->prepare("DELETE FROM distribucionhora WHERE idliquidacion = ?");
            $stmt_delete_dist->execute([$idLiquidacion]);
            if (!empty($datos['colaboradores'])) {
                foreach ($datos['colaboradores'] as $colaborador) {
                    $sql_insert_dist = "INSERT INTO distribucionhora (participante, porcentaje, comentario, idliquidacion, fecha, horas, calculo) VALUES (?, ?, ?, ?, ?, ?, ?)";
                    $stmt_insert_dist = $pdo->prepare($sql_insert_dist);
                    $stmt_insert_dist->execute([
                        $colaborador['id'], $colaborador['porcentaje'], $colaborador['comentario'], 
                        $idLiquidacion, $datos['fecha'], $datos['cantidahoras'], 
                        $datos['cantidahoras'] * (floatval($colaborador['porcentaje']) / 100)
                    ]);
                }
            }
        } else {
            $stmt_delete_dist_else = $pdo->prepare("DELETE FROM distribucionhora WHERE idliquidacion = ?");
            $stmt_delete_dist_else->execute([$idLiquidacion]);
        }

        $sql = "UPDATE liquidacion SET 
                    fecha = ?, asunto = ?, tema = ?, motivo = ?, tipohora = ?, acargode = ?, lider = ?, 
                    cantidahoras = ?, estado = ?, idcontratocli = ?, modificado = CURRENT_TIMESTAMP, 
                    editor = ?, enlace_onedrive = ?, fecha_completo = ?
                WHERE idliquidacion = ?";
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            $datos['fecha'], $datos['asunto'], $datos['tema'], $datos['motivo'], $datos['tipohora'], 
            $datos['acargode'], $datos['lider'], $datos['cantidahoras'], $datos['estado'], 
            $datos['idcontratocli'], $datos['editor'], $datos['enlace_onedrive'], 
            $datos['fecha_completo'], $idLiquidacion
        ]);

        $pdo->commit();
        return true;
    } catch (Exception $e) {
        $pdo->rollBack();
        error_log("Error en actualizarLiquidacion: " . $e->getMessage());
        throw $e;
    }
}





/*--------------------------------------------------------------------------------------------------------------------------*/

function desactivarLiquidacion($idLiquidacion, $editor_id) {
    global $pdo;
    $sql = "UPDATE liquidacion SET activo = 0, modificado = CURRENT_TIMESTAMP, editor = ? WHERE idliquidacion = ?";
    $stmt = $pdo->prepare($sql);
    return $stmt->execute([$editor_id, $idLiquidacion]);
}

function obtenerLiquidacion($idLiquidacion) {
    global $pdo;
    $sql = "SELECT * FROM liquidacion WHERE idliquidacion = ?";
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$idLiquidacion]);
    return $stmt->fetch(PDO::FETCH_ASSOC);
}

function obtenerEstadisticasHoras($filtros = []) {
    global $pdo;
    $sql = "SELECT SUM(CASE WHEN estado = 'Programado' THEN cantidahoras ELSE 0 END) AS programado, SUM(CASE WHEN estado = 'En revisión' THEN cantidahoras ELSE 0 END) AS en_revision, SUM(CASE WHEN estado = 'En proceso' THEN cantidahoras ELSE 0 END) AS en_proceso, SUM(CASE WHEN estado = 'Completo' THEN cantidahoras ELSE 0 END) AS completo, SUM(cantidahoras) AS total FROM liquidacion LIQ INNER JOIN contratocliente CON ON LIQ.idcontratocli=CON.idcontratocli INNER JOIN cliente CLI ON CLI.idcliente=CON.idcliente INNER JOIN empleado LID ON LIQ.lider=LID.idempleado WHERE LIQ.activo=1";
    $params = [];
    if (!empty($filtros['anio'])) { $sql .= " AND YEAR(LIQ.fecha) = ?"; $params[] = $filtros['anio']; }
    if (!empty($filtros['mes'])) { $sql .= " AND MONTH(LIQ.fecha) = ?"; $params[] = $filtros['mes']; }
    if (!empty($filtros['cliente'])) { $sql .= " AND CLI.idcliente = ?"; $params[] = $filtros['cliente']; }
    if (!empty($filtros['lider'])) { $sql .= " AND LID.idempleado = ?"; $params[] = $filtros['lider']; }
    if (!empty($filtros['estado'])) { $sql .= " AND LIQ.estado = ?"; $params[] = $filtros['estado']; }
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    return $stmt->fetch(PDO::FETCH_ASSOC);
}

// ----------------- FUNCIONES CRUD PARA EMPLEADOS (Existentes) -----------------
function obtenerTodosEmpleados($filtros = []) {
    global $pdo;
    $sql = "SELECT idempleado, nombres, paterno, materno, nombrecorto, dni, area, cargo, correocorporativo, rutafoto, activo, nacimiento, lugarnacimiento, domicilio, estadocivil, correopersonal, telcelular, telfijo, horasmeta, derechohabiente, cantidadhijos, contactoemergencia, nivelestudios, regimenpension, fondopension, cussp, modalidad FROM empleado WHERE 1=1"; 
    $params = [];
    if (!empty($filtros['nombre'])) {
        $sql .= " AND (nombres LIKE ? OR paterno LIKE ? OR materno LIKE ? OR nombrecorto LIKE ?)";
        $searchTerm = "%" . $filtros['nombre'] . "%";
        $params = array_merge($params, [$searchTerm, $searchTerm, $searchTerm, $searchTerm]);
    }
    if (!empty($filtros['area'])) { $sql .= " AND area = ?"; $params[] = $filtros['area']; }
    if (isset($filtros['activo']) && $filtros['activo'] !== '') { $sql .= " AND activo = ?"; $params[] = $filtros['activo'];}
    $sql .= " ORDER BY paterno ASC, materno ASC, nombres ASC"; 
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

function obtenerEmpleadoPorId($idempleado) {
    global $pdo;
    $sql = "SELECT * FROM empleado WHERE idempleado = ?";
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$idempleado]);
    return $stmt->fetch(PDO::FETCH_ASSOC);
}

function registrarEmpleado($datos) {
    global $pdo;
    $sql = "INSERT INTO empleado (nombres, paterno, materno, nombrecorto, dni, nacimiento, lugarnacimiento, domicilio, estadocivil, correopersonal, correocorporativo, telcelular, telfijo, area, cargo, horasmeta, derechohabiente, cantidadhijos, contactoemergencia, nivelestudios, regimenpension, fondopension, cussp, modalidad, rutafoto, activo, editor, registrado, modificado) VALUES (:nombres, :paterno, :materno, :nombrecorto, :dni, :nacimiento, :lugarnacimiento, :domicilio, :estadocivil, :correopersonal, :correocorporativo, :telcelular, :telfijo, :area, :cargo, :horasmeta, :derechohabiente, :cantidadhijos, :contactoemergencia, :nivelestudios, :regimenpension, :fondopension, :cussp, :modalidad, :rutafoto, :activo, :editor, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)";
    try {
        $stmt = $pdo->prepare($sql);
        // Bind all parameters including horasmeta
        $stmt->bindParam(':nombres', $datos['nombres']);
        $stmt->bindParam(':paterno', $datos['paterno']);
        $stmt->bindParam(':materno', $datos['materno']);
        $stmt->bindParam(':nombrecorto', $datos['nombrecorto']);
        $stmt->bindParam(':dni', $datos['dni']);
        $stmt->bindParam(':nacimiento', $datos['nacimiento']);
        $stmt->bindParam(':lugarnacimiento', $datos['lugarnacimiento']);
        $stmt->bindParam(':domicilio', $datos['domicilio']);
        $stmt->bindParam(':estadocivil', $datos['estadocivil']);
        $stmt->bindParam(':correopersonal', $datos['correopersonal']);
        $stmt->bindParam(':correocorporativo', $datos['correocorporativo']);
        $stmt->bindParam(':telcelular', $datos['telcelular']);
        $stmt->bindParam(':telfijo', $datos['telfijo']);
        $stmt->bindParam(':area', $datos['area']);
        $stmt->bindParam(':cargo', $datos['cargo']);
        $stmt->bindParam(':horasmeta', $datos['horasmeta'], PDO::PARAM_INT);
        $stmt->bindParam(':derechohabiente', $datos['derechohabiente']);
        $stmt->bindParam(':cantidadhijos', $datos['cantidadhijos'], PDO::PARAM_INT);
        $stmt->bindParam(':contactoemergencia', $datos['contactoemergencia']);
        $stmt->bindParam(':nivelestudios', $datos['nivelestudios']);
        $stmt->bindParam(':regimenpension', $datos['regimenpension']);
        $stmt->bindParam(':fondopension', $datos['fondopension']);
        $stmt->bindParam(':cussp', $datos['cussp']);
        $stmt->bindParam(':modalidad', $datos['modalidad']);
        $stmt->bindParam(':rutafoto', $datos['rutafoto']);
        $stmt->bindParam(':activo', $datos['activo'], PDO::PARAM_INT);
        $stmt->bindParam(':editor', $datos['editor'], PDO::PARAM_INT);
        $stmt->execute();
        return $pdo->lastInsertId();
    } catch (PDOException $e) {
        error_log("Error al registrar empleado: " . $e->getMessage());
        return false;
    }
}
function actualizarEmpleado($idempleado, $datos) {
    global $pdo;
    $sql = "UPDATE empleado SET nombres = :nombres, paterno = :paterno, materno = :materno, nombrecorto = :nombrecorto, dni = :dni, nacimiento = :nacimiento, lugarnacimiento = :lugarnacimiento, domicilio = :domicilio, estadocivil = :estadocivil, correopersonal = :correopersonal, correocorporativo = :correocorporativo, telcelular = :telcelular, telfijo = :telfijo, area = :area, cargo = :cargo, horasmeta = :horasmeta, derechohabiente = :derechohabiente, cantidadhijos = :cantidadhijos, contactoemergencia = :contactoemergencia, nivelestudios = :nivelestudios, regimenpension = :regimenpension, fondopension = :fondopension, cussp = :cussp, modalidad = :modalidad, rutafoto = :rutafoto, activo = :activo, editor = :editor, modificado = CURRENT_TIMESTAMP WHERE idempleado = :idempleado";
    try {
        $stmt = $pdo->prepare($sql);
        // Bind all parameters including horasmeta
        $stmt->bindParam(':nombres', $datos['nombres']);
        $stmt->bindParam(':paterno', $datos['paterno']);
        $stmt->bindParam(':materno', $datos['materno']);
        $stmt->bindParam(':nombrecorto', $datos['nombrecorto']);
        $stmt->bindParam(':dni', $datos['dni']);
        $stmt->bindParam(':nacimiento', $datos['nacimiento']);
        $stmt->bindParam(':lugarnacimiento', $datos['lugarnacimiento']);
        $stmt->bindParam(':domicilio', $datos['domicilio']);
        $stmt->bindParam(':estadocivil', $datos['estadocivil']);
        $stmt->bindParam(':correopersonal', $datos['correopersonal']);
        $stmt->bindParam(':correocorporativo', $datos['correocorporativo']);
        $stmt->bindParam(':telcelular', $datos['telcelular']);
        $stmt->bindParam(':telfijo', $datos['telfijo']);
        $stmt->bindParam(':area', $datos['area']);
        $stmt->bindParam(':cargo', $datos['cargo']);
        $stmt->bindParam(':horasmeta', $datos['horasmeta'], PDO::PARAM_INT);
        $stmt->bindParam(':derechohabiente', $datos['derechohabiente']);
        $stmt->bindParam(':cantidadhijos', $datos['cantidadhijos'], PDO::PARAM_INT);
        $stmt->bindParam(':contactoemergencia', $datos['contactoemergencia']);
        $stmt->bindParam(':nivelestudios', $datos['nivelestudios']);
        $stmt->bindParam(':regimenpension', $datos['regimenpension']);
        $stmt->bindParam(':fondopension', $datos['fondopension']);
        $stmt->bindParam(':cussp', $datos['cussp']);
        $stmt->bindParam(':modalidad', $datos['modalidad']);
        $stmt->bindParam(':rutafoto', $datos['rutafoto']);
        $stmt->bindParam(':activo', $datos['activo'], PDO::PARAM_INT);
        $stmt->bindParam(':editor', $datos['editor'], PDO::PARAM_INT);
        $stmt->bindParam(':idempleado', $idempleado, PDO::PARAM_INT);
        $stmt->execute();
        return $stmt->rowCount() > 0; 
    } catch (PDOException $e) {
        error_log("Error al actualizar empleado: " . $e->getMessage());
        return false;
    }
}

function desactivarEmpleado($idempleado, $editor_id) {
    global $pdo;
    $sql = "UPDATE empleado SET activo = 0, editor = ?, modificado = CURRENT_TIMESTAMP WHERE idempleado = ?";
    try {
        $stmt = $pdo->prepare($sql);
        return $stmt->execute([$editor_id, $idempleado]);
    } catch (PDOException $e) { error_log("Error al desactivar empleado: " . $e->getMessage()); return false; }
}

function activarEmpleado($idempleado, $editor_id) {
    global $pdo;
    $sql = "UPDATE empleado SET activo = 1, editor = ?, modificado = CURRENT_TIMESTAMP WHERE idempleado = ?";
     try {
        $stmt = $pdo->prepare($sql);
        return $stmt->execute([$editor_id, $idempleado]);
    } catch (PDOException $e) { error_log("Error al activar empleado: " . $e->getMessage()); return false; }
}


// ----------------- FUNCIONES CRUD PARA USUARIOS (Existentes) -----------------
/**
 * Obtiene empleados activos para poblar selects.
 * Usada por CRUD Usuarios y CRUD Temas.
 * @return array Lista de empleados con idempleado, nombrecorto y rutafoto.
 */
function obtenerEmpleadosActivosParaSelect() {
    global $pdo;
    $sql = "SELECT idempleado, nombrecorto, rutafoto FROM empleado WHERE activo = 1 ORDER BY nombrecorto ASC";
    $stmt = $pdo->query($sql);
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

function obtenerTodosUsuarios($filtros = []) {
    global $pdo;
    $sql = "SELECT u.idusuario, u.nombre, u.tipo, u.activo, u.idemp, e.nombrecorto AS nombre_empleado, e.rutafoto AS rutafoto_empleado
            FROM usuario u
            LEFT JOIN empleado e ON u.idemp = e.idempleado
            WHERE 1=1"; 
    
    $params = [];
    if (isset($filtros['activo']) && $filtros['activo'] !== '') {
        $sql .= " AND u.activo = :activo";
        $params[':activo'] = $filtros['activo'];
    }
    $sql .= " ORDER BY u.nombre ASC";
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

function obtenerUsuarioPorId($idusuario) {
    global $pdo;
    $sql = "SELECT u.idusuario, u.nombre, u.tipo, u.activo, u.idemp, e.nombrecorto AS nombre_empleado, e.rutafoto AS rutafoto_empleado
            FROM usuario u
            LEFT JOIN empleado e ON u.idemp = e.idempleado
            WHERE u.idusuario = :idusuario";
    $stmt = $pdo->prepare($sql);
    $stmt->execute([':idusuario' => $idusuario]);
    return $stmt->fetch(PDO::FETCH_ASSOC);
}

function registrarUsuario($datos) {
    global $pdo;
    $sql = "INSERT INTO usuario (nombre, password, tipo, activo, idemp, editor, registrado, modificado) 
            VALUES (:nombre, :password, :tipo, :activo, :idemp, :editor, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)";
    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            ':nombre' => $datos['nombre'],
            ':password' => $datos['password'], 
            ':tipo' => $datos['tipo'],
            ':activo' => $datos['activo'],
            ':idemp' => $datos['idemp'],
            ':editor' => $datos['editor']
        ]);
        return $pdo->lastInsertId();
    } catch (PDOException $e) {
        error_log("Error al registrar usuario: " . $e->getMessage());
        if ($e->errorInfo[1] == 1062) { 
             $_SESSION['mensaje_error_detalle'] = 'Error: El nombre de usuario ya existe.';
        } else {
             $_SESSION['mensaje_error_detalle'] = 'Error de base de datos al registrar: ' . $e->getMessage();
        }
        return false;
    }
}

function actualizarUsuario($idusuario, $datos) {
    global $pdo;
    $sql = "UPDATE usuario SET 
                nombre = :nombre, 
                tipo = :tipo, 
                activo = :activo, 
                idemp = :idemp, 
                editor = :editor, 
                modificado = CURRENT_TIMESTAMP 
            WHERE idusuario = :idusuario";
    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            ':nombre' => $datos['nombre'],
            ':tipo' => $datos['tipo'],
            ':activo' => $datos['activo'],
            ':idemp' => $datos['idemp'],
            ':editor' => $datos['editor'],
            ':idusuario' => $idusuario
        ]);
        return true; 
    } catch (PDOException $e) {
        error_log("Error al actualizar usuario: " . $e->getMessage());
         if ($e->errorInfo[1] == 1062) {
             $_SESSION['mensaje_error_detalle'] = 'Error: El nombre de usuario ya existe para otro usuario.';
        } else {
            $_SESSION['mensaje_error_detalle'] = 'Error de base de datos al actualizar: ' . $e->getMessage();
        }
        return false;
    }
}

function actualizarEstadoUsuario($idusuario, $estado, $editor_id) {
    global $pdo;
    $sql = "UPDATE usuario SET activo = :activo, editor = :editor, modificado = CURRENT_TIMESTAMP WHERE idusuario = :idusuario";
    try {
        $stmt = $pdo->prepare($sql);
        return $stmt->execute([':activo' => $estado, ':editor' => $editor_id, ':idusuario' => $idusuario]);
    } catch (PDOException $e) {
        error_log("Error al actualizar estado de usuario: " . $e->getMessage());
        $_SESSION['mensaje_error_detalle'] = 'Error de base de datos: ' . $e->getMessage();
        return false;
    }
}

function actualizarPasswordUsuario($idusuario, $hashed_password, $editor_id) {
    global $pdo;
    $sql = "UPDATE usuario SET password = :password, editor = :editor, modificado = CURRENT_TIMESTAMP WHERE idusuario = :idusuario";
    try {
        $stmt = $pdo->prepare($sql);
        return $stmt->execute([':password' => $hashed_password, ':editor' => $editor_id, ':idusuario' => $idusuario]);
    } catch (PDOException $e) {
        error_log("Error al actualizar contraseña de usuario: " . $e->getMessage());
        $_SESSION['mensaje_error_detalle'] = 'Error de base de datos: ' . $e->getMessage();
        return false;
    }
}


// ----------------- FUNCIONES CRUD PARA TEMAS (Nuevas) -----------------

function obtenerTodosTemas_crud($filtros = []) { 
    global $pdo;
    $sql = "SELECT t.idtema, t.descripcion, t.idencargado, t.comentario, t.editor, t.registrado, t.modificado, e.nombrecorto AS nombre_encargado,t.activo
            FROM tema t
            LEFT JOIN empleado e ON t.idencargado = e.idempleado
            WHERE 1=1";
    $params = [];
    if (!empty($filtros['descripcion'])) {
        $sql .= " AND t.descripcion LIKE :descripcion";
        $params[':descripcion'] = "%" . $filtros['descripcion'] . "%";
    }
    if (isset($filtros['idencargado']) && $filtros['idencargado'] !== null && $filtros['idencargado'] !== '') {
        $sql .= " AND t.idencargado = :idencargado";
        $params[':idencargado'] = $filtros['idencargado'];
    }
    $sql .= " ORDER BY t.descripcion ASC";
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

function obtenerTemaPorId($idtema) {
    global $pdo;
    $sql = "SELECT t.idtema, t.descripcion, t.idencargado, t.comentario, t.editor, t.registrado, t.modificado, e.nombrecorto AS nombre_encargado
            FROM tema t
            LEFT JOIN empleado e ON t.idencargado = e.idempleado
            WHERE t.idtema = :idtema";
    $stmt = $pdo->prepare($sql);
    $stmt->execute([':idtema' => $idtema]);
    return $stmt->fetch(PDO::FETCH_ASSOC);
}

function registrarTema($datos) {
    global $pdo;
    $sql = "INSERT INTO tema (descripcion, idencargado, comentario, editor, registrado, modificado) 
            VALUES (:descripcion, :idencargado, :comentario, :editor, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)";
    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            ':descripcion' => $datos['descripcion'],
            ':idencargado' => $datos['idencargado'], 
            ':comentario' => $datos['comentario'],
            ':editor' => $datos['editor']
        ]);
        return $pdo->lastInsertId();
    } catch (PDOException $e) {
        error_log("Error al registrar tema: " . $e->getMessage());
        $_SESSION['mensaje_error_detalle'] = 'Error de base de datos al registrar el tema: ' . $e->getMessage();
        return false;
    }
}

function actualizarTema($idtema, $datos) {
    global $pdo;
    $sql = "UPDATE tema SET 
                descripcion = :descripcion, 
                idencargado = :idencargado, 
                comentario = :comentario, 
                editor = :editor, 
                modificado = CURRENT_TIMESTAMP 
            WHERE idtema = :idtema";
    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            ':descripcion' => $datos['descripcion'],
            ':idencargado' => $datos['idencargado'],
            ':comentario' => $datos['comentario'],
            ':editor' => $datos['editor'],
            ':idtema' => $idtema
        ]);
        return true; 
    } catch (PDOException $e) {
        error_log("Error al actualizar tema: " . $e->getMessage());
        $_SESSION['mensaje_error_detalle'] = 'Error de base de datos al actualizar el tema: ' . $e->getMessage();
        return false;
    }
}

function eliminarTema($idtema) {
    global $pdo;
    $sql = "DELETE FROM tema WHERE idtema = :idtema";
    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute([':idtema' => $idtema]);
        return $stmt->rowCount() > 0; 
    } catch (PDOException $e) {
        error_log("Error al eliminar tema: " . $e->getMessage());
        $_SESSION['mensaje_error_detalle'] = 'Error de base de datos al eliminar el tema. Es posible que esté siendo referenciado en otras tablas. Detalle: ' . $e->getMessage();
        return false;
    }
}
// REEMPLAZADA: eliminarTema por actualizarEstadoTema
// function eliminarTema($idtema) { ... }

/**
 * Actualiza el estado (activo/inactivo) de un tema.
 * @param int $idtema ID del tema.
 * @param int $estado Nuevo estado (1 para activo, 0 para inactivo).
 * @param int $editor_id ID del empleado que realiza la modificación.
 * @return bool True en éxito, false en error.
 */
function actualizarEstadoTema($idtema, $estado, $editor_id) {
    global $pdo;
    $sql = "UPDATE tema SET activo = :activo, editor = :editor, modificado = CURRENT_TIMESTAMP WHERE idtema = :idtema";
    try {
        $stmt = $pdo->prepare($sql);
        return $stmt->execute([':activo' => $estado, ':editor' => $editor_id, ':idtema' => $idtema]);
    } catch (PDOException $e) {
        error_log("Error al actualizar estado de tema: " . $e->getMessage());
        $_SESSION['mensaje_error_detalle'] = 'Error de base de datos: ' . $e->getMessage();
        return false;
    }
}
/*------------------------------ */
/**
 * Obtiene un resumen de temas agrupados por encargado.
 * Devuelve solo los encargados que tienen al menos un tema.
 * @return array Lista de encargados con su idempleado, nombrecorto y la cantidad de temas asignados.
 */
function obtenerResumenTemasPorEncargado() {
    global $pdo;
    $sql = "SELECT e.idempleado, e.nombrecorto, COUNT(t.idtema) as cantidad_temas
            FROM empleado e
            JOIN tema t ON e.idempleado = t.idencargado
            GROUP BY e.idempleado, e.nombrecorto
            HAVING COUNT(t.idtema) > 0
            ORDER BY e.nombrecorto ASC";
    try {
        $stmt = $pdo->query($sql);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    } catch (PDOException $e) {
        error_log("Error al obtener resumen de temas por encargado: " . $e->getMessage());
        return []; // Devuelve array vacío en caso de error
    }
}
// ----------------- FUNCIONES CRUD PARA CLIENTES (Nuevas) -----------------

/**
 * Obtiene todos los clientes.
 * @param array$filtros Filtros opcionales (ej. por nombre, por activo).
 * @return array Lista de clientes.
 */
function obtenerTodosClientes_crud($filtros = []) { 
    global$pdo;
   $sql = "SELECT * FROM cliente WHERE 1=1";
   $params = [];

    if (isset($filtros['activo']) &&$filtros['activo'] !== '') {
       $sql .= " AND activo = :activo";
       $params[':activo'] =$filtros['activo'];
    }
   $sql .= " ORDER BY nombrecomercial ASC";
    
   $stmt =$pdo->prepare($sql);
   $stmt->execute($params);
    return$stmt->fetchAll(PDO::FETCH_ASSOC);
}

/**
 * Obtiene un cliente por su ID.
 * @param int$idcliente ID del cliente.
 * @return array|false Datos del cliente o false si no existe.
 */
function obtenerClientePorId($idcliente) {
    global$pdo;
   $sql = "SELECT * FROM cliente WHERE idcliente = :idcliente";
   $stmt =$pdo->prepare($sql);
   $stmt->execute([':idcliente' =>$idcliente]);
    return$stmt->fetch(PDO::FETCH_ASSOC);
}

/**
 * Registra un nuevo cliente.
 * @param array$datos Datos del cliente.
 * @return int|false ID del nuevo cliente o false en error.
 */
function registrarCliente($datos) {
    global$pdo;
   $sql = "INSERT INTO cliente (razonsocial, nombrecomercial, ruc, direccion, telefono, sitioweb, representante, telrepresentante, correorepre, gerente, telgerente, correogerente, activo, editor, registrado, modificado) 
            VALUES (:razonsocial, :nombrecomercial, :ruc, :direccion, :telefono, :sitioweb, :representante, :telrepresentante, :correorepre, :gerente, :telgerente, :correogerente, :activo, :editor, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)";
    try {
       $stmt =$pdo->prepare($sql);
       $stmt->execute($datos); 
        return$pdo->lastInsertId();
    } catch (PDOException$e) {
        error_log("Error al registrar cliente: " .$e->getMessage());
        if ($e->errorInfo[1] == 1062) { 
            $_SESSION['mensaje_error_detalle'] = 'Error: El RUC ya existe para otro cliente.';
        } else {
            $_SESSION['mensaje_error_detalle'] = 'Error de base de datos al registrar el cliente: ' .$e->getMessage();
        }
        return false;
    }
}

/**
 * Actualiza los datos de un cliente existente.
 * @param int$idcliente ID del cliente.
 * @param array$datos Nuevos datos del cliente.
 * @return bool True en éxito, false en caso de error.
 */
function actualizarCliente($idcliente,$datos) {
    global$pdo;
   $sql = "UPDATE cliente SET 
                razonsocial = :razonsocial, 
                nombrecomercial = :nombrecomercial, 
                ruc = :ruc, 
                direccion = :direccion, 
                telefono = :telefono, 
                sitioweb = :sitioweb, 
                representante = :representante, 
                telrepresentante = :telrepresentante, 
                correorepre = :correorepre, 
                gerente = :gerente, 
                telgerente = :telgerente, 
                correogerente = :correogerente, 
                activo = :activo, 
                editor = :editor, 
                modificado = CURRENT_TIMESTAMP 
            WHERE idcliente = :idcliente";
    try {
       $datos_completos =$datos;
       $datos_completos['idcliente'] =$idcliente;
        
       $stmt =$pdo->prepare($sql);
       $stmt->execute($datos_completos);
        return$stmt->rowCount() > 0;
    } catch (PDOException$e) {
        error_log("Error al actualizar cliente: " .$e->getMessage());
        if ($e->errorInfo[1] == 1062) { 
            $_SESSION['mensaje_error_detalle'] = 'Error: El RUC ya existe para otro cliente.';
        } else {
           $_SESSION['mensaje_error_detalle'] = 'Error de base de datos al actualizar el cliente: ' .$e->getMessage();
        }
        return false;
    }
}

/**
 * Actualiza el estado (activo/inactivo) de un cliente.
 * @param int$idcliente ID del cliente.
 * @param int$estado Nuevo estado (1 para activo, 0 para inactivo).
 * @param int$editor_id ID del empleado que realiza la modificación.
 * @return bool True en éxito, false en error.
 */
function actualizarEstadoCliente($idcliente, $estado, $editor_id) {
    global $pdo;
    $sql = "UPDATE cliente SET activo = :activo, editor = :editor, modificado = CURRENT_TIMESTAMP WHERE idcliente = :idcliente";
    try {
        $stmt = $pdo->prepare($sql);
        return $stmt->execute([':activo' => $estado, ':editor' => $editor_id, ':idcliente' => $idcliente]);
    } catch (PDOException $e) {
        error_log("Error al actualizar estado de cliente: " . $e->getMessage());
        $_SESSION['mensaje_error_detalle'] = 'Error de base de datos: ' . $e->getMessage();
        return false;
    }
}
// ----------------- FUNCIONES CRUD PARA CONTRATOS DE CLIENTES (Nuevas) -----------------

/**
 * Obtiene clientes activos para poblar selects (usada también en Contratos).
 * @return array Lista de clientes con idcliente y nombrecomercial.
 */
function obtenerClientesActivosParaSelect() {
    global $pdo;
    $sql = "SELECT idcliente, nombrecomercial FROM cliente WHERE activo = 1 ORDER BY nombrecomercial ASC";
    $stmt = $pdo->query($sql);
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}


/**
 * Obtiene un resumen de contratos agrupados por líder.
 * @return array Lista de líderes con su idempleado, nombrecorto y la cantidad de contratos asignados (solo activos).
 */
function obtenerResumenContratosPorLider() {
    global $pdo;
    $sql = "SELECT e.idempleado, e.nombrecorto, COUNT(cc.idcontratocli) as cantidad_contratos
            FROM empleado e
            JOIN contratocliente cc ON e.idempleado = cc.lider
            WHERE cc.activo = 1 
            GROUP BY e.idempleado, e.nombrecorto
            HAVING COUNT(cc.idcontratocli) > 0
            ORDER BY e.nombrecorto ASC";
    try {
        $stmt = $pdo->query($sql);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    } catch (PDOException $e) {
        error_log("Error al obtener resumen de contratos por líder: " . $e->getMessage());
        return [];
    }
}

/**
 * Obtiene todos los contratos de clientes con información del cliente y líder.
 * @param array $filtros Filtros opcionales (ej. por líder, por cliente, por activo).
 * @return array Lista de contratos.
 */
function obtenerTodosContratosClientes($filtros = []) {
    global $pdo;
    $sql = "SELECT cc.*, c.nombrecomercial AS nombre_cliente, e.nombrecorto AS nombre_lider,
                   la.ultima_numeroadenda, la.ultima_fechafin
            FROM contratocliente cc
            JOIN cliente c ON cc.idcliente = c.idcliente
            JOIN empleado e ON cc.lider = e.idempleado
            LEFT JOIN (
                SELECT a1.idcontratocli, a1.numeroadenda AS ultima_numeroadenda, a1.fechafin AS ultima_fechafin
                FROM adendacliente a1
                INNER JOIN (
                    SELECT idcontratocli, MAX(numeroadenda) AS max_numeroadenda
                    FROM adendacliente
                    GROUP BY idcontratocli
                ) a2 ON a1.idcontratocli = a2.idcontratocli AND a1.numeroadenda = a2.max_numeroadenda
            ) AS la ON cc.idcontratocli = la.idcontratocli
            WHERE 1=1"; // Para facilitar añadir filtros
    $params = [];

    if (isset($filtros['id_lider_filtro']) && $filtros['id_lider_filtro'] !== '' && $filtros['id_lider_filtro'] !== null) {
        $sql .= " AND cc.lider = :lider";
        $params[':lider'] = $filtros['id_lider_filtro'];
    }
    // Por defecto mostrar solo activos, a menos que se especifique lo contrario
    if (isset($filtros['activo']) && $filtros['activo'] !== '') {
        $sql .= " AND cc.activo = :activo";
        $params[':activo'] = $filtros['activo'];
    } else {
         //$sql .= " AND cc.activo = 1"; // Mostrar solo activos por defecto en el listado principal
    }
    
    $sql .= " ORDER BY cc.fechainicio DESC, c.nombrecomercial ASC";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

/**
 * Obtiene un contrato de cliente por su ID, con nombres de cliente y líder.
 * @param int $idcontratocli ID del contrato.
 * @return array|false Datos del contrato o false si no existe.
 */
function obtenerContratoClientePorId($idcontratocli) {
    global $pdo;
    $sql = "SELECT cc.*, c.nombrecomercial AS nombre_cliente, e.nombrecorto AS nombre_lider
            FROM contratocliente cc
            JOIN cliente c ON cc.idcliente = c.idcliente
            JOIN empleado e ON cc.lider = e.idempleado
            WHERE cc.idcontratocli = :idcontratocli";
    $stmt = $pdo->prepare($sql);
    $stmt->execute([':idcontratocli' => $idcontratocli]);
    return $stmt->fetch(PDO::FETCH_ASSOC);
}

/**
 * Registra un nuevo contrato de cliente.
 * @param array $datos Datos del contrato.
 * @return int|false ID del nuevo contrato o false en error.
 */
function registrarContratoCliente($datos) {
    global $pdo;
    
    $columnas = [];
    $placeholders = [];
    $params = [];

    foreach ($datos as $key => $value) {
        $columnas[] = $key;
        $placeholders[] = ":$key";
        $params[":$key"] = $value;
    }

    $sql = sprintf(
        "INSERT INTO contratocliente (%s, registrado, modificado) VALUES (%s, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        implode(', ', $columnas),
        implode(', ', $placeholders)
    );

    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        return $pdo->lastInsertId();
    } catch (PDOException $e) {
        error_log("Error al registrar contrato de cliente: " . $e->getMessage());
        $_SESSION['mensaje_error_detalle'] = 'Error de base de datos: ' . $e->getMessage();
        return false;
    }
}

/**
 * Actualiza un contrato de cliente existente.
 * @param int $idcontratocli ID del contrato.
 * @param array $datos Nuevos datos del contrato.
 * @return bool True en éxito, false en error.
 */
function actualizarContratoCliente($idcontratocli, $datos) {
    global $pdo;
    
    $sql_parts = [];
    $params = [];

    // Lista de campos que siempre se actualizan
    $campos_base = [
        'idcliente', 'lider', 'descripcion', 'fechainicio', 'fechafin', 
        'horasfijasmes', 'costohorafija', 'mesescontrato', 'totalhorasfijas', 
        'tipobolsa', 'costohoraextra', 'montofijomes', 'planmontomes', 
        'planhoraextrames', 'status', 'tipohora', 'activo', 'editor'
    ];

    foreach ($campos_base as $campo) {
        if (isset($datos[$campo])) {
            $sql_parts[] = "$campo = :$campo";
            $params[":$campo"] = $datos[$campo];
        }
    }

    // Añadir el campo del PDF solo si se proporcionó un nuevo archivo
    if (isset($datos['ruta_pdf_contrato']) && !is_null($datos['ruta_pdf_contrato'])) {
        $sql_parts[] = "ruta_pdf_contrato = :ruta_pdf_contrato";
        $params[':ruta_pdf_contrato'] = $datos['ruta_pdf_contrato'];
    }
    
    // Si no hay campos para actualizar, no hacemos nada.
    if (empty($sql_parts)) {
        return true; 
    }

    $sql = "UPDATE contratocliente SET " . implode(', ', $sql_parts) . ", modificado = CURRENT_TIMESTAMP WHERE idcontratocli = :idcontratocli";
    $params[':idcontratocli'] = $idcontratocli;

    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        return $stmt->rowCount() > 0;
    } catch (PDOException $e) {
        error_log("Error al actualizar contrato de cliente: " . $e->getMessage());
        $_SESSION['mensaje_error_detalle'] = 'Error de base de datos: ' . $e->getMessage();
        return false;
    }
}

/**
 * Actualiza el estado (activo/inactivo) de un contrato de cliente.
 * @param int $idcontratocli ID del contrato.
 * @param int $estado Nuevo estado (1 para activo, 0 para inactivo).
 * @param int $editor_id ID del empleado que realiza la modificación.
 * @return bool True en éxito, false en error.
 */
function actualizarEstadoContratoCliente($idcontratocli, $estado, $editor_id) {
    global $pdo;
    $sql = "UPDATE contratocliente SET activo = :activo, editor = :editor, modificado = CURRENT_TIMESTAMP 
            WHERE idcontratocli = :idcontratocli";
    try {
        $stmt = $pdo->prepare($sql);
        return $stmt->execute([':activo' => $estado, ':editor' => $editor_id, ':idcontratocli' => $idcontratocli]);
    } catch (PDOException $e) {
        error_log("Error al actualizar estado de contrato de cliente: " . $e->getMessage());
        $_SESSION['mensaje_error_detalle'] = 'Error de base de datos: ' . $e->getMessage();
        return false;
    }
}
// ----------------- FUNCIONES CRUD PARA PLANIFICACIONES (Nuevas o Modificadas) -----------------
/**
 * Obtiene todas las planificaciones con información del cliente, contrato y líder.
 * @param array $filtros Filtros opcionales (ej. por año, por mes, por activo).
 * @return array Lista de planificaciones.
 */
function obtenerTodasPlanificaciones($filtros = []) {
    global $pdo;
    $sql = "SELECT 
                p.Idplanificacion AS idplanificacion, p.idContratoCliente AS idcontratocli, p.nombreplan AS nombre_planificacion, 
                p.fechaplan AS mes_planificado, p.horasplan AS horas_planificadas, p.comentario, p.activo,
                p.editor, p.registrado, p.modificado,
                cc.descripcion AS descripcion_contrato, 
                cli.nombrecomercial AS nombre_cliente,
                emp_lider.nombrecorto AS nombre_lider
            FROM planificacion p
            JOIN contratocliente cc ON p.idContratoCliente = cc.idcontratocli 
            JOIN cliente cli ON cc.idcliente = cli.idcliente
            LEFT JOIN empleado emp_lider ON p.lider = emp_lider.idempleado
            WHERE 1=1";
    $params = [];

    if (!empty($filtros['anio_planificado'])) {
        $sql .= " AND YEAR(p.fechaplan) = :anio_planificado";
        $params[':anio_planificado'] = $filtros['anio_planificado'];
    }
    if (!empty($filtros['mes_planificado'])) {
        $sql .= " AND MONTH(p.fechaplan) = :mes_planificado";
        $params[':mes_planificado'] = $filtros['mes_planificado'];
    }
    if (isset($filtros['activo']) && $filtros['activo'] !== '' && ($filtros['activo'] == 0 || $filtros['activo'] == 1)) {
        $sql .= " AND p.activo = :activo_planificacion";
        $params[':activo_planificacion'] = $filtros['activo'];
    }
    
    $sql .= " ORDER BY p.fechaplan DESC, cli.nombrecomercial ASC, p.Idplanificacion DESC";
    
    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    } catch (PDOException $e) {
        error_log("Error en obtenerTodasPlanificaciones: " . $e->getMessage());
        $_SESSION['mensaje_error_detalle'] = 'Error de BD al obtener planificaciones: ' . $e->getMessage();
        return [];
    }
}

/**
 * Obtiene una planificación por su ID, con nombres de cliente, descripción de contrato y líder.
 * @param int $idplanificacion ID de la planificación.
 * @return array|false Datos de la planificación o false si no existe.
 */
function obtenerPlanificacionPorId($idplanificacion) {
    global $pdo;
    $sql = "SELECT 
                p.idplanificacion, p.idContratoCliente AS idcontratocliente, p.nombreplan AS nombre_planificacion, 
                p.fechaplan AS mes_planificado, p.horasplan AS horas_planificadas, 
                p.lider AS id_lider, p.comentario, p.activo,
                p.editor, p.registrado, p.modificado,
                cc.descripcion AS descripcion_contrato, 
                cli.nombrecomercial AS nombre_cliente,
                emp_lider.nombrecorto AS nombre_lider
            FROM planificacion p
            JOIN contratocliente cc ON p.idcontratocliente = cc.idcontratocli
            JOIN cliente cli ON cc.idcliente = cli.idcliente
            LEFT JOIN empleado emp_lider ON p.lider = emp_lider.idempleado
            WHERE p.idplanificacion = :idplanificacion";
    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute([':idplanificacion' => $idplanificacion]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    } catch (PDOException $e) {
        error_log("Error en obtenerPlanificacionPorId: " . $e->getMessage());
        $_SESSION['mensaje_error_detalle'] = 'Error de BD al obtener la planificación: ' . $e->getMessage();
        return false;
    }
}

/**
 * Obtiene contratos activos de clientes activos para poblar selects.
 * Incluye el ID del líder del contrato.
 * @return array Lista de contratos.
 */
// Ya existe una función obtenerClientesActivosParaSelect(), esta es más específica para contratos.
// Se renombrará la existente o se usará esta si el contexto es claro.
// Por ahora, la mantenemos con un nombre distintivo si es necesario, o ajustamos la existente.
// Esta versión es la que se necesita para el form de Planificación:
// function obtenerContratosActivosParaSelectPlanificacion() { // Nombre alternativo
function obtenerContratosActivosParaSelect() { // Sobrescribiendo/Asegurando la versión correcta
    global $pdo;

    $sql = "SELECT 
                cc.idcontratocli, 
                cli.nombrecomercial AS nombre_cliente,
                cc.lider AS id_lider_contrato, 
                CONCAT('ID: ', cc.idcontratocli, IF(cc.descripcion IS NOT NULL AND cc.descripcion != '', CONCAT(' - ', cc.descripcion), '')) AS descripcion_completa_contrato
            FROM contratocliente cc
            JOIN cliente cli ON cc.idcliente = cli.idcliente
            WHERE cc.activo = 1 AND cli.activo = 1 
            ORDER BY cli.nombrecomercial ASC, cc.idcontratocli ASC";
    try {
        $stmt = $pdo->query($sql);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    } catch (PDOException $e) {
        error_log("Error en obtenerContratosActivosParaSelect: " . $e->getMessage());
        $_SESSION['mensaje_error_detalle'] = 'Error de BD al obtener contratos: ' . $e->getMessage();
        return [];
    }
}
/**
 * Inserta una nueva planificación en la base de datos.
 * Determina el líder a partir del contrato cliente.
 * @param array $datos Datos de la planificación. Incluye 'idcontratocli', 'nombre', 'mes' (YYYY-MM-01), 
 *                     'horas_planificadas', 'comentario', 'activo', 'editor'.
 * @return int|false El ID de la nueva planificación o false en caso de error.
 */
function insertarPlanificacion($datos) {
    global $pdo;

    // Validar que los datos esperados estén presentes
    if (empty($datos['idContratoCliente']) || empty($datos['nombreplan']) || empty($datos['fechaplan']) || !isset($datos['horasplan']) || empty($datos['lider']) || !isset($datos['activo']) || empty($datos['editor'])) {
        error_log("Error en insertarPlanificacion: Datos incompletos. Datos: " . json_encode($datos));
        $_SESSION['mensaje_error_detalle'] = 'Error interno: Datos incompletos para registrar la planificación.';
        return false;
    }
    
    $sql = "INSERT INTO planificacion (idContratoCliente, nombreplan, fechaplan, horasplan, lider, comentario, activo, editor, registrado, modificado) 
            VALUES (:idContratoCliente, :nombreplan, :fechaplan, :horasplan, :lider, :comentario, :activo, :editor, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)";
    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            ':idContratoCliente' => $datos['idContratoCliente'],
            ':nombreplan' => $datos['nombreplan'],
            ':fechaplan' => $datos['fechaplan'],
            ':horasplan' => $datos['horasplan'],
            ':lider' => $datos['lider'],
            ':comentario' => $datos['comentario'] ?? null,
            ':activo' => $datos['activo'],
            ':editor' => $datos['editor']
        ]);
        return $pdo->lastInsertId();
    } catch (PDOException $e) {
        error_log("Error al insertar planificación: " . $e->getMessage() . " SQL: " . $sql . " Data: " . json_encode($datos));
        if ($e->errorInfo[1] == 1062) {
            $_SESSION['mensaje_error_detalle'] = 'Error: Ya existe una planificación para el contrato y mes seleccionados.';
        } else {
            $_SESSION['mensaje_error_detalle'] = 'Error de BD al registrar la planificación.';
        }
        return false;
    }
}

/**
 * Actualiza una planificación existente.
 * Determina el líder a partir del contrato cliente.
 * @param int $idplanificacion ID de la planificación a actualizar.
 * @param array $datos Nuevos datos. Incluye 'idcontratocli', 'nombre', 'mes', 
 *                     'horas_planificadas', 'comentario', 'activo', 'editor'.
 * @return bool True en éxito o si no hubo cambios, false en error.
 */
function actualizarPlanificacion($idplanificacion, $datos) {
    global $pdo;

    if (empty($datos['idContratoCliente']) || empty($datos['nombreplan']) || empty($datos['fechaplan']) || !isset($datos['horasplan']) || empty($datos['lider']) || !isset($datos['activo']) || empty($datos['editor'])) {
        error_log("Error en actualizarPlanificacion: Datos incompletos. Datos: " . json_encode($datos));
        $_SESSION['mensaje_error_detalle'] = 'Error interno: Datos incompletos para actualizar la planificación.';
        return false;
    }

    $sql = "UPDATE planificacion SET 
                idContratoCliente = :idContratoCliente, 
                nombreplan = :nombreplan, 
                fechaplan = :fechaplan, 
                horasplan = :horasplan, 
                lider = :lider,
                comentario = :comentario,
                activo = :activo, 
                editor = :editor, 
                modificado = CURRENT_TIMESTAMP 
            WHERE Idplanificacion = :Idplanificacion_param";
    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            ':idContratoCliente' => $datos['idContratoCliente'],
            ':nombreplan' => $datos['nombreplan'],
            ':fechaplan' => $datos['fechaplan'],
            ':horasplan' => $datos['horasplan'],
            ':lider' => $datos['lider'],
            ':comentario' => $datos['comentario'] ?? null,
            ':activo' => $datos['activo'],
            ':editor' => $datos['editor'],
            ':Idplanificacion_param' => $idplanificacion
        ]);
        return true; 
    } catch (PDOException $e) {
        error_log("Error al actualizar planificación: " . $e->getMessage() . " SQL: " . $sql . " Data: " . json_encode($datos));
        if ($e->errorInfo[1] == 1062) { 
            $_SESSION['mensaje_error_detalle'] = 'Error: Ya existe otra planificación para el contrato y mes seleccionados.';
        } else {
            $_SESSION['mensaje_error_detalle'] = 'Error de BD al actualizar la planificación.';
        }
        return false;
    }
}

/**
 * Actualiza el estado (activo/inactivo) de una planificación.
 * @param int $idplanificacion ID de la planificación.
 * @param int $estado Nuevo estado (1 para activo, 0 para inactivo).
 * @param int $editor_id ID del empleado que realiza la modificación.
 * @return bool True en éxito, false en error.
 */
function actualizarEstadoPlanificacion($idplanificacion, $estado, $editor_id) {
    global $pdo;
    $sql = "UPDATE planificacion SET activo = :activo, editor = :editor, modificado = CURRENT_TIMESTAMP 
            WHERE Idplanificacion = :Idplanificacion_param"; 
    try {
        $stmt = $pdo->prepare($sql);
        return $stmt->execute([':activo' => $estado, ':editor' => $editor_id, ':Idplanificacion_param' => $idplanificacion]);
    } catch (PDOException $e) {
        error_log("Error al actualizar estado de planificación: " . $e->getMessage());
        $_SESSION['mensaje_error_detalle'] = 'Error de BD al cambiar estado: ' . $e->getMessage();
        return false;
    }
}

/**
 * Verifica si ya existe una planificación para un contrato y mes específicos.
 * @param int $idcontratocli ID del contrato.
 * @param string $mes Mes en formato 'YYYY-MM-DD' (siempre día 01).
 * @param int|null $idplanificacion_actual ID de la planificación actual (para excluirla en caso de edición).
 * @return bool True si ya existe, false si no.
 */
function verificarPlanificacionUnica($idcontratocli, $mes_o_fechaplan, $idplanificacion_actual = null) {
    global $pdo;
    $sql = "SELECT COUNT(*) FROM planificacion WHERE idContratoCliente = :idContratoCliente AND fechaplan = :fechaplan_exacto";
    
    if (empty($idcontratocli) || empty($mes_o_fechaplan)) { 
        error_log("Error en verificarPlanificacionUnica: Parámetros idContratoCliente o mes_o_fechaplan están vacíos.");
        $_SESSION['mensaje_error_detalle'] = 'Error interno: Datos insuficientes para verificar unicidad de planificación.';
        return true; 
    }

    $params = [':idContratoCliente' => $idcontratocli, ':fechaplan_exacto' => $mes_o_fechaplan];

    if ($idplanificacion_actual !== null) {
        $sql .= " AND Idplanificacion != :idplanificacion_actual"; 
        $params[':idplanificacion_actual'] = (int)$idplanificacion_actual;
    }

    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $count = $stmt->fetchColumn();
        return $count > 0;
    } catch (PDOException $e) {
        error_log("Error en PDO verificarPlanificacionUnica: " . $e->getMessage() . " SQL: " . $sql . " Params: " . json_encode($params));
        $_SESSION['mensaje_error_detalle'] = 'Error de BD al verificar unicidad.';
        return true; 
    }
}

/**
 * Obtiene los detalles completos de una planificación para el modal de visualización.
 * Incluye datos de la planificación, liquidaciones asociadas y distribución de horas.
 * @param int $idplanificacion ID de la planificación.
 * @return array|false Array con los datos o false en caso de error.
 */
function obtenerDetallesCompletosPlanificacion($idplanificacion) {
    global $pdo;
    $resultado = [
        'planificacion' => null,
        'detalles_liquidaciones' => [],
        'distribucion_horas_por_detalle' => [] 
    ];

    try {
        $resultado['planificacion'] = obtenerPlanificacionPorId($idplanificacion);
        if (!$resultado['planificacion']) {
            $_SESSION['mensaje_error_detalle'] = 'Planificación no encontrada.';
            return false;
        }

        $sql_detalles = "SELECT 
                            dp.iddetalle, dp.idliquidacion, dp.fechaliquidacion, 
                            dp.estado AS estado_detalle_planificacion, dp.cantidahoras AS horas_en_detalle,
                            l.asunto AS asunto_liquidacion, l.idcontratocli AS idcontratocli_liquidacion,
                            l.tema AS id_tema_liquidacion, IFNULL(t.descripcion, 'N/A') AS tema_descripcion_liquidacion,
                            l.estado AS estado_original_liquidacion, l.cantidahoras AS horas_original_liquidacion,
                            l.tipohora AS tipohora_liquidacion
                        FROM detalles_planificacion dp
                        JOIN liquidacion l ON dp.idliquidacion = l.idliquidacion
                        LEFT JOIN tema t ON l.tema = t.idtema
                        WHERE dp.Idplanificacion = :idplanificacion_param 
                        ORDER BY dp.fechaliquidacion DESC, dp.idliquidacion DESC";
        $stmt_detalles = $pdo->prepare($sql_detalles);
        $stmt_detalles->execute([':idplanificacion_param' => $idplanificacion]);
        $detalles_liquidaciones = $stmt_detalles->fetchAll(PDO::FETCH_ASSOC);
        $resultado['detalles_liquidaciones'] = $detalles_liquidaciones;

        $iddetalles_completos = [];
        foreach ($detalles_liquidaciones as $detalle) {
            if ($detalle['estado_detalle_planificacion'] === 'Completo') {
                $iddetalles_completos[] = $detalle['iddetalle'];
            }
        }

        if (!empty($iddetalles_completos)) {
            $placeholders = implode(',', array_fill(0, count($iddetalles_completos), '?'));
            
            $sql_distribucion = "SELECT 
                                    disp.iddistribucionplan, disp.iddetalle, disp.idparticipante, 
                                    emp.nombrecorto AS nombre_participante,
                                    disp.porcentaje, disp.horas_asignadas
                                FROM distribucion_planificacion disp
                                JOIN empleado emp ON disp.idparticipante = emp.idempleado
                                WHERE disp.iddetalle IN ($placeholders)
                                ORDER BY disp.iddetalle, emp.nombrecorto";
            $stmt_distribucion = $pdo->prepare($sql_distribucion);
            $stmt_distribucion->execute($iddetalles_completos);
            $distribuciones_temp = $stmt_distribucion->fetchAll(PDO::FETCH_ASSOC);
            
            foreach($distribuciones_temp as $dist) {
                $resultado['distribucion_horas_por_detalle'][$dist['iddetalle']][] = $dist;
            }
        }
        return $resultado;

    } catch (PDOException $e) {
        error_log("Error en obtenerDetallesCompletosPlanificacion: " . $e->getMessage());
        $_SESSION['mensaje_error_detalle'] = 'Error de BD al obtener detalles completos de planificación: ' . $e->getMessage();
        return false;
    }
}
function ejecutarActualizacionDetalles() {
    global $pdo;
    try {
        $stmt = $pdo->prepare("CALL actualizar_planificacion_existente()");
        $stmt->execute();
        return true;
    } catch (PDOException $e) {
        error_log("Error al ejecutar el procedimiento almacenado: " . $e->getMessage());
        return false;
    }
}

// ----------------- FUNCIONES CRUD PARA ALERTAS NORMATIVAS (Nuevas) -----------------

/**
 * Obtiene todas las alertas normativas, con opción de filtros.
 * @param array $filtros Filtros opcionales (ej. por entidad, fecha).
 * @return array Lista de alertas normativas.
 */
function obtenerAlertasNormativas($filtros = []) {
    global $pdo;
    $sql = "SELECT id, tematica, entidad, tipo_norma, numero_norma, fecha, detalle, url, editor, registrado, modificado 
            FROM alerta_normativa 
            WHERE 1=1";
    $params = [];

    if (!empty($filtros['entidad'])) {
        $sql .= " AND (entidad LIKE :termino_busqueda OR tipo_norma LIKE :termino_busqueda OR tematica LIKE :termino_busqueda)";
        $params[':termino_busqueda'] = "%" . $filtros['entidad'] . "%";
    }
    if (!empty($filtros['fecha_desde'])) {
        $sql .= " AND fecha >= :fecha_desde";
        $params[':fecha_desde'] = $filtros['fecha_desde'];
    }
    if (!empty($filtros['fecha_hasta'])) {
        $sql .= " AND fecha <= :fecha_hasta";
        $params[':fecha_hasta'] = $filtros['fecha_hasta'];
    }

    $sql .= " ORDER BY fecha DESC, id DESC";
    
    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    } catch (PDOException $e) {
        error_log("Error en obtenerAlertasNormativas: " . $e->getMessage());
        return [];
    }
}

/**
 * Obtiene una alerta normativa por su ID.
 * @param int $id ID de la alerta.
 * @return array|false Datos de la alerta o false si no se encuentra.
 */
function obtenerAlertaNormativaPorId($id) {
    global $pdo;
    $sql = "SELECT * FROM alerta_normativa WHERE id = :id";
    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute([':id' => $id]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    } catch (PDOException $e) {
        error_log("Error en obtenerAlertaNormativaPorId: " . $e->getMessage());
        return false;
    }
}

/**
 * Registra una nueva alerta normativa.
 * @param array $datos Datos de la alerta.
 * @return int|false ID de la nueva alerta o false en caso de error.
 */
function registrarAlertaNormativa($datos) {
    global $pdo;
    $sql = "INSERT INTO alerta_normativa (tematica, entidad, tipo_norma, numero_norma, fecha, detalle, url, editor, registrado, modificado) 
            VALUES (:tematica, :entidad, :tipo_norma, :numero_norma, :fecha, :detalle, :url, :editor, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)";
    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            ':tematica' => $datos['tematica'],
            ':entidad' => $datos['entidad'],
            ':tipo_norma' => $datos['tipo_norma'],
            ':numero_norma' => $datos['numero_norma'],
            ':fecha' => $datos['fecha'],
            ':detalle' => $datos['detalle'],
            ':url' => $datos['url'],
            ':editor' => $datos['editor']
        ]);
        return $pdo->lastInsertId();
    } catch (PDOException $e) {
        error_log("Error al registrar alerta normativa: " . $e->getMessage());
        $_SESSION['mensaje_error_detalle'] = 'Error de base de datos al registrar la alerta: ' . $e->getMessage();
        return false;
    }
}

/**
 * Actualiza una alerta normativa existente.
 * @param int $id ID de la alerta a actualizar.
 * @param array $datos Nuevos datos para la alerta.
 * @return bool True en éxito, false en error.
 */
function actualizarAlertaNormativa($id, $datos) {
    global $pdo;
    $sql = "UPDATE alerta_normativa SET 
                tematica = :tematica,
                entidad = :entidad, 
                tipo_norma = :tipo_norma, 
                numero_norma = :numero_norma, 
                fecha = :fecha, 
                detalle = :detalle, 
                url = :url, 
                editor = :editor, 
                modificado = CURRENT_TIMESTAMP 
            WHERE id = :id";
    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            ':tematica' => $datos['tematica'],
            ':entidad' => $datos['entidad'],
            ':tipo_norma' => $datos['tipo_norma'],
            ':numero_norma' => $datos['numero_norma'],
            ':fecha' => $datos['fecha'],
            ':detalle' => $datos['detalle'],
            ':url' => $datos['url'],
            ':editor' => $datos['editor'],
            ':id' => $id
        ]);
        return true;
    } catch (PDOException $e) {
        error_log("Error al actualizar alerta normativa: " . $e->getMessage());
        $_SESSION['mensaje_error_detalle'] = 'Error de base de datos al actualizar la alerta: ' . $e->getMessage();
        return false;
    }
}

/**
 * Elimina una alerta normativa de la base de datos.
 * @param int $id ID de la alerta a eliminar.
 * @return bool True en éxito, false en error.
 */
function eliminarAlertaNormativa($id) {
    global $pdo;
    $sql = "DELETE FROM alerta_normativa WHERE id = :id";
    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute([':id' => $id]);
        return $stmt->rowCount() > 0;
    } catch (PDOException $e) {
        error_log("Error al eliminar alerta normativa: " . $e->getMessage());
        $_SESSION['mensaje_error_detalle'] = 'Error de base de datos al eliminar la alerta. Detalle: ' . $e->getMessage();
        return false;
    }
}

// ----------------- FUNCIONES CRUD PARA BOLETIN REGULATORIO (Nuevas) -----------------

/**
 * Obtiene todos los boletines regulatorios, con opción de filtros.
 * @param array $filtros Filtros opcionales (ej. por año, mes).
 * @return array Lista de boletines.
 */
function obtenerBoletinesRegulatorios($filtros = []) {
    global $pdo;
    $sql = "SELECT b.id, b.anio, b.mes, b.asunto, b.archivo, b.fecha_publicacion, b.fecha_registro, b.editor, e.nombrecorto AS nombre_editor
            FROM boletin_regulatorio b
            LEFT JOIN empleado e ON b.editor = e.idempleado
            WHERE 1=1";
    $params = [];

    if (!empty($filtros['anio'])) {
        $sql .= " AND b.anio = :anio";
        $params[':anio'] = $filtros['anio'];
    }
    if (!empty($filtros['mes'])) {
        $sql .= " AND b.mes = :mes";
        $params[':mes'] = $filtros['mes'];
    }
    if (!empty($filtros['asunto'])) {
        $sql .= " AND b.asunto LIKE :asunto";
        $params[':asunto'] = "%" . $filtros['asunto'] . "%";
    }

    $sql .= " ORDER BY b.anio DESC, FIELD(b.mes, 'Diciembre', 'Noviembre', 'Octubre', 'Septiembre', 'Agosto', 'Julio', 'Junio', 'Mayo', 'Abril', 'Marzo', 'Febrero', 'Enero') DESC";
    
    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    } catch (PDOException $e) {
        error_log("Error en obtenerBoletinesRegulatorios: " . $e->getMessage());
        return [];
    }
}

/**
 * Obtiene un boletín regulatorio por su ID.
 * @param int $id ID del boletín.
 * @return array|false Datos del boletín o false si no se encuentra.
 */
function obtenerBoletinRegulatorioPorId($id) {
    global $pdo;
    $sql = "SELECT * FROM boletin_regulatorio WHERE id = :id";
    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute([':id' => $id]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    } catch (PDOException $e) {
        error_log("Error en obtenerBoletinRegulatorioPorId: " . $e->getMessage());
        return false;
    }
}

/**
 * Registra un nuevo boletín regulatorio.
 * @param array $datos Datos del boletín.
 * @return int|false ID del nuevo boletín o false en caso de error.
 */
function registrarBoletinRegulatorio($datos) {
    global $pdo;
    $sql = "INSERT INTO boletin_regulatorio (anio, mes, asunto, archivo, fecha_publicacion, editor) 
            VALUES (:anio, :mes, :asunto, :archivo, :fecha_publicacion, :editor)";
    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            ':anio' => $datos['anio'],
            ':mes' => $datos['mes'],
            ':asunto' => $datos['asunto'],
            ':archivo' => $datos['archivo'],
            ':fecha_publicacion' => $datos['fecha_publicacion'],
            ':editor' => $datos['editor']
        ]);
        return $pdo->lastInsertId();
    } catch (PDOException $e) {
        error_log("Error al registrar boletín regulatorio: " . $e->getMessage());
        $_SESSION['mensaje_error_detalle'] = 'Error de base de datos al registrar el boletín: ' . $e->getMessage();
        return false;
    }
}

/**
 * Actualiza un boletín regulatorio existente.
 * @param int $id ID del boletín a actualizar.
 * @param array $datos Nuevos datos para el boletín.
 * @return bool True en éxito, false en error.
 */
function actualizarBoletinRegulatorio($id, $datos) {
    global $pdo;
    $sql = "UPDATE boletin_regulatorio SET 
                anio = :anio, 
                mes = :mes, 
                asunto = :asunto,
                archivo = :archivo, 
                fecha_publicacion = :fecha_publicacion, 
                editor = :editor 
            WHERE id = :id";
    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            ':anio' => $datos['anio'],
            ':mes' => $datos['mes'],
            ':asunto' => $datos['asunto'],
            ':archivo' => $datos['archivo'],
            ':fecha_publicacion' => $datos['fecha_publicacion'],
            ':editor' => $datos['editor'],
            ':id' => $id
        ]);
        return true;
    } catch (PDOException $e) {
        error_log("Error al actualizar boletín regulatorio: " . $e->getMessage());
        $_SESSION['mensaje_error_detalle'] = 'Error de base de datos al actualizar el boletín: ' . $e->getMessage();
        return false;
    }
}

/**
 * Elimina un boletín regulatorio de la base de datos.
 * @param int $id ID del boletín a eliminar.
 * @return bool True en éxito, false en error.
 */
function eliminarBoletinRegulatorio($id) {
    global $pdo;
    $sql = "DELETE FROM boletin_regulatorio WHERE id = :id";
    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute([':id' => $id]);
        return $stmt->rowCount() > 0;
    } catch (PDOException $e) {
        error_log("Error al eliminar boletín regulatorio: " . $e->getMessage());
        $_SESSION['mensaje_error_detalle'] = 'Error de base de datos al eliminar el boletín. Detalle: ' . $e->getMessage();
        return false;
    }
}

?>