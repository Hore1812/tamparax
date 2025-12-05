<?php
require_once 'includes/header.php';
require_once 'funciones.php';

// Solo los administradores pueden registrar
if (!isset($_SESSION['tipo_usuario']) || $_SESSION['tipo_usuario'] != 1) {
    header('Location: index.php');
    exit;
}
?>

<div class="container-fluid mt-4">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h1 class="text-primary">Registrar Nuevo Anuncio</h1>
        <a href="anuncios.php" class="btn btn-secondary">
            <i class="fas fa-arrow-left"></i> Volver al Listado
        </a>
    </div>
    
    <div class="card">
        <div class="card-body">
            <form id="formRegistrarAnuncio" method="POST" action="guardar_anuncio.php" enctype="multipart/form-data">
                
                <div class="row mb-3">
                    <div class="col-md-6">
                        <label for="fechainicio" class="form-label">Fecha de Inicio <span class="text-danger">*</span></label>
                        <input type="date" id="fechainicio" name="fechainicio" class="form-control" required>
                    </div>
                    <div class="col-md-6">
                        <label for="fechafin" class="form-label">Fecha de Fin <span class="text-danger">*</span></label>
                        <input type="date" id="fechafin" name="fechafin" class="form-control" required>
                    </div>
                </div>

                <div class="mb-3">
                    <label for="rutaarchivo" class="form-label">Imagen del Anuncio <span class="text-danger">*</span></label>
                    <input type="file" id="rutaarchivo" name="rutaarchivo" class="form-control" accept="image/*" required>
                </div>
                
                <div class="mb-3">
                    <label for="comentario" class="form-label">Comentario</label>
                    <textarea id="comentario" name="comentario" class="form-control" rows="3"></textarea>
                </div>
                
                <div class="d-flex justify-content-end mt-4">
                    <button type="button" class="btn btn-secondary me-2" data-bs-toggle="modal" data-bs-target="#modalConfirmarGuardado" id="btn-cancelar">
                        <i class="fas fa-times"></i> Cancelar
                    </button>
                    <button type="submit" class="btn btn-primary">
                        <i class="fas fa-save"></i> Guardar Anuncio
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<?php require_once 'includes/footer.php'; ?>

<script>
document.addEventListener('DOMContentLoaded', function() {
    const formRegistrar = document.getElementById('formRegistrarAnuncio');
    const modalConfirmar = document.getElementById('modalConfirmarGuardado');

    if(formRegistrar && modalConfirmar) {
        formRegistrar.addEventListener('submit', function(e) {
            e.preventDefault();
            
            if (!formRegistrar.checkValidity()) {
                formRegistrar.classList.add('was-validated');
                return;
            }

            const modalTitle = modalConfirmar.querySelector('.modal-title');
            const modalBody = modalConfirmar.querySelector('.modal-body');
            const btnConfirmarSubmit = modalConfirmar.querySelector('#btnConfirmarGuardarSubmit');

            modalTitle.textContent = 'Confirmar Registro';
            modalBody.textContent = '¿Está seguro de que desea guardar este nuevo anuncio?';
            btnConfirmarSubmit.textContent = 'Sí, guardar';
            btnConfirmarSubmit.className = 'btn btn-primary';

            const modalInstance = bootstrap.Modal.getOrCreateInstance(modalConfirmar);
            modalInstance.show();

            $(btnConfirmarSubmit).off('click').on('click', function() {
                formRegistrar.submit();
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
            modalBody.textContent = '¿Está seguro de que desea cancelar? No se guardará el nuevo anuncio.';
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
