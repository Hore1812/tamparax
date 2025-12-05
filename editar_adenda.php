<?php
$page_title = "Editar Adenda";
require_once 'includes/header.php';
require_once 'funciones.php';

// Validar ID de adenda
if (!isset($_GET['id']) || !filter_var($_GET['id'], FILTER_VALIDATE_INT)) {
    echo "<div class='container mt-4'><div class='alert alert-danger'>ID de adenda no válido.</div></div>";
    require_once 'includes/footer.php';
    exit;
}
$idAdenda = (int)$_GET['id'];

// Obtener datos de la adenda
$sqlAdenda = "SELECT * FROM adendacliente WHERE idadendacli = ?";
$stmtAdenda = $pdo->prepare($sqlAdenda);
$stmtAdenda->execute([$idAdenda]);
$adenda = $stmtAdenda->fetch(PDO::FETCH_ASSOC);

if (!$adenda) {
    echo "<div class='container mt-4'><div class='alert alert-danger'>No se encontró la adenda con ID $idAdenda.</div></div>";
    require_once 'includes/footer.php';
    exit;
}

$idContrato = $adenda['idcontratocli'];

// Obtener datos del contrato original (sin aplicar adendas) para los placeholders
$sqlContrato = "SELECT cc.*, c.nombrecomercial as nombre_cliente 
                FROM contratocliente cc
                JOIN cliente c ON cc.idcliente = c.idcliente
                WHERE cc.idcontratocli = ?";
$stmtContrato = $pdo->prepare($sqlContrato);
$stmtContrato->execute([$idContrato]);
$contrato = $stmtContrato->fetch(PDO::FETCH_ASSOC);

if (!$contrato) {
    // Esto es improbable si la adenda existe, pero es una buena práctica de validación
    echo "<div class='container mt-4'><div class='alert alert-danger'>No se encontró el contrato asociado con ID $idContrato.</div></div>";
    require_once 'includes/footer.php';
    exit;
}
?>

