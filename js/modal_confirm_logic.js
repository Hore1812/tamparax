document.addEventListener('DOMContentLoaded', function () {
    const form = document.getElementById('formLiquidacion');
    if (form) {
        form.addEventListener('submit', function (event) {
            event.preventDefault();
            const modal = new bootstrap.Modal(document.getElementById('modalConfirmarGuardado'));
            modal.show();
        });
    }

    const confirmBtn = document.getElementById('btnConfirmarGuardarSubmit');
    if (confirmBtn) {
        confirmBtn.addEventListener('click', function () {
            if (form) {
                form.submit();
            }
        });
    }

    // Lógica para mostrar modal de éxito o error si existe un mensaje en la sesión
    const successMessage = document.getElementById('successMessage');
    if (successMessage && successMessage.value) {
        const modalExito = new bootstrap.Modal(document.getElementById('modalExito'));
        document.getElementById('mensajeExito').textContent = successMessage.value;
        modalExito.show();
    }

    const errorMessage = document.getElementById('errorMessage');
    if (errorMessage && errorMessage.value) {
        const modalError = new bootstrap.Modal(document.getElementById('modalError'));
        document.getElementById('mensajeError').textContent = errorMessage.value;
        modalError.show();
    }
});
