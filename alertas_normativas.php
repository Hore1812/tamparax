<?php
require_once 'includes/header.php';
require_once 'funciones.php';

// Inicializar filtros
$filtros = [
    'entidad' => $_GET['entidad'] ?? null,
    'fecha_desde' => $_GET['fecha_desde'] ?? null,
    'fecha_hasta' => $_GET['fecha_hasta'] ?? null
];

// Obtener datos de alertas normativas
$alertas = obtenerAlertasNormativas($filtros);
?>

<div class="container-fluid mt-4">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h1 class="text-primary">Gestión de Alertas Normativas</h1>
        <?php if (isset($_SESSION['tipo_usuario']) && $_SESSION['tipo_usuario'] == 1): // Solo admin puede crear ?>
            <a href="registrar_alerta.php" class="btn btn-primary">
                <i class="fas fa-plus"></i> Nueva Alerta
            </a>
        <?php endif; ?>
    </div>

    <!-- Filtros -->
    <div class="card mb-4">
        <div class="card-body">
            <form id="filtrosForm" method="GET" class="row g-3">
                <div class="col-md-4">
                    <label for="entidad" class="form-label">Buscar por Entidad o Tipo de Norma</label>
                    <input type="text" id="entidad" name="entidad" class="form-control" value="<?= htmlspecialchars($filtros['entidad'] ?? '') ?>">
                </div>
                <div class="col-md-3">
                    <label for="fecha_desde" class="form-label">Desde</label>
                    <input type="date" id="fecha_desde" name="fecha_desde" class="form-control" value="<?= htmlspecialchars($filtros['fecha_desde'] ?? '') ?>">
                </div>
                <div class="col-md-3">
                    <label for="fecha_hasta" class="form-label">Hasta</label>
                    <input type="date" id="fecha_hasta" name="fecha_hasta" class="form-control" value="<?= htmlspecialchars($filtros['fecha_hasta'] ?? '') ?>">
                </div>
                <div class="col-md-2 align-self-end">
                    <button type="submit" class="btn btn-primary">Filtrar</button>
                    <a href="alertas_normativas.php" class="btn btn-secondary">Limpiar</a>
                </div>
            </form>
        </div>
    </div>
    
    <!-- Tabla de Alertas -->
    <div class="card">
        <div class="card-body">
            <div class="table-responsive">
                <table id="tablaAlertas" class="table table-striped table-hover">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Temática</th>
                            <th>Entidad</th>
                            <th>Tipo Norma</th>
                            <th>Número Norma</th>
                            <th>Fecha</th>
                            <th>Detalle</th>
                            <th class="no-filter">Opciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php if (empty($alertas)): ?>
                            <tr>
                                <td colspan="8" class="text-center">No se encontraron registros.</td>
                            </tr>
                        <?php else: ?>
                            <?php foreach ($alertas as $alerta): ?>
                                <tr>
                                    <td><?= $alerta['id'] ?></td>
                                    <td><?= htmlspecialchars($alerta['tematica'] ?? '') ?></td>
                                    <td><?= htmlspecialchars($alerta['entidad'] ?? '') ?></td>
                                    <td><?= htmlspecialchars($alerta['tipo_norma'] ?? '') ?></td>
                                    <td><?= htmlspecialchars($alerta['numero_norma'] ?? '') ?></td>
                                    <td><?= isset($alerta['fecha']) ? date('d/m/Y', strtotime($alerta['fecha'])) : '' ?></td>
                                    <td><?= nl2br(htmlspecialchars($alerta['detalle'] ?? '')) ?></td>
                                    <td>
                                        <div class="d-flex gap-1">
                                            <?php if (!empty($alerta['url'])): ?>
                                                <a href="<?= htmlspecialchars($alerta['url']) ?>" class="btn btn-sm btn-info" target="_blank" rel="noopener noreferrer" data-bs-toggle="tooltip" title="Ver Enlace">
                                                    <i class="fas fa-link"></i>
                                                </a>
                                            <?php endif; ?>
                                            <?php if (isset($_SESSION['tipo_usuario']) && $_SESSION['tipo_usuario'] == 1): // Solo admin puede editar/eliminar ?>
                                                <a href="editar_alerta.php?id=<?= $alerta['id'] ?>" class="btn btn-sm btn-secondary" data-bs-toggle="tooltip" title="Editar">
                                                    <i class="fas fa-edit"></i>
                                                </a>
                                                <button class="btn btn-sm btn-danger eliminar-alerta" 
                                                        data-id="<?= $alerta['id'] ?>" 
                                                        data-nombre="<?= htmlspecialchars($alerta['numero_norma']) ?>"
                                                        data-bs-toggle="modal" 
                                                        data-bs-target="#modalConfirmarGuardado" 
                                                        title="Eliminar">
                                                    <i class="fas fa-trash"></i>
                                                </button>
                                            <?php endif; ?>
                                        </div>
                                    </td>
                                </tr>
                            <?php endforeach; ?>
                        <?php endif; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