<div class="container mt-4">
    <div class="card">
        <div class="card-header">
            <h3>Editar Adenda #<?php echo htmlspecialchars($idAdenda); ?> para Contrato #<?php echo htmlspecialchars($idContrato); ?></h3>
            <p class="mb-0"><strong>Cliente:</strong> <?php echo htmlspecialchars($contrato['nombre_cliente'] ?? 'N/A'); ?></p>
            <p><strong>Contrato:</strong> <?php echo htmlspecialchars($contrato['descripcion']); ?></p>
        </div>
        <div class="card-body">
            <form id="formAdenda" action="procesar_adenda.php" method="POST" enctype="multipart/form-data">
                <input type="hidden" name="idcontratocli" value="<?php echo htmlspecialchars($idContrato); ?>">
                <input type="hidden" name="idadendacli" value="<?php echo htmlspecialchars($idAdenda); ?>">
                <input type="hidden" name="accion" value="editar">

                <fieldset class="mb-3">
                    <legend>Información Principal de la Adenda</legend>
                    <div class="mb-3">
                        <label for="descripcion" class="form-label">Descripción de la Adenda <span class="text-danger">*</span></label>
                        <textarea class="form-control" id="descripcion" name="descripcion" rows="3" required maxlength="500"><?php echo htmlspecialchars($adenda['descripcion']); ?></textarea>
                    </div>
                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label for="fechainicio" class="form-label">Fecha de Inicio <span class="text-danger">*</span></label>
                            <input type="date" class="form-control" id="fechainicio" name="fechainicio" value="<?php echo htmlspecialchars($adenda['fechainicio']); ?>" required>
                        </div>
                        <div class="col-md-6 mb-3">
                            <label for="fechafin" class="form-label">Fecha de Fin <span class="text-danger">*</span></label>
                            <input type="date" class="form-control" id="fechafin" name="fechafin" value="<?php echo htmlspecialchars($adenda['fechafin']); ?>" required>
                        </div>
                    </div>
                </fieldset>

                <fieldset class="mb-3">
                    <legend>Modificaciones (dejar en blanco para usar valores del contrato original)</legend>
                    <div class="row">
                        <div class="col-md-4 mb-3">
                            <label for="horasfijasmes" class="form-label">Horas Fijas/Mes</label>
                            <input type="number" class="form-control" id="horasfijasmes" name="horasfijasmes" min="0" value="<?php echo htmlspecialchars($adenda['horasfijasmes'] ?? ''); ?>" placeholder="<?php echo htmlspecialchars($contrato['horasfijasmes']); ?>">
                        </div>
                        <div class="col-md-4 mb-3">
                            <label for="costohorafija" class="form-label">Costo por Hora Fija</label>
                            <input type="number" class="form-control" id="costohorafija" name="costohorafija" step="0.01" min="0" value="<?php echo htmlspecialchars($adenda['costohorafija'] ?? ''); ?>" placeholder="<?php echo htmlspecialchars($contrato['costohorafija']); ?>">
                        </div>
                         <div class="col-md-4 mb-3">
                            <label for="montofijomes" class="form-label">Monto Fijo Mensual</label>
                            <input type="number" class="form-control" id="montofijomes" name="montofijomes" step="0.01" min="0" value="<?php echo htmlspecialchars($adenda['montofijomes'] ?? ''); ?>" placeholder="<?php echo htmlspecialchars($contrato['montofijomes']); ?>">
                        </div>
                    </div>
                    <div class="row">
                        <div class="col-md-4 mb-3">
                            <label for="mesescontrato" class="form-label">Meses de Contrato</label>
                            <input type="number" class="form-control" id="mesescontrato" name="mesescontrato" min="1" value="<?php echo htmlspecialchars($adenda['mesescontrato'] ?? ''); ?>" placeholder="<?php echo htmlspecialchars($contrato['mesescontrato']); ?>">
                        </div>
                        <div class="col-md-4 mb-3">
                            <label for="totalhorasfijas" class="form-label">Total Horas Fijas</label>
                            <input type="number" class="form-control" id="totalhorasfijas" name="totalhorasfijas" min="0" value="<?php echo htmlspecialchars($adenda['totalhorasfijas'] ?? ''); ?>" placeholder="<?php echo htmlspecialchars($contrato['totalhorasfijas']); ?>">
                        </div>
                         <div class="col-md-4 mb-3">
                            <label for="costohoraextra" class="form-label">Costo Hora Extra</label>
                            <input type="number" class="form-control" id="costohoraextra" name="costohoraextra" step="0.01" min="0" value="<?php echo htmlspecialchars($adenda['costohoraextra'] ?? ''); ?>" placeholder="<?php echo htmlspecialchars($contrato['costohoraextra']); ?>">
                        </div>
                    </div>
                     <div class="row">
                        <div class="col-md-6 mb-3">
                            <label for="tipobolsa" class="form-label">Tipo de Bolsa / Adicional</label>
                            <input type="text" class="form-control" id="tipobolsa" name="tipobolsa" maxlength="50" value="<?php echo htmlspecialchars($adenda['tipobolsa'] ?? ''); ?>" placeholder="<?php echo htmlspecialchars($contrato['tipobolsa']); ?>">
                        </div>
                    </div>
                </fieldset>

                <fieldset class="mb-3">
                    <legend>Planificación</legend>
                     <div class="row">
                        <div class="col-md-6 mb-3">
                            <label for="planmontomes" class="form-label">Plan Monto/Mes (Facturación)</label>
                            <input type="number" class="form-control" id="planmontomes" name="planmontomes" step="0.01" min="0" value="<?php echo htmlspecialchars($adenda['planmontomes'] ?? ''); ?>" placeholder="<?php echo htmlspecialchars($contrato['planmontomes']); ?>">
                        </div>
                        <div class="col-md-6 mb-3">
                            <label for="planhorasextrasmes" class="form-label">Plan Horas Extra/Mes</label>
                            <input type="number" class="form-control" id="planhorasextrasmes" name="planhorasextrasmes" min="0" value="<?php echo htmlspecialchars($adenda['planhorasextrasmes'] ?? ''); ?>" placeholder="<?php echo htmlspecialchars($contrato['planhoraextrames']); ?>">
                        </div>
                    </div>
                </fieldset>

                 <div class="mb-3">
                    <label for="comentarios" class="form-label">Comentarios</label>
                    <textarea class="form-control" id="comentarios" name="comentarios" rows="3" maxlength="500"><?php echo htmlspecialchars($adenda['comentarios'] ?? ''); ?></textarea>
                </div>
                
                <div class="mb-3">
                    <label for="pdf_adenda" class="form-label">Archivo PDF de la Adenda</label>
                    <p class="form-text">
                        Archivo actual: 
                        <?php if (!empty($adenda['rutaarchivo'])): ?>
                            <a href="<?php echo htmlspecialchars($adenda['rutaarchivo']); ?>" target="_blank"><?php echo basename(htmlspecialchars($adenda['rutaarchivo'])); ?></a>
                        <?php else: ?>
                            Ninguno
                        <?php endif; ?>
                        <br>
                        Subir un nuevo archivo reemplazará el actual.
                    </p>
                    <input class="form-control" type="file" id="pdf_adenda" name="pdf_adenda" accept=".pdf">
                </div>
                
                <div class="mt-4 text-end">
                    <button type="button" id="btnCancelarAdenda" class="btn btn-secondary me-2">Cancelar</button>
                    <button type="submit" class="btn btn-primary">Actualizar Adenda</button>
                </div>
            </form>
        </div>
    </div>
</div>

<?php 
require_once 'includes/footer.php'; 
?>
<script src="js/adenda_cancel.js"></script>
