<?php
$page_title = "Registrar Nueva Adenda";
require_once 'includes/header.php';
require_once 'funciones.php';

if (!isset($_GET['idcontrato']) || !filter_var($_GET['idcontrato'], FILTER_VALIDATE_INT)) {
    echo "<div class='container mt-4'><div class='alert alert-danger'>ID de contrato no válido.</div></div>";
    require_once 'includes/footer.php';
    exit;
}

$idContrato = (int)$_GET['idcontrato'];

$sqlContrato = "SELECT cc.*, c.nombrecomercial as nombre_cliente, e.nombrecorto as nombre_lider
                FROM vista_contratocliente_activo cc
                JOIN cliente c ON cc.idcliente = c.idcliente
                JOIN empleado e ON cc.lider = e.idempleado
                WHERE cc.idcontratocli = ?";
$stmtContrato = $pdo->prepare($sqlContrato);
$stmtContrato->execute([$idContrato]);
$contrato = $stmtContrato->fetch(PDO::FETCH_ASSOC);

if (!$contrato) {
    echo "<div class='container mt-4'><div class='alert alert-danger'>No se encontró el contrato con ID $idContrato.</div></div>";
    require_once 'includes/footer.php';
    exit;
}
?>

<div class="container mt-4">
    <div class="card">
        <div class="card-header">
            <h3>Registrar Nueva Adenda para Contrato #<?php echo htmlspecialchars($idContrato); ?></h3>
            <p class="mb-0"><strong>Cliente:</strong> <?php echo htmlspecialchars($contrato['nombre_cliente'] ?? 'N/A'); ?></p>
            <p><strong>Contrato:</strong> <?php echo htmlspecialchars($contrato['descripcion']); ?></p>
        </div>
        <div class="card-body">
            <form id="formAdenda" action="procesar_adenda.php" method="POST" enctype="multipart/form-data">
                <input type="hidden" name="idcontratocli" value="<?php echo htmlspecialchars($idContrato); ?>">
                <input type="hidden" name="accion" value="crear">

                <fieldset class="mb-3">
                    <legend>Información Principal de la Adenda</legend>
                    <div class="mb-3">
                        <label for="descripcion" class="form-label">Descripción de la Adenda <span class="text-danger">*</span></label>
                        <textarea class="form-control" id="descripcion" name="descripcion" rows="3" required maxlength="500"></textarea>
                    </div>
                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label for="fechainicio" class="form-label">Fecha de Inicio <span class="text-danger">*</span></label>
                            <input type="date" class="form-control" id="fechainicio" name="fechainicio" required>
                        </div>
                        <div class="col-md-6 mb-3">
                            <label for="fechafin" class="form-label">Fecha de Fin <span class="text-danger">*</span></label>
                            <input type="date" class="form-control" id="fechafin" name="fechafin" required>
                        </div>
                    </div>
                </fieldset>

                <fieldset class="mb-3">
                    <legend>Modificaciones Opcionales (dejar en blanco para mantener valores del contrato)</legend>
                    <div class="row">
                        <div class="col-md-4 mb-3">
                            <label for="horasfijasmes" class="form-label">Horas Fijas/Mes</label>
                            <input type="number" class="form-control" id="horasfijasmes" name="horasfijasmes" min="0" placeholder="<?php echo htmlspecialchars($contrato['horasfijasmes']); ?>">
                        </div>
                        <div class="col-md-4 mb-3">
                            <label for="costohorafija" class="form-label">Costo por Hora Fija</label>
                            <input type="number" class="form-control" id="costohorafija" name="costohorafija" step="0.01" min="0" placeholder="<?php echo htmlspecialchars($contrato['costohorafija']); ?>">
                        </div>
                         <div class="col-md-4 mb-3">
                            <label for="montofijomes" class="form-label">Monto Fijo Mensual</label>
                            <input type="number" class="form-control" id="montofijomes" name="montofijomes" step="0.01" min="0" placeholder="<?php echo htmlspecialchars($contrato['montofijomes']); ?>">
                        </div>
                    </div>
                    <div class="row">
                        <div class="col-md-4 mb-3">
                            <label for="mesescontrato" class="form-label">Meses de Contrato</label>
                            <input type="number" class="form-control" id="mesescontrato" name="mesescontrato" min="1" placeholder="<?php echo htmlspecialchars($contrato['mesescontrato']); ?>">
                        </div>
                        <div class="col-md-4 mb-3">
                            <label for="totalhorasfijas" class="form-label">Total Horas Fijas</label>
                            <input type="number" class="form-control" id="totalhorasfijas" name="totalhorasfijas" min="0" placeholder="<?php echo htmlspecialchars($contrato['totalhorasfijas']); ?>">
                        </div>
                         <div class="col-md-4 mb-3">
                            <label for="costohoraextra" class="form-label">Costo Hora Extra</label>
                            <input type="number" class="form-control" id="costohoraextra" name="costohoraextra" step="0.01" min="0" placeholder="<?php echo htmlspecialchars($contrato['costohoraextra']); ?>">
                        </div>
                    </div>
                     <div class="row">
                        <div class="col-md-6 mb-3">
                            <label for="tipobolsa" class="form-label">Tipo de Bolsa / Adicional</label>
                            <select class="form-select" id="tipobolsa" name="tipobolsa">
                                <option value="">Seleccionar...</option>
                                <option value="Mensual">Mensual</option>
                                <option value="Anual">Anual</option>
                            </select>
                        </div>
                    </div>
                </fieldset>

                <fieldset class="mb-3">
                    <legend>Planificación (Opcional)</legend>
                     <div class="row">
                        <div class="col-md-6 mb-3">
                            <label for="planmontomes" class="form-label">Plan Monto/Mes (Facturación)</label>
                            <input type="number" class="form-control" id="planmontomes" name="planmontomes" step="0.01" min="0" placeholder="<?php echo htmlspecialchars($contrato['planmontomes']); ?>">
                        </div>
                        <div class="col-md-6 mb-3">
                            <label for="planhorasextrasmes" class="form-label">Plan Horas Extra/Mes</label>
                            <input type="number" class="form-control" id="planhorasextrasmes" name="planhorasextrasmes" min="0" placeholder="<?php echo htmlspecialchars($contrato['planhoraextrames']); ?>">
                        </div>
                    </div>
                </fieldset>

                 <div class="mb-3">
                    <label for="comentarios" class="form-label">Comentarios</label>
                    <textarea class="form-control" id="comentarios" name="comentarios" rows="3" maxlength="500"></textarea>
                </div>

                <div class="mb-3">
                    <label for="pdf_adenda" class="form-label">Archivo PDF de la Adenda <span class="text-danger">*</span></label>
                    <input class="form-control" type="file" id="pdf_adenda" name="pdf_adenda" accept=".pdf" required>
                </div>

                <div class="mt-4 text-end">
                    <button type="button" id="btnCancelarAdenda" class="btn btn-secondary me-2">Cancelar</button>
                    <button type="submit" class="btn btn-primary">Guardar Adenda</button>
                </div>
            </form>
        </div>
    </div>
