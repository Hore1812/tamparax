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
        <h1 class="text-primary">Registrar Nueva Alerta Normativa</h1>
        <a href="alertas_normativas.php" class="btn btn-secondary">
            <i class="fas fa-arrow-left"></i> Volver al Listado
        </a>
    </div>
    
    <div class="card">
        <div class="card-body">
            <form id="formRegistrarAlerta" method="POST" action="guardar_alerta.php">
                
                <div class="row mb-3">
                    <div class="col-md-3">
                        <label for="tematica" class="form-label">Temática</label>
                        <input type="text" id="tematica" name="tematica" class="form-control">
                    </div>
                    <div class="col-md-3">
                        <label for="entidad" class="form-label">Entidad <span class="text-danger">*</span></label>
                        <input type="text" id="entidad" name="entidad" class="form-control" required>
                    </div>
                    <div class="col-md-3">
                        <label for="tipo_norma" class="form-label">Tipo de Norma <span class="text-danger">*</span></label>
                        <input type="text" id="tipo_norma" name="tipo_norma" class="form-control" required>
                    </div>
                     <div class="col-md-3">
                        <label for="numero_norma" class="form-label">Número de Norma <span class="text-danger">*</span></label>
                        <input type="text" id="numero_norma" name="numero_norma" class="form-control" required>
                    </div>
                </div>
                
                <div class="row mb-3">
                    <div class="col-md-3">
                        <label for="fecha" class="form-label">Fecha de Publicación <span class="text-danger">*</span></label>
                        <input type="date" id="fecha" name="fecha" class="form-control" required>
                    </div>
                    <div class="col-md-9">
                        <label for="url" class="form-label">URL del Documento</label>
                        <input type="url" id="url" name="url" class="form-control" placeholder="https://ejemplo.com/norma.pdf">
                    </div>
                </div>
                
                <div class="mb-3">
                    <label for="detalle" class="form-label">Detalle / Resumen <span class="text-danger">*</span></label>
                    <textarea id="detalle" name="detalle" class="form-control" rows="5" required></textarea>
                </div>
                
                <div class="d-flex justify-content-end mt-4">
                    <button type="button" class="btn btn-secondary me-2" data-bs-toggle="modal" data-bs-target="#modalConfirmarGuardado" id="btn-cancelar">
                        <i class="fas fa-times"></i> Cancelar
                    </button>
                    <button type="submit" class="btn btn-primary">
                        <i class="fas fa-save"></i> Guardar Alerta
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<?php require_once 'includes/footer.php'; ?>

<script>
document.addEventListener('DOMContentLoaded', function() {
    const formRegistrar = document.getElementById('formRegistrarAlerta');
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
            modalBody.textContent = '¿Está seguro de que desea guardar esta nueva alerta normativa?';
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
            modalBody.textContent = '¿Está seguro de que desea cancelar? No se guardará la nueva alerta.';
            btnConfirmarSubmit.textContent = 'Sí, cancelar';
            btnConfirmarSubmit.className = 'btn btn-danger';

            const modalInstance = bootstrap.Modal.getOrCreateInstance(modalConfirmar);
            modalInstance.show();

            $(btnConfirmarSubmit).off('click').on('click', function() {
                window.location.href = 'alertas_normativas.php';
            });
        });
    }
    
});
</script>
