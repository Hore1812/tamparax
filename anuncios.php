<?php
require_once 'includes/header.php';
require_once 'funciones.php';

// Solo los usuarios administradores y líderes pueden ver esta página
if (!isset($_SESSION['tipo_usuario']) || !in_array($_SESSION['tipo_usuario'], [1, 2])) {
    header('Location: index.php');
    exit;
}

$anuncios = obtenerAnuncios();
?>

<div class="container-fluid mt-4">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h1 class="text-primary">Gestión de Anuncios</h1>
        <?php if ($_SESSION['tipo_usuario'] == 1): ?>
            <a href="registrar_anuncio.php" class="btn btn-primary">
                <i class="fas fa-plus"></i> Nuevo Anuncio
            </a>
        <?php endif; ?>
    </div>

    <div class="card">
        <div class="card-body">
            <div class="table-responsive">
                <table id="tablaAnuncios" class="table table-striped table-hover">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Fecha Inicio</th>
                            <th>Fecha Fin</th>
                            <th>Imagen</th>
                            <th>Comentario</th>
                            <th>Editor</th>
                            <th>Registrado</th>
                            <th>Opciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($anuncios as $anuncio): ?>
                            <tr>
                                <td><?= htmlspecialchars($anuncio['idanuncio']) ?></td>
                                <td><?= htmlspecialchars(date('d/m/Y', strtotime($anuncio['fechainicio']))) ?></td>
                                <td><?= htmlspecialchars(date('d/m/Y', strtotime($anuncio['fechafin']))) ?></td>
                                <td>
                                    <img src="<?= htmlspecialchars($anuncio['rutaarchivo']) ?>" alt="Anuncio" width="100">
                                </td>
                                <td><?= htmlspecialchars($anuncio['comentario']) ?></td>
                                <td><?= htmlspecialchars($anuncio['editor_nombre']) ?></td>
                                <td><?= htmlspecialchars(date('d/m/Y H:i', strtotime($anuncio['registrado']))) ?></td>
                                <td>
                                    <a href="<?= htmlspecialchars($anuncio['rutaarchivo']) ?>" class="btn btn-sm btn-info" target="_blank" rel="noopener noreferrer" title="Ver Imagen">
                                        <i class="fas fa-eye"></i>
                                    </a>
                                    <?php if ($_SESSION['tipo_usuario'] == 1): ?>
                                        <a href="editar_anuncio.php?id=<?= $anuncio['idanuncio'] ?>" class="btn btn-sm btn-secondary" title="Editar">
                                            <i class="fas fa-edit"></i>
                                        </a>
                                        <button class="btn btn-sm btn-danger eliminar-anuncio" 
                                                data-id="<?= $anuncio['idanuncio'] ?>" 
                                                data-nombre="Anuncio ID <?= $anuncio['idanuncio'] ?>"
                                                data-bs-toggle="modal" 
                                                data-bs-target="#modalConfirmar" 
                                                title="Eliminar">
                                            <i class="fas fa-trash"></i>
                                        </button>
                                    <?php endif; ?>
                                </td>
                            </tr>
                        <?php endforeach; ?>
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

<script>
$(document).ready(function() {
    // Setup - add a text input to each footer cell
    $('#tablaAnuncios thead tr').clone(true).appendTo( '#tablaAnuncios thead' );
    $('#tablaAnuncios thead tr:eq(1) th').each( function (i) {
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

    var table = $('#tablaAnuncios').DataTable({
        language: {
            url: 'https://cdn.datatables.net/plug-ins/1.11.5/i18n/es-ES.json'
        },
        order: [[0, 'desc']],
        orderCellsTop: true,
        fixedHeader: true
    });

    const modalConfirmar = document.getElementById('modalConfirmar');
    if (modalConfirmar) {
        modalConfirmar.addEventListener('show.bs.modal', function (event) {
            const button = event.relatedTarget;
            const anuncioId = button.getAttribute('data-id');
            const anuncioNombre = button.getAttribute('data-nombre');

            const modalTitle = modalConfirmar.querySelector('.modal-title');
            const modalBody = modalConfirmar.querySelector('.modal-body');
            const btnConfirmar = modalConfirmar.querySelector('#btnConfirmarAccion');

            modalTitle.textContent = 'Confirmar Eliminación';
            modalBody.innerHTML = `¿Está seguro de que desea eliminar el <strong>${anuncioNombre}</strong>?`;
            btnConfirmar.className = 'btn btn-danger';
            btnConfirmar.textContent = 'Sí, eliminar';

            const newBtn = btnConfirmar.cloneNode(true);
            btnConfirmar.parentNode.replaceChild(newBtn, btnConfirmar);

            newBtn.addEventListener('click', function() {
                const form = document.createElement('form');
                form.method = 'POST';
                form.action = 'eliminar_anuncio.php';
                
                const inputId = document.createElement('input');
                inputId.type = 'hidden';
                inputId.name = 'id';
                inputId.value = anuncioId;
                form.appendChild(inputId);

                document.body.appendChild(form);
                form.submit();
            });
        });

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
