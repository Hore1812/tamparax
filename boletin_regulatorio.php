<?php
require_once 'includes/header.php';
require_once 'funciones.php';

// Inicializar filtros
$filtros = [
    'anio' => $_GET['anio'] ?? null,
    'mes' => $_GET['mes'] ?? null,
    'asunto' => $_GET['asunto'] ?? null
];

$boletines = obtenerBoletinesRegulatorios($filtros);

// Obtener años y meses para los filtros
$anios = [];
$meses = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"];
try {
    $stmt_anios = $pdo->query("SELECT DISTINCT anio FROM boletin_regulatorio ORDER BY anio DESC");
    $anios = $stmt_anios->fetchAll(PDO::FETCH_COLUMN);
} catch (PDOException $e) {
    error_log("Error al obtener años para filtros: " . $e->getMessage());
}

?>

<div class="container-fluid mt-4">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h1 class="text-primary">Gestión de Boletín Regulatorio</h1>
        <?php if (isset($_SESSION['tipo_usuario']) && $_SESSION['tipo_usuario'] == 1): ?>
            <a href="registrar_boletin.php" class="btn btn-primary">
                <i class="fas fa-plus"></i> Nuevo Boletín
            </a>
        <?php endif; ?>
    </div>

    <!-- Filtros -->
    <div class="card mb-4">
        <div class="card-body">
            <form id="filtrosForm" method="GET" class="row g-3">
                <div class="col-md-4">
                    <label for="anio" class="form-label">Año</label>
                    <select id="anio" name="anio" class="form-select">
                        <option value="">Todos</option>
                        <?php foreach ($anios as $a): ?>
                            <option value="<?= $a ?>" <?= ($filtros['anio'] == $a) ? 'selected' : '' ?>><?= $a ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="col-md-4">
                    <label for="mes" class="form-label">Mes</label>
                    <select id="mes" name="mes" class="form-select">
                        <option value="">Todos</option>
                        <?php foreach ($meses as $m): ?>
                            <option value="<?= $m ?>" <?= ($filtros['mes'] == $m) ? 'selected' : '' ?>><?= $m ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="col-md-3">
                    <label for="asunto" class="form-label">Asunto</label>
                    <input type="text" id="asunto" name="asunto" class="form-control" value="<?= htmlspecialchars($filtros['asunto'] ?? '') ?>">
                </div>
                <div class="col-md-2 align-self-end">
                    <button type="submit" class="btn btn-primary">Filtrar</button>
                    <a href="boletin_regulatorio.php" class="btn btn-secondary">Limpiar</a>
                </div>
            </form>
        </div>
    </div>
    
    <!-- Tabla de Boletines -->
    <div class="card">
        <div class="card-body">
            <div class="table-responsive">
                <table id="tablaBoletines" class="table table-striped table-hover">
                    <thead>
                        <tr>
                            <th>Año</th>
                            <th>Mes</th>
                            <th>Asunto</th>
                            <th>Archivo</th>
                            <th>Fecha de Publicación</th>
                            <th>Registrado por</th>
                            <th class="no-filter">Opciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php if (empty($boletines)): ?>
                            <tr>
                                <td colspan="7" class="text-center">No se encontraron registros.</td>
                            </tr>
                        <?php else: ?>
                            <?php foreach ($boletines as $boletin): ?>
                                <tr>
                                    <td><?= htmlspecialchars($boletin['anio'] ?? '') ?></td>
                                    <td><?= htmlspecialchars($boletin['mes'] ?? '') ?></td>
                                    <td><?= htmlspecialchars($boletin['asunto'] ?? '') ?></td>
                                    <td><?= htmlspecialchars($boletin['archivo'] ?? '') ?></td>
                                    <td><?= isset($boletin['fecha_publicacion']) ? date('d/m/Y', strtotime($boletin['fecha_publicacion'])) : '' ?></td>
                                    <td><?= htmlspecialchars($boletin['nombre_editor'] ?? 'N/A') ?></td>
                                    <td>
                                        <div class="d-flex gap-1">
                                            <a href="PDF/boletines/<?= htmlspecialchars($boletin['archivo']) ?>" class="btn btn-sm btn-info" target="_blank" rel="noopener noreferrer" data-bs-toggle="tooltip" title="Ver">
                                                  <i class="fas fa-eye"></i>
                                            </a>
                                            <?php if (isset($_SESSION['tipo_usuario']) && $_SESSION['tipo_usuario'] == 1): ?>
                                                <a href="editar_boletin.php?id=<?= $boletin['id'] ?>" class="btn btn-sm btn-secondary" data-bs-toggle="tooltip" title="Editar">
                                                    <i class="fas fa-edit"></i>
                                                </a>
                                                <button class="btn btn-sm btn-danger eliminar-boletin" 
                                                        data-id="<?= $boletin['id'] ?>" 
                                                        data-nombre="Boletín de <?= htmlspecialchars($boletin['mes']) . ' ' . htmlspecialchars($boletin['anio']) ?>"
                                                        data-bs-toggle="modal" 
                                                        data-bs-target="#modalConfirmar" 
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