</div>

<?php
require_once 'includes/footer.php';
?>

<script>
document.addEventListener('DOMContentLoaded', function() {
    // Lógica para el botón Cancelar
    const btnCancelarAdenda = document.getElementById('btnCancelarAdenda');
    const modalCancelarElement = document.getElementById('modalCancelar');
    let modalCancelarInstance = null;
    if (modalCancelarElement) {
        modalCancelarInstance = new bootstrap.Modal(modalCancelarElement);
    }

    if (btnCancelarAdenda && modalCancelarInstance) {
        btnCancelarAdenda.addEventListener('click', function() {
            const modalTitle = modalCancelarElement.querySelector('.modal-title');
            const modalBody = modalCancelarElement.querySelector('.modal-body');
            const modalFooter = modalCancelarElement.querySelector('.modal-footer');

            if (modalTitle) modalTitle.textContent = 'Confirmar Cancelación';
            if (modalBody) modalBody.innerHTML = '¿Está seguro que desea cancelar el registro de la adenda? Los datos no guardados se perderán.';

            if(modalFooter) {
                modalFooter.innerHTML = `
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">No</button>
                    <button type="button" id="btnModalConfirmarCancelacionAdenda" class="btn btn-danger">Sí, cancelar</button>
                `;
                const btnConfirmarSi = modalFooter.querySelector('#btnModalConfirmarCancelacionAdenda');
                if(btnConfirmarSi){
                     btnConfirmarSi.addEventListener('click', function() {
                        window.location.href = 'contratos_clientes.php';
                    }, { once: true });
                }
            }
            modalCancelarInstance.show();
        });
    }
});
</script>
