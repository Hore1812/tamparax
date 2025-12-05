<?php
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}
require_once 'funciones.php';

// Redirigir si el usuario no es administrador
if (!isset($_SESSION['tipo_usuario']) || $_SESSION['tipo_usuario'] != 1) {
    header('Location: index.php');
    exit;
}

$meses = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"];
$errores = [];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $anio = filter_input(INPUT_POST, 'anio', FILTER_VALIDATE_INT);
    $mes = $_POST['mes'] ?? '';
    $asunto = trim($_POST['asunto'] ?? '');
    $fecha_publicacion = $_POST['fecha_publicacion'] ?? '';
    $archivo = $_FILES['archivo'] ?? null;
    $editor = $_SESSION['idemp'];

    // Validaciones
    if (!$anio || $anio < 2000 || $anio > date("Y") + 5) {
        $errores[] = "El año no es válido.";
    }
    if (empty($mes) || !in_array($mes, $meses)) {
        $errores[] = "El mes seleccionado no es válido.";
    }
    if (empty($asunto)) {
        $errores[] = "El asunto es obligatorio.";
    }
    if (empty($fecha_publicacion)) {
        $errores[] = "La fecha de publicación es obligatoria.";
    }
    if (empty($archivo) || $archivo['error'] !== UPLOAD_ERR_OK) {
        $errores[] = "Debe seleccionar un archivo PDF para el boletín.";
    } else {
        $tipo_archivo = mime_content_type($archivo['tmp_name']);
        $extension_archivo = strtolower(pathinfo($archivo['name'], PATHINFO_EXTENSION));
        $tamano_archivo = $archivo['size'];

        if ($tipo_archivo != 'application/pdf' || $extension_archivo != 'pdf') {
            $errores[] = "El archivo debe ser un PDF.";
        }

        if ($tamano_archivo > 5 * 1024 * 1024) { // 5 MB
            $errores[] = "El archivo no debe exceder los 5 MB.";
        }
    }

    if (empty($errores)) {
        $directorio_destino = 'PDF/boletines/';
        if (!file_exists($directorio_destino)) {
            mkdir($directorio_destino, 0755, true);
        }
        
        $nombre_base = 'boletin_' . strtolower(str_replace(' ', '_', $mes)) . '_' . $anio;
        $nombre_archivo = preg_replace("/[^a-zA-Z0-9_.-]/", "", $nombre_base) . '.pdf';
        $ruta_archivo = $directorio_destino . $nombre_archivo;

        if (move_uploaded_file($archivo['tmp_name'], $ruta_archivo)) {
            $datos = [
                'anio' => $anio,
                'mes' => $mes,
                'asunto' => $asunto,
                'archivo' => $nombre_archivo,
                'fecha_publicacion' => $fecha_publicacion,
                'editor' => $editor
            ];
            $id_insertado = registrarBoletinRegulatorio($datos);
            if ($id_insertado) {
                $_SESSION['mensaje_exito'] = 'Boletín registrado correctamente.';
                header('Location: boletin_regulatorio.php');
                exit;
            } else {
                $errores[] = "Error al guardar el registro en la base de datos.";
                unlink($ruta_archivo); // Eliminar archivo si falla el registro en BD
            }
        } else {
            $errores[] = "Error al subir el archivo.";
        }
    }
}
require_once 'includes/header.php';
?>

<div class="container mt-4">
    <h1 class="text-primary">Registrar Nuevo Boletín Regulatorio</h1>

    <?php if (!empty($errores)): ?>
        <div class="alert alert-danger">
            <ul>
                <?php foreach ($errores as $error): ?>
                    <li><?= $error ?></li>
                <?php endforeach; ?>
            </ul>
        </div>
    <?php endif; ?>

    <div class="card">
        <div class="card-body">
            <form action="registrar_boletin.php" method="POST" enctype="multipart/form-data">
                <div class="row">
                    <div class="col-md-6 mb-3">
                        <label for="anio" class="form-label">Año <span class="text-danger">*</span></label>
                        <input type="number" class="form-control" id="anio" name="anio" value="<?= date("Y") ?>" required>
                    </div>
                    <div class="col-md-6 mb-3">
                        <label for="mes" class="form-label">Mes <span class="text-danger">*</span></label>
                        <select class="form-select" id="mes" name="mes" required>
                            <?php foreach ($meses as $m): ?>
                                <option value="<?= $m ?>" <?= (date("F") == $m) ? 'selected' : '' ?>><?= $m ?></option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                </div>
                <div class="mb-3">
                    <label for="asunto" class="form-label">Asunto <span class="text-danger">*</span></label>
                    <input type="text" class="form-control" id="asunto" name="asunto" required>
                </div>
                <div class="mb-3">
                    <label for="fecha_publicacion" class="form-label">Fecha de Publicación <span class="text-danger">*</span></label>
                    <input type="date" class="form-control" id="fecha_publicacion" name="fecha_publicacion" required>
                </div>
                <div class="mb-3">
                    <label for="archivo" class="form-label">Archivo del Boletín (PDF) <span class="text-danger">*</span></label>
                    <input class="form-control" type="file" id="archivo" name="archivo" accept=".pdf" required>
                </div>

                <div class="d-flex justify-content-end gap-2">
                    <button type="button" class="btn btn-secondary" id="btn-cancelar">Cancelar</button>
                    <button type="submit" class="btn btn-primary">Registrar Boletín</button>
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

            modalTitle.textContent = 'Confirmar Registro';
            modalBody.textContent = '¿Está seguro de que desea registrar este nuevo boletín?';
            btnConfirmarSubmit.textContent = 'Sí, registrar';
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
            modalBody.textContent = '¿Está seguro de que desea cancelar? Se perderán los datos no guardados.';
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