<!-- Modal de Confirmación Genérico -->
<div class="modal fade" id="modalConfirmar" tabindex="-1" aria-labelledby="modalConfirmarLabel" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="modalConfirmarLabel">Confirmar Acción</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        ¿Está seguro de que desea realizar esta acción?
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
        <button type="button" class="btn btn-primary" id="btnConfirmarAccion">Confirmar</button>
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

    // Inicialización de DataTables
    $('#tablaBoletines thead tr').clone(true).appendTo( '#tablaBoletines thead' );
    $('#tablaBoletines thead tr:eq(1) th').each( function (i) {
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
 
    var table = $('#tablaBoletines').DataTable( {
        orderCellsTop: true,
        fixedHeader: true,
        "language": {
            "url": "//cdn.datatables.net/plug-ins/1.11.5/i18n/es-ES.json"
        }
    } );

    const modalConfirmar = document.getElementById('modalConfirmar');
    if (modalConfirmar) {
        modalConfirmar.addEventListener('show.bs.modal', function (event) {
            const button = event.relatedTarget;
            const boletinId = button.getAttribute('data-id');
            const boletinNombre = button.getAttribute('data-nombre');

            const modalTitle = modalConfirmar.querySelector('.modal-title');
            const modalBody = modalConfirmar.querySelector('.modal-body');
            const btnConfirmar = modalConfirmar.querySelector('#btnConfirmarAccion');

            modalTitle.textContent = 'Confirmar Eliminación';
            modalBody.innerHTML = `¿Está seguro de que desea eliminar el <strong>${boletinNombre}</strong>?`;
            btnConfirmar.className = 'btn btn-danger';
            btnConfirmar.textContent = 'Sí, eliminar';

            // Clona y reemplaza el botón para eliminar listeners anteriores
            const newBtn = btnConfirmar.cloneNode(true);
            btnConfirmar.parentNode.replaceChild(newBtn, btnConfirmar);

            newBtn.addEventListener('click', function() {
                const form = document.createElement('form');
                form.method = 'POST';
                form.action = 'eliminar_boletin.php';
                
                const inputId = document.createElement('input');
                inputId.type = 'hidden';
                inputId.name = 'id';
                inputId.value = boletinId;
                form.appendChild(inputId);

                document.body.appendChild(form);
                form.submit();
            });
        });
         // Restaurar modal a su estado original al cerrarse
        modalConfirmar.addEventListener('hidden.bs.modal', function () {
            const modalTitle = modalConfirmar.querySelector('.modal-title');
            const modalBody = modalConfirmar.querySelector('.modal-body');
            const btnConfirmar = modalConfirmar.querySelector('#btnConfirmarAccion');

            modalTitle.textContent = 'Confirmar Acción';
            modalBody.textContent = '¿Está seguro de que desea realizar esta acción?';
            btnConfirmar.className = 'btn btn-primary';
            btnConfirmar.textContent = 'Confirmar';
        });
    }
});
</script>
