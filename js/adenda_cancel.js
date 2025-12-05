
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
            const isEditing = document.getElementById('formAdenda').querySelector('input[name="accion"]').value === 'editar';
            const message = isEditing ? '¿Está seguro que desea cancelar la edición de la adenda? Los datos no guardados se perderán.' : '¿Está seguro que desea cancelar el registro de la adenda? Los datos no guardados se perderán.';

            if (modalTitle) modalTitle.textContent = 'Confirmar Cancelación';
            if (modalBody) modalBody.innerHTML = message;

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
