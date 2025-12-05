<?php
require_once 'includes/header.php';
require_once 'funciones.php';

if (!isset($_SESSION['tipo_usuario']) || $_SESSION['tipo_usuario'] != 1) {
    header('Location: index.php');
    exit;
}

$id_boletin = filter_input(INPUT_GET, 'id', FILTER_VALIDATE_INT);
if (!$id_boletin) {
    header('Location: boletin_regulatorio.php');
    exit;
}

$boletin = obtenerBoletinRegulatorioPorId($id_boletin);
if (!$boletin) {
    $_SESSION['mensaje_error'] = 'Boletín no encontrado.';
    header('Location: boletin_regulatorio.php');
    exit;
}

$meses = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"];
?>

<div class="container mt-4">
    <h1 class="text-primary">Editar Boletín Regulatorio</h1>

    <?php if (isset($_SESSION['mensaje_error'])): ?>
        <div class="alert alert-danger">
             <?= $_SESSION['mensaje_error'] ?>
        </div>
        <?php unset($_SESSION['mensaje_error']); ?>
    <?php endif; ?>

    <div class="card">
        <div class="card-body">
            <form action="actualizar_boletin.php" method="POST" enctype="multipart/form-data">
                <input type="hidden" name="id" value="<?= $id_boletin ?>">
                <input type="hidden" name="archivo_actual" value="<?= htmlspecialchars($boletin['archivo']) ?>">
                <div class="row">
                    <div class="col-md-6 mb-3">
                        <label for="anio" class="form-label">Año <span class="text-danger">*</span></label>
                        <input type="number" class="form-control" id="anio" name="anio" value="<?= htmlspecialchars($boletin['anio']) ?>" required>
                    </div>
                    <div class="col-md-6 mb-3">
                        <label for="mes" class="form-label">Mes <span class="text-danger">*</span></label>
                        <select class="form-select" id="mes" name="mes" required>
                            <?php foreach ($meses as $m): ?>
                                <option value="<?= $m ?>" <?= ($boletin['mes'] == $m) ? 'selected' : '' ?>><?= $m ?></option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                </div>
                <div class="mb-3">
                    <label for="asunto" class="form-label">Asunto <span class="text-danger">*</span></label>
                    <input type="text" class="form-control" id="asunto" name="asunto" value="<?= htmlspecialchars($boletin['asunto'] ?? '') ?>" required>
                </div>
                <div class="mb-3">
                    <label for="fecha_publicacion" class="form-label">Fecha de Publicación <span class="text-danger">*</span></label>
                    <input type="date" class="form-control" id="fecha_publicacion" name="fecha_publicacion" value="<?= htmlspecialchars($boletin['fecha_publicacion']) ?>" required>
                </div>
                <div class="mb-3">
                    <label for="archivo" class="form-label">Archivo del Boletín (PDF)</label>
                    <p class="form-text">Archivo actual: <a href="PDF/boletines/<?= htmlspecialchars($boletin['archivo']) ?>" target="_blank"><?= htmlspecialchars($boletin['archivo']) ?></a></p>
                    <input class="form-control" type="file" id="archivo" name="archivo" accept=".pdf">
                    <small class="form-text text-muted">Seleccione un archivo solo si desea reemplazar el actual.</small>
                </div>
                <div class="d-flex justify-content-end gap-2">
                    <button type="button" class="btn btn-secondary" id="btn-cancelar">Cancelar</button>
                    <button type="submit" class="btn btn-primary">Actualizar Boletín</button>
                </div>
            </form>
        </div>
    </div>
</div>

<?php require_once 'includes/footer.php'; ?>

<script>
document.addEventListener('DOMContentLoaded', function() {
    const form = document.querySelector('form');
    const btnCancelar = document.getElementById('btn-cancelar');
    const modalConfirmar = document.getElementById('modalConfirmarGuardado');

    if (form && modalConfirmar) {
        form.addEventListener('submit', function(e) {
            e.preventDefault();
            const modalTitle = modalConfirmar.querySelector('.modal-title');
            const modalBody = modalConfirmar.querySelector('.modal-body');
            const btnConfirmarSubmit = modalConfirmar.querySelector('#btnConfirmarGuardarSubmit');

            modalTitle.textContent = 'Confirmar Actualización';
            modalBody.textContent = '¿Está seguro de que desea actualizar este boletín?';
            btnConfirmarSubmit.textContent = 'Sí, actualizar';
            btnConfirmarSubmit.className = 'btn btn-primary';

            const modalInstance = new bootstrap.Modal(modalConfirmar);
            modalInstance.show();

            btnConfirmarSubmit.onclick = function() {
                form.submit();
            }
        });
    }

    if (btnCancelar && modalConfirmar) {
        btnCancelar.addEventListener('click', function() {
            const modalTitle = modalConfirmar.querySelector('.modal-title');
            const modalBody = modalConfirmar.querySelector('.modal-body');
            const btnConfirmarSubmit = modalConfirmar.querySelector('#btnConfirmarGuardarSubmit');

            modalTitle.textContent = 'Confirmar Cancelación';
            modalBody.textContent = '¿Está seguro de que desea cancelar? No se guardarán los cambios.';
            btnConfirmarSubmit.textContent = 'Sí, cancelar';
            btnConfirmarSubmit.className = 'btn btn-danger';

            const modalInstance = new bootstrap.Modal(modalConfirmar);
            modalInstance.show();

            btnConfirmarSubmit.onclick = function() {
                window.location.href = 'boletin_regulatorio.php';
            }
        });
    }
});
</script>
