<?php
require_once 'includes/header.php';
require_once 'funciones.php';

// Solo los administradores pueden editar
if (!isset($_SESSION['tipo_usuario']) || $_SESSION['tipo_usuario'] != 1) {
    header('Location: index.php');
    exit;
}

if (!isset($_GET['id']) || !is_numeric($_GET['id'])) {
    $_SESSION['mensaje_error'] = "ID de anuncio no válido.";
    header('Location: anuncios.php');
    exit;
}

$idAnuncio = $_GET['id'];
$anuncio = obtenerAnuncioPorId($idAnuncio);

if (!$anuncio) {
    $_SESSION['mensaje_error'] = "Anuncio no encontrado.";
    header('Location: anuncios.php');
    exit;
}
?>

<div class="container-fluid mt-4">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h1 class="text-primary">Editar Anuncio</h1>
        <a href="anuncios.php" class="btn btn-secondary">
            <i class="fas fa-arrow-left"></i> Volver al Listado
        </a>
    </div>

    <div class="card">
        <div class="card-body">
            <form id="formEditarAnuncio" method="POST" action="actualizar_anuncio.php" enctype="multipart/form-data">
                <input type="hidden" name="idanuncio" value="<?= htmlspecialchars($anuncio['idanuncio']) ?>">
                
                <div class="row mb-3">
                    <div class="col-md-4">
                        <label for="fechainicio" class="form-label">Fecha de Inicio <span class="text-danger">*</span></label>
                        <input type="date" id="fechainicio" name="fechainicio" class="form-control" value="<?= htmlspecialchars($anuncio['fechainicio']) ?>" required>
                    </div>
                    <div class="col-md-4">
                        <label for="fechafin" class="form-label">Fecha de Fin <span class="text-danger">*</span></label>
                        <input type="date" id="fechafin" name="fechafin" class="form-control" value="<?= htmlspecialchars($anuncio['fechafin']) ?>" required>
                    </div>
                    <div class="col-md-4">
                        <label for="rutaarchivo" class="form-label">Nueva Imagen (opcional)</label>
                        <input type="file" id="rutaarchivo" name="rutaarchivo" class="form-control" accept="image/*">
                        <small class="form-text text-muted">Deje en blanco si no desea cambiar la imagen actual.</small>
                    </div>
                </div>

                <div class="mb-3">
                    <label for="comentario" class="form-label">Comentario <span class="text-danger">*</span></label>
                    <textarea id="comentario" name="comentario" class="form-control" rows="3" required><?= htmlspecialchars($anuncio['comentario']) ?></textarea>
                </div>
                
                <div class="mb-3">
                    <p>Imagen Actual:</p>
                    <img src="<?= htmlspecialchars($anuncio['rutaarchivo']) ?>" alt="Anuncio Actual" width="200">
                </div>

                <div class="d-flex justify-content-end mt-4">
                    <button type="button" class="btn btn-secondary me-2" data-bs-toggle="modal" data-bs-target="#modalConfirmarGuardado" id="btn-cancelar">
                        <i class="fas fa-times"></i> Cancelar
                    </button>
                    <button type="submit" class="btn btn-primary">
                        <i class="fas fa-save"></i> Guardar Cambios
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<?php require_once 'includes/footer.php'; ?>

<script>
document.addEventListener('DOMContentLoaded', function() {
    const formEditar = document.getElementById('formEditarAnuncio');
    const modalConfirmar = document.getElementById('modalConfirmarGuardado');

    if(formEditar && modalConfirmar) {
        formEditar.addEventListener('submit', function(e) {
            e.preventDefault();
            
            if (!formEditar.checkValidity()) {
                formEditar.classList.add('was-validated');
                return;
            }

            const modalTitle = modalConfirmar.querySelector('.modal-title');
            const modalBody = modalConfirmar.querySelector('.modal-body');
            const btnConfirmarSubmit = modalConfirmar.querySelector('#btnConfirmarGuardarSubmit');

            modalTitle.textContent = 'Confirmar Actualización';
            modalBody.textContent = '¿Está seguro de que desea guardar los cambios en este anuncio?';
            btnConfirmarSubmit.textContent = 'Sí, actualizar';
            btnConfirmarSubmit.className = 'btn btn-primary';

            const modalInstance = bootstrap.Modal.getOrCreateInstance(modalConfirmar);
            modalInstance.show();

            $(btnConfirmarSubmit).off('click').on('click', function() {
                formEditar.submit();
            });
        });
    }

    const btnCancelar = document.getElementById('btn-cancelar');
    if (btnCancelar && modalConfirmar) {
        btnCancelar.addEventListener('click', function() {
            const modalTitle = modalConfirmar.querySelector('.modal-title');
            const modalBody = modalConfirmar.querySelector('.modal-body');
            const btnConfirmarSubmit = modalConfirmar.querySelector('#btnConfirmarGuardarSubmit');

            modalTitle.textContent = 'Confirmar Cancelación';
            modalBody.textContent = '¿Está seguro de que desea cancelar? No se guardarán los cambios realizados.';
            btnConfirmarSubmit.textContent = 'Sí, cancelar';
            btnConfirmarSubmit.className = 'btn btn-danger';

            const modalInstance = bootstrap.Modal.getOrCreateInstance(modalConfirmar);
            modalInstance.show();

            $(btnConfirmarSubmit).off('click').on('click', function() {
                window.location.href = 'anuncios.php';
            });
        });
    }
    
});
</script>
