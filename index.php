<?php
require_once 'includes/header.php';
require_once 'funciones.php';
?>

<div class="container-fluid mt-4">
    <!-- Fila superior -->
    <div class="row mb-4">
        <!-- Subárea superior izquierda -->
        <div class="col-md-6">
            <div class="card h-100 bg-primary text-white">
                <div class="card-body text-center d-flex flex-column justify-content-center">
                    <?php
                    date_default_timezone_set('America/Lima');
                    $hora = date('H');
                    $saludo = '';
                    if ($hora < 12) {
                        $saludo = 'Buenos días';
                    } elseif ($hora < 18) {
                        $saludo = 'Buenas tardes';
                    } else {
                        $saludo = 'Buenas noches';
                    }
                    ?>
                    <h1 class="display-4"><?= $saludo ?>, <?= htmlspecialchars($_SESSION['nombre_empleado'] ?? 'Usuario') ?>!</h1>
                    <p class="lead">Conoce las últimas noticias del mundo de las telecomunicaciones.</p>
                    <div class="mt-4 d-grid gap-2 d-md-block">
                        <a href="alertas_normativas.php" class="btn btn-orange btn-lg">Alerta Normativa</a>
                        <a href="boletin_regulatorio.php" class="btn btn-light btn-lg">Boletín Regulatorio</a>
                    </div>
                </div>
            </div>
        </div>
        <!-- Subárea superior derecha -->
        <div class="col-md-6">
            <div class="card h-100 rounded bg-primary">
                <div class="card-body p-0">
                    <?php $anunciosActivos = obtenerAnunciosActivos(); ?>
                    <?php if (count($anunciosActivos) > 1): ?>
                        <div id="carouselAnuncios" class="carousel slide" data-bs-ride="carousel">
                            <div class="carousel-indicators">
                                <?php foreach ($anunciosActivos as $index => $anuncio): ?>
                                    <button type="button" data-bs-target="#carouselAnuncios" data-bs-slide-to="<?= $index ?>" class="<?= $index === 0 ? 'active' : '' ?>" aria-current="<?= $index === 0 ? 'true' : 'false' ?>"></button>
                                <?php endforeach; ?>
                            </div>
                            <div class="carousel-inner rounded">
                                <?php foreach ($anunciosActivos as $index => $anuncio): ?>
                                    <div class="carousel-item <?= $index === 0 ? 'active' : '' ?>">
                                        <img src="<?= htmlspecialchars($anuncio['rutaarchivo']) ?>" class="d-block w-100" alt="<?= htmlspecialchars($anuncio['comentario']) ?>">
                                    </div>
                                <?php endforeach; ?>
                            </div>
                            <button class="carousel-control-prev" type="button" data-bs-target="#carouselAnuncios" data-bs-slide="prev">
                                <span class="carousel-control-prev-icon" aria-hidden="true"></span>
                                <span class="visually-hidden">Previous</span>
                            </button>
                            <button class="carousel-control-next" type="button" data-bs-target="#carouselAnuncios" data-bs-slide="next">
                                <span class="carousel-control-next-icon" aria-hidden="true"></span>
                                <span class="visually-hidden">Next</span>
                            </button>
                        </div>
                    <?php elseif (count($anunciosActivos) === 1): ?>
                        <img src="<?= htmlspecialchars($anunciosActivos[0]['rutaarchivo']) ?>" class="d-block w-100 rounded" alt="<?= htmlspecialchars($anunciosActivos[0]['comentario']) ?>">
                    <?php else: ?>
                        <div class="d-flex justify-content-center align-items-center h-100">
                            <p class="text-white">No hay anuncios para mostrar.</p>
                        </div>
                    <?php endif; ?>
                </div>
            </div>
        </div>
    </div>

    <!-- Fila inferior -->
    <div class="row transparent-cards-row">
        <!-- Subárea inferior 1 -->
        <div class="col-md-4">
            <div class="card">
                <div class="card-body text-center">
                    <?php
                    $meses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
                    $nombreMes = $meses[date('n') - 1];
                    ?>
                    <h5 class="card-title text-center">Horas Soporte Equipo (<?= $nombreMes ?>)</h5>
                    <div style="width:95%; margin: auto;">
                        <canvas id="graficoSoporte"></canvas>
                    </div>
                </div>
            </div>
        </div>
        <!-- Subárea inferior 2 -->
        <div class="col-md-4">
            <div class="card">
                <div class="card-body text-center">
                    <h5 class="card-title text-center">Mi cumplimiento (<?= $nombreMes ?>)</h5>
                    <div style="width:95%; margin: auto;">
                        <canvas id="graficoHorasUsuario"></canvas>
                    </div>
                </div>
            </div>
        </div>
        <!-- Subárea inferior 3 -->
        <div class="col-md-4">
            <div class="card">
                <div class="card-body text-center">
                    <h5 class="card-title text-center">Mi cumplimiento por tipo hora (<?= $nombreMes ?>)</h5>
                    <div style="width:95%; margin: auto;">
                        <canvas id="graficoHorasTipo"></canvas>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<?php
$horasCompletadas = obtenerHorasCompletadasSoporteMesActual();
$horasPlanificadas = obtenerHorasPlanificadasSoporteMesActual();
$horasPendientes = max(0, $horasPlanificadas - $horasCompletadas);