<?php require_once 'includes/footer.php'; ?>

<script src="https://cdn.datatables.net/1.11.5/js/jquery.dataTables.min.js"></script>
<script src="https://cdn.datatables.net/1.11.5/js/dataTables.bootstrap5.min.js"></script>
<script>
document.addEventListener('DOMContentLoaded', function() {
    // Tooltips
    var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl);
    });

    // Setup - add a text input to each footer cell
    $('#tablaAlertas thead tr').clone(true).appendTo( '#tablaAlertas thead' );
    $('#tablaAlertas thead tr:eq(1) th').each( function (i) {
        if ($(this).hasClass('no-filter')) {
            $(this).html('');
            return;
        }
        var title = $(this).text();
        $(this).html( '<input type="text" class="form-control form-control-sm" placeholder="Buscar '+title+'" />' );
 
        $( 'input', this ).on( 'keyup change', function () {
            if ( table.column(i).search() !== this.value ) {
                table
                    .column(i)
                    .search( this.value )
                    .draw();
            }
        } );
    } );
 
    var table = $('#tablaAlertas').DataTable( {
        orderCellsTop: true,
        fixedHeader: true,
        "language": {
            "url": "//cdn.datatables.net/plug-ins/1.11.5/i18n/es-ES.json"
        }
    } );

    // Lógica para el modal de confirmación de eliminación
    const modalConfirmar = document.getElementById('modalConfirmarGuardado');
    if (modalConfirmar) {
        modalConfirmar.addEventListener('show.bs.modal', function (event) {
            const btnConfirmarSubmit = modalConfirmar.querySelector('#btnConfirmarGuardarSubmit');
            if(btnConfirmarSubmit) {
                btnConfirmarSubmit.textContent = 'Confirmar';
                btnConfirmarSubmit.className = 'btn btn-primary';
            }
            const button = event.relatedTarget;
            if (button.classList.contains('eliminar-alerta')) {
                const alertaId = button.getAttribute('data-id');
                const alertaNombre = button.getAttribute('data-nombre');

                const modalTitle = modalConfirmar.querySelector('.modal-title');
                const modalBody = modalConfirmar.querySelector('.modal-body');
                const btnConfirmarSubmit = modalConfirmar.querySelector('#btnConfirmarGuardarSubmit');

                modalTitle.textContent = 'Confirmar Eliminación';
                modalBody.innerHTML = `¿Está seguro de que desea eliminar la alerta con número de norma <strong>${alertaNombre}</strong>?`;
                btnConfirmarSubmit.textContent = 'Sí, eliminar';
                btnConfirmarSubmit.className = 'btn btn-danger'; // Cambiar color a rojo

                $(btnConfirmarSubmit).off('click').on('click', function() {
                    const form = document.createElement('form');
                    form.method = 'POST';
                    form.action = 'eliminar_alerta.php';
                    
                    const inputId = document.createElement('input');
                    inputId.type = 'hidden';
                    inputId.name = 'id';
                    inputId.value = alertaId;
                    form.appendChild(inputId);

                    document.body.appendChild(form);
                    form.submit();
                });
            }
        });

        // Restaurar el botón del modal cuando se cierra
        $(modalConfirmar).on('hidden.bs.modal', function () {
            const btnConfirmarSubmit = modalConfirmar.querySelector('#btnConfirmarGuardarSubmit');
            if(btnConfirmarSubmit) {
                btnConfirmarSubmit.textContent = 'Confirmar';
                btnConfirmarSubmit.className = 'btn btn-primary';
            }
        });
    }
});
</script>