$idUsuarioActual = $_SESSION['idemp'] ?? 0;
$horasUsuario = obtenerHorasAsignadasUsuarioMesActual($idUsuarioActual);
$horasMeta = obtenerHorasMetaEmpleado($idUsuarioActual);
$horasRestantesMeta = max(0, $horasMeta - $horasUsuario);

$horasPorTipo = obtenerHorasPlanificadasPorTipoUsuarioMesActual($idUsuarioActual);
$tiposHora = array_column($horasPorTipo, 'tipohora');
$horasAsignadas = array_column($horasPorTipo, 'HorasPlanificadasAsignadas');
?>

<?php require_once 'includes/footer.php'; ?>

<script src="https://cdn.jsdelivr.net/npm/chartjs-plugin-datalabels@2.2.0"></script>

<script>
document.addEventListener('DOMContentLoaded', function() {
    // Spinner para botones
    const buttons = document.querySelectorAll('.btn-lg');
    buttons.forEach(button => {
        button.addEventListener('click', function(e) {
            e.preventDefault();
            this.innerHTML = `<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> Cargando...`;
            this.disabled = true;
            setTimeout(() => {
                window.location.href = this.href;
            }, 750);
        });
    });

    // Gráfico de Soporte
    const ctx = document.getElementById('graficoSoporte').getContext('2d');
    const horasCompletadas = <?= json_encode($horasCompletadas) ?>;
    const horasPlanificadas = <?= json_encode($horasPlanificadas) ?>;
    const horasPendientes = <?= json_encode($horasPendientes) ?>;

    new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: ['Completadas', 'Pendientes'],
            datasets: [{
                data: [horasCompletadas, horasPendientes],
                backgroundColor: ['rgba(75, 192, 192, 0.4)', 'rgba(255, 206, 86, 0.2)'],
                borderColor: ['rgba(75, 192, 192, 1)', 'rgba(255, 206, 86, 1)'],
                borderWidth: 1
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: 'top',
                },
                title: {
                    display: true,
                    text: `Total Planificado: ${horasPlanificadas} horas`
                },
                datalabels: {
                    formatter: (value, ctx) => {
                        if (horasPlanificadas === 0) {
                            return '0%';
                        }
                        let percentage = (value * 100 / horasPlanificadas).toFixed(2) + '%';
                        return percentage;
                    },
                    color: '#000',
                }
            }
        },
        plugins: [ChartDataLabels]
    });

    // Gráfico de Horas de Usuario
    const ctx2 = document.getElementById('graficoHorasUsuario').getContext('2d');
    const horasUsuario = <?= json_encode($horasUsuario) ?>;
    const horasRestantesMeta = <?= json_encode($horasRestantesMeta) ?>;
    const horasMeta = <?= json_encode($horasMeta) ?>;

    new Chart(ctx2, {
        type: 'doughnut',
        data: {
            labels: ['Cumplidas', 'Pendientes'],
            datasets: [{
                data: [horasUsuario, horasRestantesMeta],
                backgroundColor: ['rgba(24, 62, 235, 0.4)', 'rgba(201, 203, 207, 0.2)'],
                borderColor: ['rgba(24, 62, 235, 1)', 'rgba(201, 203, 207, 1)'],
                borderWidth: 1
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: 'top',
                },
                title: {
                    display: true,
                    text: `Meta Mensual: ${horasMeta} horas`
                },
                datalabels: {
                    formatter: (value, ctx) => {
                        if (horasMeta === 0) {
                            return '0%';
                        }
                        let percentage = (value * 100 / horasMeta).toFixed(2) + '%';
                        return percentage;
                    },
                    color: '#000',
                }
            }
        },
        plugins: [ChartDataLabels]
    });

    // Gráfico de Horas por Tipo
    const ctx3 = document.getElementById('graficoHorasTipo').getContext('2d');
    const tiposHora = <?= json_encode($tiposHora) ?>;
    const horasAsignadas = <?= json_encode($horasAsignadas) ?>;

    new Chart(ctx3, {
        type: 'doughnut',
        data: {
            labels: tiposHora,
            datasets: [{
                label: 'Horas Planificadas',
                data: horasAsignadas,
                backgroundColor: [
                    'rgba(255, 170, 132, 0.4)',
                    'rgba(54, 162, 235, 0.4)',
                    'rgba(255, 206, 86, 0.4)',
                    'rgba(75, 192, 192, 0.4)',
                ],
                borderColor: [
                    'rgba(255, 170, 132, 1)',
                    'rgba(54, 162, 235, 1)',
                    'rgba(255, 206, 86, 1)',
                    'rgba(75, 192, 192, 1)',
                ],
                borderWidth: 1
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: 'top',
                },
                title: {
                    display: true,
                    text: `Horas cumplidas: ${horasAsignadas.reduce((a, b) => parseFloat(a) + parseFloat(b), 0)}`
                },
                datalabels: {
                    formatter: (value, ctx) => {
                        let sum = ctx.chart.data.datasets[0].data.reduce((a, b) => parseFloat(a) + parseFloat(b), 0);
                        if (sum === 0) {
                            return '0%';
                        }
                        let percentage = (value * 100 / sum).toFixed(2) + '%';
                        return percentage;
                    },
                    color: '#000',
                }
            }
        },
        plugins: [ChartDataLabels]
    });
});
</script>
